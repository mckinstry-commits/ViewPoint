SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    Procedure [dbo].[bspVSBatchLock]
   /*********************************************
   Created By: RM 10/10/03
   			RM 03/26/04 - Issue# 23061 - Added IsNulls
   
   Usage: Update InUseBy, Description
   
   **********************************************/
   (@batchid bBatchID,@description bDesc, @errmsg varchar(255) = null output)
   as
   
   declare @rcode int
   select @rcode = 0
   
   select @batchid = isnull(max(BatchId),0) +1 from bVSBH
   
   update bVSBH
   set Description = @description,
   InUseBy=suser_sname()
   where BatchId=@batchid
   
   if @@rowcount <> 1
   begin
   	select @errmsg = 'Could not create new batch.',@rcode=1
   	goto bspexit
   end
   
   bspexit:
   	if @rcode <> 0 select @errmsg = isnull(@errmsg,'') + ' - [bspVSLockBatch]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspVSBatchLock] TO [public]
GO
