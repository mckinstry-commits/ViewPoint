SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE        Procedure [dbo].[bspVSBatchVal]
   /*********************************************
   Created By: RM 10/10/03
   			RM 03/26/04 - Issue# 23061 - Added IsNulls
   
   Usage: Validate batch and return info
   
   **********************************************/
   (@batchdesc bDesc, @createdby bVPUserName output, @createddate bDate output,
    @doccount int output, @unattached int output,@batchid bBatchID output, @msg varchar(255) = null output)
   as
   
   declare @rcode int
   select @rcode = 0
   
   
   if @batchdesc is null
   begin
   	select @msg = 'Description is missing.', @rcode = 1
   	goto bspexit
   end
   
   --Get Header Info
   select @msg = Description, @createdby=CreatedBy, @createddate=CreatedDate, @batchid=BatchId from bVSBH where Description=@batchdesc
   
   if @@rowcount <> 1
   begin
   	select @msg = 'Batch not found.',@rcode=1
   	goto bspexit
   end
   
   
   --Get Doc Count
   select @doccount=count(*) from bVSBD where BatchId=@batchid
   
   --Get unattached count
   select @unattached=count(*) from bVSBD where BatchId=@batchid and Attached='N'
   
   
   
   
   bspexit:
   	if @rcode <> 0 select @msg = isnull(@msg,'') + ' - [bspVSBatchVal]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspVSBatchVal] TO [public]
GO
