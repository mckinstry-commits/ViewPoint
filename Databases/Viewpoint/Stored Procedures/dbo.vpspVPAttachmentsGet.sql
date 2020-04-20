SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE    PROCEDURE [dbo].[vpspVPAttachmentsGet]
/************************************************************
* CREATED:     SDE 3/1/2006
* MODIFIED:    
*
* USAGE:
*   Returns the Attachments for a UniqueAttchID
*	
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    UniqueAttchID        
*
* OUTPUT PARAMETERS
*   
* RETURN VALUE
*   
************************************************************/
(@UniqueAttchID varchar(50))
AS
	SET NOCOUNT ON;


SELECT HQCo, FormName, KeyField, Description, AddedBy, AddDate, DocName, AttachmentID, TableName, 
	UniqueAttchID, OrigFileName, 
	isnull(OrigFileName,Right(DocName,charindex('\',reverse(DocName))-1)) as 'LinkName'

FROM HQAT WITH (NOLOCK)

WHERE UniqueAttchID = @UniqueAttchID


GO
GRANT EXECUTE ON  [dbo].[vpspVPAttachmentsGet] TO [VCSPortal]
GO
