SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   Proc [dbo].[vspHQGetAttachmentInfo]
/*********************************
History:
	JonathanP 05/04/07 - Now returns the DocAttchYN column in the result set.
	JonathanP 03/11/08 - Now returns the CurrentState column in the result set.
	JonathanP 04/17/08 - Now returns the AttachmentTypeID column in the result set



**********************************/
(@attachmentid int)

as


select	HQCo, FormName, KeyField, Description, AddedBy, AddDate, DocName, AttachmentID, TableName, 
		UniqueAttchID, OrigFileName, DocAttchYN, CurrentState, AttachmentTypeID	
from HQAT with (nolock)
where AttachmentID = @attachmentid

GO
GRANT EXECUTE ON  [dbo].[vspHQGetAttachmentInfo] TO [public]
GRANT EXECUTE ON  [dbo].[vspHQGetAttachmentInfo] TO [VCSPortal]
GO
