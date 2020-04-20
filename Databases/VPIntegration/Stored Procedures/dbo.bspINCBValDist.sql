SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     procedure [dbo].[bspINCBValDist]
   /***********************************************************
    * CREATED: GG 04/08/02
    * MODIFIED: GG 06/07/02 - #17597 - fix updates to bINCJ, pull tax description
    *           DANF 09/05/02 - 17738 - Added Phase Group to bspJobTypeVal & bspJCCAGlacctDflt
    *			DC 11/21/03 - 21084 - Send the material description to the JCCD description field on MO's
    *			GG 02/02/04 - #20538 - split GL units flag
    *          TRL 08/03/05 - #28448 - Added TaxBasis column to INCJ
    *			GP 05/06/09 - Modified @description, @HQMatldesc bItemDesc
    *			GP 12/24/09 - Issue 137182 added substring to @description on bINCJ insert
    *
    * USAGE:
    * Called by bspINCBVal to create JC and GL distributions for a
    * batch entry.
    *
    * Validation errors passed back to bspINCBVal to be added to bHQBE 
    * Job Cost distributions added to bINCJ
    * General Ledger distributions added to bINCG
    *
    * 
    * INPUT PARAMETERS
    *  @co        	IN Company
    *  @mth       	Month of batch
    *  @batchid   	Batch ID#
    *	@seq		Batch Sequence 
    *	@oldnew		0 = Old, 1 = New
    *	@inglco		IN GL Co#
    *
    * OUTPUT PARAMETERS
    *   @errmsg     error message 
    *
    * RETURN VALUE
    *   @rcode		0 = success, 1 = error
    *   1   fail
    *****************************************************/
   
   	(@co bCompany = null, @mth bMonth = null, @batchid bBatchID = null, 
   	 @seq int = null, @oldnew tinyint = null, @inglco bCompany = null,
   	 @errmsg varchar(255) output)
    
   as
    
   set nocount on
   
   declare @rcode int, @intrans bTrans, @mo bMO, @moitem bItem, @loc bLoc, @matlgroup bGroup, @material bMatl,
   	@confirmdate bDate, @description bItemDesc, @confirmunits bUnits, @remainunits bUnits, @unitprice bUnitCost,
   	@ecm bECM, @confirmtotal bDollar, @stkum bUM, @stkunits bUnits, @stkunitcost bUnitCost, @stkecm bECM, 
   	@stktotalcost bDollar, @status tinyint, @inusemth bMonth, @inusebatchid bBatchID, @jcco bCompany,
   	@job bJob, @phasegroup bGroup, @phase bPhase, @jcctype bJCCType, @glco bCompany, @glacct bGLAcct,
   	@taxgroup bGroup, @taxcode bTaxCode, @matlcategory varchar(10), @glsaleunits bYN, @active bYN,
   	@conv bUnitCost, @umconv bUnitCost, @msg varchar(255), @lminvglacct bGLAcct, @lmcostglacct bGLAcct,
   	@lmsalesglacct bGLAcct, @lmqtyglacct bGLAcct, @loinvglacct bGLAcct, @locostglacct bGLAcct, 
   	@lssalesglacct bGLAcct, @lsqtyglacct bGLAcct, @lcsalesglacct bGLAcct, @lcqtyglacct bGLAcct,
   	@invglacct bGLAcct, @costglacct bGLAcct, @salesglacct bGLAcct, @qtyglacct bGLAcct, @jcum bUM,
   	@taxphase bPhase, @taxjcctype bJCCType, @taxrate bRate, @taxamt bDollar, @taxglacct bGLAcct,
   	@taxexpglacct bGLAcct, @jcumconv bUnitCost, @um bUM, @jcconfirmunits bUnits, @arglacct bGLAcct,
   	@apglacct bGLAcct, @jcremainunits bUnits, @jctotalcmtdcost bDollar, @jcremaincmtdcost bDollar,
   	@factor smallint, @jctotalcmtdtax bDollar, @jcremaincmtdtax bDollar, @jcconfirmtotal bDollar, @taxdesc bDesc,
   	@HQMatldesc bItemDesc,  --DC 21084
   	@INMatldesc bDesc  --DC 21084
   
   select @rcode = 0
   
   if @oldnew is null or @oldnew not in (0,1)
   	begin
   	select @errmsg = 'Invalid ''old/new'' value!', @rcode = 1
   	goto bspexit
   	end
   
   -- get old info from batch entry, reverse sign on units and totals
   if @oldnew = 0
   	begin
   	select @intrans = INTrans, @mo = OldMO, @moitem = OldMOItem, @loc = OldLoc, @matlgroup = OldMatlGroup,
   		@material = OldMaterial, @um = OldUM, @confirmdate = OldConfirmDate, @description = OldDesc,
   		@confirmunits = -(OldConfirmUnits), @remainunits = -(OldRemainUnits), @unitprice = OldUnitPrice,
   		@ecm = OldECM, @confirmtotal = -(OldConfirmTotal), @stkum = OldStkUM, @stkunits = -(OldStkUnits),
   		@stkunitcost = OldStkUnitCost, @stkecm = OldStkECM, @stktotalcost = -(OldStkTotalCost)
   	from bINCB where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
   	if @@rowcount = 0
   		begin
   		select @errmsg = 'Missing Batch Sequence!', @rcode = 1
   		goto bspexit
   		end
   	end
   -- get new info from batch entry
   if @oldnew = 1
   	begin
   	select @intrans = INTrans, @mo = MO, @moitem = MOItem, @loc = Loc, @matlgroup = MatlGroup,
   		@material = Material, @um = UM, @confirmdate = ConfirmDate, @description = Description,
   		@confirmunits = ConfirmUnits, @remainunits = RemainUnits, @unitprice = UnitPrice,
   		@ecm = ECM, @confirmtotal = ConfirmTotal, @stkum = StkUM, @stkunits = StkUnits,
   		@stkunitcost = StkUnitCost, @stkecm = StkECM, @stktotalcost = StkTotalCost
   	from bINCB where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
   	if @@rowcount = 0
   		begin
   		select @errmsg = 'Missing Batch Sequence!', @rcode = 1
   		goto bspexit
   		end
   	end
   
   -- validate MO#
   select @status = Status, @inusemth = InUseMth, @inusebatchid = InUseBatchId
   from bINMO where INCo = @co and MO = @mo
   if @@rowcount = 0
   	begin
       select @errmsg = 'Invalid Material Order#: ' + @mo, @rcode = 1
   	goto bspexit
       end
   if @status <> 0
   	begin
       select @errmsg = 'Material Order#: ' + @mo + ' must be ''open''.', @rcode = 1
   	goto bspexit
       end
   if @inusemth is null or @inusebatchid is null
   	begin
   	select @errmsg = 'Material Order#: ' + @mo + ' has not been flagged as ''In Use'' by this batch.', @rcode = 1
   	goto bspexit
       end
   if @inusemth <> @mth or @inusebatchid <> @batchid
       begin
       select @errmsg = 'Material Order#: ' + @mo + ' is ''In Use'' by another batch.', @rcode = 1
   	goto bspexit
   	end
   -- validate MO Item info
   select @jcco = JCCo, @job = Job, @phasegroup = PhaseGroup, @phase = Phase, @jcctype = JCCType,
   	@glco = GLCo, @glacct = GLAcct, @taxgroup = TaxGroup, @taxcode = TaxCode, @INMatldesc = Description
   from bINMI where INCo = @co and MO = @mo and MOItem = @moitem
   if @@rowcount = 0
   	begin
   	select @errmsg = 'Missing Item#: ' + convert(varchar,@moitem) + ' for Material Order#: ' + @mo, @rcode = 1
   	goto bspexit
   	end
   
   -- validate Material in HQ  
   select @matlcategory = Category, @HQMatldesc = Description  --DC 21084
   from bHQMT where MatlGroup = @matlgroup and Material = @material
   if @@rowcount = 0
   	begin
   	select @errmsg = 'Material: ' + @material + ' not setup in HQ.', @rcode = 1
   	goto bspexit
   	end
   -- validate Material in IN
   select @glsaleunits = GLSaleUnits, @active = Active
   from bINMT where INCo = @co and Loc = @loc and MatlGroup = @matlgroup and Material = @material
   if @@rowcount = 0
   	begin
   	select @errmsg =  'Location: ' + @loc + ' Material: ' + @material + ' not setup in Inventory!', @rcode = 1   
   	goto bspexit
   	end
   if @active = 'N'
   	begin
   	select @errmsg = 'Location: ' + @loc + ' Material: ' + @material + ' is inactive!', @rcode = 1
   	goto bspexit
   	end
   -- validate Material U/M
   exec @rcode = bspINMOMatlUMVal @co, @loc, @material, @matlgroup, @um, @conv = @umconv output, @msg = @errmsg output
   if @rcode <> 0 goto bspexit
   
   -- get Inventory GL Accounts from Location Master
   select @lminvglacct = InvGLAcct, @lmcostglacct = CostGLAcct, @lmsalesglacct = JobSalesGLAcct,
   	@lmqtyglacct = JobQtyGLAcct, @active = Active
   from bINLM where INCo = @co and Loc = @loc
   if @@rowcount = 0
   	begin
   	select @errmsg = 'Missing Location: ' + @loc, @rcode = 1   
   	goto bspexit
   	end
   if @active = 'N'
   	begin
   	select @errmsg = 'Location: ' + @loc + ' is inactive!', @rcode = 1
   	goto bspexit
   	end
   -- check for GL Account overrides based on Location and Category
   select @loinvglacct = InvGLAcct, @locostglacct = CostGLAcct
   from bINLO
   where INCo = @co and Loc = @loc and MatlGroup = @matlgroup and Category = @matlcategory
   -- check for GL Account overrides based on Location and JC Co#
   select @lssalesglacct = JobSalesGLAcct, @lsqtyglacct = JobQtyGLAcct
   from bINLS
   where INCo = @co and Loc = @loc and Co = @jcco
   -- check for GL Account overrides based on Location, JC Co#, and Category
   select @lcsalesglacct = JobSalesGLAcct, @lcqtyglacct = JobQtyGLAcct
   from bINLC
   where INCo = @co and Loc = @loc and Co = @jcco and MatlGroup = @matlgroup and Category = @matlcategory
   
   -- assign Inventory and Cost of Sales GL Accounts
   select @invglacct = isnull(@loinvglacct,@lminvglacct), @costglacct = isnull(@locostglacct,@lmcostglacct),
   	@salesglacct = coalesce(@lcsalesglacct,@lssalesglacct,@lmsalesglacct),
   	@qtyglacct = coalesce(@lcqtyglacct,@lsqtyglacct,@lmqtyglacct)
   
   -- validate Job, Phase, and Cost Type
   exec @rcode = bspJobTypeVal @jcco, @phasegroup, @job, @phase, @jcctype, @jcum output, @errmsg output
   if @rcode <> 0 goto bspexit
   -- validate Month in JC GL Co# - subledgers must be open
   if @glco <> @inglco 
   	begin
   	exec @rcode = bspHQBatchMonthVal @glco, @mth, 'IN', @errmsg output
       if @rcode <> 0 goto bspexit
   	end
   
   -- validate Tax Code & calculate Tax Amt
   select @taxphase = @phase, @taxjcctype = @jcctype, @taxamt = 0, @taxrate = 0
   if @taxcode is not null
   	begin
   	exec @rcode = bspHQTaxRateGet @taxgroup, @taxcode, @confirmdate, @taxrate output,
   		@taxphase output, @taxjcctype output, @taxdesc output
   	if @rcode <> 0
   		begin
   		select @errmsg = @taxdesc
   		goto bspexit
   		end
   	-- get Tax Accrual GL Account
   	select @taxglacct = GLAcct from bHQTX where TaxGroup = @taxgroup and TaxCode = @taxcode
   	if @@rowcount = 0
   		begin
   		select @errmsg = 'Invalid Tax Code: ' + @taxcode, @rcode = 1
   		end
   	select @taxamt = @confirmtotal * @taxrate, @taxexpglacct = @glacct	-- default to Job Expense GL Account
   	if @taxphase is null select @taxphase = @phase
   	if @taxjcctype is null select @taxjcctype = @jcctype
   	if @taxphase <> @phase or @taxjcctype <> @jcctype
   		begin
   		-- validate Tax Phase and Cost Type
   		exec @rcode = bspJobTypeVal @jcco, @phasegroup, @job, @taxphase, @taxjcctype, @errmsg = @errmsg output
   		if @rcode <> 0
   			begin
   			select @errmsg = @errmsg + ' - Tax Phase and Cost Type.'
   			goto bspexit
   			end
   		-- get JC Expense GL Account for Tax
   		exec @rcode = bspJCCAGlacctDflt @jcco, @job, @phasegroup, @taxphase, @taxjcctype, 'N', @taxexpglacct output, @errmsg output
   		if @rcode <> 0
   			begin
   			select @errmsg = @errmsg + ' - Tax Expense GL Account.'
   			goto bspexit
   			end
   		end
   	end
   
   -- determine conversion factor from posted UM to JC UM
   select @jcumconv = 0
   if isnull(@jcum,'') = @um select @jcumconv = 1
   if isnull(@jcum,'') <> @um
   	begin
       exec @rcode = bspHQStdUMGet @matlgroup, @material, @jcum, @jcumconv output, @msg = @errmsg output
       if @rcode <> 0
   		begin
           select @errmsg = 'JC UM: ' + @jcum + ' for Material: ' + @material + ' - ' + @errmsg, @rcode = 1
   		goto bspexit
           end
   	if @jcumconv <> 0 select @jcumconv = @umconv / @jcumconv
   	end
   -- convert confirmed and remaining units into JC UM
   select @jcconfirmunits = @confirmunits * @jcumconv, @jcremainunits = @remainunits * @jcumconv
   
   -- calculate change to JC Total and Remaining Committed Cost
   select @factor = case @ecm when 'M' then 1000 when 'C' then 100 else 1 end
   select @jctotalcmtdcost = ((@confirmunits + @remainunits) * @unitprice) / @factor
   select @jctotalcmtdtax = @jctotalcmtdcost * @taxrate
   select @jcremaincmtdcost = (@remainunits * @unitprice) / @factor
   select @jcremaincmtdtax = @jcremaincmtdcost * @taxrate
   
   -- add JC Distributions - bINCJ
   select @jcconfirmtotal = @confirmtotal
   if @taxphase = @phase and @taxjcctype = @jcctype
   	begin
   	select @jcconfirmtotal = @jcconfirmtotal + @taxamt, @jctotalcmtdcost = @jctotalcmtdcost + @jctotalcmtdtax,
   		@jcremaincmtdcost = @jcremaincmtdcost + @jcremaincmtdtax	-- include tax unless redirected	
   	end
   
   --DC 21084 - Send the material description to the JCCD description field on MO's
   if @description is null set @description = isnull(@HQMatldesc,@INMatldesc)
   
   
   -- add entry to JC Distribution Audit for actual/committed units and costs - bINCJ
   if @confirmunits <> 0 or @remainunits <> 0 or @jcconfirmtotal <> 0
   	begin
   	insert bINCJ (INCo, Mth, BatchId, JCCo, Job, PhaseGroup, Phase, JCCType, BatchSeq,
   		OldNew, MO, MOItem, Loc, MatlGroup, Material, UM, ConfirmDate, Description,
   		ConfirmUnits, RemainUnits, UnitPrice, ECM, ConfirmTotal, TaxGroup, TaxCode, TaxAmt, TaxBasis,/*Issue 28448 TRL 08/03/05*/
   		StkUM, StkUnitCost,	StkECM, JCUM, JCConfirmUnits, JCRemUnits, JCTotalCmtdCost, JCRemainCmtdCost	)
   	values (@co, @mth, @batchid, @jcco, @job, @phasegroup, @phase, @jcctype, @seq,
   		@oldnew, @mo, @moitem, @loc, @matlgroup, @material, @um, @confirmdate, substring(@description,1,30),
   		@confirmunits, @remainunits, @unitprice, @ecm, @jcconfirmtotal,  @taxgroup,@taxcode, 
   		--Issue 28448 TRL 08/03/05, TaxAmt and TaxBasis
   		case when (@taxphase <> @phase or @taxjcctype <> @jcctype) and (@taxamt <> 0 or @jcremaincmtdtax <> 0) then 0 else  @taxamt end ,
   		case  when @taxcode is null then 0 
   		         when (@taxphase <> @phase or @taxjcctype <> @jcctype) and (@taxamt <> 0 or @jcremaincmtdtax <> 0) then 0
   		         when  @taxphase= @phase or @taxjcctype = @jcctype then @jcconfirmtotal-@taxamt
   			else  @jcconfirmtotal -@taxamt  end,
   		@stkum, @stkunitcost, @stkecm, @jcum, @jcconfirmunits, @jcremainunits, @jctotalcmtdcost, @jcremaincmtdcost )
   	end
   -- add entry to JC Distribution Audit for Tax (if redirected)
   if (@taxphase <> @phase or @taxjcctype <> @jcctype) and (@taxamt <> 0 or @jcremaincmtdtax <> 0)
      	begin
   	insert bINCJ (INCo, Mth, BatchId, JCCo, Job, PhaseGroup, Phase, JCCType, BatchSeq,
           OldNew, MO, MOItem, Loc, MatlGroup, Material, UM, ConfirmDate, Description,
   		ConfirmUnits, RemainUnits, UnitPrice, ECM, ConfirmTotal, TaxGroup, TaxCode, TaxAmt, TaxBasis,/*Issue 28448 TRL 08/03/05*/
   		StkUM, StkUnitCost, StkECM, JCUM, JCConfirmUnits, JCRemUnits, JCTotalCmtdCost, JCRemainCmtdCost)
   	values (@co, @mth, @batchid, @jcco, @job, @phasegroup,@taxphase, @taxjcctype, @seq,
           @oldnew, @mo, @moitem, @loc, @matlgroup, @material, @um, @confirmdate, @taxdesc,
   		0, 0, 0, 'E', @taxamt, @taxgroup, @taxcode, @taxamt, @jcconfirmtotal,/*Issue 28448 TRL 08/03/05*/ 
   		@stkum, 0, 'E', @jcum, 0, 0, @jctotalcmtdtax, @jcremaincmtdtax)
     	end
   
   -- add GL Distributions - bINCG
   -- validate Inventory GL Account - must be subledger type 'I'
   exec @rcode = bspGLACfPostable @inglco, @invglacct, 'I', @errmsg output
   if @rcode <> 0
   	begin
   	select @errmsg = @errmsg + ' - Inventory GL Account!'
   	goto bspexit
       end
   -- credit Inventory in IN GL Co#
   update bINCG set Amt = Amt - @stktotalcost
   where INCo = @co and Mth = @mth and BatchId = @batchid and GLCo = @inglco and GLAcct = @invglacct
   	and BatchSeq = @seq and OldNew = @oldnew
   if @@rowcount = 0
   	insert bINCG (INCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, OldNew, INTrans, MO, MOItem,
   		Loc, MatlGroup, Material, Description, ConfirmDate, Amt)
   	values (@co, @mth, @batchid, @inglco, @invglacct, @seq, @oldnew, @intrans, @mo, @moitem,
   		@loc, @matlgroup, @material, @description, @confirmdate, -@stktotalcost)
   
   -- validate Cost of Sales GL Account - must be subledger type 'I'
   exec @rcode = bspGLACfPostable @inglco, @costglacct, 'I', @errmsg output
   if @rcode <> 0
   	begin
   	select @errmsg = @errmsg + ' - Cost of Sales GL Account!'
   	goto bspexit
       end
   -- debit Cost of Sales in IN GL Co# - (offsets Inventory)
   update bINCG set Amt = Amt + @stktotalcost
   where INCo = @co and Mth = @mth and BatchId = @batchid and GLCo = @inglco and GLAcct = @costglacct
     	and BatchSeq = @seq and OldNew = @oldnew
   if @@rowcount = 0
   	insert bINCG (INCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, OldNew, INTrans, MO, MOItem,
   		Loc, MatlGroup, Material, Description, ConfirmDate, Amt)
   	values (@co, @mth, @batchid, @inglco, @costglacct, @seq, @oldnew, @intrans, @mo, @moitem,
   		@loc, @matlgroup, @material, @description, @confirmdate, @stktotalcost)
   
   -- validate Sales to Jobs GL Account - must be subledger type 'I'
   exec @rcode = bspGLACfPostable @inglco, @salesglacct, 'I', @errmsg output
   if @rcode <> 0
   	begin
   	select @errmsg = @errmsg + ' - Sales to Jobs GL Account!' 
   	goto bspexit
   	end
   -- credit Sales to Jobs in IN GL Co#
   update bINCG set Amt = Amt - @confirmtotal
   where INCo = @co and Mth = @mth and BatchId = @batchid and GLCo = @inglco and GLAcct = @salesglacct
     	and BatchSeq = @seq and OldNew = @oldnew
   if @@rowcount = 0
   	insert bINCG (INCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, OldNew, INTrans, MO, MOItem,
   
   		Loc, MatlGroup, Material, Description, ConfirmDate, Amt)
   	values (@co, @mth, @batchid, @inglco, @salesglacct, @seq, @oldnew, @intrans, @mo, @moitem,
   		@loc, @matlgroup, @material, @description, @confirmdate, -@confirmtotal)
   		
   -- Qty Sold --
   if @glsaleunits ='Y' and @qtyglacct is not null
   	begin
   	-- validate Sales Qty Account
   	exec @rcode = bspGLACQtyVal @inglco, @qtyglacct, @errmsg output
   	if @rcode <> 0
     		begin
     		select @errmsg = @errmsg + ' - Sales Qty Account!' 
         	goto bspexit
     		end
   	-- Sales Qty (credit unit sold)
    	update bINCG set Amt = Amt - @stkunits
   	where INCo = @co and Mth = @mth and BatchId = @batchid and GLCo = @inglco and GLAcct = @qtyglacct
     		and BatchSeq = @seq and OldNew = @oldnew
   	if @@rowcount = 0
   		insert bINCG (INCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, OldNew, INTrans, MO, MOItem,
   			Loc, MatlGroup, Material, Description, ConfirmDate, Amt)
   		values (@co, @mth, @batchid, @inglco, @qtyglacct, @seq, @oldnew, @intrans, @mo, @moitem,
   			@loc, @matlgroup, @material, @description, @confirmdate, -@stkunits)
   	end
   
   -- validate Job Expense GL Account - must be subledger type 'J'
   exec @rcode = bspGLACfPostable @glco, @glacct, 'J', @errmsg output
   if @rcode <> 0
   	begin
   	select @errmsg = @errmsg + ' - Job Expense GL Account!' 
   	goto bspexit
       end
   -- debit Job Expense GL Account in JC GL Co# - (offsets Sales)
   update bINCG set Amt = Amt + @confirmtotal
   where INCo = @co and Mth = @mth and BatchId = @batchid and GLCo = @glco and GLAcct = @glacct
   	and BatchSeq = @seq and OldNew = @oldnew
   if @@rowcount = 0
   	insert bINCG (INCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, OldNew, INTrans, MO, MOItem,
   		Loc, MatlGroup, Material, Description, ConfirmDate, Amt)
   	values (@co, @mth, @batchid, @glco, @glacct, @seq, @oldnew, @intrans, @mo, @moitem,
   		@loc, @matlgroup, @material, @description, @confirmdate, @confirmtotal)
   
   -- add Intercompany entries if needed
   if @glco <> @inglco
   	begin
   	-- get interco GL Accounts
   	select @arglacct = ARGLAcct, @apglacct = APGLAcct
   	from bGLIA where ARGLCo = @inglco and APGLCo = @glco
   	if @@rowcount = 0
   		begin
   		select @errmsg = 'Intercompany Accounts not setup in GL for IN and JC Companies!', @rcode = 1
   		goto bspexit
   		end
   	-- validate Intercompany AR GL Account
   	exec @rcode = bspGLACfPostable @inglco, @arglacct, 'R', @errmsg output
   	if @rcode <> 0
   		begin
   		select @errmsg = @errmsg + ' - Intercompany AR Account!' 
   		goto bspexit
   		end
   	-- Intercompany AR debit (posted in IN GL Co#)
   	update bINCG set Amt = Amt + @confirmtotal
   	where INCo = @co and Mth = @mth and BatchId = @batchid and GLCo = @inglco and GLAcct = @arglacct
   	  	and BatchSeq = @seq and OldNew = @oldnew
   	if @@rowcount = 0
   		insert bINCG (INCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, OldNew, INTrans, MO, MOItem,
   			Loc, MatlGroup, Material, Description, ConfirmDate, Amt)
   		values (@co, @mth, @batchid, @inglco, @arglacct, @seq, @oldnew, @intrans, @mo, @moitem,
   			@loc, @matlgroup, @material, @description, @confirmdate, @confirmtotal)
   	-- validate Intercompany AP GL Account
   	exec @rcode = bspGLACfPostable @glco, @apglacct, 'P', @errmsg output
   	if @rcode <> 0
   	  	begin
   	  	select @errmsg = @errmsg + ' - Intercompany AP Account!' 
   	    goto bspexit
   	  	end
   	-- Intercompany AP credit (posted in JC GL Co#)
   	update bINCG set Amt = Amt - @confirmtotal
   	where INCo = @co and Mth = @mth and BatchId = @batchid and GLCo = @glco and GLAcct = @apglacct
   	  	and BatchSeq = @seq and OldNew = @oldnew
   	if @@rowcount = 0
   		insert bINCG (INCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, OldNew, INTrans, MO, MOItem,
   			Loc, MatlGroup, Material, Description, ConfirmDate, Amt)
   		values (@co, @mth, @batchid, @glco, @apglacct, @seq, @oldnew, @intrans, @mo, @moitem,
   			@loc, @matlgroup, @material, @description, @confirmdate, -@confirmtotal)
   	end
   
   -- Tax Expense and Accrual - both posted in JC GL Co#
   if @taxamt <> 0
   	begin
   	-- validate Job Expense Account for use tax in JC GL Co#
   	exec @rcode = bspGLACfPostable @glco, @taxexpglacct, 'J', @errmsg output
   	if @rcode <> 0
   		begin
   		select @errmsg = @errmsg + ' - Tax Expense GL Account!' 
   		goto bspexit
   		end
   	-- Tax Expense debit
   	update bINCG set Amt = Amt + @taxamt
   	where INCo = @co and Mth = @mth and BatchId = @batchid and GLCo = @glco and GLAcct = @taxexpglacct
   	  	and BatchSeq = @seq and OldNew = @oldnew
   	if @@rowcount = 0
   		insert bINCG (INCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, OldNew, INTrans, MO, MOItem,
   			Loc, MatlGroup, Material, Description, ConfirmDate, Amt)
   		values (@co, @mth, @batchid, @glco, @taxexpglacct, @seq, @oldnew, @intrans, @mo, @moitem,
   			@loc, @matlgroup, @material, @description, @confirmdate, @taxamt)
   	-- validate Tax Accrual Account in JC GL Co#
   	exec @rcode = bspGLACfPostable @glco, @taxglacct, 'N', @errmsg output
   	if @rcode <> 0
   		begin
   		select @errmsg = @errmsg + ' - Tax Accrual GL Account!'
   		goto bspexit
   		end
   	-- Tax Accrual credit
   	update bINCG set Amt = Amt - @taxamt
   	where INCo = @co and Mth = @mth and BatchId = @batchid and GLCo = @glco and GLAcct = @taxglacct
   	  	and BatchSeq = @seq and OldNew = @oldnew
   	if @@rowcount = 0
   		insert bINCG (INCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, OldNew, INTrans, MO, MOItem,
   			Loc, MatlGroup, Material, Description, ConfirmDate, Amt)
   		values (@co, @mth, @batchid, @glco, @taxglacct, @seq, @oldnew, @intrans, @mo, @moitem,
   			@loc, @matlgroup, @material, @description, @confirmdate, -@taxamt)
   	end
   
   
   
   bspexit:
  -- 	if @rcode <> 0 select @errmsg
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINCBValDist] TO [public]
GO
