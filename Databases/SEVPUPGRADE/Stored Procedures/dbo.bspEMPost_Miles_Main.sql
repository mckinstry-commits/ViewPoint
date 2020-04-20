SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE       procedure [dbo].[bspEMPost_Miles_Main]
   /***********************************************************
   * CREATED BY: JM 10/8/99
   * MODIFIED By :	CMW 04/04/02 - added bHQBC.Notes interface levels update (issue # 16692).
   *				JM 08/09/02 - Rewritten for new header-detail form design and new tables - ref Issue 17838
   *				TV 02/11/04 - 23061 added isnulls
   *				GP 10/31/08	- Issue 130576, changed text datatype to varchar(max)
   *
   * USAGE:
   * 	Posts a validated batch of bEMMH/bEMML entries to bEMMS, deletes
   *	successfully posted bEMMH/bEMML rows, clears bHQCC when complete.
   *
   * INPUT PARAMETERS
   *   	EMCo        	EM Co
   *   	Month       	Month of batch
   *   	BatchId     	Batch ID to validate
   *   	PostingDate 	Posting date to write out if successful
   *
   * OUTPUT PARAMETERS
   *   	@errmsg     	If something went wrong
   *
   * RETURN VALUE
   *   	0   		Success
   *   	1   		fail
   *****************************************************/
   (@co bCompany,
   @mth bMonth,
   @batchid bBatchID,
   @dateposted bDate = null,
   @errmsg varchar(255) output)
   
   as
   
   set nocount on
   
   declare @rcode int,
   	@status tinyint,
   	@notes varchar(256)
   
   select @rcode = 0
   
   /* Check for date posted. */
   if @dateposted is null
   	begin
   	select @errmsg = 'Missing posting date!', @rcode = 1
   	goto bspexit
   	end
   
   /* Validate HQ Batch. */
   exec @rcode = dbo.bspHQBatchProcessVal @co, @mth, @batchid, 'EMMiles', 'EMMH', @errmsg output, @status output
   	if @rcode <> 0 goto bspexit
   	if @status <> 3 and @status <> 4 /* valid - OK to post, or posting in progress. */
   		begin
   		select @errmsg = 'Invalid Batch Status-must be Valid-OK To Post or
   		Posting In Progress!', @rcode = 1
   		goto bspexit
   		end
   
   /* Set HQ Batch status to 4 (posting in progress). */
   update bHQBC set Status = 4, DatePosted = @dateposted where Co = @co and Mth = @mth and BatchId = @batchid
   	if @@rowcount = 0
   	begin
   	select @errmsg = 'Unable to update HQ Batch Control information!',
   	@rcode = 1
   	goto bspexit
   	end
   
   /* **************************** */
   /* Insert records in bEMSM and EMSD.  */
   /* **************************** */
   exec @rcode = dbo.bspEMPost_Miles_EMSM_Inserts @co, @mth, @batchid,@dateposted, @errmsg output
   	if @rcode <> 0
   	begin
   	select @errmsg = @errmsg, @rcode = 1
   	goto bspexit
   	end
   
   /* ************** */
   /* Close routine. */
   /* ************** */
   -- set interface levels note string
   select @notes = Notes from bHQBC where Co = @co and Mth = @mth and BatchId = @batchid
   if @notes is NULL select @notes='' else select @notes=@notes + char(13) + char(10)
   	select @notes=@notes + 'GL Adjustments Interface Level set at: ' + isnull(convert(char(1), a.AdjstGLLvl),'') + char(13) + char(10) +
   		'GL Usage Interface Level set at: ' + isnull(convert(char(1), a.UseGLLvl),'') + char(13) + char(10) +
   		'GL Parts Interface Level set at: ' + isnull(convert(char(1), a.MatlGLLvl),'') + char(13) + char(10)
   	from bEMCO a where EMCo=@co
   
   /* Delete HQ Close Control entries. */
   delete bHQCC where Co = @co and Mth = @mth and BatchId = @batchid
   
   /* Set HQ Batch status to 5 (posted). */
   update bHQBC set Status = 5, DateClosed = getdate(), Notes = convert(varchar(max),@notes) where Co = @co and Mth = @mth and BatchId = @batchid
   if @@rowcount = 0
   	begin
   	select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
   	goto bspexit
   	end
   
   bspexit:
   if @rcode<>0 select @errmsg=isnull(@errmsg,'')	--+ char(13) + char(10) + '[bspEMPost_Miles_Main]'
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMPost_Miles_Main] TO [public]
GO
