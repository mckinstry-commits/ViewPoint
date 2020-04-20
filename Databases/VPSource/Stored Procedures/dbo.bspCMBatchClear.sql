SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     procedure [dbo].[bspCMBatchClear]
    /*************************************************************************************************
     * CREATED BY: MH 09/27/99
     * MODIFIED By : TV/RM 02/22/02 Attachment Fix
     * 				RM 07/29/03 Cleaned up Attachment Code (21576)
	 *				mh 05/18/09 Issue 133433/127603
	 *              DW 07/13/12 - TK-16355 - Modified the 'BatchClear' stored procedures to delete from the batch tables instead of the batch views.
     * USAGE:
     * Clears CM batch tables
     *
     * INPUT PARAMETERS
     *   CMCo        AR Co
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
   
    declare @rcode int, @source bSource, @tablename char(20), @status tinyint, @inuseby bVPUserName,
            @openattcursor int, @batchseq int, @keyfield varchar(255), @guid uniqueIdentifier
    select @rcode = 0, @openattcursor = 0
   
    select @status=Status, @inuseby=InUseBy, @tablename=TableName
    from bHQBC
    where Co=@co and Mth=@mth and BatchId=@batchid

    select [Status], InUseBy, TableName from bHQBC where Co = @co and Mth = @mth and BatchId = @batchid
 
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
   
	if @tablename='CMDB'
	begin
		delete from bCMDB where Co=@co and Mth=@mth and BatchId=@batchid
		delete from bCMDA where CMCo=@co and Mth=@mth and BatchId=@batchid
		delete from bHQCC where Co=@co and Mth=@mth and BatchId=@batchid
	end
   
	if @tablename = 'CMTB'
	begin
		delete from bCMTB where Co=@co and Mth=@mth and BatchId=@batchid
		delete from bCMTA where Co=@co and Mth=@mth and BatchId=@batchid
		delete from bHQCC where Co=@co and Mth=@mth and BatchId=@batchid
	end
   
   
    update bHQBC set Status=6 where Co=@co and Mth=@mth and BatchId=@batchid
   
    bspexit:
   
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspCMBatchClear] TO [public]
GO
