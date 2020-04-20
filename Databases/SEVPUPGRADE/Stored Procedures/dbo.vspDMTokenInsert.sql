SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspDMTokenInsert]
/***********************************************************************
*  Created by: 	JonathanP 03/19/2010 - 130945 
* 
*  Altered by: Jacob VH	10/19/2010 - 141299 Changed @tableName to varchar(128)
*			   Gartht 04/08/2011 - TK-03974 Added @autoResponseAttachment to insert.
*							
* Usage: Inserts a DM Token.
* 
***********************************************************************/
(@company bCompany, @tableName varchar(128), @tableKeyField varchar(500), @formName varchar(30),
 @isPMDocumentAttachment bYN, @standAloneAttachment bYN,  @autoResponseAttachment bYN,
 @token varchar(32) = null, @attachmentID int = null, @errorMessage varchar(255) = '' output)

AS  
BEGIN

	-- Returns the KeyID of the record added.	
	INSERT INTO dbo.vDMTokens(Company, TableName, TableKeyField, FormName, 
							PMDocumentAttachment, StandAloneAttachment, AutoResponseAttachment, 
							Token, AttachmentID) OUTPUT INSERTED.KeyID 							  
		VALUES (@company, @tableName, @tableKeyField, @formName, 
							@isPMDocumentAttachment, @standAloneAttachment, @autoResponseAttachment,
							@token, @attachmentID)
	
			
END
GO
GRANT EXECUTE ON  [dbo].[vspDMTokenInsert] TO [public]
GO
