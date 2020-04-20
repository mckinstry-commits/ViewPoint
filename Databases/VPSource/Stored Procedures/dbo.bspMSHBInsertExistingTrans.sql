SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*********************************************************/
CREATE procedure [dbo].[bspMSHBInsertExistingTrans]
/****************************************************************
 * Created By:  GF 12/20/2000
 * Modified By: MV 07/05/01 - Issue 12769 BatchUserMemoInsertExisting
 *              GF 07/05/01 - missing OldMatlGroup when pulling in existing transaction
 *              TV 05/29/02 - insert UniqueAttchID into batch table
 *				GF 11/26/2003 - issue #23139 - use new stored procedure to create user memo update statement.
 *				MV 09/07/11 - TK-08245 Added Haul Tax fields to insert to bMSLB
 *
 * USAGE:
 * This procedure is used by the MS Haul Entry to pull existing
 * transactions from bMSHH into bMSHB for editing.  Will only pull
 * haul entries not in another batch, that meet all restrictions.
 *
 * Checks batch info in bHQBC, and transaction info in bMSHH.
 * Adds entry to next available Seq# in bMSHB.
 *
 * MSHB insert trigger will update InUseBatchId in bMSHD
 *
 *
 * INPUT PARAMETERS
 *  @msco			MS Co#
 *  @mth			Batch month
 *  @batchid		Batch ID
 *  @xfreightbill   Freight Bill
 *  @xtrans         Haul Trans
 *
 * OUTPUT PARAMETERS
 *  @errmsg		Error message
 *
 * RETURN VALUE
 *   0   			success
 *   1   			fail
 ****************************************************************/
(@co bCompany = null, @mth bMonth = null, @batchid bBatchID = null,
 @xfreightbill varchar(10) = null, @xtrans bTrans = null,
 @errmsg varchar(255) output)
as
set nocount on

declare @rcode int, @status tinyint, @seq int, @errtext varchar(100), @haultrans bTrans,
		@count smallint, @batchtranstype char(1), @openbcMSTD tinyint, @mstrans bTrans,
		@line int, @mshbud_flag bYN, @mslbud_flag bYN, @h_join varchar(2000),
		@h_where varchar(2000), @h_update varchar(2000), @l_join varchar(2000),
		@l_where varchar(2000), @l_update varchar(2000), @usermemosql varchar(8000),
		@opencursor int, @freightbill varchar(10)

select @rcode = 0, @count=0, @opencursor = 0, @openbcMSTD = 0, @batchtranstype = 'C', 
   	   @mshbud_flag = 'N', @mslbud_flag = 'N'

---- validate HQ Batch
exec @rcode = dbo.bspHQBatchProcessVal @co, @mth, @batchid, 'MS Haul', 'MSHB', @errtext output, @status output
if @rcode <> 0
	begin
   	select @errmsg = @errtext, @rcode = 1
   	goto bspexit
   	end

if @status <> 0
	begin
	select @errmsg = 'Invalid Batch status -  must be ''open''!', @rcode = 1
	goto bspexit
	end

if @xfreightbill is null and @xtrans is null
	begin
	select @errmsg = 'Must select a freight bill or Haul Transaction to add to batch.', @rcode = 1
	goto bspexit
	end

---- call bspUserMemoQueryBuild to create update, join, and where clause
---- pass in source and destination. Remember to use views only unless working
---- with a Viewpoint (bidtek) connection.
exec @rcode = dbo.bspUserMemoQueryBuild @co, @mth, @batchid, 'MSHH', 'MSHB', @mshbud_flag output,
   			@h_update output, @h_join output, @h_where output, @errmsg output
if @rcode <> 0 goto bspexit

---- call bspUserMemoQueryBuild to create update, join, and where clause
---- pass in source and destination. Remember to use views only unless working
---- with a Viewpoint (bidtek) connection.
exec @rcode = dbo.bspUserMemoQueryBuild @co, @mth, @batchid, 'MSTD', 'MSLB', @mslbud_flag output,
   			@l_update output, @l_join output, @l_where output, @errmsg output
if @rcode <> 0 goto bspexit


---- create cursor on MSHH to insert transactions into MSHB
declare bcMSHH cursor for select HaulTrans, FreightBill
from MSHH where MSCo=@co and Mth=@mth and InUseBatchId is null and Purge <> 'Y'

---- open cursor
open bcMSHH
select @opencursor = 1

---- loop through all rows in MSHH cursor and update their info.
mshh_posting_loop:
fetch next from bcMSHH into @haultrans, @freightbill

if @@fetch_status <> 0 goto mshh_posting_end

if @xfreightbill is not null 
	begin
	if @xfreightbill <> @freightbill goto mshh_posting_loop
	end

if @xtrans is not null
	begin
	if @xtrans <> @haultrans goto mshh_posting_loop
	end

---- get next available sequence # for this batch
select @seq = isnull(max(BatchSeq),0)+1
from MSHB where Co=@co and Mth=@mth and BatchId=@batchid
---- add MS transaction to batch
insert into bMSHB (Co,Mth,BatchId,BatchSeq,BatchTransType,HaulTrans,FreightBill,SaleDate,
		HaulerType,VendorGroup,HaulVendor,Truck,Driver,EMCo,Equipment,EMGroup,PRCo,Employee,
		Notes,OldFreightBill,OldSaleDate,OldHaulerType,OldVendorGroup,OldHaulVendor,OldTruck,
		OldDriver,OldEMCo,OldEquipment,OldPRCo,OldEmployee,OldNotes,UniqueAttchID)
select @co,@mth,@batchid,@seq,@batchtranstype,HaulTrans,FreightBill,SaleDate,HaulerType,
		VendorGroup,HaulVendor,Truck,Driver,EMCo,Equipment,EMGroup,PRCo,Employee,Notes,
		FreightBill,SaleDate,HaulerType,VendorGroup,HaulVendor,Truck,Driver,EMCo,Equipment,
		PRCo,Employee,Notes,UniqueAttchID
from MSHH where MSCo=@co and Mth=@mth and HaulTrans=@haultrans
if @@rowcount <> 1
	begin
	select @errmsg = 'Unable to add entry to MS Haul Entry Batch!', @rcode = 1
	goto bspexit
	end

if @mshbud_flag = 'Y'
	begin
	set @usermemosql = @h_update + @h_join + @h_where + ' and b.HaulTrans = ' + convert(varchar(10), @haultrans) + ' and MSHB.HaulTrans = ' + convert(varchar(10),@haultrans)
	exec (@usermemosql)
	end



---- create cursor for MSTD to insert lines
declare bcMSTD cursor LOCAL FAST_FORWARD for select MSTrans
from MSTD where MSCo=@co and Mth=@mth and HaulTrans=@haultrans
and InUseBatchId is null and Purge <> 'Y'

open bcMSTD
set @openbcMSTD = 1

---- loop through all rows in MSTD cursor and update their info.
mstd_posting_loop:
fetch next from bcMSTD into @mstrans

if @@fetch_status <> 0 goto mstd_posting_end

---- get next available line # for this MSLB batch
select @line = isnull(max(HaulLine),0)+1
from MSLB where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq
---- add MS transaction to MSLB batch
insert into bMSLB(Co,Mth,BatchId,BatchSeq,HaulLine,BatchTransType,MSTrans,FromLoc,VendorGroup,
		MatlVendor,MatlGroup,Material,UM,SaleType,CustGroup,Customer,CustJob,CustPO,PaymentType,
		CheckNo,Hold,JCCo,Job,PhaseGroup,HaulPhase,HaulJCCType,INCo,ToLoc,TruckType,StartTime,
		StopTime,Loads,Miles,Hours,Zone,HaulCode,HaulBasis,HaulRate,HaulTotal,PayCode,PayBasis,
		PayRate,PayTotal,RevCode,RevBasis,RevRate,RevTotal,TaxGroup,TaxCode,TaxType,TaxBasis,
		TaxTotal,DiscBasis,DiscRate,DiscOff,TaxDisc,HaulPayTaxType, HaulPayTaxCode, HaulPayTaxRate,HaulPayTaxAmt,
		OldFromLoc,OldVendorGroup,OldMatlVendor,OldMatlGroup,OldMaterial,OldUM,OldSaleType,OldCustGroup,OldCustomer,
		OldCustJob,OldCustPO,OldPaymentType,OldCheckNo,OldHold,OldJCCo,OldJob,OldPhaseGroup,OldHaulPhase,OldHaulJCCType,
		OldINCo,OldToLoc,OldTruckType,OldStartTime,OldStopTime,OldLoads,OldMiles,OldHours,
		OldZone,OldHaulCode,OldHaulBasis,OldHaulRate,OldHaulTotal,OldPayCode,OldPayBasis,
		OldPayRate,OldPayTotal,OldRevCode,OldRevBasis,OldRevRate,OldRevTotal,OldTaxGroup,
		OldTaxCode,OldTaxType,OldTaxBasis,OldTaxTotal,OldDiscBasis,OldDiscRate,OldDiscOff,
		OldTaxDisc,OldMSInv,OldAPRef,
		OldHaulPayTaxType, OldHaulPayTaxCode,OldHaulPayTaxRate, OldHaulPayTaxAmt)
select @co,@mth,@batchid,@seq,@line,@batchtranstype,MSTrans,FromLoc,VendorGroup,MatlVendor,
		MatlGroup,Material,UM,SaleType,CustGroup,Customer,CustJob,CustPO,PaymentType,CheckNo,
		Hold,JCCo,Job,PhaseGroup,HaulPhase,HaulJCCType,INCo,ToLoc,TruckType,StartTime,StopTime,
		Loads,Miles,Hours,Zone,HaulCode,HaulBasis,HaulRate,HaulTotal,PayCode,PayBasis,PayRate,
		PayTotal,RevCode,RevBasis,RevRate,RevTotal,TaxGroup,TaxCode,TaxType,TaxBasis,TaxTotal,
		DiscBasis,DiscRate,DiscOff,TaxDisc,HaulPayTaxType, HaulPayTaxCode, HaulPayTaxRate, HaulPayTaxAmt,
		FromLoc,VendorGroup,MatlVendor,MatlGroup,Material,UM,SaleType,CustGroup,Customer,CustJob,
		CustPO,PaymentType,CheckNo,Hold,JCCo,Job,PhaseGroup,
		HaulPhase,HaulJCCType,INCo,ToLoc,TruckType,StartTime,StopTime,Loads,Miles,Hours,Zone,HaulCode,
		HaulBasis,HaulRate,HaulTotal,PayCode,PayBasis,PayRate,PayTotal,RevCode,RevBasis,RevRate,
		RevTotal,TaxGroup,TaxCode,TaxType,TaxBasis,TaxTotal,DiscBasis,DiscRate,DiscOff,TaxDisc,
		MSInv,APRef,
		HaulPayTaxType, HaulPayTaxCode, HaulPayTaxRate, HaulPayTaxAmt
from MSTD where MSCo = @co and Mth = @mth and MSTrans = @mstrans
if @@rowcount <> 1
	begin
	select @errmsg = 'Unable to add entry to MS Haul Entry Batch!', @rcode = 1
	goto bspexit
	end

if @mslbud_flag = 'Y'
	begin
	set @usermemosql = @l_update + @l_join + @l_where + ' and b.MSTrans = ' + convert(varchar(10), @mstrans) + ' and MSLB.MSTrans = ' + convert(varchar(10),@mstrans)
	exec (@usermemosql)
	end

goto mstd_posting_loop

mstd_posting_end:
if @openbcMSTD = 1
	begin
	close bcMSTD
	deallocate bcMSTD
	select @openbcMSTD = 0
	end

select @count = @count + 1
goto mshh_posting_loop



mshh_posting_end:
if @opencursor = 1
	begin
	close bcMSHH
	deallocate bcMSHH
	select @opencursor = 0
	end

if @count=0
	begin
	select @errmsg='No entries were found to add to batch.', @rcode=1
	end
else
	begin
	select @errmsg=convert(varchar(6),@count) + ' entries have been added to this batch.'
	end



bspexit:
if @opencursor = 1
	begin
	close bcMSHH
	deallocate bcMSHH
	select @opencursor = 0
	end

if @openbcMSTD = 1
	begin
	close bcMSTD
	deallocate bcMSTD
	select @openbcMSTD = 0
	end

	if @rcode<>0 select @errmsg = isnull(@errmsg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSHBInsertExistingTrans] TO [public]
GO
