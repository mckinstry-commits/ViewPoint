SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMVal_Cost_Main    Script Date: 1/17/2002 10:19:18 AM ******/
CREATE         procedure [dbo].[bspEMVal_Cost_Main]
/***********************************************************
* CREATED BY: JM 2/5/99
* MODIFIED By : JM 4/7/99 - Broke out major sections into subroutines.
*	JM 4/25/99 - Added validation of bEMCO.AdjstGLJrnl/MatlGLJrnl
*				since this column cannot be null in bGLDT where it is
*				eventually posted but can be null in bEMCO.
*   ae 9/3/99  Added EMAlloc
*   JM 12/29/99 - Activated call to bspEMVal_Cost_EMIN_Inserts.
*   JM 1/5/00 - Added restriction to call to bspEMVal_Cost_EMIN_Inserts
*             for INLoc not null only.
*   ae 1/28/00 Added EMDepr and EMAlloc changed to EMAdj Batch, type Alloc.
*   JM 2/22/00 Changed selection of GLJrnl and GLLvl for Source = EMAdj & EMFuel.
*   JM 2/23/00 Moved validation of GL info to record level (inside loop).
*   Danf 04/07/00 Added validation for Source EMTime.
*   DANF 06/19/00 Added Inventory updates.
*   GG 11/27/00 - changed datatype from bAPRef to bAPReference
*   DANF 12/19/00 - Added check for Old Inventory
*	TV 06/21/01	- Validate the sub type of GL account to null or 'E'
*	09/17/01 JM - Changed creation method for temp tables from 'select * into' to discrete declaration
*	of specific fields. Also changed inserts into temp tables to discrete declaration of fields. 
*	Ref Issue 14227.
*	JM 7/9/02 - Redesign of proc nesting by Source per Issue 17743.
*   GF 10/04/2002 - Added update of reversal status to zero if null in batch.
*	TV 02/11/04 - 23061 added isnulls
*	TRL 06/04/08 -- Issue 126940 Update procedure, removed begin while statement and added local cursor
*	TRL 12/01/08 -- Issue 131264 removed Reversal = 0 from cursor restriction
*	DAN SO 01/29/09 -- Issue 131478 - Source 'EMAdj', 'EMAlloc', and 'EMDepr to be processed in same batch
*   GF 02/01/2010 - issue #132064 set previous hour meter and previous odometer to zero.
*
*
*
*
* USAGE:
* 	Validates each entry in bEMBF for a selected EM Cost
*	batch (Source = 'EMAdj', 'EMParts', 'EMTime', 'EMDepr', 'EMAlloc'
*	'EMFuel') - must be called prior to posting the batch.
*
* 	After initial Batch and EM checks, bHQBC Status set to 1
*	(validation in progress), bHQBE (Batch Errors), and bEMGL
*	(EM GL Batch) entries are deleted.
*
* 	Creates a loop on bEMBF to validate each entry
*	individually.
*
* 	Errors in batch added to bHQBE using bspHQBEInsert.
* 	Account distributions added to bEMGL.
*
* 	GL Reference debit and credit totals must balance.
*
* 	bHQBC Status updated to 2 if errors found, or 3 if OK to post
*
* INPUT PARAMETERS
*	EMCo        EM Company
*	Month       Month of batch
*	BatchId     Batch ID to validate
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
@source bSource,
@errmsg varchar(255) output

as

set nocount on
       
declare @actualdate bDate, @balamt bDollar,  @batchseq int, @batchtranstype char(1), @emtrans bTrans, @errorstart varchar(50), @errtext varchar(255), @glco bCompany, 
	@inlocation bLoc, @oldactualdate bDate, @oldalloccode tinyint, @oldapco bCompany, @oldapline bItem, @oldapref bAPReference,
	@oldaptrans bTrans, @oldapvendor bVendor, @oldasset varchar(20), @oldbatchtranstype char(1), @oldcomponent bEquip, @oldcomponenttypecode varchar(10),
	@oldcostcode bCostCode, @oldcurrentodometer bHrs, @oldcurrenthourmeter bHrs, @oldcurrenttotalodometer bHrs, @oldcurrenttotalhourmeter bHrs, @olddescription bTransDesc,
	@olddollars bDollar, @oldemcosttype bEMCType, @oldemgroup bGroup, @oldemtrans bTrans, @oldemtranstype varchar(10), @oldequipment bEquip, @oldglco bCompany,
	@oldgloffsetacct bGLAcct, @oldgltransacct bGLAcct, @oldhours bHrs, @oldinco bCompany, @oldinlocation bLoc, @oldinstkunitcost bUnitCost, @oldinstkecm bECM,
	@oldinstkum bUM, @oldjcco bCompany, @oldjccosttype bJCCType, @oldjcphase bPhase, @oldjob bJob, @oldmaterial bMatl, @oldmatlgroup bGroup, @oldmeterhrs bHrs,
	@oldmetermiles bHrs, @oldmeterreaddate bDate, @oldmetertrans bTrans, @oldoffsetglco bCompany, @oldorigemtrans bTrans, @oldorigmth bMonth, @oldpartsstatuscode varchar(10), 
	@oldperecm char(1), @oldphasegrp bGroup, @oldprco bCompany, @oldpremployee bEmployee,
	---- #132064
	----@oldprevioushourmeter bHrs, @oldpreviousodometer bHrs, @oldprevioustotalhourmeter bHrs, @oldprevioustotalodometer bHrs,
	@oldreplacedhourreading bHrs, @oldreplacedodoreading bHrs, @oldrevcode bRevCode, @oldrevdollars bDollar, @oldreversalstatus tinyint, 
	@oldrevrate bDollar, @oldrevtimeunits bUnits, @oldrevtranstype varchar(20), @oldrevusedonequip bEquip, @oldrevusedonequipco bCompany, @oldrevusedonequipgroup bGroup, 
	@oldrevworkunits bUnits, @oldserialno varchar(20), @oldsource bSource, @oldtaxtype tinyint, @oldtaxamount bDollar, @oldtaxbasis bDollar, @oldtaxcode bTaxCode, @oldtaxgroup bGroup, 
	@oldtaxrate bRate, @oldtimeum bUM, @oldtotalcost bDollar, @oldum bUM, @oldunitprice bUnitCost, @oldunits bUnits, @oldvendorgrp bGroup, @oldwoitem bItem, @oldworkorder bWO, 
	@rcode int, @status tinyint, @rtcode int, @opencursor int
       
select @rcode = 0,@opencursor = 0

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

if @source is null
begin
	select @errmsg = 'Missing Batch Source!', @rcode = 1
    goto bspexit
end

/***************************************************************** */
/* Validate batch data, set HQ Batch status. clear HQ Batch Errors.
clear GL Detail Audit. and clear and refresh HQCC entries.
Exit immediately if batch doesnt validate. */
/* **************************************************************** */
exec @rcode = bspEMVal_Cost_BatchVal @co, @mth, @batchid, @source, @errmsg output
if @rcode <> 0 goto bspexit
      
-- update ReversalStatus to zero if null
update bEMBF 
set ReversalStatus = 0
from bEMBF where Co=@co and Mth=@mth and BatchId=@batchid and ReversalStatus is null

/*** Issue 126940 ***/
declare bcEMBF cursor local fast_forward for
select BatchSeq, ActualDate,BatchTransType,EMTrans,GLCo,INLocation,OldActualDate,OldAllocCode, 
    OldAPCo,OldAPLine,OldAPRef,OldAPTrans,OldAPVendor,OldAsset,OldBatchTransType,
    OldComponent,OldComponentTypeCode,OldCostCode,OldCurrentOdometer,
    OldCurrentHourMeter,OldCurrentTotalHourMeter,OldCurrentTotalOdometer,
    OldDescription,OldDollars,OldEMCostType,OldEMGroup,OldEMTrans,
    OldEMTransType,OldEquipment,OldGLCo,OldGLOffsetAcct,OldGLTransAcct,
    OldHours,OldINCo,OldINLocation,OldINStkUnitCost,OldINStkECM,OldINStkUM,
    OldJCCo,OldJCCostType,OldJCPhase,OldJob,OldMaterial,OldMatlGroup,
    OldMeterHrs,OldMeterMiles,OldMeterReadDate,OldMeterTrans,OldOffsetGLCo, 
    OldOrigEMTrans,OldOrigMth,OldPartsStatusCode,OldPerECM,OldPhaseGrp, 
    OldPRCo,OldPREmployee,
    ---- #132064
    ----OldPreviousHourMeter,OldPreviousOdometer,OldPreviousTotalHourMeter,OldPreviousTotalOdometer,
    OldReplacedHourReading,OldReplacedOdoReading,OldRevCode,OldRevDollars, 
    OldReversalStatus,OldRevRate,OldRevTimeUnits,OldRevTransType,OldRevUsedOnEquip, 
    OldRevUsedOnEquipCo,OldRevUsedOnEquipGroup,OldRevWorkUnits,OldSerialNo,OldSource, 
    OldTaxAmount,OldTaxType,OldTaxBasis,OldTaxCode,OldTaxGroup,OldTaxRate,OldTimeUM,
    OldTotalCost,OldUM,OldUnitPrice,OldUnits,OldVendorGrp,OldWOItem, 
    OldWorkOrder 
from EMBF Where Co=@co and Mth=@mth and BatchId=@batchid /*Issue 131264 and IsNull(ReversalStatus,0)=0*/

--Open Cursor
open bcEMBF
select @opencursor = 1
	
goto NextEMBFtrans
NextEMBFtrans:
Fetch next from bcEMBF into @batchseq, @actualdate,@batchtranstype,@emtrans,@glco,@inlocation,@oldactualdate,@oldalloccode, 
    @oldapco,@oldapline,@oldapref,@oldaptrans,@oldapvendor,@oldasset,@oldbatchtranstype,
    @oldcomponent,@oldcomponenttypecode,@oldcostcode,@oldcurrentodometer,
    @oldcurrenthourmeter,@oldcurrenttotalhourmeter,@oldcurrenttotalodometer,
    @olddescription,@olddollars,@oldemcosttype,@oldemgroup,@oldemtrans,
    @oldemtranstype,@oldequipment,@oldglco,@oldgloffsetacct,@oldgltransacct,
    @oldhours,@oldinco,@oldinlocation,@oldinstkunitcost,@oldinstkecm,@oldinstkum,
    @oldjcco,@oldjccosttype,@oldjcphase,@oldjob,@oldmaterial,@oldmatlgroup,
    @oldmeterhrs,@oldmetermiles,@oldmeterreaddate,@oldmetertrans,@oldoffsetglco, 
    @oldorigemtrans,@oldorigmth,@oldpartsstatuscode,@oldperecm,@oldphasegrp, 
    @oldprco,@oldpremployee,
    ----#132064
    ----@oldprevioushourmeter,@oldpreviousodometer,@oldprevioustotalhourmeter,@oldprevioustotalodometer,
    @oldreplacedhourreading,@oldreplacedodoreading,@oldrevcode,@oldrevdollars, 
    @oldreversalstatus,@oldrevrate,@oldrevtimeunits,@oldrevtranstype,@oldrevusedonequip, 
    @oldrevusedonequipco,@oldrevusedonequipgroup,@oldrevworkunits,@oldserialno,@oldsource, 
    @oldtaxamount,@oldtaxtype,@oldtaxbasis,@oldtaxcode,@oldtaxgroup,@oldtaxrate,@oldtimeum,
    @oldtotalcost,@oldum,@oldunitprice,@oldunits,@oldvendorgrp,@oldwoitem, 
    @oldworkorder
If (@@fetch_status <> 0)
begin
	goto EndNextEMBFtrans
end
	/* Setup @errorstart string. */
    select @errorstart = 'Seq ' + isnull(convert(varchar(9),@batchseq),'') + '-'
       
	select @rtcode = 0
    /* Do validations independent of Source */
    /* Validate BatchTransType. */
    if @batchtranstype not in ('A','C','D')
    begin
		select @errtext = isnull(@errorstart,'') + 'Invalid BatchTransType, must be A,C, or D.'
       	exec @rtcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
       	if @rtcode <> 0
       	begin
       	   	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
       		goto NextEMBFtrans
       	end
    end
     
	/* Verify ActualDate not null. */
    if @actualdate is null
    begin
		select @errtext = isnull(@errorstart,'') + 'Invalid ActualDate, must be not null.'
       	exec @rtcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
       	if @rtcode <> 0
       	begin
       	   	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
       		goto NextEMBFtrans
       	end
    end
       
    /*  Verify that EMTrans and all 'Olds' are null for Add type record */
    if @batchtranstype = 'A'
    begin
		/* Verify that EMTrans is null for Add type record. */
		if @emtrans is not null
		begin
       		select @errtext = isnull(@errorstart,'') + 'New entries may not ref a EMTrans.'
       		exec @rtcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
       		if @rtcode <> 0
       		begin
       		   	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
       			goto NextEMBFtrans
       		end
       	end
       	/* Verify all 'old' values are null. */
       	if @oldactualdate is not null or @oldalloccode is not null or @oldapco is not null or @oldapline is not null or @oldapref is not null or
       	@oldaptrans is not null or @oldapvendor is not null or @oldasset is not null or @oldbatchtranstype is not null or @oldcomponent is not null or 
       	@oldcomponenttypecode is not null or @oldcostcode is not null or @oldcurrentodometer is not null or @oldcurrenthourmeter is not null or 
       	@oldcurrenttotalhourmeter is not null or @oldcurrenttotalodometer is not null or @olddescription is not null or @olddollars is not null or 
       	@oldemcosttype is not null or @oldemgroup is not null or @oldemtrans is not null or @oldemtranstype is not null or @oldequipment is not null or
       	@oldglco is not null or @oldgloffsetacct is not null or @oldgltransacct is not null or @oldhours is not null or @oldinco is not null or
       	@oldinlocation is not null or @oldinstkecm is not null or @oldinstkum is not null or @oldinstkunitcost is not null or @oldjcco is not null or 
       	@oldjccosttype is not null or @oldjcphase is not null or @oldjob is not null or @oldmaterial is not null or @oldmatlgroup is not null or @oldmeterhrs is not null or
       	@oldmetermiles is not null or @oldmeterreaddate is not null or @oldmetertrans is not null or @oldoffsetglco is not null or @oldorigemtrans is not null or 
       	@oldorigmth is not null or @oldpartsstatuscode is not null or @oldperecm is not null or @oldphasegrp is not null or @oldprco is not null or @oldpremployee is not null or
       	----#132064
       	/*@oldprevioushourmeter is not null or @oldpreviousodometer is not null or @oldprevioustotalhourmeter is not null or @oldprevioustotalodometer is not null or*/
       	@oldreplacedhourreading is not null or @oldreplacedodoreading is not null or
       	@oldrevcode is not null or @oldrevdollars is not null or @oldreversalstatus is not null or @oldrevrate is not null or @oldrevtimeunits is not null or
       	@oldrevtranstype is not null or @oldrevusedonequip is not null or @oldrevusedonequipco is not null or @oldrevusedonequipgroup is not null or
       	@oldrevworkunits is not null or @oldserialno is not null or @oldsource is not null or @oldtaxtype is not null or @oldtaxamount is not null or
       	@oldtaxbasis is not null or @oldtaxcode is not null or @oldtaxgroup is not null or @oldtaxrate is not null or @oldtimeum is not null or
       	@oldtotalcost is not null or @oldum is not null or @oldunitprice is not null or @oldunits is not null or @oldvendorgrp is not null or 
       	@oldwoitem is not null or @oldworkorder is not null
       	begin
       		select @errtext = isnull(@errorstart,'') + 'Old info must be null for Add entries.'
       		exec @rtcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
       		if @rtcode <> 0
       		begin
       		  	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
       			goto NextEMBFtrans
       		end
       	end
     end --if @batchtranstype = 'A'
       

	-- ************** --
	-- ISSUE: #131478 --
	-- ************** --
     /* Do validations dependent on Source */
     if (@source = 'EMAdj') OR (@source = 'EMAlloc') OR (@source = 'EMDepr')
	 begin
		exec @rtcode = dbo.bspEMVal_Cost_SeqVal_Adj @co, @mth, @batchid, @batchseq, @errmsg output
		if @rtcode <> 0
		begin
			goto NextEMBFtrans
		end
     end
--     if @source = 'EMAlloc'
--	 begin
--       	exec @rtcode = dbo.bspEMVal_Cost_SeqVal_Alloc @co, @mth, @batchid, @batchseq, @errmsg output
--      	if @rtcode <> 0
--		begin
--			goto NextEMBFtrans
--		end
--	 end	
--     if @source = 'EMDepr'
--     begin
--		exec @rtcode = dbo.bspEMVal_Cost_SeqVal_Depr @co, @mth, @batchid, @batchseq, @errmsg output
--       	if @rtcode <> 0
--		begin
--			goto NextEMBFtrans
--		end
--     end
     if @source = 'EMFuel'
     begin
		exec @rtcode = dbo.bspEMVal_Cost_SeqVal_Fuel @co, @mth, @batchid, @batchseq, @errmsg output
       	if @rtcode <> 0
		begin
			goto NextEMBFtrans
		end
     end
     if @source = 'EMParts'
     begin
		exec @rtcode = dbo.bspEMVal_Cost_SeqVal_Parts @co, @mth, @batchid, @batchseq, @errmsg output
       	if @rtcode <> 0
		begin
			goto NextEMBFtrans
		end
     end
     if @source = 'EMTime'
     begin
     	exec @rtcode = dbo.bspEMVal_Cost_SeqVal_Time @co, @mth, @batchid, @batchseq, @errmsg output
     	if @rtcode <> 0
		begin
			goto NextEMBFtrans
		end
     end
       
     /* **************************************************************** */
     /* Update IN data table bEMIN and GL Detail Audit table bEMGL for   */
     /* Change records or if Amount, GLTransAcct or GLOffsetAcct change. */
     /* **************************************************************** */
     if @inlocation is not null or @oldinlocation is not null
     begin
		exec @rtcode = dbo.bspEMVal_Cost_EMIN_Inserts @co, @mth, @batchid, @batchseq, @errmsg output
       	--if @rcode <> 0 goto bspexit
     end
       	
     exec @rtcode = dbo.bspEMVal_Cost_EMGL_Inserts @co, @mth, @batchid, @batchseq, @errmsg output
     --if @rcode <> 0 goto bspexit

	goto NextEMBFtrans


EndNextEMBFtrans:
If @opencursor = 1
begin
	close bcEMBF
	deallocate bcEMBF
	select @opencursor = 0
End
       
/* ************************* */
/* Check balances and close. */
/* ************************* */
/* GL totals in bEMGL should always be in balance. */ --fixed TV 05/05/05 27430
select @glco = GLCo,@balamt=isnull(sum(isnull(Amount,0)),0) from bEMGL
where EMCo = @co and Mth = @mth and BatchId = @batchid
group by GLCo
having isnull(sum(Amount),0) <> 0
   	 
if isnull(@balamt,0) <> 0
begin
	select @errtext =  'Debit and credit entires are out of balance by ' + isnull(convert(varchar(20),@balamt),'') + '!'
    exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
    if @rcode <> 0 
	begin
     	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
      	goto bspexit
    end
end
   
/* Check HQ Batch Errors and update HQ Batch Control status. */
if exists(select top 1 1 from bHQBE where Co = @co and Mth = @mth and BatchId = @batchid)
	begin
		/* validation errors */
		select @status = 2 
	end
else
	begin
		/* valid - ok to post */
		select @status = 3
    end

update bHQBC
set Status = @status
where Co = @co and Mth = @mth and BatchId = @batchid
if @@rowcount <> 1
begin
	select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
    goto bspexit
end
       
bspexit:

If @opencursor = 1
begin
	close bcEMBF
	deallocate bcEMBF
	select @opencursor = 0
End
       
if @rcode<>0 select @errmsg=isnull(@errmsg,'')
	
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMVal_Cost_Main] TO [public]
GO
