SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		JonathanP
-- Create date: 04/14/08	
-- Description:	Checks if an attachment type already exists. If it does, return an error. 
--				Used for validation.
-- =============================================
CREATE PROCEDURE [dbo].[vspDMAttachmentTypeValidateNew]
	
	(@typeName varchar(50), @errorMessage varchar(255) = '' output)
AS
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @returnCode INT
	SELECT @returnCode = 0
    
    IF EXISTS(SELECT TOP 1 1 FROM DMAttachmentTypesShared WHERE RTRIM([Name]) = RTRIM(@typeName))
    BEGIN
		SELECT @errorMessage = @typeName + ' attachment type already exists.'
		SELECT @returnCode = 1
		GOTO vspExit
    END	

vspExit:
	return @returnCode

GO
GRANT EXECUTE ON  [dbo].[vspDMAttachmentTypeValidateNew] TO [public]
GO
