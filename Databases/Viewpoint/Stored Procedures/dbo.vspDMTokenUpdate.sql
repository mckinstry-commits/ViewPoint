SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspDMTokenUpdate]
/***********************************************************************
*  Created by: 	JonathanP 03/22/2010 - 130945 
* 
*  Altered by: 
*			
*							
* Usage: Updates a DM Token's information.
* 
***********************************************************************/
(@tokenKeyID as int, @tokenValue as varchar(32), @attachmentID int, @errorMessage varchar(255) = '' output)

AS  
BEGIN

	DECLARE @returnCode int
	SET @returnCode = 0

	IF @tokenKeyID <= 0
	BEGIN
		SELECT @errorMessage = 'The token key ID must be greater than 0', @returnCode = 1
		GOTO vspExit
	END

	UPDATE vDMTokens SET Token = @tokenValue, AttachmentID = @attachmentID WHERE KeyID = @tokenKeyID			
			
vspExit:			
			
	RETURN @returnCode			
END



GO
GRANT EXECUTE ON  [dbo].[vspDMTokenUpdate] TO [public]
GO
