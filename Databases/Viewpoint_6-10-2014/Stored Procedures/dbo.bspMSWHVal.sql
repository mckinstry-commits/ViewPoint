SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




/**********************************************************/
   CREATE  procedure [dbo].[bspMSWHVal]
   /***********************************************************
   * CREATED: GG 02/10/01
   * MODIFIED: GF 12/04/2001 - Issue #15446 validation added for 1099 type and box.
   *			GF 02/12/2002 - Issue #15446 rejected, validcnt <> 0 s/b validcnt=0 on 1099Type
   *			GG 05/31/02 - #17526 - skip null Pay Codes
   *			MV 08/05/02 - #15113 - APRef validation
   *			MV 09/18/02 - #15113 - AP ref checking for all levels enhancement
   *			GF 03/27/2003 - #20785 - TransMth added to MSWD to allow payments in batch month or earlier.
   *			GF 07/29/2003 - #21933 - speed improvements
   *			GF 10/14/2003 - #22696 - check from/to location to make sure active.
   *			GF 12/05/2003 - #23205 - check error messages, wrap concatenated values with isnull
   *			GF 06/16/2004 - #24852 - duplicate index error when different AP GLCo.
   *			GF 12/15/2004 - #18884, #20558, #25040 MS hauler payment enhancements
   *			GF 03/29/2010 - #129350 - surcharges
   *			MH 09/17/2011 - TK-01835 Include HaulPaymentTaxes in update to AP.
   *			MV 10/25/2011 - TK-09243 - added NULL output param to bspHQTaxRateGetAll
   *			GF 05/01/2013 TFS-49547 haul payment taxes null error updating MSWG.Amount
   *			GF 07/18/2013 TFS-56370 GL distribution fix for negative tax amount
   *
   *
   *
   *
   * USAGE:
   * Called from MS Batch Process to validate an Hauler Payment batch.
   * Adds distribution entries in bMSAP for AP Lines and bMSWG for GL.
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
   
declare @rcode int, @status tinyint, @msglco bCompany, @apco bCompany, @apglco bCompany, @expjrnl bJrnl,
		@aprefunqyn bYN, @apcmco bCompany, @exppaytype tinyint, @apexpglacct bGLAcct, @openMSWHcursor tinyint,
		@seq int, @vendorgroup bGroup, @haulvendor bVendor, @apref bAPReference, @invdate bDate, @description bDesc,
		@holdcode bHoldCode, @cmco bCompany, @cmacct bCMAcct, @errorstart varchar(30), @vendorsort varchar(15),
		@msg varchar(255), @errortext varchar(255), @openMSWDcursor tinyint, @mstrans bTrans, @paycode bPayCode,
		@paybasis bUnits, @payrate bUnitCost, @paytotal bDollar, @fromloc bLoc, @matlgroup bGroup, @material bMatl,
		@saletype char(1), @jcco bCompany, @inco bCompany, @matlcategory varchar(10), @lchaulexpglacct bGLAcct,
		@lshaulexpglacct bGLAcct, @lohaulexpglacct bGLAcct, @lmhaulexpglacct bGLAcct, @haulexpglacct bGLAcct,
		@arglacct bGLAcct, @apglacct bGLAcct, @glco bCompany, @v1099yn bYN, @v1099type varchar(10), @v1099box tinyint,
		@validcnt int, @transmth bMonth, @active_loc bYN, @toloc bLoc, @netamtopt bYN, @discoffglacct bGLAcct,
		@apdiscoffglacct bGLAcct, @payterms bPayTerms, @discrate bPct, @discdate bDate, @duedate bDate,
		@calcduedate bDate, @discoff bDollar, @paycategory int, @apexppaytype tinyint,
		@inter_amount bDollar,
		---- #129350
		@SurchargeKeyID bigint, @SurchargeCode smallint, @haulpaytaxtype tinyint, @haulpaytaxcode bTaxCode, 
		@haulpaytaxamt bDollar,	@haulpaytaxbasis bDollar, @haulpaytaxrate bUnitCost, @taxgroup bGroup, @valueadd char(1), @taxrate bRate, 
		@gstrate bRate, @pstrate bRate,	@crdGLAcct bGLAcct, @crdRetgGLAcct bGLAcct, @dbtGLAcct bGLAcct, @dbtRetgGLAcct bGLAcct,
		@crdGLAcctPST bGLAcct, @crdRetgGLAcctPST bGLAcct, @crdRetgGLAcctGST bGLAcct, @mswgglacct bGLAcct,
		@taxgrouprcode tinyint, @taxgroupmsg varchar(60), @gstTaxAmt bDollar, @payTaxAmt bDollar, @VATpstTaxAmt bDollar, @VATgstTaxAmt bDollar,
		@pstTaxAmt bDollar
 

   select @rcode = 0, @openMSWHcursor = 0, @openMSWDcursor = 0
   
   -- validate HQ Batch
   exec @rcode = dbo.bspHQBatchProcessVal @msco, @mth, @batchid, 'MS HaulPay', 'MSWH', @errmsg output, @status output
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
   delete bMSAP where MSCo = @msco and Mth = @mth and BatchId = @batchid
   delete bMSWG where MSCo = @msco and Mth = @mth and BatchId = @batchid
   
 
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
   
   -- declare cursor on MS Hauler Worksheet Batch Header for validation
   declare bcMSWH cursor LOCAL FAST_FORWARD
   for select BatchSeq, VendorGroup, HaulVendor, APRef, InvDate, InvDescription, PayTerms, DueDate, HoldCode, 
   		CMCo, CMAcct, APCo, PayCategory, PayType
   from bMSWH where Co = @msco and Mth = @mth and BatchId = @batchid
   
   -- open cursor
   open bcMSWH
   select @openMSWHcursor = 1
   
   MSWH_loop:
   fetch next from bcMSWH into @seq, @vendorgroup, @haulvendor, @apref, @invdate, @description, @payterms, @duedate, @holdcode,
   		@cmco, @cmacct, @apco, @paycategory, @exppaytype
   
   if @@fetch_status <> 0 goto MSWH_end
   
   -- save Batch Sequence # for any errors that may be found
   select @errorstart = 'Seq#' + convert(varchar(6),@seq)
   
   select @discrate = 0, @discdate = null, @calcduedate = null
   
   -- get AP Co# information
   select @apglco = GLCo, @expjrnl = ExpJrnl,  @aprefunqyn = APRefUnqYN, @apcmco = CMCo,
   		@apexppaytype = ExpPayType, @netamtopt = NetAmtOpt, @apdiscoffglacct = DiscOffGLAcct
   from bAPCO with (Nolock) where APCo = @apco
   if @@rowcount = 0
   	begin
   	select @errortext = @errorstart + ': ' + 'Invalid AP Company #' + isnull(convert(varchar(3),@apco),'')
   	exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
   	if @rcode <> 0 goto bspexit
   	goto MSWH_loop
   	end
   
   -- validate AP Expense Journal
   if not exists(select TOP 1 1 from bGLJR with (Nolock) where GLCo = @apglco and Jrnl = @expjrnl)
       begin
   	select @errortext = @errorstart + ': ' + 'Invalid Expense Journal ' + isnull(@expjrnl,'') + ' assigned in AP Company!'
   	exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
   	if @rcode <> 0 goto bspexit
   	goto MSWH_loop
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
   		goto MSWH_loop
   		end
       end
   
   --TK-01835 Get Tax Group.
   --See TaxGroup: If there is an error see comment tag below
   exec @taxgrouprcode = bspHQTaxGrpGet @apglco, @taxgroup output, @taxgroupmsg output   
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
   		goto MSWH_loop
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
   	goto MSWH_loop
   	end
   
   -- validate GL Payables Account for Expense
   exec @rcode = dbo.bspGLACfPostable @apglco, @apexpglacct, 'P', @errmsg output
   if @rcode <> 0 goto bspexit
   
   -- validate Haul Vendor
   select @vendorsort = convert(varchar(15),@haulvendor)
   exec @rcode = dbo.bspAPVendorVal @apco, @vendorgroup, @vendorsort, 'Y', 'R', @msg = @errmsg output
   if @rcode <> 0
   	begin
   	select @errortext = @errorstart + ': ' + isnull(@errmsg,'')
   	exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
   	if @rcode <> 0 goto bspexit
   	goto MSWH_loop
   	end
   
   -- validate vendor 1099 info
   select @v1099yn = V1099YN, @v1099type = V1099Type, @v1099box = V1099Box                   
   from bAPVM with (Nolock) where VendorGroup = @vendorgroup and Vendor = @haulvendor
   if @@rowcount <> 0 and @v1099yn = 'Y'
   	begin
   	-- validate 1099 type
   	select @validcnt = count(*) from bAPTT with (Nolock) where V1099Type=@v1099type
   	if @validcnt = 0
   		begin
   		select @errortext = @errorstart + ': invalid 1099 type Vendor: ' + convert(varchar(8),@haulvendor)
   		exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
   		if @rcode <> 0 goto bspexit
   		goto MSWH_loop
   		end
   
   	-- validate 1099 box
   	if @v1099box <1 or @v1099box >18
   		begin
   		select @errortext = @errorstart + ': invalid 1099 box # must be 1 through 18'
   		exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
   		if @rcode <> 0 goto bspexit
   		goto MSWH_loop
   		end
   	end
   
   
   -- validate AP Reference
   if @aprefunqyn = 'Y'   -- must be unique
   	begin
   	exec @rcode = dbo.bspMSAPRefUnique @msco, @apco, @mth, @batchid, @seq, @vendorgroup, @haulvendor, @apref, 'MS HaulPay', @errmsg output
   	if @rcode <> 0
   		begin
   		select @errortext = @errorstart + ':' + isnull(@errmsg,'')
   		exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
   		if @rcode <> 0 goto bspexit
   		goto MSWH_loop
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
   		goto MSWH_loop
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
   		goto MSWH_loop
   		end
   
   	-- -- -- calculate discount date
   	exec @rcode = dbo.bspHQPayTermsDateCalc @payterms, @invdate, @discdate output, @calcduedate output, @discrate output, @errmsg output
   	if @rcode <> 0
   		begin
   		select @errortext = @errorstart + ':' + isnull(@errmsg,'')
   		exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
   		if @rcode <> 0 goto bspexit
   		goto MSWH_loop
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
   	goto MSWH_loop
   	end
   
   -- -- -- validate CM Account - not required
   if @cmacct is not null
   	if not exists(select top 1 1 from bCMAC with (Nolock) where CMCo = @cmco and CMAcct = @cmacct)
           begin
           select @errortext = @errorstart + ': Invalid CM Co#' + convert(varchar(3),@cmco)
               + ' and Account ' + convert(varchar(6),isnull(@cmacct,''))
           exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
    	    if @rcode <> 0 goto bspexit
           goto MSWH_loop
           end
   
   
   -- -- -- update discount date (bMSWH)
   update bMSWH set DiscDate=@discdate
   where Co = @msco and Mth = @mth and BatchId = @batchid and BatchSeq=@seq
   
   
   -- -- -- declare cursor on MS Hauler Worksheet Batch Detail for validation and distributions
   declare bcMSWD cursor LOCAL FAST_FORWARD
		for select TransMth, MSTrans, PayCode, PayBasis, PayRate, PayTotal, HaulPayTaxType,
		HaulPayTaxCode, HaulPayTaxAmt, HaulPayTaxRate
   from bMSWD
   where Co = @msco and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
   
   -- open cursor
   open bcMSWD
   select @openMSWDcursor = 1
   
   MSWD_loop:
   	fetch next from bcMSWD into @transmth, @mstrans, @paycode, @paybasis, @payrate, @paytotal,
   	@haulpaytaxtype, @haulpaytaxcode, @haulpaytaxamt, @haulpaytaxrate
   	
   	if @@fetch_status <> 0 goto MSWD_end
   
   	-- add MS Trans# to error message
   	select @errorstart = 'Seq#' + convert(varchar(6),@seq) + ' Trans#' + convert(varchar(8),@mstrans)
   
   	-- validate Trans# and get info for distributions
   	select @fromloc = FromLoc, @matlgroup = MatlGroup, @material = Material, @saletype = SaleType,
   				@jcco = JCCo, @inco = INCo, @toloc = ToLoc,
   				---- #129350
   				@SurchargeKeyID = SurchargeKeyID, @SurchargeCode = @SurchargeCode
   				---- #129350
   	from bMSTD with (Nolock) where MSCo = @msco and Mth = @transmth and MSTrans = @mstrans
   	if @@rowcount = 0
   		begin
   		select @errortext = @errorstart + ' - Invalid or missing MS Transaction#.'
   		goto MSWD_error
   		end
   
   	-- Worksheet Detail already validated via triggers on bMSWD
   	if @paycode is null and @paytotal <> 0
   		begin
   		select @errortext = @errorstart + ' - Pay Code is missing, and Pay Total is not 0.00.'
   		goto MSWD_error
   		end
   
   	if @paytotal = 0 goto MSWD_loop		-- #17526 - skip updates
   
   	-- validate to location is active if sale type = 'I'
   	if @saletype = 'I'
   		begin
   		set @active_loc = 'Y'
   		select @active_loc = Active
   		from bINLM with (nolock) where INCo=@inco and Loc=@toloc
   		if @active_loc = 'N'
   			begin
   			select @errortext = @errorstart + ' - Inactive To location!'
   			goto MSWD_error
   			end
   		end
   
   	-- get info from Material
   	select @matlcategory = Category
   	from bHQMT with (Nolock) where MatlGroup = @matlgroup and Material = @material
   	if @@rowcount = 0
   		begin
   		select @errortext = @errorstart + ' - Invalid Material!'
   		goto MSWD_error
   		end
   
-- -- -- calculate discount offered
select @discoff = @discrate * @paytotal

-- get Haul Expense Account based on Location with overrides by Sell To Co# and Category
select @lchaulexpglacct = null, @lshaulexpglacct = null, @lohaulexpglacct = null, @active_loc = 'Y'

----#129350
---- get Haul Expense Account based on Location 
if @SurchargeKeyID is null
	begin
	select @lmhaulexpglacct = case @saletype when 'C' then CustHaulExpOutGLAcct when 'J' then JobHaulExpOutGLAcct
	when 'I' then InvHaulExpOutGLAcct end, @active_loc = Active
	from bINLM with (Nolock) where INCo = @msco and Loc = @fromloc
	if @@rowcount = 0
		begin
		select @errortext = @errorstart + ' - Invalid From Location!'
		goto MSWD_error
		end
	end	
else
	begin
	select @lmhaulexpglacct = case @saletype when 'C' then CustSurchargeExpOutGLAcct
							when 'J' then JobSurchargeExpOutGLAcct
							when 'I' then InvSurchargeExpOutGLAcct end,
							@active_loc = Active
	from bINLM with (Nolock) where INCo = @msco and Loc = @fromloc
	if @@rowcount = 0
		begin
		select @errortext = @errorstart + ' - Invalid From Location!'
		goto MSWD_error
		end
	end	

---- location must be active	
if @active_loc = 'N'
	begin
	select @errortext = @errorstart + ' - Inactive from location!'
	goto MSWD_error
	end

---- if Customer sale, check for GL Account overrides based on Material Category
if @SurchargeKeyID is null
	BEGIN
	if @saletype = 'C'
			select @lohaulexpglacct = CustHaulExpOutGLAcct
			from bINLO with (Nolock) 
			where INCo = @msco and Loc = @fromloc and MatlGroup = @matlgroup and Category = @matlcategory
	-- if Job or Inventory sale, check for GL Account override based on Sell To Co#
	if @saletype = 'J'
			select @lshaulexpglacct = JobHaulExpOutGLAcct
			from bINLS with (Nolock) 
			where INCo = @msco and Loc = @fromloc and Co = @jcco
	if @saletype = 'I'
			select @lshaulexpglacct = InvHaulExpOutGLAcct
			from bINLS with (Nolock) 
			where INCo = @msco and Loc = @fromloc and Co = @inco
         
	---- if Job or Inventory sale, check for GL Account override by based on Sell To Co# and Material Caetgory
	if @saletype = 'J'
			select @lchaulexpglacct = JobHaulExpOutGLAcct
			from bINLC with (Nolock) 
			where INCo = @msco and Loc = @fromloc and Co = @jcco and MatlGroup = @matlgroup and Category = @matlcategory
	if @saletype = 'I'
			select @lchaulexpglacct = InvHaulExpOutGLAcct
			from bINLC with (Nolock) 
			where INCo = @msco and Loc = @fromloc and Co = @inco and MatlGroup = @matlgroup and Category = @matlcategory
	END
----#129350 END

---- assign Haul Expense Account
select @haulexpglacct = isnull(isnull(isnull(@lchaulexpglacct,@lshaulexpglacct),@lohaulexpglacct),@lmhaulexpglacct)
-- validate Expense Account
exec @rcode = dbo.bspGLACfPostable @msglco, @haulexpglacct, 'I', @errmsg output
if @rcode <> 0
	begin
	select @errortext = @errorstart + ' - Haul Expense Account ' + isnull(@errmsg,'')
	goto MSWD_error
	end
   
   	-- -- -- validate Discount Offered GL Account
   	if @discoff <> 0 and @netamtopt = 'Y'   -- only used if interfacing net
   		begin
   		exec @rcode = dbo.bspGLACfPostable @apglco, @discoffglacct, 'I', @errmsg output
   		if @rcode <> 0
   			begin
   			select @errortext = @errorstart + ' - Discount Offered Expense Account ' + isnull(@errmsg,'')
   			goto MSWD_error
   			end
   		end
   
   	-- -- -- add AP Line distribution entry
   	insert bMSAP(MSCo, Mth, BatchId, BatchSeq, GLCo, GLAcct, PayCode, PayRate, TransMth, MSTrans,
   			PayBasis, PayTotal, DiscOff, HaulPayTaxType, HaulPayTaxCode, HaulPayTaxAmt, TaxGroup)
   	values(@msco, @mth, @batchid, @seq, @msglco, @haulexpglacct, @paycode, @payrate, @transmth, @mstrans,
   			@paybasis, @paytotal, @discoff, @haulpaytaxtype, @haulpaytaxcode, @haulpaytaxamt, @taxgroup)

   	-- Haul Expense debits
   	if @discoff <> 0 and @netamtopt = 'Y'   -- only used if interfacing net
   		begin
   		-- -- -- haul expense debit for net
   		update bMSWG set Amount = Amount + @paytotal - @discoff
   		where MSCo=@msco and Mth=@mth and BatchId=@batchid and GLCo=@msglco and GLAcct=@haulexpglacct and BatchSeq=@seq
   		if @@rowcount = 0
   			begin
   			insert bMSWG(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, VendorGroup, HaulVendor, APRef, InvDescription,
   						InvDate, APTrans, Amount)
   			values(@msco, @mth, @batchid, @msglco, @haulexpglacct, @seq, @vendorgroup, @haulvendor, @apref, @description,
   						@invdate, null, @paytotal - @discoff)
   			end
   		-- -- -- discount offered debit
   		update bMSWG set Amount = Amount + @discoff
   		where MSCo=@msco and Mth=@mth and BatchId=@batchid and GLCo=@msglco and GLAcct=@discoffglacct and BatchSeq=@seq
   		if @@rowcount = 0
   			begin
   			insert bMSWG(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, VendorGroup, HaulVendor, APRef, InvDescription,
   						InvDate, APTrans, Amount)
   			values(@msco, @mth, @batchid, @msglco, @discoffglacct, @seq, @vendorgroup, @haulvendor, @apref, @description,
   						@invdate, null, @discoff)
   			end
   		end
   	else
   		begin
   		update bMSWG set Amount = Amount + @paytotal
   		where MSCo=@msco and Mth=@mth and BatchId=@batchid and GLCo=@msglco and GLAcct=@haulexpglacct and BatchSeq=@seq
   		if @@rowcount = 0
   			begin
   			insert bMSWG(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, VendorGroup, HaulVendor, APRef, InvDescription,
   						InvDate, APTrans, Amount)
   			values(@msco, @mth, @batchid, @msglco, @haulexpglacct, @seq, @vendorgroup, @haulvendor, @apref, @description,
   						@invdate, null, @paytotal)
   			end
   		end
   
   	-- AP Expense Payables credit
   	update bMSWG set Amount = Amount - @paytotal
   	where MSCo=@msco and Mth=@mth and BatchId=@batchid and GLCo=@apglco and GLAcct=@apexpglacct and BatchSeq=@seq
   	if @@rowcount = 0
   		begin
   		insert bMSWG(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, VendorGroup, HaulVendor, APRef, InvDescription,
                   	InvDate, APTrans, Amount)
   		values(@msco, @mth, @batchid, @apglco, @apexpglacct, @seq, @vendorgroup, @haulvendor, @apref, @description,
                   	@invdate, null, -@paytotal)
   		end


	--TK-01835 -Create entries for Haul Payment Tax
	----TFS_56370
	IF (@haulpaytaxcode is not null) and (isnull(@haulpaytaxamt,0) <> 0)
	BEGIN
		--TaxGroup:  We get Tax Group above. However, we really do not care about it until here.  If Tax Group is null
		--in this block then we are going to raise an error.
		if @taxgrouprcode <> 0
		begin
			select @errmsg = 'Tax Group:' + isnull(convert(varchar(3),@taxgroup), '') + isnull(@taxgroupmsg,''), @rcode = 1 
			goto bspexit
		end
		   		          
		exec bspHQTaxRateGetAll @taxgroup, @haulpaytaxcode, @invdate, @valueadd output, @taxrate output, @gstrate output, @pstrate output, 
		@crdGLAcct output, @crdRetgGLAcct output, @dbtGLAcct output, @dbtRetgGLAcct output, @crdGLAcctPST output, 
		@crdRetgGLAcctPST output, @crdRetgGLAcctGST output, NULL, @msg output 

--Begin GST/PST
		
		if isnull(@valueadd,'N') = 'Y' -- VAT value added tax
		begin	
			/* Breakout and establish all VAT related tax amounts now. */
			if @pstrate = 0
			begin
				/* When @pstrate = 0:  Either VAT SingleLevel using GST only, or VAT MultiLevel GST/PST with PST set to 0.00 tax rate. */
				select @payTaxAmt = @haulpaytaxamt 
				select @gstTaxAmt = @payTaxAmt
				select @VATgstTaxAmt = @gstTaxAmt 
				select @VATpstTaxAmt = 0
			end
			else
			begin
				select @payTaxAmt = @haulpaytaxamt 
				select @gstTaxAmt = case @haulpaytaxrate when 0 then 0 else (@payTaxAmt * @gstrate) / @haulpaytaxrate end	
				select @pstTaxAmt = @payTaxAmt - @gstTaxAmt	
				select @VATgstTaxAmt = @gstTaxAmt
				select @VATpstTaxAmt = @pstTaxAmt
			end		
		end
		
		----TFS-49547
		IF @VATgstTaxAmt IS NULL SET @VATgstTaxAmt = 0
		IF @VATpstTaxAmt IS NULL SET @VATpstTaxAmt = 0
		--End GST/PST		
		
		if @VATpstTaxAmt <> 0
		begin
			update bMSWG set Amount = Amount + @VATpstTaxAmt
			where MSCo=@msco and Mth=@mth and BatchId=@batchid and GLCo=@msglco and GLAcct=@haulexpglacct and BatchSeq=@seq
			if @@rowcount = 0
			begin
				insert bMSWG(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, VendorGroup, HaulVendor, APRef, InvDescription,
				InvDate, APTrans, Amount)
				values(@msco, @mth, @batchid, @msglco, @mswgglacct, @seq, @vendorgroup, @haulvendor, @apref, @description,
				@invdate, null, @VATpstTaxAmt)
			end	
		end
		
		
		-- post GST portion of tax to GST Payables
		if @VATgstTaxAmt <> 0 
		BEGIN  
			SELECT @mswgglacct = isnull(@dbtGLAcct, @haulexpglacct)
			update bMSWG set Amount = Amount + @VATgstTaxAmt
			where MSCo=@msco and Mth=@mth and BatchId=@batchid and GLCo=@msglco and GLAcct=@mswgglacct and BatchSeq=@seq
			if @@rowcount = 0
			begin
				insert bMSWG(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, VendorGroup, HaulVendor, APRef, InvDescription,
				InvDate, APTrans, Amount)
				values(@msco, @mth, @batchid, @msglco, @mswgglacct, @seq, @vendorgroup, @haulvendor, @apref, @description,
				@invdate, null, @VATgstTaxAmt)
			end	
		end

   		update bMSWG set Amount = Amount - @VATpstTaxAmt - @VATgstTaxAmt
   		where MSCo=@msco and Mth=@mth and BatchId=@batchid and GLCo=@apglco and GLAcct=@apexpglacct and BatchSeq=@seq
   		if @@rowcount = 0
   		begin
	   		insert bMSWG(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, VendorGroup, HaulVendor, APRef, InvDescription,
                   	InvDate, APTrans, Amount)
   			values(@msco, @mth, @batchid, @apglco, @apexpglacct, @seq, @vendorgroup, @haulvendor, @apref, @description,
                   	@invdate, null, (-@VATpstTaxAmt - @VATgstTaxAmt))
   		end
   				
   END
      
	-- add Intercompany entries if needed
	if @apglco <> @msglco
	begin
		-- get interco GL Accounts
		select @arglacct = ARGLAcct, @apglacct = APGLAcct
		from bGLIA with (Nolock) where ARGLCo = @apglco and APGLCo = @msglco
		if @@rowcount = 0
		begin
			select @errortext = @errorstart + ' - Intercompany Accounts not setup in GL for these companies!'
			goto MSWD_error
		end

		-- validate Intercompany AR GL Account
		exec @rcode = dbo.bspGLACfPostable @apglco, @arglacct, 'R', @errmsg output
		if @rcode <> 0
		begin
			select @errortext = @errorstart + ' - Intercompany AR Account  ' + isnull(@errmsg,'')
			goto MSWD_error
		end

		-- validate Intercompany AP GL Account
		exec @rcode = dbo.bspGLACfPostable @msglco, @apglacct, 'P', @errmsg output
		if @rcode <> 0
		begin
			select @errortext = @errorstart + ' - Intercompany AP Account  ' + isnull(@errmsg,'')
			goto MSWD_error
		end

		--TK-01835 - Include @haulpaytaxamt into intercompany amts.  
		-- -- -- set @inter_amount to paytotal - discoff or paytotal
		if @netamtopt = 'Y'
			select @inter_amount = @paytotal - @discoff + isnull(@haulpaytaxamt,0)
		else
			select @inter_amount = @paytotal + isnull(@haulpaytaxamt,0)

		--PRINT 'Intercompany Amounts: ' + dbo.vfToString(@paytotal) + ','
		--							   + dbo.vfToString(@discoff) + ','
		--							   + dbo.vfToString(@haulpaytaxamt) + ','
		--							   + dbo.vfToString(@VATgstTaxAmt) + ','
		--							   + dbo.vfToString(@VATpstTaxAmt) + ','

		-- Intercompany AR debit (posted in AP GL Co#)
		update bMSWG set Amount = Amount + @inter_amount
		where MSCo=@msco and Mth=@mth and BatchId=@batchid and GLCo=@apglco and GLAcct=@arglacct and BatchSeq=@seq
		if @@rowcount = 0
		begin
			insert bMSWG(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, VendorGroup, HaulVendor, APRef, InvDescription,
			InvDate, APTrans, Amount)
			values(@msco, @mth, @batchid, @apglco, @arglacct, @seq, @vendorgroup, @haulvendor, @apref, @description,
			@invdate, null, @inter_amount)
		end
		
		

		-- Intercompany AP credit (posted in IN/MS Co#)
		update bMSWG set Amount = Amount - @inter_amount
		where MSCo=@msco and Mth=@mth and BatchId=@batchid and GLCo=@msglco and GLAcct=@apglacct and BatchSeq=@seq
		if @@rowcount = 0
		begin
			insert bMSWG(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, VendorGroup, HaulVendor, APRef, InvDescription,
			InvDate, APTrans, Amount)
			values(@msco, @mth, @batchid, @msglco, @apglacct, @seq, @vendorgroup, @haulvendor, @apref, @description,
			@invdate, null, -@inter_amount)
		end
	end
   
   		-- finished with GL distributions
   		goto MSWD_loop
   
   
   MSWD_error:	-- record error message and go to next Worksheet Detail
       exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
       if @rcode <> 0 goto bspexit
       goto MSWD_loop
   
   MSWD_end:   -- finished with Worksheet Detail
       close bcMSWD
       deallocate bcMSWD
       set @openMSWDcursor = 0
       goto MSWH_loop  -- next Worksheet Header
   
   MSWH_error:	-- record error message and go to next Worksheet Header
    	exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
       if @rcode <> 0 goto bspexit
       goto MSWH_loop
   
   MSWH_end:   -- finished with Worksheet Headers
       close bcMSWH
       deallocate bcMSWH
       set @openMSWHcursor = 0
   
 
   -- make sure debits and credits balance
   select @glco = m.GLCo
   from bMSWG m with (Nolock) join bGLAC g with (Nolock) on m.GLCo = g.GLCo and m.GLAcct = g.GLAcct
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
       if @openMSWDcursor = 1
     		begin
     		close bcMSWD
     		deallocate bcMSWD
     		end
        if @openMSWHcursor = 1
     		begin
     		close bcMSWH
     		deallocate bcMSWH
     		end
   
       if @rcode <> 0 select @errmsg = isnull(@errmsg,'')
     	return @rcode





GO
GRANT EXECUTE ON  [dbo].[bspMSWHVal] TO [public]
GO
