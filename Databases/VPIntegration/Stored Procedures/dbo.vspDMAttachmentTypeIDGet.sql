SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		JonathanP
-- Create date: 04/18/08	
-- Description:	Gets the attachment type name for the given attachment type ID.
-- =============================================
CREATE PROCEDURE [dbo].[vspDMAttachmentTypeIDGet]
	
	(@attachmentTypeName varchar(50), @attachmentTypeID int output, @errorMessage varchar(255) = '' output)
AS
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @returnCode INT
	SELECT @returnCode = 0       
    	            
	SELECT @attachmentTypeID = AttachmentTypeID
		FROM DMAttachmentTypesShared
		WHERE RTRIM([Name]) = RTRIM(@attachmentTypeName)
    	
    -- If @attachmentTypeID is null, then the attachment type was not found.
    IF @attachmentTypeID IS NULL
    BEGIN
		SELECT @errorMessage = 'Please enter in a valid attachment type.'
		SELECT @returnCode = 1
		GOTO vspExit
    END	

vspExit:
	return @returnCode

GO
GRANT EXECUTE ON  [dbo].[vspDMAttachmentTypeIDGet] TO [public]
GO
