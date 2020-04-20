SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE    procedure [dbo].[bspEMVal_Cost_SeqVal_Fuel]
    /***********************************************************
     * CREATED BY: JM 7/9/02 - Ref Issue 17743 - Combination bspEMVal_Cost_AddedChanged and 
     *				bspEMVal_Cost_ChangedDeleted for each source, called from bspEMVal_Cost_Main
     *
     * Modified By : JM 10-02-02 - Ref Issue 18024 - For EMFuel Source, validate GLOffsetAcct SubType = 'I' or null
     *				 JM 10-09-02 - Remove 'rtrim(ltrim(' from GLTransAcct validation against blank (per DF)
     *				 GF 01/27/03 - Issue #19863. not validating UM from fuel initialize. problem w/fuelcapum.
     *				 GF 02/26/2003 - more changes for fuelcapum validation.
     *				 GF 04/15/2003 - issue #19730 - EM cost type validation to not allow null.
     *				 GF 04/24/2003 - issue #21067 - EM Offset acct validation for cross-co IN. Not passing in IN location.
     *				 GF 10/14/2003 - issue #22704 - missing @errorstart for journal and ledger validation
     *				 TV 02/11/04 - 23061 added isnulls
     *				 TV 07/12/2005 - issue 29254 - Allow Deptartment and Category to be Null.
     *				TRL 02/04/2010 Issue 137916  change @description to 60 characters
     *				GF 10/12/2012 TK-18533 add check for empty UM
	 *				GF 11/19/2012 TK-19431 validation error for missing cost type though there is one
	 *				GF 01/04/2013 TK-20577 bad check for old material empty value, not working for empty
	 *				GF 01/14/2013 TK-20723 pass material, matl group to IN Location validation for category override GL Account
	 *
     *
     *
     *	Called by bspEMVal_Cost_Main to run validation applicable only to referenced EMCost Source.
     *	
     *	Forms: EMFuelPosting and EMFuelPostingInit
     *	Posting table: bEMBF
     *	
     *	GLTransAcct must be subtype 'E'
     *	GLJrnl = MatlGLJrnl
     *	GLLvl = MatlGLLvl
     *	
     *	Visible bound inputs that use the same valproc here as in DDFI:
     *		WorkOrder - bspEMWOVal
     *		WOItem - bspEMWOItemVal
     *		Equipment - bspEMEquipValForFuelPosting
     *		ComponentTypeCode - bspEMComponentTypeCodeVal
     *		Component - bspEMComponentVal
     *		CostCode - bspEMCostCodeValForPartsPosting
     *		EMCostType - bspEMCostTypeValForFuelPosting
     *		Material - bspEMMatlValForFuelPosting
     *		NOTE: If Fuel in EMBF matches Fuel in EMEM make sure UM in EMBF matches the FuelCapUM in EMEM or has a conversion.
     *		INCo - bspINCompanyValForFuelPosting
     *		INLocation - bspINLocValForFuelPosting
     *		TaxCode - bspHQTaxCodeValForFuelPosting
     *		NOTE: If Material is non-taxable, make sure TaxCode, TaxRate, TaxBasis and TaxAmount are null. Otherwise, get the 
     *		TaxRate and TaxBasis, calc the TaxAmount, and update bEMBF.
     *		GLTransAcct - bspGLACfPostable and cannot be blank
     *		GLOffsetAcct - bspEMGLOffsetAcctValForFuelPosting and cannot be null
     *		GLTransAcct cannot = GLOffsetAcct 
     *	
     *	Hidden bound inputs without valprocs in DDFI that receive basic validation here:
     *		Source = 'EMFuel'
     *		EMTransType = 'Fuel'
     *		EMGroup - bspHQGroupVal
     *		MatlGroup - bspHQGroupVal
     *		GLCo - bspGLCompanyVal
     *		OffsetGLCo - bspGLCompanyVal
     *		PerECM = ' E', 'C' or 'M'
     *		INStkECM = ' E', 'C' or 'M'
     *		Units must not be null
     *		UnitPrice must not be null
     *		Dollars must not be null
     *		TaxGroup - bspHQGroupVal
     *		UM - bspEMUMValForFuelPosting
     *		INStkUM - bspEMUMValForFuelPosting
     *	
     *	Bound inputs that do not receive validation here:
     *		CurrentOdometer
     *		CurrentHourMeter
     *		BatchTransType
     *		ActualDate
     *		Description	
     *		CurrentTotalOdometer
     *		CurrentTotalHourMeter
     *		TaxBasis
     *		TaxRate
     *		TaxAmount
     *		EMTrans
     *		PreviousHourMeter
     *		PreviousOdometer
     *		PreviousTotalHourMeter
     *		PreviousTotalOdometer
     *		ReplacedHourReading
     *		ReplacedOdoReading
     *		MeterMiles
     *		MeterHours
     *		MeterReadDate
     *		INStkUnitCost
     *		TotalCost
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
        
    -- General declares
    declare @active  bYN, @conversion bUnitCost, @department bDept, @emfixedrate bUnitCost, @errorstart varchar(50), @errtext varchar(255),  
      		@fuelcapum bUM, @fuelmatlcode bMatl, @gljrnl bJrnl, @gllvl tinyint, @glsubtype char(1), @oldemcosttypechar varchar(5), @rcode int, 
      		@stdum bUM, @umconv bUnitCost
       
      
    -- bEMBF non-Olds declares
    declare @actualdate bDate, @alloccode tinyint, @apco bCompany, @apline bItem, @apref bAPReference,@aptrans bTrans, @apvendor bVendor, @asset varchar(20), 
      		@batchtranstype char(1), @component bEquip, @componenttypecode varchar(10), @costcode bCostCode, @currenthourmeter bHrs, @currentodometer bHrs,  
      		@currenttotalhourmeter bHrs, @currenttotalodometer bHrs, @description bItemDesc/*137916*/, @dollars bDollar, @emcosttype bEMCType, @emgroup bGroup,@emtrans bTrans, 
      		@emtranstype varchar(10), @equipment bEquip,@glco bCompany,  @gloffsetacct bGLAcct, @gltransacct bGLAcct, @hours bHrs, @inco bCompany, 
      		@inlocation bLoc, @instkecm bECM,  @instkum bUM,  @instkunitcost bUnitCost, @jcco bCompany, @jccosttype bJCCType, @jcphase bPhase, @job bJob, 
      		@material bMatl, @matlgroup bGroup, @meterhrs bHrs, @metermiles bHrs, @metertrans bTrans, @meterreaddate bDate, @offsetglco bCompany, 
      		@origemtrans bTrans, @origmth bMonth, @phasegrp bGroup, @perecm char(1), @prco bCompany,  @premployee bEmployee, 
      		@previoushourmeter bHrs, @previousodometer bHrs, @previoustotalhourmeter bHrs, @previoustotalodometer bHrs, @replacedhourreading bHrs, @replacedodoreading bHrs,
      		@revcode bRevCode, @reversalstatus tinyint, @revdollars bDollar, @revrate bDollar, @revtimeunits bUnits, @revusedonequip bEquip, @revusedonequipco bCompany, 
      		@revusedonequipgroup bGroup, @revworkunits bUnits, @serialno varchar(20),  @taxamount bDollar, @taxbasis bDollar, @taxcode bTaxCode, @taxgroup bGroup, 
      		@taxrate bRate, @taxtype tinyint, @timeum bUM, @totalcost bDollar, @um bUM, @unitprice bUnitCost,  @units bUnits, @vendorgrp bGroup
        
    -- bEMBF Olds declares
    declare @oldactualdate bDate, @oldalloccode tinyint, @oldapco bCompany, @oldapline bItem, @oldapref bAPReference,
      		@oldaptrans bTrans, @oldapvendor bVendor, @oldasset varchar(20), @oldbatchtranstype char(1), @oldcomponent bEquip, @oldcomponenttypecode varchar(10),
         		@oldcostcode bCostCode, @oldcurrentodometer bHrs, @oldcurrenthourmeter bHrs, @oldcurrenttotalodometer bHrs, @oldcurrenttotalhourmeter bHrs, 
        		@olddescription bTransDesc, @olddollars bDollar, @oldemcosttype bEMCType, @oldemgroup bGroup, @oldemtrans bTrans, @oldemtranstype varchar(10), 
        		@oldequipment bEquip, @oldglco bCompany, @oldgloffsetacct bGLAcct, @oldgltransacct bGLAcct, @oldhours bHrs, @oldinco bCompany, @oldinlocation bLoc, 
        		@oldinstkunitcost bUnitCost, @oldinstkecm bECM, @oldinstkum bUM, @oldjcco bCompany, @oldjccosttype bJCCType, @oldjcphase bPhase, @oldjob bJob, @oldmaterial bMatl, 
        		@oldmatlgroup bGroup, @oldmeterhrs bHrs, @oldmetermiles bHrs, @oldmeterreaddate bDate, @oldmetertrans bTrans, @oldoffsetglco bCompany, @oldorigemtrans bTrans, 
        		@oldorigmth bMonth, @oldperecm char(1), @oldphasegrp bGroup, @oldprco bCompany, @oldpremployee bEmployee, @oldprevioushourmeter bHrs, 
        		@oldpreviousodometer bHrs, @oldprevioustotalhourmeter bHrs, @oldprevioustotalodometer bHrs, @oldreplacedhourreading bHrs, @oldreplacedodoreading bHrs, @oldrevcode bRevCode,  
        		@oldrevdollars bDollar, @oldreversalstatus tinyint, @oldrevrate bDollar, @oldrevtimeunits bUnits, @oldrevtranstype varchar(20), @oldrevusedonequip bEquip, 
        		@oldrevusedonequipco bCompany, @oldrevusedonequipgroup bGroup, 	@oldrevworkunits bUnits, @oldserialno varchar(20), @oldsource varchar(10), @oldtaxtype tinyint, 
        		@oldtaxamount bDollar, @oldtaxbasis bDollar, @oldtaxcode bTaxCode, @oldtaxgroup bGroup, @oldtaxrate bRate, @oldtimeum bUM, @oldtotalcost bDollar, @oldum bUM, 
        		@oldunitprice bUnitCost, @oldunits bUnits, @oldvendorgrp bGroup
        
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
        
      -- Fetch row data into variables.
      select @actualdate = ActualDate, @alloccode = AllocCode, @apco = APCo, @apline = APLine, @apref = APRef, @aptrans = APTrans, @apvendor = APVendor, @asset = Asset,
      	@batchtranstype = BatchTransType, @component = Component, @componenttypecode = ComponentTypeCode, @costcode = CostCode, @currenthourmeter = CurrentHourMeter,
        	@currentodometer = CurrentOdometer, @currenttotalhourmeter = CurrentTotalHourMeter, @currenttotalodometer = CurrentTotalOdometer, @description = [Description],
        	@dollars = Dollars, @emcosttype = EMCostType, @emgroup = EMGroup, @emtrans = EMTrans, @emtranstype = EMTransType, @equipment = Equipment, @glco = GLCo,
        	@gloffsetacct = GLOffsetAcct, @gltransacct = GLTransAcct, @hours = Hours, @inco = INCo, @inlocation = INLocation, @instkecm = INStkECM, @instkum = INStkUM,
        	@instkunitcost = INStkUnitCost, @jcco = JCCo, @jccosttype = JCCostType, @jcphase = JCPhase, @job = Job, @material = Material, @matlgroup = MatlGroup, @meterhrs = MeterHrs,
        	@metermiles = MeterMiles, @meterreaddate = MeterReadDate, @metertrans = MeterTrans, @offsetglco = OffsetGLCo, @origemtrans = OrigEMTrans, @origmth = OrigMth,
        	@perecm = PerECM, @phasegrp = PhaseGrp, @prco = PRCo, @premployee = PREmployee, @previoushourmeter = PreviousHourMeter,
        	@previousodometer = PreviousOdometer, @previoustotalhourmeter = PreviousTotalHourMeter, @previoustotalodometer = PreviousTotalOdometer, @replacedhourreading = ReplacedHourReading,
        	@replacedodoreading = ReplacedOdoReading, @revcode = RevCode, @reversalstatus = ReversalStatus, @revdollars = RevDollars, @revrate = RevRate, @revtimeunits = RevTimeUnits,
        	@revusedonequip = RevUsedOnEquip, @revusedonequipco = RevUsedOnEquipCo, @revusedonequipgroup = RevUsedOnEquipGroup, @revworkunits = RevWorkUnits, 
        	@serialno = SerialNo, @taxamount = TaxAmount, @taxbasis = TaxBasis, @taxcode = TaxCode, @taxgroup = TaxGroup, @taxrate = TaxRate, @taxtype = TaxType,
        	@timeum = TimeUM, @totalcost = TotalCost, @um = UM, @unitprice = UnitPrice, @units = Units, @oldactualdate = OldActualDate,
         @oldalloccode = OldAllocCode, @oldapco = OldAPCo,  @oldapline = OldAPLine, @oldapref = OldAPRef, @oldaptrans = OldAPTrans,  @oldapvendor = OldAPVendor, @oldasset = OldAsset,
         @oldbatchtranstype = OldBatchTransType, @oldcomponent = OldComponent, @oldcomponenttypecode = OldComponentTypeCode, @oldcostcode = OldCostCode,
         @oldcurrenthourmeter = OldCurrentHourMeter, @oldcurrentodometer = OldCurrentOdometer, @oldcurrenttotalhourmeter = OldCurrentTotalHourMeter,
        	@oldcurrenttotalodometer = OldCurrentTotalOdometer, @olddescription = OldDescription, @olddollars = OldDollars, @oldemcosttype = OldEMCostType, @oldemgroup = OldEMGroup,
         @oldemtrans = OldEMTrans, @oldemtranstype = OldEMTransType, @oldequipment = OldEquipment, @oldglco = OldGLCo, @oldgloffsetacct = OldGLOffsetAcct,
         @oldgltransacct = OldGLTransAcct, @oldinco = OldINCo, @oldinstkecm = OldINStkECM, @oldinstkum = OldINStkUM,  @oldinstkunitcost = OldINStkUnitCost, @oldinlocation = OldINLocation,
         @oldmaterial = OldMaterial, @oldmatlgroup = OldMatlGroup, @oldmetertrans = OldMeterTrans, @oldperecm = OldPerECM,
        	@oldprco = OldPRCo, @oldpremployee = OldPREmployee,  @oldreversalstatus = OldReversalStatus, @oldserialno = OldSerialNo, @oldsource = OldSource, @oldtaxamount = OldTaxAmount,
        	@oldtaxbasis = OldTaxBasis, @oldtaxcode = OldTaxCode, @oldtaxgroup = OldTaxGroup, @oldtaxrate = OldTaxRate, @oldtaxtype = OldTaxType, @oldtotalcost = OldTotalCost,
         @oldum = OldUM, @oldunitprice = OldUnitPrice, @oldunits = OldUnits, @oldvendorgrp = VendorGrp 
      from bEMBF where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
        
      -- Setup @errorstart string.
      select @errorstart = 'Seq: ' + isnull(convert(varchar(9),@batchseq),'') + ' - '
        
      ---------------All BatchTransTypes
      -- Ref Issue 18024 - For EMFuel Source, validate GLOffsetAcct SubType = 'I' or null
      select @glsubtype = (select SubType From bGLAC where GLCo = @glco and GLAcct = @gloffsetacct)
     if @inco is not null and  isnull(@inlocation,'') <>'' 
		begin
			if @glsubtype <> 'I' and isnull(@glsubtype,'') <>''
			begin
       			select @errtext = isnull(@errorstart,'') + 'GLOffsetAcct: ' + isnull(convert(varchar(20),@gloffsetacct),'') + ' has a Subledger Type: ' + isnull(@glsubtype,'') + '. Must be I or null!'
       			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
       			if @rcode <> 0
       			begin
       				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
       				goto bspexit
       			end
       		end
       	end 
      else 
		begin  
			-- Validate GLTransAcct SubType = 'E' or null
			select @glsubtype = (select SubType From bGLAC where GLCo = @glco and GLAcct = @gloffsetacct)
			if @glsubtype <> 'E' and  isnull(@glsubtype,'') <>''
        		begin
        			select @errtext = isnull(@errorstart,'') + 'GLTransAcct: ' + isnull(convert(varchar(20),@gloffsetacct),'') + ' has a Subledger Type: ' + isnull(@glsubtype,'') + '. Must be E or null!'
        			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
        			if @rcode <> 0
        				begin
        					select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
        					goto bspexit
        				end
        		end
		end
		
	-- Validate GLTransAcct SubType = 'E' or null
	select @glsubtype = (select SubType From bGLAC where GLCo = @glco and GLAcct = @gltransacct)
	if @glsubtype <> 'E' and isnull(@glsubtype,'')<>''
	begin
		select @errtext = isnull(@errorstart,'') + 'GLTransAcct: ' + isnull(convert(varchar(20),@gltransacct),'') + ' has a Subledger Type: ' + isnull(@glsubtype,'') + '. Must be E or null!'
        	exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
        	if @rcode <> 0
        	begin
        		select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
        		goto bspexit
        	end
       end	
      -- Valide GLJrnl
      select @gljrnl = MatlGLJrnl, @glco = GLCo, @gllvl = MatlGLLvl from bEMCO where EMCo = @co
      if @gllvl <> 0 -- Dont check on No Update GL Lvl.
        	begin
        	if @gljrnl is null
        		begin
        		--select @errtext = 'GLJrnl=' + convert(varchar(4),@gljrnl) +  ' - GLJrnl null in bEMCO.'
       		select @errtext = isnull(@errorstart,'') + 'GLJrnl null in bEMCO.'
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
        			select @errtext = isnull(@errorstart,'') + 'GLJrnl ' + isnull(@gljrnl,'') + '-' + isnull(@errmsg,'')
        			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
        			if @rcode <> 0
        				begin
        				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
        				goto bspexit
   
        				end
        			end
        		end
        	end
        
      -- Validate EMTransType =
      if @emtranstype <> 'Fuel'
   
        	begin
        	select @errtext = isnull(@errorstart,'') + isnull(@emtranstype,'') + ' is an invalid EMTransType.'
        	exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
        	if @rcode <> 0
        		begin
        		select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
        		goto bspexit
        		end
        	end
        
      -- Verify Units not null.
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
        
      -- Verify UnitPrice not null.
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
        
      -- Verify Dollars not null.
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
        	-- Validate Equipment - cannot be null.
        	exec @rcode = dbo.bspEMEquipValForFuelPosting @co, @equipment, @matlgroup, @emgroup, @inco, @inlocation, null, null, null, 
        		null, null, null, null, null, null, null, null, null, null, 
        		null, null, null, null, null, null, @errmsg output
        	if @rcode = 1
        		begin
        		select @errtext = isnull(@errorstart,'') + 'Equipment ' + isnull(@equipment,'') + '-' + isnull(@errmsg,'')
        		exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
        		if @rcode <> 0
        			begin
        			select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
        			goto bspexit
        			end
        		end
        	
        	-- Validate ComponentTypeCode - can be null.
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
        	
        	-- Validate Component - can be null.
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
        	
        	-- Validate EMGroup - can be null.
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
        	
        	-- Validate CostCode - can be null.
        	if @costcode is not null
        		begin
        		exec @rcode = dbo.bspEMCostCodeValForFuelPosting @co, @emgroup, @costcode, @equipment, @gltransacct, @emcosttype, null, @errmsg output
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
        		end
        	
        	-- Validate EMCostType
        	if @emcosttype is not null
        		begin
        		exec @rcode = dbo.bspEMCostTypeValForFuelPosting @co, @emgroup, @equipment, @costcode, @emcosttype, null, null, null, @errmsg output
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
        		END
			----TK-19431            
			ELSE
   				BEGIN
   				select @errtext = isnull(@errorstart,'') + 'Missing EM Cost Type'
         		exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
         		if @rcode <> 0
         			begin
         			select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
         			goto bspexit
         			end
         		END
                
			---- TK-18533 UM not empty
			IF ISNULL(@um,'') = ''
				BEGIN
				SELECT @errtext = dbo.vfToString(@errorstart) + ' - Invalid UM. Must not be empty.'
				exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
       			if @rcode <> 0
       				begin
       				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
       				goto bspexit
       				end
				END
				

        	
        	-- Validate MatlGroup - can be null.
        	if @matlgroup is not null
        		begin
        		exec @rcode = dbo.bspHQGroupVal @matlgroup, @errmsg output
        		if @rcode = 1
        			begin
        			select @errtext = isnull(@errorstart,'') + 'MatlGroup ' + isnull(convert(varchar(5),@matlgroup),'') + '-' + isnull(@errmsg,'')
        			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
        			if @rcode <> 0
        				begin
        				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
        				goto bspexit
        				end
        			end
        		end
        	
    		-- Validate Material - can be null.
    		if isnull(@material,'') = '' goto Validate_GLCo
    
    		select @stdum = null
        	exec @rcode = dbo.bspEMMatlValForFuelPosting @co, @equipment, @matlgroup, @material, 'EA', @inco, @inlocation,
    					@stdum output, null, null, null, null, null, null, @errmsg output
    		if @rcode <> 0 
    			begin
    			select @errtext = isnull(@errorstart,'') + 'Material ' + isnull(@material,'') + '-' + isnull(@errmsg,'')
    			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    			if @rcode <> 0
    				begin
    				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
    				goto bspexit
    				end
    			goto Validate_GLCo
    			end
    
    	    -- If Fuel in EMBF matches Fuel in EMEM (per RH 8/7/01), make sure UM in EMBF matches the 
    	    -- FuelCapUM in EMEM or has a conversion.
    	    select @fuelmatlcode = FuelMatlCode, @fuelcapum = FuelCapUM 
    	  	from EMEM with (nolock) where EMCo = @co and Equipment = @equipment
    		-- skip if @fuelmatlcode <> @material code
    		if @fuelmatlcode <> @material goto Validate_GLCo
    	
    		-- @fuelcapum must exist
    	 	if isnull(@fuelcapum,'') = ''
    	 		begin
    		 	select @errtext = isnull(@errorstart,'') + 'Missing Fuel Cap U/M from Equipment Master EMEM.'
    		 	exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    		 	if @rcode <> 0
    		 	   	begin
    		 	   	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
    		 	   	goto bspexit
    		 	   	end
    			goto Validate_GLCo
    	 	   	end
				
    		-- if @fuelcapum = @um then done
    		if @fuelcapum = @um goto Validate_GLCo
    	
    		-- when @um <> @stdum then verify that @um conversion exists in HQMU for material
    		if @stdum <> @um
    			begin
    			if not exists(select * from bHQMU with (nolock) where MatlGroup=@matlgroup and Material=@material and UM=@um)
    				begin
    	 	   		select @errtext = isnull(@errorstart,'') + 'Unit of Measure does not have a conversion to U/M listed for this fuel in EMEM.'
    	 	   		exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    	 	   		if @rcode <> 0
    	 	   			begin
    	 	   			select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
    	 	   			goto bspexit
    	 	   			end
    	 	   		end
    	 	   	end
     
    
    		Validate_GLCo:
    	    -- Validate GLCo - can be null.
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
        
        	-- Validate OffsetGLCo - can be null.
        	if @offsetglco is not null
        		begin
        		exec @rcode = dbo.bspGLCompanyVal @offsetglco, @errmsg output
        		if @rcode = 1
        			begin
        			select @errtext = isnull(@errorstart,'') + 'OffsetGLCo ' + isnull(convert(varchar(5),@offsetglco),'') + '-' + isnull(@errmsg,'')
        			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
        			if @rcode <> 0
        				begin
        				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
        				goto bspexit
        				end
        			end
        		end
        
        	-- Validate INCo - can be null.
        	if @inco is not null
        		begin
        		exec @rcode = dbo.bspINCompanyValForFuelPosting @inco, null, null, null, null, @errmsg output
        		if @rcode = 1
        			begin
        			select @errtext = isnull(@errorstart,'') + 'INCo ' + isnull(convert(varchar(3),@inco),'') + '-' + isnull(@errmsg,'')
        			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
        			if @rcode <> 0
        				begin
        				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
        				goto bspexit
        				end
        			end
        		end
       
        	-- Validate INLocation - can be null.
        	if @inlocation is not null
        		BEGIN
				----TK-20723              
        		exec @rcode = dbo.bspINLocValForFuelPosting @inco, @inlocation, @material, null, @matlgroup, @co, @equipment, null, null, null, null, null, @errmsg OUTPUT
        		if @rcode = 1
        			begin
        			select @errtext = isnull(@errorstart,'') + 'INLocation ' + isnull(@inlocation,'') + '-' + isnull(@errmsg,'')
        			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
        			if @rcode <> 0
        				begin
        				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
        				goto bspexit
        				end
        			end
        		end
        	
        	-- Validate PerECM - can be null.
        	if @perecm is not null and @perecm not in ('E','C','M')
        		begin
        		select @errtext = isnull(@errorstart,'') + 'Invalid PerECM, must be E,C, or M.'
        		exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
        		if @rcode <> 0
        			begin
        			select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
        			goto bspexit
        			end
        		end
        	
        	-- Validate INStkECM - can be null.
        	if @instkecm is not null and @instkecm not in ('E','C','M')
        		begin
        		select @errtext = isnull(@errorstart,'') + 'Invalid INStkECM, must be E,C, or M.'
        		exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
        		if @rcode <> 0
        			begin
        			select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
        			goto bspexit
        			end
        		end
        
        	/* Validate TaxGroup - can be null. */
        	if @taxgroup is not null
        		begin
        		exec @rcode = dbo.bspHQGroupVal @taxgroup, @errmsg output
        		if @rcode = 1         
        			begin
        			select @errtext = isnull(@errorstart,'') + 'TaxGroup ' + isnull(convert(varchar(5),@taxgroup),'') + '-' + isnull(@errmsg,'')
        			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
        			if @rcode <> 0
        				begin
        				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
        				goto bspexit
        				end
        			end
        		end
        	
        	/* Validate TaxCode - can be null. Also pull TaxRate, calculate TaxAmount
        	assuming TaxBasis = bEMBF.TotalCost, and update bEMBF.*/
        	if @taxcode is not null
        		begin
        		exec @rcode = dbo.bspHQTaxCodeValForFuelPosting @taxgroup, null, @taxcode, @errmsg output
        		if @rcode = 1
        			begin
        			select @errtext = isnull(@errorstart,'') + 'TaxCode ' + isnull(@taxcode,'') + '-' + isnull(@errmsg,'')
        			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
        			if @rcode <> 0
        				begin
        				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
        				goto bspexit
        				end
        			end
        		/* If Material is non-taxable, make sure @taxcode, @taxrate, @taxbasis and @taxamount are null. */
        		if (select Taxable from bHQMT where MatlGroup = @matlgroup and Material = @material) = 'N'
        			select @taxcode = null, @taxrate = null, @taxbasis = null, @taxamount = null
        		else
        			begin
        			/* Pull TaxRate from bHQTX and calculate TaxAmount assuming TaxBasis = bEMBF.TotalCost. */
        			exec @rcode = dbo.bspHQTaxRateGet @taxgroup, @taxcode, @actualdate, @taxrate output,          null, null, @errmsg output
        			if @rcode <> 0
        				begin
        				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
        				goto bspexit
        				end
        			--select @taxbasis = Dollars from #ValRec - remmed out - no #ValRec
        			select @taxamount = @taxrate * @taxbasis
        			select @taxtype = 1
        			end
        	
        		/* Update bEMBF. */
        		select @taxrate=null, @taxbasis=null, @taxamount=null
        		update bEMBF set TaxRate = @taxrate, TaxBasis = @taxbasis, TaxAmount = @taxamount
        		where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
        		
        		end --if @taxcode is not null
        	
        	if @taxcode is null
        		begin
        		select @taxrate = null, @taxbasis = null, @taxamount = null
        		/* Update bEMBF. */
        		update bEMBF set TaxRate = @taxrate, TaxBasis = @taxbasis, TaxAmount = @taxamount
        		where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
        		end
        	
        	/* Validate UM - can be null. */
        	if @um is not null
        		begin
        		exec @rcode = dbo.bspEMUMValForFuelPosting @co, @um, @matlgroup, null, null, null, null, @errmsg output
        		if @rcode = 1
        			begin
        			select @errtext = isnull(@errorstart,'') + 'UM ' + isnull(@um,'') + '-' + isnull(@errmsg,'')
        			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
        			if @rcode <> 0
        				begin
        				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
        				goto bspexit
        				end
        			end
        		end
        
        	/* Validate INStkUM - can be null. */
        	if @instkum is not null
        		begin
        		exec @rcode = dbo.bspEMUMValForFuelPosting @co, @instkum, @matlgroup, null, null, null, null, @errmsg output
        		if @rcode = 1
        			begin
        			select @errtext = isnull(@errorstart,'') + 'INStkUM ' + isnull(@instkum,'') + '-' + isnull(@errmsg,'')
        			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
        			if @rcode <> 0
        				begin
        				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
        				goto bspexit
        				end
        			end
        		end
        
        	/* Validate GLTransAcct - can be null except when Source = 'EMFuel' In that case, log error to HQBE and assume that user will setup cost code or cost type properly
        	for the Equipment's dept after the batch is rejected, and then run the validation again where we will add the GLTransAcct for them from bEMDO or bEMDG. */
        	if @gltransacct is null 
        		begin
        		/* Get Department for @equipment from bEMEM. */
        		select @department = Department from bEMEM where EMCo = @co and Equipment = @equipment
        		/* If GLAcct exists in bEMDO, use it. */
        		select @gltransacct = GLAcct from bEMDO where EMCo = @co and isnull(Department,'') = isnull(@department,'') and EMGroup = @emgroup and CostCode = @costcode
        		/* If GLAcct not in bEMDO, get the GLAcct in bEMDG. */
        		if @gltransacct is null
        			select @gltransacct = GLAcct from bEMDG where EMCo = @co and isnull(Department,'') = isnull(@department,'') and EMGroup = @emgroup and CostType = @emcosttype

        		-- if GLAcct not found in either file, log error, let user do setup and rerun validation
        		if @gltransacct is null
        			begin
        			declare @msg varchar(255)
        			select @msg =  'GLTransAcct missing in EMDept for BatchSeq ' + isnull(convert(varchar(5),@batchseq),'')
        			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @msg, @errmsg output
   	  			if @rcode <> 0
   	  				begin
   	  				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   	  				goto bspexit
   	  				end
     				end
     			end
   
        	-- If GLAcct found in either file, update bEMBF for this record; else log to HQBE.
        	if @gltransacct is not null
        		begin
        		update bEMBF set GLTransAcct = @gltransacct where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
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
       
        	/* Ref Issue 14064 - JM - Check for blank GLTransAcct */
        	--select @gltransacct = rtrim(ltrim(@gltransacct))
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
        	
        	/* Validate GLOffsetAcct */
        	/* If GLOffsetAcct not null, run basic validation. */
        	if @gloffsetacct is not null
        		begin
        		exec @rcode = dbo.bspEMGLOffsetAcctValForFuelPosting  @co, @inco, @gloffsetacct, @inlocation, @errmsg output
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
        	
        	
        	/* Verify that GLTrans and GLOffset accts arent the same. */
        	if @gltransacct = @gloffsetacct 
        		begin
        		select @errtext = isnull(@errorstart,'') + 'GLTransAcct and GLOffsetAcct cannot be the same!'
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
        
        	end --if @batchtranstype in ('A','C')
        
        ---------------BatchTransType = C & D
        
        if @batchtranstype in ('C','D')
        	begin
        
        	 /* Get existing values from EMCD. */
        	select @emcdactualdate = ActualDate, @emcdalloccode = AllocCode, @emcdapco = APCo, @emcdapline = APLine, @emcdapref = APRef, @emcdaptrans = APTrans, 
        		@emcdapvendor = APVendor, @emcdasset = Asset, @emcdcomponent = Component, @emcdcomponenttypecode = ComponentTypeCode, @emcdcostcode = CostCode,
        	 	@emcddescription = [Description], @emcddollars = Dollars, @emcdemcosttype = EMCostType, @emcdcurrenthourmeter = CurrentHourMeter,
        		@emcdcurrentodometer = CurrentOdometer, @emcdcurrenttotalhourmeter = CurrentTotalHourMeter, @emcdcurrenttotalodometer = CurrentTotalOdometer,
        	 	@emcdemgroup = EMGroup, @emcdemtrans = EMTrans, @emcdemtranstype = EMTransType, @emcdequipment = Equipment, @emcdglco = GLCo,
        	 	@emcdgloffsetacct = GLOffsetAcct, @emcdgltransacct = GLTransAcct, @emcdinco = INCo, @emcdinlocation = INLocation, @emcdinstkecm = INStkECM,
        		@emcdinstkum = INStkUM, @emcdinstkunitcost = INStkUnitCost,	@emcdmaterial = Material, @emcdinusebatchid = InUseBatchID, 	@emcdmatlgroup = MatlGroup,
        		@emcdmetertrans = MeterTrans, @emcdperecm = PerECM, @emcdprco = PRCo, @emcdpremployee = PREmployee, @emcdreversalstatus = ReversalStatus,
        	 	@emcdserialno = SerialNo, @emcdsource = Source, @emcdtaxcode = TaxCode, @emcdtaxamount = TaxAmount, @emcdtaxbasis = TaxBasis,
        		@emcdtaxgroup = TaxGroup, @emcdtaxrate = TaxRate, @emcdtaxtype = TaxType, @emcdtotalcost = TotalCost,  @emcdum = UM, @emcdunitprice = UnitPrice,
        	 	@emcdunits = Units, @emcdvendorgrp = VendorGrp, @emcdwoitem = WOItem, @emcdworkorder = WorkOrder
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
        		or isnull(@emcdalloccode,'') <> isnull(@oldalloccode,'')
        		or isnull(@emcdapco,0) <> isnull(@oldapco,0)
        		or isnull(@emcdapline,0) <> isnull(@oldapline,0)
        		or isnull(@emcdaptrans,0) <> isnull(@oldaptrans,0)
        		or isnull(@emcdapvendor,0) <> isnull(@oldapvendor,0)
        		or isnull(@emcdasset,'') <> isnull(@oldasset,'')
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
        		or isnull(@emcdinstkecm,'') <> isnull(@oldinstkecm,'')
        		or isnull(@emcdinstkum,'') <> isnull(@oldinstkum,'')
        		or @emcdinstkunitcost <> @oldinstkunitcost
        		or isnull(@emcdmaterial,'') <> isnull(@oldmaterial,'')
        		or isnull(@emcdmatlgroup,0) <> isnull(@oldmatlgroup,0)
        		or isnull(@emcdmetertrans,0) <> isnull(@oldmetertrans,0)
        		or isnull(@emcdperecm,'') <> isnull(@oldperecm,'')
        		or isnull(@emcdprco,0) <> isnull(@oldprco,0)
        		or isnull(@emcdpremployee,'') <> isnull(@oldpremployee,'')
        		or isnull(@emcdreversalstatus,0) <> isnull(@oldreversalstatus,0)
        		or isnull(@emcdserialno,'') <> isnull(@oldserialno,'')
        		or isnull(@emcdsource,'') <> isnull(@oldsource,'')
        		or isnull(@emcdtaxamount,0) <> isnull(@oldtaxamount,0)
        		or isnull(@emcdtaxbasis,0) <> isnull(@oldtaxbasis,0)
        		or isnull(@emcdtaxcode,'') <> isnull(@oldtaxcode,'')
        		or isnull(@emcdtaxgroup,0) <> isnull(@oldtaxgroup,0)
        		or isnull(@emcdtaxrate,0) <> isnull(@oldtaxrate,0)
       
        		or isnull(@emcdtaxtype,0) <> isnull(@oldtaxtype,0)
        		or isnull(@emcdtotalcost,0) <> isnull(@oldtotalcost,0)
        		or isnull(@emcdum,'') <> isnull(@oldum,'')
        		or @emcdunitprice <> @oldunitprice
        		or @emcdunits <> @oldunits
        		or isnull(@emcdvendorgrp,0) <> isnull(@oldvendorgrp,0)
        		begin
        		select @errtext = isnull(@errorstart,'') + '-Batch Old info does not match EM Cost Detail.'
        		exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
        		if @rcode <> 0
        			begin
        			select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
        			goto bspexit
        			end
        		end
        	
        	-- Validate OldEquipment - cannot be null.
       	exec @rcode = dbo.bspEMEquipValForFuelPosting @co, @oldequipment, @oldmatlgroup, @oldemgroup, @oldinco, @oldinlocation, null, null, 
        		null, null, null, null, null, null, null, null, null, null, null, 
        		null, null, null, null, null, null, @errmsg output
        	if @rcode = 1
        		begin
        		select @errtext = isnull(@errorstart,'') + 'Equipment ' + isnull(@oldequipment,'') + '-' + isnull(@errmsg,'')
        		exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
        		if @rcode <> 0
        			begin
        			select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
        			goto bspexit
        			end
        		end
        	
        	-- Validate OldComponentTypeCode - can be null.
        	if @oldcomponenttypecode is not null
        		begin
        		exec @rcode = dbo.bspEMComponentTypeCodeVal @co, @oldcomponenttypecode, @oldcomponent, @oldequipment, @oldemgroup, null, null, @errmsg output
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
        	
        	-- Validate OldComponent - can be null.
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
        	
        	-- Validate OldEMGroup - can be null.
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
        	
        	-- Validate OldCostCode - cannot be null.
        	exec @rcode = dbo.bspEMCostCodeValForFuelPosting @co, @oldemgroup, @oldcostcode, @oldequipment, @oldgltransacct, @oldemcosttype, null, @errmsg output
        	if @rcode = 1
        		begin
        		select @errtext = isnull(@errorstart,'') + 'CostCode ' + isnull(@oldcostcode,'') + '-' + isnull(@errmsg,'')
        		exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
        		if @rcode <> 0
        			begin
        			select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
        			goto bspexit
        			end
        		end
        	
        	-- Validate OldEMCostType - cannot be null.
        	exec @rcode = dbo.bspEMCostTypeValForFuelPosting @co, @oldemgroup, @oldequipment, @oldcostcode, @oldemcosttype, null, null, null, @errmsg output
        	if @rcode = 1
        		begin
        		select @errtext = isnull(@errorstart,'') + 'EMCostType ' + isnull(convert(varchar(5),@oldemcosttype),'') + '-' + isnull(@errmsg,'')
        		exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
        		if @rcode <> 0
        			begin
        			select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
        			goto bspexit
        			end
        		end
        	
        	-- Validate OldMatlGroup - can be null.
        	if @oldmatlgroup is not null
        		begin
        		exec @rcode = dbo.bspHQGroupVal @oldmatlgroup, @errmsg output
        		if @rcode = 1
        			begin
        			select @errtext = isnull(@errorstart,'') + 'OldMatlGroup ' + isnull(convert(varchar(5),@oldmatlgroup),'') + '-' + isnull(@errmsg,'')
        			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
        			if @rcode <> 0
        
        				begin
        				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
        				goto bspexit
        				end
        			end
        		end
        	
    		-- Validate OldMaterial - can be null.
			----TK-20577 was not checking for empty
    		if isnull(@oldmaterial,'') = '' goto Validate_OldGLCo
    	
    		select @stdum = null
        		exec @rcode = dbo.bspEMMatlValForFuelPosting @co, @oldequipment, @oldmatlgroup, @oldmaterial, 'EA', @oldinco, @oldinlocation,
    					@stdum output, null, null, null, null, null, null, @errmsg output
    		if @rcode <> 0
    			begin
    			select @errtext = isnull(@errorstart,'') + 'OldMaterial ' + isnull(@material,'') + '-' + isnull(@errmsg,'')
    			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    			if @rcode <> 0
    				begin
    				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
    				goto bspexit
    				end
    			goto Validate_OldGLCo
    			end
    
    		-- If Fuel in EMBF matches Fuel in EMEM (per RH 8/7/01), make sure UM in EMBF matches the FuelCapUM in EMEM or has a conversion.
    		select @fuelmatlcode = FuelMatlCode, @fuelcapum = FuelCapUM 
    		from EMEM with (nolock) where EMCo = @co and Equipment = @oldequipment
    		-- skip if @fuelmatlcode <> @material code
    		if @fuelmatlcode <> @oldmaterial goto Validate_OldGLCo
    	
    		-- @fuelcapum must exist
    	 	if isnull(@fuelcapum,'') = ''
    	 		begin
    		 	select @errtext = isnull(@errorstart,'') + 'Missing Fuel Cap U/M from Equipment Master EMEM.'
    		 	exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    		 	if @rcode <> 0
    		 	   	begin
    		 	   	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
    		 	   	goto bspexit
    		 	   	end
    			goto Validate_OldGLCo
    	 	   	end
    
    		-- if @fuelcapum = @um then done
    		if @fuelcapum = @oldum goto Validate_OldGLCo
    	
    		-- when @um <> @stdum then verify that @um conversion exists in HQMU for material
    		if @stdum <> @oldum
    			begin
    			if not exists(select * from bHQMU with (nolock) where MatlGroup=@oldmatlgroup and Material=@oldmaterial and UM=@oldum)
    				begin
    	 	   		select @errtext = isnull(@errorstart,'') + 'Unit of Measure does not have a conversion to U/M listed for this fuel in EMEM.'
    	 	   		exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    	 	   		if @rcode <> 0
    	 	   			begin
    	 	   			select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
    	 	   			goto bspexit
    	 	   			end
    	 	   		end
    	 	   	end
    
   		
        	Validate_OldGLCo:
   		
        	-- Validate OldGLCo - can be null.
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
        	
        	-- Validate OldOffsetGLCo - can be null. 
        	if @oldoffsetglco is not null
        		begin
        		exec @rcode = dbo.bspGLCompanyVal @oldoffsetglco, @errmsg output
        		if @rcode = 1
        			begin
        			select @errtext = isnull(@errorstart,'') + 'OldOffsetGLCo ' + isnull(convert(varchar(5),@oldoffsetglco),'') + '-' + isnull(@errmsg,'')
        			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
        			if @rcode <> 0
        				begin
        				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
        				goto bspexit
        				end
        			end
        		end
        	
        	-- Validate OldINCo - can be null. 
        	if @oldinco is not null
        		begin
        		exec @rcode = dbo.bspINCompanyValForFuelPosting @oldinco, null, null, null, null, @errmsg output
        		if @rcode = 1
        			begin
        			select @errtext = isnull(@errorstart,'') + 'INCo ' + isnull(convert(varchar(3),@oldinco),'') + '-' + isnull(@errmsg,'')
        			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
        			if @rcode <> 0
        				begin
        				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
        				goto bspexit
        				end
        			end
        		end
        	
        	-- Validate OldINLocation - can be null.
        	if @oldinlocation is not null
        		BEGIN
				----TK-20723         
        		exec @rcode = dbo.bspINLocValForFuelPosting @oldinco, @oldinlocation, @oldmaterial, null, @oldmatlgroup, @co, @oldequipment, null, null, null, null, null, @errmsg output
        		if @rcode = 1
        			begin
        			select @errtext = isnull(@errorstart,'') + 'INLocation ' + isnull(@oldinlocation,'') + '-' + isnull(@errmsg,'')
        			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
        			if @rcode <> 0
        				begin
        				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
        				goto bspexit
        				end
        			end
        		end
        	
        	-- Validate OldGLTransAcct - can be null.
        	if @oldgltransacct is not null
        		begin
        		exec @rcode = dbo.bspEMGLTransAcctValForFuelPosting @co, @oldgltransacct, @errmsg output
        		if @rcode = 1
        			begin
        			select @errtext = isnull(@errorstart,'') + 'GLTransAcct ' + isnull(@oldgltransacct,'') + '-' + isnull(@errmsg,'')
        			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
        			if @rcode <> 0
        				begin
        				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
        				goto bspexit
        				end
        			end
        		end
        	
        	-- Validate OldGLOffsetAcct - cannot be null if a Reversal transaction.
        	if @oldreversalstatus = 1 and @oldgloffsetacct is null
        		begin
        		select @errtext = isnull(@errorstart,'') + 'OldGLOffsetAcct null-Invalid for Reversal transactions.'
        		exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
        		if @rcode <> 0
        			begin
        			select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
        			goto bspexit
        			end
        		end
        	
        	if @oldgloffsetacct is not null
        		begin
        		exec @rcode = dbo.bspEMGLOffsetAcctValForFuelPosting  @co, @oldinco, @oldgloffsetacct, @oldinlocation, @errmsg output
        		if @rcode = 1
        			begin
        			select @errtext = isnull(@errorstart,'') + 'OldGLOffsetAcct ' + isnull(@oldgloffsetacct,'') + '-' + isnull(@errmsg,'')
        			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
        			if @rcode <> 0
        				begin
        				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
        				goto bspexit
        				end
        			end
        		end
        	
        	-- Verify that OldGLTrans and OldGLOffset accts arent the same.
        	if @oldgltransacct = @oldgloffsetacct 
        		begin
        		select @errtext = isnull(@errorstart,'') + 'OldGLTransAcct and OldGLOffsetAcct cannot be the same!'
        		exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
        		if @rcode <> 0
        			begin
        			select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
        			goto bspexit
        			end
        		end
        	
        	-- Validate OldPerECM - can be null.
        	if @oldperecm is not null and @oldperecm not in ('E','C','M')
        		begin
        		select @errtext = isnull(@errorstart,'') + 'Invalid OldPerECM, must be E, C, or M.'
        		exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
        		if @rcode <> 0
        			begin
        			select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
        			goto bspexit
        			end
        		end
        
        	-- Validate OldINStkECM - can be null.
        	if @oldinstkecm is not null and @oldinstkecm not in ('E','C','M')
        		begin
        		select @errtext = isnull(@errorstart,'') + 'Invalid OldINStkECM, must be E,C, or M.'
        		exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
        		if @rcode <> 0
        			begin
        			select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
        			goto bspexit
        			end
        		end
        	
        	-- Validate OldTaxGroup - can be null.
        	if @oldtaxgroup is not null
        		begin
        		exec @rcode = dbo.bspHQGroupVal @oldtaxgroup, @errmsg output
        		if @rcode = 1
        			begin
        			select @errtext = isnull(@errorstart,'') + 'OldTaxGroup ' + isnull(convert(varchar(5),@oldtaxgroup),'') + '-' + isnull(@errmsg,'')
        			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
        			if @rcode <> 0
        				begin
        				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
        				goto bspexit
        				end
        			end
        		end
        	
        	-- Validate OldTaxCode - can be null.
        	if @oldtaxcode is not null
        		begin
        		exec @rcode = dbo.bspHQTaxCodeValForFuelPosting @oldtaxgroup, null, @oldtaxcode, @errmsg output
        		if @rcode = 1
        			begin
        			select @errtext = isnull(@errorstart,'') + 'OldTaxCode ' + isnull(@oldtaxcode,'') + '-' + isnull(@errmsg,'')
        			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
        			if @rcode <> 0
        				begin
        				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
        				goto bspexit
        				end
        			end
        		end
        	
        	-- Validate OldUM - can be null.
        	if @oldum is not null
        		begin
        		exec @rcode = dbo.bspEMUMValForFuelPosting @co, @oldum, @oldmatlgroup, null, null, null, null, @errmsg output
        		if @rcode = 1
        			begin
        			select @errtext = isnull(@errorstart,'') + 'OldUM ' + isnull(@oldum,'') + '-' + isnull(@errmsg,'')
        			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
        			if @rcode <> 0
        				begin
        				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
        				goto bspexit
        				end
        			end
        		end
        
        	-- Validate OldINStkUM - can be null.
        	if @oldinstkum is not null
        		begin
        		exec @rcode = dbo.bspEMUMValForFuelPosting @co, @oldinstkum, @oldmatlgroup, null, null, null, null, @errmsg output
        		if @rcode = 1
        			begin
        			select @errtext = isnull(@errorstart,'') + 'OldINStkUM ' + isnull(@oldinstkum,'') + '-' + isnull(@errmsg,'')
        			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
        			if @rcode <> 0
        				begin
        				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
        				goto bspexit
        				end
        			end
        		end
   
        	end --if @batchtranstype in ('A','C')
      
   
   bspexit:
   	if @rcode<>0 select @errmsg=isnull(@errmsg,'')	--+ char(13) + char(10) + '[bspEMVal_Cost_SeqVal_Fuel]'
   	return @rcode



GO
GRANT EXECUTE ON  [dbo].[bspEMVal_Cost_SeqVal_Fuel] TO [public]
GO
