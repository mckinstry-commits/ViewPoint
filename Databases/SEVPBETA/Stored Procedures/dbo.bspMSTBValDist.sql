SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspMSTBValDist]
/*****************************************************************************
* Created By: GG 10/21/00
* Modified: GG 02/16/01 - improved error messages
*          GF 07/25/2001 - check @ecm before insert into bMSIN, might be null.
*			GG 11/12/01 - #15029 - pass @unitprice, @ecm to bspMSTBValJob
*			GG 02/13/02 - #16085 - fix cross-company search for 'sell to' Inventory GL Account
*			GG 07/11/02 - #13929 - pass Hours to bspMSTBValRev
*          DANF 09/05/02 - 17738 - Add Phase Group to bspJCCAGlacctDflt
*			GF 07/23/2003 - issue #21860 - need to get @umconv for material with material vendor. for jc distr.
*			GF 12/05/2003 - #23205 - check error messages, wrap concatenated values with isnull
*			GG 02/02/04 - #20538 - split GL units flag
*			GF 05/02/04 - #24418 - pass @emgroup and @revcode to bspMSTBValJob procedure
*			GF 06/16/2004 - #24845 - need to calculate @stkunits before checking GLFlag and @matlvendor is null for update to GL w/units
*			GF 07/06/2004 - #25035 - the TotalPrice column being updated to MSIN needs to be reversed. Like Posted and Stk.
*			GF 09/13/2006 - #122420 - read @haulvendor and pass to bspMSTBValJob as parameter
*			GF 06/23/2008 - issue #128290 international tax GST/PST
*			TJL 03/24/09 - Issue #132867 - ANSI Null evaluating FALSE instead of TRUE
*			GF 03/27/2010 - issue #129350 - surcharges
*			GF 05/26/2010 - issue #139945 surcharges for inventory sale distributions (IN/GL) changed based on burden.
*			GF 05/12/2011 - ISSUE #143976 surcharge with 'N' haul use own equip for inventory account.
*			MV 10/25/2011 - TK-09243 - added NULL param to bspHQTaxRateGetAll
*
*
*
* USAGE:
*   Called by main MS Ticket Batch validation procedure (bspMSTBVal) to
*   create IN, JC, EM, and GL distributions for a single sequence.
*
*   Executes bspMSTBValJob, bspMSTBValInv, and bspMSTBValRev based on
*   sale type and haul info to create distributions bMSJC, bMSIN, bMSEM,
*   bMSRB, and bMSGL.
*
*   Errors in batch added to bHQBE using bspHQBEInsert
*
* INPUT PARAMETERS
*   @msco          MS/IN Co#
*   @mth           Batch month
*   @batchid       Batch ID
*   @seq           Batch Sequence
*   @oldnew        0 = old (use old values from bMSTB, reverse sign on amounts),
*                  1 = new (use current values from bMSTB)
*
* OUTPUT PARAMETERS
*   @errmsg        error message
*
*******************************************************************************/
(@msco bCompany, @mth bMonth, @batchid bBatchID, @seq int, @oldnew tinyint, @errmsg varchar(255) output)
as
set nocount on

declare @rcode int, @errorstart varchar(10), @errortext varchar(255), @glunits bYN, @msglco bCompany,
     @intercoinv bYN, @matlcategory varchar(10), @stdum bUM, @lminvglacct bGLAcct, @lmcostglacct bGLAcct,
     @lmcustsalesglacct bGLAcct, @loinvglacct bGLAcct, @locostglacct bGLAcct, @locustsalesglacct bGLAcct,
     @invglacct bGLAcct, @costglacct bGLAcct, @custsalesglacct bGLAcct, @toglco bCompany, @jcmatlglacct bGLAcct,
     @toinvglacct bGLAcct, @umconv bUnitCost, @stkunits bUnits, @intranstype varchar(10), @glco bCompany,
     @glacct bGLAcct, @toco bCompany, @lssalesglacct bGLAcct, @lsqtyglacct bGLAcct, @lshaulrevequipglacct bGLAcct,
     @lshaulrevoutglacct bGLAcct, @lcsalesglacct bGLAcct, @lcqtyglacct bGLAcct, @lchaulrevequipglacct bGLAcct,
     @lchaulrevoutglacct bGLAcct, @lmsalesglacct bGLAcct, @lmqtyglacct bGLAcct, @lmhaulrevequipglacct bGLAcct,
     @lmhaulrevoutglacct bGLAcct, @salesglacct bGLAcct, @qtyglacct bGLAcct, @haulrevglacct bGLAcct, @taxglacct bGLAcct,
     @arglacct bGLAcct, @apglacct bGLAcct, @gltotal bDollar, @subtype char(1), @tomatlgroup bGroup

---- bMSTB declares
declare @mstrans bTrans,@saledate bDate, @fromloc bLoc, @ticket bTic, @vendorgroup bGroup, @matlvendor bVendor,
		@saletype char(1), @custgroup bGroup, @customer bCustomer, @custjob varchar(20), @custpo varchar(20), @jcco bCompany,
		@job bJob, @phasegroup bGroup, @inco bCompany, @toloc bLoc, @matlgroup bGroup, @material bMatl, @matlum bUM, @matlphase bPhase,
		@matljcct bJCCType, @matlunits bUnits, @unitprice bUnitCost, @ecm bECM, @matltotal bDollar, @matlcost bDollar,
		@haultype char(1), @emco bCompany, @equipment bEquip, @emgroup bGroup, @prco bCompany, @employee bEmployee, @hrs bHrs,
		@haulcode bHaulCode, @haulphase bPhase, @hauljcct bJCCType, @haulbasis bUnits, @haultotal bDollar,
		@revcode bRevCode, @revbasis bUnits, @revrate bUnitCost, @revtotal bDollar, @taxgroup bGroup,
		@taxcode bTaxCode, @taxtype tinyint, @taxbasis bDollar, @taxtotal bDollar, @haulvendor bVendor,
		----International Sales Tax
		@taxrate bRate, @gstrate bRate, @pstrate bRate, @valueadd varchar(1), @dbtglacct bGLAcct,
		@HQTXcrdGLAcct bGLAcct, @HQTXcrdGLAcctPST bGLAcct, @TaxAmount bDollar, @TaxAmountPST bDollar,
		@gsttaxamt bDollar,
		---- #129350
		@SurchargeKeyID bigint, @SurchargeCode varchar(10), @ParentKeyID bigint,
		@lmcustsurrevequipglacct bGLAcct, @lmjobsurrevequipglacct bGLAcct, @lminvsurrevequipglacct bGLAcct,
		@lmcustsurrevoutglacct bGLAcct, @lmjobsurrevoutglacct bGLAcct, @lminvsurrevoutglacct bGLAcct,
		@SurchargeTotal bDollar, @SurchargeTax bDollar, @burdencost varchar(1)
		---- #129350


select @rcode = 0, @errorstart = 'Seq#' + convert(varchar(6),@seq)
select @glunits = 'N'   -- flag to update units sold to GL
set @burdencost = 'N'

---- get MS Company info
select @msglco = GLCo, @intercoinv = InterCoInv
from dbo.bMSCO with (nolock) where MSCo = @msco
if @@rowcount = 0
	begin
	select @errmsg = 'Missing MS Company!', @rcode = 1  -- already validated
	goto bspexit
	end

---- get IN Company Info
select @burdencost = BurdenCost
from dbo.bINCO with (nolock) where INCo=@msco
if @@rowcount = 0 set @burdencost = 'N'

---- get old info from batch entry, reverse sign on units and totals
if @oldnew = 0
	begin
	select @mstrans = MSTrans, @saledate = OldSaleDate, @fromloc = OldFromLoc, @ticket = OldTic,
             @vendorgroup = OldVendorGroup, @matlvendor = OldMatlVendor, @saletype = OldSaleType, @custgroup = OldCustGroup,
             @customer = OldCustomer, @custjob = OldCustJob, @custpo = OldCustPO, @jcco = OldJCCo, @job = OldJob,
             @phasegroup = OldPhaseGroup, @inco = OldINCo, @toloc = OldToLoc, @matlgroup = OldMatlGroup, @material = OldMaterial,
             @matlum = OldUM, @matlphase = OldMatlPhase, @matljcct = OldMatlJCCType, @matlunits = -(OldMatlUnits),
             @unitprice = OldUnitPrice, @ecm = OldECM, @matltotal = -(OldMatlTotal), @matlcost = -(OldMatlCost),
             @haultype = OldHaulerType, @emco = OldEMCo, @equipment = OldEquipment, @emgroup = OldEMGroup,
             @prco = OldPRCo, @employee = OldEmployee, @hrs = -(OldHours), @haulcode = OldHaulCode, @haulphase = OldHaulPhase,
             @hauljcct = OldHaulJCCType, @haulbasis = -(OldHaulBasis), @haultotal = -(OldHaulTotal), @revcode = OldRevCode,
             @revbasis = -(OldRevBasis), @revrate = OldRevRate, @revtotal = -(OldRevTotal), @taxgroup = OldTaxGroup,
             @taxcode = OldTaxCode, @taxtype = OldTaxType, @taxbasis = -(OldTaxBasis), @taxtotal = -(OldTaxTotal),
			 @haulvendor = OldHaulVendor,
			 ---- #129350
			 @SurchargeKeyID = SurchargeKeyID, @SurchargeCode = SurchargeCode, @ParentKeyID = KeyID
			 ---- #129350
	from MSTB with (nolock) where Co = @msco and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
	if @@rowcount = 0
		begin
		select @errmsg = 'Missing Batch Sequence!', @rcode = 1
		goto bspexit
		end
	end

---- get new info from batch entry
if @oldnew = 1
	begin
	select @mstrans = MSTrans, @saledate = SaleDate, @fromloc = FromLoc, @ticket = Ticket,
             @vendorgroup = VendorGroup, @matlvendor = MatlVendor, @saletype = SaleType, @custgroup = CustGroup,
             @customer = Customer, @custjob = CustJob, @custpo = CustPO, @jcco = JCCo, @job = Job,
             @phasegroup = PhaseGroup, @inco = INCo, @toloc = ToLoc, @matlgroup = MatlGroup, @material = Material,
             @matlum = UM, @matlphase = MatlPhase, @matljcct = MatlJCCType, @matlunits = MatlUnits,
             @unitprice = UnitPrice, @ecm = ECM, @matltotal = MatlTotal, @matlcost = MatlCost,
             @haultype = HaulerType, @emco = EMCo, @equipment = Equipment, @emgroup = EMGroup,
             @prco = PRCo, @employee = Employee, @hrs = Hours, @haulcode = HaulCode, @haulphase = HaulPhase,
             @hauljcct = HaulJCCType, @haulbasis = HaulBasis, @haultotal = HaulTotal, @revcode = RevCode,
             @revbasis = RevBasis, @revrate = RevRate, @revtotal = RevTotal, @taxgroup = TaxGroup,
             @taxcode = TaxCode, @taxtype = TaxType, @taxbasis = TaxBasis, @taxtotal = TaxTotal,
			 @haulvendor = HaulVendor,
			 ---- #129350
			 @SurchargeKeyID = SurchargeKeyID, @SurchargeCode = SurchargeCode, @ParentKeyID = KeyID
			 ---- #129350
	from MSTB with (nolock) where Co = @msco and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
	if @@rowcount = 0
		begin
		select @errmsg = 'Missing Batch Sequence!', @rcode = 1
		goto bspexit
		end
	end

---- get info from Material
select @matlcategory = Category, @stdum = StdUM
from HQMT with (nolock) where MatlGroup = @matlgroup and Material = @material
if @@rowcount = 0
	begin
	select @errmsg = 'Missing Material!', @rcode = 1
	goto bspexit
	end

---- get 'Sell from' Location GL Accounts
select @lminvglacct = InvGLAcct, @lmcostglacct = CostGLAcct, @lmcustsalesglacct = CustSalesGLAcct,
		---- #129350
		@lmcustsurrevequipglacct = CustSurchargeRevEquipGLAcct,
		@lmjobsurrevequipglacct = JobSurchargeRevEquipGLAcct,
		@lminvsurrevequipglacct = InvSurchargeRevEquipGLAcct,
		@lmcustsurrevoutglacct = CustSurchargeRevOutGLAcct,
		@lmjobsurrevoutglacct = JobSurchargeRevOutGLAcct,
		@lminvsurrevoutglacct = InvSurchargeRevOutGLAcct
		---- #129350
from INLM with (nolock) where INCo = @msco and Loc = @fromloc
if @@rowcount = 0
	begin
	select @errmsg = 'Missing Location!', @rcode = 1   -- sales location already validated in bspMSTBVal
	goto bspexit
	end

---- #139945 check to see if there are any surcharges for the material and
---- get the surcharge total. We will need this total if doing an inventory sale
---- and using burdened cost.
set @SurchargeTotal = 0
set @SurchargeTax = 0
if @SurchargeKeyID is null and exists(select top 1 1 from dbo.bMSTB with (nolock)
			where Co=@msco and Mth=@mth and BatchId=@batchid and SurchargeKeyID=@ParentKeyID)
	begin
	---- we need to get the surcharge total differently if we are getting old or new
	---- get old info from batch entry, reverse sign for totals
	if @oldnew = 0
		begin
		select @SurchargeTotal = -(sum(OldMatlTotal) + sum(OldTaxTotal)),
			   @SurchargeTax = -(sum(OldTaxTotal))
		from dbo.bMSTB with (nolock) where Co=@msco and Mth=@mth
		and BatchId=@batchid and SurchargeKeyID=@ParentKeyID
		and BatchTransType in ('D','C')
		end
	else
		begin
		select @SurchargeTotal = sum(MatlTotal) + sum(TaxTotal),
			   @SurchargeTax = sum(TaxTotal)
		from dbo.bMSTB with (nolock) where Co=@msco and Mth=@mth
		and BatchId=@batchid and SurchargeKeyID=@ParentKeyID
		end
	end

---- check for GL Account overrides based on 'sell from' Location and Category
select @loinvglacct = InvGLAcct, @locostglacct = CostGLAcct, @locustsalesglacct = CustSalesGLAcct
from INLO with (nolock) 
where INCo = @msco and Loc = @fromloc and MatlGroup = @matlgroup and Category = @matlcategory

---- assign Inventory and Cost of Sales GL Accounts
select @invglacct = isnull(@loinvglacct,@lminvglacct), @costglacct = isnull(@locostglacct,@lmcostglacct),
		@custsalesglacct = isnull(@locustsalesglacct,@lmcustsalesglacct)

---- issue #143976
---- if a surcharge and no haul then assign the own equipent surcharge GL account in place of invglacct
IF @SurchargeKeyID IS NOT NULL AND @haultype = 'N'
	BEGIN
	IF @saletype = 'C' SET @invglacct = ISNULL(@lmcustsurrevequipglacct,@invglacct)
	IF @saletype = 'J' SET @invglacct = ISNULL(@lmjobsurrevequipglacct, @invglacct)
	IF @saletype = 'I' SET @invglacct = ISNULL(@lminvsurrevequipglacct, @invglacct)
	END

---- get Job Expense GL Account for material
if @saletype = 'J'
	begin
	select @toglco = GLCo from JCCO with (nolock) where JCCo = @jcco
	if @@rowcount = 0
		begin
		select @errmsg = 'Invalid JC Co#', @rcode = 1   ---- already validated
		goto bspexit
		end
	exec @rcode =dbo. bspJCCAGlacctDflt @jcco, @job, @phasegroup, @matlphase, @matljcct, 'N', @jcmatlglacct output, @errmsg output
	if @rcode = 1 goto bspexit
	end

---- get Inventory GL Account for 'sell to' Location
if @saletype = 'I'
	begin
   	select @toglco = i.GLCo, @tomatlgroup = h.MatlGroup	---- use 'sell to' group
   	from INCO i with (nolock) join bHQCO h with (nolock) on i.INCo = h.HQCo where i.INCo = @inco
	if @@rowcount = 0
		begin
		select @errmsg = 'Invalid Sell To IN Co#', @rcode = 1   -- already validated
		goto bspexit
		end
	exec @rcode = dbo.bspINGlacctDflt @inco, @toloc, @material, @tomatlgroup, @toinvglacct output,null, @errmsg  output
	if @rcode = 1 goto bspexit
	end


---- get material conversion factor
if @matlunits <> 0
	begin
	---- get stocked material info
	select @glunits = GLSaleUnits
	from INMT with (nolock) where INCo = @msco and Loc = @fromloc and MatlGroup = @matlgroup and Material = @material
	if @@rowcount = 0
		begin
   		if @matlvendor is null
   			begin
   			select @errmsg = 'Invalid material!', @rcode = 1    -- already validated
   			goto bspexit
   			end
   		else
   			begin
   			set @glunits = 'N'
   			end
   		end

	---- get UM conversion factor
   	set @umconv = 1
   	if @matlum <> @stdum
   		begin
   		select @umconv = Conversion
   		from INMU with (nolock) where INCo = @msco and Loc = @fromloc 
		and MatlGroup = @matlgroup and Material = @material and UM = @matlum
   		if @@rowcount = 0
			begin
   			if @matlvendor is null
   				begin
   				select @errmsg = 'Invalid UM!', @rcode = 1  ---- already validated
   				goto bspexit
   				end
   			else
   				begin
   				select @umconv = Conversion
   				from HQMU with (nolock)
   				where MatlGroup = @matlgroup and Material = @material and UM = @matlum
   				if @@rowcount = 0 set @umconv = 0
   				end
   			end
   		end
   
   	select @stkunits = @matlunits * @umconv  ---- convert units sold to std u/m
   	end

---- process material sold from stock, all sale types
if @matlvendor is null and @matlunits <> 0
	begin
	---- set GL Account based on Sale Type
	if @saletype = 'C' select @intranstype = 'AR Sale', @glco = @msglco, @glacct = @custsalesglacct, @subtype = 'I' -- Customer Sales
	if @saletype = 'J' select @intranstype = 'JC Sale', @glco = @toglco, @glacct = @jcmatlglacct, @subtype = 'J'    -- Job expense
	if @saletype = 'I' select @intranstype = 'IN Sale', @glco = @toglco, @glacct = @toinvglacct, @subtype = 'I' -- sell to Inventory
	---- validate Expense GL Account
	exec @rcode = dbo.bspGLACfPostable @glco, @glacct, @subtype, @errmsg output
	if @rcode <> 0
		begin
		if @saletype = 'C' select @errortext = @errorstart + ' - Customer Sales Account: ' + isnull(@errmsg,'')
		if @saletype = 'J' select @errortext = @errorstart + ' - Job Expense Account: ' + isnull(@errmsg,'')
		if @saletype = 'I' select @errortext = @errorstart + ' - Sell To Inventory Account: ' + isnull(@errmsg,'')
		exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
		goto bspexit
		end

	if isnull(@ecm,'') = '' select @ecm='E'
	---- #139945 only parent ticket
	if @SurchargeKeyID is null
		begin
		---- add Inventory distribution for sale
		insert bMSIN(MSCo, Mth, BatchId, INCo, Loc, MatlGroup, Material, INTransType, BatchSeq, HaulLine, OldNew,
				MSTrans, SaleDate, CustGroup, Customer, CustJob, CustPO, JCCo, Job, PhaseGroup, MatlPhase,
				MatlJCCType, SalesINCo, SalesLoc, GLCo, GLAcct, PostedUM, PostedUnits, PostedUnitCost,
				PostECM, PostedTotalCost, StkUM, StkUnits, StkUnitCost, StkECM, StkTotalCost, UnitPrice,
				PECM, TotalPrice)
		values(@msco, @mth, @batchid, @msco, @fromloc, @matlgroup, @material, @intranstype, @seq, 0, @oldnew,
				@mstrans, @saledate, @custgroup, @customer, @custjob, @custpo, @jcco, @job, @phasegroup, @matlphase,
				@matljcct, @inco, @toloc, @glco, @glacct, @matlum, -(isnull(@matlunits,0)), case when @matlcost is null then 0 else case
				isnull(@matlunits, 0) when 0 then 0 else(@matlcost / @matlunits) end end,
				'E', -(isnull(@matlcost,0)), @stdum, -(isnull(@stkunits,0)), case when @matlcost is null then 0 else case isnull(@stkunits, 0) when 0 then 0 
					else (@matlcost / @stkunits) end end, 'E', -(isnull(@matlcost,0)), @unitprice,@ecm, -(@matltotal)) ---- #24950 reverse @matltotal
		end
			
	---- validate Inventory GL Account
	exec @rcode = dbo.bspGLACfPostable @msglco, @invglacct, 'I', @errmsg output
	if @rcode <> 0
		begin
		select @errortext = @errorstart + ' - Inventory Account at Sell From Location: ' + isnull(@errmsg,'')
		exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
		goto bspexit
		end

	---- Inventory credit (use material cost from entry)
	update MSGL set Amount = isnull(Amount,0) - isnull(@matlcost,0)
	where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @msglco and GLAcct = @invglacct
	and BatchSeq = @seq and HaulLine = 0 and OldNew = @oldnew
	if @@rowcount = 0
		insert bMSGL(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, HaulLine, OldNew, MSTrans, Ticket, SaleDate,
				FromLoc, MatlGroup, Material, SaleType, CustGroup, Customer, CustJob, JCCo, Job, INCo, ToLoc, Amount)
		values(@msco, @mth, @batchid, @msglco, @invglacct, @seq, 0, @oldnew, @mstrans, @ticket, @saledate,
				@fromloc, @matlgroup, @material, @saletype, @custgroup, @customer, @custjob, @jcco, @job, @inco, @toloc, -(isnull(@matlcost,0)))
		---- validate Cost of Sales GL Account
		exec @rcode = dbo.bspGLACfPostable @msglco, @costglacct, 'I', @errmsg output
		if @rcode <> 0
			begin
			select @errortext = @errorstart + ' - Cost of Sales Account at Sell From Location: ' + isnull(@errmsg,'')
			exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
			goto bspexit
			end

		---- Cost of Sales debit (offsets Inventory credit)
		update MSGL set Amount = Amount + @matlcost
		where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @msglco and GLAcct = @costglacct
		and BatchSeq = @seq and HaulLine = 0 and OldNew = @oldnew
		if @@rowcount = 0
			insert bMSGL(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, HaulLine, OldNew, MSTrans, Ticket, SaleDate,
					FromLoc, MatlGroup, Material, SaleType, CustGroup, Customer, CustJob, JCCo, Job, INCo, ToLoc, Amount)
			values(@msco, @mth, @batchid, @msglco, @costglacct, @seq, 0, @oldnew, @mstrans, @ticket, @saledate,
					@fromloc, @matlgroup, @material, @saletype, @custgroup, @customer, @custjob, @jcco, @job, @inco, @toloc, isnull(@matlcost,0))
	end


---- process Job or Inventory sale unless posted to another GL Co# and not using Interco Invoicing option
if @saletype in ('J','I') and (@toglco = @msglco or @intercoinv = 'N')
	begin
	select @HQTXcrdGLAcct = null, @HQTXcrdGLAcctPST = null, @TaxAmount = 0, @TaxAmountPST = 0,
			@gsttaxamt = 0, @dbtglacct = null, @valueadd = 'N'
	---- will get tax information at this point. may need to back out GST for the Job or Inventory Sale
	---- if the GST is split out and we have a debit account ITC then the tax amount that is expensed
	---- with the job or inventory sale will have the GST portion backed out of the tax amount.
	
	---- #139945 when an inventory sale and using burden cost
	---- any surcharge tax is included in the parent tax amount.
	if @saletype = 'I' and @SurchargeKeyID is null and @burdencost = 'Y'
		begin
		set @taxtotal = @taxtotal + @SurchargeTax
		end
		
	if @taxtotal <> 0
		begin
		---- get tax rates for international
		exec @rcode = dbo.bspHQTaxRateGetAll @taxgroup, @taxcode, @saledate, @valueadd output,
				@taxrate output, @gstrate output, @pstrate output, @HQTXcrdGLAcct output,
				null, @dbtglacct output, null, @HQTXcrdGLAcctPST output, null, NULL, @errmsg output
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
		exec @rcode = dbo.bspMSTBValJob @msco, @mth, @batchid, @seq, @oldnew, @fromloc, @mstrans, @ticket,
				@saledate, @vendorgroup, @matlvendor, @matlgroup, @material, @jcco, @job, @phasegroup, @toglco,
				@jcmatlglacct, @emco, @equipment, @emgroup, @revcode, @prco, @employee, @matlphase, @matljcct, 
				@matlunits, @matlum, @stdum, @umconv, @matltotal, @haulcode, @haulphase, @hauljcct, @haulbasis, 
				@haultotal, @hrs, @taxgroup, @taxcode, @taxtype, @taxbasis, @taxtotal, @unitprice, @ecm,
				@haulvendor, @gsttaxamt, @SurchargeKeyID, @SurchargeCode, ---- #129350
				@errmsg output
		if @rcode = 1 goto bspexit
		end

	---- process Inventory sale unless posted to another GL Co# and using Interco invoicing option
	if @saletype = 'I' and (@toglco = @msglco or @intercoinv = 'N')
		begin
		exec @rcode = dbo.bspMSTBValInv @msco, @mth, @batchid, @seq, @fromloc, @inco, @toloc, @matlgroup,
				@material, @matlcategory, @stdum, @matlunits, @matlum, @oldnew, @mstrans, @ticket, @saledate,
				@matltotal, @unitprice, @ecm, @haultotal, @taxtotal, @gsttaxamt, @SurchargeKeyID,
				@SurchargeCode, @SurchargeTotal, @SurchargeTax, @errmsg output ----#129350
		if @rcode = 1 goto bspexit
		end
	end



---- GL distributions in MS/IN GL Co# for Job and Inventory sales.  Similar
---- distributions made for Customer and Interco sales when invoice batch is validated
if @saletype in ('J','I') and (@toglco = @msglco or @intercoinv = 'N')
	begin
	select @toco = case @saletype when 'J' then @jcco else @inco end
	select @lssalesglacct = null, @lsqtyglacct = null, @lshaulrevequipglacct = null, @lshaulrevoutglacct = null,
           @lcsalesglacct = null, @lcqtyglacct = null, @lchaulrevequipglacct = null, @lchaulrevoutglacct = null

	---- get default GL Accounts based on Location
	---- #129350
	if @SurchargeKeyID is null
		begin
		select @lmsalesglacct = case @saletype when 'J' then JobSalesGLAcct when 'I' then InvSalesGLAcct else null end,
			   @lmqtyglacct = case @saletype when 'J' then JobQtyGLAcct when 'I' then InvQtyGLAcct else null end,
			   @lmhaulrevequipglacct = case @saletype when 'J' then JobHaulRevEquipGLAcct
													  when 'I' then InvHaulRevEquipGLAcct
													  else null end,
			   @lmhaulrevoutglacct = case @saletype   when 'J' then JobHaulRevOutGLAcct
													  when 'I' then InvHaulRevOutGLAcct
													  else null end
		from dbo.INLM with (nolock) where INCo = @msco and Loc = @fromloc
		if @@rowcount = 0
			begin
			select @errmsg = 'Missing Location!', @rcode = 1   -- already validated
			goto bspexit
			end

		---- get any GL Account overrides based on 'sell to' Co#
		select @lssalesglacct = case @saletype when 'J' then JobSalesGLAcct else InvSalesGLAcct end,
				 @lsqtyglacct = case @saletype when 'J' then JobQtyGLAcct else InvQtyGLAcct end,
				 @lshaulrevequipglacct = case @saletype when 'J' then JobHaulRevEquipGLAcct else InvHaulRevEquipGLAcct end,
				 @lshaulrevoutglacct = case @saletype when 'J' then JobHaulRevOutGLAcct else InvHaulRevOutGLAcct end
		from INLS with (nolock) where INCo = @msco and Loc = @fromloc and Co = @toco
		---- get any GL Account overrides based on 'sell to' Co# and Category
		select @lcsalesglacct = case @saletype when 'J' then JobSalesGLAcct else InvSalesGLAcct end,
				 @lcqtyglacct = case @saletype when 'J' then JobQtyGLAcct else InvQtyGLAcct end,
				 @lchaulrevequipglacct = case @saletype when 'J' then JobHaulRevEquipGLAcct else InvHaulRevEquipGLAcct end,
				 @lchaulrevoutglacct = case @saletype when 'J' then JobHaulRevOutGLAcct else InvHaulRevOutGLAcct end
		from INLC with (nolock) where INCo = @msco and Loc = @fromloc and Co = @toco
		and MatlGroup = @matlgroup and Category = @matlcategory
		end
	else
		begin
		select @lcsalesglacct = null, @lssalesglacct = null, @lcqtyglacct = null, @lsqtyglacct = null
		select @lmsalesglacct = case @saletype when 'J' then JobSalesGLAcct when 'I' then InvSalesGLAcct else null end,
			   @lmqtyglacct = case @saletype when 'J' then JobQtyGLAcct when 'I' then InvQtyGLAcct else null end,
			   @lmhaulrevequipglacct = case @saletype when 'J' then JobSurchargeRevEquipGLAcct
												      when 'I' then InvSurchargeRevEquipGLAcct
													  else null end,
			   @lmhaulrevoutglacct = case @saletype   when 'J' then JobSurchargeRevOutGLAcct
													  when 'I' then InvSurchargeRevOutGLAcct
													  else null end
		from dbo.INLM with (nolock) where INCo = @msco and Loc = @fromloc
		if @@rowcount = 0
			begin
			select @errmsg = 'Missing Location!', @rcode = 1   -- already validated
			goto bspexit
			end
		end
---- #129350

	---- assign Sales and Qty Accounts
	select @salesglacct = isnull(@lcsalesglacct,isnull(@lssalesglacct,@lmsalesglacct)),
			 @qtyglacct = isnull(@lcqtyglacct,isnull(@lsqtyglacct,@lmqtyglacct))
	---- validate Sales Account
	exec @rcode = dbo.bspGLACfPostable @msglco, @salesglacct, 'I', @errmsg output
	if @rcode <> 0
		begin
		select @errortext = @errorstart + ' - Sales Account ' + isnull(@errmsg,'')
		exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
		goto bspexit
		end

	----#129350
	---- Sales credit for material (no haul or tax)
	if @SurchargeKeyID is null
		begin
		update MSGL set Amount = Amount - @matltotal
		where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @msglco and GLAcct = @salesglacct
		and BatchSeq = @seq and HaulLine = 0 and OldNew = @oldnew
		if @@rowcount = 0
			begin
			insert bMSGL(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, HaulLine, OldNew, MSTrans, Ticket, SaleDate,
					 FromLoc, MatlGroup, Material, SaleType, JCCo, Job, INCo, ToLoc, Amount)
			values(@msco, @mth, @batchid, @msglco, @salesglacct, @seq, 0, @oldnew, @mstrans, @ticket, @saledate,
					 @fromloc, @matlgroup, @material, @saletype, @jcco, @job, @inco, @toloc, -@matltotal)
			end
		end
	----#129350

	---- Qty Sold ----
	if @glunits ='Y' and @qtyglacct is not null and @SurchargeKeyID is null
		begin
		---- validate Sales Qty Account
		exec @rcode = dbo.bspGLACQtyVal @msglco, @qtyglacct, @errmsg output
		if @rcode <> 0
			begin
			select @errortext = @errorstart + ' - Sales Qty Account ' + isnull(@errmsg,'')
			exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
			goto bspexit
			end
		---- Sales Qty (credit unit sold)
		update MSGL set Amount = Amount - @stkunits
		where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @msglco and GLAcct = @qtyglacct
		and BatchSeq = @seq and HaulLine = 0 and OldNew = @oldnew
		if @@rowcount = 0
				insert bMSGL(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, HaulLine, OldNew, MSTrans, Ticket, SaleDate,
                     FromLoc, MatlGroup, Material, SaleType, JCCo, Job, INCo, ToLoc, Amount)
				values(@msco, @mth, @batchid, @msglco, @qtyglacct, @seq, 0, @oldnew, @mstrans, @ticket, @saledate,
                     @fromloc, @matlgroup, @material, @saletype, @jcco, @job, @inco, @toloc, -@stkunits)
		end

	----#129350
     ---- Haul Revenue credit
     if @haultotal <> 0 and @SurchargeKeyID is null
         begin
         -- get Haul Revenue GL Accounts (Equip or Outside)
         if @haultype = 'E' select @haulrevglacct = isnull(@lchaulrevequipglacct,isnull(@lshaulrevequipglacct,@lmhaulrevequipglacct))
         if @haultype = 'H' select @haulrevglacct = isnull(@lchaulrevoutglacct,isnull(@lshaulrevoutglacct,@lmhaulrevoutglacct))

         ---- validate Haul Revenue Account
         exec @rcode = dbo.bspGLACfPostable @msglco, @haulrevglacct, 'I', @errmsg output
         if @rcode <> 0
             begin
             select @errortext = @errorstart + ' - Haul Revenue Account ' + isnull(@errmsg,'')
        	 exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
   			 goto bspexit
             end
         ---- Haul Revenue credit
         update bMSGL set Amount = Amount - @haultotal
         where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @msglco and GLAcct = @haulrevglacct
             and BatchSeq = @seq and HaulLine = 0 and OldNew = @oldnew
         if @@rowcount = 0
             insert bMSGL(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, HaulLine, OldNew, MSTrans, Ticket, SaleDate,
                 FromLoc, MatlGroup, Material, SaleType, JCCo, Job, INCo, ToLoc, Amount)
             values(@msco, @mth, @batchid, @msglco, @haulrevglacct, @seq, 0, @oldnew, @mstrans, @ticket, @saledate,
                 @fromloc, @matlgroup, @material, @saletype, @jcco, @job, @inco, @toloc, -@haultotal)
         end

     ---- Surcharge Revenue credit handled at parent ticket if burdened unit cost
     ---- and an inventory sale. #139945
     if @SurchargeTotal <> 0 and @SurchargeKeyID is null and @burdencost = 'Y' and @saletype = 'I'
         begin
         ---- get Surcharge Revenue GL Accounts (Equip or Outside)
		if @haultype in ('E','N')
			begin
			if @saletype = 'C' set @haulrevglacct = @lmcustsurrevequipglacct
			if @saletype = 'J' set @haulrevglacct = @lmjobsurrevequipglacct
			if @saletype = 'I' set @haulrevglacct = @lminvsurrevequipglacct
			end
		if @haultype = 'H'
			begin
			if @saletype = 'C' set @haulrevglacct = @lmcustsurrevoutglacct
			if @saletype = 'J' set @haulrevglacct = @lmjobsurrevoutglacct
			if @saletype = 'I' set @haulrevglacct = @lminvsurrevoutglacct
			end
			
         ---- validate Surcharge Revenue Account
         exec @rcode = dbo.bspGLACfPostable @msglco, @haulrevglacct, 'I', @errmsg output
         if @rcode <> 0
             begin
             select @errortext = @errorstart + ' - Surcharge Revenue Account ' + isnull(@errmsg,'')
        	 exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
   			 goto bspexit
             end
             
         ---- Surcharge Revenue credit
         update bMSGL set Amount = Amount - @SurchargeTotal - @SurchargeTax
         where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @msglco and GLAcct = @haulrevglacct
         and BatchSeq = @seq and HaulLine = 0 and OldNew = @oldnew
         if @@rowcount = 0
			begin
			insert bMSGL(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, HaulLine, OldNew, MSTrans, Ticket, SaleDate,
				FromLoc, MatlGroup, Material, SaleType, JCCo, Job, INCo, ToLoc, Amount)
			values(@msco, @mth, @batchid, @msglco, @haulrevglacct, @seq, 0, @oldnew, @mstrans, @ticket, @saledate,
				@fromloc, @matlgroup, @material, @saletype, @jcco, @job, @inco, @toloc, -(@SurchargeTotal - @SurchargeTax))
			end
         end 
         
	---- Surcharge Revenue Credit #129350
     if @matltotal <> 0 and @SurchargeKeyID is not null
         begin
         ---- get Surcharge Revenue GL Accounts (Equip or Outside)
		if @haultype in ('E','N')
			begin
			if @saletype = 'C' set @haulrevglacct = @lmcustsurrevequipglacct
			if @saletype = 'J' set @haulrevglacct = @lmjobsurrevequipglacct
			if @saletype = 'I' set @haulrevglacct = @lminvsurrevequipglacct
			end
		if @haultype = 'H'
			begin
			if @saletype = 'C' set @haulrevglacct = @lmcustsurrevoutglacct
			if @saletype = 'J' set @haulrevglacct = @lmjobsurrevoutglacct
			if @saletype = 'I' set @haulrevglacct = @lminvsurrevoutglacct
			end

        ---- validate Surcharge Revenue Account
		exec @rcode = dbo.bspGLACfPostable @msglco, @haulrevglacct, 'I', @errmsg output
		if @rcode <> 0
			begin
			select @errortext = @errorstart + ' - Surcharge Revenue Account ' + isnull(@errmsg,'')
			exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
			goto bspexit
			end

		---- surcharge revenue credit will only apply if the surcharge
		---- has not been burdened at the parent ticket level. If burdened unit cost
		---- then the surcharge has been accounted for with the parent.
		if @saletype = 'J' or (@saletype = 'I' and @burdencost = 'N')
			begin
			---- Surcharge Revenue credit
			update bMSGL set Amount = Amount - (@matltotal+@haultotal)
			where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @msglco and GLAcct = @haulrevglacct
			and BatchSeq = @seq and HaulLine = 0 and OldNew = @oldnew
			if @@rowcount = 0
				begin
				insert bMSGL(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, HaulLine, OldNew, MSTrans, Ticket, SaleDate,
				FromLoc, MatlGroup, Material, SaleType, JCCo, Job, INCo, ToLoc, Amount)
				values(@msco, @mth, @batchid, @msglco, @haulrevglacct, @seq, 0, @oldnew, @mstrans, @ticket, @saledate,
				@fromloc, @matlgroup, @material, @saletype, @jcco, @job, @inco, @toloc, -(@matltotal+@haultotal))
				end
			end
		end
	---- #129350


	-- Tax Accrual credit
	if @taxtotal <> 0
		begin
		---- #139945 surcharge tax may be handled at parent if burdened cost
		if @saletype = 'J' or ((@saletype = 'I' and @SurchargeKeyID is null) or (@saletype = 'I' and @SurchargeKeyID is not null and @burdencost = 'N'))
			begin
			-- posted in MS GL Co# if 'sales' or 'vat' tax, posted in 'sell to' GL Co# if 'use' tax #128290
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
					values(@msco, @mth, @batchid, @glco, @dbtglacct, @seq, 0, @oldnew, @mstrans, @ticket, @saledate,
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
				values(@msco, @mth, @batchid, @glco, @HQTXcrdGLAcct, @seq, 0, @oldnew, @mstrans, @ticket, @saledate,
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
					values(@msco, @mth, @batchid, @glco, @HQTXcrdGLAcctPST, @seq, 0, @oldnew, @mstrans, @ticket, @saledate,
						@fromloc, @matlgroup, @material, @saletype, @jcco, @job, @inco, @toloc, -@TaxAmountPST)
					end
				end
			end
		end



     -- add Intercompany entries if needed
     if @toglco <> @msglco
         begin
         -- get interco GL Accounts
         select @arglacct = ARGLAcct, @apglacct = APGLAcct
         from bGLIA with (nolock) where ARGLCo = @msglco and APGLCo = @toglco
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
         select @gltotal = @matltotal + @haultotal
		 ---- #128290
		 if @taxtype = 1 select @gltotal = @gltotal + @taxtotal  -- include 'sales' tax, but not 'use' tax
         if @taxtype = 3 select @gltotal = @gltotal + @TaxAmountPST  -- include 'vat' pst tax
         update bMSGL set Amount = Amount + @gltotal
         where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @msglco and GLAcct = @arglacct
             and BatchSeq = @seq and HaulLine = 0 and OldNew = @oldnew
         if @@rowcount = 0
    		 insert bMSGL(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, HaulLine, OldNew, MSTrans, Ticket, SaleDate,
                 FromLoc, MatlGroup, Material, SaleType, JCCo, Job, INCo, ToLoc, Amount)
             values(@msco, @mth, @batchid, @msglco, @arglacct, @seq, 0, @oldnew, @mstrans, @ticket, @saledate,
                 @fromloc, @matlgroup, @material, @saletype, @jcco, @job, @inco, @toloc, @gltotal)

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
             and BatchSeq = @seq and HaulLine = 0 and OldNew = @oldnew
         if @@rowcount = 0
             insert bMSGL(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, HaulLine, OldNew, MSTrans, Ticket, SaleDate,
                 FromLoc, MatlGroup, Material, SaleType, JCCo, Job, INCo, ToLoc, Amount)
             values(@msco, @mth, @batchid, @toglco, @apglacct, @seq, 0, @oldnew, @mstrans, @ticket, @saledate,
                 @fromloc, @matlgroup, @material, @saletype, @jcco, @job, @inco, @toloc, -@gltotal)
         end
     end -- finished with distributions to MS/IN GL Co#


-- process Haul Expense and Equipment Revenue for all Sale Types
if @revtotal <> 0
	begin
	exec @rcode = dbo.bspMSTBValRev @msco, @mth, @batchid, @seq, @oldnew, @fromloc, @saletype, @matlgroup,
		@matlcategory, @material, @toco, @msglco, @revtotal, @mstrans, @ticket, @saledate, @custgroup,
		@customer, @custjob, @jcco, @job, @inco, @toloc, @emco, @equipment, @emgroup, @revcode, @phasegroup,
		@haulphase, @hauljcct, @prco, @employee, @revbasis, @revrate, @hrs, @errmsg output

	if @rcode = 1 goto bspexit
	end


bspexit:
	if @rcode <> 0 select @errmsg = isnull(@errmsg,'')
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspMSTBValDist] TO [public]
GO
