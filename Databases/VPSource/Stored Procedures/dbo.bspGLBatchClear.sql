SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspGLBatchClear    Script Date: 11/25/2003 8:10:39 AM ******/
   
   
   CREATE   procedure [dbo].[bspGLBatchClear]
    /*************************************************************************************************
     * CREATED BY: MH 10/20/99
     * MODIFIED By :	MV 01/31/03 - #20246 dbl quote cleanup.
     *			DC 11/25/03 - 23061 Check for ISNull when concatenating fields to create descriptions
	 *          DW 07/13/12 - TK-16355 - Modified the 'BatchClear' stored procedures to delete from the batch tables instead of the batch views.
     * USAGE:
     * Clears GL batch tables
     *
     * INPUT PARAMETERS
     *   Co          Company
     *   Month       Month of batch
     *   BatchId     Batch ID
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
    from dbo.bHQBC WITH (NOLOCK)
    where Co=@co and Mth=@mth and BatchId=@batchid
   --mark
    select Status, InUseBy, TableName from bHQBC where Co = @co and Mth = @mth and BatchId = @batchid
   
   --goto bspexit
   --end mark
   
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
    	select @errmsg='Batch is already in use by: ' + ISNULL(@inuseby,'MISSING, @inuseby') + '!', @rcode=1
    	goto bspexit
    	end
   
    if @tablename='GLRB'
    	begin
    	delete from bGLRB where Co=@co and Mth=@mth and BatchId=@batchid
    	delete from bGLRA where Co=@co and Mth=@mth and BatchId=@batchid
     	end
   
    if @tablename = 'GLDB'
    	begin
    	delete from bGLDB where Co=@co and Mth=@mth and BatchId=@batchid
    	delete from bGLDA where Co=@co and Mth=@mth and BatchId=@batchid
     	end
   
    if @tablename = 'GLJB'
    	begin
    	delete from bGLJB where Co=@co and Mth=@mth and BatchId=@batchid
    	delete from bGLJA where Co=@co and Mth=@mth and BatchId=@batchid
     	end
   
    delete from bHQCC where Co=@co and Mth=@mth and BatchId=@batchid
   
    update bHQBC set Status=6 where Co=@co and Mth=@mth and BatchId=@batchid
   
    bspexit:
   
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspGLBatchClear] TO [public]
GO
