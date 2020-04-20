SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    Procedure [dbo].[bspVSBatchUnLock]
   /*********************************************
   Created By: RM 10/10/03
   
   Usage: Update InUseBy to null
   
   **********************************************/
   (@batchid bBatchID, @errmsg varchar(255) = null output)
   as
   
   declare @rcode int
   select @rcode = 0
   
   
   update bVSBH
   set InUseBy=null
   where BatchId=@batchid
   
   if @@rowcount <> 1
   begin
   	select @errmsg = 'Could not unlock batch.',@rcode=1
   	goto bspexit
   end
   
   bspexit:
   	if @rcode <> 0 select @errmsg = @errmsg + ' - [bspVSBatchUnLock]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspVSBatchUnLock] TO [public]
GO
