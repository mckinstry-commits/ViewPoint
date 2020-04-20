SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspDMTokenGetUsingValue]
/***********************************************************************
*  Created by: 	JonathanP 03/25/2010 - 130945 
* 
*  Altered by: 
*			
*							
* Usage: Get a DM Token's information.
* 
***********************************************************************/
(@tokenValue as varchar(32), @errorMessage varchar(255) = '' output)

AS  
BEGIN

	DECLARE @returnCode int
	SET @returnCode = 0

	SELECT Company ,
	        TableName ,
	        TableKeyField ,
	        FormName ,
	        PMDocumentAttachment ,
	        StandAloneAttachment ,
	        AutoResponseAttachment ,
	        Token ,
	        AttachmentID ,
	        KeyID 
	FROM dbo.vDMTokens 
	WHERE Token = @tokenValue
			
	RETURN @returnCode			
END
GO
GRANT EXECUTE ON  [dbo].[vspDMTokenGetUsingValue] TO [public]
GO
