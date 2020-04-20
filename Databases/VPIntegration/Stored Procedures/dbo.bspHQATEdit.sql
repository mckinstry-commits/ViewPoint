SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [dbo].[bspHQATEdit]
   /*****************************************************
   	Created: RM 06/08/04
   	Modified: 	RT 08/19/04 - #21497, add OrigFileName and increase filename to 512 bytes.
   				RT 09/21/04 - #21497, also remove transaction.
				JonathanP 05/01/07 - DocAttchYN will now be updated.
				JonathanP 03/06/08 - Changed @desc from bDesc to varchar(255). See issue #120620
   	Usage:
   		Used to change the path and/or description of a given attachment.
   		
   
   ******************************************************/
   (@attid int, @filename varchar(512), @desc VARCHAR(255), @origfilename varchar(512), @docattchyn as char = 'N', @errmsg varchar(255) output)
   as
   
   
   declare @rcode int
   select @rcode = 0
   
   update bHQAT
   set DocName=@filename,
   Description=@desc,
   OrigFileName = @origfilename,
   DocAttchYN = @docattchyn
   where AttachmentID=@attid
   
   if @@rowcount <> 1
   begin
   	set @rcode=1
   	set @errmsg='An error occurred while trying to update the attachment record.' 
   end
   
   
   bspExit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQATEdit] TO [public]
GO
