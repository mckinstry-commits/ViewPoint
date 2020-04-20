SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspINCBVal    Script Date: 12/8/2003 7:16:20 AM ******/
   
   
   
   CREATE    procedure [dbo].[bspINCBVal]
   /***********************************************************
    * CREATED BY: GG 04/08/02
    * MODIFIED By:   DC 12/08/03 - 23061 - Check for ISNull when concatenating fields to create descriptions
    *
    * USAGE:
    * Validates IN Material Order Confirmation Entry batch - must be called
    * prior to posting the batch.
    *
    * Creates a cursor on bINCB to validate each entry individually
    * Calls bspINCBValDist to perform validation and generate JC and GL distributions
    *
    * INPUT PARAMETERS
    *   @co        IN Company
    *   @mth       Month of batch
    *   @batchid   Batch ID to validate
    *
    * OUTPUT PARAMETERS
    *   @errmsg     if something went wrong
    *
    * RETURN VALUE
    *   0   success
    *   1   fail
    *****************************************************/
   
   	(@co bCompany = null, @mth bMonth = null, @batchid bBatchID = null, @errmsg varchar(255) output)
    
   as
    
   set nocount on
   
   declare @rcode int, @errortext varchar(255), @inuseby bVPUserName, @status tinyint,
   	@opencursor tinyint, @errorstart varchar(50), @inglco bCompany, @jrnl bJrnl, @seq int,
   	@transtype char(1), @intrans bTrans, @oldnew tinyint, @inusebatchid bBatchID, @glco bCompany
   	
   select @rcode = 0
   
   -- validate HQ Batch 
   exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, 'MO Confirm', 'INCB', @errmsg output, @status output
   if @rcode <> 0 goto bspexit
   if @status < 0 or @status > 3
   	begin
       select @errmsg = 'Invalid Batch status!', @rcode = 1
       goto bspexit
       end
   -- set HQ Batch status to 1 (validation in progress) 
   update dbo.bHQBC set Status = 1
   where Co = @co and Mth = @mth and BatchId = @batchid
   if @@rowcount = 0
       begin
       select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
       goto bspexit
       end
   
   -- clear HQ Batch Errors 
   delete dbo.bHQBE where Co = @co and Mth = @mth and BatchId = @batchid
   -- clear JC Distributions 
   delete dbo.bINCJ where INCo = @co and Mth = @mth and BatchId = @batchid
   -- clear GL Distributions 
   delete dbo.bINCG where INCo = @co and Mth = @mth and BatchId = @batchid
   
   -- validate Month in IN GL Co# - subledgers must be open
   select @inglco = GLCo, @jrnl = Jrnl
   from dbo.bINCO with (nolock) where INCo = @co
   if @@rowcount = 0
   	begin
   	select @errmsg = 'Invalid IN Company #!', @rcode = 1
   	goto bspexit
   	end
   -- validate IN GL Co#
   exec @rcode = bspHQBatchMonthVal @inglco, @mth, 'IN', @errmsg output
   if @rcode <> 0 goto bspexit
   -- validate Expense Journal in AP GL Co#
   if not exists(select 1 from dbo.bGLJR with (nolock) where GLCo = @inglco and Jrnl = @jrnl)
       begin
       select @errmsg = 'Invalid Journal ' + @jrnl + ' assigned in IN Company!', @rcode = 1
       goto bspexit
       end	
   
   -- create cursor on MO Confirmation Batch for validation
   declare bcINCB cursor for
   select BatchSeq, BatchTransType, INTrans
   from bINCB
   where Co = @co and Mth = @mth and BatchId = @batchid
   
   open bcINCB
   select @opencursor = 1  
   
   INCB_loop:      -- process each entry
   	fetch next from bcINCB into @seq, @transtype, @intrans
   
     	if @@fetch_status <> 0 goto INCB_end
   
      	select @errorstart = 'Seq#:' + convert(varchar(6),@seq)
   
   	-- validate transaction type
     	if @transtype not in ('A','C','D')
     		begin
     		select @errortext = @errorstart + ' -  Invalid transaction type, must be ''A'',''C'', or ''D''.'
     		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     		if @rcode <> 0 goto bspexit
           goto INCB_loop
     		end
   
   	if @transtype in ('C','D')
   		begin
   		-- validate IN Trans#
   		select @inusebatchid = InUseBatchId
   		from dbo.bINDT with (nolock) where INCo = @co and Mth = @mth and INTrans = @intrans
   		if @@rowcount = 0
   			begin
   			select @errortext = @errorstart + ' -  Missing IN Trans#: ' + convert(varchar,isnull(@intrans,0))
   	  		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   	  		if @rcode <> 0 goto bspexit
   	        goto INCB_loop
   	  		end
   		if @inusebatchid is null or @inusebatchid <> @batchid
   			begin
   			select @errortext = @errorstart + ' -  IN Trans#: ' + convert(varchar,isnull(@intrans,0)) + ' not locked by the current batch.'
   	  		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   	  		if @rcode <> 0 goto bspexit
   	        goto INCB_loop
   	  		end 
   
   		-- validate and create distributions for 'old' values
   		select @oldnew = 0	-- old
   		exec @rcode = bspINCBValDist @co, @mth, @batchid, @seq, @oldnew, @inglco, @errmsg output
   		if @rcode <> 0
   			begin
   	  		select @errortext = @errorstart + ' - ' + @errmsg
   	  		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   	  		if @rcode <> 0 goto bspexit
   	        goto INCB_loop
   	  		end
   		end
   
   	if @transtype in ('A','C')
   		begin
   		-- validate and create distributions for 'new' values
   		select @oldnew = 1	-- new
   		exec @rcode = bspINCBValDist @co, @mth, @batchid, @seq, @oldnew, @inglco, @errmsg output
   		if @rcode <> 0
   			begin
   	  		select @errortext = @errorstart + ' - ' + @errmsg
   	  		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   	  		if @rcode <> 0 goto bspexit
   	        goto INCB_loop
   	  		end
   		end
   
   	goto INCB_loop
   
   INCB_end:
   	close bcINCB
   	deallocate bcINCB
   	select @opencursor = 0
   
   -- make sure debits and credits balance
   select @glco = i.GLCo
   from dbo.bINCG i with (nolock) join bGLAC g on i.GLCo = g.GLCo and i.GLAcct = g.GLAcct and g.AcctType <> 'M'  -- exclude memo accounts for qtys
   where i.INCo = @co and i.Mth = @mth and i.BatchId = @batchid
   group by i.GLCo
   having isnull(sum(Amt),0) <> 0
   if @@rowcount <> 0
   	begin
      	select @errortext =  'GL Company ' + convert(varchar(3), @glco) + '  entries don''t balance!'
       exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
       if @rcode <> 0 goto bspexit
       end
   
   /* check HQ Batch Errors and update HQ Batch Control status */
   select @status = 3	/* valid - ok to post */
   if exists(select 1 from dbo.bHQBE with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid)
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
   		close bcINCB
   		deallocate bcINCB
   		end
   
  -- 	if @rcode <> 0 select @errmsg
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINCBVal] TO [public]
GO
