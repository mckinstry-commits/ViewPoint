SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/**********************************************************/
CREATE procedure [dbo].[bspMSHaulInit]
/***********************************************************
* Created By:	GG 01/06/01
* Modified By:	GF 09/06/02 - #17909 - added ending location group to restrictions
*				GF 03/25/2003 - issue #20785 added TransMth to bMSWD. Pass @transmth parameter
*								in to use as restriction when initializing MSTD transactions.
*				GF 12/15/2004 - issue #18884 APCo passed in from MSHaulInit insert into bMSWH
*				GF 02/15/2005 - issue #20558 added abiltiy to initialize by cust/custjob, jcco/job, inco/toloc
*				GF 06/18/2007 - issue #123471 check @apref for decimal, if exists do not create new APRef
*				GF 02/04/2008 - issue #120618 use invoice restriction when assigning transaction to existing or new invoice.
*				gf 02/25/2008 - ISSUE #25570 use pay code restriction when assigning transaction to existing or new invoice 
*				GP 08/22/2008 - Issue #129348 added ability to initialize by Vendor Truck.
*				DAN SO 12/24/2008 - Issue #131529 Tech fix for Initializing with a NULL Truck
*				TJL 02/16/09 - #132289 - Add CMAcct in APVM as default and use here.
*				DAN SO 03/11/2009 - Issue #131942 Allow Initialize by a Ticket range.
*				MH 09/11/2011 - B-05901/TK-08135 Support VAT on Hauler Payments
*
*
*
* Called from the MS Hauler Payment Initialization form to
* load the Hauler Payment Worksheet tables (bMSWH and bMSWD)
*
* INPUT PARAMETERS
*   @msco               MS Co#
*   @mth                Batch Month
*   @batchid            Batch ID
*   @xlocgroup          Begin Location Group restriction
*   @xloc               Location restriction
*   @xvendorgroup       Vendor Group restriction
*   @xvendor            Vendor # restriction
*   @xbegindate         Beginning Sale Date restriction
*   @xenddate           Ending Sale Date restriction
*   @invdate            Invoice Date - required
*   @xduedate           Due Date - if null, calculate from Vendor Pay Terms
*   @description        Invoice description - optional
*   @apref              AP Reference - required
*   @paycontrol         Payment Control - optional
*   @holdcode           Hold Code - optional
*   @cmco               CM Co# for payment - optional
*   @cmacct             CM Account for payment - optional
*	@xendlocgroup		End Location group restriction
*	@transmth			Transaction month
*	@apco				AP Company
*	@custgroup			AR Customer Group
*	@customer			AR Customer
*	@custjob			MS Customer/CustJob
*	@jcco				JC Company
*	@job				JC Job
*	@inco				IN Company
*	@toloc				IN Sell to Location
*	@grpbycust			group by customer-custjob flag Y/N
*	@grpbyjob			group by jcco-job flag Y/N
*	@grpbytoloc			group by inco-toloc flag Y/N
*	@paycategory		AP Pay Category
*	@paytype			AP Expense Pay Type
*	@xsaletype			Sale Type
*	@includepayonly		Include only tickets or time sheets with a pay code assigned.
*	@VendorTruck		MS Vendor Truck
*	@TicketRangeYN		Initialize by date range?
*	@TicketBeginNum	    Begin number for Ticket range
*	@TicketEndNum		End number for Ticket range
*
*
* OUTPUT PARAMETERS
*   @msg            success or error message
*
* RETURN VALUE
*   0               success
*   1               fail
*****************************************************/
(@msco bCompany = null, @mth bMonth = null, @batchid bBatchID = null, @xlocgroup bGroup = null,
 @xloc bLoc = null, @xvendorgroup bGroup = null, @xvendor bVendor = null, @xbegindate bDate = null,
 @xenddate bDate = null, @invdate bDate = null, @xduedate bDate = null, @description bDesc = null,
 @apref bAPReference = null, @paycontrol varchar(10) = null, @holdcode bHoldCode = null,
 @cmco bCompany = null, @cmacct bCMAcct = null, @xendlocgroup bGroup = null, @transmth bMonth = null, 
 @apco bCompany = null, @xcustgroup bGroup = null, @xcustomer bCustomer = null, 
 @xcustjob varchar(20) = null, @xjcco bCompany = null, @xjob bJob = null, @xinco bCompany = null,
 @xtoloc bLoc = null, @grpbycust bYN = 'N', @grpbyjob bYN = 'N', @grpbytoloc bYN = 'N',
 @paycategory int = null,@paytype tinyint = null, @xsaletype varchar(1) = 'N', 
 @xendlocation bLoc = null, @includepayonly bYN = 'N', @VendorTruck bTruck = null,  
 @TicketBeginNum bTic = null, @TicketEndNum bTic = null,
 @msg varchar(255) output)

as
set nocount on

declare @rcode int, @invcount int, @transcount int, @status tinyint,
		@openMSTD tinyint, @mstrans bTrans, @fromloc bLoc, @vendorgroup bGroup, @haulvendor bVendor,
		@paycode bPayCode, @paybasis bUnits, @payrate bUnitCost, @paytotal bDollar,@locgroup bGroup,
		@payterms bPayTerms, @rc int, @discrate bPct, @discdate bDate, @duedate bDate, @batchseq int,
		@custgroup bGroup, @customer bCustomer, @custjob varchar(20), @jcco bCompany, @job bJob,
		@inco bCompany, @toloc bLoc, @saletype varchar(1), @ticket varchar(10), @saledate bDate, 
		@truck bTruck, @trucktype varchar(10), @matlgroup bGroup, @material bMatl,
		@newref bAPReference, @apvmcmacct bCMAcct, @apcocmco bCompany, @apcocmacct bCMAcct, 
		@haulpaytaxcode bTaxCode, @haulpaytaxrate bUnitCost, @haulpaytaxamt bDollar, @haulpaytaxtype tinyint,
		@surchargekeyid bigint, @parentHaulPayTaxRate bUnitCost, @parentHaulPayTaxType tinyint, 
		@parentHaulPayTaxCode bTaxCode, @defaultCountry char(2)
		

select @rcode = 0, @invcount = 0, @transcount = 0, @openMSTD = 0


if @xcustjob = '' set @xcustjob = null
if @xjob = '' set @xjob = null
if @xtoloc = '' set @xtoloc = null

---- validate HQ Batch
exec @rcode = bspHQBatchProcessVal @msco, @mth, @batchid, 'MS HaulPay', 'MSWH', @msg output, @status output
if @rcode <> 0 goto bspexit
if @status <> 0     -- must be open
	begin
	select @msg = 'Invalid Batch status - must be Open!', @rcode = 1
	goto bspexit
	end

---- validate AP Reference
if @apref is null
	begin
	select @msg = 'Missing AP Reference!', @rcode = 1
	goto bspexit
	end

---- validate Invoice Date
if @invdate is null
	begin
	select @msg = 'Missing Invoice Date!', @rcode = 1
	goto bspexit
	end

---- validate transaction month
if @transmth is null
	begin
	select @msg = 'Missing transaction month!', @rcode = 1
	goto bspexit
	end

---- validate APCO
if @apco is null
	begin
	select @msg = 'Missing AP Company!', @rcode = 1
	goto bspexit
	end

---- get AP company info
select @apcocmco = CMCo, @apcocmacct = CMAcct
from bAPCO with (nolock) where APCo = @apco

---- use a cursor to cycle through hauler payable detail
declare bcMSTD cursor LOCAL FAST_FORWARD
		for select MSTrans, FromLoc, VendorGroup, HaulVendor, PayCode, PayBasis, PayRate, PayTotal,
		CustGroup, Customer, CustJob, JCCo, Job, INCo, ToLoc, SaleType, Ticket, SaleDate, Truck, 
		TruckType, MatlGroup, Material, HaulPayTaxCode, HaulPayTaxRate, HaulPayTaxAmt, HaulPayTaxType,
		SurchargeKeyID
from bMSTD
where MSCo = @msco and Mth = @transmth
and SaleDate >= isnull(@xbegindate,SaleDate) and SaleDate <= isnull(@xenddate,SaleDate)
and FromLoc >= isnull(@xloc,FromLoc) and FromLoc <= isnull(@xendlocation,FromLoc)
and isnull(Ticket,'') >= isnull(isnull(@TicketBeginNum,Ticket),'') and isnull(Ticket,'') <= isnull(isnull(@TicketEndNum,Ticket),'') -- ISSUE: #131942 --
and VendorGroup = isnull(@xvendorgroup,VendorGroup) and HaulVendor = isnull(@xvendor,HaulVendor)
--and Truck = isnull(@VendorTruck, Truck) -- Issue 129348
and isnull(Truck,'') = isnull(isnull(@VendorTruck,Truck),'') -- Issue 131529 
and HaulerType = 'H' and Void = 'N'       -- must be 'outside hauler' and not void
and APRef is null and InUseBatchId is null  -- not invoiced to AP or in a batch


---- open cursor
open bcMSTD
select @openMSTD = 1

MSTD_loop:
fetch next from bcMSTD into @mstrans, @fromloc, @vendorgroup, @haulvendor, @paycode, @paybasis, @payrate, @paytotal,
	@custgroup, @customer, @custjob, @jcco, @job, @inco, @toloc, @saletype, @ticket, @saledate, @truck,
	@trucktype, @matlgroup, @material, @haulpaytaxcode, @haulpaytaxrate, @haulpaytaxamt, @haulpaytaxtype,
	@surchargekeyid 

if @@fetch_status = -1 goto MSTD_end
if @@fetch_status <> 0 goto MSTD_loop

---- check include pay code only restriction
if @includepayonly = 'Y'
	begin
	if isnull(@paycode,'') = '' goto MSTD_loop
	end

---- check Location Group restriction
select @locgroup = LocGroup
from bINLM with (Nolock) where INCo = @msco and Loc = @fromloc

---- beginning location group restriction
if isnull(@xlocgroup,0) > 0
	begin
	if @locgroup < @xlocgroup goto MSTD_loop
	end

---- ending location group restriction
if isnull(@xendlocgroup,0) > 0
	begin
	if @locgroup > @xendlocgroup goto MSTD_loop
	end

---- check sale type restriction
if @xsaletype <> 'N'
	begin
	---- match sale type restriction to MSTD.SaleType
	if @saletype <> @xsaletype goto MSTD_loop

	---- customer sale type restriction
	if @saletype = 'C' -- -- -- and @xcustomer is not null
		begin
		if @customer <> isnull(@xcustomer,@customer) goto MSTD_loop
		if @custjob <> isnull(@xcustjob,@custjob) goto MSTD_loop
		end

	----  job sale type restriction
	if @saletype = 'J' -- -- -- and @xjcco is not null
		begin
		if @jcco <> isnull(@xjcco,@jcco) goto MSTD_loop
		if @job <> isnull(@xjob,@job) goto MSTD_loop
		end

	---- sell to location sale type restriction
	if @saletype = 'I' -- -- -- and @xinco is not null
		begin
		if @inco <> isnull(@xinco,@inco) goto MSTD_loop
		if @toloc <> isnull(@xtoloc,@toloc) goto MSTD_loop
		end
	end

---- get Vendor Pay Terms
select @payterms = null, @duedate = @xduedate   -- use input Due Date if provided
select @payterms = PayTerms, @apvmcmacct = CMAcct
from bAPVM with (Nolock) where VendorGroup = @vendorgroup and Vendor = @haulvendor
if @duedate is null
	begin
	---- determine Due Date based on Vendor's Payment Terms and Invoice date
	exec @rc = dbo.bspHQPayTermsDateCalc @payterms, @invdate, @discdate output, @duedate output, @discrate output, @msg output
	if @rc <> 0 select @duedate = @invdate  -- use Invoice Date if error
	end

---- generate next AP Reference
set @newref = null
---- if @apref has a decimal ignore
if charindex('.', @apref) = 0
	begin
	exec @rc = dbo.bspMSAPRefCreate @msco, @mth, @batchid, @apref, 'MS HaulPay', @newref output, @msg output
	end
if isnull(@newref,'') = '' set @newref = @apref

---- check for existing worksheet header, can vary depending on whether group by customer-job
---- or jcco-job or neither. Standard check is one entry per vendor, invoice date, and invoice description.
---- check by customer-custjob
if @grpbycust = 'Y' and @saletype = 'C'
	begin
	select @batchseq = BatchSeq
	from bMSWH with (nolock)
	where Co=@msco and Mth=@mth and BatchId=@batchid and VendorGroup=@vendorgroup 
	and HaulVendor=@haulvendor and InvDate=@invdate and APCo=@apco
	---- issue #120618
	and isnull(InvDescription,'')=isnull(@description,'')
	and Customer=isnull(@customer,Customer) and isnull(CustJob,'')=isnull(@custjob,isnull(CustJob,''))
	if @@rowcount = 0
		begin
		---- get next Batch Sequence #
		select @batchseq = isnull(max(BatchSeq),0) + 1
		from bMSWH with (Nolock) where Co = @msco and Mth = @mth and BatchId = @batchid
		---- add Worksheet Header
		insert bMSWH(Co, Mth, BatchId, BatchSeq, VendorGroup, HaulVendor, APRef, InvDate, InvDescription,
			PayTerms, DueDate, HoldCode, PayControl, CMCo, CMAcct, APCo, SalesTypeRstrct, CustGroup,
			Customer, CustJob, JCCo, Job, INCo, ToLoc, PayCategory, PayType, DiscDate)
		values(@msco, @mth, @batchid, @batchseq, @vendorgroup, @haulvendor, @newref, @invdate, @description,
			@payterms, @duedate, @holdcode, @paycontrol, isnull(@cmco, @apcocmco), isnull(@cmacct, isnull(@apvmcmacct, @apcocmacct)), @apco, 'C', @custgroup,
			@customer, @custjob, null, null, null, null, @paycategory, @paytype, null)

		select @invcount = @invcount + 1    -- # of new Worksheet headers
		end
	goto bMSWD_insert
	end

---- group by JCCo-Job
if @grpbyjob = 'Y' and @saletype = 'J'
	begin
	select @batchseq = BatchSeq
	from bMSWH with (nolock)
	where Co=@msco and Mth=@mth and BatchId=@batchid and VendorGroup=@vendorgroup 
	and HaulVendor=@haulvendor and InvDate=@invdate and APCo=@apco
	---- issue #120618
	and isnull(InvDescription,'')=isnull(@description,'')
	and JCCo = isnull(@jcco, JCCo) and Job = isnull(@job, Job)
	if @@rowcount = 0
		begin
		---- get next Batch Sequence #
		select @batchseq = isnull(max(BatchSeq),0) + 1
		from bMSWH with (Nolock) where Co = @msco and Mth = @mth and BatchId = @batchid
		---- add Worksheet Header
		insert bMSWH(Co, Mth, BatchId, BatchSeq, VendorGroup, HaulVendor, APRef, InvDate, InvDescription,
		PayTerms, DueDate, HoldCode, PayControl, CMCo, CMAcct, APCo, SalesTypeRstrct, CustGroup,
		Customer, CustJob, JCCo, Job, INCo, ToLoc, PayCategory, PayType, DiscDate)
		values(@msco, @mth, @batchid, @batchseq, @vendorgroup, @haulvendor, @newref, @invdate, @description,
		@payterms, @duedate, @holdcode, @paycontrol, isnull(@cmco, @apcocmco), isnull(@cmacct, isnull(@apvmcmacct, @apcocmacct)), @apco, 'J', null,
		null, null, @jcco, @job, null, null, @paycategory, @paytype, null)

		select @invcount = @invcount + 1    -- # of new Worksheet headers
		end
	goto bMSWD_insert
	end

---- group by INCo-ToLoc
if @grpbytoloc = 'Y' and @saletype = 'I'
	begin
	select @batchseq = BatchSeq
	from bMSWH with (nolock)
	where Co=@msco and Mth=@mth and BatchId=@batchid and VendorGroup=@vendorgroup 
	and HaulVendor=@haulvendor and InvDate=@invdate and APCo=@apco
	---- issue #120618
	and isnull(InvDescription,'')=isnull(@description,'')
	and INCo = isnull(@inco, INCo) and ToLoc = isnull(@toloc, ToLoc)
	if @@rowcount = 0
		begin
		---- get next Batch Sequence #
		select @batchseq = isnull(max(BatchSeq),0) + 1
		from bMSWH with (Nolock) where Co = @msco and Mth = @mth and BatchId = @batchid
		---- add Worksheet Header
		insert bMSWH(Co, Mth, BatchId, BatchSeq, VendorGroup, HaulVendor, APRef, InvDate, InvDescription,
		PayTerms, DueDate, HoldCode, PayControl, CMCo, CMAcct, APCo, SalesTypeRstrct, CustGroup,
		Customer, CustJob, JCCo, Job, INCo, ToLoc, PayCategory, PayType, DiscDate)
		values(@msco, @mth, @batchid, @batchseq, @vendorgroup, @haulvendor, @newref, @invdate, @description,
		@payterms, @duedate, @holdcode, @paycontrol, isnull(@cmco, @apcocmco), isnull(@cmacct, isnull(@apvmcmacct, @apcocmacct)), @apco, 'I', null,
		null, null, null, null, @inco, @toloc, @paycategory, @paytype, null)

		select @invcount = @invcount + 1    -- # of new Worksheet headers
		end
	goto bMSWD_insert
	end


---- check for one entry per vendor, invoice date, APCo, and invoice description
select @batchseq = BatchSeq
from bMSWH with (Nolock) 
where Co=@msco and Mth=@mth and BatchId=@batchid and VendorGroup=@vendorgroup
and HaulVendor=@haulvendor and InvDate=@invdate and APCo=@apco
---- issue #120618
and isnull(InvDescription,'')=isnull(@description,'')
and Customer is null and CustJob is null and JCCo is null and Job is null and INCo is null and ToLoc is null
if @@rowcount = 0
	begin
	---- get next Batch Sequence #
	select @batchseq = isnull(max(BatchSeq),0) + 1
	from bMSWH with (Nolock) where Co = @msco and Mth = @mth and BatchId = @batchid
	---- add worksheet header
	insert bMSWH(Co, Mth, BatchId, BatchSeq, VendorGroup, HaulVendor, APRef, InvDate, InvDescription,
	PayTerms, DueDate, HoldCode, PayControl, CMCo, CMAcct, APCo, SalesTypeRstrct, CustGroup,
	Customer, CustJob, JCCo, Job, INCo, ToLoc, PayCategory, PayType, DiscDate)
	values(@msco, @mth, @batchid, @batchseq, @vendorgroup, @haulvendor, @newref, @invdate, @description,
	@payterms, @duedate, @holdcode, @paycontrol, isnull(@cmco, @apcocmco), isnull(@cmacct, isnull(@apvmcmacct, @apcocmacct)), @apco, 'N', null,
	null, null, null, null, null, null, @paycategory, @paytype, null)

	select @invcount = @invcount + 1    -- # of new Worksheet headers
	end


bMSWD_insert:

--B-05901/TK-08135.  If we have a surcharge will need to calculate the VAT tax on it.  Use
--the tax code from the Ticket.  User can override it in Haul Payment Worksheet.
SELECT @defaultCountry = ISNULL(DefaultCountry, 'US') FROM HQCO WHERE HQCo = @msco

IF @defaultCountry <> 'US' and @surchargekeyid is not null
BEGIN
	--Check for a surcharge.  If so, we will need to calculate a VAT tax on it of the
	--Haul Payment was taxable
	SELECT @parentHaulPayTaxType = HaulPayTaxType, @parentHaulPayTaxCode = HaulPayTaxCode, 
	@parentHaulPayTaxRate = HaulPayTaxRate
	FROM bMSTD WHERE KeyID = @surchargekeyid
	
	SELECT @haulpaytaxamt = (@paytotal * isnull(@parentHaulPayTaxRate, 0)) 
	SELECT @haulpaytaxtype = @parentHaulPayTaxType, @haulpaytaxcode = @parentHaulPayTaxCode, 
	@haulpaytaxrate = @parentHaulPayTaxRate
END



---- add Worksheet Detail - insert trigger on bMSWD will lock bMSTD entry
insert bMSWD(Co, Mth, BatchId, BatchSeq, TransMth, MSTrans, PayCode, PayBasis, PayRate, PayTotal,
		UniqueAttchID, Ticket, SaleDate, Truck, TruckType, FromLoc, MatlGroup, Material,
		HaulPayTaxCode, HaulPayTaxRate, HaulPayTaxAmt, HaulPayTaxType)
values(@msco, @mth, @batchid, @batchseq, @transmth, @mstrans, @paycode, @paybasis, @payrate, @paytotal,
		null, @ticket, @saledate, @truck, @trucktype, @fromloc, @matlgroup, @material,
		@haulpaytaxcode, @haulpaytaxrate, @haulpaytaxamt, @haulpaytaxtype)

select @transcount = @transcount + 1    -- # of transactions

goto MSTD_loop  -- next transaction


MSTD_end:	    -- no more rows to process
	close bcMSTD
	deallocate bcMSTD
	select @openMSTD = 0


bspexit:
	if @openMSTD = 1
		begin
		close bcMSTD
		deallocate bcMSTD
		end

	if @rcode = 0 select @msg = 'Created ' + isnull(convert(varchar(6),@invcount),'') + ' new Hauler Worksheet entries, covering '
			+ isnull(convert(varchar(8),@transcount),'') + ' payable transactions.'

	if @rcode <> 0 select @msg = isnull(@msg,'')
	return @rcode





GO
GRANT EXECUTE ON  [dbo].[bspMSHaulInit] TO [public]
GO
