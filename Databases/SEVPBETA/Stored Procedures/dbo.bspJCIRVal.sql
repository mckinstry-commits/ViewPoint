SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   procedure [dbo].[bspJCIRVal]
   /***********************************************************
    * Created By:  DANF 03/09/2005
    * Modified By: 
    *
    * USAGE:
    * Validates each entry in bJCIR for a selected batch - must be called
    * prior to posting the batch.
    *
    * After initial Batch and JC checks, bHQBC Status set to 1 (validation in progress)
    * bHQBE (Batch Errors) entries are deleted.
    *
    * Creates a cursor on bJCIR to validate each entry individually.
    *
   
    * Errors in batch added to bHQBE using bspHQBEInsert
    *
    * bHQBC Status updated to 2 if errors found, or 3 if OK to post
    * INPUT PARAMETERS
    *   JCCo        JC Co
    *   Month       Month of batch
    *   BatchId     Batch ID to validate
    * OUTPUT PARAMETERS
    *   @errmsg     if something went wrong
    * RETURN VALUE
    *   0   success
    *   1   fail
    *****************************************************/
   @co bCompany, @mth bMonth, @batchid bBatchID, @errmsg varchar(255) output
   as
   set nocount on
   
   declare @rcode int, @errortext varchar(255), @status tinyint, @opencursor tinyint,
           @errorstart varchar(50), @ctstring varchar(5)
   
   declare @Contract bContract, @Item bContractItem, @ActualDate bDate, 
   		@RevProjUnits bUnits, @RevProjDollars bDollar, 
   		@PrevRevProjUnits bUnits, @PrevRevProjDollars bDollar, 
   		@RevProjPlugged bYN
   
   select @rcode = 0, @opencursor = 0
   
   -- validate HQ Batch
   exec @rcode = dbo.bspHQBatchProcessVal @co, @mth, @batchid, 'JC RevProj', 'JCIR', @errmsg output, @status output
   if @rcode <> 0
       begin
       select @errmsg = @errmsg, @rcode = 1
       goto bspexit
      	end
   
   if @status < 0 or @status > 3
   	begin
   	select @errmsg = 'Invalid Batch status!', @rcode = 1
   	goto bspexit
   	end
   
   -- set HQ Batch status to 1 (validation in progress)
   update dbo.bHQBC set Status = 1
   where Co=@co and Mth=@mth and BatchId=@batchid
   if @@rowcount = 0
   	begin
   	select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
   	goto bspexit
   	end
   
   -- clear HQ Batch Errors
   delete dbo.bHQBE where Co=@co and Mth=@mth and BatchId=@batchid
   
   -- clear and refresh HQCC entries
   delete dbo.bHQCC where Co = @co and Mth = @mth and BatchId = @batchid
   
   insert into dbo.bHQCC(Co, Mth, BatchId, GLCo)
   select distinct Co, Mth, BatchId, Co from dbo.bJCIR with (nolock)
   where Co=@co and Mth=@mth and BatchId=@batchid
   
   
   
   --, UniqueAttchID
   
   -- declare cursor on JC Detail Batch for validation
   declare bcJCIR cursor local fast_forward for 
   select 	Contract, Item, ActualDate, 
   		RevProjUnits, RevProjDollars, 
   		PrevRevProjUnits, PrevRevProjDollars, 
   		RevProjPlugged
   
   from dbo.bJCIR where Co=@co and Mth=@mth and BatchId=@batchid and 
   				(RevProjUnits<>PrevRevProjUnits or RevProjDollars<>PrevRevProjDollars)
   
   -- open cursor
   open bcJCIR
   -- set open cursor flag to true
   select @opencursor = 1
   
   -- get first row
   fetch next from bcJCIR into 
   		@Contract, @Item, @ActualDate, 
   		@RevProjUnits, @RevProjDollars, 
   		@PrevRevProjUnits, @PrevRevProjDollars, 
   		@RevProjPlugged
   
   
   -- loop through all rows
   while (@@fetch_status = 0)
   BEGIN
   
   	select @errorstart = 'Contract: ' + isnull(@Contract,'')
       -- validate contract
       if not exists (select 1 from dbo.bJCCM with (nolock) where JCCo = @co and Contract = @Contract)
           begin
           select @errortext = @errorstart + ' - is invalid.'
           exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
           if @rcode <> 0 goto bspexit
           goto nextrec
           end
   
   	select @errorstart = 'Contract : ' + isnull(@Contract,'') + ' Item : ' + isnull(@Item,'')
       -- validate contract item
       if not exists (select 1 from dbo.bJCCI with (nolock) where JCCo = @co and Contract = @Contract and Item = @Item)
           begin
           select @errortext = @errorstart + ' - is invalid.'
           exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
           if @rcode <> 0 goto bspexit
           goto nextrec
           end
   
   nextrec:
   
   fetch next from bcJCIR into @Contract, @Item, @ActualDate, 
   		@RevProjUnits, @RevProjDollars, 
   		@PrevRevProjUnits, @PrevRevProjDollars, 
   		@RevProjPlugged
   
   END
   
   -- check HQ Batch Errors and update HQ Batch Control status
   select @status = 3	-- valid - ok to post
   if exists(select 1 from dbo.bHQBE with (nolock) where Co=@co and Mth=@mth and BatchId=@batchid)
       begin
   	select @status = 2	-- validation errors
   	end
   
   update dbo.bHQBC set Status = @status
   where Co=@co and Mth=@mth and BatchId=@batchid
   if @@rowcount <> 1
   	begin
   	select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
   	goto bspexit
   	end
   
   bspexit:
   	if @opencursor = 1
   		begin
   		close bcJCIR
   		deallocate bcJCIR
   		end
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCIRVal] TO [public]
GO
