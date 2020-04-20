SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [dbo].[vspDMUpdateDocName]
   /*****************************************************
   	Created: JonathanP 06/25/07
   	Modified: 	

   	Usage:
   		Updates the DocName column in HQAT.
   		
   
   ******************************************************/
   (@attachmentid int, @newdocname varchar(512), @errmsg varchar(255) output)
   as   
   
   declare @rcode int
   select @rcode = 0
   
   update bHQAT
   set DocName=@newdocname   
   where AttachmentID = @attachmentid
   
   if @@rowcount <> 1
   begin
   	set @rcode=1
   	set @errmsg='An error occurred while trying to update the attachment record.' 
   end
   
   
   bspExit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDMUpdateDocName] TO [public]
GO
