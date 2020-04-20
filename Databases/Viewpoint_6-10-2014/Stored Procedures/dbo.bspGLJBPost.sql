SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspGLJBPost]
/************************************************************************
* CREATED: ??
* MODIFIED: kb 12/6/98
*			MV 01/31/03 - #20246 dbl quote cleanup.
*			DC 11/26/03 - Check for ISNull when concatenating fields to create descriptions
*			ES 03/31/04 - 18616 - re-index attachments
*			GG 03/31/08 - #30071 - interco auto journal entries
*			GP 05/14/09 - 133435 Removed update to HQAT
*
* Posts a validated batch of GL Auto Journal entries (bGLJB)
* 
* Inputs:
*	@co				Batch Company #
*	@mth			Batch Month
*	@batchid		Batch ID#
*	@dateposted		Date posted
*
* Outputs:
*	@errmsg			error message
*
* Return code:
*	@rcode			0 = success, 1 = error 
*
************************************************************************/
	(@co bCompany = null, @mth bMonth = null, @batchid bBatchID = null,
	 @dateposted bDate = null, @errmsg varchar(255) output)
   
 as
 set nocount on
   
 declare @rcode int, @opencursor tinyint, @source bSource, @status tinyint, @batchseq int,
   	 @gltrans bTrans, @glacct bGLAcct, @jrnl bJrnl, @glref bGLRef, @interco bCompany, 
   	 @description bTransDesc, @amount bDollar, @actdate bDate, @guid uniqueidentifier
   
select @rcode = 0, @opencursor = 0

/* check for date posted */
if @dateposted is null
	begin
	select @errmsg = 'Missing posting date!', @rcode = 1
	goto bspexit
	end
	
-- validate HQ Batch 
exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, 'GL Auto', 'GLJB', @errmsg output, @status output
if @rcode <> 0  goto bspexit
if @status <> 3 and @status <> 4	/* valid - OK to post, or posting in progress */
	begin
   	select @errmsg = 'Invalid Batch status -  must be ''valid - OK to post'' or ''posting in progress''!', @rcode = 1
   	goto bspexit
   	end
   	
/* set HQ Batch status to 4 (posting in progress) */
update dbo.bHQBC
set Status = 4, DatePosted = @dateposted
where Co = @co and Mth = @mth and BatchId = @batchid
if @@rowcount = 0
	begin
	select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
	goto bspexit
	end
   
-- declare cursor on GL Journal Batch Account Distributions for posting - use bGLJA because it may contain
-- intercompany entries added during batch validation 
declare bcGLJA cursor for
select a.BatchSeq, a.Jrnl, a.GLRef, a.Description, a.GLAcct, 
	a.Amount, a.ActDate, a.InterCo, a.Source, b.UniqueAttchID
from dbo.bGLJA a
join dbo.bGLJB b on a.Co = b.Co and a.Mth=b.Mth and a.BatchId = b.BatchId and a.BatchSeq = b.BatchSeq
where a.Co = @co and a.Mth = @mth and a.BatchId = @batchid 
   
/* open cursor */
open bcGLJA
select @opencursor = 1
   
/* loop through all rows in this batch */
posting_loop:
	fetch next from bcGLJA into @batchseq, @jrnl, @glref, @description, @glacct,
   		@amount, @actdate, @interco, @source, @guid
   	
   	if (@@fetch_status <> 0) goto posting_loop_end
   
   	/* all transactions are add */
   	begin transaction
   
   	/* get next available transaction # for GLDT  - use Inter GL Co# */
   	exec @gltrans = bspHQTCNextTrans 'bGLDT', @interco, @mth, @errmsg output
   	if @gltrans = 0 goto posting_error
   	  
           /* insert GL Detail */
    insert dbo.bGLDT(GLCo, Mth, GLTrans, GLAcct, Jrnl, GLRef, SourceCo, Source, ActDate,
   		DatePosted, Description, BatchId, Amount, RevStatus, Adjust, InUseBatchId, Purge, UniqueAttchID)
   	values (@interco, @mth, @gltrans, @glacct, @jrnl, @glref, @co, @source, @actdate,
   	 	@dateposted, @description, @batchid, @amount, 0, 'N', null, 'N', @guid)
      		
   	-- remove GL Distribution
   	delete dbo.bGLJA
   	where Co = @co and Mth = @mth and BatchId = @batchid and Jrnl = @jrnl and GLRef = @glref
   		and GLAcct = @glacct and BatchSeq = @batchseq and InterCo = @interco
   	if @@rowcount <> 1 
   		begin
           select @errmsg = 'Unable to remove GL distribution entry from bGLJA.'
     		goto posting_error
           end      

   	commit transaction
   
   	-- issue 18616 Refresh indexes for this header if attachments exist
   	if @guid is not null exec bspHQRefreshIndexes null, null, @guid, null	
   
   	goto posting_loop
   
 posting_error:		/* error occured within transaction - rollback any updates and exit */
   	rollback transaction
   	select @rcode = 1
   	goto bspexit
   
posting_loop_end:	/* no more rows to process */
	close bcGLJA
   	deallocate bcGLJA
   	select @opencursor = 0
   		
	/* make sure batch is empty */
	if exists(select * from bGLJA where Co = @co and Mth = @mth and BatchId = @batchid)
		begin
		select @errmsg = 'Not all batch entries were posted - unable to close batch!', @rcode = 1
		goto bspexit
		end
	
	/* clear GL Detail Audit entries */
	delete dbo.bGLJB where Co=@co and Mth=@mth and BatchId=@batchid 

	/* delete HQ Close Control entries */
	delete dbo.bHQCC where Co = @co and Mth = @mth and BatchId = @batchid

	/* set HQ Batch status to 5 (posted) */
	update dbo.bHQBC
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
   		close bcGLJA
   		deallocate bcGLJA
   		end
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspGLJBPost] TO [public]
GO
