SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMBF_Usage_InsExistingTrans    Script Date: 8/28/99 9:34:24 AM ******/
    CREATE    procedure [dbo].[bspEMBF_Usage_InsExistingTrans]
    /***********************************************************
     * CREATED BY:	bc 04/02/99
     * MODIFIED By: MV 7/3/01 - Issue 12769 BatchUserMemoInsertExisting
     *              TV 05/28/02 pass UniqueAttchID  to batch table
     *				TV 02/11/04 - 23061 added isnulls
     *				TV 05/18/04 - 24583 was not pulling OldEMTrans
     *				TV 11/22/04 - 24034 Send crew to JCCD with equipment entries
	 *				GP 06/30/08 - Issue 124677, inserts bEMBF.Description from bEMRD.Memo because of the
	 *								added "Description" field on EMUsePosting.
     *
     * USAGE:
     * This procedure is used by the EM Posting program to pull existing
     * transactions from bEMRD into bEMBF for editing.
     *
     * Checks batch info in bHQBC
     * Adds entry to next available Seq# in bEMBF
     *
     * bEMBF insert trigger will update InUseBatchId in bEMRD
     *
     * INPUT PARAMETERS
     *   Co         EM Co to pull from
     *   Mth        Month of batch
     *   BatchId    Batch ID to insert transaction into
     *   EMTrans    EM Transaction to pull
     *
     * OUTPUT PARAMETERS
     *
     * RETURN VALUE
     *   0   success
     *   1   fail
     *****************************************************/
    (@co bCompany, @mth bMonth, @batchid bBatchID, @emtrans bTrans, @source bSource, @errmsg varchar(255) output)
    as
    set nocount on
    
    declare @rcode int, @inuseby bVPUserName, @status tinyint, @dtsource bSource, @inusebatchid bBatchID,
    		@seq int, @errtext varchar(60), @source_desc bSource
    
    select @rcode = 0
    
    -- validate HQ Batch
    exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, 'EMRev', 'EMBF', @errtext output, @status output
    if @rcode <> 0
        begin
        select @errmsg = @errtext, @rcode = 1
        goto bspexit
        end
    
    if @status <> 0
        begin
        select @errmsg = 'Invalid Batch status -  must be Open!', @rcode = 1
        goto bspexit
        end
    
    -- all Invoices's can be pulled into a batch as long as it's InUseFlag is set to null
    select @inusebatchid = InUseBatchID from bEMRD where EMCo=@co and Mth=@mth and Trans=@emtrans
    if @@rowcount = 0
     	begin
     	select @errmsg = 'The EM Tranasction :' + isnull(convert(varchar(6),@emtrans),'') + ' cannot be found.' , @rcode = 1
     	goto bspexit
     	end
    
    if @inusebatchid is not null
     	begin
     	select @source_desc=Source
     	from HQBC
     	where Co=@co and BatchId=@inusebatchid  and Mth=@mth
     	if @@rowcount<>0
    		begin
     		select @errmsg = 'Transaction already in use by ' +
     		      isnull(convert(varchar(2),DATEPART(month, @mth)),'') + '/' +
     		      isnull(substring(convert(varchar(4),DATEPART(year, @mth)),3,4),'') +
     			' batch # ' + isnull(convert(varchar(6),@inusebatchid),'') + ' - ' + 'Batch Source: ' + isnull(@source_desc,''), @rcode = 1
     		goto bspexit
    		end
    	else
    		begin
     		select @errmsg='Transaction already in use by another batch!', @rcode=1
     		goto bspexit
    		end
     	end
    
    -- get next available sequence # for this batch 
    select @seq = isnull(max(BatchSeq),0)+1 from bEMBF where Co = @co and Mth = @mth and BatchId = @batchid
    -- add Transaction to batch 
    insert into bEMBF (Co, Mth, BatchId, BatchSeq, Source, Equipment, RevCode, EMTrans, BatchTransType,
    		EMTransType, ComponentTypeCode, Component, EMGroup, CostCode, EMCostType, ActualDate, Description, GLCo,
    		GLOffsetAcct, PRCo, PREmployee, WorkOrder, WOItem, UM, JCCo, Job, PhaseGrp, JCPhase, JCCostType,
    		RevRate, MeterTrans, CurrentOdometer, PreviousOdometer, CurrentHourMeter, PreviousHourMeter,
    		RevWorkUnits, RevTimeUnits, RevDollars, OffsetGLCo, RevUsedOnEquipCo, RevUsedOnEquipGroup,
    		RevUsedOnEquip, TimeUM, OldEquipment, OldRevCode, OldEMTrans,OldEMTransType, OldComponentTypeCode,
    		OldComponent, OldEMGroup, OldCostCode, OldEMCostType, OldActualDate, OldGLCo, OldGLTransAcct,
    		OldGLOffsetAcct, OldPRCo, OldPREmployee, OldWorkOrder, OldWOItem, OldUM, OldRevTransType,
    		OldJCCo, OldJob, OldPhaseGrp, OldJCPhase, OldJCCostType, OldRevRate,
    		OldCurrentOdometer, OldPreviousOdometer, OldCurrentHourMeter, OldPreviousHourMeter,
    		OldRevWorkUnits, OldRevTimeUnits, OldRevDollars, OldOffsetGLCo, OldRevUsedOnEquipCo, OldRevUsedOnEquipGroup,
    		OldRevUsedOnEquip, OldTimeUM, UniqueAttchID,PRCrew )
    Select EMCo, @mth, @batchid, @seq, @source, Equipment, RevCode, Trans, 'C', TransType, UsedOnComponentType,
    
    	   UsedOnComponent,	EMGroup, EMCostCode, EMCostType, ActualDate, Memo, GLCo, ExpGLAcct, PRCo, Employee,
    	   WorkOrder, WOItem, UM, JCCo, Job, PhaseGroup, JCPhase, JCCostType, RevRate,
           MeterTrans, OdoReading, PreviousOdoReading, HourReading, PreviousHourReading,
           WorkUnits, TimeUnits, Dollars, ExpGLCo, UsedOnEquipCo, UsedOnEquipGroup, UsedOnEquipment, TimeUM,
           Equipment, RevCode, @emtrans, TransType, UsedOnComponentType,
           UsedOnComponent,	EMGroup, EMCostCode, EMCostType, ActualDate, GLCo, RevGLAcct,
           ExpGLAcct, PRCo, Employee, WorkOrder, WOItem, UM, TransType,
           JCCo, Job, PhaseGroup, JCPhase, JCCostType, RevRate,
           OdoReading, PreviousOdoReading, HourReading, PreviousHourReading,
           WorkUnits, TimeUnits, Dollars, ExpGLCo, UsedOnEquipCo, UsedOnEquipGroup,
           UsedOnEquipment, TimeUM, UniqueAttchID, PRCrew 
    from bEMRD where EMCo=@co and Mth=@mth and Trans=@emtrans
     if @@rowcount <> 1
     	begin
     	select @errmsg = 'Unable to add entry to EM Entry Batch!', @rcode = 1
     	goto bspexit
     	end
    
    -- BatchUserMemoInsertExisting - update the user memo in the batch record
    exec @rcode =  bspBatchUserMemoInsertExisting @co, @mth, @batchid, @seq, 'EM UsePosting', 0, @errmsg output
    if @rcode <> 0
    	begin
    	select @errmsg = 'Unable to update User Memos in EMBF', @rcode = 1
    	goto bspexit
    	end
    
    
    
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMBF_Usage_InsExistingTrans] TO [public]
GO
