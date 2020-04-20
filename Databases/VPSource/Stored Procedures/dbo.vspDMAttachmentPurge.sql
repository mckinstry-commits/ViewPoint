SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		JonathanP
-- Create date: 04/16/09
-- Description:	See issue 129918. This will permanently delete an attachment. All archiving and auditing will be bypassed.
-- =============================================
CREATE PROCEDURE [dbo].[vspDMAttachmentPurge]
	@attachmentID int, @returnMessage varchar(255) = '' output
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	declare @returnCode int
	set @returnCode = 0

	-- Call vspHQATDelete to delete the attachment. 
    exec vspHQATDelete @attachmentID, null, 'N', null, @returnMessage output
    
    -- If archiving is enabled, the attachment will still exist but it will be in a deleted state. Calling vspHQATDelete
    -- on a "deleted" attachment purges it from the system.
    if exists(select top 1 1 from bHQAT where AttachmentID = @attachmentID)
    begin
		-- Call vspHQATDelete again to remove the archived attachment.
		exec vspHQATDelete @attachmentID, null, 'N', null, @returnMessage output
    end
    
    -- Make sure the attachment was truly purged.
    if exists(select top 1 1 from bHQAT where AttachmentID = @attachmentID)
    begin
		set @returnMessage = 'Error: Attachment was not purged.'
		set @returnCode = 1
		goto vspExit
    end    
  
vspExit:

	return @returnCode
    
END

GO
GRANT EXECUTE ON  [dbo].[vspDMAttachmentPurge] TO [public]
GO
