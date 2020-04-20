SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		JonathanP	
-- Create date: 03/27/09
-- Description:	127603 - The procedure will flag the attachments associated with the given unique attachment ID
--				for deletion. These attachments will eventually be deleted by remote helper.
-- =============================================
CREATE PROCEDURE [dbo].[vspDMFlagAttachmentsForDeletion]
	@uniqueAttachID uniqueidentifier = null, @deletedFromRecord bYN
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;	

	-- If the a unique attachment ID is not specified, do not flag anything for deletion.
    if @uniqueAttachID is null
    begin 
		return
    end         
    
    -- Make sure the Y or N is upper case.
    set @deletedFromRecord = upper(@deletedFromRecord)
    
    -- Insert a record into vDMAttachmentDeletionQueue to be deleted by Remote Helper.
	insert vDMAttachmentDeletionQueue (AttachmentID, UserName, DeletedFromRecord)
		select AttachmentID, suser_name(), @deletedFromRecord from bHQAT where UniqueAttchID = @uniqueAttachID
    
END

GO
GRANT EXECUTE ON  [dbo].[vspDMFlagAttachmentsForDeletion] TO [public]
GO
