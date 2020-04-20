SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspHQATDeleteAttachments]
	/*******************************************************************************
	* CREATED BY: JonathanP 05/07/07
	* MODIFIED BY: JonathanP 02/07/08 - Added @username parameter so we can call vspHQATDelete correctly.
	*			   JonathanP 03/31/08 - See #127607. Added @deletedFromRecord so we can call vspHQATDelete correctly.
	*
	* Deletes all the attachments associated with the given unique attachment ID. All
	* attachments that refer to that ID will be deleted from bHQAT and all the indexes
	* will be removed from bHQAI. 
	*
	* Inputs:
	*		uniqueattachmentid - The unique attachment ID of the attachments to delete.
	*		username - Name of the user deleted the attachment(s).
	*		deletedFromRecord - If the attachments were deleted from a record, then set this to 'Y', otherwise 'F'
	*
	* Error returns:
	*  1 and error message
	*
	********************************************************************************/
	(@uniqueattachmentid UNIQUEIDENTIFIER,@username VARCHAR(128),  @deletedFromRecord bYN, @msg varchar(255) output)
	as
		set nocount on
		declare @rcode int
		select @rcode=0	
	
	declare @attachmentid as integer

	-- Check if the given unique attachment ID exists in bHQAT
	select AttachmentID from bHQAT where UniqueAttchID = @uniqueattachmentid
	if @@ROWCOUNT <= 0
	Begin
		select @msg = 'There are no attachments with that given unique attachment ID.'
		select @rcode = 1
		goto vspexit
	End
 
DeleteAttachments:
	-- If there are still attachments in HQAT with the given unique attachment ID, delete another attachment.
	if (select COUNT(AttachmentID) from bHQAT where UniqueAttchID = @uniqueattachmentid) > 0
	Begin	
		select top (1) @attachmentid = AttachmentID from bHQAT where UniqueAttchID = @uniqueattachmentid

		begin try
			exec dbo.vspHQATDelete @attid = @attachmentid, 
				@username = @username,  
				@deletedFromRecord = @deletedFromRecord, 
				@msg = @msg	
		end try
		begin catch
			-- If an error occurs, ignore it and go to the next attachment.			
		end catch

		goto DeleteAttachments
	End

   vspexit:
       if @rcode<>0 select @msg = isnull(@msg,'') + char(13) + char(10) + 'vspHQATDeleteAttachments'
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHQATDeleteAttachments] TO [public]
GO
