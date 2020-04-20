SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspDMEmailsToUpgrade]
/***********************************************************************
*  Created by: 	CC 03/11/2010 - 130945 
* 
*  Altered by: 
*			
*							
* Usage: Retrieves email attachments that are missing HQAI email data
* 
***********************************************************************/

AS  
BEGIN

	SELECT	HQAT.AttachmentID ,
			'N' AS 'Upgrade',
			[Description] ,
			OrigFileName ,
			ISNULL(DDFH.Title, FormName) AS FormName ,
			'' AS [Status]
	FROM HQAT 
	LEFT OUTER JOIN HQAI ON HQAT.AttachmentID = HQAI.AttachmentID AND HQAI.IsEmailIndex = 1
	LEFT OUTER JOIN DDFH ON FormName = Form
	WHERE	IsEmail = 'Y' AND 
			HQAI.AttachmentID IS NULL and
			CurrentState <> 'D';
			
END


GO
GRANT EXECUTE ON  [dbo].[vspDMEmailsToUpgrade] TO [public]
GO
