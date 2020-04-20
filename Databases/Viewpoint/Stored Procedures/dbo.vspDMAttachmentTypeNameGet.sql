SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		JonathanP
-- Create date: 04/18/08	
-- Description:	Gets the attachment type ID for the given attachment type Name.
-- =============================================
CREATE PROCEDURE [dbo].[vspDMAttachmentTypeNameGet]
	
	(@attachmentTypeID int, @attachmentTypeName varchar(50) output, @errorMessage varchar(255) = '' output)
AS
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @returnCode INT
	SELECT @returnCode = 0       

	IF @attachmentTypeID = 0
	BEGIN
		SELECT @attachmentTypeName = ''
		GOTO vspExit
	END
    	            
	SELECT @attachmentTypeName = RTRIM(Name)
		FROM DMAttachmentTypesShared
		WHERE AttachmentTypeID = @attachmentTypeID
    	
    -- If @attachmentTypeName is null, then the attachment type was not found.
    IF @attachmentTypeName IS NULL
    BEGIN
		SELECT @errorMessage = 'Please enter in a valid attachment type ID.'
		SELECT @returnCode = 1
		GOTO vspExit
    END	

vspExit:
	return @returnCode

GO
GRANT EXECUTE ON  [dbo].[vspDMAttachmentTypeNameGet] TO [public]
GO
