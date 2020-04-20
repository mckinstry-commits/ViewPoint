SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE     procedure [dbo].[bspEMVal_Cost_SeqVal_Parts]
/***********************************************************
* CREATED BY: JM 7/9/02 - Ref Issue 17743 - Combination bspEMVal_Cost_AddedChanged and 
*	bspEMVal_Cost_ChangedDeleted for each source, called from bspEMVal_Cost_Main
*
* MODIFIED By :  GG 09/20/02 - #18522 ANSI nulls 
*		JM 10-02-02 -  Ref Issue 18024 - For EMParts Source, validate GLOffsetAcct SubType = 'I' or null
*      		 DANF 10/09/02 - Issue 18879 Correcting GL company for gl account offset validation
*		JM 10-09-02 -  Remove 'rtrim(ltrim(' from GLTransAcct validation against blank (per DF)
*		JM 11-12-02 - Ref Issue 19307 - Corrected update of taxamount, taxbasis, taxrate in olds
*		GF 01/27/02 - Need to update GL trans account for added or changed type.
*		GF 02/27/2003 - issue #20542 EM cost type cannot be null for source 'EMParts'
*		GF 10/23/2003 - issue #22799 - fixes issue #19307 whcih messes up old tax values
*		TV 02/11/04 - 23061 added isnulls 
*		TRL 11/02/07 --Issue 120727, removed trim functions around @oldgltranacct 
*		TRL 07/21/09 --Issue 134218, fixed subledgert type validation with GL Off set Account
*			TRL 09/07/09--Issue 135655 added IsNull(@xxxx,'')<>''
*				TRL 02/04/2010 Issue 137916  change @description to 60 characters
*				GF 01/14/2013 TK-20723 pass material, matl group to IN Location validation for category override GL Account
*
* USAGE:
*	Called by bspEMVal_Cost_Main to run validation applicable only to referenced EMCost Source.
*	
*	Form: EMWOPartsPosting
*	Posting table: bEMBF
*	
*	GLTransAcct must be subtype 'E'
*	GLJrnl = MatlGLJrnl
*	GLLvl = MatlGLLvl
*	
*	Visible bound inputs that use the same valproc here as in DDFI:
*		WorkOrder - dbo.bspEMWOValForPartsPosting
*		WOItem - dbo.bspEMWOItemValForPartsPosting
*		CostCode - dbo.bspEMCostCodeValForPartsPosting
*		EMCostType - dbo.bspEMCostTypeValForFuelPosting
*		INCo - bspINCompanyVal
*		INLocation - dbo.bspINLocValForFuelPosting
*		Material - bspEMWOPartsPostHQMatlVal
*		UM - bspHQUMValWithInfo
*		PartsStatusCode - dbo.bspEMPartsStatusCodeVal
*		TaxCode - dbo.bspHQTaxVal
*		NOTE: If Material is non-taxable, make sure TaxCode, TaxRate, TaxBasis and TaxAmount are null. Otherwise, get the 		
*		TaxRate and TaxBasis, calc the TaxAmount, and update bEMBF.
*	
*	Hidden bound inputs without valprocs in DDFI that receive basic validation here:
*		Equipment - dbo.bspEMEquipVal
*		ComponentTypeCode - bspEMComponentTypeCodeVal
*		Component - dbo.bspEMComponentVal
*		EMGroup - dbo.bspHQGroupVal
*		MatlGroup - dbo.bspHQGroupVal
*		GLCo -dbo.bspGLCompanyVal
*		PerECM - ' E', 'C' or 'M'
*		Source = 'EMParts'
*		EMTransType = 'Parts'
*		GLTransAcct - dbo.bspGLACfPostable and cannot be blank
*		GLOffsetAcct - dbo.bspGLACfPostable and cannot be null
*		GLTransAcct cannot = GLOffsetAcct 
*		TaxGroup - dbo.bspHQGroupVal
*		Units must not be null
*		UnitPrice must not be null
*		Dollars must not be null
*	
*	Bound inputs that do not receive validation here:
*		CurrentOdometer
*		CurrentHourMeter
*		BatchTransType
*		ActualDate
*		Description	
*		SerialNo
*		CurrentTotalOdometer
*		CurrentTotalHourMeter
*		TaxBasis
*		TaxRate
*		TaxAmount
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
@co bCompany,@mth bMonth,@batchid bBatchID,@batchseq int,@errmsg varchar(255) output

as

set nocount on

/* General decs */
declare @errorstart varchar(50), @errtext varchar(255), @gljrnl bJrnl, @gllvl tinyint, @glsubtype char(1), @rcode int 
/* bEMBF non-Olds decs */
declare @actualdate bDate, @batchtranstype char(1), @component bEquip, @componenttypecode varchar(10), @costcode bCostCode, @currenthourmeter bHrs, 
@currentodometer bHrs, @currenttotalhourmeter bHrs, @currenttotalodometer bHrs, @dollars bDollar, @emcosttype bEMCType, @emgroup bGroup,
@emtrans bTrans, @emtranstype varchar(10), @equipment bEquip,@glco bCompany,  @gloffsetacct bGLAcct, @gltransacct bGLAcct, 
@inco bCompany, @inlocation bLoc, @material bMatl, @matlgroup bGroup, @partsstatuscode varchar(10), @perecm char(1), 
@reversalstatus tinyint, @serialno varchar(20), @source varchar(10), @taxamount bDollar, @taxbasis bDollar, @taxcode bTaxCode, @taxgroup bGroup, 
@taxrate bRate, @um bUM, @unitprice bUnitCost, @units bUnits, @woitem bItem, @workorder bWO
/* bEMBF Olds decs */
declare @oldactualdate bDate, @oldbatchtranstype  char(1), @oldcomponent bEquip, @oldcomponenttypecode varchar(10), @oldcostcode bCostCode, 
@oldcurrenthourmeter bHrs, @oldcurrentodometer bHrs, @oldcurrenttotalhourmeter bHrs, @oldcurrenttotalodometer bHrs, @olddescription bItemDesc/*137916*/, 
@olddollars bDollar, @oldemcosttype bEMCType, @oldemgroup bGroup,@oldemtrans bTrans, @oldemtranstype varchar(10), @oldequipment bEquip,
@oldglco bCompany, @oldgloffsetacct bGLAcct, @oldgltransacct bGLAcct, @oldinco bCompany, @oldinlocation bLoc, @oldmaterial bMatl, 
@oldmatlgroup bGroup, @oldpartsstatuscode varchar(10), @oldperecm char(1), @oldreversalstatus tinyint, @oldserialno varchar(20), @oldsource varchar(10), 
@oldtaxamount bDollar, @oldtaxbasis bDollar, @oldtaxcode bTaxCode, @oldtaxgroup bGroup, @oldtaxrate bRate, @oldum bUM, @oldunitprice bUnitCost,  
@oldunits bUnits, @oldwoitem bItem, @oldworkorder bWO
/* bEMCD decs */
declare @emcdactualdate bDate, @emcdcomponent bEquip,  @emcdcomponenttypecode varchar(10),  @emcdcostcode bCostCode, @emcdcurrenthourmeter bHrs,
@emcdcurrentodometer bHrs, @emcdcurrenttotalhourmeter bHrs, @emcdcurrenttotalodometer bHrs, @emcddescription bItemDesc/*137916*/, @emcddollars bDollar,
@emcdemcosttype bEMCType, @emcdemgroup bGroup, @emcdemtrans bTrans, @emcdemtranstype varchar(10), @emcdequipment bEquip, @emcdglco bCompany, 
@emcdgloffsetacct bGLAcct, @emcdgltransacct bGLAcct, @emcdinco bCompany, @emcdinlocation bLoc, @emcdinusebatchid bBatchID, @emcdmaterial bMatl, 
@emcdmatlgroup bGroup, @emcdperecm bECM, @emcdreversalstatus tinyint, @emcdserialno varchar(20), @emcdsource varchar(10), @emcdtaxamount bDollar, 
@emcdtaxbasis bDollar, @emcdtaxgroup bGroup, @emcdtaxrate bRate, @emcdum bUM, @emcdunitprice bUnitCost, @emcdunits bUnits, @emcdwoitem bItem, 
@emcdworkorder bWO

declare @offglco bCompany, @inglco bCompany

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
@costcode = CostCode, @currenthourmeter = CurrentHourMeter, @currentodometer = CurrentOdometer, @currenttotalhourmeter = CurrentTotalHourMeter, 
@currenttotalodometer = CurrentTotalOdometer, @dollars = Dollars, @emcosttype = EMCostType, @emgroup = EMGroup, @emtrans = EMTrans, 
@emtranstype = EMTransType, @equipment  = Equipment, @glco =GLCo,  @gloffsetacct = GLOffsetAcct, 
@gltransacct = GLTransAcct, @inco = INCo, @inlocation = INLocation, @material = Material, @matlgroup = MatlGroup, @partsstatuscode = PartsStatusCode, 
@perecm = PerECM, 	@reversalstatus = ReversalStatus, @serialno = SerialNo, @source = rtrim(Source), @taxamount = TaxAmount, @taxbasis = TaxBasis, 
@taxcode = TaxCode, @taxgroup = TaxGroup, @taxrate = TaxRate, @um = UM, @unitprice = UnitPrice, @units = Units, @woitem = WOItem, @workorder = WorkOrder,
@oldactualdate = OldActualDate, @oldbatchtranstype  = OldBatchTransType, @oldcomponent = OldComponent, @oldcomponenttypecode = OldComponentTypeCode, 
@oldcostcode = OldCostCode, @oldcurrenthourmeter = OldCurrentHourMeter, @oldcurrentodometer = OldCurrentOdometer, 
@oldcurrenttotalhourmeter = OldCurrentTotalHourMeter, @oldcurrenttotalodometer = OldCurrentTotalOdometer, @olddescription = OldDescription, 
@olddollars = OldDollars, @oldemcosttype = OldEMCostType, @oldemgroup = OldEMGroup,@oldemtrans = OldEMTrans, @oldemtranstype = OldEMTransType, 
@oldequipment = OldEquipment, @oldglco = OldGLCo, @oldgloffsetacct = OldGLOffsetAcct, @oldgltransacct = OldGLTransAcct, @oldinco = OldINCo, 
@oldinlocation = OldINLocation, @oldmaterial = OldMaterial, @oldmatlgroup = OldMatlGroup, @oldpartsstatuscode = OldPartsStatusCode, 
@oldperecm = OldPerECM, @oldreversalstatus = OldReversalStatus, @oldserialno = OldSerialNo, @oldsource = rtrim(OldSource), @oldtaxamount = OldTaxAmount, 
@oldtaxbasis = OldTaxBasis, @oldtaxcode = OldTaxCode, @oldtaxgroup = OldTaxGroup, @oldtaxrate = OldTaxRate, @oldum = OldUM, @oldunitprice = OldUnitPrice, 
@oldunits = OldUnits, @oldwoitem = OldWOItem, @oldworkorder = OldWorkOrder
from bEMBF where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq

/* Setup @errorstart string. */
select @errorstart = 'Seq ' + isnull(convert(varchar(9),@batchseq),'') + '-'

---------------All BatchTransTypes
/* Validate GLJrnl in bEMCO GLLvl <> NoUpdate - can be null in bEMCO but cannot be null in bGLDT.
Need to do this validation record-by-record because EMAdj sources can have EMTransType = 'Fuel' which uses a
different GL set than all other EMAdj EMTransTypes. */
-- Valide GLJrnl
select @gljrnl = MatlGLJrnl, @glco = GLCo,	@gllvl  = MatlGLLvl from bEMCO where EMCo = @co
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

/* Validate Source */
if @source <> 'EMParts'
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
if @emtranstype <> 'Parts'
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

/* Verify UnitPrice not null. */
if @unitprice is null 
begin
	select @errtext = isnull(@errorstart,'') + 'Invalid UnitPrice, must be not null.'
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

-- validate cost type is not null
if @emcosttype is null
begin
	select @errtext = isnull(@errorstart,'') + 'Invalid Cost Type, must be not null.'
	exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
	if @rcode <> 0
	begin
		select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
		goto bspexit
	end
end

-- Validate INCo - can be null.
if @inco is not null
begin
	exec @rcode = dbo.bspINCompanyVal @inco, @inglco output, @errmsg output
	if @rcode = 1
	begin
		select @errtext = isnull(@errorstart,'') + 'INCo ' + isnull(convert(varchar(3),@inco),'') + '-' + isnull(@errmsg,'')
		exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
		if @rcode <> 0
		begin
			select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
			goto bspexit
		end
	end
end

/* Set Gl Expense Company from IN is location or EM if there is no location */
select @offglco = @glco

-- Validate INLocation - can be null.
/*135655*/
if isnull(@inlocation ,'')<>'' 
--if @inlocation is not null
begin
	select @offglco = @inglco
	----TK-20723
	exec @rcode = dbo.bspINLocValForFuelPosting @inco, @inlocation, @material, null, @matlgroup, @co, @equipment, null, null, 
	null, null, null, @errmsg output
	if @rcode = 1
	begin
		select @errtext = isnull(@errorstart,'') + 'INLocation ' + isnull(@inlocation,'') + '-' + isnull(@errmsg,'')
		exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
		if @rcode <> 0
		begin
			select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
			goto bspexit
		end
	end
end

-- Ref Issue 18024 - For EMParts Source, validate GLOffsetAcct SubType = 'I' or null
/*START Issue 134218*/ 
select @glsubtype =  SubType From dbo.GLAC with(nolock) where GLCo = @offglco and GLAcct = @gloffsetacct
if  @inco is not null and isnull(@inlocation,'') <> ''
	begin 
		if @glsubtype <> 'I' and isnull(@glsubtype,'')<>''
		begin
			select @errtext = 'GLOffsetAcct: ' + isnull(convert(varchar(20),@gloffsetacct),'') + '	 has a Subledger Type: ' + isnull(@glsubtype,'') + '. Must = I or null!'
			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
			if @rcode <> 0
			begin
				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
				goto bspexit
			end
		end
	end
else
	BEGIN
		if @glsubtype <> 'E' and isnull(@glsubtype,'')<>''
		begin
			select @errtext = 'GLOffsetAcct: ' + isnull(convert(varchar(20),@gloffsetacct),'') + '	 has a Subledger Type: ' + isnull(@glsubtype,'') + '. Must = E or null!'
			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
			if @rcode <> 0
			begin
				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
				goto bspexit
			end
		end
	END
/*START Issue 134218*/ 

-- Validate GLTransAcct SubType = 'E'
select @glsubtype = SubType From dbo.GLAC with(nolock) where GLCo = @glco and GLAcct = @gltransacct
if @glsubtype <> 'E' and isnull(@glsubtype,'')<>''/* @glsubtype is not null		-- #18522*/
begin
	select @errtext = 'GL Account: ' + isnull(convert(varchar(20),@gltransacct),'') + ' has a Subledger Type: ' + isnull(@glsubtype,'') + '. Must be E or null!'
	exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
	if @rcode <> 0
	begin
		select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
		goto bspexit
	end
end
/*END Issue 134218*/  

---------------BatchTransType = A & C---------------
if @batchtranstype in ('A', 'C')
begin
	/* First run through visible bound inputs on EMWOPartsPosting and use the same valproc here as in DDFI */
	/* Validate WorkOrder - can be null. */
	/*135655*/
	if isnull(@workorder,'')<>''
	begin
		exec @rcode = dbo.bspEMWOValForPartsPosting @co, @workorder, @inlocation, null, null, null, null, null, 
		null, @errmsg output
		if @rcode = 1
		begin
			select @errtext = isnull(@errorstart,'') + 'WorkOrder ' + isnull(@workorder,'') + '-' + isnull(@errmsg,'')
			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
			if @rcode <> 0
			begin
				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
				goto bspexit
			end
		end
	end

	/* Validate WOItem - can be null. */
	if @woitem is not null
	begin
		exec @rcode = dbo.bspEMWOItemValForPartsPosting @co, @workorder, @woitem, @equipment, 
		null, null, null, null, null, null, null, null,null,null,null,null, @errmsg output
		if @rcode = 1
		begin
			select @errtext = isnull(@errorstart,'') + 'WOItem ' + isnull(convert(varchar(5),@woitem),'') + '-' + isnull(@errmsg,'')
			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
			if @rcode <> 0
			begin
				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
				goto bspexit
			end
		end
	end

	/* Validate CostCode - can be null. */
	/*135655*/
	if isnull(@costcode,'')<>''
	begin
		-- changed to return @gltransacct
		--exec @rcode = dbo.bspEMCostCodeValForPartsPosting @co, @emgroup, @costcode, @equipment, @gltransacct,
		--		@emcosttype, @workorder, @woitem, null, @errmsg output
		exec @rcode = dbo.bspEMCostCodeValForPartsPosting @co, @emgroup, @costcode, @equipment, @gltransacct,
		@emcosttype, @workorder, @woitem, @gltransacct output, @errmsg output
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
		-- update gl accounts in bEMBF
		update bEMBF set GLTransAcct = @gltransacct
		where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
	end

	/* Validate EMCostType - can be null. */
	if @emcosttype is not null
	begin
		exec @rcode = dbo.bspEMCostTypeValForFuelPosting @co, @emgroup, @equipment, @costcode, @emcosttype, null, null, null, @errmsg output
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

	/* Validate Material - can be null. */
	/*135655*/
	if isnull(@material,'')<>''
	begin
		exec @rcode = dbo.bspEMMatlValForFuelPosting @co, @equipment, @matlgroup, @material, @um, @inco, @inlocation, 
		null, null, null, null,null, null, null, @errmsg output
		if @rcode = 1
			begin
			select @errtext = isnull(@errorstart,'') + 'Material ' + isnull(@material,'') + '-' + isnull(@errmsg,'')
			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
			if @rcode <> 0
			begin
				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
				goto bspexit
			end
		end
	end --if @material is not null

	/* Validate UM - can be null. */
	/*135655*/
	if isnull(@um,'')<>''
	begin
		exec @rcode = dbo.bspHQUMValWithInfoForEM @co, @emtranstype, @um, @matlgroup, @material, @inco, @inlocation, null, @errmsg output
		if @rcode = 1
		begin
			select @errtext = isnull(@errorstart,'') + 'UM ' + isnull(@um,'') + '-' + isnull(@errmsg,'')
			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
			if @rcode <> 0
			begin
				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
				goto bspexit
			end
		end
	end

	/* Validate PartsStatusCode - can be null. */
	/*135655*/
	if isnull(@partsstatuscode,'')<>''
	begin
		exec @rcode = dbo.bspEMPartsStatusCodeVal @emgroup, @partsstatuscode, @errmsg output
		if @rcode = 1
		begin
			select @errtext = isnull(@errorstart,'') + 'PartsStatusCode ' + isnull(@partsstatuscode,'') + '-' + isnull(@errmsg,'')
			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
			if @rcode <> 0
			begin
				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
				goto bspexit
			end
		end
	end

	/* Validate TaxCode - can be null. Also pull TaxRate, calculate TaxAmount assuming TaxBasis = bEMBF.TotalCost, and update bEMBF.*/
	/*135655*/
	if isnull(@taxcode,'')<>''
		begin
			/* Use a basic validation even though it is different that the one on the form since other work is done below */
			exec @rcode = dbo.bspHQTaxVal @taxgroup, @taxcode, @errmsg output
			if @rcode = 1
				begin
					select @errtext = isnull(@errorstart,'') + 'TaxCode ' + isnull(@taxcode,'') + '-' + isnull(@errmsg,'')
					exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
					if @rcode <> 0
					begin
						select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
						goto bspexit
					end
				end
				/* If Material is non-taxable, make sure @taxcode, @taxrate, @taxbasis and @taxamount are null. 
				Otherwise, get the TaxRate and TaxBasis, calc the TaxAmount, and update bEMBF. */
				if (select Taxable from bHQMT where MatlGroup = @matlgroup and Material = @material) = 'N'
				begin 
					select @taxcode = null, @taxrate = null, @taxbasis = null, @taxamount = null
				end
			else
				begin
					/* Pull TaxRate from bHQTX and calculate TaxAmount assuming TaxBasis = bEMBF.TotalCost. */
					exec @rcode = dbo.bspHQTaxRateGet @taxgroup, @taxcode, @actualdate, @taxrate output, null, null, @errmsg output
					if @rcode <> 0
					begin
						select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
						goto bspexit
					end
					-- select @taxbasis = Dollars from #ValRec - remmed out - no #ValRec
					select @taxamount = @taxrate * @taxbasis
				end
			/* Update bEMBF. */
			update bEMBF set TaxRate = @taxrate, TaxBasis = @taxbasis, TaxAmount = @taxamount 
			where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
		end 
		--if @taxcode is not null
	else 
		-- @taxcode is null
		begin
			/* Make sure @taxrate, @taxbasis and @taxamount are null and update bEMBF. */
			select @taxrate = null, @taxbasis = null, @taxamount = null
			update bEMBF set TaxRate = @taxrate, TaxBasis = @taxbasis, TaxAmount = @taxamount 
			where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
		end

	/* Next run through hidden bound inputs on EMWOPartsPosting that aren't validated through DDFI, using a basic validation.
	These include Equipment, Component, EMGroup, MatlGroup, GLCo, PerECM, GLTransAcct, GLOffsetAcct, TaxGroup*/
	/* Validate Equipment - can be null. */
	--if @equipment is not null
	if isnull(@equipment,'')<>''
	begin
		exec @rcode = dbo.bspEMEquipVal @co, @equipment, @errmsg output
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
	end

	/* Validate Component - can be null. */
	--if @component is not null
	if isnull(@component,'')<>''
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

	/* Validate EMGroup - can be null. */
	if @emgroup is not null
	begin
		exec @rcode = dbo.bspHQGroupVal @emgroup, @errmsg output
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

	/* Validate MatlGroup - can be null. */
	if @matlgroup is not null
	begin
		exec @rcode = dbo.bspHQGroupVal @matlgroup, @errmsg output
		if @rcode = 1
		begin
			select @errtext = isnull(@errorstart,'') + 'MatlGroup ' + isnull(convert(varchar(5),@matlgroup),'') + '-' + isnull(@errmsg,'')
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
		exec @rcode =dbo.bspGLCompanyVal @glco, @errmsg output
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

	/* Validate PerECM - can be null. */
	if @perecm is not null and @perecm not in ('E','C','M')
	begin
		select @errtext = isnull(@errorstart,'') + 'Invalid PerECM, must be E,C, or M.'
		exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
		if @rcode <> 0
		begin
			select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
			goto bspexit
		end
	end

	/* Validate ComponentTypeCode - can be null. */
	/*135655*/
	if isnull(@componenttypecode ,'')<>''
	begin
		exec @rcode = dbo.bspEMComponentTypeCodeVal @co, @componenttypecode, @component, @equipment, @emgroup, null, null, @errmsg output
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

	-- Validate GLTransAcct - can be null
	if @gltransacct  is not null
	begin
		If isnull(@gltransacct,'') = ''
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
		/* Issue 134218*/
		select @glsubtype = SubType From bGLAC where GLCo = @glco and GLAcct = @gloffsetacct
		exec @rcode = dbo.bspGLACfPostable @glco, @gltransacct, 'E', @errmsg output
		if @rcode = 1
		begin
			select @errtext = isnull(@errorstart,'') + 'GLTransAcct ' + isnull(@gltransacct,'') + '-' + isnull(@errmsg ,'')
			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
			if @rcode <> 0
			begin
				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
				goto bspexit
			end
		end
	end --if @gltransacct is not null

	/* Validate GLOffsetAcct */
	/* GLOffsetAcct cannot be null if a Parts Posting transaction. Ref Issue 5466. */
	/*135655*/
	if isnull(@gloffsetacct ,'')=''
	begin
		select @errtext = isnull(@errorstart,'') + 'GLOffsetAcct cannot be null for WOPartsPosting.'
		exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
		if @rcode <> 0
		begin
			select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
			goto bspexit
		end
	end

	/* If GLOffsetAcct not null, run basic validation. */
	if isnull(@gloffsetacct ,'')<>''
	begin
		/*START Issue 134218*/
		select @glsubtype = SubType From bGLAC where GLCo = @glco and GLAcct = @gloffsetacct
		/* Use CheckSubType 'I' for WOPartsPosting per DianaR */
		exec @rcode = dbo.bspGLACfPostable  @offglco, @gloffsetacct, @glsubtype, @errmsg output
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
	/*START END Issue 134218*/

	/* Verify that GLTrans and GLOffset accts arent the same. */
	if @gltransacct = @gloffsetacct
	begin
		select @errtext = isnull(@errorstart,'') + 'Transaction and Offset accts cannot be the same!'
		exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
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
			exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
			if @rcode <> 0
			begin
				select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
				goto bspexit
			end
		end
	end

	/* Validate ReversalStatus - can be null.
	If null convert to 0; otherwise must be 0, 1, 2, 3, 4 */
	if @reversalstatus is null
		begin
			update bEMBF set ReversalStatus = 0 where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
		end
	else
		begin
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
		end
end --if @batchtranstype in ('A'  or 'C')

---------------BatchTransType = C & D---------------
if @batchtranstype in ('C','D')
begin

/* Verify values in bEMCD match Old's in bEMBF. */
/* Get existing values from EMCD. */
select @emcdactualdate = ActualDate, @emcdcomponent = Component, @emcdcomponenttypecode = ComponentTypeCode, @emcdcostcode = CostCode, 
@emcdcurrenthourmeter = CurrentHourMeter, @emcdcurrentodometer = CurrentOdometer, @emcdcurrenttotalhourmeter = CurrentTotalHourMeter, 
@emcdcurrenttotalodometer = CurrentTotalOdometer, @emcddescription = Description, @emcddollars = Dollars, @emcdemcosttype = EMCostType, 
@emcdemgroup = EMGroup, @emcdemtrans = EMTrans, @emcdemtranstype = EMTransType, @emcdequipment = Equipment, @emcdglco = GLCo, 
@emcdgloffsetacct = GLOffsetAcct, @emcdgltransacct = GLTransAcct, @emcdinco = INCo, @emcdinlocation = INLocation, @emcdinusebatchid = InUseBatchID, 
@emcdmaterial = Material, @emcdmatlgroup = MatlGroup, @emcdperecm = PerECM, @emcdreversalstatus = ReversalStatus, @emcdserialno = SerialNo, 
@emcdsource = Source, @emcdtaxamount = TaxAmount, 	@emcdtaxbasis = TaxBasis, @emcdtaxgroup = TaxGroup, @emcdtaxrate = TaxRate, 
@emcdum = UM, @emcdunitprice = UnitPrice, @emcdunits = Units, @emcdwoitem = WOItem, @emcdworkorder = WorkOrder
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
or isnull(@emcdtaxgroup,0) <> isnull(@oldtaxgroup,0)
or isnull(@emcdtaxrate,0) <> isnull(@oldtaxrate,0)
or isnull(@emcdum,'') <> isnull(@oldum,'')
or @emcdunitprice <> @oldunitprice
or @emcdunits <> @oldunits
or isnull(@emcdwoitem,0) <> isnull(@oldwoitem,0)
or isnull(@emcdworkorder,'') <> isnull(@oldworkorder,'')
begin
	select @errtext = isnull(@errorstart,'') + '-Batch Old info does not match EM Cost Detail.'
	exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
	if @rcode <> 0
	begin
		select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
		goto bspexit
	end
end

/* First run through visible bound inputs on EMWOPartsPosting and use the same valproc here as in DDFI */
/* Validate OldWorkOrder - can be null. */
/*135655*/
if isnull(@oldworkorder ,'')<>''
begin
	exec @rcode = dbo.bspEMWOValForPartsPosting @co, @oldworkorder,@oldinlocation, null, null, null, null, null, 
	null, @errmsg output
	if @rcode = 1
	begin
		select @errtext = isnull(@errorstart,'') + 'OldWorkOrder ' + isnull(@oldworkorder,'') + '-' + isnull(@errmsg,'')
		exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
		if @rcode <> 0
		begin
			select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
			goto bspexit
		end
	end
end

/* Validate OldWOItem - can be null. */
if @oldwoitem is not null
begin
	exec @rcode = dbo.bspEMWOItemValForPartsPosting @co, @oldworkorder, @oldwoitem, @oldequipment,
	null, null, null, null, null,null, null, null, null,  null, null,null,@errmsg output
	if @rcode = 1
	begin
		select @errtext = isnull(@errorstart,'') + 'OldWOItem ' + isnull(convert(varchar(5),@oldwoitem),'')+ '-' + isnull(@errmsg,'')
		exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
		if @rcode <> 0
		begin
			select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
			goto bspexit
		end
	end
end

/* Validate OldCostCode - can be null. */
/*135655*/
if isnull(@oldcostcode ,'')<>''
begin
	exec @rcode = dbo.bspEMCostCodeValForPartsPosting @co, @oldemgroup, @oldcostcode, @oldequipment, @oldgltransacct, @oldemcosttype, 
	@oldworkorder, @oldwoitem, null, @errmsg output
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
	exec @rcode = dbo.bspEMCostTypeValForFuelPosting @co, @oldemgroup, @oldequipment, @oldcostcode, @oldemcosttype, null, null, 
	null, @errmsg output
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

/* Validate OldINCo - can be null. */
if @oldinco is not null
begin
	exec @rcode = dbo.bspINCompanyVal @oldinco, @inglco output, @errmsg output
	if @rcode = 1
	begin
		select @errtext = isnull(@errorstart,'') + 'OldINCo ' + isnull(convert(varchar(3),@inco),'') + '-' + isnull(@errmsg,'')
		exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
		if @rcode <> 0
		begin
			select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
			goto bspexit
		end
	end
end

/* Set Gl Expense Company from IN is location or EM if there is no location */
select @offglco = @oldglco

-- Validate OldINLocation - can be null.
/*135655*/
if isnull(@oldinlocation,'')<>''
begin
	select @offglco = @inglco
	----TK-20723
	exec @rcode = dbo.bspINLocValForFuelPosting @oldinco, @oldinlocation, @oldmaterial, null, @oldmatlgroup, @co, @oldequipment, null, null, 
	null, null, null, @errmsg output
	if @rcode = 1
	begin
		select @errtext = isnull(@errorstart,'') + 'OldINLocation ' + isnull(@oldinlocation,'') + '-' + isnull(@errmsg,'')
		exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
		if @rcode <> 0
		begin
			select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
			goto bspexit
		end
	end
end

/* Validate OldMaterial - can be null. */
/*135655*/
if isnull(@oldmaterial,'')<>''
begin
	exec @rcode = dbo.bspEMMatlValForFuelPosting @co, @oldequipment, @oldmatlgroup, @oldmaterial, @oldum, @oldinco, @oldinlocation, 
	null, null, null, null,null, null, null, @errmsg output
	if @rcode = 1
	begin
		select @errtext = isnull(@errorstart,'') + 'OldMaterial ' + isnull(@oldmaterial,'') + '-' + isnull(@errmsg,'')
		exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
		if @rcode <> 0
		begin
			select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
			goto bspexit
		end
	end
end --if @material is not null

/* Validate OldUM - can be null. */
/*135655*/
if isnull(@oldum,'')<>''
begin
	exec @rcode = dbo.bspHQUMValWithInfoForEM @co, @oldemtranstype, @oldum, @oldmatlgroup, @oldmaterial, @oldinco, @oldinlocation, null, @errmsg output
	if @rcode = 1
	begin
		select @errtext = isnull(@errorstart,'') + 'OldUM ' + isnull(@oldum,'') + '-' + isnull(@errmsg,'')
		exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
		if @rcode <> 0
		begin
			select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
			goto bspexit
		end
	end
end

/* Validate OldPartsStatusCode - can be null. */
/*135655*/
if isnull(@oldpartsstatuscode,'')<>''
begin
	exec @rcode = dbo.bspEMPartsStatusCodeVal @oldemgroup, @oldpartsstatuscode, @errmsg output
	if @rcode = 1
	begin
		select @errtext = isnull(@errorstart,'') + 'OldPartsStatusCode ' + isnull(@oldpartsstatuscode,'') + '-' + isnull(@errmsg,'')
		exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
		if @rcode <> 0
		begin
			select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
			goto bspexit
		end
	end
end

/* Validate OldTaxCode - can be null. Also pull OldTaxRate, calculate OldTaxAmount assuming OldTaxBasis = bEMBF.TotalCost, and update bEMBF.*/
/*135655*/
if isnull(@oldtaxcode ,'')<>''
begin
	/* Use a basic validation even though it is different that the one on the form since other work is done below */
	exec @rcode = dbo.bspHQTaxVal @oldtaxgroup, @oldtaxcode, @errmsg output
	if @rcode = 1
	begin
		select @errtext = isnull(@errorstart,'') + 'OldTaxCode ' + isnull(@oldtaxcode,'') + '-' + isnull(@errmsg,'')
		exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
		if @rcode <> 0
		begin
			select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
			goto bspexit
		end
	end
end

/*
-- If Material is non-taxable, make sure @taxcode, @taxrate, @taxbasis and @taxamount are null. 
-- Otherwise, get the TaxRate and TaxBasis, calc the TaxAmount, and update bEMBF.
if (select Taxable from bHQMT where MatlGroup = @oldmatlgroup and Material = @oldmaterial) = 'N'
select @oldtaxcode = null, @oldtaxrate = null, @oldtaxbasis = null, @oldtaxamount = null
else
begin
-- Pull TaxRate from bHQTX and calculate TaxAmount assuming TaxBasis = bEMBF.TotalCost.
exec @rcode = dbo.bspHQTaxRateGet @oldtaxgroup, @oldtaxcode, @oldactualdate, @oldtaxrate output, null, null, @errmsg output
if @rcode <> 0
begin
select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
goto bspexit
end
--select @oldtaxbasis = Dollars from #ValRec  - remmed out - no #ValRec
select @oldtaxamount = @oldtaxrate * @oldtaxbasis
end
-- Update bEMBF.
update bEMBF set OldTaxRate = @oldtaxrate, OldTaxBasis = @oldtaxbasis, OldTaxAmount = @oldtaxamount 
where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
end --if @taxcode is not null
else -- @oldtaxcode is null
begin
-- Smake sure @oldtaxrate, @oldtaxbasis and @oldtaxamount are null and update bEMBF.
select @oldtaxrate = null, @oldtaxbasis = null, @oldtaxamount = null
update bEMBF set OldTaxRate = @oldtaxrate, OldTaxBasis = @oldtaxbasis, OldTaxAmount = @oldtaxamount 
where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
end
*/

/* Next run through hidden bound inputs on EMWOPartsPosting that aren't validated through DDFI, using a basic validation.
These include Equipment, Component, EMGroup, MatlGroup, GLCo, PerECM, GLTransAcct, GLOffsetAcct, TaxGroup*/

/* Validate OldEquipment - can be null. */
if isnull(@oldequipment ,'')<>''
begin
	exec @rcode = dbo.bspEMEquipVal @co, @oldequipment, @errmsg output
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
end

/* Validate OldComponent - can be null. */
if isnull(@oldcomponent ,'')<>''
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

/* Validate OldMatlGroup - can be null. */
if @oldmatlgroup is not null
begin
	exec @rcode = dbo.bspHQGroupVal @oldmatlgroup, @errmsg output
	if @rcode = 1
	begin
		select @errtext = isnull(@errorstart,'') + 'OldMatlGroup ' + isnull(convert(varchar(5),@oldmatlgroup),'') + '-' + isnull(@errmsg,'')
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
	exec @rcode =dbo.bspGLCompanyVal @oldglco, @errmsg output
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

/* Validate OldPerECM - can be null. */
if @oldperecm is not null and @oldperecm not in ('E','C','M')
begin
	select @errtext = isnull(@errorstart,'') + 'Invalid OldPerECM, must be E,C, or M.'
	exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
	if @rcode <> 0
	begin
		select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
		goto bspexit
	end
end



/* Validate OldComponentTypeCode - can be null. */
/*135655*/
if isnull(@oldcomponenttypecode,'')<>''
begin
	exec @rcode = dbo.bspEMComponentTypeCodeVal @co, @oldcomponenttypecode, @oldcomponent, @oldequipment, @oldemgroup, null, null, @errmsg output
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

/* Validate OldGLTransAcct - can be null */
/* Ref Issue 14064 - JM - Check for blank GLTransAcct */
/*135655*/
--Issue 120727
	--select @oldgltransacct = rtrim(ltrim(@oldgltransacct))
if IsNull(@oldgltransacct,'') = ''
begin
	select @errtext = isnull(@errorstart,'') + 'OldGLTransAcct blank.'
	exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
	if @rcode <> 0
	begin
		select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
		goto bspexit
	end
end

if isnull(@oldgltransacct,'')<>''
begin
	/* Use CheckSubType 'E' for WOPartsPosting per DianaR */
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
/* OldGLOffsetAcct cannot be null if a Parts Posting transaction. Ref Issue 5466. */
/*135655*/
if isnull(@oldgloffsetacct ,'')=''
begin
	select @errtext = isnull(@errorstart,'') + 'OldGLOffsetAcct cannot be null for WOPartsPosting.'
	exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
	if @rcode <> 0
	begin
		select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
		goto bspexit
	end
end
/* If OldGLOffsetAcct not null, run basic validation. */
/*135655*/
if isnull(@oldgloffsetacct ,'')<>''
begin
	/* Use CheckSubType 'I' for WOPartsPosting per DianaR */
	/*Issue 134218*/
	select @glsubtype = SubType From bGLAC where GLCo = @glco and GLAcct = @gloffsetacct
	exec @rcode = dbo.bspGLACfPostable  @offglco, @oldgloffsetacct, @glsubtype, @errmsg output
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
	select @errtext = isnull(@errorstart,'') + 'OldTransaction and OldOffset accts cannot be the same!'
	exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
	if @rcode <> 0
	begin
		select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
		goto bspexit
	end
end

/* Validate OldTaxGroup - can be null. */
if @oldtaxgroup is not null
begin
	exec @rcode = dbo.bspHQGroupVal @oldtaxgroup, @errmsg output
	if @rcode = 1         
	begin
		select @errtext = isnull(@errorstart,'') + 'OldTaxGroup ' + isnull(convert(varchar(5),@oldtaxgroup),'') + '-' + isnull(@errmsg,'')
		exec @rcode =dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
		if @rcode <> 0
		begin
			select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
			goto bspexit
		end
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
if @rcode<>0 
begin
	select @errmsg=isnull(@errmsg,'')	--+ char(13) + char(10) + '[bspEMVal_Cost_SeqVal_Parts]'
end
return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspEMVal_Cost_SeqVal_Parts] TO [public]
GO
