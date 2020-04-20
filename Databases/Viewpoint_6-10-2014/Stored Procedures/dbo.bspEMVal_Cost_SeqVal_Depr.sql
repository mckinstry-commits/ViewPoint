SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE             procedure [dbo].[bspEMVal_Cost_SeqVal_Depr]
   /***********************************************************
   * CREATED BY: JM 7/9/02 - Ref Issue 17743 - Combination bspEMVal_Cost_AddedChanged and 
   *	bspEMVal_Cost_ChangedDeleted for each source, called from bspEMVal_Cost_Main
   *
   * MODIFIED By :  GG 09/20/02 - #18522 ANSI nulls
   *		JM 10-02-02 -  Ref Issue 18024 - For EMDepr Source, validate GLOffsetAcct SubType = null
   *       		DANF 10/09/02 - 18873 Corrected Asset validation when the asset is assign to a component.
   *		JM 10-09-02 -  Remove 'rtrim(ltrim(' from GLTransAcct validation against blank (per DF)
   *		TV 02/11/04 - 23061 added isnulls
   *		TV 06/22/04 issue 24853 - Was passing Co instead of GLCO
  *				TRL 02/04/2010 Issue 137916  change @description to 60 characters
  * 
   * USAGE:
   * 	Called by bspEMVal_Cost_Main to run validation applicable only to referenced EMCost Source.
   *
   *	Form: EMDeprProc
   *	Posting table: bEMBF
   *	Visible bound inputs that use the same valproc here as in DDFI:
   *		<None>
   *	Hidden bound inputs without valprocs in DDFI that receive basic validation here:
   *		<None>
   *	Bound inputs that do not receive validation here:
   *		<None>
   *	Fields supplied to bEMBF by processing form procedure bspEMProcDepr that 
   *	receive basic validation here:
   *		Source
   *		Equipment
   *		EMTransType
   *		ComponentTypeCode
   *		Component
   *		Asset
   *		EMGroup
   *		CostCode
   *		EMCostType
   *		GLCo
   *		GLTransAcct
   *		GLOffsetAcct
   *	Fields supplied to bEMBF by processing form procedure bspEMProcDepr that 
   *	do not receive basic validation here:
   *		BatchTransType
   *		ActualDate
   *		Description
   *		Units
   *		Dollars
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
   declare @ctchar varchar(3),@errorstart varchar(50), @errtext varchar(255), @gljrnl bJrnl, @gllvl tinyint, @glsubtype char(1), @rcode int
   
   /* bEMBF non-Olds decs */
   declare @actualdate bDate, @asset varchar(20), @batchtranstype char(1), @component bEquip, @componenttypecode varchar(10), @costcode bCostCode, 
   	@description bItemDesc/*137916*/, @dollars bDollar, @emcosttype bEMCType, @emgroup bGroup, @emtrans bTrans, @emtranstype varchar(10), @equipment bEquip, 
   	@glco bCompany, @gloffsetacct bGLAcct, @gltransacct bGLAcct, @reversalstatus tinyint, @source varchar(10), @units bUnits
   
   /* bEMBF Olds decs */
   declare @oldactualdate bDate, @oldasset varchar(20), @oldbatchtranstype char(1), @oldcomponent bEquip, @oldcomponenttypecode varchar(10), 
   	@oldcostcode bCostCode, @olddescription bItemDesc/*137916*/, @olddollars bDollar, @oldemcosttype bEMCType, @oldemgroup bGroup, @oldemtrans bTrans, 
   	@oldemtranstype varchar(10), @oldequipment bEquip, @oldglco bCompany, @oldgloffsetacct bGLAcct, @oldgltransacct bGLAcct, 
   	@oldreversalstatus tinyint, @oldsource varchar(10), @oldunitprice bUnitCost, @oldunits bUnits
   
   /* bEMCD decs */
   declare @emcdactualdate bDate, @emcdasset varchar(20), @emcdcomponent bEquip,  @emcdcomponenttypecode varchar(10), @emcdcostcode bCostCode, 
    	@emcddescription bItemDesc/*137916*/, @emcddollars bDollar,	@emcdemcosttype bEMCType, @emcdemgroup bGroup, @emcdemtrans bTrans, 
   	@emcdemtranstype varchar(10), @emcdequipment bEquip, @emcdglco bCompany, @emcdgloffsetacct bGLAcct, @emcdgltransacct bGLAcct, 
   	@emcdinusebatchid bBatchID, @emcdreversalstatus tinyint, @emcdsource varchar(10), @emcdunitprice bUnitCost, @emcdunits bUnits
   
   declare @equipmentasset bEquip
   
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
   select @actualdate = ActualDate, @asset = Asset, @batchtranstype = BatchTransType, @component = Component, @componenttypecode = ComponentTypeCode, 
   	@costcode = CostCode, @description = Description, @dollars = Dollars, @emcosttype = EMCostType, @emgroup = EMGroup, @emtranstype = EMTransType, 
   	@equipment = Equipment, @glco = GLCo, @gloffsetacct = GLOffsetAcct, @gltransacct = GLTransAcct, @reversalstatus = ReversalStatus, @source =rtrim( Source), 
   	@units = Units, @oldactualdate = OldActualDate, @oldasset = OldAsset, @oldbatchtranstype = OldBatchTransType, @oldcomponent = OldComponent, 
   	@oldcomponenttypecode = OldComponentTypeCode, @oldcostcode = OldCostCode, @olddescription = OldDescription, @olddollars = OldDollars, 
   	@oldemcosttype = OldEMCostType, @oldemgroup = OldEMGroup, @oldemtranstype = OldEMTransType, @oldequipment = OldEquipment, 
   	@oldglco = OldGLCo, @oldgloffsetacct = OldGLOffsetAcct, @oldgltransacct = OldGLTransAcct, 
   	@oldreversalstatus = ReversalStatus, @oldsource = rtrim(OldSource), @oldunitprice = OldUnitPrice, @oldunits = OldUnits
   from bEMBF where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
   
   /* Setup @errorstart string. */
   select @errorstart = 'Seq ' + isnull(convert(varchar(9),@batchseq),'') + '-'
   
   ---------------All BatchTransTypes
   /* Validate GLJrnl in bEMCO GLLvl <> NoUpdate - can be null in bEMCO but cannot be null in bGLDT.
   Need to do this validation record-by-record because EMAdj sources can have EMTransType = 'Fuel' which uses a
   different GL set than all other EMAdj EMTransTypes. */
   
   -- Ref Issue 18024 - For EMDepr Source, validate GLOffsetAcct SubType is null
   select @glsubtype = (select SubType From bGLAC where GLCo = @glco and GLAcct = @gloffsetacct)
   if @glsubtype is not null	
   	begin
   	select @errtext = 'GLOffsetAcct: ' + isnull(convert(varchar(20),@gloffsetacct),'') + ' has a Subledger Type: ' + isnull(@glsubtype,'') + '. Must be null!'
   	exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   	if @rcode <> 0
   		begin
   		select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   		goto bspexit
   		end
   	end
   
   -- Validate GLTransAcct SubType = 'E' or null
   select @glsubtype = (select SubType From bGLAC where GLCo = @glco and GLAcct = @gltransacct)
   if @glsubtype <> 'E' and @glsubtype is not null		-- #18522
   	begin
   	select @errtext = 'GLTransAcct: ' + isnull(convert(varchar(20),@gltransacct),'') + ' has a Subledger Type: ' + isnull(@glsubtype,'') + '. Must be E or null!'
   	exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
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
   		exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   		if @rcode <> 0
   			begin
   			select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   			goto bspexit
   			end
   		end
   	else
   		begin
   		exec @rcode = bspGLJrnlVal @glco, @gljrnl, @errmsg output
   		if @rcode = 1
   			begin
   			select @errtext = 'GLJrnl ' + isnull(@gljrnl,'') + '-' + isnull(@errmsg,'')
   			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   			if @rcode <> 0
   				begin
   				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   				goto bspexit
   				end
   			end
   		end
   	end
   
   /* Validate Source */
   if @source <> 'EMDepr'
   	begin
   	select @errtext = isnull(@errorstart,'') + isnull(@source,'') + ' is invalid Source.'
   	exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   	if @rcode <> 0
   		begin
   		select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   		goto bspexit
   		end
   	end
   
   /* Validate EMTransType = */
   if @emtranstype <> 'Depn'
   	begin
   	select @errtext = isnull(@errorstart,'') + isnull(@emtranstype,'') + ' is an invalid EMTransType.'
   	exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   	if @rcode <> 0
   		begin
   		select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   		goto bspexit
   		end
   	end
   
   /* Verify Units not null. */
   if @units is null 
   	begin
   	select @errtext = isnull(@errorstart,'') + 'Invalid Units, must be not null.'
   	exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
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
   	exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   	if @rcode <> 0
   		begin
   		select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   		goto bspexit
   		end
   	end
   
   ---------------BatchTransType = A & C
   
   if @batchtranstype in ('A','C')
   	begin
   
   	/* Validate Equipment - cannot be null. */
   	/* JM - 01/17/02 - Ref Issue 15162 - Allow Depn batches to post to inactive equipment. */
   	exec @rcode = dbo.bspEMEquipValInactiveOK @co, @equipment, @errmsg output
   	if @rcode = 1
   		begin
   		select @errtext = isnull(@errorstart,'') + 'Equipment ' + isnull(@equipment,'') + '-' + isnull(@errmsg,'')
   		exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   		if @rcode <> 0
   			begin
   			select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   			goto bspexit
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
   			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
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
   			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   			if @rcode <> 0
   				begin
   				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   				goto bspexit
   				end
   			end
   		end
   	
   	/* Validate Asset - can be null. */
   	if @asset is not null
   		begin
   		select @equipmentasset = @equipment
   		if isnull(@component,'')<>'' select @equipmentasset = @component
   		exec @rcode = dbo.bspEMAssetVal @co, @asset, @equipmentasset, @errmsg output
   		if @rcode = 1
   		begin
   			select @errtext = isnull(@errorstart,'') + 'Asset ' + isnull(@asset,'') + '-' + isnull(@errmsg,'')
   			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   			if @rcode <> 0
   				begin
   				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   				goto bspexit
   				end
   			end
   		end
   	
   	/* Validate EMGroup - can be null. */
   	if @emgroup is not null
   		begin
   		exec @rcode = bspHQGroupVal @emgroup, @errmsg output
   		if @rcode = 1
   			begin
   			select @errtext = isnull(@errorstart,'') + 'EMGroup ' + isnull(convert(varchar(5),@emgroup),'') + '-' + isnull(@errmsg,'')
   			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   			if @rcode <> 0
   				begin
   				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   				goto bspexit
   				end
   			end
   		end
   	
   	/* Validate CostCode - can be null. */
   	if @costcode is not null
   		begin
   		exec @rcode = dbo.bspEMCostCodeVal @emgroup, @costcode, @errmsg output
   		if @rcode = 1
   			begin
   			select @errtext = isnull(@errorstart,'') + 'CostCode ' + isnull(@costcode,'') + '-' + isnull(@errmsg,'')
   			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
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
   		select @ctchar = convert(varchar(3),@emcosttype)
   		exec @rcode = dbo.bspEMCostTypeValForCostCode @co, @emgroup, @ctchar, @costcode, @equipment, 'N', null, null, @errmsg output
   		if @rcode = 1
   			begin
   			select @errtext = isnull(@errorstart,'') + 'EMCostType ' + isnull(convert(varchar(5),@emcosttype),'') + '-' + isnull(@errmsg,'')
   			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
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
   			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   			if @rcode <> 0
   				begin
   				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   				goto bspexit
   				end
   			end
   		end
   	
   	/* Validate GLTransAcct - can be null */
   	/* Ref Issue 14064 - JM - Check for blank GLTransAcct */
   	if @gltransacct is not null
   		begin
   		--select @gltransacct = rtrim(ltrim(@gltransacct))
   		if isnull(@gltransacct,'') = ''
   			begin
   			select @errtext = isnull(@errorstart,'') + 'GLTransAcct blank.'
   			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   			if @rcode <> 0
   				begin
   				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   				goto bspexit
   				end
   			end
   		/* Use CheckSubType 'E' for WOPartsPosting per DianaR */
   		-- TV 06/22/04 issue 24853 - Was passing Co instead of GLCO
   		exec @rcode = dbo.bspGLACfPostable @glco, @gltransacct, 'E', @errmsg output
   		if @rcode = 1
   			begin
   			select @errtext = isnull(@errorstart,'') + 'GLTransAcct ' + isnull(@gltransacct,'') + '-' + isnull(@errmsg,'')
   			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   			if @rcode <> 0
   				begin
   				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   				goto bspexit
   				end
   			end
   		end --if @gltransacct is not null
   	
   	/* Validate GLOffsetAcct */
   	/* If GLOffsetAcct not null, run basic validation. */
   	if @gloffsetacct is not null
   		begin
   		select @glsubtype = 'N'
   		exec @rcode = dbo.bspGLACfPostable  @glco, @gloffsetacct, @glsubtype, @errmsg output
   		if @rcode = 1
   			begin
   			select @errtext = isnull(@errorstart,'') + 'GLOffsetAcct ' + isnull(@gloffsetacct,'') + '-' + isnull(@errmsg,'')
   			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   			if @rcode <> 0
   				begin
   				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   				goto bspexit
   				end
   			end
   		end
   	
   	/* Verify that GLTrans and GLOffset accts arent the same. */
   	if @gltransacct=@gloffsetacct 
   		begin
   		select @errtext = isnull(@errorstart,'') + 'GLTransAcct and GLOffsetAcct cannot be the same!'
   		exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
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
   			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   			if @rcode <> 0
   				begin
   				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   				goto bspexit
   				end
   			end
   	
   	end --if @batchtranstype in ('A','C')
   
   ---------------BatchTransType = C & D
   
   if @batchtranstype in ('C','D')
   	begin
   
   	 /* Get existing values from EMCD. */
   	select @emcdactualdate = ActualDate, @emcdasset = Asset, @emcdcomponent = Component, @emcdcomponenttypecode = ComponentTypeCode, 
   		@emcdcostcode = CostCode, @emcddescription = [Description], @emcddollars = Dollars, @emcdemcosttype = EMCostType, 
   		@emcdemgroup = EMGroup, @emcdemtrans = EMTrans, @emcdemtranstype = EMTransType, @emcdequipment = Equipment, @emcdglco = GLCo,
   	 	@emcdgloffsetacct = GLOffsetAcct, @emcdgltransacct = GLTransAcct, @emcdinusebatchid = InUseBatchID, 
   	 	@emcdreversalstatus = ReversalStatus, @emcdsource = Source, @emcdunitprice = UnitPrice, @emcdunits = Units
   	from bEMCD where EMCo = @co and Mth = @mth and EMTrans = @emtrans
   	
   	if @@rowcount = 0
   		begin
   		select @errtext = isnull(@errorstart,'') + '-Missing EM Detail Transaction #:' + isnull(convert(char(3),@emtrans),'')
   		exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
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
   		exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   		if @rcode <> 0
   			begin
   			select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   			goto bspexit
   			end
   		end
   	
   	/* Make sure old values in batch match existing values in cost detail table. */
   	if @emcdactualdate <> @oldactualdate
   		or isnull(@emcdasset,'') <> isnull(@oldasset,'')
   		or isnull(@emcdcomponent,'') <> isnull(@oldcomponent,'')
   		or isnull(@emcdcomponenttypecode,'') <> isnull(@oldcomponenttypecode,'')
   		or @emcdcostcode <> @oldcostcode
   		or isnull(@emcddescription,'') <> isnull(@olddescription,'')
   		or @emcddollars <> @olddollars
   		or @emcdemcosttype <> @oldemcosttype
   		or @emcdemgroup <> @oldemgroup 
   		or @emcdemtrans <> @oldemtrans
   		or isnull(@emcdemtranstype,'') <> isnull(@oldemtranstype,'')
   		or @emcdequipment <> @oldequipment
   		or isnull(@emcdglco,0) <> isnull(@oldglco,0)
   		or isnull(@emcdgloffsetacct,'') <> isnull(@oldgloffsetacct,'')
   		or isnull(@emcdgltransacct,'') <> isnull(@oldgltransacct,'')
   		or isnull(@emcdreversalstatus,0) <> isnull(@oldreversalstatus,0)
   		or isnull(@emcdsource,'') <> isnull(@oldsource,'')
   		or @emcdunitprice <> @oldunitprice
   		or @emcdunits <> @oldunits
   		begin
   		select @errtext = isnull(@errorstart,'') + '-Batch Old info does not match EM Cost Detail.'
   		exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   		if @rcode <> 0
   			begin
   			select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   			goto bspexit
   			end
   		end
   
   	/* Validate OldEquipment - cannot be null. */
   	/* JM - 01/17/02 - Ref Issue 15162 - Allow Depn batches to post to inactive equipment. */
   	exec @rcode =dbo. bspEMEquipValInactiveOK @co, @oldequipment, @errmsg output
   	if @rcode = 1
   		begin
   		select @errtext = isnull(@errorstart,'') + 'OldEquipment ' + isnull(@oldequipment,'') + '-' + isnull(@errmsg,'')
   		exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   		if @rcode <> 0
   			begin
   			select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   			goto bspexit
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
   			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
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
   			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   			if @rcode <> 0
   				begin
   				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   				goto bspexit
   				end
   			end
   		end
   	
   	/* Validate OldAsset - can be null. */
   	if @oldasset is not null
   
   		begin
   		exec @rcode = dbo.bspEMAssetVal @co, @oldasset, @oldequipment, @errmsg output
   		if @rcode = 1
   		begin
   			select @errtext = isnull(@errorstart,'') + 'OldAsset ' + isnull(@oldasset,'') + '-' + isnull(@errmsg,'')
   			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
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
   			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
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
   		exec @rcode = dbo.bspEMCostCodeVal @oldemgroup, @oldcostcode, @errmsg output
   		if @rcode = 1
   			begin
   			select @errtext = isnull(@errorstart,'') + 'OldCostCode ' + isnull(@oldcostcode,'') + '-' + isnull(@errmsg,'')
   			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
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
   		select @ctchar = convert(varchar(3),@oldemcosttype)
   		exec @rcode = dbo.bspEMCostTypeValForCostCode @co, @oldemgroup, @ctchar, @oldcostcode, @oldequipment, 'N', null, null, @errmsg output
   		if @rcode = 1
   			begin
   			select @errtext = isnull(@errorstart,'') + 'OldEMCostType ' + isnull(convert(varchar(5),@oldemcosttype),'') + '-' + isnull(@errmsg,'')
   			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
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
   			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   			if @rcode <> 0
   				begin
   				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   				goto bspexit
   				end
   			end
   		end
   	
   	/* Validate OldGLTransAcct - can be null */
   	/* Ref Issue 14064 - JM - Check for blank GLTransAcct */
   	if @oldgltransacct is not null
   		begin
   		select @oldgltransacct = rtrim(ltrim(@oldgltransacct))
   		if @oldgltransacct = ''
   			begin
   			select @errtext = isnull(@errorstart,'') + 'OldGLTransAcct blank.'
   			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   			if @rcode <> 0
   				begin
   				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   				goto bspexit
   				end
   			end
   		/* Use CheckSubType 'E' for WOPartsPosting per DianaR */
   		-- TV 06/22/04 issue 24853 - Was passing Co instead of GLCO
   		exec @rcode = dbo.bspGLACfPostable @oldglco, @oldgltransacct, 'E', @errmsg output
   		if @rcode = 1
   			begin
   			select @errtext = isnull(@errorstart,'') + 'OldGLTransAcct ' + isnull(@oldgltransacct,'') + '-' + isnull(@errmsg,'')
   			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   			if @rcode <> 0
   				begin
   				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   				goto bspexit
   				end
   			end
   		end --if @gltransacct is not null
   	
   	/* Validate OldGLOffsetAcct */
   	/* If OldGLOffsetAcct not null, run basic validation. */
   	if @oldgloffsetacct is not null
   		begin
   		select @glsubtype = 'N'
   		exec @rcode = dbo.bspGLACfPostable  @oldglco, @oldgloffsetacct, @glsubtype, @errmsg output
   		if @rcode = 1
   			begin
   			select @errtext = isnull(@errorstart,'') + 'OldGLOffsetAcct ' + isnull(@oldgloffsetacct,'') + '-' + isnull(@errmsg,'')
   			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   			if @rcode <> 0
   				begin
   				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   				goto bspexit
   				end
   			end
   		end
   	
   	/* Verify that OldGLTrans and OldGLOffset accts arent the same. */
   	if @oldgltransacct = @oldgloffsetacct 
   		begin
   		select @errtext = isnull(@errorstart,'') + 'OldGLTransAcct and GLOffsetAcct cannot be the same!'
   		exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
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
   			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   			if @rcode <> 0
   				begin
   				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   				goto bspexit
   				end
   			end*/
   	
   	end --if @batchtranstype in ('C','D')
   
   bspexit:
   	if @rcode<>0 select @errmsg=isnull(@errmsg,'')	--+ char(13) + char(10) + '[bspEMVal_Cost_SeqVal_Depr]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMVal_Cost_SeqVal_Depr] TO [public]
GO
