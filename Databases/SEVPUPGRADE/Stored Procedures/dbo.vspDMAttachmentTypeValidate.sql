SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		JonathanP
-- Create date: 04/17/08	
-- Description:	Makes sure the attachment type exists. If it does, it returns the
--				description and ID of that name.
-- =============================================
CREATE PROCEDURE [dbo].[vspDMAttachmentTypeValidate]
	
	(@typeName varchar(50), @description varchar(255) output, 
	@attachmentTypeID int output, @errorMessage varchar(255) = '' output)
AS
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @returnCode INT
	SELECT @returnCode = 0       
    	            
	SELECT @description = [Description], @attachmentTypeID = AttachmentTypeID
		FROM DMAttachmentTypesShared
		WHERE RTRIM([Name]) = RTRIM(@typeName)
    	
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
GRANT EXECUTE ON  [dbo].[vspDMAttachmentTypeValidate] TO [public]
GO
