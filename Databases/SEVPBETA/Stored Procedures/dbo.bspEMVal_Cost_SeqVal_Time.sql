SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   procedure [dbo].[bspEMVal_Cost_SeqVal_Time]
   /***********************************************************
   * CREATED BY: JM 7/9/02 - Ref Issue 17743 - Combination bspEMVal_Cost_AddedChanged and 
   *	bspEMVal_Cost_ChangedDeleted for each source, called from bspEMVal_Cost_Main
   *
   * MODIFIED By :  GG 09/20/02 - #18522 ANSI nulls
   *		EN 9/25/02 - issue 18685  add validation for costcode/costtype combo
   *		JM 10-02-02 -  Ref Issue 18024 - For EMTime Source, validate GLOffsetAcct SubType = null
   *		JM 10-09-02 -  Remove 'rtrim(ltrim(' from GLTransAcct validation against blank (per DF)
   *		EN 10/15/02 - issue 18964 - added validation for 0 labor rate and fixed six error messages to not show extraeneous info such as company name
   *		EN 10/15/02 - issue 18964 - modified verbage used when dbo.bspPREmplValForWOTimeCards validation fails to make more sense
   *		EN 10/18/02 - issue 19037 - error occurring because call to dbo.bspEMWOItemValForTimeCards is including params that were removed from bsp (see issue 18015)
   *		EN 10/25/02 - issue 19037 - error occurring when code tried to check OldHours against Units in EMCD ... removed
   *		JM 12-03-02 - Ref Issue 19127 - Removed validation of GLTransAcct and GLOffsetAcct; updated bEMBF when these accts are established by successful CostCode validation.
   *		GF 01/16/03 - Issue #20029 - need to update bEMBF set Units = Hours
   *		GF 05/19/03 - issue #21285 - ignore validation about EMBF rate does not equal PREH rate. 5.81
   *		GF 06/06/03 - issue #21450 - need to check for inactive GL trans acct. Added validation for GL Offset Acct
   *		TV 02/11/04 - 23061 added isnulls 
   * USAGE:
   *
   *	GLTransAcct must be subtype 'E'
   *	GLJrnl = AdjstGLJrnl
   *	GLLvl = AdjstGLLvl
   *	
   *	Visible bound inputs that use the same valproc here as in DDFI:
   *		PRCo - dbo.bspPRCompanyVal
   *		PREmployee - dbo.bspPREmplValForWOTimeCards
   *		WorkOrder - bspEMWOVal only for EMTransType 'WO'
   *		WOItem - dbo.bspEMWOItemValForTimeCardsonly for EMTransType 'WO'
   *		Equipment - bspEMEquipValNoComponent
   *		ComponentTypeCode - dbo.bspEMComponentTypeCodeVal
   *		Component - dbo.bspEMComponentVal
   *		CostCode - dbo.bspEMCostCodeValForWOTimeCards
   *	
   *	Hidden bound inputs without valprocs in DDFI that receive basic validation here:
   *		EMGroup - dbo.bspHQGroupVal
   *		EMCostType - dbo.bspEMCostTypeVal
   *		GLCo - dbo.bspGLCompanyVal
   *		Source = 'EMTime'
   *		EMTransType = 'WO' or 'Equip'
   *		UM = 'HRS'
   *		PerECM = 'E'
   *		GLOffsetAcct = bEMDM.LaborFixedRateAcct for EMCo where Department = bEMEM.Department for EMCo and Equipment
   *		GLTransAcct - dbo.bspEMGLTransAcctVal
   *		UnitPrice = PREH.EMFixedRate and cannot be null
   *		Hours must not be null
   *		Dollars must not be null
   *	
   *	Bound inputs that do not receive validation here:
   *		BatchTransType
   *		ActualDate
   *		EMTrans
   *
   *	Unbound columns in bEMBF that receive validation here:
   *		ReversalStatus - if null, converted to 0; must be 0, 1, 2, 3, 4
   *
   * INPUT PARAMETERS
   *	EMCo        EM Company
   *	Month       Month of batch
   *	BatchId     Batch ID to validate
   *	BatchSeq	Batch Seq to validate
   *
   * OUTPUT PARAMETERS
   *	@errmsg     if something went wrong
   *
   * RETURN VALUE
   *	0   Success
   *	1   Failure
   *****************************************************/
   @co bCompany,
   @mth bMonth,
   @batchid bBatchID,
   @batchseq int,
   @errmsg varchar(255) output
   
   as
   
   set nocount on
   
   /* General decs */
   declare @department bDept, @errorstart varchar(50), @errtext varchar(255), @gljrnl bJrnl, @gllvl tinyint, @glsubtype char(1), @rcode int
   
   /* bEMBF non-Olds decs */
   declare @actualdate bDate, @batchtranstype char(1), @component bEquip, @componenttypecode varchar(10), @costcode bCostCode, @dollars bDollar, 
   	@emcosttype bEMCType, @emgroup bGroup,@emtrans bTrans, @emtranstype varchar(10), @equipment bEquip, @glco bCompany, @gloffsetacct bGLAcct, 
   	@gltransacct bGLAcct, @hours bHrs, @perecm char(1), @prco bCompany,  @premployee bEmployee, @reversalstatus tinyint, @source varchar(10), @um bUM, 
   	@unitprice bUnitCost, @woitem bItem, @workorder bWO
   
   /* bEMBF Olds decs */
   declare @oldactualdate bDate, @oldbatchtranstype char(1), @oldcomponent bEquip, @oldcomponenttypecode varchar(10), @oldcostcode bCostCode, 
   	@oldemcosttype bEMCType, @olddollars bDollar, @oldemgroup bGroup,@oldemtrans bTrans, @oldemtranstype varchar(10), @oldequipment bEquip, 
   	@oldglco bCompany, @oldgloffsetacct bGLAcct, @oldgltransacct bGLAcct, @oldhours bHrs, @oldperecm bECM, @oldprco bCompany,  
   	@oldpremployee bEmployee, @oldreversalstatus tinyint, @oldsource varchar(10), @oldum bUM, @oldunitprice bUnitCost, @oldwoitem bItem, 
   	@oldworkorder bWO
   
   /* bEMCD decs */
   declare @emcdactualdate bDate, @emcdcomponent bEquip, @emcdcomponenttypecode varchar(10),  @emcdcostcode bCostCode, @emcddollars bDollar, 
   	@emcdemcosttype bEMCType, @emcdemgroup bGroup, @emcdemtrans bTrans, @emcdemtranstype varchar(10), @emcdequipment bEquip, 
   	@emcdglco bCompany, @emcdgloffsetacct bGLAcct, @emcdgltransacct bGLAcct, @emcdinusebatchid bBatchID, @emcdperecm bECM, 
   	@emcdprco bCompany, @emcdpremployee bEmployee, @emcdreversalstatus tinyint, @emcdsource varchar(10), @emcdum bUM, 
   
   	@emcdunitprice bUnitCost, @emcdunits bUnits, @emcdwoitem bItem, @emcdworkorder bWO
   
   select @rcode = 0
   
   /* Verify parameters passed in. */
   if @co is null
   	begin
   	select @errmsg = 'Missing Batch Company!', @rcode = 1
   	goto bspexit
   	end
   if @mth is null
   	begin
   	select @errmsg = 'Missing Batch Month!', @rcode = 1
   	goto bspexit
   	end
   if @batchid is null
   	begin
   	select @errmsg = 'Missing BatchID!', @rcode = 1
   	goto bspexit
   	end
   if @batchseq is null
   	begin
   	select @errmsg = 'Missing Batch Sequence!', @rcode = 1
   	goto bspexit
   	end
   
   /* Fetch row data into variables. */
   select @actualdate = ActualDate, @batchtranstype = BatchTransType, @component = Component, @componenttypecode = ComponentTypeCode, 
   	@costcode = CostCode, @dollars = Dollars, @emcosttype = EMCostType, @emgroup = EMGroup, @emtrans = EMTrans, 
   	@emtranstype = EMTransType, @equipment = Equipment, @glco = GLCo, @gloffsetacct = GLOffsetAcct, @gltransacct = GLTransAcct, 
   	@hours = Hours, @perecm = PerECM, @prco = PRCo, @premployee = PREmployee, @reversalstatus = ReversalStatus, @source = rtrim(Source), 
   	@um = UM, @unitprice = UnitPrice, @woitem = WOItem, @workorder = WorkOrder, @oldactualdate = OldActualDate, @oldbatchtranstype = OldBatchTransType, 
   	@oldcomponent = OldComponent, @oldcomponenttypecode = OldComponentTypeCode, @oldcostcode = OldCostCode, @olddollars = OldDollars, 
   	@oldemcosttype = OldEMCostType, @oldemgroup = OldEMGroup, @oldemtrans = OldEMTrans, @oldemtranstype = OldEMTransType, 
   	@oldequipment = OldEquipment, @oldglco = OldGLCo, @oldgloffsetacct = OldGLOffsetAcct, @oldgltransacct = OldGLTransAcct, 
   	@oldhours = OldHours, @oldperecm = OldPerECM, @oldprco = OldPRCo,  @oldpremployee = OldPREmployee, @oldreversalstatus = OldReversalStatus,
   	@oldsource = rtrim(OldSource), @oldum = OldUM, @oldunitprice = OldUnitPrice, @oldwoitem = OldWOItem, @oldworkorder = OldWorkOrder
   from bEMBF where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
   
   /* Setup @errorstart string. */
   select @errorstart = 'Seq ' + isnull(convert(varchar(9),@batchseq),'') + '-'
   
   ---------------All BatchTransTypes
   
   /* Validate GLJrnl in bEMCO GLLvl <> NoUpdate - can be null in bEMCO but cannot be null in bGLDT. */
   
   -- Ref Issue 18024 - For EMTime Source, validate GLOffsetAcct SubType = null
   select @glsubtype = (select SubType From bGLAC where GLCo = @glco and GLAcct = @gloffsetacct)
   if @glsubtype is not null	
   	begin
   	select @errtext = 'GLOffsetAcct: ' + isnull(convert(varchar(20),@gloffsetacct),'') + ' has a Subledger Type: ' + isnull(@glsubtype,'') + '. Must be null!'
   	exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   	if @rcode <> 0
   		begin
   		select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   		goto bspexit
   		end
   	end
   
   -- Validate GLTransAcct SubType = 'E' or null
   select @glsubtype = (select SubType From bGLAC where GLCo = @glco and GLAcct = @gltransacct)
   if @glsubtype <> 'E' and IsNull(@glsubtype,'')<>''	-- #18522
   	begin
   	select @errtext = 'GL Account: ' + isnull(convert(varchar(20),@gltransacct),'') + ' has a Subledger Type: ' + isnull(@glsubtype,'') + '. Must be E or null!'
   	exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   	if @rcode <> 0
   		begin
   		select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   		goto bspexit
   		end
   	end
   
   -- Valide GLJrnl
   select @gljrnl = AdjstGLJrnl, @glco = GLCo, @gllvl = AdjstGLLvl from bEMCO where EMCo = @co
   if @gllvl <> 0 /* Dont check on No Update GL Lvl. */
   	begin
   	if @gljrnl is null
   
   		begin
   		select @errtext = 'GLJrnl null in bEMCO.'
   		exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   		if @rcode <> 0
   			begin
   			select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   			goto bspexit
   			end
   		end
   	else
   		begin
   		exec @rcode = dbo.bspGLJrnlVal @glco, @gljrnl, @errmsg output
   		if @rcode = 1
   			begin
   			select @errtext = 'GLJrnl ' + isnull(@gljrnl,'') + '-' + isnull(@errmsg,'')
   			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   			if @rcode <> 0
   				begin
   				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   				goto bspexit
   				end
   			end
   		end
   	end
   
   /* Validate Source */
   if @source <> 'EMTime'
   	begin
   	select @errtext = isnull(@errorstart,'') + isnull(@source,'') + ' is invalid Source.'
   	exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   	if @rcode <> 0
   		begin
   		select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   		goto bspexit
   		end
   	end
   
   /* Validate EMTransType = */
   if @emtranstype <> 'WO' and @emtranstype <> 'Equip'
   	begin
   	select @errtext = isnull(@errorstart,'') + isnull(@emtranstype,'') + ' is an invalid EMTransType.'
   	exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   	if @rcode <> 0
   		begin
   		select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   		goto bspexit
   		end
   	end
   
   
   /* Verify Hours not null. */
   if @hours is null 
   	begin
   	select @errtext = isnull(@errorstart,'') + 'Invalid Hours, must be not null.'
   	exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   	if @rcode <> 0
   		begin
   		select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   		goto bspexit
   		end
   	end
   
   /* Verify UnitPrice not null. */
   if @unitprice is null 
   	begin
   	select @errtext = isnull(@errorstart,'') + 'Invalid UnitPrice, must be not null.'
   	exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   	if @rcode <> 0
   		begin
   		select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   		goto bspexit
   		end
   	end
   
   /* Verify Dollars not null. */
   if @dollars is null 
   	begin
   	select @errtext = isnull(@errorstart,'') + 'Invalid Dollars, must be not null.'
   	exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   	if @rcode <> 0
   		begin
   		select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   		goto bspexit
   		end
   	end
   
   -- Issue #20029
   -- update units = hours
   update bEMBF set Units = Hours 
   where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@batchseq
   
   ---------------BatchTransType = A & C
   if @batchtranstype in ('A', 'C')
   	begin
   
   	/* Validate PRCo */
   	if @prco is not null
   		begin
   		exec @rcode = dbo.bspPRCompanyVal @prco, @errmsg output
   		if @rcode = 1
   			begin
   			select @errtext = isnull(@errorstart,'') + 'PRCo ' + isnull(convert(varchar(6),@prco),'') + ' not on file. - ' + isnull(@errmsg,'')
   			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   			if @rcode <> 0
   				begin
   				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   				goto bspexit
   				end
   			end
   		end
   	
   	/* Validate PREmployee; must be Active */
   	if @premployee is not null
   		begin
   		exec @rcode = dbo.bspPREmplValForWOTimeCards @prco, @premployee, 'Y', null, null, @errmsg output
   		if @rcode = 1
   			begin
   			select @errtext = isnull(@errorstart,'') + 'Employee ' + isnull(convert(varchar(6),@premployee),'') + isnull(@errmsg,'')
   			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   			if @rcode <> 0
   				begin
   				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   				goto bspexit
   				end
   			end
   		end
   	
   	/* Validate WorkOrder - can be null - do not validate if EMTransType = 'Equip' */
   	if @workorder is not null and @emtranstype = 'WO'
   		begin
   		exec @rcode = dbo.bspEMWOValForTimeCards @co, @workorder, null, null, null, @errmsg output
   		if @rcode = 1
   			begin
   			select @errtext = isnull(@errorstart,'') + 'WorkOrder ' + isnull(@workorder,'') + '-' + isnull(@errmsg,'')
   			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   			if @rcode <> 0
   				begin
   				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   				goto bspexit
   				end
   			end
   		end
   	
   	/* Validate WOItem - can be null - do not validate if EMTransType = 'Equip' */
   	if @woitem is not null and @emtranstype = 'WO'
   		begin
   		exec @rcode = dbo.bspEMWOItemValForTimeCards @co, @workorder, @woitem, 
   			null, null, null, null, @errmsg output
   		if @rcode = 1
   			begin
   			select @errtext = isnull(@errorstart,'') + 'WOItem ' + isnull(convert(varchar(5),@woitem),'') + '-' + isnull(@errmsg,'')
   			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   			if @rcode <> 0
   				begin
   				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   				goto bspexit
   				end
   			end
   		end
   	
   	/* Validate Equipment - cannot be null. */
   	if @equipment is not null 
   		begin
   		exec @rcode = dbo.bspEMEquipValForTimeCards @co, @equipment, null, null, null, 
   			null, null, null, null, null, @errmsg output
   		if @rcode = 1
   			begin
   			select @errtext = isnull(@errorstart,'') + 'Equipment ' + isnull(convert(varchar(5),@equipment),'') + ' invalid -' + isnull(@errmsg,'')
   			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   			if @rcode <> 0
   				begin
   				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   				goto bspexit
   				end
   			end
   		end
   
   	/* Validate ComponentTypeCode - can be null. */
   	if @componenttypecode is not null
   		begin
   		exec @rcode = dbo.bspEMComponentTypeCodeVal @co, @componenttypecode, @component, @equipment,
   		@emgroup, null, null, @errmsg output
   		if @rcode = 1
   
   			begin
   			select @errtext = isnull(@errorstart,'') + 'ComponentTypeCode ' + isnull(@componenttypecode,'') + '-' + isnull(@errmsg,'')
   			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   			if @rcode <> 0
   				begin
   				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   				goto bspexit
   				end
   			end
   		end
   	
   	/* Validate Component - can be null. */
   	if @component is not null
   		begin
   		exec @rcode = dbo.bspEMComponentVal @co, @component, @equipment, @emgroup, null, null, @errmsg output
   		if @rcode = 1
   			begin
   			select @errtext = isnull(@errorstart,'') + 'Component ' + isnull(@component,'') + '-' + isnull(@errmsg,'')
   			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   			if @rcode <> 0
   				begin
   				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   				goto bspexit
   				end
   			end
   		end
   	
   	/* JM 12-3-02 - Ref Issue 19127 - Moved establishment of GLTransAcct and GLOffsetAcct from form to validation. */
   	/* Validate CostCode - can be null. */
   	if @costcode is not null
   		begin
   		exec @rcode = dbo.bspEMCostCodeValForWOTimeCards @co, @equipment, @emgroup, @costcode, @gltransacct output, @gloffsetacct output, @errmsg output
   		if @rcode = 1
   			begin
   			select @errtext = isnull(@errorstart,'') + 'CostCode ' + isnull(@costcode,'') + '-' + isnull(@errmsg,'')
   			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   			if @rcode <> 0
   				begin
   				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   				goto bspexit
   				end
   			end
   		
    		-- update gl accounts in bEMBF
    		update bEMBF set GLTransAcct = @gltransacct, GLOffsetAcct = @gloffsetacct 
    		where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
   		-- validate GL Trans Account
   		if isnull(@gltransacct,'') <> ''
   			begin
   			exec @rcode = dbo.bspEMGLTransAcctVal @glco, @gltransacct, 'E', @errmsg output
   	     	if @rcode = 1
   	     		begin
   	     		select @errtext = isnull(@errorstart,'') + 'GLTransAcct ' + isnull(@gltransacct,'') + '-' + isnull(@errmsg,'')
   	     		exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   	     		if @rcode <> 0
   	     			begin
   	     			select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   	     			goto bspexit
   	     			end
   	     		end
   			end
   		-- validate GL Offset Account
   		if isnull(@gloffsetacct,'') <> ''
   			begin
   	 		exec @rcode = dbo.bspEMGLOffsetAcctValForFuelPosting  @co, null, @gloffsetacct, null, @errmsg output
   	 		if @rcode = 1
   	 			begin
   	 			select @errtext = isnull(@errorstart,'') + 'GLOffsetAcct ' + isnull(@gloffsetacct,'') + '-' + isnull(@errmsg,'')
   	 			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   	 			if @rcode <> 0
   	 				begin
   	 				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   	 				goto bspexit
   	 				end
   	 			end
   	 		end
   		end
   
   	/* Validate EMGroup - can be null. */
   	if @emgroup is not null
   		begin
   		exec @rcode = dbo.bspHQGroupVal @emgroup, @errmsg output
   		if @rcode = 1
   			begin
   			select @errtext = isnull(@errorstart,'') + 'EMGroup ' + isnull(convert(varchar(5),@emgroup),'') + '-' + isnull(@errmsg,'')
   			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   			if @rcode <> 0
   				begin
   				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   				goto bspexit
   				end
   			end
   		end
   	
   	/* Validate EMCostType - can be null. */
   	if @emcosttype is not null
   		begin
   		exec @rcode = dbo.bspEMCostTypeVal @emgroup, @emcosttype, null, @errmsg output
   		if @rcode = 1
   			begin
   			select @errtext = isnull(@errorstart,'') + 'EMCostType ' + isnull(convert(varchar(5),@emcosttype),'') + '-' + isnull(@errmsg,'')
   			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   			if @rcode <> 0
   				begin
   				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   				goto bspexit
   				end
   			end
   		end
   
   	/* Validate CostCode/CostType combination */ --issue 18685
   	if @costcode is not null and @emcosttype is not null
   		begin
   		exec @rcode = dbo.bspEMCostTypeCostCodeVal @emgroup, @costcode, @emcosttype, null, @errmsg output
   		if @rcode = 1
   			begin
   			select @errtext = isnull(@errorstart,'') + 'CostCode ' + isnull(@costcode,'') + '/EMCostType ' + isnull(convert(varchar(5),@emcosttype),'') + '-' + isnull(@errmsg,'')
   			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   			if @rcode <> 0
   				begin
   				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   				goto bspexit
   				end
   			end
   		end
   	
   	/* Validate GLCo - can be null. */
   	if @glco is not null
   		begin
   		exec @rcode = dbo.bspGLCompanyVal @glco, @errmsg output
   		if @rcode = 1
   			begin
   			select @errtext = isnull(@errorstart,'') + 'GLCo ' + isnull(convert(varchar(5),@glco),'') + '-' + isnull(@errmsg,'')
   			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   			if @rcode <> 0
   				begin
   				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   				goto bspexit
   				end
   			end
   		end
   	
   	-- Verify UnitPrice = bPREH.EMFixedRate - cannot be null
   	-- per issue #21285 do not care if rates are different
   	/*
   	if @unitprice <> (select EMFixedRate from bPREH where PRCo = @prco and Employee = @premployee)
   		begin
   		select @errtext = isnull(@errorstart,'') + 'UnitPrice does not match EMFixedRate in bPREH for this Employee -'
   		exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   		if @rcode <> 0
   			begin
   			select @errmsg = @errtext + isnull(@errmsg,'')
   			goto bspexit
   			end
   		end*/
   
   
   	/* Validate UM - can be null. */
   	if @um is not null
   		begin
   		if @um <> 'HRS'
   			begin
   			select @errtext = isnull(@errorstart,'') + 'UM ' + isnull(@um,'') + ' invalid - must be HRS -'
   			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   			if @rcode <> 0
   				begin
   				select @errmsg = isnull(@errtext,'') + isnull(@errmsg,'')
   				goto bspexit
   				end
   			end
   		end
   
   	/* Validate PerECM - can be null. */
   	if @perecm is not null
   		begin
   		if @perecm <> 'E'
   			begin
   			select @errtext = isnull(@errorstart,'') + 'PerECM ' + isnull(@perecm,'') + ' invalid - must be E -'
   			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   			if @rcode <> 0
   				begin
   				select @errmsg = isnull(@errtext,'') + isnull(@errmsg,'')
   				goto bspexit
   				end
   			end
   		end
   	
   	-- Ref Issue 14064 - JM - Check for blank GLTransAcct 
   	if isnull(@gltransacct,'') = ''
   		begin
   		select @errtext = isnull(@errorstart,'') + 'GLTransAcct blank.'
   		exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   		if @rcode <> 0
   			begin
   			select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   			goto bspexit
   			end
   		end
   
   	/* Validate ReversalStatus - can be null.
   	If null convert to 0; otherwise must be 0, 1, 2, 3, 4 */
   	if @reversalstatus is null
   		update bEMBF set ReversalStatus = 0 where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
   	else
   		if @reversalstatus not in (0,1,2,3,4)
   			begin
   			select @errtext = isnull(@errorstart,'') + 'ReversalStatus ' + isnull(convert(char(2),@reversalstatus),'') + ' invalid. Must be 0, 1, 2, 3, or 4.'
   			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   			if @rcode <> 0
   				begin
   				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   				goto bspexit
   				end
   			end
   
   	end --if @batchtranstype in ('A', 'C')
   
   /* Note that for Source = EMTime GLTrans and GLOffset accts are allowed to be  the same. */
   
   ---------------BatchTransType = C & D
   if @batchtranstype in ('C','D')
   	begin
   
   	 /* Get existing values from EMCD. */
   	select @emcdactualdate = ActualDate, @emcdcomponent = Component, @emcdcomponenttypecode = ComponentTypeCode, @emcdcostcode = CostCode, 
   		@emcddollars = Dollars, @emcdemcosttype = EMCostType, @emcdemgroup = EMGroup, @emcdemtrans = EMTrans, @emcdemtranstype = EMTransType, 
   		@emcdequipment = Equipment, @emcdglco = GLCo, @emcdgloffsetacct = GLOffsetAcct, @emcdgltransacct = GLTransAcct, 
   		@emcdinusebatchid = InUseBatchID, @emcdperecm = PerECM, @emcdprco = PRCo, @emcdpremployee = PREmployee, 
   		@emcdreversalstatus = ReversalStatus, @emcdsource = Source, @emcdum = UM, @emcdunitprice = UnitPrice, @emcdunits = Units, 
   		@emcdwoitem = WOItem, @emcdworkorder = WorkOrder
   	from bEMCD where EMCo = @co and Mth = @mth and EMTrans = @emtrans
   	
   	if @@rowcount = 0
   		begin
   		select @errtext = isnull(@errorstart,'') + '-Missing EM Detail Transaction #:' + isnull(convert(char(3),@emtrans),'')
   		exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   		if @rcode <> 0
   			begin
   			select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   			goto bspexit
   			end
   		end
   	
   	/* Verify EMCD record assigned to same BatchId. */
   	if @emcdinusebatchid <> @batchid
   		begin
   		select @errtext = isnull(@errorstart,'') + '-Detail Transaction has not been assigned to this BatchId.'
   		exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   		if @rcode <> 0
   			begin
   			select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   			goto bspexit
   			end
   		end
   	
   	/* Make sure old values in batch match existing values in cost detail table. */
   	if @emcdactualdate <> @oldactualdate
   		or isnull(@emcdcomponent,'') <> isnull(@oldcomponent,'')
   		or isnull(@emcdcomponenttypecode,'') <> isnull(@oldcomponenttypecode,'')
   		or @emcdcostcode <> @oldcostcode
   		or isnull(@emcddollars,0) <> isnull(@olddollars,0)
   		or @emcdemcosttype <> @oldemcosttype
   		or @emcdemgroup <> @oldemgroup 
   		or @emcdemtrans <> @oldemtrans
   		or isnull(@emcdemtranstype,'') <> isnull(@oldemtranstype,'')
   		or @emcdequipment <> @oldequipment
   		or isnull(@emcdglco,0) <> isnull(@oldglco,0)
   		or isnull(@emcdgloffsetacct,'') <> isnull(@oldgloffsetacct,'')
   		or isnull(@emcdgltransacct,'') <> isnull(@oldgltransacct,'')
   		or isnull(@emcdperecm,'') <> isnull(@oldperecm,'')
   		or isnull(@emcdprco,0) <> isnull(@oldprco,0)
   		or isnull(@emcdpremployee,'') <> isnull(@oldpremployee,'')
   		or isnull(@emcdreversalstatus,0) <> isnull(@oldreversalstatus,0)
   		or isnull(@emcdsource,'') <> isnull(@oldsource,'')
   		or isnull(@emcdum,'') <> isnull(@oldum,'')
   		or isnull(@emcdunitprice,0) <> isnull(@oldunitprice,'')
   		/*or @emcdunits <> @oldhours*/ --issue 19037
   		or isnull(@emcdwoitem,0) <> isnull(@oldwoitem,0)
   		or isnull(@emcdworkorder,'') <> isnull(@oldworkorder,'')
   		begin
   		select @errtext = isnull(@errorstart,'') + '-Batch Old info does not match EM Cost Detail.'
   		exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   		if @rcode <> 0
   			begin
   			select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   			goto bspexit
   			end
   		end
   
   	/* Validate OldPRCo */
   	if @oldprco is not null
   		begin
   		exec @rcode = dbo.bspPRCompanyVal @oldprco, @errmsg output
   		if @rcode = 1
   			begin
   			select @errtext = isnull(@errorstart,'') + 'OldPRCo ' + isnull(convert(varchar(6),@oldprco),'') + ' not on file. - ' + isnull(@errmsg,'')
   			--select @errtext = isnull(@errorstart,'') + isnull(@errmsg,'')
   			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   			if @rcode <> 0
   				begin
   				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   				goto bspexit
   				end
   			end
   		end
   	
   	/* Validate OldPREmployee; must be Active */
   	if @oldpremployee is not null
   		begin
   
   		exec @rcode = dbo.bspPREmplValForWOTimeCards @oldprco, @oldpremployee, 'Y', null, null, @errmsg output
   		if @rcode = 1
   			begin
   			select @errtext = isnull(@errorstart,'') + 'OldEmployee ' + isnull(convert(varchar(6),@oldpremployee),'') + ' not on file. - ' + isnull(@errmsg,'')
   			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   			if @rcode <> 0
   				begin
   				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   				goto bspexit
   				end
   			end
   		end
   	
   	/* Validate OldWorkOrder - can be null - do not validate if OldEMTransType = 'Equip' */
   	if @oldworkorder is not null and @oldemtranstype = 'WO'
   		begin
   		exec @rcode = dbo.bspEMWOVal @co, @oldworkorder, @errmsg output
   		if @rcode = 1
   			begin
   			select @errtext = isnull(@errorstart,'') + 'OldWorkOrder ' + isnull(@oldworkorder,'') + '-' + isnull(@errmsg,'')
   			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   			if @rcode <> 0
   				begin
   				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   				goto bspexit
   				end
   			end
   		end
   	
   	/* Validate OldWOItem - can be null - do not validate if OldEMTransType = 'Equip' */
   	if @oldwoitem is not null and @oldemtranstype = 'WO'
   		begin
   		exec @rcode = dbo.bspEMWOItemValForTimeCards @co, @oldworkorder, @oldwoitem, 
   			null, null, null, null, @errmsg output
   		if @rcode = 1
   			begin
   			select @errtext = isnull(@errorstart,'') + 'OldWOItem ' + isnull(convert(varchar(5),@oldwoitem),'') + '-' + isnull(@errmsg,'')
   			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   			if @rcode <> 0
   				begin
   				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   				goto bspexit
   				end
   			end
   		end
   	
   	/* Validate OldEquipment - cannot be null. */
   	if @oldequipment is not null 
   		begin
   		exec @rcode = dbo.bspEMEquipValNoComponent @co, @oldequipment, null, null, null, null, null, @errmsg output
   		if @rcode = 1
   			begin
   			select @errtext = isnull(@errorstart,'') + 'OldEquipment ' + isnull(convert(varchar(5),@oldequipment),'') + ' invalid -' + isnull(@errmsg,'')
   			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   			if @rcode <> 0
   				begin
   				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   				goto bspexit
   				end
   			end
   		end
   
   	/* Validate OldComponentTypeCode - can be null. */
   	if @oldcomponenttypecode is not null
   		begin
   		exec @rcode = dbo.bspEMComponentTypeCodeVal @co, @oldcomponenttypecode, @oldcomponent, @oldequipment,
   		@oldemgroup, null, null, @errmsg output
   		if @rcode = 1
   			begin
   			select @errtext = isnull(@errorstart,'') + 'OldComponentTypeCode ' + isnull(@oldcomponenttypecode,'') + '-' + isnull(@errmsg,'')
   			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   			if @rcode <> 0
   				begin
   				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   				goto bspexit
   				end
   			end
   		end
   	
   	/* Validate OldComponent - can be null. */
   	if @oldcomponent is not null
   		begin
   		exec @rcode = dbo.bspEMComponentVal @co, @oldcomponent, @oldequipment, @oldemgroup, null, null, @errmsg output
   		if @rcode = 1
   			begin
   			select @errtext = isnull(@errorstart,'') + 'OldComponent ' + isnull(@oldcomponent,'') + '-' + isnull(@errmsg,'')
   			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   			if @rcode <> 0
   				begin
   				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   				goto bspexit
   				end
   			end
   		end
   	
   	/* Validate OldCostCode - can be null. */
   	if @oldcostcode is not null
   		begin
   
   		exec @rcode = dbo.bspEMCostCodeValForWOTimeCards @co, @oldequipment, @oldemgroup, @oldcostcode, null, null, @errmsg output
   		if @rcode = 1
   			begin
   			select @errtext = isnull(@errorstart,'') + 'OldCostCode ' + isnull(@oldcostcode,'') + '-' + isnull(@errmsg,'')
   			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   			if @rcode <> 0
   				begin
   				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   				goto bspexit
   				end
   			end
   		end
   
   	/* Validate OldEMGroup - can be null. */
   	if @oldemgroup is not null
   		begin
   		exec @rcode = dbo.bspHQGroupVal @oldemgroup, @errmsg output
   		if @rcode = 1
   			begin
   			select @errtext = isnull(@errorstart,'') + 'OldEMGroup ' + isnull(convert(varchar(5),@oldemgroup),'') + '-' + isnull(@errmsg,'')
   			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   			if @rcode <> 0
   				begin
   				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   				goto bspexit
   				end
   			end
   		end
   	
   	/* Validate OldEMCostType - can be null. */
   	if @oldemcosttype is not null
   		begin
   		exec @rcode = dbo.bspEMCostTypeVal @oldemgroup, @oldemcosttype, null, @errmsg output
   		if @rcode = 1
   			begin
   			select @errtext = isnull(@errorstart,'') + 'OldEMCostType ' + isnull(convert(varchar(5),@oldemcosttype),'') + '-' + isnull(@errmsg,'')
   			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   			if @rcode <> 0
   				begin
   				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   				goto bspexit
   				end
   			end
   		end
   	
   	/* Validate OldGLCo - can be null. */
   	if @oldglco is not null
   		begin
   		exec @rcode = dbo.bspGLCompanyVal @oldglco, @errmsg output
   		if @rcode = 1
   			begin
   			select @errtext = isnull(@errorstart,'') + 'OldGLCo ' + isnull(convert(varchar(5),@oldglco),'') + '-' + isnull(@errmsg,'')
   			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   			if @rcode <> 0
   				begin
   				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   				goto bspexit
   				end
   			end
   		end
   	
   	-- Verify OldUnitPrice = bPREH.EMFixedRate - cannot be null
   	--if @oldunitprice <> (select EMFixedRate from bPREH where PRCo = @oldprco and Employee = @oldpremployee)
   	--	begin
   	--	select @errtext = isnull(@errorstart,'') + 'OldUnitPrice does not match EMFixedRate in bPREH for this Employee -'
   	--	exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   	--	if @rcode <> 0
   	--		begin
   	--		select @errmsg = @errtext + isnull(@errmsg,'')
   	--		goto bspexit
   	--		end
   	--	end
   
   
   	/* Validate OldUM - can be null. */
   	if @oldum is not null
   		begin
   		if @oldum <> 'HRS'
   			begin
   			select @errtext = isnull(@errorstart,'') + 'OldUM ' + isnull(@oldum,'') + ' invalid - must be HRS -'
   			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   			if @rcode <> 0
   				begin
   				select @errmsg = @errtext + isnull(@errmsg,'')
   				goto bspexit
   				end
   			end
   		end
   
   	/* Validate OldPerECM - can be null. */
   	if @oldperecm is not null
   		begin
   		if @oldperecm <> 'E'
   			begin
   			select @errtext = isnull(@errorstart,'') + 'OldPerECM ' + isnull(@oldperecm,'') + ' invalid - must be E -'
   			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   			if @rcode <> 0
   				begin
   				select @errmsg = @errtext + isnull(@errmsg,'')
   				goto bspexit
   				end
   			end
   		end
   	
   	/* Verify OldGLOffsetAcct = bEMDM.LaborFixedRateAcct */
   	if @oldgloffsetacct is not null
   		begin
   		if @oldgloffsetacct <> (select LaborFixedRateAcct from bEMDM where EMCo = @co 
   				and Department = (select Department from bEMEM where EMCo = @co and Equipment = @oldequipment))
   			begin
   			select @errtext = isnull(@errorstart,'') + 'OldGLOffsetAcct does not match bEMDM.LaborFixedRateAcct for Dept : ' + isnull(@department,'') + '.'
   			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   			if @rcode <> 0
   				begin
   				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   				goto bspexit
   				end
   			end
   		end
   	
   	/* Validate OldGLTransAcct - can be null */
   	if @oldgltransacct is not null 
   		begin
   		exec @rcode = dbo.bspEMGLTransAcctVal @glco, @oldgltransacct, 'E', @errmsg output
   		if @rcode = 1
   			begin
   			select @errtext = isnull(@errorstart,'') + 'OldGLTransAcct ' + isnull(@oldgltransacct,'') + '-' + isnull(@errmsg,'')
   			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   			if @rcode <> 0
   				begin
   				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   				goto bspexit
   				end
   			end
   		end
   	
   	/* Ref Issue 14064 - JM - Check for blank OldGLTransAcct */
   	select @oldgltransacct = rtrim(ltrim(@oldgltransacct))
   	if @oldgltransacct = ''
   		begin
   		select @errtext = isnull(@errorstart,'') + 'OldGLTransAcct blank.'
   		exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   		if @rcode <> 0
   			begin
   			select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   			goto bspexit
   			end
   		end
   
   	/* Validate OldReversalStatus - can be null.
   	If null convert to 0; otherwise must be 0, 1, 2, 3, 4 */
   	/*if @oldreversalstatus is null
   		update bEMBF set OldReversalStatus = 0 where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
   	else
   		if @oldreversalstatus not in (0,1,2,3,4)
   			begin
   			select @errtext = isnull(@errorstart,'') + 'OldReversalStatus ' + convert(char(2),@oldreversalstatus) + ' invalid. Must be 0, 1, 2, 3, or 4.'
   			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   			if @rcode <> 0
   				begin
   				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   				goto bspexit
   				end
   			end*/
   
   	end --if @batchtranstype in ('C','D')
   
   
   
   bspexit:
   	if @rcode<>0 select @errmsg=isnull(@errmsg,'')	--+ char(13) + char(10) + '[bspEMVal_Cost_SeqVal_Time]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMVal_Cost_SeqVal_Time] TO [public]
GO
