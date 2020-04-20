SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspARBatchClear    Script Date: 8/28/99 9:34:08 AM ******/
   CREATE  procedure [dbo].[bspARBatchClear]
    /*************************************************************************************************
     * CREATED BY: bc 06/30/99
     * MODIFIED By :  MH 5/20/11 - TK-05144
	 *                DW 07/13/12 - TK-16355 - Modified the 'BatchClear' stored procedures to delete from the batch tables instead of the batch views.
     *
     * USAGE:
     * Clears batch tables
     *
     * INPUT PARAMETERS
     *   ARCo        AR Co
     *   Month       Month of batch
     *   BatchId     Batch ID to validate
     *
     * OUTPUT PARAMETERS
     *   @errmsg     if something went wrong
     *
     * RETURN VALUE
     *   0   success
     *   1   fail
     **************************************************************************************************/
   
    	(@co bCompany, @mth bMonth, @batchid bBatchID, @errmsg varchar(60) output)
    as
   
    set nocount on
   
    declare @rcode int, @source bSource, @tablename char(20), @status tinyint, @inuseby bVPUserName
   
    select @rcode = 0
   
    select @status=Status, @inuseby=InUseBy, @tablename=TableName
    from bHQBC
    where Co=@co and Mth=@mth and BatchId=@batchid
   
    if @@rowcount=0
    	begin
    	select @errmsg='Invalid batch.', @rcode=1
    	goto bspexit
    	end
   
    if @status=5
    	begin
    	select @errmsg='Cannot clear, batch has already been posted!', @rcode=1
    	goto bspexit
    	end
   if @status=4
    	begin
    	select @errmsg='Batch posting was interrupted, cannot clear!', @rcode=1
    	goto bspexit
    	end
    if @inuseby<>SUSER_SNAME()
    	begin
    	select @errmsg='Batch is already in use by @inuseby ' + @inuseby + '!', @rcode=1
    	goto bspexit
    	end
   
    if @tablename='ARBH'
    	begin
    	delete from bARBC where ARCo=@co and Mth=@mth and BatchId=@batchid
    	delete from bARBM where Co=@co and Mth=@mth and BatchId=@batchid
    	delete from bARBI where ARCo=@co and Mth=@mth and BatchId=@batchid
    	delete from bARBJ where ARCo=@co and Mth=@mth and BatchId=@batchid
    	delete from bARBA where Co=@co and Mth=@mth and BatchId=@batchid
    	delete from bARBL where Co=@co and Mth=@mth and BatchId=@batchid
    	delete from bARBH where Co=@co and Mth=@mth and BatchId=@batchid
    	/* clear GL Entries created for SM */
		DELETE vGLEntry
		FROM dbo.vGLEntryBatch
			INNER JOIN dbo.vGLEntry ON vGLEntryBatch.GLEntryID = vGLEntry.GLEntryID
		WHERE vGLEntryBatch.Co = @co AND vGLEntryBatch.Mth = @mth AND vGLEntryBatch.BatchId = @batchid
		DELETE dbo.vHQBatchDistribution WHERE Co = @co AND Mth = @mth AND BatchId = @batchid
    	end
   
    update bHQBC set Status=6 where Co=@co and Mth=@mth and BatchId=@batchid
   
    bspexit:
   
    	return @rcode



GO
GRANT EXECUTE ON  [dbo].[bspARBatchClear] TO [public]
GO
