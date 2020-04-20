SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspGLDBPost    Script Date: 11/26/2003 12:12:03 PM ******/
   CREATE     proc [dbo].[bspGLDBPost]
   /************************************************************************
   * Created by: ????
   * Modified by: kb 10/30/98
   *              mh 10/11/00 - Added Attachment code.
   *              MV 06/21/01 - Issue 12769 BatchUserMemoUpdate
   *              TV/RM 02/22/02 Attachment Fix
   *				GG 04/08/02 - #16702 - remove parameter from bspBatchUserMemoUpdate
   *				SR 08/08/02 - #15111 - intercompany posting
   *				GG 12/03/02 - #19372 - cleanup
   *				MV 01/31/03 - #20246 - dbl quote cleanup.
   *				GG 03/14/03 - #20660 skip GL Trans# update back to batch for intercompany entries 
   *				DC 11/26/03 - 23061 - Check for ISNull when concatenating fields to create descriptions
   *				ES 03/31/04 - 18616 - re-index attachments
   *				GP 05/14/09 - 133435 Removed HQAT update/delete code
   *
   * Posts a  validated batch of GLDB entries
   *
   * pass in Co#, Month, Batch ID#, and Posting Date
   * deletes successfully posted bGLDB rows
   * clears bGLDA and bHQCC when complete
   *
   * returns 1 and message if error
   ************************************************************************/
      	(@co bCompany, @mth bMonth, @batchid bBatchID, @dateposted bDate = null, @errmsg varchar(100) output)
      
   as
   
   set nocount on
     
   declare @rcode int, @opencursor tinyint, @source bSource, @tablename char(20),
   	@inuseby bVPUserName, @status tinyint, @adj bYN, @seq int, @transtype char(1),
   	@gltrans bTrans, @glacct bGLAcct, @jrnl bJrnl, @glref bGLRef, @actdate bDate,
   	@description bTransDesc, @amt bDollar, @errors varchar(30), @lastseq int,
      	@keyfield varchar(128), @updatekeyfield varchar(128), @deletekeyfield varchar(128),
      	@guid uniqueIdentifier, @interco bCompany, @oldnew tinyint
     
    
   select @rcode = 0, @opencursor = 0

  
      /* check for date posted */
      if @dateposted is null
      	begin
      	select @errmsg = 'Missing posting date!'
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
      if @source <> 'GL Jrnl'
      	begin
      	select @errmsg = 'Invalid Batch source - must be ''GL Jrnl''!', @rcode = 1
      	goto bspexit
      	end
      if @tablename <> 'GLDB'
      	begin
      	select @errmsg = 'Invalid Batch table name - must be ''GLDB''!', @rcode = 1
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
     
   -- declare cursor on GL Detail Batch Account Distributions for posting - use bGLDA because it may contain
   -- intercompany entries added during batch validation 
   declare bcGLDA cursor for
   select a.BatchSeq, a.OldNew, b.BatchTransType, a.GLTrans, a.GLAcct, a.Jrnl,
      	a.GLRef, a.Source, a.ActDate, a.Description, a.Amount, b.UniqueAttchID, a.InterCo
   from bGLDA a
   join bGLDB b on a.Co = b.Co and a.Mth=b.Mth and a.BatchId = b.BatchId and a.BatchSeq = b.BatchSeq
   where a.Co = @co and a.Mth = @mth and a.BatchId = @batchid 
     
   /* open cursor */
   open bcGLDA
   select @opencursor = 1
     
   /* loop through all rows in this batch */
   posting_loop:
   	fetch next from bcGLDA into @seq, @oldnew, @transtype, @gltrans, @glacct, @jrnl,
      		@glref, @source, @actdate, @description, @amt, @guid, @interco
     
      	if (@@fetch_status <> 0) goto posting_loop_end
     
    	begin transaction
     
      	if @transtype = 'A' and @oldnew = 1		/* add new GL transactions */
      		begin
    		-- get next available transaction # for GL Detail - use Inter GL Co#
      		exec @gltrans = bspHQTCNextTrans 'bGLDT', @interco, @mth, @errmsg output
      	    if @gltrans = 0 goto posting_error 
   
      		insert bGLDT (GLCo, Mth, GLTrans, GLAcct, Jrnl, GLRef, SourceCo, Source, ActDate, DatePosted,
   			Description, BatchId, Amount, RevStatus, Adjust, InUseBatchId, Purge, UniqueAttchID)
      		values (@interco, @mth, @gltrans, @glacct, @jrnl, @glref, @co, @source, @actdate, @dateposted,
   			@description, @batchid, @amt, 0, @adj, null, 'N', @guid)
   
   		
    		/* update GLTrans in batch table bGLDB for BatchUserMemoUpdate */
           if @interco = @co	-- #20660 skip GL Trans# update back to batch for intercompany entries 
   			begin
   			update bGLDB set GLTrans = @gltrans
           	where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq 
   			if @@rowcount = 0 goto posting_error
   			end
      
        	end 
     
      	if @transtype = 'C' and @oldnew = 1		/* update existing GL transaction */
      		begin
      		update bGLDT
      		set GLAcct = @glacct, ActDate = @actdate, Description = @description,
      			BatchId = @batchid, Amount = @amt, InUseBatchId = null, UniqueAttchID = @guid
      		where GLCo = @co and Mth = @mth and GLTrans = @gltrans
      		if @@rowcount = 0 goto posting_error
   
      		end
     
      	if @transtype = 'D' and @oldnew = 0		/* delete existing GL transaction */
      		begin
      		delete bGLDT where GLCo = @co and Mth = @mth and GLTrans = @gltrans
      		if @@rowcount = 0  goto posting_error
   
     		end
   
   	/* call bspBatchUserMemoUpdate to update user memos in bGLDT before deleting the batch record */
     	if @transtype in ('A','C')
         	begin
         	exec @rcode = bspBatchUserMemoUpdate @co, @mth, @batchid, @seq, 'GL JournalEntry', @errmsg output
         	if @rcode <> 0
             	begin
             	select @errmsg = 'Unable to update User Memo in GLDT.'
     			goto posting_error
             	end
         	end
   
   	-- remove GL Distribution
   	delete bGLDA
   	where Co = @co and Mth = @mth and BatchId = @batchid and Jrnl = @jrnl and GLRef = @glref
   		and GLAcct = @glacct and BatchSeq = @seq and OldNew = @oldnew and InterCo = @interco
   	if @@rowcount <> 1 
   		begin
           select @errmsg = 'Unable to remove GL distribution entry from bGLDA.'
     		goto posting_error
           end
     
      	/* commit transaction */
      	commit transaction
   
   	 -- issue 18616 Refresh indexes for this header if attachments exist
   	 if @guid is not null exec bspHQRefreshIndexes null, null, @guid, null
     
      	goto posting_loop
     
     
   posting_error:		/* error occured within transaction - rollback any updates and continue */
      	rollback transaction
   	select @rcode = 1
      	goto bspexit
     
     
   posting_loop_end:	/* no more rows to process */
   	close bcGLDA
   	deallocate bcGLDA
   	select @opencursor = 0
   
      	/* make sure batch is empty */
      	if exists(select 1 from bGLDA where Co = @co and Mth = @mth and BatchId = @batchid)
      		begin
      		select @errmsg = 'Not all entries were posted - unable to close batch!', @rcode = 1
      		goto bspexit
      		end
   
   	/* clear GL Detail Audit entries */
      	delete bGLDB where Co=@co and Mth=@mth and BatchId=@batchid 
   
   	/* delete HQ Close Control entries */
      	delete bHQCC where Co = @co and Mth = @mth and BatchId = @batchid
     
      	/* set HQ Batch status to 5 (posted) */
      	update bHQBC
      	set Status = 5, DateClosed = getdate()
      	where Co = @co and Mth = @mth and BatchId = @batchid
      	if @@rowcount = 0
      		begin
      		select @errmsg = 'Unable to update HQ Batch Control information!'
      		goto bspexit
      		end
     
   bspexit:
      	if @opencursor = 1
      		begin
      		close bcGLDA
      		deallocate bcGLDA
      		end
     
      	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspGLDBPost] TO [public]
GO
