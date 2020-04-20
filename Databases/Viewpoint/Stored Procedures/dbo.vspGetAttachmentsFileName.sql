SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspGetAttachmentsFileName]
/********************************
* Created: Narendra 2012-04-11
* Modified: 
* 
* Returns File Name for the given AttachmentID. 
* 
* 
* Input:
* @attachmentid - AttachmentID for which we are returning File Name
* 
* Output:
* FileName
* 
*********************************/
 (@attachmentid int = null)
AS
BEGIN
SET NOCOUNT ON

SELECT OrigFileName 
FROM dbo.HQAT
WHERE AttachmentID =@attachmentid

END
GO
GRANT EXECUTE ON  [dbo].[vspGetAttachmentsFileName] TO [public]
GO
