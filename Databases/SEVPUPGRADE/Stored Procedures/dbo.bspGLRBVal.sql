SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspGLRBVal    Script Date: 8/28/99 9:36:18 AM ******/
   CREATE    procedure [dbo].[bspGLRBVal]
   /************************************************************************
    * Created: ??
    * Modified: GG 05/20/98
    *           LM 3/30/99 changed sum(isnull... to isnull(sum...
    *			 MV 01/31/03 - #20246 dbl quote cleanup.
    *			 MV 02/11/03 - #20285 - exclude memo accts from check of Journal/GL Reference totals
    *			DC 12/2/03 - 23061 - Check for ISNull when concatenating fields to create descriptions
    *
    * Validates each entry in bGLRB for a select batch - must be called
    * prior to posting the batch.
    *
    * After initial Batch and GL checks, bHQBC Status set to 1 (validation in progress)
    *
    * bHQBE (Batch Errors), and bGLRA (GL Reversal Audit) entries are deleted.
    *
    * Creates a cursor on bGLRB to validate each entry individually.
    *
    * Errors in batch added to bHQBE using bspHQBEInsert
    *
    * Account distributions added to bGLRA
    *
    * Jrnl and GL Reference debit and credit totals must balance
    *
    * bHQBC Status updated to 2 if errors found, or 3 if OK to post
    *
    * pass in Co, Month, and BatchId
    * returns 0 if successfull (even if entries addeed to bHQBE)
    * returns 1 and error msg if failed
    *
    *************************************************************************/
   
   	@co bCompany, @mth bMonth, @batchid bBatchID,@errmsg varchar(60) output
   
   as
   set nocount on
   declare @rcode int, @source bSource, @tablename char(20), @inuseby bVPUserName, @status tinyint,
   	 @adj bYN, @opencursor tinyint, @lastglmth bMonth, @lastsubmth bMonth, @maxopen tinyint,
   	 @fy bMonth, @seq int, @origmonth bMonth, @origgltrans bTrans, @glacct bGLAcct, @revstatus tinyint,
   	 @jrnl bJrnl, @glref bGLRef, @description bTransDesc, @amt bDollar, @inusebatchid bBatchID,
   	 @errortext varchar(255), @accttype char(1), @active bYN, @glrefadj bYN, @errno int, @actdate bDate
   
   select @rcode = 0
   
   /* set open cursor flag to false */
   select @opencursor = 0
   
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
   if @status < 0 or @status > 3
   	begin
   	select @errmsg = 'Invalid Batch status!', @rcode = 1
   	goto bspexit
   	end
   if @adj = 'Y'
   
   	begin
   	select @errmsg = 'Reversal entries cannot be posted as adjustments!', @rcode = 1
   	goto bspexit
   	end
   
   /* validate GL Company and Month */
   select @lastglmth = LastMthGLClsd, @lastsubmth = LastMthSubClsd, @maxopen = MaxOpen
   	from bGLCO where GLCo = @co
   if @@rowcount = 0
   	begin
   	select @errmsg = 'Invalid GL Company #', @rcode = 1
   	goto bspexit
   	end
   if @mth <= @lastglmth or @mth > dateadd(month, @maxopen, @lastsubmth)
   	begin
   	select @errmsg = 'Not an open month', @rcode = 1
   	goto bspexit
   	end
   
   /* validate Fiscal Year */
   select @fy = FYEMO from bGLFY
   	where GLCo = @co and @mth >= BeginMth and @mth <= FYEMO
   if @@rowcount = 0
   	begin
   	select @errmsg = 'Must first add Fiscal Year', @rcode = 1
   	goto bspexit
   	end
   
   /* set HQ Batch status to 1 (validation in progress) */
   update bHQBC
   	set Status = 1
   	where Co = @co and Mth = @mth and BatchId = @batchid
   if @@rowcount = 0
   	begin
   	select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
   	goto bspexit
   	end
   
   /* clear HQ Batch Errors */
   delete bHQBE where Co = @co and Mth = @mth and BatchId = @batchid
   
   /* clear GL Reversal Audit */
   delete bGLRA where Co = @co and Mth = @mth and BatchId = @batchid
   
   /* declare cursor on GL Reversal Batch for validation */
   declare bcGLRB cursor for select BatchSeq, OrigMonth, OrigGLTrans, Jrnl, GLRef,
   	Description, GLAcct, Amount, ActDate
   	from bGLRB where Co = @co and Mth = @mth and BatchId = @batchid
   
   /* open cursor */
   open bcGLRB
   
   
   /* set open cursor flag to true */
   select @opencursor = 1
   
   /* get first row */
   fetch next from bcGLRB into @seq, @origmonth, @origgltrans, @jrnl, @glref,
   	@description, @glacct, @amt, @actdate
   
   /* loop through all rows */
   while (@@fetch_status = 0)
   	begin
   	/* validate GL Reversal Batch info for each entry */
   	select @errortext = 'Seq#' + convert(varchar(6),@seq)
   
   	/* check original GL Trans# */
   	select @inusebatchid = InUseBatchId, @revstatus = RevStatus from bGLDT
   		where GLCo = @co and Mth = @origmonth and GLTrans = @origgltrans
   	if @@rowcount = 0
   		begin
   		select @errortext = @errortext + ' - Invalid original GL Transaction to reverse.'
   		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   		if @rcode <> 0 goto bspexit
   		goto validate_glaccount
   	    	end
   	if @inusebatchid <> @batchid
   		begin
   		select @errortext = @errortext + ' - Original GL Transaction in another batch.'
   		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   		if @rcode <> 0 goto bspexit
   		end
   	if @revstatus <> 0	/* 0 = original */
   		begin
   		select @errortext = @errortext + ' - Original GL Transaction has an invalid reversal status.'
   		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   		if @rcode <> 0 goto bspexit
   		end
   
   
   	validate_glaccount:	/* validate GL Account */
   	select @accttype = AcctType, @active = Active
     	       from bGLAC where GLCo = @co and GLAcct = @glacct
   	if @@rowcount = 0
   		begin
   		select @errortext = @errortext + ' - Invalid GL Account'
   		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   		if @rcode <> 0 goto bspexit
   		goto validate_journal
   		end
   
   	if @accttype = 'H'
   		begin
   		select @errortext = @errortext + '- Cannot post to a GL Heading Account.'
   		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   		if @rcode <> 0 goto bspexit
   		end
   	if @active = 'N'
   		begin
   		select @errortext = @errortext + ' - Cannot post to an inactive GL Account.'
   		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   		if @rcode <> 0 goto bspexit
   		end
   
   	validate_journal:	/* validate Journal */
   	exec @errno = bspGLJrnlVal @co, @jrnl, @errmsg output
   
   	if @errno <> 0
   
   		begin
   		select @errortext = @errortext + ' - ' + @errmsg
   		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   		if @rcode <> 0 goto bspexit
   		end
   
   	/* if GL Reference exists validate adjustment flag */
   	select @glrefadj = Adjust from bGLRF
   		where GLCo = @co and Mth = @mth and Jrnl = @jrnl and GLRef = @glref
   	if @@rowcount <> 0 and @glrefadj <> @adj
   		begin
   		select @errortext = @errortext + ' - Batch and GL Reference Adjustment flags must match.'
   		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   		if @rcode <> 0 goto bspexit
   		end
   
   
   	/* update GLRA (Reversal Audit) */
   	insert into bGLRA (Co, Mth, BatchId, Jrnl, GLRef, GLAcct, BatchSeq, OldNew,
   		OrigMonth, OrigGLTrans, Description, Amount, ActDate)
   	values (@co, @mth, @batchid, @jrnl, @glref, @glacct, @seq, 1,
   			@origmonth, @origgltrans, @description, @amt, @actdate)
   	if @@rowcount = 0
   		begin
  
   		select @errmsg = 'Unable to update GL Reversal audit!', @rcode=1
   		goto bspexit
   		end
   
   
          fetch next from bcGLRB into @seq, @origmonth, @origgltrans, @jrnl, @glref,
   		@description, @glacct, @amt, @actdate
   
   	end
   
   /* check Journal/GL Reference totals - unbalanced entries not allowed  */
   /*select @jrnl = Jrnl, @glref = GLRef from bGLRB 
   	where Co = @co and Mth = @mth and BatchId = @batchid
   	group by Jrnl, GLRef
   	having isnull(sum(Amount),0)<>0*/
   
   -- #20285 exclude memo accts 
   select @jrnl = Jrnl, @glref = GLRef from bGLRB b join bGLAC a on b.Co=a.GLCo and b.GLAcct= a.GLAcct
   where Co = @co and Mth = @mth and BatchId = @batchid and AcctType <> 'M' -- exclude memo accounts 
     	group by Jrnl, GLRef
     	having sum(Amount) <> 0
   if @@rowcount <> 0
   	begin
   	select @errortext = 'Journal: ' + @jrnl + ' and GL Reference: ' + @glref + ' entries don''t balance!'
   	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   	if @rcode <> 0 goto bspexit
   	end
   
   
   /* check HQ Batch Errors and update HQ Batch Control status */
   select @status = 3	/* valid - ok to post */
   if exists(select * from bHQBE where Co = @co and Mth = @mth and BatchId = @batchid)
   	begin
   	select @status = 2	/* validation errors */
   	end
   update bHQBC
   	set Status = @status
   	where Co = @co and Mth = @mth and BatchId = @batchid
   if @@rowcount <> 1
   	begin
   	select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
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
GRANT EXECUTE ON  [dbo].[bspGLRBVal] TO [public]
GO
