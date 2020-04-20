SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/***************************************************************/
CREATE  procedure [dbo].[bspMSTBInsertExistingTrans]
/****************************************************************
* Created By:	GF 09/18/2000
* Modified By:	GF 10/12/2000
*				GG 11/08/00 - Added Haul Trans restriction, general cleanup
*				GF 01/16/2001 - Added Purge <> 'Y' to restrictions
*				MV 07/05/01 - Issue 12769 BatchUserMemoInsertExisting
*				TV 05/28/02 - insert UniqueAttchID into batch table
*				GF 06/20/03 - issue #20785 added APCo,APMth,OldAPCo,OldAPMth to insert into MSTB
*				GF 07/23/03 - issue #21933 - speed improvement clean up.
*				GF 11/26/2003 - issue #23139 - use new stored procedure to create user memo update statement.
*				GF 01/16/2003 - issue #22634 - need to exclude tickets w/APRef assigned when mark as delete = 'Y'
*				GF 08/04/2004 - issue #25298 - need to exclude tickets w/MSInv assigned when mark as delete = 'Y'
*				GF 03/02/2005 - issue #19185 material vendor enhancement
*				GF 06/08/2005 - issue #28906 added reasoncode and oldreasoncode to insert into MSTB
*				GF 07/15/2007 - issue #28259 changed from execute sql to creating local cursor. 6.x
*				GF 07/23/2007 - issue #27185 changed ticket # to a range of tickets (beg,end)
*				GF 02/25/2008 - issue #25573 & #26088 changed sale date to sale date range. improved return message.
*				CHS 03/14/2008 - issue #127082 - international addresses
*				DAN SO 01/22/2010 - Issue #129350 - Pull associated Surcharges w/out creating Surcharge Tickets AND
*													set Surcharges InUseBatchId to the Parent record InUseBatchId
*				GF 07/30/2012 TK-16657 move error count after batch check and only count if in use in different batch
*				GF 04/30/2013 TFS-48687 added APRef/MatlAPRef to surcharge batch table
*
*													
*
* USAGE:
* This procedure is used by the MS Ticket Entry to pull existing
* transactions from bMSTD into bMSTB for editing.  Will only pull
* ticket entries not in another batch, that meet all restrictions
*
* Checks batch info in bHQBC.
* Adds entry to next available Seq# in bMSTB
*
*
* INPUT PARAMETERS
*  @msco			MS Co#
*  @mth				Batch month
*  @batchid			Batch ID
*  @xtrans			MS Trans# restriction
*  @xbatchid		Batch ID restriction
*  @saledate		Sale date restirction
*  @fromloc			From Location restriction
*  @ticket			Beginning Ticket restriction
*  @matlgroup		Material Group restriction
*  @material		Material restriction
*  @um				Unit of measure restriction
*  @saletype		Sale type restriction ('C','J','I',null)
*  @custgroup		Customer Group restriction
*  @customer		Customer restriction
*  @custjob			Customer Job restriction
*  @custpo			Customer PO restriction
*  @hold			Hold restriction ('Y','N',null)
*  @jcco			JC Co# restriction
*  @job				Job restriction
*  @inco			Sell to IN Co# restriction
*  @toloc			Sell to Location restriction
*  @markasdelete	Mark as delete flag ('Y','N') - determines BatchTransType
*  @check_ticket	check Ticket flag
*  @endticket		Ending Ticket Restriction
*  @check_saledate	check sale date flag
*  @endsaledate		Ending Sale Date
*
* OUTPUT PARAMETERS
*  @errmsg		Error message
*
* RETURN VALUE
*   0   			success
*   1   			fail
****************************************************************/
(@co bCompany = null, @mth bMonth = null, @batchid bBatchID = null,
 @xtrans bTrans = null, @xbatchid bBatchID= null, @saledate bDate = null,
 @fromloc bLoc = null, @ticket bTic = null, @matlgroup bGroup = null,
 @material bMatl = null, @um bUM = null, @saletype char(1) = null, @custgroup bGroup,
 @customer bCustomer = null, @custjob varchar(20) = null, @custpo varchar(20) = null,
 @hold bYN = null, @jcco bCompany = null, @job bJob = null, @inco bCompany = null,
 @toloc bLoc = null, @markasdelete bYN = null, @check_ticket bYN = null,
 @endticket bTic = null, @check_saledate bYN = null, @endsaledate bDate = null,
 @errmsg varchar(255) output)
as
set nocount on

declare @rcode int, @retcode int, @status tinyint, @seq int, @errtext varchar(100),
		@count smallint, @batchtranstype char(1), @opencursor tinyint, @mstbud_flag bYN,
		@join varchar(2000), @where varchar(2000), @update varchar(2000),
   		@usermemosql varchar(8000), @errcount smallint

declare @mstrans bTrans, @mstd_batchid bBatchID, @mstd_saledate bDate, @mstd_fromloc bLoc,
		@mstd_saletype varchar(1), @mstd_ticket varchar(10), @mstd_material bMatl, @mstd_um bUM,
		@mstd_customer bCustomer, @mstd_custjob varchar(20), @mstd_custpo varchar(20),
		@mstd_hold bYN, @mstd_jcco bCompany, @mstd_job bJob, @mstd_inco bCompany,
		@mstd_toloc bLoc, @mstd_apref bAPReference, @mstd_msinv varchar(10),
		@mstd_matlapref bAPReference, @inusebatchid bBatchID, @batcherrmsg varchar(100),
		@DetailKeyID bigint, @BatchKeyID bigint

select @rcode = 0, @count=0, @opencursor = 0, @mstbud_flag = 'N', @errcount = 0, @batcherrmsg = null

if @markasdelete='Y'
	begin
	select @batchtranstype='D'
	end
else
	begin
	select @batchtranstype='C'
	end
   

---- call bspUserMemoQueryBuild to create update, join, and where clause
---- pass in source and destination. Remember to use views only unless working
---- with a Viewpoint (bidtek) connection.
exec @rcode = dbo.bspUserMemoQueryBuild @co, @mth, @batchid, 'MSTD', 'MSTB', @mstbud_flag output,
   			@update output, @join output, @where output, @errmsg output
if @rcode <> 0 goto bspexit

---- validate HQ Batch
exec @rcode = dbo.bspHQBatchProcessVal @co, @mth, @batchid, 'MS Tickets', 'MSTB', @errtext output, @status output
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


---- create cursor on MSTD to insert transactions into MSTB
declare bcMSTD cursor LOCAL FAST_FORWARD
	for select MSTrans, BatchId, SaleDate, FromLoc, Ticket,
			SaleType, Material, UM, Customer, CustJob, CustPO, Hold, JCCo, Job,
			INCo, ToLoc, APRef, MSInv, MatlAPRef, InUseBatchId, KeyID
from MSTD where MSCo=@co and Mth=@mth ----and InUseBatchId is null
and HaulTrans is null and Purge <> 'Y'
and SurchargeKeyID IS NULL --ISSUE: #129350

---- open cursor
open bcMSTD
select @opencursor = 1

---- loop through all rows in MSTD cursor and update their info.
ms_posting_loop:
fetch next from bcMSTD into @mstrans, @mstd_batchid, @mstd_saledate, @mstd_fromloc, @mstd_ticket,
				@mstd_saletype, @mstd_material, @mstd_um, @mstd_customer, @mstd_custjob, @mstd_custpo,
				@mstd_hold, @mstd_jcco, @mstd_job, @mstd_inco, @mstd_toloc, @mstd_apref, @mstd_msinv,
				@mstd_matlapref, @inusebatchid, @DetailKeyID

if @@fetch_status <> 0 goto ms_posting_end

if @markasdelete = 'Y'
	begin
	if isnull(@mstd_apref,'') <> '' goto ms_posting_loop
	if isnull(@mstd_msinv,'') <> '' goto ms_posting_loop
	if isnull(@mstd_matlapref,'') <> '' goto ms_posting_loop
	end

if @xtrans is not null 
	begin
	if @xtrans <> @mstrans goto ms_posting_loop
	end

if @xbatchid is not null
	begin
	if @xbatchid <> @mstd_batchid goto ms_posting_loop
	end

----TK-16657
if @inusebatchid is not null
	BEGIN
	IF @inusebatchid <> @batchid
		BEGIN
		select @batcherrmsg = 'Transaction: ' + convert(varchar(8),@mstrans) + ' already in use by Batch Id: ' + convert(varchar(6),@inusebatchid) + '.'
		select @errcount = @errcount + 1
		END
	goto ms_posting_loop
	end

---- range of sale dates
if @check_saledate = 'Y'
	begin
	---- if we have a begin and end range of sale dates must have @mstd_ticket
	if isnull(@saledate,'') <> '' and isnull(@endsaledate,'') <> ''
		begin
		---- begin
		if @mstd_saledate < @saledate goto ms_posting_loop
		---- end
		if @mstd_saledate > @endsaledate goto ms_posting_loop
		end
	else
		begin
		---- begin sale date may be empty
		if isnull(@saledate,'') <> '' and isnull(@mstd_saledate,'') <> ''
			begin
			if @mstd_saledate < @saledate goto ms_posting_loop
			end
		---- end sale date may be empty
		if isnull(@endsaledate,'') <> '' and isnull(@mstd_saledate,'') <> ''
			begin
			if @mstd_saledate > @endsaledate goto ms_posting_loop
			end
		end
	end

if @fromloc is not null
	begin
	if @fromloc <> @mstd_fromloc goto ms_posting_loop
	end

if @material is not null
	begin
	if @material <> @mstd_material goto ms_posting_loop
	end

if @um is not null
	begin
	if @um <> @mstd_um goto ms_posting_loop
	end

if @saletype is not null
	begin
	if @saletype <> @mstd_saletype goto ms_posting_loop
	---- customer

	if @saletype = 'C'
		begin
		if @customer is not null
			begin
			if @customer <> @mstd_customer goto ms_posting_loop
			end
		if @custjob is not null
			begin
			if @custjob <> @mstd_custjob goto ms_posting_loop
			end
		if @custpo is not null
			begin
			if @custpo <> @mstd_custpo goto ms_posting_loop
			end
		if @hold is not null
			begin
			if @hold <> @mstd_hold goto ms_posting_loop
			end
		end

	---- job
	if @saletype = 'J'
		begin
		if @jcco is not null
			begin
			if @jcco <> @mstd_jcco goto ms_posting_loop
			end
		if @job is not null
			begin
			if @job <> @mstd_job goto ms_posting_loop
			end
		end

	---- inventory
	if @saletype = 'I'
		begin
		if @inco is not null
			begin
			if @inco <> @mstd_inco goto ms_posting_loop
			end
		if @toloc is not null
			begin
			if @toloc <> @mstd_toloc goto ms_posting_loop
			end
		end
	end

---- range of tickets
if @check_ticket = 'Y'
	begin
	---- if we have a begin and end range of tickets must have @mstd_ticket
	if isnull(@ticket,'') <> '' and isnull(@endticket,'') <> ''
		begin
		if isnull(@mstd_ticket,'') = '' goto ms_posting_loop
		---- begin
		if @mstd_ticket < @ticket goto ms_posting_loop
		---- end
		if @mstd_ticket > @endticket goto ms_posting_loop
		end
	else
		begin
		---- begin ticket may be empty
		if isnull(@ticket,'') <> '' and isnull(@mstd_ticket,'') <> ''
			begin
			if @mstd_ticket < @ticket goto ms_posting_loop
			end
		---- end ticket may be empty
		if isnull(@endticket,'') <> '' and isnull(@mstd_ticket,'') <> ''
			begin
			if @mstd_ticket > @endticket goto ms_posting_loop
			end
		end
	end



---- get next available sequence # for this batch
select @seq = isnull(max(BatchSeq),0)+1
from MSTB with (nolock)
where Co=@co and Mth=@mth and BatchId=@batchid

---- add MS transaction to batch
insert into bMSTB (Co,Mth,BatchId,BatchSeq,BatchTransType,MSTrans,SaleDate,FromLoc,Ticket,
		VendorGroup,MatlVendor,SaleType,CustGroup,Customer,CustJob,CustPO,PaymentType,CheckNo,
		Hold,JCCo,Job,PhaseGroup,INCo,ToLoc,MatlGroup,Material,UM,MatlPhase,MatlJCCType,GrossWght,
		TareWght,WghtUM,MatlUnits,UnitPrice,ECM,MatlTotal,MatlCost,HaulerType,HaulVendor,Truck,
		Driver,EMCo,Equipment,EMGroup,PRCo,Employee,TruckType,StartTime,StopTime,Loads,Miles,
		Hours,Zone,HaulCode,HaulPhase,HaulJCCType,HaulBasis,HaulRate,HaulTotal,PayCode,PayBasis,
		PayRate,PayTotal,RevCode,RevBasis,RevRate,RevTotal,TaxGroup,TaxCode,TaxType,TaxBasis,TaxTotal,
		DiscBasis,DiscRate,DiscOff,TaxDisc,Void,ShipAddress,City,State,Zip,Country,OldSaleDate,OldTic,OldFromLoc,
		OldVendorGroup,OldMatlVendor,OldSaleType,OldCustGroup,OldCustomer,OldCustJob,OldCustPO,
		OldPaymentType,OldCheckNo,OldHold,OldJCCo,OldJob,OldPhaseGroup,OldINCo,OldToLoc,OldMatlGroup,
		OldMaterial,OldUM,OldMatlPhase,OldMatlJCCType,OldGrossWght,OldTareWght,OldWghtUM,OldMatlUnits,
		OldUnitPrice,OldECM,OldMatlTotal,OldMatlCost,OldHaulerType,OldHaulVendor,OldTruck,OldDriver,
		OldEMCo,OldEquipment,OldEMGroup,OldPRCo,OldEmployee,OldTruckType,OldStartTime,OldStopTime,
		OldLoads,OldMiles,OldHours,OldZone,OldHaulCode,OldHaulPhase,OldHaulJCCType,OldHaulBasis,
		OldHaulRate,OldHaulTotal,OldPayCode,OldPayBasis,OldPayRate,OldPayTotal,OldRevCode,OldRevBasis,
		OldRevRate,OldRevTotal,OldTaxGroup,OldTaxCode,OldTaxType,OldTaxBasis,OldTaxTotal,OldDiscBasis,
		OldDiscRate,OldDiscOff,OldTaxDisc,OldVoid,OldMSInv,OldAPRef,OldVerifyHaul,OldShipAddress,
		OldCity,OldState,OldZip,OldCountry,UniqueAttchID,APCo,APMth,OldAPCo,OldAPMth,
		MatlAPCo,MatlAPMth,MatlAPRef,OldMatlAPCo,OldMatlAPMth,OldMatlAPRef,ReasonCode,OldReasonCode,
		HaulPayTaxType, HaulPayTaxCode, HaulPayTaxRate, HaulPayTaxAmt, 
		OldHaulPayTaxType, OldHaulPayTaxCode, OldHaulPayTaxRate, OldHaulPayTaxAmt)
select @co,@mth,@batchid,@seq,@batchtranstype,MSTrans,SaleDate,FromLoc,Ticket,
		VendorGroup,MatlVendor,SaleType,CustGroup,Customer,CustJob,CustPO,PaymentType,CheckNo,
		Hold,JCCo,Job,PhaseGroup,INCo,ToLoc,MatlGroup,Material,UM,MatlPhase,MatlJCCType,GrossWght,
		TareWght,WghtUM,MatlUnits,UnitPrice,ECM,MatlTotal,MatlCost,HaulerType,HaulVendor,Truck,
		Driver,EMCo,Equipment,EMGroup,PRCo,Employee,TruckType,StartTime,StopTime,Loads,Miles,
		Hours,Zone,HaulCode,HaulPhase,HaulJCCType,HaulBasis,HaulRate,HaulTotal,PayCode,PayBasis,
		PayRate,PayTotal,RevCode,RevBasis,RevRate,RevTotal,TaxGroup,TaxCode,TaxType,TaxBasis,TaxTotal,
		DiscBasis,DiscRate,DiscOff,TaxDisc,Void,ShipAddress,City,State,Zip,Country,SaleDate,Ticket,FromLoc,
		VendorGroup,MatlVendor,SaleType,CustGroup,Customer,CustJob,CustPO,PaymentType,CheckNo,
		Hold,JCCo,Job,PhaseGroup,INCo,ToLoc,MatlGroup,Material,UM,MatlPhase,MatlJCCType,GrossWght,
		TareWght,WghtUM,MatlUnits,UnitPrice,ECM,MatlTotal,MatlCost,HaulerType,HaulVendor,Truck,
		Driver,EMCo,Equipment,EMGroup,PRCo,Employee,TruckType,StartTime,StopTime,Loads,Miles,
		Hours,Zone,HaulCode,HaulPhase,HaulJCCType,HaulBasis,HaulRate,HaulTotal,PayCode,PayBasis,
		PayRate,PayTotal,RevCode,RevBasis,RevRate,RevTotal,TaxGroup,TaxCode,TaxType,TaxBasis,TaxTotal,
		DiscBasis,DiscRate,DiscOff,TaxDisc,Void,MSInv,APRef,VerifyHaul,ShipAddress,City,State,Zip,Country,
		UniqueAttchID,APCo,APMth,APCo,APMth,MatlAPCo,MatlAPMth,MatlAPRef,MatlAPCo,MatlAPMth,MatlAPRef,
		ReasonCode,ReasonCode,HaulPayTaxType, HaulPayTaxCode, HaulPayTaxRate, HaulPayTaxAmt, 
		HaulPayTaxType, HaulPayTaxCode, HaulPayTaxRate, HaulPayTaxAmt
from MSTD with (nolock)
where MSCo = @co and Mth = @mth and MSTrans = @mstrans 
if @@rowcount <> 1
	begin
	select @errmsg = 'Unable to add entry to MS Ticket Entry Batch!', @rcode = 1
	goto bspexit
	end

---------------------------------------
-- PULL ASSOCIATED SURCHARGE RECORDS --
---------------------------------------
-- ISSUE: #129350 --			

-- GET IDENTITY/KeyID FROM THE NEWLY INSERTED RECORD IN MSTB --
SET @BatchKeyID = SCOPE_IDENTITY()	

INSERT INTO bMSSurcharges 
			(Co, Mth, BatchId, BatchSeq, BatchTransType, SurchargeSeq, 
			 SurchargeCode, SurchargeMaterial, UM, SurchargeBasis, SurchargeRate, SurchargeTotal, TaxBasis, 
			 TaxTotal, DiscountOffered, TaxDiscount, MSTBKeyID, MSTDKeyID
			 ----TFS-48687
			 ,APRef, MatlAPRef)
	 SELECT @co, @mth, @batchid, @seq, @batchtranstype, ROW_NUMBER() OVER(PARTITION BY @DetailKeyID ORDER BY KeyID), 
			 SurchargeCode, Material, UM, MatlUnits, UnitPrice, MatlTotal, TaxBasis, 
			 TaxTotal, DiscOff, TaxDisc, @BatchKeyID, KeyID
			 ----TFS-48687
			 ,APRef, MatlAPRef
	   FROM MSTD WITH (NOLOCK)
	  WHERE SurchargeKeyID = @DetailKeyID
	  
---------------------------------------------------
-- UPDATE InUseBatchId FOR ASSOCIATED SURCHARGES --
---------------------------------------------------
-- ISSUE: #129350 --
UPDATE SurchargeRec
   SET SurchargeRec.InUseBatchId = ParentRec.InUseBatchId
  FROM bMSTD SurchargeRec
  JOIN bMSTD ParentRec ON ParentRec.KeyID = SurchargeRec.SurchargeKeyID
 WHERE SurchargeRec.SurchargeKeyID = @DetailKeyID



if @mstbud_flag = 'Y'
	begin
	set @usermemosql = @update + @join + @where + ' and b.MSTrans = ' + convert(varchar(10), @mstrans) + ' and MSTB.MSTrans = ' + convert(varchar(10),@mstrans)
	exec (@usermemosql)
	end

select @count = @count + 1
goto ms_posting_loop


ms_posting_end:
if @count=0
	begin
	select @errmsg = 'No transactions were found to add to batch.', @rcode=1
	if @errcount = 1 and @batcherrmsg is not null
		begin
		select @errmsg = @errmsg + char(13) + char(10) + @batcherrmsg
		goto bspexit
		end
	if @errcount <> 0
		begin
		select @errmsg = @errmsg + char(13) + char(10) + convert(varchar(8),@errcount) + ' transactions could not be added to this batch.'
		end
	end
else
	begin
	select @errmsg = convert(varchar(8),@count) + ' transactions have been added to this batch.'
	if @errcount = 1 and @batcherrmsg is not null
		begin
		select @errmsg = @errmsg + char(13) + char(10) + @batcherrmsg
		goto bspexit
		end
	if @errcount <> 0
		begin
		select @errmsg = @errmsg + char(13) + char(10) + convert(varchar(8),@errcount) + ' transactions could not be added to this batch.'
		end
	end







bspexit:
	if @opencursor = 1
		begin
		close bcMSTD
		deallocate bcMSTD
		end
   
	if @rcode <> 0 select @errmsg = isnull(@errmsg,'')
	return @rcode



GO
GRANT EXECUTE ON  [dbo].[bspMSTBInsertExistingTrans] TO [public]
GO
