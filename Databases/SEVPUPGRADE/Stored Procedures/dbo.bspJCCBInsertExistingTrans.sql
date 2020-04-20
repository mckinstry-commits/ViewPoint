SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*********************************************************/
CREATE procedure [dbo].[bspJCCBInsertExistingTrans]
/***********************************************************
* CREATED BY:	SE		12/04/96
* MODIFIED By:	SE		12/04/96
*				DANF	03/01/2000	- Added additional columns
*				DANF	03/16/2000	- Added check for reversal status
*				DANF	05/18/2000	- Added Shift
*				GG		11/27/00	- changed datatype from bAPRef to bAPReference
*				DANF	04/13/01	- remove check for redirected taxes
*				MV		7/3/01		- Issue 12769 BatchUserMemoInsertExisting
*				DANF	04/04/02	- Do Not allow Intercompany Adjustment to be added to a batch.
*				TV		05/29/02	- insert @uniqueattchid into Batch Table
*				GF		06/09/2003	- issue #21405 - do not allow JCTransType='RU' to be pulled in.
*				TV					- 23061 added isnulls
*				DANF	09/29/2005	- Issue 28992 unburden posted unit cost
*				DANF	02/27/2007	- Issue 120441 Correct error message for reversal transctions that are pulled into a batch and inuse.
*				CHS		08/06/2008	- Issue #123239
*				CHS		11/21/2008	- Issue #131157
*				GF		05/24/2010 - issue #137811 set OffsetGLCo for cost adjustment transactions
*				gf 06/25/2010 - issue #135813 expanded SL to varchar(30)
*				TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
*				GF 09/07/2011 TK-08225 PO ITEM LINE
*
*
* USAGE:
* This procedure is used by the JC Cost Adujstment entry to pull existing
* transactions from bJCCD into bJCCB for editing.
*
* Checks batch info in bHQBC, and transaction info in bJCCD.
* Adds entry to next available Seq# in bJCCB
*
* JCCB insert trigger will update InUseBatchId in bJCCD
*
* INPUT PARAMETERS
*   Co         JC Co to pull from
*   Mth        Month of batch
*   BatchId    Batch ID to insert transaction into
*   JCTrans    JCCD Detail transaction to add to batch.
* OUTPUT PARAMETERS
*
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/
@co bCompany, @mth bMonth, @batchid bBatchID,
@jctrans bTrans, @errmsg varchar(200) output
as
set nocount on

declare @rcode int, @inuseby bVPUserName, @status tinyint, @source bSource,
		@dtsource bSource, @inusebatchid bBatchID, @seq int, @errtext varchar(60),
		@costtrans bTrans, @job bJob, @PhaseGroup tinyint, @phase bPhase, @costtype bJCCType, @actualdate bDate,
		@jctranstype varchar(2), @description bTransDesc, @glco bCompany, @gltransacct bGLAcct,
		@gloffsetacct bGLAcct, @reversalstatus tinyint, @um bUM, @hours bHrs, @units bUnits,
		@cost bDollar,@prco bCompany,@employee bEmployee,@craft bCraft,@class bClass,@crew varchar(10),@earnfactor bRate,
		@earntype bEarnType, @shift tinyint, @liabilitytype bLiabilityType,@vendorgroup bGroup,@vendor bVendor,
		@apco bCompany,@aptrans bTrans,@apline smallint,@apref bAPReference,@po varchar(30),@poitem bItem,
		@sl VARCHAR(30),
		@slitem bItem,@mo bMO,@moitem bItem,@matlgroup bGroup,@material bMatl,@inco bCompany,
		@loc bLoc,@mstrans bTrans,@msticket varchar(30),@emco bCompany,@emequip bEquip,
		@emrevcode bRevCode,@emgroup bGroup, @pstum bUM, @pstunits bUnits, @pstunitcost bUnitCost,
		@pstecm bECM, @instdunitcost bUnitCost, @instdecm bECM, @instdum bUM, @taxtype tinyint,
		@taxgroup bGroup, @taxcode bTaxCode, @taxbasis bDollar, @taxamt bDollar,
		@taxphase bPhase, @taxct bJCCType, @uniqueattchid uniqueidentifier,
		@jbbillstatus char(1), @jbbillmonth bMonth, @jbbillnumber int,
		----#137811
		@OffsetGLCo bCompany,
		----TK-08225
		@POItemLine INT

SET @rcode = 0

/* validate HQ Batch */
exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, 'JC CostAdj', 'JCCB', @errtext output, @status output
if @rcode <> 0
	begin
	exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, 'JC MatUse', 'JCCB', @errtext output, @status output
	if @rcode <> 0
		begin
		select @errmsg = 'Invalid Source must be JC CostAdj or JC MatUse.', @rcode = 1
		goto bspexit
		end
	end

if @status <> 0
	begin
	select @errmsg = 'Invalid Batch status -  must be (open)!', @rcode = 1
	goto bspexit
	end


/* validate existing JC Trans */
select  @dtsource=Source, @inusebatchid=InUseBatchId,
		@job=Job, @PhaseGroup=PhaseGroup, @phase=Phase, @costtype=CostType, @actualdate=ActualDate,
		@jctranstype=JCTransType, @description=Description,
		@glco=GLCo, @gltransacct=GLTransAcct, @gloffsetacct=GLOffsetAcct,
		@reversalstatus=ReversalStatus, @um=UM, @hours=ActualHours, @units=ActualUnits, @cost=ActualCost,
		@prco=PRCo,@employee=Employee,@craft=Craft,@class=Class,@crew=Crew,@earnfactor=EarnFactor,
		@earntype=EarnType,@shift=Shift,@liabilitytype=LiabilityType,@vendorgroup=VendorGroup,@vendor=Vendor,
		@apco=APCo,@aptrans=APTrans,@apline=APLine,@apref=APRef,
		@po=PO,@poitem=POItem,@sl=SL,@slitem=SLItem,@mo=MO,@moitem=MOItem,@matlgroup=MatlGroup,
		@material=Material,@inco=INCo,@loc=Loc,@mstrans=MSTrans,@msticket=MSTicket,@emco=EMCo,@emequip=EMEquip,
		@emrevcode=EMRevCode,@emgroup=EMGroup, @pstum=PostedUM, @pstunits=PostedUnits, @pstunitcost=PostedUnitCost,
		@pstecm=PostedECM, @instdunitcost=INStdUnitCost, @instdecm=INStdECM, @instdum=INStdUM, @taxtype=TaxType,
		@taxgroup=TaxGroup, @taxcode=TaxCode, @taxbasis=TaxBasis, @taxamt=TaxAmt, @uniqueattchid = UniqueAttchID,
		@jbbillstatus = JBBillStatus, @jbbillmonth = JBBillMonth, @jbbillnumber = JBBillNumber,
		----#137811
		@OffsetGLCo = OffsetGLCo,
		----TK-08225
		@POItemLine = POItemLine
from dbo.bJCCD where JCCo=@co and Mth=@mth and CostTrans = @jctrans
if @@rowcount = 0
	begin
	select @errmsg = 'JC transaction #' + isnull(convert(varchar(6),@jctrans),'') + ' not found!', @rcode = 1
	goto bspexit
	end

if @inusebatchid is not null
	begin
	select @source=Source
	from dbo.bHQBC where Co=@co and BatchId=@inusebatchid and Mth=@mth
	if @@rowcount <> 0
		begin
		if isnull(@reversalstatus,0) < 1 -- Reversal transactions that are in are missing the correct Inuse batch month therefore display a different error message with out the month
			begin
			select @errmsg = 'Transaction already in use by ' +
				isnull(convert(varchar(2),DATEPART(month, @mth)),'') + '/' +
				isnull(substring(convert(varchar(4),DATEPART(year, @mth)),3,4),'') +
				' batch # ' + isnull(convert(varchar(6),@inusebatchid),'') + ' - ' + 'Batch Source: ' + isnull(@source,''), @rcode = 1
			end
		else
			begin
			select @errmsg = 'Reversal Transaction already in use by ' +
				' batch # ' + isnull(convert(varchar(6),@inusebatchid),''), @rcode = 1
			end

		goto bspexit
		end
	else
		begin
		select @errmsg='Transaction already in use by another batch!', @rcode=1
		goto bspexit
		end
	end
   
/*validate Reversal Status, cannot be 2, 3, 4 as we do not store the Orig month and transaction to be changed */
/************************************* 
   '0=no action
   '1=Transaction is to be reversed.
   '2=Reversal Transaction.
   '3=original Transaction Reversed.
   '4=reversal canceld
*************************************/ 
if @reversalstatus in (2,3,4)
	begin
	select @rcode = 1
	If @reversalstatus = 2 select @errmsg = 'Reversal Transactions cannot be changed or deleted. -  reversal status:' + isnull(convert(varchar(1),@reversalstatus),'')
	If @reversalstatus = 3 select @errmsg = 'Transactions has been Reversed cannot be changed or deleted. -  reversal status:' + isnull(convert(varchar(1),@reversalstatus),'')
	If @reversalstatus = 4 select @errmsg = 'Canceled Reversal Transactions cannot be changed or deleted. -  reversal status:' + isnull(convert(varchar(1),@reversalstatus),'')
	goto bspexit
	end

if @jctranstype = 'RU'
	begin
	select @errmsg = 'This is a JC Roll up transaction which cannot be edited!', @rcode = 1
	goto bspexit
	end

if @jctranstype = 'IC'
	begin
	select @errmsg = 'This is a Inter Company transaction which cannot be edited!', @rcode = 1
	goto bspexit
	end

if @dtsource <> 'JC CostAdj' and @dtsource <> 'JC MatUse'
	begin
	select @errmsg = 'This JC transaction was created with a ' + isnull(@dtsource,'') + ' source!', @rcode = 1
	goto bspexit
	end

-- CHS - Issue #123239
if @jbbillstatus in (1,2)
	begin
		select @errmsg = 'This transaction has been included on a bill - Month ' +  
				isnull(convert(varchar(2),DATEPART(month, @jbbillmonth)),'') + '/' +
				isnull(substring(convert(varchar(4),DATEPART(year, @jbbillmonth)),3,4),'') +
				' Bill #' + cast(@jbbillnumber as varchar) + ' and cannot be edited!', @rcode = 1
		goto bspexit
	end


---- #137811 - for cost adjustments just use the existing GLCo
if @dtsource = 'JC CostAdj' and @OffsetGLCo is null
	begin
	set @OffsetGLCo = @glco
	end
---- if we do not have an Offset GLCo for JC Material Use transactions, go find one.
if @dtsource = 'JC MatUse' and @jctranstype in ('IN','MI') and @OffsetGLCo is null
	begin
	---- when type is miscellenous use the transaction GLCo
	set @OffsetGLCo = @glco
	---- when type is inventory use the IN Company GLCo
	if @jctranstype = 'IN'
		begin
		select @OffsetGLCo = GLCo from dbo.bINCO with (nolock) where INCo=@inco	
		end
	end
---- #137811


/* Do not allow a transaction to be change if tax has been redirect to a different phase or cost type */
/*if @taxcode is not null
     begin
     select @taxphase = Phase, @taxct = JCCostType
     from bHQTX
     where TaxGroup = @taxgroup and TaxCode = @taxcode
     if @@rowcount = 0
         begin
         goto addtransaction
         end
      -- use 'posted' phase and cost type unless overridden by tax code
      if not @taxphase is null or not @taxct is null
        begin
    	select @errmsg = 'Cannot change this transaction as tax has been redirected to a different phase and or cost type. Post reversing entries to correct.', @rcode = 1
	    goto bspexit
       end
     end

addtransaction:*/


---- issue 28992 unburden posted unit cost
if isnull(@taxamt,0)<>0 and isnull(@units,0)<>0 select @pstunitcost = (@cost-@taxamt)/@pstunits

/* get next available sequence # for this batch */
select @seq = isnull(max(BatchSeq),0)+1 from bJCCB where Co = @co and Mth = @mth and BatchId = @batchid

/* add JC transaction to batch */
insert into bJCCB (Co, Mth, BatchId, BatchSeq, Source, TransType, CostTrans, Job, PhaseGroup, Phase,
		CostType, ActualDate, JCTransType, Description, GLCo, GLTransAcct, GLOffsetAcct,
		ReversalStatus, UM, Hours, Units, Cost,
		OldJob, OldPhaseGroup, OldPhase, OldCostType, OldActualDate, OldJCTransType, OldDescription,
		OldGLCo, OldGLTransAcct, OldGLOffsetAcct, OldReversalStatus, OldUM, OldHours, OldUnits, OldCost,
		PRCo,Employee,Craft,Class,Crew,EarnFactor,EarnType,Shift,LiabilityType,VendorGroup,Vendor,APCo,
		APTrans,APLine,APRef,PO,POItem,SL,SLItem,MO,MOItem,MatlGroup,Material,INCo,Loc,
		MSTrans,MSTicket,EMCo,EMEquip,EMRevCode,EMGroup,PstUM,PstUnits,PstUnitCost,
		PstECM,INStdUnitCost,INStdECM,INStdUM,TaxType,TaxGroup,TaxCode,TaxBasis,TaxAmt,
		OldPRCo,OldEmployee,
		OldCraft,OldClass,OldCrew,OldEarnFactor,OldEarnType,OldShift,OldLiabilityType,OldVendorGroup,
		OldVendor,OldAPCo,OldAPTrans,OldAPLine,OldAPRef,OldPO,OldPOItem,OldSL,OldSLItem,
		OldMO,OldMOItem,OldMatlGroup,OldMaterial,OldINCo,OldLoc,OldMSTrans,OldMSTicket,
		OldEMCo,OldEMEquip,OldEMRevCode,OldEMGroup,OldPstUM,OldPstUnits,OldPstUnitCost,
		OldPstECM,OldINStdUnitCost,OldINStdECM,OldINStdUM,OldTaxType,OldTaxGroup,OldTaxCode,
		OldTaxBasis, OldTaxAmt, ToJCCo, UniqueAttchID,
		----#137811
		OffsetGLCo, OldOffsetGLCo,
		----TK-08225
		OldPOItemLine, POItemLine)
values (@co, @mth, @batchid, @seq, @dtsource, 'C', @jctrans, @job, @PhaseGroup, @phase, @costtype,
		@actualdate, @jctranstype, @description, @glco, @gltransacct, @gloffsetacct,
		@reversalstatus, @um, @hours, @units, @cost,
		@job, @PhaseGroup, @phase, @costtype, @actualdate, @jctranstype,
		@description, @glco, @gltransacct, @gloffsetacct,
		@reversalstatus, @um, @hours, @units, @cost,
		@prco, @employee, @craft, @class,
		@crew,@earnfactor,@earntype,@shift,@liabilitytype,@vendorgroup,@vendor,@apco,@aptrans,@apline,
		@apref,	@po,@poitem,@sl,@slitem,@mo,@moitem,@matlgroup,@material,@inco,@loc,
		@mstrans,@msticket,@emco,@emequip,@emrevcode,@emgroup,@pstum,@pstunits,@pstunitcost,
		@pstecm, @instdunitcost,@instdecm,@instdum,@taxtype,
		@taxgroup,@taxcode,@taxbasis,@taxamt,
		@prco, @employee, @craft, @class,
		@crew,@earnfactor,@earntype,@shift,@liabilitytype,@vendorgroup,@vendor,@apco,@aptrans,@apline,
		@apref,	@po,@poitem,@sl,@slitem,@mo,@moitem,@matlgroup,@material,@inco,@loc,
		@mstrans,@msticket,@emco,@emequip,@emrevcode,@emgroup,@pstum,@pstunits,@pstunitcost,
		@pstecm, @instdunitcost,@instdecm,@instdum,@taxtype,
		@taxgroup,@taxcode,@taxbasis,@taxamt, @co, @uniqueattchid,
		----#137811
		@OffsetGLCo, @OffsetGLCo,
		----TK-08225
		@POItemLine, @POItemLine)

if @@rowcount <> 1
	begin
	select @errmsg = 'Unable to add entry to JC Cost Adjustment Batch!', @rcode = 1
	goto bspexit
	end

/* BatchUserMemoInsertExisting - update the user memo in the batch record */
exec @rcode =  bspBatchUserMemoInsertExisting @co, @mth, @batchid, @seq, @dtsource, 0, @errmsg output
if @rcode <> 0
	begin
	select @errmsg = 'Unable to update User Memos in JCCB', @rcode = 1
	goto bspexit
	end


bspexit:
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspJCCBInsertExistingTrans] TO [public]
GO
