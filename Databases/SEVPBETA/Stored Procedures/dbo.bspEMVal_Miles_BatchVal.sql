SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     procedure [dbo].[bspEMVal_Miles_BatchVal]
   /***********************************************************
    * CREATED BY: JM 10/8/99
    * MODIFIED By : TV 02/11/04 - 23061 added isnulls 
    *					TV 07/18/05 - 27547 Need to check if bEMBM is still being utilized. If not, needs to be removed
    *
    * USAGE:
    * 	Called by bspEMVal_Miles_Main to validate batch data,
    *	set HQ Batch status. clear HQ Batch Errors. and clear and
    *	refresh HQCC entries.
    *
    * INPUT PARAMETERS
    *	EMCo        EM Company
    *	Month       Month of batch
    *	BatchId     Batch ID to validate
    *
    * OUTPUT PARAMETERS
    *	@errmsg     if something went wrong
    *
    * RETURN VALUE
    *	0   Success
    *	1   Failure
    *****************************************************/
   @co bCompany, @mth bMonth, @batchid bBatchID, @errmsg varchar(255) output
   
   as
   
   declare @maxopen tinyint, @rcode int, @status tinyint
   
   set nocount on
   
   select @rcode = 0
   
   -- Verify parameters passed in. 
   if @co is null
   	begin
   	select @errmsg = 'Missing Batch Company!', @rcode = 1
   	goto bspexit
   	end
   if @mth is null
   	begin
   	select @errmsg = 'Missing Batch Month!', @rcode = 1
   	goto bspexit
   	end
   if @batchid is null
   	begin
   	select @errmsg = 'Missing BatchID!', @rcode = 1
   	goto bspexit
   	end
   
   -- Validate HQ Batch 
   exec @rcode = dbo.bspHQBatchProcessVal @co, @mth, @batchid, 'EMMiles', 'EMMH', @errmsg output, @status output
   if @rcode <> 0
   	begin
   	select @rcode = 1
   	goto bspexit
      	end
   
   if @status < 0 or @status > 3
   	begin
   	select @errmsg = 'Invalid Batch status!', @rcode = 1
   	goto bspexit
   	end
   
   -- Set HQ Batch status to 1 (validation in progress). 
   update bHQBC
   set Status = 1
   where Co = @co and Mth = @mth and BatchId = @batchid
   if @@rowcount = 0
   	begin
   	select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
   	goto bspexit
   	end
   
   -- Clear HQ Batch Errors. 
   delete bHQBE 
   where Co = @co and Mth = @mth and BatchId = @batchid
   
   -- Clear and refresh HQCC entries. 
   delete bHQCC 
   where Co = @co and Mth = @mth and BatchId = @batchid
   
   -- TV 07/18/05 - 27547 Need to check if bEMBM is still being utilized. If not, needs to be removed
   /*insert into bHQCC(Co, Mth, BatchId, GLCo)
   select distinct Co, Mth, BatchId, GLCo 
   from bEMBM
   where Co=@co and Mth=@mth and BatchId=@batchid*/
   
   bspexit:
   	if @rcode<>0 select @errmsg=isnull(@errmsg,'')	--+ char(13) + char(10) + '[bspEMVal_Miles_BatchVal]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMVal_Miles_BatchVal] TO [public]
GO
