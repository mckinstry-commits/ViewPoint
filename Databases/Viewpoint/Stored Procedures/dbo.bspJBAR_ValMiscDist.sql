SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJBAR_ValMiscDist    Script Date: 8/28/99 9:34:07 AM ******/
   CREATE proc [dbo].[bspJBAR_ValMiscDist]
   /***********************************************************
   * CREATED BY: 	 bc 10/26/99
   * MODIFIED By : TJL 09/20/03 - Issue #22126, Performance mods, added noLocks to this procedure, remove psuedo cursors
   *
   * USAGE:
   * Validates each entry in bJBBM for a selected batch - must be called
   * prior to posting the batch. Called by Invoice Val and Posting Val
   *
   * INPUT PARAMETERS
   *   co        JB Co
   *   mth       Month of batch
   *   batchid    Batch ID to validate
   * OUTPUT PARAMETERS
   *   @errmsg     if something went wrong
   * RETURN VALUE
   *   0   success
   *   1   fail
   *****************************************************/
   @co bCompany, @mth bMonth, @batchid bBatchID, @seq int, @errmsg varchar(255) output
   as
   
   set nocount on
   
   declare @bmCode char(10), @bmGroup bGroup, @rcode int,
   	@errorstart varchar(50),@errortext varchar(255), @openJBBMcursor int
   
   --@BatchSeq int, 
   
   select @rcode=0, @openJBBMcursor = 0
   
   /* Validate Misc Distribution Codes */
   declare bcJBBM cursor local fast_forward for
   select CustGroup, MiscDistCode
   from bJBBM with (nolock)
   where JBCo = @co and Mth=@mth and BatchId = @batchid and BatchSeq = @seq 
   
   open bcJBBM
   select @openJBBMcursor = 1
   	
   fetch next from bcJBBM into @bmGroup, @bmCode
   while @@fetch_status = 0
    	begin
   	select @errorstart = 'Seq# ' + convert(varchar(6),@seq)
   
   	/* Validate Dist Code*/
   	exec @rcode = bspARMiscDistCodeVal @bmGroup, @bmCode, @errmsg output
   	if @rcode <> 0
   		begin
   		select @errortext = @errorstart + ' - Misc Dist Code :' + isnull(@bmCode,'') +', ' +  isnull(@errmsg,'')
   		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   		if @rcode <> 0 goto bspexit
   		end
   
   	fetch next from bcJBBM into @bmGroup, @bmCode
   	end 
   
   bspexit:
   if @openJBBMcursor = 1
   	begin
   	close bcJBBM
   	deallocate bcJBBM
   	select @openJBBMcursor = 0
   	end
   
   if @rcode <> 0 select @errmsg = @errmsg		--+ char(13) + char(10) + '[bspJBAR_ValMiscDist]'
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBAR_ValMiscDist] TO [public]
GO
