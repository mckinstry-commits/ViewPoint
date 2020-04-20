SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspDMTokenGet]
/***********************************************************************
*  Created by: 	JonathanP 03/22/2010 - 130945 
* 
*  Altered by: Gartht 4/09/2011 Added AutoResponseAttachment.
*			
*							
* Usage: Get a DM Token's information.
* 
***********************************************************************/
(@tokenKeyID as int, @errorMessage varchar(255) = '' output)

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
	WHERE KeyID = @tokenKeyID
			
	RETURN @returnCode			
END



GO
GRANT EXECUTE ON  [dbo].[vspDMTokenGet] TO [public]
GO
