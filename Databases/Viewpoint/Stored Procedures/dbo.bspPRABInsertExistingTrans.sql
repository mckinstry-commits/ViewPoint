SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRABInsertExistingTrans    Script Date: 8/28/99 9:35:27 AM ******/
    CREATE       procedure [dbo].[bspPRABInsertExistingTrans]
    /************************************************************************
     * CREATED BY: EN 1/16/98
     * MODIFIED By : EN 2/18/99
     *               EN 2/17/00 - Initialize Cap1Amt, Cap2Amt and AvailBalAmt in bPRAB to 0
     *               MV 7/6/01 - Issue 12769 BatchUserMemoInsertExisting
     *               EN 4/3/02 - Issue 15788 Adjust for renamed bPRAB fields
     *				  EN 5/2/02 - issue 15775 include Accum1Adj, Accum2Adj, and AvailBalAdj values when insert trans
      *              TV 05/28/02 inseert UniqueAttchID into batch table
     *				  EN 6/4/02 - issue 15788 add reset transactions as BatchTransType 'D'
     *				  EN 10/7/02 - issue 18877 change double quotes to single
     *
     * USAGE:
     * Used by the PR Leave Entry and PR Auto Leave programs to pull existing
     * transactions from bPRLH into bPRAB for editing.
     *
     * Checks batch info in bHQBC, and transaction info in bPRLH.
     * Adds entry to next available Seq# in bPRAB.
     *
     * PRAB insert trigger will update InUseBatchId in bPRLH *
     *  INPUT PARAMETERS
     *   @co	PR company number
     *   @mth	month
     *   @batchid	batch identification
     *   @trans	PR leave history transaction #
     *   @source	'PR Leave Entry' or 'PR Auto Leave'
     *
     * OUTPUT PARAMETERS
     *   @errmsg      error message if error occurs
     *
     * RETURN VALUE
     *   0   success
     *   1   fail
     *
     *************************************************************************/
   
    	@co bCompany, @mth bMonth, @batchid bBatchID,
    	@trans bTrans, @source bSource, @errmsg varchar(100) output
   
   
    as
    set nocount on
    declare @rcode int, @inusemth bMonth, @status tinyint, @inusebatchid bBatchID, @seq int,
    	@employee bEmployee, @leavecode bLeaveCode, @actdate bDate, @type varchar(1),
    	@amt bHrs, @description bDesc, @prgroup bGroup, @prenddate bDate, @payseq tinyint,
        @errtext varchar(200), @accum1adj bHrs, @accum2adj bHrs, @availbaladj bHrs, @uniqueattchid uniqueidentifier,
   	@batchtranstype char(1)
   
    select @rcode = 0
   
    /* validate HQ Batch */
    exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, @source, 'PRAB', @errtext output, @status output
    if @rcode <> 0
       begin
        select @errmsg = @errtext, @rcode = 1
        goto bspexit
       end
   
    if @status <> 0
       begin
        select @errmsg = 'Invalid Batch status -  must be ''open''!', @rcode = 1
        goto bspexit
       end
   
    /* validate existing PR Trans */
    select  @employee=Employee, @leavecode=LeaveCode, @actdate=ActDate, @type=Type, @amt=Amt,
    	@description=Description, @prgroup=PRGroup, @prenddate=PREndDate, @payseq=PaySeq,
    	@inusebatchid=InUseBatchId, @accum1adj=Accum1Adj, @accum2adj=Accum2Adj, @availbaladj=AvailBalAdj,
       @uniqueattchid = UniqueAttchID
    	from PRLH Where PRCo=@co and Mth=@mth and Trans=@trans
   
    if @@rowcount = 0
    	begin
    	select @errmsg = 'Transaction ' + convert(varchar(6),@trans) + ' not found!', @rcode = 1
    	goto bspexit
    	end
    if @inusebatchid = @batchid
    	begin
    	select @errmsg = 'Transaction already in use by this Batch.', @rcode = 1
    	goto bspexit
    	end
    if @inusebatchid is not null
    	begin
    	select @source=Source
    	       from HQBC
    	       where Co=@co and BatchId=@inusebatchid and Mth=@inusemth
    	    if @@rowcount<>0
    	       begin
    		select @errmsg = 'Transaction already in use by ' +
    		      convert(varchar(2),DATEPART(month, @inusemth)) + '/' +
    		      substring(convert(varchar(4),DATEPART(year, @inusemth)),3,4) +
    			' batch # ' + convert(varchar(6),@inusebatchid) + ' - ' + 'Batch Source: ' + @source, @rcode = 1
    		goto bspexit
    	       end
    	    else
    	       begin
    		select @errmsg='Transaction already in use by another batch!', @rcode=1
    		goto bspexit
    	       end
    	end
   
    --issue 15788 set trans type to 'C' or to 'D' if adding a reset transaction
    select @batchtranstype='C'
    if @type='R' select @batchtranstype='D'
   
    /* get next available sequence # for this batch */
    select @seq = isnull(max(BatchSeq),0)+1 from PRAB where Co = @co and Mth = @mth and BatchId = @batchid
   
    /* add Transaction to PRAB */
    insert into bPRAB (Co, Mth, BatchId, BatchSeq, BatchTransType, Trans, Employee, LeaveCode,
    	ActDate, Type, Amt, Accum1Adj, Accum2Adj, AvailBalAdj, Description, PRGroup, PREndDate,
    	PaySeq, OldEmployee, OldLeaveCode, OldActDate, OldType, OldAmt, OldAccum1Adj, OldAccum2Adj,
    	OldAvailBalAdj, OldDesc, OldPRGroup, OldPREndDate, OldPaySeq, UniqueAttchID)
    values (@co, @mth, @batchid, @seq, @batchtranstype, @trans, @employee, @leavecode, @actdate, @type,
    	@amt, @accum1adj, @accum2adj, @availbaladj, @description, @prgroup, @prenddate, @payseq,
    	@employee, @leavecode, @actdate, @type, @amt, @accum1adj, @accum2adj, @availbaladj,
    	@description, @prgroup, @prenddate, @payseq, @uniqueattchid)
    if @@rowcount <> 1
    	begin
    	select @errmsg = 'Unable to add entry to PR Leave Entry Batch!', @rcode = 1
    	goto bspexit
    	end
   
    /* update user memo to PRAB batch table- BatchUserMemoInsertExisting */
    exec @rcode = bspBatchUserMemoInsertExisting @co, @mth, @batchid, @seq, 'PR Leave',
        0, @errmsg output
        if @rcode <> 0
        begin
   	 select @errmsg = 'Unable to update user memo to PR Employee Leave Batch!', @rcode = 1
   	 goto bspexit
   	 end
   
    bspexit:
   
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRABInsertExistingTrans] TO [public]
GO
