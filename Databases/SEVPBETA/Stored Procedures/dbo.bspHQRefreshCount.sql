SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE        Procedure [dbo].[bspHQRefreshCount]
   /*************************************************
   	Created: 08/20/02 - RM
   	Modified: 08/03/06 - RM Issue 122067
   
   	Usage:
   		Returns a count of how many records will be reindexed.
   
   	Pass-in:
   
   	Returns: @rcode  - 1 = Fail
   					   0 = Success
   
   
   *************************************************/
   (@attid int = null, @mod char(2) = null,@uniqueattchid varchar(100) = null,@count int = null output,@msg varchar(255) = '' output)
   
   as 
   
   declare @rcode int
   
   select @rcode = 0
   
   Select @count=count(*) from HQAT T 
   		left join HQAI I on T.AttachmentID = I.AttachmentID
   		where T.AttachmentID = isnull(@attid,T.AttachmentID) 
   		and  upper(left(T.TableName,2)) = upper(isnull(@mod,left(T.TableName,2)))
   		and T.UniqueAttchID = isnull(@uniqueattchid,T.UniqueAttchID)
   
   
   
   
   bspexit:
   
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQRefreshCount] TO [public]
GO
