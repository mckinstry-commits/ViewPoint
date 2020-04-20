SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE         procedure [dbo].[bspEMVal_Cost_SeqVal_Adj]
    /***********************************************************
     * CREATED BY: JM 7/9/02 - Ref Issue 17743 - Combination bspEMVal_Cost_AddedChanged and 
     *	bspEMVal_Cost_ChangedDeleted for each source, called from bspEMVal_Cost_Main
     *
     * MODIFIED By :  GG 09/20/02 - #18522 ANSI nulls
     *				  GF 09/26/2002 - 17967 no #ValRec and missing param for bspEMMatlValForCostAdj
     *				  GF 09/26/2002 - 18534 not reading old source for validation to EMCD.
     *				  JM 10-02-02 -  Ref Issue 18024 - For EMAdj Source, validate GLOffsetAcct SubType = null
     *				  JM 10-09-02 -  Remove 'rtrim(ltrim(' from GLTransAcct validation against blank (per DF)
     *				  JM 1-3-02 Ref Issue 19756 - Need to pass @inlocation and @oldinlocation to 
     *								bspEMGLOffsetAcctValForFuelPosting rather than null so correct GLCo is used
     *								for Offset Acct validation
     *				  GF 02/26/2003 - more changes for fuelcapum validation.
     *				  GF 03/06/2003 - issue #20175 - GLTransAcct not validated always, missed inactive.
     *				  GF 08/19/2003 - issue #22201 - GLOffset account may be null. Remmed out not null check
     *				  TV 02/11/04 - 23061 added isnulls
     *				  TV 03/07/05 26837 - Old GL Offset Acct cannot be null when deleting transaction
     *				  TV 03/18/05 27430 - GL Account Pulls wrong when info is changed
     *				  TV 07/12/2005 - issue 29254 - Allow Deptartment and Category to be Null.
	 *					TRL 01/15/08 - 121839 added Equipment Depts Depr Accum GLAcct
	 *				  DAN SO 05/28/08 - Issue: 128003 - added output param to bspEMMatlValForCostAdj call
	 *				  TRL 02/18/09 Issue 127133 added output paramter for bspEMMatlValForCostAdj
	 *					GP	03/12/09 - Issue 132617, missing fuel cap UM error was showing up when not appropriate.
     *					JVH 1/28/10	- Issue 137693 - Skip validation if fueltype is none
     *				TRL 02/04/2010 Issue 137916  change @description to 60 characters
     *				TRL 034/12/10 Issue 137092  Fixed Offset GL Accnt  sub ledger type validation
	 *				GF 01/14/2013 TK-20723 pass material, matl group to IN Location validation for category override GL Account
     *
	 *
     *	Called by bspEMVal_Cost_Main to run validation applicable only to referenced EMCost Source.
     *	
     *	Forms: EMCostAdj
     *	Posting table: bEMBF
     *	
     *	GLTransAcct must be subtype 'E'
     *	For EMTransType 
     *		'WO', 'Equip', 'Depn', 'Alloc' - GLJrnl = AdjstGLJrnl, GLLvl = AdjstGLLvl
     *		'Fuel', 'Parts' - GLJrnl = MatlGLJrnl, GLLvl = MatlGLLvl
     *	
     *	Visible bound inputs that use the same valproc here as in DDFI:
     *		WorkOrder 
     *		WOItem 
     *		Equipment 
     *		ComponentTypeCode 
     *		Component 
     *		CostCode 
     *		EMCostType 
     *		INLocation 
     *		Material 
     *		NOTE: If Fuel in EMBF matches Fuel in EMEM make sure UM in EMBF matches the FuelCapUM in EMEM or has a conversion.
     *		GLTransAcct 
     *		GLOffsetAcct 
     *		GLTransAcct cannot = GLOffsetAcct 
     *		TaxCode 
     *		NOTE: If Material is non-taxable, make sure TaxCode, TaxRate, TaxBasis and TaxAmount are null. Otherwise, get the 
     *		TaxRate and TaxBasis, calc the TaxAmount, and update bEMBF.
     *		UM
     *		INCo 
     *	
     *	Hidden bound inputs without valprocs in DDFI that receive basic validation here:
     *		Source = 'EMAdj'
     *		EMTransType = 'WO', 'Equip', 'Depn', 'Alloc', 'Fuel', 'Parts'
     *		GLCo 
     *		EMGroup 
     *		MatlGroup
     *		TaxGroup 
     *		Units must not be null
     *		UnitPrice must not be null
     * 		Dollars must not be null
     *		PerECM = ' E', 'C' or 'M'
     *		ReversalStatus = 0, 1, 2, 3, 4 and cannot be null; Cannot cancel Reversal unless it is original reversing entry
     *	
     *	Bound inputs that do not receive validation here:
     *		ActualDate
     *		EMTrans
     *		BatchTransType
     *		Description	
     *		SerialNo
     *		CurrentOdometer
     *		CurrentHourMeter
     *		CurrentTotalOdometer
     *		CurrentTotalHourMeter
     *		OldDollars
     *		TaxBasis
     *		TaxRate
     *		TaxAmount
     *		OrigEMTrans
     *
     *	Unbound columns in bEMBF that receive validation here:
     *		ReversalStatus - if null, converted to 0; must be 0, 1, 2, 3, 4
     *
     * USAGE:
     * 	Called by bspEMVal_Cost_Main to run validation applicable only to referenced EMCost Source.
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
    (@co bCompany, @mth bMonth, @batchid bBatchID, @batchseq int, @errmsg varchar(255) output)
    as
    set nocount on
    
    -- General decs
    declare @department bDept, @errorstart varchar(50), @errtext varchar(255),  @fuelcapum bUM, @fueltype char(1),
    		@fuelmatlcode bMatl, @gljrnl bJrnl, @gllvl tinyint, @glsubtype char(1), @rcode int 
    
    -- bEMBF non-Olds decs 
    declare @actualdate bDate, @batchtranstype char(1), @component bEquip, @componenttypecode varchar(10), @costcode bCostCode, @currenthourmeter bHrs, 
    		@currentodometer bHrs, @currenttotalhourmeter bHrs, @currenttotalodometer bHrs, @description bItemDesc/*137916*/, @dollars bDollar, @emcosttype bEMCType, 
    		@emgroup bGroup,@emtrans bTrans, @emtranstype varchar(10), @equipment bEquip,@glco bCompany,  @gloffsetacct bGLAcct, @gltransacct bGLAcct, 
    		@inco bCompany, @inlocation bLoc, @material bMatl, @matlgroup bGroup, @origemtrans bTrans, @perecm char(1), @reversalstatus tinyint, 
    		@serialno varchar(20), @source varchar(10), @taxamount bDollar, @taxbasis bDollar, @taxcode bTaxCode, @taxgroup bGroup, @taxrate bRate, 
    		@um bUM, @stdum bUM, @unitprice bUnitCost, @units bUnits, @woitem bItem, @workorder bWO
    
    -- bEMBF Olds decs
    declare @oldactualdate bDate, @oldbatchtranstype char(1), @oldcomponent bEquip, @oldcomponenttypecode varchar(10), @oldcostcode bCostCode, @oldcurrenthourmeter bHrs, 
    		@oldcurrentodometer bHrs, @oldcurrenttotalhourmeter bHrs, @oldcurrenttotalodometer bHrs, @olddescription bItemDesc/*137916*/, @olddollars bDollar, @oldemcosttype bEMCType, 
    		@oldemgroup bGroup,@oldemtrans bTrans, @oldemtranstype varchar(10), @oldequipment bEquip,@oldglco bCompany,  @oldgloffsetacct bGLAcct, @oldgltransacct bGLAcct, 
    		@oldinco bCompany, @oldinlocation bLoc, @oldmaterial bMatl, @oldmatlgroup bGroup, @oldorigemtrans bTrans, @oldperecm char(1), @oldreversalstatus tinyint, 
    		@oldserialno varchar(20), @oldsource varchar(10), @oldtaxamount bDollar, @oldtaxbasis bDollar, @oldtaxcode bTaxCode, @oldtaxgroup bGroup, @oldtaxrate bRate, 
    		@oldum bUM, @oldunitprice bUnitCost, @oldunits bUnits, @oldwoitem bItem, @oldworkorder bWO
    
    -- bEMCD decs
    declare @emcdactualdate bDate, @emcdalloccode tinyint, @emcdapco bCompany, @emcdapline int, @emcdapref bAPReference, @emcdaptrans bTrans, @emcdapvendor bVendor,
    		@emcdasset varchar(20), @emcdcomponent bEquip,  @emcdcomponenttypecode varchar(10),  @emcdcostcode bCostCode, @emcdcurrenthourmeter bHrs,
     		@emcdcurrentodometer bHrs, @emcdcurrenttotalhourmeter bHrs, @emcdcurrenttotalodometer bHrs, @emcddescription bItemDesc/*137916*/, @emcddollars bDollar,
    		@emcdemcosttype bEMCType, @emcdemgroup bGroup, @emcdemtrans bTrans, @emcdemtranstype varchar(10), @emcdequipment bEquip, @emcdglco bCompany, 
    		@emcdgloffsetacct bGLAcct, @emcdgltransacct bGLAcct, @emcdinco bCompany, @emcdinlocation bLoc,  @emcdinstkecm bECM, @emcdinstkum bUM, 
    		@emcdinstkunitcost bUnitCost, @emcdinusebatchid bBatchID, @emcdmaterial bMatl, @emcdmatlgroup bGroup, @emcdmetertrans bTrans, @emcdprco bCompany, 
    		@emcdperecm bECM, @emcdpremployee bEmployee, @emcdreversalstatus tinyint, @emcdserialno varchar(20), @emcdsource varchar(10), @emcdtaxamount bDollar, 
    		@emcdtaxbasis bDollar, @emcdtaxcode bTaxCode, @emcdtaxgroup bGroup, @emcdtaxrate bRate, @emcdtaxtype tinyint, @emcdtotalcost bDollar,@emcdum bUM, 
    		@emcdunitprice bUnitCost, @emcdunits bUnits, @emcdvendorgrp bGroup, @emcdwoitem bItem, @emcdworkorder bWO
    
    
    select @rcode = 0
    
    -- Verify parameters passed in.
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
    	@costcode = CostCode, @currenthourmeter = CurrentHourMeter, @currentodometer = CurrentOdometer, @currenttotalhourmeter = CurrentTotalHourMeter, 
    	@currenttotalodometer = CurrentTotalOdometer, @description = [Description], @dollars = Dollars, @emcosttype = EMCostType, @emgroup = EMGroup,
    	@emtrans = EMTrans, @emtranstype = EMTransType, @equipment = Equipment, @glco = GLCo, @gloffsetacct = GLOffsetAcct, @gltransacct = GLTransAcct, 
    	@inco = INCo, @inlocation = INLocation, @material = Material, @matlgroup = MatlGroup, @origemtrans = OrigEMTrans, @perecm = PerECM, 
    	@reversalstatus = ReversalStatus, @serialno = SerialNo, @source = rtrim(Source), @taxamount = TaxAmount, @taxbasis = TaxBasis, @taxcode = TaxCode, 
    	@taxgroup = TaxGroup,  @taxrate = TaxRate, @um = UM, @unitprice = UnitPrice,  @units = Units, @woitem = WOItem, @workorder = WorkOrder, 
    	@oldactualdate = OldActualDate, @oldbatchtranstype = OldBatchTransType, @oldcomponent = OldComponent, @oldcomponenttypecode = OldComponentTypeCode, 
    	@oldcostcode = OldCostCode, @oldcurrenthourmeter = OldCurrentHourMeter, @oldcurrentodometer = OldCurrentOdometer, 
    
    	@oldcurrenttotalhourmeter = OldCurrentTotalHourMeter, @oldcurrenttotalodometer = OldCurrentTotalOdometer, @olddescription = OldDescription, 
    	@olddollars = OldDollars, @oldemcosttype = OldEMCostType, @oldemgroup = OldEMGroup, @oldemtrans = OldEMTrans, @oldemtranstype = OldEMTransType, 
    	@oldequipment = OldEquipment, @oldglco = OldGLCo, @oldgloffsetacct = OldGLOffsetAcct, @oldgltransacct = OldGLTransAcct, @oldinco = OldINCo, 
    	@oldinlocation = OldINLocation, @oldmaterial = OldMaterial, @oldmatlgroup = OldMatlGroup, @oldorigemtrans = OldOrigEMTrans, @oldperecm = OldPerECM, 
    	@oldreversalstatus = OldReversalStatus, @oldserialno = OldSerialNo, @oldtaxamount = OldTaxAmount, @oldtaxbasis = OldTaxBasis, @oldtaxcode = OldTaxCode, 
    	@oldtaxgroup = OldTaxGroup, @oldtaxrate = OldTaxRate, @oldum = OldUM, @oldunitprice = OldUnitPrice,  @oldunits = OldUnits, @oldwoitem = OldWOItem, 
    	@oldworkorder = OldWorkOrder, @oldsource = rtrim(OldSource)
    from bEMBF where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
    
    /* Setup @errorstart string. */
    select @errorstart = 'Seq ' + isnull(convert(varchar(9),@batchseq),'') + '-'
    
    ---------------All BatchTransTypes
    /* Validate GLJrnl in bEMCO GLLvl <> NoUpdate - can be null in bEMCO but cannot be null in bGLDT.
    Need to do this validation record-by-record because EMAdj sources can have EMTransType = 'Fuel' which uses a
    different GL set than all other EMAdj EMTransTypes. */
    
    -- Ref Issue 18024 - For EMAdj Source, validate GLOffsetAcct SubType = null
    select @glsubtype = (select SubType From bGLAC where GLCo = @glco and GLAcct = @gloffsetacct)
    if /*(@emtranstype = 'Fuel' or @emtranstype = 'Parts') and*/ @inco is not null and @inlocation is not null--TV 03/18/05 27430 - GL Account Pulls wrong when info is changed
    	begin
    	if @glsubtype is not null and @glsubtype <> 'I' 
    		begin
    		select @errtext = 'GLOffsetAcct: ' + isnull(convert(varchar(20),@gloffsetacct),'') + ' has a Subledger Type: ' + isnull(@glsubtype,'') + '. Must be I or null for EMTransType = Fuel or Parts from Inventory'
    		exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    		if @rcode <> 0
    			begin
    			select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
    			goto bspexit
    			end
    		end
    	end
    
   --Issue 137092 
    if /*(@emtranstype = 'Fuel' or @emtranstype = 'Parts') and */@inco is null and isnull(@inlocation,'')='' --TV 03/18/05 27430 - GL Account Pulls wrong when info is changed
   	begin
    	if @glsubtype is not null  and @glsubtype <> 'E' 
    		begin
    		select @errtext = 'GLOffsetAcct: ' + isnull(convert(varchar(20),@gloffsetacct),'') + ' has a Subledger Type: ' + isnull(@glsubtype,'') + '. Must be null for EMTransType = Fuel or Parts not from Inventory'
    		exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    		if @rcode <> 0
    			begin
    			select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
    			goto bspexit
    			end
    		end
    	end
    --TV 03/18/05 27430 - GL Account Pulls wrong when info is changed
    /*if (@emtranstype <> 'Fuel' and @emtranstype <> 'Parts') and @glsubtype is not null	
    	begin
    	select @errtext = 'GLOffsetAcct: ' + isnull(convert(varchar(20),@gloffsetacct),'') + ' has a Subledger Type: ' + isnull(@glsubtype,'') + '. Must be null! for EMTransType other than Fuel or Parts'
    	exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    	if @rcode <> 0
    		begin
    		select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
    		goto bspexit
    		end
    	end*/
    
    -- Validate GLTransAcct SubType = 'E' or null
    select @glsubtype = (select SubType From bGLAC where GLCo = @glco and GLAcct = @gltransacct)
    if @glsubtype <> 'E' and @glsubtype is not null		-- #18522
    	begin
    	select @errtext = 'GLTransAcct: ' + isnull(convert(varchar(20),@gltransacct),'') + ' has a Subledger Type: ' + isnull(@glsubtype,'') + '. Must be E or null!'
    	exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    	if @rcode <> 0
    		begin
    		select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
    		goto bspexit
    		end
    	end
    
    -- Valide GLJrnl
    select @gljrnl = case @emtranstype
    		when 'WO' then AdjstGLJrnl
    		when 'Equip' then AdjstGLJrnl
    		when 'Depn' then AdjstGLJrnl
    		when 'Alloc' then AdjstGLJrnl
    		when 'Fuel' then MatlGLJrnl
    		when 'Parts' then MatlGLJrnl
    		end,
    	@glco = GLCo,
    	@gllvl  = case @emtranstype
    		when 'WO' then AdjstGLLvl
    		when 'Equip' then AdjstGLLvl
    		when 'Depn' then AdjstGLLvl
    		when 'Alloc' then AdjstGLLvl
    		when 'Fuel' then MatlGLLvl
    		when 'Parts' then MatlGLLvl
    		end
    from bEMCO where EMCo = @co
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
    			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    			if @rcode <> 0
    				begin
    				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
    				goto bspexit
    				end
    			end
    		end
    	end
    
    /* Validate Source - can be posting Adj, Alloc or Depr batch */
    if @source <> 'EMAdj' and @source <> 'EMAlloc' and @source <> 'EMDepr'
    	begin
    	select @errtext = isnull(@errorstart,'') + isnull(@source,'') + ' is an invalid Source.'
    	exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    	if @rcode <> 0
    		begin
    		select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
    		goto bspexit
    		end
    	end
    
    /* Validate EMTransType = */
    if @emtranstype not in ('WO', 'Equip', 'Depn', 'Fuel', 'Parts', 'Alloc')
    	begin
    	select @errtext = isnull(@errorstart,'') + isnull(@emtranstype,'') + ' is an invalid EMTransType.'
    	exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
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
    
    ---------------BatchTransType = A & C
    if @batchtranstype in ('A','C')
    	begin
    
    	/* Validate WorkOrder only if EMTransType = 'WO' - can be null. */
    	if @workorder is not null and @emtranstype = 'WO'
    		begin
    		exec @rcode = dbo.bspEMWOVal @co, @workorder, @errmsg output
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
    	
    	/* Validate WOItem only if EMTransType = 'WO' - can be null. */
    	if @woitem is not null and @emtranstype = 'WO'
    		begin
    		exec @rcode = dbo.bspEMWOItemValForCostAdj @co, @workorder, @woitem, null, null, null, null, null, null, null, null,
    			null,  null, null, null, null, null, null, null, null, null, null, null, null, null, null,  @errmsg output
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
    	/* JM 12-05-02 Ref Issue 19565 - Iimported depreciation records on inactive Equipment are failing batch validation due to import
    	process assigning Source = 'EMAdj' which uses this validation procedure and calls bspEMEquipValForCostAdj which doesn't allow
    	inactive Equipment. Thus, for any EMAdj source records with EMTransType = 'Depn', do all validation in bspEMEquipValForCostAdj except
    	for the check for Inactive. This basic validation will check for validity of the Equipment vs EMEM and make sure it isn't a Component. */
    	if @emtranstype = 'Depn'
    		begin
    		 /* Validate Equipment and read @shop and @type from bEMEM. */
    		declare @equiptype char(1)
    		 select @equiptype = Type from bEMEM where EMCo = @co and Equipment = @equipment
    		 if @@rowcount = 0
    		 	begin
    			select @errtext = isnull(@errorstart,'') + 'Equipment ' + isnull(@equipment,'') + ' invalid!', @rcode = 1
    			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    			if @rcode <> 0
    				begin
    				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
    				goto bspexit
    				end
    		 	end
    		 /* Reject if passed Equipments Type is C for Component. */
    		 if @equiptype = 'C'
    		 	begin
    			select @errtext = isnull(@errorstart,'') + 'Equipment ' + isnull(@equipment,'') + ' is a Component!', @rcode = 1
    			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    			if @rcode <> 0
    				begin
    				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
    				goto bspexit
    				end
    		 	end
    		end
    	else
    		exec @rcode = dbo.bspEMEquipValForCostAdj @co, @equipment, null, null, null, null, null, null, null, @errmsg output
    		if @rcode = 1
    			begin
    			select @errtext = isnull(@errorstart,'') + 'Equipment ' + isnull(@equipment,'') + '-' + isnull(@errmsg,'') + ' equipment validation'
    			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    			if @rcode <> 0
    				begin
    				select @errmsg =isnull(@errtext,'') + '-' + isnull(@errmsg,'')
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
    			select @errtext  = isnull(@errorstart,'') + 'ComponentTypeCode ' + isnull(@componenttypecode,'') + '-' + isnull(@errmsg,'')
    			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    			if @rcode <> 0
    				begin
    
    				select @errmsg =isnull(@errtext,'') + '-' + isnull(@errmsg,'')
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
    			select @errtext  = isnull(@errorstart,'') + 'Component ' + isnull(@component,'') + '-' + isnull(@errmsg,'')
    			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    			if @rcode <> 0
    				begin
    				select @errmsg =isnull(@errtext,'') + '-' + isnull(@errmsg,'')
    				goto bspexit
    
    				end
    			end
    
    		end
    	
    	/* Validate CostCode - can be null. */
    	if @costcode is not null
    		begin
    		exec @rcode = dbo.bspEMCostCodeValWithInfo @co, @emgroup, @costcode, @equipment, null, @errmsg output
    		if @rcode = 1
    			begin
    			select @errtext  = isnull(@errorstart,'') + 'CostCode ' + isnull(@costcode,'') + '-' + isnull(@errmsg,'')
    			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    			if @rcode <> 0
    				begin
    				select @errmsg =isnull(@errtext,'') + '-' + isnull(@errmsg,'')
    				goto bspexit
    				end
    			end
    		end
    	
    	/* Validate EMCostType - can be null. */
    	if @emcosttype is not null
    		begin
    		exec @rcode = dbo.bspEMCostTypeValForCostCode @co, @emgroup, @emcosttype, @costcode, @equipment, 'N', null, null, @errmsg output
    		if @rcode = 1
    
    			begin
    			select @errtext  = isnull(@errorstart,'') + 'EMCostType ' + isnull(convert(varchar(5),@emcosttype),'') + '-' + isnull(@errmsg,'')
    			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    			if @rcode <> 0
    
    				begin
    				select @errmsg =isnull(@errtext,'') + '-' + isnull(@errmsg,'')
    				goto bspexit
    				end
    			end
    		end
    
    	/* Validate INCo - can be null. */
    	if @inco is not null
    		begin
    		exec @rcode = dbo.bspINCompanyValForFuelPosting @inco, null, null, null, null, @errmsg output
    		if @rcode = 1
    			begin
    			select @errtext  = isnull(@errorstart,'') + 'INCo ' + isnull(convert(varchar(3),@inco),'') + '-' + isnull(@errmsg,'')
    			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    			if @rcode <> 0
    				begin
    				select @errmsg =isnull(@errtext,'') + '-' + isnull(@errmsg,'')
    				goto bspexit
    				end
    			end
    		end
    	
    	-- Validate INLocation - can be null.
    	if @inlocation is not null
    		BEGIN
			----TK-20723          
    		exec @rcode = dbo.bspINLocValForFuelPosting @inco, @inlocation, @material, null, @matlgroup, @co, @equipment, null, null, null, null, null, @errmsg output
    		if @rcode = 1
    			begin
    			select @errtext  = isnull(@errorstart,'') + 'INLocation ' + isnull(@inlocation,'') + '-' + isnull(@errmsg,'')
    			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    			if @rcode <> 0
    				begin
    				select @errmsg =isnull(@errtext,'') + '-' + isnull(@errmsg,'')
    				goto bspexit
    				end
    			end
    		end
    
    
    	-- Validate Material - can be null.
    	--if isnull(@material,'') is null goto Validate_EMGroup -TV 03/06/03 this is always false
        if isnull(@material,'') = '' goto Validate_EMGroup
    
    	select @stdum = null
    	exec @rcode = dbo.bspEMMatlValForCostAdj @co, @equipment, @matlgroup, @material, 'LS', @inco, @inlocation, 
					--Issue 127133
    				@stdum output, null, null, null, null, null, null, null, null,null, @errmsg output
    	if @rcode <> 0 
    		begin
    		select @errtext  = isnull(@errorstart,'') + 'Material ' + isnull(@material,'') + '-' + isnull(@errmsg,'')
    		exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    		if @rcode <> 0
    			begin
    			select @errmsg =isnull(@errtext,'') + '-' + isnull(@errmsg,'')
    			goto bspexit
    			end
    		goto Validate_EMGroup
    		end
    
        -- If Fuel in EMBF matches Fuel in EMEM (per RH 8/7/01), make sure UM in EMBF matches the 
        -- FuelCapUM in EMEM or has a conversion.
        select @fuelmatlcode = FuelMatlCode, @fuelcapum = FuelCapUM, @fueltype = FuelType
      	from EMEM with (nolock) where EMCo = @co and Equipment = @equipment

		--132617 + 137693
		if @fueltype = 'N' or @fuelmatlcode is null goto Validate_EMGroup
    	-- skip if @fuelmatlcode <> @material code
    	if isnull(@fuelmatlcode,'') <> isnull(@material,'') goto Validate_EMGroup
    
    	-- @fuelcapum must exist
     	if isnull(@fuelcapum,'') = ''
     		begin
    	 	select @errtext  = isnull(@errorstart,'') + 'Missing Fuel Cap U/M from Equipment Master EMEM.'
    	 	exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    	 	if @rcode <> 0
    	 	   	begin
    	 	   	select @errmsg =isnull(@errtext,'') + '-' + isnull(@errmsg,'')
    	 	   	goto bspexit
    	 	   	end
    		goto Validate_EMGroup
     	   	end
    
    	-- if @fuelcapum = @um then done
    	if @fuelcapum = @um goto Validate_EMGroup
    
    	-- when @um <> @stdum then verify that @um conversion exists in HQMU for material
    	if @stdum <> @um
    		begin
    		if not exists(select top 1 1 from bHQMU with (nolock) where MatlGroup=@matlgroup and Material=@material and UM=@um)
    			begin
     	   		select @errtext  = isnull(@errorstart,'') + 'Unit of Measure does not have a conversion to U/M listed for this fuel in EMEM.'
     	   		exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
     	   		if @rcode <> 0
     	   			begin
     	   			select @errmsg =isnull(@errtext,'') + '-' + isnull(@errmsg,'')
     	   			goto bspexit
     	   			end
     	   		end
     	   	end
    
    	Validate_EMGroup:
    	-- Validate EMGroup - can be null.
    	if @emgroup is not null
    		begin
    		exec @rcode = dbo.bspHQGroupVal @emgroup, @errmsg output
    		if @rcode = 1
    			begin
    			select @errtext  = isnull(@errorstart,'') + 'EMGroup ' + isnull(convert(varchar(5),@emgroup),'') + '-' + isnull(@errmsg,'')
    			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    			if @rcode <> 0
    				begin
    				select @errmsg =isnull(@errtext,'') + '-' + isnull(@errmsg,'')
    				goto bspexit
    				end
    			end
    		end
    	
    	/* Validate MatlGroup - can be null. */
    	if @matlgroup is not null
    		begin
    		exec @rcode = dbo.bspHQGroupVal @matlgroup, @errmsg output
    		if @rcode = 1
    			begin
    			select @errtext  = isnull(@errorstart,'') + 'MatlGroup ' + isnull(convert(varchar(5),@matlgroup),'') + '-' + isnull(@errmsg,'')
    			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    			if @rcode <> 0
    				begin
    				select @errmsg =isnull(@errtext,'') + '-' + isnull(@errmsg,'')
    				goto bspexit
    				end
    			end
    		end
    	
    	/* Validate TaxGroup - can be null. */
    	if @taxgroup is not null
    		begin
    		exec @rcode = dbo.bspHQGroupVal @taxgroup, @errmsg output
    		if @rcode = 1         
    			begin
    			select @errtext  = isnull(@errorstart,'') + 'TaxGroup ' + isnull(convert(varchar(5),@taxgroup),'') + '-' + isnull(@errmsg,'')
    			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    			if @rcode <> 0
    				begin
    				select @errmsg =isnull(@errtext,'') + '-' + isnull(@errmsg,'')
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
    			select @errtext  = isnull(@errorstart,'') + 'GLCo ' + isnull(convert(varchar(5),@glco),'') + '-' + isnull(@errmsg,'')
    			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    			if @rcode <> 0
    				begin
    				select @errmsg =isnull(@errtext,'') + '-' + isnull(@errmsg,'')
    				goto bspexit
    				end
    			end
    		end
    
    	/* Validate PerECM - can be null. */
    	if @perecm is not null and @perecm not in ('E','C','M')
    		begin
    		select @errtext  = isnull(@errorstart,'') + 'Invalid PerECM, must be E,C, or M.'
    		exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    		if @rcode <> 0
    			begin
    			select @errmsg =isnull(@errtext,'') + '-' + isnull(@errmsg,'')
    			goto bspexit
    			end
    		end
    
    	/* Validate UM - can be null. */
    	if @um is not null
    		begin
    		exec @rcode = dbo.bspHQUMValWithInfoForEM @co, @emtranstype, @um, @matlgroup, @material, @inco, @inlocation, null, @errmsg output
    		if @rcode = 1
    			begin
    			select @errtext  = isnull(@errorstart,'') + 'UM ' + isnull(@um,'') + '-' + isnull(@errmsg,'')
    			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    			if @rcode <> 0
    				begin
    				select @errmsg =isnull(@errtext,'') + '-' + isnull(@errmsg,'')
    				goto bspexit
    				end
    			end
    		end
    	
    	/* Validate ReversalStatus - can be null - Must be 0, 1, 2, 3, 4; cannot cancel unless original reversing entry. */
    	/* Convert null ReversalStatus to 0. */
    	if @reversalstatus is null
    		update bEMBF set ReversalStatus = 0 where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
    	else
    		begin
    		if @reversalstatus not in (0,1,2,3,4)
    			begin
    			select @errtext  = isnull(@errorstart,'') + 'ReversalStatus ' + isnull(convert(char(2),@reversalstatus),'') + ' invalid. Must be 0, 1, 2, 3, or 4.'
    			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    			if @rcode <> 0
    				begin
    				select @errmsg =isnull(@errtext,'') + '-' + isnull(@errmsg,'')
    				goto bspexit
    				end
    			end
    
    		if @reversalstatus=4 and @batchtranstype = 'C'
    			begin
    			select @errtext  = isnull(@errorstart,'') + 'Cannot cancel Reversal unless it is original reversing entry.'
    			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    			if @rcode <> 0
    				begin
    				select @errmsg =isnull(@errtext,'') + '-' + isnull(@errmsg,'')
    				goto bspexit
    				end
    			end
    		end
    	
    	-- Validate TaxCode - can be null. Also pull TaxRate, calculate TaxAmount	assuming TaxBasis = bEMBF.TotalCost, and update bEMBF.
    	if @taxcode is null or @emtranstype = 'Fuel' or (select Taxable from bHQMT where MatlGroup = @matlgroup and Material = @material) = 'N'
    		begin
    		select @taxcode = null, @taxrate = null, @taxbasis = null, @taxamount = null
    		-- Update bEMBF.
    		update bEMBF set TaxRate = @taxrate, TaxBasis = @taxbasis, TaxAmount = @taxamount 
    		where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
    		end
    	else
    		begin
    		exec @rcode = dbo.bspHQTaxRateGet @taxgroup, @taxcode, @actualdate, null, null, null, @errmsg output
    		if @rcode = 1
    			begin
    			select @errtext  = isnull(@errorstart,'') + 'TaxCode ' + isnull(@taxcode,'') + '-' + isnull(@errmsg,'')
    			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    			if @rcode <> 0
    				begin
    				select @errmsg =isnull(@errtext,'') + '-' + isnull(@errmsg,'')
    				goto bspexit
    				end
    			end
    	
    		/* If Material is non-taxable or EMTransType = 'Fuel', set @taxcode, @taxrate, @taxbasis and @taxamount to null. */
    		--select @taxbasis = Dollars from #ValRec -- remmed out no #ValRec
    		select @taxamount = @taxrate * @taxbasis
    	
    		/* Update bEMBF. */
    		update bEMBF set TaxRate = @taxrate, TaxBasis = @taxbasis, TaxAmount = @taxamount
    		where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
    		
    		end --else for if @taxcode is null or @emtranstype = 'Fuel' or (select Taxable from bHQMT where MatlGroup = @matlgroup and Material = @material) = 'N'
    
    	/* JM 12-23-02 - Ref Issue 17856 Rej 1 - Used validation from bspEMVal_Cost_SeqVal_Fuel */ 
     	/* Validate GLTransAcct - can be null except when Source = 'EMFuel' In that case, log error to HQBE and assume that user will setup cost code or cost type properly
     	for the Equipment's dept after the batch is rejected, and then run the validation again where we will add the GLTransAcct for them from bEMDO or bEMDG. */
     	if @gltransacct is null 
     		begin
     		-- Get Department for @equipment from bEMEM.
     		select @department = Department from bEMEM with (nolock) where EMCo = @co and Equipment = @equipment
     		-- If GLAcct exists in bEMDO, use it.
     		select @gltransacct = GLAcct from bEMDO with (nolock)
    		where EMCo = @co and isnull(Department,'') = isnull(@department,'') and EMGroup = @emgroup and CostCode = @costcode
     		-- If GLAcct not in bEMDO, get the GLAcct in bEMDG.
     		if @gltransacct is null
    			begin
     			select @gltransacct = GLAcct from bEMDG with (nolock)
    			where EMCo = @co and isnull(Department,'') = isnull(@department,'') and EMGroup = @emgroup and CostType = @emcosttype
    			end
    		-- update EMBF with GLTransAcct if found
    		if isnull(@gltransacct,'') <> ''
    			begin
    			update bEMBF set GLTransAcct = @gltransacct where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@batchseq
    			end
    		end
    
     	-- Validate GLTransAcct if not null
     	if isnull(@gltransacct,'') <> ''
     		begin
     		exec @rcode = dbo.bspEMGLTransAcctVal @glco, @gltransacct, 'E', @errmsg output
     		if @rcode = 1
     			begin
     			select @errtext  = isnull(@errorstart,'') + 'GLTransAcct ' + isnull(@gltransacct,'') + '-' + isnull(@errmsg,'')
     			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
     			if @rcode <> 0
     				begin
     				select @errmsg =isnull(@errtext,'') + '-' + isnull(@errmsg,'')
     				goto bspexit
     				end
     			end
     		end
    	else
    		begin
    		-- ref Issue 14064 - JM - Check for blank GLTransAcct
    		select @errtext  = isnull(@errorstart,'') + 'Missing GLTransAcct.'
    		exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    		if @rcode <> 0
    			begin
    			select @errmsg =isnull(@errtext,'') + '-' + isnull(@errmsg,'')
    			goto bspexit
    			end
    		end
    	
    	/* Validate GLOffsetAcct - GLOffsetAcct cannot be null */
    	/* if @gloffsetacct is null
    		begin
    		select @errtext  = isnull(@errorstart,'') + 'GLOffsetAcct cannot be null.'
    		exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    		if @rcode <> 0
    			begin
    			select @errmsg =isnull(@errtext,'') + '-' + isnull(@errmsg,'')
    			goto bspexit
    			end
    		end
    	else */
    	if @gloffsetacct is not null
    		begin
    		-- GLOffsetAcct not null so run basic validation. 
    		-- JM 1-3-02 Ref Issue 19756 - Need to pass @inlocation rather than null so correct GLCo is used for Offset Acct validation
    		-- (also applies to call in Change type transaction below.)
    		exec @rcode = dbo.bspEMGLOffsetAcctValForFuelPosting  @co, @inco, @gloffsetacct, @inlocation, @errmsg output
    		if @rcode = 1
    			begin
    			select @errtext  = isnull(@errorstart,'') + 'GLOffsetAcct ' + isnull(@gloffsetacct,'') + '-' + isnull(@errmsg,'')
    			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    			if @rcode <> 0
    				begin
    				select @errmsg =isnull(@errtext,'') + '-' + isnull(@errmsg,'')
    				goto bspexit
    				end
    
    			end
    		end
    	
    	/* Verify that GLTrans and GLOffset accts arent the same. */
    	if @gltransacct=@gloffsetacct
    		begin
    		select @errtext  = isnull(@errorstart,'') + 'GLTransAcct and GLOffsetAcct cannot be the same!'
    		exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    		if @rcode <> 0
    			begin
    			select @errmsg =isnull(@errtext,'') + '-' + isnull(@errmsg,'')
    			goto bspexit
    			end
    		end
    
    	end --if @batchtranstype in ('A','C')
    
    
    ---------------BatchTransType = C & D
    
    if @batchtranstype in ('C','D')
    	begin
    
    	 /* Get existing values from EMCD. */
    	select @emcdactualdate = ActualDate, @emcdcomponent = Component, @emcdcomponenttypecode = ComponentTypeCode, @emcdcostcode = CostCode,
    	 	@emcddescription = [Description], @emcddollars = Dollars, @emcdemcosttype = EMCostType, @emcdcurrenthourmeter = CurrentHourMeter,
    		@emcdcurrentodometer = CurrentOdometer, @emcdcurrenttotalhourmeter = CurrentTotalHourMeter, @emcdcurrenttotalodometer = CurrentTotalOdometer,
    	 	@emcdemgroup = EMGroup, @emcdemtrans = EMTrans, @emcdemtranstype = EMTransType, @emcdequipment = Equipment, @emcdglco = GLCo,
    	 	@emcdgloffsetacct = GLOffsetAcct, @emcdgltransacct = GLTransAcct, @emcdinco = INCo, @emcdinlocation = INLocation, @emcdmaterial = Material, 
    		@emcdinusebatchid = InUseBatchID, @emcdmatlgroup = MatlGroup, @emcdperecm = PerECM, @emcdreversalstatus = ReversalStatus,
    	 	@emcdserialno = SerialNo, @emcdsource = Source, @emcdtaxcode = TaxCode, @emcdtaxamount = TaxAmount, @emcdtaxbasis = TaxBasis,
    		@emcdtaxgroup = TaxGroup, @emcdtaxrate = TaxRate, @emcdum = UM, @emcdunitprice = UnitPrice,
    	 	@emcdunits = Units, @emcdwoitem = WOItem, @emcdworkorder = WorkOrder
    	from bEMCD where EMCo = @co and Mth = @mth and EMTrans = @emtrans
    	
    	if @@rowcount = 0
    		begin
    		select @errtext  = isnull(@errorstart,'') + '-Missing EM Detail Transaction #:' + isnull(convert(char(3),@emtrans),'')
    		exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    		if @rcode <> 0
    			begin
    			select @errmsg =isnull(@errtext,'') + '-' + isnull(@errmsg,'')
    			goto bspexit
    			end
    		end
    	
    	/* Verify EMCD record assigned to same BatchId. */
    	if @emcdinusebatchid <> @batchid
    		begin
    		select @errtext  = isnull(@errorstart,'') + '-Detail Transaction has not been assigned to this BatchId.'
    		exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    		if @rcode <> 0
    			begin
    			select @errmsg =isnull(@errtext,'') + '-' + isnull(@errmsg,'')
    			goto bspexit
    			end
    		end
    	
    	/* Make sure old values in batch match existing values in cost detail table. */
    	if @emcdactualdate <> @oldactualdate
    		or isnull(@emcdcomponent,'') <> isnull(@oldcomponent,'')
    		or isnull(@emcdcomponenttypecode,'') <> isnull(@oldcomponenttypecode,'')
    		or @emcdcostcode <> @oldcostcode
    		or @emcdcurrenthourmeter <> @oldcurrenthourmeter
    		or @emcdcurrentodometer <> @oldcurrentodometer
    		or @emcdcurrenttotalhourmeter <> @oldcurrenttotalhourmeter
    		or @emcdcurrenttotalodometer <> @oldcurrenttotalodometer
    		or isnull(@emcddescription,'') <> isnull(@olddescription,'')
    		or @emcddollars - @emcdtaxamount <> @olddollars
    		or @emcdemcosttype <> @oldemcosttype
    		or @emcdemgroup <> @oldemgroup 
    		or @emcdemtrans <> @oldemtrans
    		or isnull(@emcdemtranstype,'') <> isnull(@oldemtranstype,'')
    		or @emcdequipment <> @oldequipment
    		or isnull(@emcdglco,0) <> isnull(@oldglco,0)
    		or isnull(@emcdgloffsetacct,'') <> isnull(@oldgloffsetacct,'')
    		or isnull(@emcdgltransacct,'') <> isnull(@oldgltransacct,'')
    		or isnull(@emcdinco,0) <> isnull(@oldinco,0)
    		or isnull(@emcdinlocation,'') <> isnull(@oldinlocation,'')
    		or isnull(@emcdmaterial,'') <> isnull(@oldmaterial,'')
    		or isnull(@emcdmatlgroup,0) <> isnull(@oldmatlgroup,0)
    		or isnull(@emcdperecm,'') <> isnull(@oldperecm,'')
    		or isnull(@emcdreversalstatus,0) <> isnull(@oldreversalstatus,0)
    		or isnull(@emcdserialno,'') <> isnull(@oldserialno,'')
    		or isnull(@emcdsource,'') <> isnull(@oldsource,'')
    		or isnull(@emcdtaxamount,0) <> isnull(@oldtaxamount,0)
    		or isnull(@emcdtaxbasis,0) <> isnull(@oldtaxbasis,0)
    		or isnull(@emcdtaxcode,'') <> isnull(@oldtaxcode,'')
    		or isnull(@emcdtaxgroup,0) <> isnull(@oldtaxgroup,0)
    		or isnull(@emcdtaxrate,0) <> isnull(@oldtaxrate,0)
    		or isnull(@emcdum,'') <> isnull(@oldum,'')
    		or @emcdunitprice <> @oldunitprice
    		or @emcdunits <> @oldunits
    		or isnull(@emcdwoitem,0) <> isnull(@oldwoitem,0)
    		or isnull(@emcdworkorder,'') <> isnull(@oldworkorder,'')
    		begin
    		select @errtext  = isnull(@errorstart,'') + '-Batch Old info does not match EM Cost Detail.'
    		exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    		if @rcode <> 0
    			begin
    			select @errmsg =isnull(@errtext,'') + '-' + isnull(@errmsg,'')
    			goto bspexit
    			end
    		end
    
    
    	/* Validate WorkOrder only if EMTransType = 'WO' - can be null. */
    
    	if @oldworkorder is not null and @oldemtranstype = 'WO'
    		begin
    		exec @rcode = bspEMWOVal @co, @oldworkorder, @errmsg output
    		if @rcode = 1
    			begin
    			select @errtext  = isnull(@errorstart,'') + 'WorkOrder ' + isnull(@oldworkorder,'') + '-' + isnull(@errmsg,'')
    			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    			if @rcode <> 0
    				begin
    				select @errmsg =isnull(@errtext,'') + '-' + isnull(@errmsg,'')
    				goto bspexit
    				end
    			end
    		end
    	
    	/* Validate OldWOItem only if OldEMTransType = 'WO' - can be null. */
    	if @oldwoitem is not null and @oldemtranstype = 'WO'
    		begin
    		exec @rcode = dbo.bspEMWOItemValForCostAdj @co, @oldworkorder, @oldwoitem, null, null, null, null, null, null, null, null,
    			null,  null, null, null, null, null, null, null, null, null, null, null, null, null, null, @errmsg output
    		if @rcode = 1
    			begin
    			select @errtext  = isnull(@errorstart,'') + 'OldWOItem ' + isnull(convert(varchar(5),@oldwoitem),'') + '-' + isnull(@errmsg,'')
    			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    			if @rcode <> 0
    				begin
    				select @errmsg =isnull(@errtext,'') + '-' + isnull(@errmsg,'')
    				goto bspexit
    				end
    			end
    		end
    	
    	/* Validate OldEquipment - cannot be null. */
    	exec @rcode = dbo.bspEMEquipValForCostAdj @co, @oldequipment, null, null, null, null, null, null, null, @errmsg output
    	if @rcode = 1
    		begin
    		select @errtext  = isnull(@errorstart,'') + 'OldEquipment ' + isnull(@oldequipment,'') + '-' + isnull(@errmsg,'')
    		exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    		if @rcode <> 0
    			begin
    			select @errmsg =isnull(@errtext,'') + '-' + isnull(@errmsg,'')
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
    			select @errtext  = isnull(@errorstart,'') + 'OldComponentTypeCode ' + isnull(@oldcomponenttypecode,'') + '-' + isnull(@errmsg,'')
    			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    			if @rcode <> 0
    				begin
    				select @errmsg =isnull(@errtext,'') + '-' + isnull(@errmsg,'')
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
    			select @errtext  = isnull(@errorstart,'') + 'OldComponent ' + isnull(@oldcomponent,'') + '-' + isnull(@errmsg,'')
    			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    			if @rcode <> 0
    				begin
    				select @errmsg =isnull(@errtext,'') + '-' + isnull(@errmsg,'')
    				goto bspexit
    				end
    			end
    		end
    	
    	/* Validate OldCostCode - can be null. */
    	if @oldcostcode is not null
    		begin
    		exec @rcode = dbo.bspEMCostCodeValWithInfo @co, @oldemgroup, @oldcostcode, @oldequipment, null, @errmsg output
    		if @rcode = 1
    			begin
    			select @errtext  = isnull(@errorstart,'') + 'OldCostCode ' + isnull(@oldcostcode,'') + '-' + isnull(@errmsg,'')
    			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    			if @rcode <> 0
    				begin
    				select @errmsg =isnull(@errtext,'') + '-' + isnull(@errmsg,'')
    				goto bspexit
    				end
   
    			end
    		end
    	
    	/* Validate OldEMCostType - can be null. */
    	if @oldemcosttype is not null
    		begin
    		exec @rcode = dbo.bspEMCostTypeValForCostCode @co, @oldemgroup, @oldemcosttype, @oldcostcode, @oldequipment, 'N', null, 
    			null, @errmsg output
    		if @rcode = 1
    			begin
    			select @errtext  = isnull(@errorstart,'') + 'OldEMCostType ' + isnull(convert(varchar(5),@oldemcosttype),'') + '-' + isnull(@errmsg,'')
    
    			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    			if @rcode <> 0
    				begin
    				select @errmsg =isnull(@errtext,'') + '-' + isnull(@errmsg,'')
    				goto bspexit
    				end
    			end
    		end
    
    	/* Validate OldINCo - can be null. */
    	if @oldinco is not null
    		begin
    		exec @rcode = dbo.bspINCompanyValForFuelPosting @oldinco, null, null, null, null, @errmsg output
    		if @rcode = 1
    			begin
    			select @errtext  = isnull(@errorstart,'') + 'OldINCo ' + isnull(convert(varchar(3),@oldinco),'') + '-' + isnull(@errmsg,'')
    			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    			if @rcode <> 0
    				begin
    				select @errmsg =isnull(@errtext,'') + '-' + isnull(@errmsg,'')
    				goto bspexit
    				end
    			end
    		end
    	
    	-- Validate OldINLocation - can be null.
    	if @oldinlocation is not null
    		BEGIN
			----TK-20723          
    		exec @rcode = dbo.bspINLocValForFuelPosting @oldinco, @oldinlocation, @oldmaterial, null, @oldmatlgroup, @co, @oldequipment, null, 
    			null, null, null, null, @errmsg output
    		if @rcode = 1
    			begin
    
    			select @errtext  = isnull(@errorstart,'') + 'OldINLocation ' + isnull(@oldinlocation,'') + '-' + isnull(@errmsg,'')
    			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    			if @rcode <> 0
    				begin
    				select @errmsg =isnull(@errtext,'') + '-' + isnull(@errmsg,'')
    				goto bspexit
    				end
    			end
    		end
    
    	-- Validate OldMaterial - can be null.
        if isnull(@oldmaterial,'') = '' goto Validate_OldEMGroup
        
    	select @stdum = null
    	exec @rcode = dbo.bspEMMatlValForCostAdj @co, @oldequipment, @oldmatlgroup, @oldmaterial, 'LS', @oldinco, @oldinlocation, 
				--Issue 127133
    			@stdum output, null, null, null, null, null, null, null, null,null, @errmsg output
    	if @rcode <> 0
    		begin
    		select @errtext  = isnull(@errorstart,'') + 'OldMaterial ' + isnull(@material,'') + '-' + isnull(@errmsg,'')
    		exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    		if @rcode <> 0
    			begin
    			select @errmsg =isnull(@errtext,'') + '-' + isnull(@errmsg,'')
    			goto bspexit
    			end
    		goto Validate_OldEMGroup
    		end
    	-- If Fuel in EMBF matches Fuel in EMEM (per RH 8/7/01), make sure UM in EMBF matches the FuelCapUM in EMEM or has a conversion.
    	select @fuelmatlcode = FuelMatlCode, @fuelcapum = FuelCapUM, @fueltype = FuelType
    	from EMEM with (nolock) where EMCo = @co and Equipment = @oldequipment
    	
    	--132617 + 137693
		if @fueltype = 'N' or @fuelmatlcode is null goto Validate_OldEMGroup
    	-- skip if @fuelmatlcode <> @material code
    	if isnull(@fuelmatlcode,'') <> isnull(@oldmaterial,'') goto Validate_OldEMGroup
    
    	-- @fuelcapum must exist
     	if isnull(@fuelcapum,'') = ''
     		begin
    	 	select @errtext  = isnull(@errorstart,'') + 'Missing Fuel Cap U/M from Equipment Master EMEM.'
    	 	exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    	 	if @rcode <> 0
    	 	   	begin
    	 	   	select @errmsg =isnull(@errtext,'') + '-' + isnull(@errmsg,'')
    	 	   	goto bspexit
    	 	   	end
    		goto Validate_OldEMGroup
     	   	end
   
    	-- if @fuelcapum = @um then done
    	if @fuelcapum = @oldum goto Validate_OldEMGroup
    
    	-- when @um <> @stdum then verify that @um conversion exists in HQMU for material
    	if @stdum <> @oldum
    		begin
    		if not exists(select * from bHQMU with (nolock) where MatlGroup=@oldmatlgroup and Material=@oldmaterial and UM=@oldum)
    			begin
     	   		select @errtext  = isnull(@errorstart,'') + 'Unit of Measure does not have a conversion to U/M listed for this fuel in EMEM.'
     	   		exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
     	   		if @rcode <> 0
     	   			begin
     	   			select @errmsg =isnull(@errtext,'') + '-' + isnull(@errmsg,'')
     	   			goto bspexit
     	   			end
     	   		end
   
     	   	end
    
    	Validate_OldEMGroup:
    	-- Validate OldEMGroup - can be null.
    	if @oldemgroup is not null
    		begin
    		exec @rcode = dbo.bspHQGroupVal @oldemgroup, @errmsg output
    		if @rcode = 1
    			begin
    			select @errtext  = isnull(@errorstart,'') + 'OldEMGroup ' + isnull(convert(varchar(5),@oldemgroup),'') + '-' + isnull(@errmsg,'')
    			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    			if @rcode <> 0
    				begin
    				select @errmsg =isnull(@errtext,'') + '-' + isnull(@errmsg,'')
    				goto bspexit
    				end
    			end
    		end
    	
    	/* Validate OldMatlGroup - can be null. */
    	if @oldmatlgroup is not null
    		begin
    		exec @rcode = dbo.bspHQGroupVal @oldmatlgroup, @errmsg output
    		if @rcode = 1
    			begin
    			select @errtext  = isnull(@errorstart,'') + 'OldMatlGroup ' + isnull(convert(varchar(5),@oldmatlgroup),'') + '-' + isnull(@errmsg,'')
    			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    			if @rcode <> 0
    				begin
    				select @errmsg =isnull(@errtext,'') + '-' + isnull(@errmsg,'')
    				goto bspexit
    				end
    			end
    		end
    	
    	/* Validate OldTaxGroup - can be null. */
    	if @oldtaxgroup is not null
    		begin
    		exec @rcode = dbo.bspHQGroupVal @oldtaxgroup, @errmsg output
    		if @rcode = 1         
    			begin
    			select @errtext  = isnull(@errorstart,'') + 'OldTaxGroup ' + isnull(convert(varchar(5),@oldtaxgroup),'') + '-' + isnull(@errmsg,'')
    			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    			if @rcode <> 0
    				begin
    				select @errmsg =isnull(@errtext,'') + '-' + isnull(@errmsg,'')
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
    			select @errtext  = isnull(@errorstart,'') + 'OldGLCo ' + isnull(convert(varchar(5),@oldglco),'') + '-' + isnull(@errmsg,'')
    			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    			if @rcode <> 0
    				begin
    				select @errmsg =isnull(@errtext,'') + '-' + isnull(@errmsg,'')
    				goto bspexit
    				end
    			end
    		end
    
    	/* Validate OldPerECM - can be null. */
    	if @oldperecm is not null and @oldperecm not in ('E','C','M')
    		begin
    		select @errtext  = isnull(@errorstart,'') + 'Invalid OldPerECM, must be E,C, or M.'
    		exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    
    		if @rcode <> 0
    			begin
    			select @errmsg =isnull(@errtext,'') + '-' + isnull(@errmsg,'')
    			goto bspexit
    			end
    		end
    
    	/* Validate OldUM - can be null. */
    	if @oldum is not null
    		begin
    		exec @rcode = dbo.bspHQUMValWithInfoForEM @co, @oldemtranstype, @oldum, @oldmatlgroup, @oldmaterial, @oldinco, @oldinlocation, null, @errmsg output
    		if @rcode = 1
    			begin
    			select @errtext  = isnull(@errorstart,'') + 'OldUM ' + isnull(@oldum,'') + '-' + isnull(@errmsg,'')
    			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    			if @rcode <> 0
    				begin
    				select @errmsg =isnull(@errtext,'') + '-' + isnull(@errmsg,'')
    				goto bspexit
    				end
    			end
    		end
    	
    
    	/* Validate OldReversalStatus - can be null - Must be 0, 1, 2, 3, 4; cannot cancel unless original reversing entry. */
    	/* Convert null OldReversalStatus to 0. */
    	if @oldreversalstatus is null
    		update bEMBF set ReversalStatus = 0 where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
    	else
    		begin
    		if @oldreversalstatus not in (0,1,2,3,4)
    			begin
    			select @errtext  = isnull(@errorstart,'') + 'OldReversalStatus ' + isnull(convert(char(2),@reversalstatus),'') + ' invalid. Must be 0, 1, 2, 3, or 4.'
    			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    			if @rcode <> 0
    				begin
    				select @errmsg =isnull(@errtext,'') + '-' + isnull(@errmsg,'')
    				goto bspexit
    				end
    			end
    		if @oldreversalstatus=4 and @batchtranstype = 'C'
    			begin
    			select @errtext  = isnull(@errorstart,'') + 'Cannot cancel OldReversal unless it is original reversing entry.'
    			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    			if @rcode <> 0
    				begin
    				select @errmsg =isnull(@errtext,'') + '-' + isnull(@errmsg,'')
    				goto bspexit
    				end
    			end
    		end
    	
    	/* Validate OldTaxCode - can be null. Also pull TaxRate, calculate TaxAmount	assuming TaxBasis = bEMBF.TotalCost, and update bEMBF.*/
    	if @oldtaxcode is null or @oldemtranstype = 'Fuel' or (select Taxable from bHQMT where MatlGroup = @oldmatlgroup and Material = @oldmaterial) = 'N'
    		begin
    		select @oldtaxcode = null, @oldtaxrate = null, @oldtaxbasis = null, @oldtaxamount = null
    		/* Update bEMBF. */
    		update bEMBF set OldTaxRate = @oldtaxrate, OldTaxBasis = @oldtaxbasis, OldTaxAmount = @oldtaxamount 
    		where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
    		end
    	else
    		begin
    		exec @rcode = dbo.bspHQTaxRateGet @oldtaxgroup, @oldtaxcode, @oldactualdate, null, null, null, @errmsg output
    		if @rcode = 1
    			begin
    
    			select @errtext  = isnull(@errorstart,'') + 'OldTaxCode ' + isnull(@oldtaxcode,'') + '-' + isnull(@errmsg,'')
    			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    			if @rcode <> 0
    				begin
    				select @errmsg =isnull(@errtext,'') + '-' + isnull(@errmsg,'')
    				goto bspexit
    				end
    			end
    	
    		/* If Material is non-taxable or EMTransType = 'Fuel', set @taxcode, @taxrate, @taxbasis and @taxamount to null. */
    		--select @oldtaxbasis = OldDollars from #ValRec --remmed out 9/26 no #ValRec
    		select @oldtaxamount = @oldtaxrate * @oldtaxbasis
    	
    		/* Update bEMBF. */
    		update bEMBF set OldTaxRate = @oldtaxrate, OldTaxBasis = @oldtaxbasis, OldTaxAmount = @oldtaxamount
    		where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
    		
    		end --else for if @taxcode is null or @emtranstype = 'Fuel' or (select Taxable from bHQMT where MatlGroup = @matlgroup and Material = @material) = 'N'
    
     	-- Validate GLTransAcct - can be null except when Source = 'EMFuel' In that case, log error to HQBE and assume that user will setup cost code or cost type properly
     	-- for the Equipment's dept after the batch is rejected, and then run the validation again where we will add the GLTransAcct for them from bEMDO or bEMDG
     	if @oldgltransacct is null 
     		begin
     		-- Get Department for @equipment from bEMEM.
     		select @department = Department from bEMEM with (nolock) where EMCo = @co and Equipment = @oldequipment
     		-- If GLAcct exists in bEMDO, use it.
     		select @oldgltransacct = GLAcct from bEMDO with (nolock)
    		where EMCo = @co and isnull(Department,'') = isnull(@department,'') and EMGroup = @oldemgroup and CostCode = @oldcostcode
     		-- If GLAcct not in bEMDO, get the GLAcct in bEMDG.
     		if @oldgltransacct is null
    			begin
     			select @oldgltransacct = GLAcct from bEMDG with (nolock)
    			where EMCo = @co and isnull(Department,'') = isnull(@department,'') and EMGroup = @oldemgroup and CostType = @oldemcosttype
    			end
    		-- update EMBF with OldGLTransAcct if found
    		if isnull(@oldgltransacct,'') <> ''
    			begin
    			update bEMBF set GLTransAcct = @oldgltransacct where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
    			end
    		end
    
     	-- Validate OldGLTransAcct if not null
     	if isnull(@oldgltransacct,'') <> ''
    		begin
    		exec @rcode = dbo.bspEMGLTransAcctVal @oldglco, @oldgltransacct, 'E', @errmsg output
    		if @rcode = 1
    			begin
    			select @errtext  = isnull(@errorstart,'') + 'OldGLTransAcct ' + isnull(@oldgltransacct,'') + '-' + isnull(@errmsg,'')
    			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    			if @rcode <> 0
    				begin
    				select @errmsg =isnull(@errtext,'') + '-' + isnull(@errmsg,'')
    				goto bspexit
    				end
   
    			end
    		end	
    	else
    		begin
    		-- ref Issue 14064 - JM - Check for blank GLTransAcct
    		select @errtext  = isnull(@errorstart,'') + 'Missing GLTransAcct.'
    		exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    		if @rcode <> 0
    			begin
    			select @errmsg =isnull(@errtext,'') + '-' + isnull(@errmsg,'')
    			goto bspexit
    			end
    		end
    
    	-- Validate OldGLOffsetAcct - GOldLOffsetAcct cannot be null
    	/*if @oldgloffsetacct is null TV 03/07/05 26837 - Old GL Offset Acct cannot be null when deleting transaction
    		begin
    		select @errtext  = isnull(@errorstart,'') + 'OldGLOffsetAcct cannot be null.'
    		exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    		if @rcode <> 0
    			begin
    			select @errmsg =isnull(@errtext,'') + '-' + isnull(@errmsg,'')
    			goto bspexit
    			end
    		end
    	else*/ --OldGLOffsetAcct not null so run basic validation.
    	if @oldgloffsetacct is not null 
    		begin
    		/* JM 1-3-02 Ref Issue 19756 - Need to pass @oldinlocation rather than null so correct GLCo is used for Offset Acct validation
    		(also applies to call in Add type transaction above.) */
    		exec @rcode = dbo.bspEMGLOffsetAcctValForFuelPosting  @co, @oldinco, @oldgloffsetacct, @oldinlocation, @errmsg output
    		if @rcode = 1
    			begin
    			select @errtext  = isnull(@errorstart,'') + 'OldGLOffsetAcct ' + isnull(@oldgloffsetacct,'') + '-' + isnull(@errmsg,'')
    			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    			if @rcode <> 0
    				begin
    
    				select @errmsg =isnull(@errtext,'') + '-' + isnull(@errmsg,'')
    				goto bspexit
    				end
    			end
    		end
    	end --if @batchtranstype in ('C','D')
    
    
    
    
    bspexit:
    	if @rcode<>0 select @errmsg=isnull(@errmsg,'')	--+ char(13) + char(10) + '[bspEMVal_Cost_SeqVal_Adj]'
    	return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspEMVal_Cost_SeqVal_Adj] TO [public]
GO
