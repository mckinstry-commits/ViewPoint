SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*******************************************************/
CREATE    procedure [dbo].[bspMSLBValDist]
/*****************************************************************************
* Created By:	GG 11/06/00
* Modified By:	GG 07/11/02 - #13929 - pass @hrs to bspMSLBValRev for update to bMSEM
*				GF 05/02/04 - #24418 - pass @emgroup and @revcode to bspMSLBValJob procedure
*				GF 07/08/2008 - issue #128290 international tax GST/PST
*				MV 02/04/10 - #136500 - bspHQTaxRateGetAll added NULL output param
*				MV 10/25/11 - TK-09243 - bspHQTaxRateGetAll added NULL output param
*
* USAGE:
*   Called by main MS Hauler Time Sheet Batch validation procedure (bspMSHBVal) to
*   create JC, EM, and GL distributions for a single sequence.
*
*   Executes bspMSLBValJob and bspMSLBValRev based on
*   sale type and haul info to create distributions bMSJC, bMSEM,
*   bMSRB, and bMSGL.
*
*   Errors in batch added to bHQBE using bspHQBEInsert
*
* INPUT PARAMETERS
*   @msco          MS/IN Co#
*   @mth           Batch month
*   @batchid       Batch ID
*   @seq           Batch Sequence
*   @haulline      Haul Line
*   @oldnew        0 = old (use old values from bMSHB and bMSLB, reverse sign on amounts),
*                  1 = new (use current values from bMSHB and bMSLB)
*
* OUTPUT PARAMETERS
*   @errmsg        error message
*
*******************************************************************************/
    (@msco bCompany, @mth bMonth, @batchid bBatchID, @seq int, @haulline smallint,
     @oldnew tinyint, @errmsg varchar(255) output)
as
set nocount on
    
declare @rcode int, @errorstart varchar(30), @errortext varchar(255), @msglco bCompany, @intercoinv bYN,
        @matlcategory varchar(10), @stdum bUM, @toglco bCompany, @toinvglacct bGLAcct, @umconv bUnitCost,
        @intranstype varchar(10), @glco bCompany, @glacct bGLAcct, @toco bCompany, @lshaulrevequipglacct bGLAcct,
        @lshaulrevoutglacct bGLAcct, @lchaulrevequipglacct bGLAcct, @lchaulrevoutglacct bGLAcct, @lmhaulrevequipglacct bGLAcct,
        @lmhaulrevoutglacct bGLAcct, @haulrevglacct bGLAcct, @taxglacct bGLAcct, @arglacct bGLAcct, @apglacct bGLAcct,
        @gltotal bDollar
    
    --bMSHB declares
declare @saledate bDate, @haultype char(1), @vendorgroup bGroup, @haulvendor bVendor, @emco bCompany,
        @equipment bEquip, @emgroup bGroup, @prco bCompany, @employee bEmployee
    
    -- bMSLB declares
declare @mstrans bTrans, @fromloc bLoc, @saletype char(1), @custgroup bGroup, @customer bCustomer,
        @custjob varchar(20), @custpo varchar(20), @jcco bCompany, @job bJob, @phasegroup bGroup,
        @inco bCompany, @toloc bLoc, @matlgroup bGroup, @material bMatl, @matlum bUM, @hrs bHrs,
        @haulcode bHaulCode, @haulphase bPhase, @hauljcct bJCCType, @haulbasis bUnits, @haultotal bDollar,
        @revcode bRevCode, @revbasis bUnits, @revrate bUnitCost, @revtotal bDollar, @taxgroup bGroup,
        @taxcode bTaxCode, @taxtype tinyint, @taxbasis bDollar, @taxtotal bDollar,
		----International Sales Tax
		@taxrate bRate, @gstrate bRate, @pstrate bRate, @valueadd varchar(1), @dbtglacct bGLAcct,
		@HQTXcrdGLAcct bGLAcct, @HQTXcrdGLAcctPST bGLAcct, @TaxAmount bDollar, @TaxAmountPST bDollar,
		@gsttaxamt bDollar


select @rcode = 0, @errorstart = 'Seq#' + convert(varchar(6),@seq) + ' Line#' + convert(varchar(6),@haulline)
    
    -- get MS Company info
    select @msglco = GLCo, @intercoinv = InterCoInv
    from bMSCO where MSCo = @msco
    if @@rowcount = 0
            begin
            select @errmsg = 'Missing MS Company!', @rcode = 1  -- already validated
     	    goto bspexit
            end
    
-- get old info from batch entry, reverse sign on units and totals
if @oldnew = 0
    begin
    select @saledate = OldSaleDate, @haultype = OldHaulerType, @vendorgroup = OldVendorGroup, @haulvendor = OldHaulVendor,
	  @emco = OldEMCo, @equipment = OldEquipment, @emgroup = EMGroup, @prco = OldPRCo, @employee = OldEmployee
    from bMSHB where Co = @msco and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
    if @@rowcount = 0
        begin
        select @errmsg = 'Missing Batch Sequence!', @rcode = 1
 	   goto bspexit
        end
    select @mstrans = MSTrans, @fromloc = OldFromLoc, @saletype = OldSaleType, @custgroup = OldCustGroup,
        @customer = OldCustomer, @custjob = OldCustJob, @custpo = OldCustPO, @jcco = OldJCCo, @job = OldJob,

        @phasegroup = OldPhaseGroup, @inco = OldINCo, @toloc = OldToLoc, @matlgroup = OldMatlGroup, @material = OldMaterial,
        @matlum = OldUM, @hrs = -(OldHours), @haulcode = OldHaulCode, @haulphase = OldHaulPhase,
        @hauljcct = OldHaulJCCType, @haulbasis = -(OldHaulBasis), @haultotal = -(OldHaulTotal), @revcode = OldRevCode,
        @revbasis = -(OldRevBasis), @revrate = OldRevRate, @revtotal = -(OldRevTotal), @taxgroup = OldTaxGroup,
        @taxcode = OldTaxCode, @taxtype = OldTaxType, @taxbasis = -(OldTaxBasis), @taxtotal = -(OldTaxTotal)
    from bMSLB where Co = @msco and Mth = @mth and BatchId = @batchid and BatchSeq = @seq and HaulLine = @haulline
    if @@rowcount = 0
        begin
        select @errmsg = 'Missing Haul Line!', @rcode = 1
 	    goto bspexit
        end
    end

-- get new info from batch entry
if @oldnew = 1
    begin
    select @saledate = SaleDate, @haultype = HaulerType, @vendorgroup = VendorGroup, @haulvendor = HaulVendor,
        @emco = EMCo, @equipment = Equipment, @emgroup = EMGroup, @prco = PRCo, @employee = Employee
    from bMSHB where Co = @msco and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
    if @@rowcount = 0
        begin
        select @errmsg = 'Missing Batch Sequence!', @rcode = 1
 	    goto bspexit
        end
    select @mstrans = MSTrans, @fromloc = FromLoc, @saletype = SaleType, @custgroup = CustGroup,
        @customer = Customer, @custjob = CustJob, @custpo = CustPO, @jcco = JCCo, @job = Job,
        @phasegroup = PhaseGroup, @inco = INCo, @toloc = ToLoc, @matlgroup = MatlGroup, @material = Material,
        @matlum = UM, @hrs = Hours, @haulcode = HaulCode, @haulphase = HaulPhase,
        @hauljcct = HaulJCCType, @haulbasis = HaulBasis, @haultotal = HaulTotal, @revcode = RevCode,
        @revbasis = RevBasis, @revrate = RevRate, @revtotal = RevTotal, @taxgroup = TaxGroup,
        @taxcode = TaxCode, @taxtype = TaxType, @taxbasis = TaxBasis, @taxtotal = TaxTotal
    from bMSLB where Co = @msco and Mth = @mth and BatchId = @batchid and BatchSeq = @seq and HaulLine = @haulline
    if @@rowcount = 0
        begin
        select @errmsg = 'Missing Haul Line!', @rcode = 1
 	    goto bspexit
        end
    end
    
-- get info from Material
select @matlcategory = Category, @stdum = StdUM
from bHQMT where MatlGroup = @matlgroup and Material = @material
if @@rowcount = 0
    begin
    select @errmsg = 'Missing Material!' + 'MatlGroup: ' + convert(varchar(4),@matlgroup) + ' Material: ' + isnull(@material,'') + '.', @rcode = 1
 	goto bspexit
    end
    
-- get Job Expense GL Account for material
if @saletype = 'J'
    begin
    select @toglco = GLCo from bJCCO where JCCo = @jcco
    if @@rowcount = 0
        begin
        select @errmsg = 'Invalid JC Co#', @rcode = 1   -- already validated
        goto bspexit
        end
    end
    
-- get Inventory GL Account for 'sell to' Location
if @saletype = 'I'
    begin
    select @toglco = GLCo from bINCO where INCo = @inco
    if @@rowcount = 0
        begin
        select @errmsg = 'Invalid Sell To IN Co#', @rcode = 1   -- already validated
        goto bspexit
        end
    end




---- process Job or Inventory sale unless posted to another GL Co# and not using Interco Invoicing option
if @saletype in ('J','I') and (@toglco = @msglco or @intercoinv = 'N')
	begin
	select @HQTXcrdGLAcct = null, @HQTXcrdGLAcctPST = null, @TaxAmount = 0, @TaxAmountPST = 0,
			@gsttaxamt = 0, @dbtglacct = null, @valueadd = 'N'
	---- will get tax information at this point. may need to back out GST for the Job or Inventory Sale
	---- if the GST is split out and we have a debit account ITC then the tax amount that is expensed
	---- with the job or inventory sale will have the GST portion backed out of the tax amount.
	if @taxtotal <> 0
		begin
		---- get tax rates for international
		exec @rcode = dbo.bspHQTaxRateGetAll @taxgroup, @taxcode, @saledate, @valueadd output,
				@taxrate output, @gstrate output, @pstrate output, @HQTXcrdGLAcct output,
				null, @dbtglacct output, null, @HQTXcrdGLAcctPST output, null, NULL, NULL, @errmsg output
		if @rcode <> 0
			begin
			select @errortext = @errorstart + ' - Tax Code: ' + isnull(@taxcode,'') + ' is not valid. ' + isnull(@errmsg,'')
			exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
			goto bspexit
			end

		---- Break out PST/GST tax amount before doing distributions
		if @valueadd <> 'Y'
			begin
			select @TaxAmount = @taxtotal
			end
		else
			begin
			---- Breakout and establish all VAT related tax amounts
			if @pstrate = 0
				begin
				/* When @pstrate = 0:  Either VAT SingleLevel using GST only, or VAT MultiLevel GST/PST with PST set to 0.00 tax rate. */
				select @TaxAmount = @taxtotal
				select @gsttaxamt = @taxtotal
				end
			else
				begin
				---- VAT MultiLevel:  Breakout GST and PST for proper GL distribution
				if @taxrate <> 0
					begin
					select @TaxAmount = (@taxtotal * @gstrate) / @taxrate		--GST TaxAmount
					select @TaxAmountPST = @taxtotal - @TaxAmount				--PST TaxAmount
					select @gsttaxamt = @TaxAmount
					end
				end

			---- if the user set up a ValueAdd GST taxcode but is NOT tracking the GST in an ITC account
			---- then we will not break out the GST tax for the Job or Inventory sale expense.
			if @dbtglacct is null
				begin
				select @gsttaxamt = 0
				end
			end
		end

	---- process Job sale unless posted to another GL Co# and using Interco invoicing
	if @saletype = 'J' and (@toglco = @msglco or @intercoinv = 'N')
		begin
		exec @rcode = dbo.bspMSLBValJob @msco, @mth, @batchid, @seq, @haulline, @oldnew, @fromloc, @mstrans,
			@saledate, @vendorgroup, @haulvendor, @matlgroup, @material, @jcco, @job, @phasegroup, @toglco,
			@emco, @equipment, @emgroup, @revcode, @prco, @employee, @matlum, @stdum, @umconv, @haulcode, 
			@haulphase, @hauljcct, @haulbasis, @haultotal, @hrs, @taxgroup, @taxcode, @taxtype,
			@taxbasis, @taxtotal, @gsttaxamt, @errmsg output
		if @rcode = 1 goto bspexit
		end

	---- process Inventory sale unless posted to another GL Co# and using Interco invoicing option
	if @saletype = 'I' and (@toglco = @msglco or @intercoinv = 'N')
		begin
		exec @rcode = dbo.bspMSLBValInv @msco, @mth, @batchid, @seq, @haulline, @fromloc, @inco,
			@toloc, @matlgroup, @material, @matlcategory, @stdum, @matlum, @oldnew, @mstrans,
			@saledate, @haultotal, @taxtotal, @gsttaxamt, @errmsg output
		if @rcode = 1 goto bspexit
		end
	end



/* GL distributions in MS/IN GL Co# for Job and Inventory sales.  Similar
 * distributions made for Customer and Interco sales when invoice batch is validated */
if @saletype in ('J','I') and (@toglco = @msglco or @intercoinv = 'N')
    begin
    select @toco = case @saletype when 'J' then @jcco else @inco end
    select @lshaulrevequipglacct = null, @lshaulrevoutglacct = null, @lchaulrevequipglacct = null, @lchaulrevoutglacct = null

    -- get default GL Accounts based on Location
    select @lmhaulrevequipglacct = case @saletype when 'J' then JobHaulRevEquipGLAcct when 'I' then InvHaulRevEquipGLAcct else null end,
        @lmhaulrevoutglacct = case @saletype when 'J' then JobHaulRevOutGLAcct when 'I' then InvHaulRevOutGLAcct else null end
    from bINLM where INCo = @msco and Loc = @fromloc
    if @@rowcount = 0
        begin
        select @errmsg = 'Missing Location!', @rcode = 1   -- already validated
        goto bspexit
        end
    -- get any GL Account overrides based on 'sell to' Co#
    select @lshaulrevequipglacct = case @saletype when 'J' then JobHaulRevEquipGLAcct else InvHaulRevEquipGLAcct end,
        @lshaulrevoutglacct = case @saletype when 'J' then JobHaulRevOutGLAcct else InvHaulRevOutGLAcct end
    from bINLS
    where INCo = @msco and Loc = @fromloc and Co = @toco
    -- get any GL Account overrides based on 'sell to' Co# and Category
    select @lchaulrevequipglacct = case @saletype when 'J' then JobHaulRevEquipGLAcct else InvHaulRevEquipGLAcct end,
        @lchaulrevoutglacct = case @saletype when 'J' then JobHaulRevOutGLAcct else InvHaulRevOutGLAcct end
    from bINLC
    where INCo = @msco and Loc = @fromloc and Co = @toco and MatlGroup = @matlgroup and Category = @matlcategory

    -- Haul Revenue credit
    if @haultotal <> 0
        begin
        -- get Haul Revenue GL Accounts (Equip or Outside)
        if @haultype = 'E' select @haulrevglacct = isnull(@lchaulrevequipglacct,isnull(@lshaulrevequipglacct,@lmhaulrevequipglacct))
        if @haultype = 'H' select @haulrevglacct = isnull(@lchaulrevoutglacct,isnull(@lshaulrevoutglacct,@lmhaulrevoutglacct))

        -- validate Haul Revenue Account
        exec @rcode = bspGLACfPostable @msglco, @haulrevglacct, 'I', @errmsg output
        if @rcode <> 0
            begin
            select @errortext = @errorstart + ' - Haul Revenue Account ' + @errmsg
            exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
  	        goto bspexit
            end
        -- Haul Revenue credit
        update bMSGL set Amount = Amount - @haultotal
        where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @msglco and GLAcct = @haulrevglacct
            and BatchSeq = @seq and HaulLine = @haulline and OldNew = @oldnew
        if @@rowcount = 0
			begin
            insert bMSGL(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, HaulLine, OldNew, MSTrans, Ticket, SaleDate,
                FromLoc, MatlGroup, Material, SaleType, JCCo, Job, INCo, ToLoc, Amount)
            values(@msco, @mth, @batchid, @msglco, @haulrevglacct, @seq, @haulline, @oldnew, @mstrans, null, @saledate,
                @fromloc, @matlgroup, @material, @saletype, @jcco, @job, @inco, @toloc, -@haultotal)
			end
        end
    
    ---- Tax Accrual credit
    if @taxtotal <> 0
        begin
		---- posted in MS GL Co# if 'sales' or 'vat' tax, posted in 'sell to' GL Co# if 'use' tax #128290
		select @glco = case @taxtype when 1 then @msglco when 2 then @toglco when 3 then @msglco else 0 end

		---- validate GST tax expense account
		if @dbtglacct is not null
			begin
			exec @rcode = dbo.bspGLACfPostable @glco, @dbtglacct, 'N', @errmsg output
			if @rcode <> 0
				begin
				select @errortext = @errorstart + ' - GST Expense GL account ' + isnull(@errmsg,'')
				exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
				goto bspexit
				end

			---- GST Tax Expense
			update bMSGL set Amount = @gsttaxamt
			where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @glco and GLAcct = @dbtglacct
			and BatchSeq = @seq and HaulLine = 0 and OldNew = @oldnew
			if @@rowcount = 0
				begin
				insert bMSGL(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, HaulLine, OldNew, MSTrans, Ticket, SaleDate,
					FromLoc, MatlGroup, Material, SaleType, JCCo, Job, INCo, ToLoc, Amount)
				values(@msco, @mth, @batchid, @glco, @dbtglacct, @seq, @haulline, @oldnew, @mstrans, null, @saledate,
					@fromloc, @matlgroup, @material, @saletype, @jcco, @job, @inco, @toloc, @gsttaxamt)
				end
			end
		
		---- validate tax accrual account
		exec @rcode = dbo.bspGLACfPostable @glco, @HQTXcrdGLAcct, 'N', @errmsg output
		if @rcode <> 0
			begin
			select @errortext = @errorstart + ' - Tax Accrual GL account ' + isnull(@errmsg,'')
			exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
			goto bspexit
			end
		---- Tax Accrual credit
		update bMSGL set Amount = Amount - @TaxAmount
		where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @glco and GLAcct = @HQTXcrdGLAcct
		and BatchSeq = @seq and HaulLine = 0 and OldNew = @oldnew
		if @@rowcount = 0
			begin
			insert bMSGL(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, HaulLine, OldNew, MSTrans, Ticket, SaleDate,
				FromLoc, MatlGroup, Material, SaleType, JCCo, Job, INCo, ToLoc, Amount)
			values(@msco, @mth, @batchid, @glco, @HQTXcrdGLAcct, @seq, @haulline, @oldnew, @mstrans, null, @saledate,
				@fromloc, @matlgroup, @material, @saletype, @jcco, @job, @inco, @toloc, -@TaxAmount)
			end

		---- validate PST tax accrual account if we have one
		if @pstrate <> 0 and @TaxAmountPST <> 0
			begin
			exec @rcode = dbo.bspGLACfPostable @glco, @HQTXcrdGLAcctPST, 'N', @errmsg output
			if @rcode <> 0
				begin
				select @errortext = @errorstart + ' - PST Tax Accrual GL account ' + isnull(@errmsg,'')
				exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
				goto bspexit
				end

			---- Tax Accrual credit - PST
			update bMSGL set Amount = Amount - @TaxAmountPST
			where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @glco and GLAcct = @HQTXcrdGLAcctPST
			and BatchSeq = @seq and HaulLine = 0 and OldNew = @oldnew
			if @@rowcount = 0
				begin
				insert bMSGL(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, HaulLine, OldNew, MSTrans, Ticket, SaleDate,
					FromLoc, MatlGroup, Material, SaleType, JCCo, Job, INCo, ToLoc, Amount)
				values(@msco, @mth, @batchid, @glco, @HQTXcrdGLAcctPST, @seq, @haulline, @oldnew, @mstrans, null, @saledate,
					@fromloc, @matlgroup, @material, @saletype, @jcco, @job, @inco, @toloc, -@TaxAmountPST)
				end
			end
		end

----        -- get Tax Accrual GL Account
----        select @taxglacct = GLAcct from bHQTX where TaxGroup = @taxgroup and TaxCode = @taxcode
----        if @@rowcount = 0
----            begin
----            select @errmsg = 'Invalid Tax Code!', @rcode = 1    -- already validated
----  	        goto bspexit
----            end
----        ---- posted in MS GL Co# if 'sales' tax, posted in 'sell to' GL Co# if 'use' tax
----        select @glco = case @taxtype when 1 then @msglco when 2 then @toglco else 0 end
----        -- validate Tax Accrual Account
----        exec @rcode = dbo.bspGLACfPostable @glco, @taxglacct, 'N', @errmsg output
----        if @rcode <> 0
----            begin
----            select @errortext = @errorstart + ' - Tax Accrual GL account ' + isnull(@errmsg,'')
----            exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
----  	        goto bspexit
----            end
----        -- Tax Accrual credit
----        update bMSGL set Amount = Amount - @taxtotal
----        where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @glco and GLAcct = @taxglacct
----            and BatchSeq = @seq and HaulLine = @haulline and OldNew = @oldnew
----        if @@rowcount = 0
----			begin
----            insert bMSGL(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, HaulLine, OldNew, MSTrans, Ticket, SaleDate,
----                FromLoc, MatlGroup, Material, SaleType, JCCo, Job, INCo, ToLoc, Amount)
----            values(@msco, @mth, @batchid, @glco, @taxglacct, @seq, @haulline, @oldnew, @mstrans, null, @saledate,
----                @fromloc, @matlgroup, @material, @saletype, @jcco, @job, @inco, @toloc, -@taxtotal)
----			end
----        end
    
    -- add Intercompany entries if needed
    if @toglco <> @msglco
        begin
        -- get interco GL Accounts
        select @arglacct = ARGLAcct, @apglacct = APGLAcct
        from bGLIA where ARGLCo = @msglco and APGLCo = @toglco
        if @@rowcount = 0
            begin
            select @errortext = @errorstart + ' - Intercompany Accounts not setup in GL for these companies!'
            exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
  	        goto bspexit
            end
        -- validate Intercompany AR GL Account
        exec @rcode = dbo.bspGLACfPostable @msglco, @arglacct, 'R', @errmsg output
        if @rcode <> 0
            begin
            select @errortext = @errorstart + ' - Intercompany AR Account  ' + isnull(@errmsg,'')
            exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
  	        goto bspexit
            end
        -- Intercompany AR debit (posted in IN/MS GL Co#)
        select @gltotal = @haultotal
		---- #128290
		if @taxtype = 1 select @gltotal = @gltotal + @taxtotal  -- include 'sales' tax, but not 'use' tax
		if @taxtype = 3 select @gltotal = @gltotal + @TaxAmountPST -- include 'VAT' tax, PST portion
        ---- if @taxtype = 1 select @gltotal = @gltotal + @taxtotal  -- include 'sales' tax, but not 'use' tax
        update bMSGL set Amount = Amount + @gltotal
        where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @msglco and GLAcct = @arglacct
            and BatchSeq = @seq and HaulLine = @haulline and OldNew = @oldnew
        if @@rowcount = 0
			begin
            insert bMSGL(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, HaulLine, OldNew, MSTrans, Ticket, SaleDate,
                FromLoc, MatlGroup, Material, SaleType, JCCo, Job, INCo, ToLoc, Amount)
            values(@msco, @mth, @batchid, @msglco, @arglacct, @seq, @haulline, @oldnew, @mstrans, null, @saledate,
                @fromloc, @matlgroup, @material, @saletype, @jcco, @job, @inco, @toloc, @gltotal)
			end

        -- validate Intercompany AP GL Account
        exec @rcode = dbo.bspGLACfPostable @toglco, @apglacct, 'P', @errmsg output
        if @rcode <> 0
            begin
            select @errortext = @errorstart + ' - Intercompany AP Account  ' + isnull(@errmsg,'')
            exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
  	        goto bspexit
            end
        -- Intercompany AP credit (posted in 'sell to' GL Co#)
        update bMSGL set Amount = Amount - @gltotal
        where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @toglco and GLAcct = @apglacct
            and BatchSeq = @seq and HaulLine = @haulline and OldNew = @oldnew
        if @@rowcount = 0
			begin
            insert bMSGL(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, HaulLine, OldNew, MSTrans, Ticket, SaleDate,
                FromLoc, MatlGroup, Material, SaleType, JCCo, Job, INCo, ToLoc, Amount)
            values(@msco, @mth, @batchid, @toglco, @apglacct, @seq, @haulline, @oldnew, @mstrans, null, @saledate,
                @fromloc, @matlgroup, @material, @saletype, @jcco, @job, @inco, @toloc, -@gltotal)
			end
        end
	end -- finished with distributions to MS/IN GL Co#




-- process Haul Expense and Equipment Revenue for all Sale Types
if @revtotal <> 0
    begin
    exec @rcode = dbo.bspMSLBValRev @msco, @mth, @batchid, @seq, @haulline, @oldnew, @fromloc, @saletype, @matlgroup,
        @matlcategory, @material, @toco, @msglco, @revtotal, @mstrans, @saledate, @custgroup,
        @customer, @custjob, @jcco, @job, @inco, @toloc, @emco, @equipment, @emgroup, @revcode, @phasegroup,
        @haulphase, @hauljcct, @prco, @employee, @revbasis, @revrate, @hrs, @errmsg output
    if @rcode = 1 goto bspexit
    end




bspexit:
	if @rcode <> 0 select @errmsg = isnull(@errmsg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSLBValDist] TO [public]
GO
