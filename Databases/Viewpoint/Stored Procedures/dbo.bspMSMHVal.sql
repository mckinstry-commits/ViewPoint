SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**********************************************************/
CREATE   procedure [dbo].[bspMSMHVal]
/***********************************************************
* Created By:	GF 02/24/2005
* Modified By:	GF 07/15/2008 - issue #128458 international GST/PST added tax type to MSMT
*				DAN SO 12/02/2008 - Issue: #130168 AP Entry Line for $0 transactions
*				MV 02/04/10 - #136500 bspHQTaxRateGetAll added NULL output param
*				MV 10/25/11 - TK-09243 - bspHQTaxRateGetAll added NULL output param
*
*
*
*
* USAGE:
* Called from MS Batch Process to validate an Material Vendor Payment batch.
* Adds distribution entries in bMSMA for AP Lines and bMSMG for GL.
*
* Errors in batch added to bHQBE using bspHQBEInsert
*
* INPUT PARAMETERS
*   @msco          MS Co#
*   @mth           Batch Month
*   @batchid       Batch ID
*
* OUTPUT PARAMETERS
*   @errmsg        error message
*
* RETURN VALUE
*   0              success
*   1              fail
*****************************************************/
@msco bCompany = null, @mth bMonth = null, @batchid bBatchID = null, @errmsg varchar(255) output
as
set nocount on

declare @rcode int, @status tinyint, @openMSMH_cursor tinyint,  @openMSMT_cursor tinyint, @seq int,
   		@msglco bCompany, @apco bCompany, @apglco bCompany, @expjrnl bJrnl, @aprefunqyn bYN,
   		@apcmco bCompany, @exppaytype tinyint, @apexpglacct bGLAcct, @vendorgroup bGroup,
   		@matlvendor bVendor, @apref bAPReference, @invdate bDate, @description bDesc, @holdcode bHoldCode,
   		@cmco bCompany, @cmacct bCMAcct, @errorstart varchar(30), @vendorsort varchar(15), @msg varchar(255),
   		@errortext varchar(255), @mstrans bTrans, @paycode bPayCode, @paybasis bUnits, @payrate bUnitCost,
   		@paytotal bDollar, @fromloc bLoc, @matlgroup bGroup, @material bMatl, @saletype char(1), 
   		@jcco bCompany, @inco bCompany, @matlcategory varchar(10),
   		@lcmatlexpglacct bGLAcct, @lsmatlexpglacct bGLAcct, @lomatlexpglacct bGLAcct, @lmmatlexpglacct bGLAcct,
   		@matlexpglacct bGLAcct, @arglacct bGLAcct, @apglacct bGLAcct, @glco bCompany, @v1099yn bYN,
   		@v1099type varchar(10), @v1099box tinyint, @validcnt int, @transmth bMonth, @active_loc bYN,
   		@toloc bLoc, @netamtopt bYN, @discoffglacct bGLAcct, @apdiscoffglacct bGLAcct, @payterms bPayTerms,
   		@discrate bPct, @discdate bDate, @duedate bDate, @calcduedate bDate, @discoff bDollar, @paycategory int,
   		@apexppaytype tinyint, @inter_amount bDollar, @um bUM, @units bUnits, @unitcost bUnitCost, @ecm bECM,
   		@totalcost bDollar, @taxgroup bGroup, @taxcode bTaxCode, @taxbasis bDollar, @taxamt bDollar,
   		@taxable bYN, @usetaxdiscount bYN, @saledate bDate, @taxrate bRate, @taxtype tinyint,
		----International Sales Tax
		@gstrate bRate, @pstrate bRate, @valueadd varchar(1), @dbtglacct bGLAcct,
		@TaxAmount bDollar, @TaxAmountPST bDollar, @gsttaxamt bDollar

select @rcode = 0, @openMSMH_cursor = 0, @openMSMT_cursor = 0

-- validate HQ Batch
exec @rcode = dbo.bspHQBatchProcessVal @msco, @mth, @batchid, 'MS MatlPay', 'MSMH', @errmsg output, @status output
if @rcode <> 0 goto bspexit
if @status < 0 or @status > 3
   begin
   select @errmsg = 'Invalid Batch status!', @rcode = 1
   goto bspexit
   end
-- set HQ Batch status to 1 (validation in progress)
update bHQBC set Status = 1
where Co = @msco and Mth = @mth and BatchId = @batchid
if @@rowcount = 0
   begin
   select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
   goto bspexit
   end
   
   -- clear HQ Batch Errors
   delete bHQBE where Co = @msco and Mth = @mth and BatchId = @batchid
   
   -- clear AP and GL distribution entries
   delete bMSMA where MSCo = @msco and Mth = @mth and BatchId = @batchid
   delete bMSMG where MSCo = @msco and Mth = @mth and BatchId = @batchid
   
   -- get Company info from MS Company
   select @msglco = GLCo
   from bMSCO with (Nolock) where MSCo = @msco
   if @@rowcount = 0
       begin
       select @errmsg = 'Invalid MS Company #' + convert(varchar(3),@msco), @rcode = 1
       goto bspexit
       end
   -- validate Month in MS GL Co# - subledgers must be open
   exec @rcode = dbo.bspHQBatchMonthVal @msglco, @mth, 'MS', @errmsg output
   if @rcode <> 0 goto bspexit
   
   
   
   -- declare cursor on MS Material Vendor Worksheet Batch Header for validation
   declare bcMSMH cursor LOCAL FAST_FORWARD
   for select BatchSeq, VendorGroup, MatlVendor, APRef, InvDate, InvDescription, PayTerms, DueDate, HoldCode, 
   		CMCo, CMAcct, APCo, PayCategory, PayType
   from bMSMH where Co = @msco and Mth = @mth and BatchId = @batchid
   
   -- open cursor
   open bcMSMH
   select @openMSMH_cursor = 1
   
   MSMH_loop:
   fetch next from bcMSMH into @seq, @vendorgroup, @matlvendor, @apref, @invdate, @description, @payterms,
   		@duedate, @holdcode, @cmco, @cmacct, @apco, @paycategory, @exppaytype
   
   if @@fetch_status <> 0 goto MSMH_end
   
   -- save Batch Sequence # for any errors that may be found
   select @errorstart = 'Seq#' + convert(varchar(6),@seq)
   
   select @discrate = 0, @discdate = null, @calcduedate = null
   
   -- get AP Co# information
   select @apglco = GLCo, @expjrnl = ExpJrnl,  @aprefunqyn = APRefUnqYN, @apcmco = CMCo,
   		@apexppaytype = ExpPayType, @netamtopt = NetAmtOpt, @apdiscoffglacct = DiscOffGLAcct,
   		@usetaxdiscount = UseTaxDiscountYN
   from bAPCO with (Nolock) where APCo = @apco
   if @@rowcount = 0
   	begin
   	select @errortext = @errorstart + ': ' + 'Invalid AP Company #' + isnull(convert(varchar(3),@apco),'')
   	exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
   	if @rcode <> 0 goto bspexit
   	goto MSMH_loop
   	end
   
   -- validate AP Expense Journal
   if not exists(select TOP 1 1 from bGLJR with (Nolock) where GLCo = @apglco and Jrnl = @expjrnl)
       begin
   	select @errortext = @errorstart + ': ' + 'Invalid Expense Journal ' + isnull(@expjrnl,'') + ' assigned in AP Company!'
   	exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
   	if @rcode <> 0 goto bspexit
   	goto MSMH_loop
   	end
   
	-- validate Month in AP GL Co# - subledgers must be open, and Journal in MS GL Co#
	if @apglco <> @msglco
		begin
		exec @rcode = dbo.bspHQBatchMonthVal @apglco, @mth, 'AP', @errmsg output
		if @rcode <> 0 goto bspexit
		-- -- validate journal for MS GL Company
   
		if not exists(select top 1 1 from bGLJR with (Nolock) where GLCo = @msglco and Jrnl = @expjrnl)
			begin
			select @errortext = @errorstart + ': ' + 'Invalid Journal ' + isnull(@expjrnl,'') + ' for MS GL Company!'
			exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 goto bspexit
			goto MSMH_loop
			end
		end
   
   -- -- -- use APCO.ExpPayType if MSWH.PayType is null
   if @exppaytype is null set @exppaytype = @apexppaytype
   
   -- -- -- validate PayCategory
   if @paycategory is not null
   	begin
   	select @discoffglacct=DiscOffGLAcct from bAPPC with (nolock)
   	where APCo=@apco and PayCategory=@paycategory
   	if @@rowcount = 0
   		begin
   		select @errortext = @errorstart + ': ' + 'Invalid Pay Category ' + isnull(@paycategory,'') + ' !'
   		exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
   		if @rcode <> 0 goto bspexit
   		goto MSMH_loop
   		end
   	end
   else
   	begin
   	select @discoffglacct=@apdiscoffglacct
   	end
   
   -- -- -- get GL Payables Account for Expense Pay Type
   select @apexpglacct = GLAcct
   from bAPPT with (Nolock) where APCo = @apco and PayType = @exppaytype
   if @@rowcount = 0
       begin
   	select @errortext = @errorstart + ': ' + 'Invalid AP Expense Pay Type!'
   	exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
   	if @rcode <> 0 goto bspexit
   	goto MSMH_loop
   	end
   
   -- validate GL Payables Account for Expense
   exec @rcode = dbo.bspGLACfPostable @apglco, @apexpglacct, 'P', @errmsg output
   if @rcode <> 0 goto bspexit
   
   -- validate Material Vendor
   select @vendorsort = convert(varchar(15),@matlvendor)
   exec @rcode = dbo.bspAPVendorVal @apco, @vendorgroup, @vendorsort, 'Y', 'R', @msg = @errmsg output
   if @rcode <> 0
   	begin
   	select @errortext = @errorstart + ': ' + isnull(@errmsg,'')
   	exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
   	if @rcode <> 0 goto bspexit
   	goto MSMH_loop
   	end
   
   -- validate vendor 1099 info
   select @v1099yn = V1099YN, @v1099type = V1099Type, @v1099box = V1099Box                   
   from bAPVM with (Nolock) where VendorGroup = @vendorgroup and Vendor = @matlvendor
   if @@rowcount <> 0 and @v1099yn = 'Y'
   	begin
   	-- validate 1099 type
   	select @validcnt = count(*) from bAPTT with (Nolock) where V1099Type=@v1099type
   	if @validcnt = 0
   		begin
   		select @errortext = @errorstart + ': invalid 1099 type Vendor: ' + convert(varchar(8),@matlvendor)
   		exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
   		if @rcode <> 0 goto bspexit
   		goto MSMH_loop
   		end
   
   	-- validate 1099 box
   	if @v1099box <1 or @v1099box >18
   		begin
   		select @errortext = @errorstart + ': invalid 1099 box # must be 1 through 18'
   		exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
   		if @rcode <> 0 goto bspexit
   		goto MSMH_loop
   		end
   	end
   
   
   -- validate AP Reference
   if @aprefunqyn = 'Y'   -- must be unique
   	begin
   	exec @rcode = dbo.bspMSAPRefUnique @msco, @apco, @mth, @batchid, @seq, @vendorgroup, @matlvendor, @apref, 'MS MatlPay', @errmsg output
   	if @rcode <> 0
   		begin
   		select @errortext = @errorstart + ':' + isnull(@errmsg,'')
   		exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
   		if @rcode <> 0 goto bspexit
   		goto MSMH_loop
   		end
   	end
   
   
   -- -- -- validate Hold Code
   if not @holdcode is null
   	begin
   	exec @rcode = dbo.bspHQHoldCodeVal @holdcode, @msg = @errmsg output
   	if @rcode <> 0
   		begin
   		select @errortext = @errorstart + ':' + isnull(@errmsg,'')
   		exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
   		if @rcode <> 0 goto bspexit
   		goto MSMH_loop
   		end
   	end
   
-- -- -- validate pay terms
if @payterms is not null
	begin
	exec @rcode = dbo.bspHQPayTermsVal @payterms, 'N', @discrate output, @errmsg output
	if @rcode <> 0
		begin
		select @errortext = @errorstart + ':' + isnull(@errmsg,'')
		exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
		if @rcode <> 0 goto bspexit
		goto MSMH_loop
		end

	-- -- -- calculate discount date
	exec @rcode = dbo.bspHQPayTermsDateCalc @payterms, @invdate, @discdate output, @calcduedate output, @discrate output, @errmsg output
	if @rcode <> 0
		begin
		select @errortext = @errorstart + ':' + isnull(@errmsg,'')
		exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
		if @rcode <> 0 goto bspexit
		goto MSMH_loop
		end

	-- -- -- if discount date > MSWH.DueDate set to due date
	if isnull(@discdate,'') <> '' and isnull(@duedate,'') <> '' and @discdate > @duedate select @discdate = @duedate
	end
   
   
   -- -- -- validate CM Co#
   if @cmco is null select @cmco = @apcmco    -- use default CM Co# from AP if null
   if not exists(select top 1 1 from bCMCO with (Nolock) where CMCo = @cmco)
   	begin
   	select @errortext = @errorstart + ': Invalid CM Co#' + convert(varchar(3),@cmco)
   	exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
   	if @rcode <> 0 goto bspexit
   	goto MSMH_loop
   	end
   
   -- -- -- validate CM Account - not required
   if @cmacct is not null
   	if not exists(select top 1 1 from bCMAC with (Nolock) where CMCo = @cmco and CMAcct = @cmacct)
           begin
           select @errortext = @errorstart + ': Invalid CM Co#' + convert(varchar(3),@cmco)
               + ' and Account ' + convert(varchar(6),isnull(@cmacct,''))
           exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
    	    if @rcode <> 0 goto bspexit
           goto MSMH_loop
           end
   
   -- -- -- update discount date (bMSWH)
   update bMSMH set DiscDate=@discdate
   where Co = @msco and Mth = @mth and BatchId = @batchid and BatchSeq=@seq
   
   
   
-- -- -- declare cursor on MS Material Vendor Worksheet Batch Detail for validation and distributions
declare bcMSMT cursor LOCAL FAST_FORWARD
for select TransMth, MSTrans, FromLoc, SaleDate, MatlGroup, Material, UM, Units, UnitCost, ECM,
			TotalCost, TaxGroup, TaxCode, TaxBasis, TaxAmt, TaxType
from bMSMT
where Co = @msco and Mth = @mth and BatchId = @batchid and BatchSeq = @seq

-- open cursor
open bcMSMT
select @openMSMT_cursor = 1

MSMT_loop:
fetch next from bcMSMT into @transmth, @mstrans, @fromloc, @saledate, @matlgroup, @material, @um, @units,
			@unitcost, @ecm, @totalcost, @taxgroup, @taxcode, @taxbasis, @taxamt, @taxtype

if @@fetch_status <> 0 goto MSMT_end

-- -- -- add MS Trans# to error message
select @errorstart = 'Seq#' + convert(varchar(6),@seq) + ' Trans#' + convert(varchar(8),@mstrans)

-- -- -- validate Trans# and get info for distributions
select @saletype=SaleType, @jcco=JCCo, @inco=INCo, @toloc=ToLoc
from bMSTD with (Nolock) where MSCo = @msco and Mth = @transmth and MSTrans = @mstrans
if @@rowcount = 0
	begin
	select @errortext = @errorstart + ' - Invalid or missing MS Transaction#.'
	goto MSMT_error
	end
   
-- ************* --
-- ISSUE: 130168 --
-- ************* --
--if @totalcost = 0 and @taxamt = 0 goto MSMT_loop -- -- -- skip updates

---- if there is a tax amount, must also be a tax code
if @taxcode is null and @taxamt <> 0
	begin
	select @errortext = @errorstart + ' - Tax Code is missing, and Tax Amount is not 0.00.'
	goto MSMT_error
	end

---- verify there is a tax group to go with tax code
if @taxgroup is null and @taxcode is not null
	begin
	select @errortext = @errorstart + ' - Tax Group is missing, and Tax Code is not null.'
	goto MSMT_error
	end

---- validate Tax Code and get tax rate
select @taxrate = 0, @gsttaxamt = 0, @dbtglacct = null, @valueadd = 'N'
if @taxcode is null set @taxtype = null
if @taxcode is not null
	begin
	---- will get tax information at this point. may need to back out GST for the Job or Inventory Sale
	---- if the GST is split out and we have a debit account ITC then the tax amount that is expensed
	---- get tax rates for international
	exec @rcode = dbo.bspHQTaxRateGetAll @taxgroup, @taxcode, @saledate, @valueadd output,
			@taxrate output, @gstrate output, @pstrate output, null,
			null, @dbtglacct output, null, null, null, NULL, NULL, @errmsg output
	if @@rowcount = 0
		begin
		select @errortext = @errorstart + ' - Invalid Tax Code: ' + isnull(@taxcode,'') + ' !'
		goto MSMT_error
		end
	---- validate tax type
	if @taxtype is null
		begin
		select @errortext = @errorstart + ' - Invalid tax type - no tax type assigned.'
		goto MSMT_error
		end
	if @taxtype not in (1,3)
		begin
		select @errortext = @errorstart + ' - Invalid Tax Type, must be 1, or 3.'
		goto MSMT_error
		end
	if @taxtype = 3 and isnull(@valueadd,'N') <> 'Y'
		begin
		select @errortext = @errorstart + ' - Invalid Tax Code: ' + isnull(@taxcode,'') + '. Must be a value added tax code!'
		goto MSMT_error
		end
	end

-- -- -- get info from Material
select @matlcategory = Category, @taxable = Taxable
from bHQMT with (Nolock) where MatlGroup = @matlgroup and Material = @material
if @@rowcount = 0
	begin
	select @errortext = @errorstart + ' - Invalid Material!'
	goto MSMT_error
	end
if @taxable = 'N' and @taxcode is not null
	begin
	select @errortext = @errorstart + ' - Material is not taxable.'
	goto MSMT_error
	end

-- -- -- validate to location is active if sale type = 'I'
if @saletype = 'I'
	begin
	set @active_loc = 'Y'
	select @active_loc = Active
	from bINLM with (nolock) where INCo=@inco and Loc=@toloc
	if @active_loc = 'N'
		begin
		select @errortext = @errorstart + ' - Inactive To location!'
		goto MSMT_error
		end
	end

-- -- -- calculate discount offered
select @discoff = @discrate * @totalcost

-- -- -- if APCO.UseTaxDiscount = 'Y' need to adjust tax basis and recalculate tax amount
if @usetaxdiscount = 'Y' and @discoff <> 0
	begin
	select @taxbasis = @taxbasis - @discoff
	select @taxamt = (@taxbasis * @taxrate)
	end

---- #128458 calculate tax amount for GST, will debit the contra account if there is one
---- for the GST amount and back out from the GST tax amount when posting to MSMA table
if @valueadd = 'Y'
	begin
	---- Breakout and establish all GST tax amounts
	if @pstrate = 0
		begin
		/* When @pstrate = 0:  Either VAT SingleLevel using GST only, or VAT MultiLevel GST/PST with PST set to 0.00 tax rate. */
		select @gsttaxamt = @taxamt
		end
	else
		begin
		---- VAT MultiLevel:  Breakout GST and PST for proper GL distribution
		if @taxrate <> 0
			begin
			select @gsttaxamt = (@taxamt * @gstrate) / @taxrate		--GST TaxAmount
			end
		end

	---- if the user set up a ValueAdd GST taxcode but is NOT tracking the GST in an ITC account
	---- then we will not break out the GST tax for the Job or Inventory sale expense.
	if @dbtglacct is null
		begin
		select @gsttaxamt = 0
		end
	end


-- -- -- get Material Expense Account based on Location with overrides by Sell To Co# and Category
select @lcmatlexpglacct = null, @lsmatlexpglacct = null, @lomatlexpglacct = null, @active_loc = 'Y'

---- get inventory locaton expence accounts
select @lmmatlexpglacct = case @saletype 
		when 'C' then CustMatlExpGLAcct 
		when 'J' then JobMatlExpGLAcct
		when 'I' then InvMatlExpGLAcct end,
		@active_loc = Active
from bINLM with (Nolock) where INCo = @msco and Loc = @fromloc
if @@rowcount = 0
	begin
	select @errortext = @errorstart + ' - Invalid From Location!'
	goto MSMT_error
	end

---- location must be active
if @active_loc = 'N'
   	begin
   	select @errortext = @errorstart + ' - Inactive from location!'
   	goto MSMT_error
   	end

---- if Customer sale, check for GL Account overrides based on Material Category
if @saletype = 'C'
	begin
	select @lomatlexpglacct = CustMatlExpGLAcct
	from bINLO with (Nolock) 
	where INCo = @msco and Loc = @fromloc and MatlGroup = @matlgroup and Category = @matlcategory
	end

---- if Job sale, check for GL Account override based on Sell To Co#
if @saletype = 'J'
	begin
	select @lsmatlexpglacct = JobMatlExpGLAcct
	from bINLS with (Nolock) 
	where INCo = @msco and Loc = @fromloc and Co = @jcco
	end

---- if Inventory sale, check for GL Account override based on Sell To Co#
if @saletype = 'I'
	begin
	select @lsmatlexpglacct = InvMatlExpGLAcct
	from bINLS with (Nolock) 
	where INCo = @msco and Loc = @fromloc and Co = @inco
	end

---- if Job or Inventory sale, check for GL Account override by based on Sell To Co# and Material Caetgory
if @saletype = 'J'
	begin
	select @lcmatlexpglacct = JobMatlExpGLAcct
	from bINLC with (Nolock) 
	where INCo = @msco and Loc = @fromloc and Co = @jcco and MatlGroup = @matlgroup
	and Category = @matlcategory
	end
if @saletype = 'I'
	begin
	select @lcmatlexpglacct = InvMatlExpGLAcct
	from bINLC with (Nolock) 
	where INCo = @msco and Loc = @fromloc and Co = @inco and MatlGroup = @matlgroup
	and Category = @matlcategory
	end
	
---- assign Material Expense Account
select @matlexpglacct = isnull(isnull(isnull(@lcmatlexpglacct,@lsmatlexpglacct),@lomatlexpglacct),@lmmatlexpglacct)

---- validate Expense Account
exec @rcode = dbo.bspGLACfPostable @msglco, @matlexpglacct, 'I', @errmsg output
if @rcode <> 0
	begin
	select @errortext = @errorstart + ' - Material Expense Account ' + isnull(@errmsg,'')
	goto MSMT_error
	end
   
---- validate Discount Offered GL Account
if @discoff <> 0 and @netamtopt = 'Y'   -- only used if interfacing net
	begin
	exec @rcode = dbo.bspGLACfPostable @apglco, @discoffglacct, 'I', @errmsg output
	if @rcode <> 0
		begin
		select @errortext = @errorstart + ' - Discount Offered Expense Account ' + isnull(@errmsg,'')
		goto MSMT_error
		end
	end

---- validate GST debit account #128458
if @valueadd = 'Y' and @dbtglacct is not null and @gsttaxamt <> 0
	begin
	exec @rcode = dbo.bspGLACfPostable @apglco, @dbtglacct, 'N', @errmsg output
	if @rcode <> 0
		begin
		select @errortext = @errorstart + ' - GST Expense GL account ' + isnull(@errmsg,'')
		goto MSMT_error
		end
	end


-- -- -- add AP Line distribution entry
insert bMSMA(MSCo, Mth, BatchId, BatchSeq, MatlGroup, Material, UM, UnitCost, ECM, GLCo, GLAcct,
		TaxGroup, TaxCode, TransMth, MSTrans, Units, TotalCost, DiscOff,
		TaxBasis, TaxAmt, TaxType, GSTTaxAmt)
values(@msco, @mth, @batchid, @seq, @matlgroup, @material, @um, @unitcost, @ecm, @msglco, @matlexpglacct,
		@taxgroup, @taxcode, @transmth, @mstrans, @units, @totalcost, @discoff,
		@taxbasis, @taxamt, @taxtype, @gsttaxamt)


-- -- -- Material Expense debits
if @discoff <> 0 and @netamtopt = 'Y'   -- only used if interfacing net
	begin
	-- -- -- material expense debit for net
	update bMSMG set Amount = Amount + (@totalcost + @taxamt - @discoff - @gsttaxamt)
	where MSCo=@msco and Mth=@mth and BatchId=@batchid and GLCo=@msglco and GLAcct=@matlexpglacct and BatchSeq=@seq
	if @@rowcount = 0
		begin
		insert bMSMG(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, VendorGroup, MatlVendor, APRef,
					InvDescription, InvDate, APTrans, Amount)
		values(@msco, @mth, @batchid, @msglco, @matlexpglacct, @seq, @vendorgroup, @matlvendor, @apref,
					@description, @invdate, null, (@totalcost + @taxamt - @discoff - @gsttaxamt))
		end
   
	-- -- -- discount offered debit
	update bMSMG set Amount = Amount + @discoff
	where MSCo=@msco and Mth=@mth and BatchId=@batchid and GLCo=@msglco and GLAcct=@discoffglacct and BatchSeq=@seq
	if @@rowcount = 0
		begin
		insert bMSMG(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, VendorGroup, MatlVendor, APRef,
					InvDescription, InvDate, APTrans, Amount)
		values(@msco, @mth, @batchid, @msglco, @discoffglacct, @seq, @vendorgroup, @matlvendor, @apref,
					@description, @invdate, null, @discoff)
		end

	---- GST debit account #128458
	if @valueadd = 'Y' and @dbtglacct is not null and @gsttaxamt <> 0
		begin
		update bMSMG set Amount = Amount + @gsttaxamt
		where MSCo=@msco and Mth=@mth and BatchId=@batchid and GLCo=@msglco and GLAcct=@dbtglacct and BatchSeq=@seq
		if @@rowcount = 0
			begin
			insert bMSMG(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, VendorGroup, MatlVendor, APRef,
						InvDescription, InvDate, APTrans, Amount)
			values(@msco, @mth, @batchid, @msglco, @dbtglacct, @seq, @vendorgroup, @matlvendor, @apref,
						@description, @invdate, null, @gsttaxamt)
			end
		end
	end
else
   	begin
   	update bMSMG set Amount = Amount + @totalcost + @taxamt - @gsttaxamt
   	where MSCo=@msco and Mth=@mth and BatchId=@batchid and GLCo=@msglco and GLAcct=@matlexpglacct and BatchSeq=@seq
   	if @@rowcount = 0
   		begin
   		insert bMSMG(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, VendorGroup, MatlVendor, APRef,
   					InvDescription, InvDate, APTrans, Amount)
   		values(@msco, @mth, @batchid, @msglco, @matlexpglacct, @seq, @vendorgroup, @matlvendor, @apref,
   					@description, @invdate, null, (@totalcost + @taxamt - @gsttaxamt))
   		end

	---- GST debit account #128458
	if @valueadd = 'Y' and @dbtglacct is not null and @gsttaxamt <> 0
		begin
		update bMSMG set Amount = Amount + @gsttaxamt
		where MSCo=@msco and Mth=@mth and BatchId=@batchid and GLCo=@msglco and GLAcct=@dbtglacct and BatchSeq=@seq
		if @@rowcount = 0
			begin
			insert bMSMG(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, VendorGroup, MatlVendor, APRef,
						InvDescription, InvDate, APTrans, Amount)
			values(@msco, @mth, @batchid, @msglco, @dbtglacct, @seq, @vendorgroup, @matlvendor, @apref,
						@description, @invdate, null, @gsttaxamt)
			end
		end
   	end
   
-- -- -- AP Expense Payables credit
update bMSMG set Amount = Amount - (@totalcost + @taxamt)
where MSCo=@msco and Mth=@mth and BatchId=@batchid and GLCo=@apglco and GLAcct=@apexpglacct and BatchSeq=@seq
if @@rowcount = 0
	begin
	insert bMSMG(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, VendorGroup, MatlVendor, APRef,
					InvDescription, InvDate, APTrans, Amount)
	values(@msco, @mth, @batchid, @apglco, @apexpglacct, @seq, @vendorgroup, @matlvendor, @apref,
					@description, @invdate, null, -(@totalcost + @taxamt))
	end
   
-- -- -- add Intercompany entries if needed
if @apglco <> @msglco
begin
   	-- get interco GL Accounts
   	select @arglacct = ARGLAcct, @apglacct = APGLAcct
   	from bGLIA with (Nolock) where ARGLCo = @apglco and APGLCo = @msglco
   	if @@rowcount = 0
   		begin
   		select @errortext = @errorstart + ' - Intercompany Accounts not setup in GL for these companies!'
   		goto MSMT_error
   		end
   
   	-- -- -- validate Intercompany AR GL Account
   	exec @rcode = dbo.bspGLACfPostable @apglco, @arglacct, 'R', @errmsg output
   	if @rcode <> 0
   		begin
   		select @errortext = @errorstart + ' - Intercompany AR Account  ' + isnull(@errmsg,'')
   		goto MSMT_error
   		end
   
   	-- -- -- validate Intercompany AP GL Account
   	exec @rcode = dbo.bspGLACfPostable @msglco, @apglacct, 'P', @errmsg output
   	if @rcode <> 0
   		begin
   		select @errortext = @errorstart + ' - Intercompany AP Account  ' + isnull(@errmsg,'')
   		goto MSMT_error
   		end
   
   	-- -- -- set @inter_amount to paytotal - discoff or paytotal
   	if @netamtopt = 'Y'
		begin
   		select @inter_amount = (@totalcost + @taxamt - @discoff)
		end
   	else
		begin
   		select @inter_amount = (@totalcost + @taxamt)
		end
   
   
   	-- -- -- Intercompany AR debit (posted in AP GL Co#)
   	update bMSMG set Amount = Amount + @inter_amount
   	where MSCo=@msco and Mth=@mth and BatchId=@batchid and GLCo=@apglco and GLAcct=@arglacct and BatchSeq=@seq
   	if @@rowcount = 0
   		begin
   		insert bMSMG(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, VendorGroup, MatlVendor, APRef,
   				InvDescription, InvDate, APTrans, Amount)
   		values(@msco, @mth, @batchid, @apglco, @arglacct, @seq, @vendorgroup, @matlvendor, @apref,
   				@description, @invdate, null, @inter_amount)
   		end
   
   	-- -- -- Intercompany AP credit (posted in IN/MS Co#)
   	update bMSMG set Amount = Amount - @inter_amount
   	where MSCo=@msco and Mth=@mth and BatchId=@batchid and GLCo=@msglco and GLAcct=@apglacct and BatchSeq=@seq
   	if @@rowcount = 0
   		begin
   		insert bMSMG(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, VendorGroup, MatlVendor, APRef,
   				InvDescription, InvDate, APTrans, Amount)
   		values(@msco, @mth, @batchid, @msglco, @apglacct, @seq, @vendorgroup, @matlvendor, @apref,
   				@description, @invdate, null, -@inter_amount)
   		end
   	end
   
   
   
   -- -- -- finished with GL distributions
   goto MSMT_loop
   
   
   
   
   MSMT_error:	-- record error message and go to next Worksheet Detail
       exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
       if @rcode <> 0 goto bspexit
       goto MSMT_loop
   
   MSMT_end:   -- finished with Worksheet Detail
       close bcMSMT
       deallocate bcMSMT
       set @openMSMT_cursor = 0
       goto MSMH_loop  -- next Worksheet Header
   
   MSWH_error:	-- record error message and go to next Worksheet Header
    	exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
       if @rcode <> 0 goto bspexit
       goto MSMH_loop
   
   MSMH_end:   -- finished with Worksheet Headers
       close bcMSMH
       deallocate bcMSMH
       set @openMSMH_cursor = 0
   
   -- make sure debits and credits balance
   select @glco = m.GLCo
   from bMSMG m with (Nolock) join bGLAC g with (Nolock) on m.GLCo = g.GLCo and m.GLAcct = g.GLAcct
   where m.MSCo = @msco and m.Mth = @mth and m.BatchId = @batchid
   group by m.GLCo
   having isnull(sum(Amount),0) <> 0
   if @@rowcount <> 0
        begin
        select @errortext = 'GL Company ' + convert(varchar(3), @glco) + ' entries do not balance!'
        exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
        if @rcode <> 0 goto bspexit
        end
   
   -- check HQ Batch Errors and update HQ Batch Control status
   select @status = 3	-- valid - ok to post 
   if exists(select 1 from bHQBE with (Nolock) where Co = @msco and Mth = @mth and BatchId = @batchid)
        select @status = 2	-- validation errors 
   
   update bHQBC
   set Status = @status
   where Co = @msco and Mth = @mth and BatchId = @batchid
   if @@rowcount <> 1
       begin
   
     	select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
     	goto bspexit
     	end
   
   
   
   
   
   bspexit:
       if @openMSMT_cursor = 1
     		begin
     		close bcMSMT
     		deallocate bcMSMT
     		end
        if @openMSMH_cursor = 1
     		begin
     		close bcMSMH
     		deallocate bcMSMH
     		end
   
       if @rcode <> 0 select @errmsg = isnull(@errmsg,'')
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSMHVal] TO [public]
GO
