SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspGLDBInsertExistingTrans]
   /************************************************************************
   * Created: ??
   * Modified: MV 7/3/01 - Issue 12769 BatchUserMemoInsertExisting
   *           TV 05/29/02 - insert UniqueAttchID into batch Table
   *			 SR 08/12/02 - error if dbsource='GL JrnlXCo'
   *			GG 03/12/02 - #19372 - initialize bGLDB.InterCo from bGLDT, cleanup
   *		DC 23061 - Check for ISNull when concatenating fields to create descriptions
   *		ES 04/12/04 - Issue 18616 QA caught that the guid was pulling from the wrong table
   *		GG 09/30/05 - #29523 - pass back warning message with reversed or reversing entries (RevStatus = 1 or 2) 
   *		GP 02/15/09 - Issue 135418 added cursor to cycle through multiple GLDT records, validate, insert, and display errors last
   *		GP 07/29/10 - Issue 140775 fixed where clause in cursor select to use "or" for Trans OR Journal & Ref
   *		GF 07/30/2010 - issue #140779 was not writing the GL Trans to batch table when pulling transactions in
   *						by journal and reference.
	*		AMR 01/12/11 - Issue #142350, making case sensitive by removing unused vars and renaming same named variables
   *
   * This procedure is used by the GL Journal Entry program to pull existing
   * transactions from bGLDT into bGLDB for editing.
   *
   * Checks batch info in bHQBC, and transaction info in bGLDT.
   * Adds entry to next available Seq# in bGLDB
   *
   * GLDB insert trigger will update InUseBatchId in bGLDT
   *
   * Input:
   *	@co			GL Company #
   *	@mth		Month
   *	@batchid	Batch ID#
   *	@gltrans	GL Transaction to pull into batch
   *
   * Output:
   *	@msg		Warning or error message
   *
   * Return Code:
   *	0 = success
   *	1 = error with message
   *	2 = success with warning 
   *
   *************************************************************************/
   
   	@co bCompany = null, @mth bMonth = null, @batchid bBatchID = null,
   	@gltrans bTrans = null, @Jrnl bJrnl = null, @GLRef bGLRef = null, @errmsg varchar(255) output
   
   as
   set nocount on
   
   declare @rcode int, @source bSource, @tablename char(20), @inuseby bVPUserName, @status tinyint,
   	@adj bYN, @glacct bGLAcct, @JrnlCur bJrnl, @GLRefCur bGLRef, @dtsource bSource, @actdate bDate,
    	@desc bTransDesc, @amt bDollar, @dtadj bYN, @inusebatchid bBatchID, @seq int, 
       @uniqueattchid uniqueidentifier, @interco bCompany, @revstatus tinyint, @rc int,
       @opencursor tinyint, @AnotherBatch char(1), @NotGLSource char(1), @InAdjPeriod char(1),
       @OutOfAdjPeriod char(1), @RevFail1 char(1), @RevFail2 char(1),
       @GLDT_GLTrans bTrans, @Record_Count int ---#140779
      
   set @rcode = 0
   select @opencursor = 0, @AnotherBatch = 'N', @NotGLSource = 'N', @InAdjPeriod = 'N',
       @OutOfAdjPeriod = 'N', @RevFail1 = 'N', @RevFail2 = 'N', @Record_Count = 0
   
   /* validate HQ Batch */
   select @source = Source, @tablename = TableName, @inuseby = InUseBy,
   	@status = Status, @adj = Adjust--, @uniqueattchid = UniqueAttchID  Issue 18616
   from dbo.bHQBC with (nolock)
   where Co = @co and Mth = @mth and BatchId = @batchid
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
   if @inuseby <> SUSER_SNAME()
    	begin
    	select @errmsg = 'Batch already in use by ' + isnull(@inuseby,'MISSING: @inuseby'), @rcode = 1
    	goto bspexit
    	end
   if @status <> 0
    	begin
    	select @errmsg = 'Invalid Batch status -  must be ''open''!', @rcode = 1
    	goto bspexit
    	end

	declare bcGLDT cursor local fast_forward for
	----#140779
	select GLTrans, GLAcct, Jrnl, GLRef, Source, ActDate, Description, Amount, Adjust, InUseBatchId, SourceCo, UniqueAttchID, RevStatus
	from dbo.bGLDT with (nolock)
	where GLCo=@co and Mth=@mth and (GLTrans=@gltrans or (Jrnl=@Jrnl and GLRef=@GLRef))

	open bcGLDT
	select @opencursor = 1


gl_posting_loop:
	----#140779
	fetch next from bcGLDT into @GLDT_GLTrans, @glacct, @JrnlCur, @GLRefCur, @dtsource, @actdate, @desc, @amt, @dtadj, @inusebatchid, @interco,
		@uniqueattchid, @revstatus
	if @@fetch_status <> 0 goto gl_posting_end
   
   /* validate existing GL Trans */
    if @inusebatchid is not null
    	begin
    	set @AnotherBatch = 'Y'
    	goto gl_posting_loop
    	end
  if substring(@dtsource,1,2) <> 'GL' or @dtsource = 'GL JrnlXCo'
		begin
		select @NotGLSource = 'Y'
		goto gl_posting_loop
		end 	
   if @dtadj <> @adj
    	begin
    	if @dtadj = 'Y'
    		begin
    		set @InAdjPeriod = 'Y'
    		end
    	if @dtadj = 'N'
    		begin
    		set @OutOfAdjPeriod = 'Y'
    		end	
		goto gl_posting_loop
    	end
   -- #29523 - add check for Reversal Status
   if @revstatus = 1 
   	begin
   	set @RevFail1 = 'Y'
   	end
   if @revstatus = 2 
   	begin
   	set @RevFail2 = 'Y'
   	end
   
   /* get next available sequence # for this batch */
   select @seq = isnull(max(BatchSeq),0) + 1
   from bGLDB
   where Co = @co and Mth = @mth and BatchId = @batchid
   
   /* add GL transaction to batch */
   ----#140779
   insert bGLDB (Co, Mth, BatchId, BatchSeq, BatchTransType, GLTrans, GLAcct, Jrnl, GLRef, Source,
    	ActDate, Description, Amount, OldGLAcct, OldActDate, OldDesc, OldAmount, UniqueAttchID, InterCo)
   values (@co, @mth, @batchid, @seq, 'C', @GLDT_GLTrans, @glacct, @JrnlCur, @GLRefCur, @dtsource, @actdate,
    	@desc, @amt, @glacct, @actdate, @desc, @amt, @uniqueattchid, @interco)
    
   /* BatchUserMemoInsertExisting - update the user memo in the batch record */
   exec @rc =  bspBatchUserMemoInsertExisting @co, @mth, @batchid, @seq, 'GL JournalEntry', 0, @errmsg output
   if @rc <> 0
   	begin
   	select @errmsg = 'Unable to update User Memos in GLDB', @rcode = 1
   	goto bspexit
   	end

	set @Record_Count = @Record_Count + 1
    goto gl_posting_loop
    
    
gl_posting_end:
	close bcGLDT
    deallocate bcGLDT
	set @opencursor = 0
	
	if @RevFail1 = 'Y' select @errmsg = char(10) + char(13) + 'Warning: Transaction has been reversed.  Changing or deleting this transaction will not'
  		+ char(13) + 'affect its reversing entry, nor will this transaction be reversed again.', @rcode = 2
	if @RevFail2 = 'Y' select @errmsg = @errmsg + char(10) + char(13) + 'Warning: Transaction posted from a reversal batch.  Changing or deleting this transaction'
  		+ char(13) + 'will not affect its originally reversed entry.', @rcode = 2
	if @AnotherBatch = 'Y' select @errmsg = @errmsg + char(10) + char(13) + 'in another batch...', @rcode = 1
	if @NotGLSource = 'Y' select @errmsg = @errmsg + char(10) + char(13) + 'source other than GL...', @rcode = 1
	if @InAdjPeriod = 'Y' select @errmsg = @errmsg + char(10) + char(13) + 'posted in an adjustment period...', @rcode = 1
	if @OutOfAdjPeriod = 'Y' select @errmsg = @errmsg + char(10) + char(13) + 'posted outside of an adjustment period...', @rcode = 1



   bspexit:
	if @rcode = 0 and @Record_Count = 0
		begin
		if isnull(@errmsg,'') = '' set @errmsg = 'No Records exist that meet the criteria.'
		set @rcode = 1
		end
	if @rcode = 1 select @errmsg = isnull(@errmsg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspGLDBInsertExistingTrans] TO [public]
GO
