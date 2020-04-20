SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO











CREATE        Procedure [dbo].[vspVSCreateBatch]
   /*********************************************
   Created By: RM 10/10/03
   			RM 03/26/04 - Issue# 23061 - Added IsNulls
   			GF 09/10/2010 - issue #141031 change to use vfDateOnly
   			
   
   Usage: Creates a header entry for a scanning batch.
          I no batchid is passed, it will create one and pass it back.
   	   Batch will be locked once it is opened.
   
   **********************************************/
   (@description bDesc,@restricted bYN,@batchid bBatchID = null output , @errmsg varchar(255) = null output)
   as
   
   declare @rcode int
   select @rcode = 0
   
   
   
   
   	if exists(select top 1 1 from VSBH where Description=@description)
	begin
		select @errmsg = 'Batch with this description already exists.',@rcode=1
		goto bspexit
	end
   
   
  
   	select @batchid = isnull(max(BatchId),0) +1 from bVSBH
   	
   	insert bVSBH(BatchId,Description,CreatedDate,CreatedBy, Restricted)
   		values(@batchid,@description,
   		----#141031
   		dbo.vfDateOnly(),suser_sname(),@restricted)
   	
   	if @@rowcount <> 1
   	begin
   		select @errmsg = 'Could not create new batch.',@rcode=1
   		goto bspexit
   	end
   
   
   
   
   
   
   
   
   
   bspexit:
   	if @rcode <> 0 select @errmsg = isnull(@errmsg,'') + ' - [bspVSCreateNewBatch]'
   	return @rcode
   
   
   
   
   
   
   
   
   
  
 




GO
GRANT EXECUTE ON  [dbo].[vspVSCreateBatch] TO [public]
GO
