SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**********************************************************/
CREATE  procedure [dbo].[bspMSMatlPayInit]
/***********************************************************
* Created By:	GF 02/23/2005
* Modified By:	GF 06/18/2007 - issue #123471 check @apref for decimal, if exists do not create new APRef
*				GF 10/29/2007 - issue #122769 - allow tickets with zero units to be added.
*				GF 12/18/2007 - issue #126509 for tickets with zero units, set total cost = material total.
*				GF 02/04/2008 - issue #120618 use invoice restriction when assigning transaction to existing or new invoice.
*				GP 06/25/2008 - issue #127986 added call to bspMSTicTemplateGet to retrieve @quote, also added @quote
*									input to bspMSMatlPayUnitCostGet call. Also added @phasegroup & @matlphase to
*									bMSTD cursor, passed values into SP.
*				GF 07/15/2008 - issue #128458 international GST/PST added tax type to MSMT set to '1' or '3'
*				TJL 02/16/09 - #132289 - Add CMAcct in APVM as default and use here.
*				MH 02/10/2010 - #143319 - Added customer group to MSMH insert.  See issue number comment tag below.
*				DAN SO 03/01/2012 - TK-12904/#145689 - Added customer group for Job and Inventory Types 
*
*
*
*
* Called from the MS Material Vendor Payment Initialization form to
* load the Material Vendor Payment Worksheet tables (bMSMH and bMSMD)
*  
* The tax group will come from the AP Company passed in as a parameter.
*
*
* INPUT PARAMETERS
*   @msco               MS Co#
*   @mth                Batch Month
*   @batchid            Batch ID
*   @xlocgroup          Begin Location Group restriction
*	@xendlocgroup		End Location group restriction
*   @xloc               Begin Location restriction
*	@xendloc			End Location restriction
*   @xvendorgroup       Vendor Group restriction
*   @xvendor            Vendor # restriction
*	@xmatlcategory		Material Category restriction
*	@xmatl				Begin Material restriction
*	@xendmatl			End Material restriction
*	@xsaletype			Sale Type restriction
*	@xcustgroup			AR Customer Group
*	@xcustomer			AR Customer
*	@xcustjob			MS Customer/CustJob
*	@xjcco				JC Company
*	@xjob				JC Job
*	@xinco				IN Company
*	@xtoloc				IN Sell to Location
*	@transmth			Transaction month
*   @xbegindate         Beginning Sale Date restriction
*   @xenddate           Ending Sale Date restriction
*	@custcostoption		customer sale cost option
*	@custtaxoption		customer sale tax option
*	@custtaxadjust		customer sale tax adjust flag bYN
*	@jobcostoption		job sale cost option
*	@jobtaxoption		job sale tax option
*	@jobtaxadjust		job sale tax adjust flag bYN
*	@invcostoption		inventory sale cost option
*	@invtaxoption		inventory sale tax option
*	@invtaxadjust		inventory sale tax adjust flag bYN
*	@apco				AP Company
*   @invdate            Invoice Date - required
*   @xduedate           Due Date - if null, calculate from Vendor Pay Terms
*   @description        Invoice description - optional
*   @apref              AP Reference - required
*   @paycontrol         Payment Control - optional
*   @holdcode           Hold Code - optional
*   @cmco               CM Co# for payment - optional
*   @cmacct             CM Account for payment - optional
*	@grpbycust			group by customer-custjob flag Y/N
*	@grpbyjob			group by jcco-job flag Y/N
*	@grpbytoloc			group by inco-toloc flag Y/N
*	@paycategory		AP Pay Category
*	@paytype			AP Expense Pay Type
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
 @xendlocgroup bGroup = null, @xloc bLoc = null, @xendloc bLoc = null, @xvendorgroup bGroup = null,
 @xvendor bVendor = null, @xmatlcat varchar(10) = null, @xmatl bMatl = null, @xendmatl bMatl = null,
 @xsaletype varchar(1) = 'N', @xcustgroup bGroup = null, @xcustomer bCustomer = null,
 @xcustjob varchar(20) = null, @xjcco bCompany = null, @xjob bJob = null, @xinco bCompany = null,
 @xtoloc bLoc = null, @transmth bMonth = null, @xbegindate bDate = null, @xenddate bDate = null,
 @custcostoption tinyint = null, @custtaxoption tinyint = null, @custtaxadjust bYN = 'N',
 @jobcostoption tinyint = null, @jobtaxoption tinyint = null, @jobtaxadjust bYN = 'N',
 @invcostoption tinyint = null, @invtaxoption tinyint = null, @invtaxadjust bYN = 'N',
 @apco bCompany = null, @invdate bDate = null, @xduedate bDate = null, @description bDesc = null,
 @apref bAPReference = null, @paycontrol varchar(10) = null, @holdcode bHoldCode = null,
 @cmco bCompany = null, @cmacct bCMAcct = null, @grpbycust bYN = 'N', @grpbyjob bYN = 'N',
 @grpbytoloc bYN = 'N', @paycategory int = null,@paytype tinyint = null,  
 @msg varchar(255) output)
as
set nocount on

declare @rcode int, @retcode int, @errmsg varchar(255), @invcount int, @transcount int, @status tinyint,
		@openMSTD tinyint, @mstrans bTrans, @fromloc bLoc, @vendorgroup bGroup, @matlvendor bVendor, 
		@locgroup bGroup, @payterms bPayTerms, @rc int, @discrate bPct, @discdate bDate, @duedate bDate, 
		@batchseq int, @custgroup bGroup, @customer bCustomer, @custjob varchar(20), @jcco bCompany, 
		@job bJob, @inco bCompany, @toloc bLoc, @saletype varchar(1), @ticket varchar(10), @saledate bDate, 
		@matlgroup bGroup, @material bMatl, @category varchar(10), @um bUM, @matlunits bUnits,
		@unitprice bUnitCost, @pecm bECM, @unitcost bUnitCost, @ecm bECM, @totalcost bDollar,
		@factor smallint, @taxgroup bGroup, @taxcode bTaxCode, @taxbasis bDollar, @taxamt bDollar,
		@taxable bYN, @actualunitcost bUnitCost, @newref bAPReference, @matltotal bDollar,
		@phasegroup bGroup, @matlphase bPhase, @taxtype tinyint, @country varchar(2),
		@valueadd varchar(1), @apvmcmacct bCMAcct, @apcocmco bCompany, @apcocmacct bCMAcct

-- Declare parameters to get quote - Issue 127986
declare @custpo varchar(20), @quote varchar(10), @disctemplate smallint,
		@pricetemplate smallint, @zone varchar(10), @haultaxopt tinyint, @matldisc bYN, @discopt tinyint

select @rcode = 0, @invcount = 0, @transcount = 0, @openMSTD = 0

if @xcustjob = '' set @xcustjob = null
if @xjob = '' set @xjob = null
if @xtoloc = '' set @xtoloc = null

---- validate HQ Batch
exec @rcode = bspHQBatchProcessVal @msco, @mth, @batchid, 'MS MatlPay', 'MSMH', @msg output, @status output
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

---- get country code
select @country=isnull(Country,DefaultCountry)
from bHQCO with (nolock) where HQCo = @msco
if @@rowcount = 0 select @country = 'US'

---- get AP company info
select @apcocmco = CMCo, @apcocmacct = CMAcct
from bAPCO with (nolock) where APCo = @apco

---- use a cursor to cycle through material vendor ticket detail
declare bcMSTD cursor LOCAL FAST_FORWARD
	for select MSTrans, SaleDate, FromLoc, VendorGroup, MatlVendor, SaleType, CustGroup, 
			Customer, CustJob, JCCo, Job, PhaseGroup, INCo, ToLoc, Ticket, MatlGroup, Material, UM,
			MatlPhase, MatlUnits, UnitPrice, ECM, MatlTotal
from bMSTD
where MSCo = @msco and Mth = @transmth
and MatlVendor is not null ----and MatlUnits <> 0
and SaleDate >= isnull(@xbegindate,SaleDate) and SaleDate <= isnull(@xenddate,SaleDate)
and FromLoc >= isnull(@xloc,FromLoc) and FromLoc <= isnull(@xendloc,FromLoc)
and VendorGroup = isnull(@xvendorgroup,VendorGroup) and MatlVendor = isnull(@xvendor,MatlVendor)
and Material >= isnull(@xmatl,Material) and Material <= isnull(@xendmatl,Material)
and Void = 'N'       -- must not be void
and MatlAPRef is null and InUseBatchId is null  -- not invoiced to AP or in a batch

---- open cursor
open bcMSTD
select @openMSTD = 1

MSTD_loop:
fetch next from bcMSTD into @mstrans, @saledate, @fromloc, @vendorgroup, @matlvendor, @saletype, @custgroup,
		@customer, @custjob, @jcco, @job, @phasegroup, @inco, @toloc, @ticket, @matlgroup, @material, @um,
		@matlphase, @matlunits, @unitprice, @pecm, @matltotal

if @@fetch_status = -1 goto MSTD_end
if @@fetch_status <> 0 goto MSTD_loop

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

---- check material category restriction
select @category = Category
from bHQMT with (nolock) where MatlGroup=@matlgroup and Material=@material

---- category restriction
if isnull(@xmatlcat,'') <> ''
	begin
	if @category <> @xmatlcat goto MSTD_loop
	end

---- check sale type restriction
if @xsaletype <> 'N'
   	begin
   	---- match sale type restriction to MSTD.SaleType
   	if @saletype <> @xsaletype goto MSTD_loop
   
   	---- customer sale type restriction
   	if @saletype = 'C' ---- and @xcustomer is not null
   		begin
   		if @customer <> isnull(@xcustomer,@customer) goto MSTD_loop
   		if @custjob <> isnull(@xcustjob,@custjob) goto MSTD_loop
   		end
   	
   	---- job sale type restriction
   	if @saletype = 'J' ---- and @xjcco is not null
   		begin
   		if @jcco <> isnull(@xjcco,@jcco) goto MSTD_loop
   		if @job <> isnull(@xjob,@job) goto MSTD_loop
   		end
   
   	---- sell to location sale type restriction
   	if @saletype = 'I' ---- and @xinco is not null
   		begin
   		if @inco <> isnull(@xinco,@inco) goto MSTD_loop
   		if @toloc <> isnull(@xtoloc,@toloc) goto MSTD_loop
   		end
   	end


---- HQMT material info
select @taxable=Taxable
from bHQMT with (nolock) where MatlGroup=@matlgroup and Material=@material
if @@rowcount = 0 set @taxable = 'N'

---- get tax group
select @taxgroup = TaxGroup
from bHQCO with (nolock) where HQCo=@apco
if @@rowcount = 0 set @taxgroup = null

-- Get default quote - Issue 127986
exec @retcode = dbo.bspMSTicTemplateGet @msco, @saletype, @custgroup, @customer, @custjob, @custpo,
				@jcco, @job, @inco, @toloc, @fromloc, @quote output, @disctemplate output, @pricetemplate output, 
				@zone output, @haultaxopt output, @taxcode output, @payterms output, @matldisc output, 
				@discrate output, @discopt output, @msg output

---- call material vendor payment unit cost get SP to return MSMT values
---- this SP is shared with material vendor payment detail manuall adding
---- of transactions. So if need to change, do in both SP's. Parameters
---- are slightly different depending on sale type.
if @saletype = 'C'
   	exec @retcode = dbo.bspMSMatlPayUnitCostGet @msco, @apco, @taxgroup, @custcostoption, @custtaxoption,
   					@custtaxadjust, @vendorgroup, @matlvendor, @matlgroup, @material, @um, @taxable,
   					@saletype, @saledate, @fromloc, @custgroup, @customer, null, null, null, null,
   					@matlunits, @unitprice, @pecm, @quote, @phasegroup, @matlphase, 
					@unitcost output, @ecm output, @totalcost output,
   					@taxcode output, @taxbasis output, @taxamt output, @actualunitcost output, @errmsg output

if @saletype = 'J'
   	exec @retcode = dbo.bspMSMatlPayUnitCostGet @msco, @apco, @taxgroup, @jobcostoption, @jobtaxoption,
   					@jobtaxadjust, @vendorgroup, @matlvendor, @matlgroup, @material, @um, @taxable,
   					@saletype, @saledate, @fromloc, null, null, @jcco, @job, null, null,
   					@matlunits, @unitprice, @pecm, @quote, @phasegroup, @matlphase,
					@unitcost output, @ecm output, @totalcost output,
   					@taxcode output, @taxbasis output, @taxamt output, @actualunitcost output, @errmsg output

if @saletype = 'I'
   	exec @retcode = dbo.bspMSMatlPayUnitCostGet @msco, @apco, @taxgroup, @invcostoption, @invtaxoption,
   					@invtaxadjust, @vendorgroup, @matlvendor, @matlgroup, @material, @um, @taxable,
   					@saletype, @saledate, @fromloc, null, null, null, null, @inco, @toloc,
   					@matlunits, @unitprice, @pecm, @quote, @phasegroup, @matlphase, 
					@unitcost output, @ecm output, @totalcost output,
   					@taxcode output, @taxbasis output, @taxamt output, @actualunitcost output, @errmsg output

if @retcode <> 0
   	begin
   	select @unitcost = 0, @ecm = 'E', @totalcost = 0, @taxcode = null, @taxbasis = 0, @taxamt = 0
   	end

---- get Vendor Pay Terms
select @payterms = null, @duedate = @xduedate   -- use input Due Date if provided
select @payterms = PayTerms, @apvmcmacct = CMAcct
from bAPVM with (Nolock) where VendorGroup = @vendorgroup and Vendor = @matlvendor
if @duedate is null
   	begin
   	---- determine Due Date based on Vendor's Payment Terms and Invoice date
   	exec @retcode = bspHQPayTermsDateCalc @payterms, @invdate, @discdate output, @duedate output, @discrate output, @errmsg output
   	if @retcode <> 0 select @duedate = @invdate  -- use Invoice Date if error
   	end


---- generate next AP Reference
set @newref = null
---- if @apref has a decimal ignore
if charindex('.', @apref) = 0
	begin
	exec @rc = dbo.bspMSAPRefCreate @msco, @mth, @batchid, @apref, 'MS MatlPay', @newref output, @msg output
	end
if isnull(@newref,'') = '' set @newref = @apref

---- #126509 when zero material units set @totalcost = @materialtotal
if @matlunits = 0
	begin
	select @unitcost = 0, @ecm = 'E', @totalcost = @matltotal
	end

---- #128458 set the tax type for the tax code
select @taxtype = null
if @taxcode is not null and @taxgroup is not null
	begin
	select @taxtype = 1
	select @valueadd=ValueAdd from bHQTX where TaxGroup=@taxgroup and TaxCode=@taxcode
	if isnull(@valueadd,'N') = 'Y' select @taxtype = 3
	end

---- check for existing worksheet header, can vary depending on whether group by customer-job
---- or jcco-job or neither. Standard check is one entry per vendor, invoice date, and invoice description.
---- check by customer-custjob
InvoiceGroupBy:
if @grpbycust = 'Y' and @saletype = 'C'
   	begin
   	select @batchseq = BatchSeq
   	from bMSMH with (nolock)
   	where Co=@msco and Mth=@mth and BatchId=@batchid and VendorGroup=@vendorgroup
   	and MatlVendor=@matlvendor and InvDate=@invdate and APCo=@apco
	---- #120618
	and isnull(InvDescription,'')=isnull(@description,'')
	and Customer = isnull(@customer, Customer) and isnull(CustJob,'') = isnull(@custjob, isnull(CustJob,''))
   	if @@rowcount = 0
   		begin
   		---- get next Batch Sequence #
   		select @batchseq = isnull(max(BatchSeq),0) + 1
   		from bMSMH with (Nolock) where Co = @msco and Mth = @mth and BatchId = @batchid
   		---- add Worksheet Header
   		insert bMSMH(Co, Mth, BatchId, BatchSeq, VendorGroup, MatlVendor, APRef, InvDate, InvDescription,
               	PayTerms, DueDate, HoldCode, PayControl, CMCo, 
               	CMAcct, APCo, SalesTypeRstrct, CustGroup,
   				Customer, CustJob, JCCo, Job, INCo, ToLoc, PayCategory, PayType, DiscDate)
   		values(@msco, @mth, @batchid, @batchseq, @vendorgroup, @matlvendor, @newref, @invdate, @description,
               	@payterms, @duedate, @holdcode, @paycontrol, isnull(@cmco, @apcocmco), 
               	isnull(@cmacct, isnull(@apvmcmacct, @apcocmacct)), @apco, 'C', @custgroup,
   				@customer, @custjob, null, null, null, null, @paycategory, @paytype, null)
   
   		select @invcount = @invcount + 1    -- # of new Worksheet headers
   		end
   	goto bMSMT_insert
   	end


---- group by JCCo-Job
if @grpbyjob = 'Y' and @saletype = 'J'
   	begin
   	select @batchseq = BatchSeq
   	from bMSMH with (nolock)
   	where Co=@msco and Mth=@mth and BatchId=@batchid and VendorGroup=@vendorgroup 
   	and MatlVendor=@matlvendor and InvDate=@invdate and APCo=@apco
	---- #120618
	and isnull(InvDescription,'')=isnull(@description,'')
	and JCCo = isnull(@jcco, JCCo) and Job = isnull(@job, Job)
   	if @@rowcount = 0
   		begin
   		---- get next Batch Sequence #
   		select @batchseq = isnull(max(BatchSeq),0) + 1
   		from bMSMH with (Nolock) where Co = @msco and Mth = @mth and BatchId = @batchid
   
   		---- add Worksheet Header
   		insert bMSMH(Co, Mth, BatchId, BatchSeq, VendorGroup, MatlVendor, APRef, InvDate, InvDescription,
               	PayTerms, DueDate, HoldCode, PayControl, CMCo, 
               	CMAcct, APCo, SalesTypeRstrct, CustGroup,
   				Customer, CustJob, JCCo, Job, INCo, ToLoc, PayCategory, PayType, DiscDate)
   		values(@msco, @mth, @batchid, @batchseq, @vendorgroup, @matlvendor, @newref, @invdate, @description,
               	@payterms, @duedate, @holdcode, @paycontrol, isnull(@cmco, @apcocmco),
               	-- TK-12904/#145689 -- 
               	isnull(@cmacct, isnull(@apvmcmacct, @apcocmacct)), @apco, 'J', @custgroup,
   				null, null, @jcco, @job, null, null, @paycategory, @paytype, null)
   
   		select @invcount = @invcount + 1    -- # of new Worksheet headers
   		end
   	goto bMSMT_insert
   	end


---- group by INCo-ToLoc
if @grpbytoloc = 'Y' and @saletype = 'I'
   	begin
   	select @batchseq = BatchSeq
   	from bMSMH with (nolock)
   	where Co=@msco and Mth=@mth and BatchId=@batchid and VendorGroup=@vendorgroup 
   	and MatlVendor=@matlvendor and InvDate=@invdate and APCo=@apco
	---- #120618
	and isnull(InvDescription,'')=isnull(@description,'')
	and INCo = isnull(@inco, INCo) and ToLoc = isnull(@toloc, ToLoc)
   	if @@rowcount = 0
   		begin
   		---- get next Batch Sequence #
   		select @batchseq = isnull(max(BatchSeq),0) + 1
   		from bMSMH with (Nolock) where Co = @msco and Mth = @mth and BatchId = @batchid
   		---- add Worksheet Header
   		insert bMSMH(Co, Mth, BatchId, BatchSeq, VendorGroup, MatlVendor, APRef, InvDate, InvDescription,
               	PayTerms, DueDate, HoldCode, PayControl, CMCo, 
               	CMAcct, APCo, SalesTypeRstrct, CustGroup,
   				Customer, CustJob, JCCo, Job, INCo, ToLoc, PayCategory, PayType, DiscDate)
   		values(@msco, @mth, @batchid, @batchseq, @vendorgroup, @matlvendor, @newref, @invdate, @description,
               	@payterms, @duedate, @holdcode, @paycontrol, isnull(@cmco, @apcocmco), 
               	-- TK-12904/#145689 --
               	isnull(@cmacct, isnull(@apvmcmacct, @apcocmacct)), @apco, 'I', @custgroup,
   				null, null, null, null, @inco, @toloc, @paycategory, @paytype, null)
   
   		select @invcount = @invcount + 1    -- # of new Worksheet headers
   		end
   	goto bMSMT_insert
   	end


---- check for one entry per vendor, invoice date, APCo, and invoice description
select @batchseq = BatchSeq
from bMSMH with (Nolock) 
where Co=@msco and Mth=@mth and BatchId=@batchid and VendorGroup=@vendorgroup
and MatlVendor=@matlvendor and InvDate=@invdate and APCo=@apco
---- #120618
and isnull(InvDescription,'')=isnull(@description,'')
and Customer is null and CustJob is null and JCCo is null and Job is null and INCo is null and ToLoc is null
if @@rowcount = 0
   	begin
   	---- get next Batch Sequence #
   	select @batchseq = isnull(max(BatchSeq),0) + 1
   	from bMSMH with (Nolock) where Co = @msco and Mth = @mth and BatchId = @batchid
   	---- add worksheet header
   	--Issue 143319 - Include @custgroup in insert.
   	insert bMSMH(Co, Mth, BatchId, BatchSeq, VendorGroup, MatlVendor, APRef, InvDate, InvDescription,
   	            PayTerms, DueDate, HoldCode, PayControl, CMCo, 
   	            CMAcct, APCo, SalesTypeRstrct, CustGroup,
   				Customer, CustJob, JCCo, Job, INCo, ToLoc, PayCategory, PayType, DiscDate)
   	values(@msco, @mth, @batchid, @batchseq, @vendorgroup, @matlvendor, @newref, @invdate, @description,
   	            @payterms, @duedate, @holdcode, @paycontrol, isnull(@cmco, @apcocmco), 
   	            isnull(@cmacct, isnull(@apvmcmacct, @apcocmacct)), @apco, 'N', @custgroup,
   				null, null, null, null, null, null, @paycategory, @paytype, null)
   	
   	select @invcount = @invcount + 1    ---- # of new Worksheet headers
   	end



bMSMT_insert:
---- add Worksheet Detail - insert trigger on bMSWMT will lock bMSTD entry
insert bMSMT(Co, Mth, BatchId, BatchSeq, TransMth, MSTrans, FromLoc, Ticket, SaleDate, MatlGroup,
   		Material, UM, Units, UnitPrice, PECM, UnitCost, ECM, TotalCost, TaxGroup, TaxCode,
   		TaxBasis, TaxAmt, UniqueAttchID, TaxType)
values(@msco, @mth, @batchid, @batchseq, @transmth, @mstrans, @fromloc, @ticket, @saledate, @matlgroup,
   		@material, @um, @matlunits, @unitprice, @pecm, @unitcost, @ecm, @totalcost, @taxgroup, @taxcode, 
   		@taxbasis, @taxamt, null, @taxtype)

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
   
	if @rcode = 0 select @msg = 'Created ' + isnull(convert(varchar(6),@invcount),'') + ' new Material Vendor Worksheet entries, covering '
					+ isnull(convert(varchar(8),@transcount),'') + ' payable transactions.'

	if @rcode <> 0 select @msg = isnull(@msg,'')
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspMSMatlPayInit] TO [public]
GO
