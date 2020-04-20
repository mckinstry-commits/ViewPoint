SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspDMGetStandAloneAttachments]
/********************************
* Created: CC 10/08/2009
* Modified:	
* 
* Returns a list of standalone attachments
* 
* Input: None
*	
* Output: No output parameters
* 
* 
* 
*********************************/
AS
BEGIN
	SELECT 
		  h.AttachmentID
		, h.OrigFileName
		, h.[Description]
		, h.DocName
		, h.AddedBy
		, h.AddDate
		, h.HQCo
		, h.FormName
		, h.KeyField
		, h.TableName
		, h.UniqueAttchID
		, h.DocAttchYN
		, h.CurrentState
		, h.AttachmentTypeID
	FROM dbo.HQAT h
	WHERE h.CurrentState = 'S'
END
GO
GRANT EXECUTE ON  [dbo].[vspDMGetStandAloneAttachments] TO [public]
GO
