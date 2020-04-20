SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMBF_Cost_InsExistingTrans    Script Date: 8/28/99 9:34:24 AM ******/
CREATE procedure [dbo].[bspEMBF_Cost_InsExistingTrans]
  /***********************************************************
  * CREATED BY: JM 12/22/98
  * MODIFIED By : JM 2/22/00
  *               DANF 04/07/00 Added source 'EMTime'
  *               MV 07/0201 - Issue 12769 BatchUserMemoInsertExisting
  *               TV 06/28/02 move UniqueAttchID  to batch table
  *				EN 10/18/02 issue 19037  include Hours & OldHours when load a transaction into bEMBF
  *				RM 10/22/02 When loading Hours and OldHours, if unitprice is 0 enter 0 (to avoid divide by 0 error)
  *							Also, put isnull around TaxAmount to prevent null entries in Hours
  *				EN 10/24/02 issue 19037  remove code that tries to set Hours from Units ... it interferes with my fix made on 10/18/02
  *               TV 09/21/03 -  Issue 22149 Only allow certain type to be pulled in to EMAdj
  *               TV 08/26/03 22149 - Added isnulls
  *               TV 09/05/03 22366 - Cannot add Auto-reversal transactions back into a batch. 
  *				TV 02/11/04 - 23061 added isnulls
  *				TV 11/15/05 - 30362 Receive error "Batch old info doesn't match EM Cost Detail"
  *				DAN SO 03/02/09 - Issue #131478 - modifed bspHQBatchProcessVal call to allow other Sources to be added to a batch
  * USAGE:
  *	This procedure pulls existing transactions from bEMCD
  *	into bEMBF for editing for Cost-type Sources (Parts &
  *	Fuel).
  *
  *	Checks batch info in bHQBC, and transaction info in bEMCD.
  *	Adds entry to next available Seq# in bEMBF.
  *
  *	bEMBF insert trigger will update InUseBatchId in bEMCD.
  *
  * INPUT PARAMETERS
  *	Co         EM Co to pull from
  *	Mth        Month of batch
  *	BatchId    Batch ID to insert transaction into
  *	AR         EM Trans to Pull
  *	Source     EM Source
  *
  * OUTPUT PARAMETERS
  *
  * RETURN VALUE
  *	0   Success
  *	1   Failure
  *****************************************************/
  @co bCompany, @mth bMonth, @batchid bBatchID, @emtrans bTrans, @source varchar(10), @errmsg varchar(255) output
  
  as
  set nocount on
  
  declare @emtranstype varchar(10), @errtext varchar(60), @hqbcsource varchar(10), @inusebatchid bBatchID,
		@inuseby bVPUserName, @postedmth bMonth, @rcode int, @seq int, @status tinyint, @emcdsource varchar(10),
        @formname varchar(30), @insertsource varchar(10), @reversalstatus int, 
		@checktable varchar(30), @TempEMBFSource varchar(10), @embfsource varchar(10),
		@TempSource varchar(10) -- used to send in a null value into bspHQBatchProcessVal
  
  select @rcode = 0
  
  -- Validate all params passed. 
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
  	select @errmsg = 'Missing Batch ID!', @rcode = 1
  	goto bspexit
  	end
  if @emtrans is null
  	begin
  	select @errmsg = 'Missing Batch Transaction!', @rcode = 1
  	goto bspexit
  	end
  if @source is null
  	begin
  	select @errmsg = 'Missing Batch Source!', @rcode = 1
  	goto bspexit
  	end
  -- Validate Source. 
  if @source not in ('EMParts','EMAdj','EMDepr','EMTime','EMAlloc','EMFuel')
  	begin
  	select @errmsg = isnull(@source,'') + ' is an invalid Source', @rcode = 1
  	goto bspexit
  	end
 
	-- ************** --
	-- ISSUE: #131478 --
	-- ************** --
  -- Validate HQ Batch. 
  --exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, @source, 'EMBF', @errtext output, @status output
	exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, @TempSource, 'EMBF', @errtext output, @status output

  if @rcode <> 0
  	begin
  	select @errmsg = @errtext, @rcode = 1
  	goto bspexit
  	end
  if @status <> 0
  	begin
  	select @errmsg = 'Invalid Batch status - must be Open!', @rcode = 1
  	goto bspexit
  	end
  
  --All Transactions can be pulled into a batch as long as its InUseFlag is set to null and Month is same as current
  select @inusebatchid = InUseBatchID, @emtranstype=EMTransType, @postedmth=Mth, @emcdsource=Source,
  @reversalstatus = ReversalStatus
  from bEMCD
  where EMCo=@co and Mth = @mth and EMTrans=@emtrans
  if @@rowcount = 0
  	begin
  	select @errmsg = 'The EM EMTrans :' + isnull(convert(varchar(10),@emtrans),'') + ' cannot be found.' , @rcode = 1
  	goto bspexit
  	end
  if @emtranstype is null
  	begin
  	select @errmsg ='The EM Trans Type is invalid!'
  	goto bspexit
  	end
  if @inusebatchid is not null
  	begin
  	select @hqbcsource=Source
  	from HQBC
  	where Co=@co and BatchId=@inusebatchid and Mth=@mth
  	if @@rowcount<>0
  		begin
  		select @errmsg = 'Transaction already in use by ' +
  		       isnull(convert(varchar(2),DATEPART(month, @mth)),'') + '/' +
  		       isnull(substring(convert(varchar(4),DATEPART(year, @mth)),3,4),'') +
  			   ' batch # ' + isnull(convert(varchar(6),@inusebatchid),'') + ' - ' + 'Batch Source: ' +
  			   isnull(@hqbcsource,''), @rcode = 1
  		goto bspexit
  		end
  	else
  		begin
  		select @errmsg='Transaction already in use by another batch!', @rcode=1
  		goto bspexit
  		end
  	end
  if @postedmth <> @mth
  	begin
  	select @errmsg = 'Cannot edit! EM transaction posted in prior month: ' +
  		   isnull(convert (varchar(60),@postedmth),'') + ',' + isnull(convert(varchar(60), @mth),''), @rcode = 1
  	goto bspexit
  	end
  
  --Validate EMSource vs Source. 
  if @source='EMTime' and @emcdsource <> 'EMTime'
  	begin
  	select @errmsg = 'Cannot edit! Not a valid EM source of EMTime.', @rcode = 1
  	goto bspexit
  	end
  
  -- Validate EMTransType vs Source. 
  if @source='EMParts' and @emtranstype <> 'Parts'
  	begin
  	select @errmsg = 'Cannot edit! Not a valid EM Parts Trans Type.', @rcode = 1
  	goto bspexit
  	end
  
  --09/21/03 - TV Issue 22149 Only allow certain type to be pulled in to EMAdj
  if @source = 'EMAdj' and @emcdsource not in ('EMAdj','EMDepr','EMAlloc')
      begin
     	select @errmsg = 'Cannot edit! ' + isnull(@emcdsource,'') + ' is not a valid source in EM Cost Adjustments', @rcode = 1
     	goto bspexit
     	end
  
  -- If we're adding a batch to EMCostAdj form that wasn't created with that form, insert the @emcdsource
  -- so that the added back transaction will not have its source changed to 'EMAdj' 
  if @source = 'EMAdj' and (@emcdsource = 'EMAlloc' or @emcdsource = 'EMDepr')
  select @insertsource = @emcdsource
  else
  select @insertsource = @source




--Cannot add Auto-reversal transactions back into a batch. TV 22366
--validate Reversal Status, cannot be 2, 3, 4 as we do not store the Orig month and transaction to be changed 
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
	If @reversalstatus = 2 select @errmsg = 'Reversal Transaction cannot change or delete. -  status:' + isnull(convert(varchar(1),@reversalstatus),'')
	If @reversalstatus = 3 select @errmsg = 'Transaction has been Reversed cannot change or delete. -  status:' + isnull(convert(varchar(1),@reversalstatus),'')
	If @reversalstatus = 4 select @errmsg = 'Canceled Reversal Transaction cannot change or delete. -  status:' + isnull(convert(varchar(1),@reversalstatus),'')
	goto bspexit
	end

-- get next available sequence # for this batch 
select @seq = isnull(max(BatchSeq),0)+1
from bEMBF
where Co = @co and Mth = @mth and BatchId = @batchid

-- Add record back to EMBF 
insert bEMBF (Co, Mth, BatchId, BatchSeq, Source, Equipment, EMTrans,BatchTransType,
		EMTransType, ComponentTypeCode, Component, Asset, EMGroup, CostCode,
		EMCostType, ActualDate, Description, GLCo, GLTransAcct, GLOffsetAcct,
		ReversalStatus, PRCo, PREmployee, APCo, APTrans,APLine, VendorGrp,
		APVendor, APRef, WorkOrder, WOItem, MatlGroup, INCo, INLocation, Material,
		SerialNo, UM, Units, Dollars, UnitPrice, PerECM, TotalCost, MeterTrans,
		CurrentHourMeter,CurrentTotalHourMeter, CurrentOdometer, CurrentTotalOdometer,
		TaxCode,TaxGroup, TaxBasis, TaxRate, TaxAmount, AllocCode,
		OldSource, OldEquipment, OldEMTrans,OldBatchTransType, OldEMTransType,
		OldComponentTypeCode, OldComponent, OldAsset, OldEMGroup, OldCostCode,
		OldEMCostType, OldActualDate, OldDescription, OldGLCo, OldGLTransAcct,
		OldGLOffsetAcct, OldReversalStatus, OldPRCo, OldPREmployee, OldAPCo,
		OldAPTrans, OldAPLine, OldVendorGrp, OldAPVendor, OldAPRef, OldWorkOrder,
		OldWOItem, OldMatlGroup, OldINCo, OldINLocation, OldMaterial, OldSerialNo,
		OldUM, OldUnits, OldDollars, OldUnitPrice, OldPerECM, OldTotalCost,
		OldMeterTrans, OldCurrentHourMeter, OldCurrentTotalHourMeter, OldCurrentOdometer,
		OldCurrentTotalOdometer, OldTaxType, OldTaxCode, OldTaxGroup, OldTaxBasis, OldTaxRate,
		OldTaxAmount, OldAllocCode, INStkECM, OldINStkECM, INStkUnitCost, OldINStkUnitCost,
		INStkUM, OldINStkUM,UniqueAttchID, Hours, OldHours)

Select @co, @mth, @batchid, @seq, @insertsource, Equipment, @emtrans, 'C',
		EMTransType,  ComponentTypeCode, Component, Asset, EMGroup, CostCode,
		EMCostType, ActualDate, Description, GLCo, GLTransAcct, GLOffsetAcct,
		ReversalStatus, PRCo, PREmployee, APCo, APTrans, APLine, VendorGrp,
		APVendor, APRef, WorkOrder, WOItem, MatlGroup, INCo, INLocation, Material,
		SerialNo, UM, Units, (Dollars - TaxAmount), UnitPrice, PerECM, TotalCost, MeterTrans,
		CurrentHourMeter, CurrentTotalHourMeter, CurrentOdometer, CurrentTotalOdometer,
		TaxCode, TaxGroup, TaxBasis, TaxRate, TaxAmount, AllocCode,
		@insertsource, Equipment, @emtrans, 'C', EMTransType,
		ComponentTypeCode, Component, Asset, EMGroup, CostCode,
		EMCostType, ActualDate, Description, GLCo, GLTransAcct,
		GLOffsetAcct, ReversalStatus, PRCo, PREmployee, APCo,
		APTrans, APLine, VendorGrp, APVendor, APRef, WorkOrder,
		WOItem, MatlGroup, INCo, INLocation, Material, SerialNo,
		UM, Units, (Dollars - isnull(TaxAmount,0)), UnitPrice, PerECM, TotalCost,
		MeterTrans, CurrentHourMeter, CurrentTotalHourMeter, CurrentOdometer,
		CurrentTotalOdometer, TaxType, TaxCode, TaxGroup, TaxBasis, TaxRate,
		TaxAmount,  AllocCode, INStkECM, INStkECM, INStkUnitCost, INStkUnitCost,
		INStkUM, INStkUM,UniqueAttchID,
		case isnull(UnitPrice,0) when 0 then 0 else ((Dollars - isnull(TaxAmount,0)) / UnitPrice) end, 
		case isnull(UnitPrice,0) when 0 then 0 else ((Dollars - isnull(TaxAmount,0)) / UnitPrice) end
from EMCD
where EMCo=@co and Mth = @mth and EMTrans=@emtrans
if @@rowcount <> 1
	begin
	select @errmsg = 'Unable to add entry to EM Batch table!', @rcode = 1
	goto bspexit
	end


-- BatchUserMemoInsertExisting - update the user memo in the batch record
exec @rcode =  bspBatchUserMemoInsertExisting @co, @mth, @batchid, @seq, @source, 0,@errmsg output
if @rcode <> 0
	begin
	select @errmsg = 'Unable to update User Memos in EMBF', @rcode = 1
	goto bspexit
	end



bspexit:
	if @rcode<>0 select @errmsg=isnull(@errmsg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMBF_Cost_InsExistingTrans] TO [public]
GO
