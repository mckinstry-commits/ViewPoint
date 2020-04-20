SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspGLRBPost    Script Date: 8/28/99 9:36:17 AM ******/
    CREATE     procedure [dbo].[bspGLRBPost]
    /************************************************************************
    * CREATED: ??
    * MODIFIED: kb 12/6/98
    *           MV 06/21/01 - Issue 12769 BatchUserMemoUpdate
    *			 GG 04/08/02 - #16702 - remove parameter from bspBatchUserMemoUpdate
    *			 MV 01/31/03 - #20246 dbl Quote cleanup.
    *			DC 12/02/03 - #23061 - Check for ISNull when concatenating fields to create descriptions
    *			ES 03/31/04 - 18616 - re-index attachments
    *			GP 05/14/09 - 133435 Removed HQAT update code
    *
    * Posts a  validated batch of GLRB entries
    *
    * pass in Co#, Month, Batch ID#, and Posting Date
    * deletes successfully posted bGLRB rows
    * clears bHQCC when complete
    *
    * returns 1 and message if error
    ************************************************************************/
   
    	(@co bCompany, @mth bMonth, @batchid bBatchID,
    	@dateposted bDate = null, @errmsg varchar(60) output)
   
    as
    set nocount on
   
    declare @rcode int, @opencursor tinyint, @source bSource, @tablename char(20),
    	 @inuseby bVPUserName, @status tinyint, @adj bYN, @seq int,
    	 @gltrans bTrans, @glacct bGLAcct, @jrnl bJrnl, @glref bGLRef,
    	 @description bTransDesc, @amt bDollar, @origmonth bMonth,
    	 @origgltrans bTrans, @actdate bDate, @guid uniqueIdentifier
   
    select @rcode = 0
   
    /* set open cursor flag to false */
    select @opencursor = 0
   
    /* check for date posted */
    if @dateposted is null
   
    	begin
    	select @errmsg = 'Missing posting date!', @rcode = 1
    	goto bspexit
    	end
   
    /* validate HQ Batch */
    select @source = Source, @tablename = TableName, @inuseby = InUseBy,
    	@status = Status, @adj = Adjust
    	from dbo.bHQBC with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid
    if @@rowcount = 0
    	begin
    	select @errmsg = 'Invalid Batch - missing from HQ Batch Control!', @rcode = 1
    	goto bspexit
    	end
    if @source <> 'GL Rev'
    	begin
    	select @errmsg = 'Invalid Batch source - must be ''GL Rev''!', @rcode = 1
    	goto bspexit
    	end
    if @tablename <> 'GLRB'
    	begin
    	select @errmsg = 'Invalid Batch table name - must be ''GLRB''!', @rcode = 1
    	goto bspexit
    	end
    if @inuseby is null
    	begin
    	select @errmsg = 'HQ Batch Control must first be updated as ''In Use''!', @rcode = 1
    	goto bspexit
    	end
    if @inuseby <> SUSER_SNAME()
    	begin
    	select @errmsg = 'Batch already in use by ' + isnull(@inuseby,'MISSING: @inuseby'), @rcode = 1
    	goto bspexit
    	end
    if @status <> 3 and @status <> 4	/* valid - OK to post, or posting in progress */
    	begin
    	select @errmsg = 'Invalid Batch status -  must be ''valid - OK to post'' or ''posting in progress''!', @rcode = 1
    	goto bspexit
    	end
   
    /* set HQ Batch status to 4 (posting in progress) */
    update bHQBC
    	set Status = 4, DatePosted = @dateposted
    	where Co = @co and Mth = @mth and BatchId = @batchid
    if @@rowcount = 0
   
    	begin
    	select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
    	goto bspexit
    	end
   
    /* declare cursor on GL Detail Batch for posting */
    declare bcGLRB cursor for select BatchSeq, OrigMonth, OrigGLTrans, GLAcct, Jrnl,
    	GLRef, Description, Amount, ActDate, UniqueAttchID
    	from bGLRB where Co = @co and Mth = @mth and BatchId = @batchid for update
   
    /* open cursor */
    open bcGLRB
   
    /* set open cursor flag to true */
    select @opencursor = 1
   
    /* loop through all rows in this batch */
    posting_loop:
    	fetch next from bcGLRB into @seq, @origmonth, @origgltrans, @glacct, @jrnl,
    		@glref, @description, @amt, @actdate, @guid
   
    	if (@@fetch_status <> 0) goto posting_loop_end
   
    	begin transaction
   
    	/* get next available transaction # for GLDT */
    	select @tablename = 'bGLDT'
    	exec @gltrans = bspHQTCNextTrans @tablename, @co, @mth, @errmsg output
    	if @gltrans = 0 goto posting_error
   
   
           /* insert GL Detail */
           insert bGLDT (GLCo, Mth, GLTrans, GLAcct, Jrnl, GLRef, SourceCo, Source, ActDate,
    		DatePosted, Description, BatchId, Amount, RevStatus, Adjust, InUseBatchId, Purge)
    	    values (@co, @mth, @gltrans, @glacct, @jrnl, @glref, @co, 'GL Rev', @actdate,
    		@dateposted, @description, @batchid, @amt, 2, @adj, null, 'N')
     	    if @@rowcount = 0 goto posting_error
   
            /* update the original entry as reversed */
          	update bGLDT set RevStatus = 1
        		where GLCo = @co and Mth = @origmonth and GLTrans = @origgltrans
          	if @@rowcount = 0 goto posting_error
     
       /* call bspBatchUserMemoUpdate to update user memos in bGLDT before deleting the batch record */
       if exists (select * from bGLRB where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq= @seq)
       begin
       exec @rcode = bspBatchUserMemoUpdate @co, @mth, @batchid, @seq, 'GL Reversal', @errmsg output
       if @rcode <> 0
           begin
           select @errmsg = 'Unable to update User Memo in GLDT.', @rcode = 1
   		goto posting_error
           end
       end
   
    	/* delete current row from cursor */
           /* delete trigger on bGLRB will null out InUseBatchID on orig trans in bGLDT */
    	delete from bGLRB where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq= @seq
   
    	commit transaction
   	 
   	-- issue 18616 Refresh indexes for this header if attachments exist
   	if @guid is not null exec bspHQRefreshIndexes null, null, @guid, null
   
    	goto posting_loop
   
   
    posting_error:	/* error occured within transaction - rollback any updates and continue */
    	rollback transaction
    	goto posting_loop
   
   
   
    posting_loop_end:	/* no more rows to process */
    	/* make sure batch is empty */
    	if exists(select * from bGLRB where Co = @co and Mth = @mth and BatchId = @batchid)
    		begin
    		select @errmsg = 'Not all batch entries were posted - unable to close batch!', @rcode = 1
    		goto bspexit
    		end
   
    	/* delete HQ Close Control entries */
    	delete bHQCC where Co = @co and Mth = @mth and BatchId = @batchid
   
    	/* clear GL Reversal Audit entries */
    	delete bGLRA where Co = @co and Mth = @mth and BatchId = @batchid
   
    	/* set HQ Batch status to 5 (posted) */
    	update bHQBC
    	set Status = 5, DateClosed = getdate()
    	where Co = @co and Mth = @mth and BatchId = @batchid
    	if @@rowcount = 0
    		begin
    		select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
    		goto bspexit
    		end
   
   
    bspexit:
    	if @opencursor = 1
    		begin
    		close bcGLRB
    		deallocate bcGLRB
    		end
   
   
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspGLRBPost] TO [public]
GO
