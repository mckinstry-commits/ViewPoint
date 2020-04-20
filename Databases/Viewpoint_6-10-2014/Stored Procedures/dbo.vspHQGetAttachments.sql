SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
History:
	04/30/07 JonathanP - The result set now also returns the DocAttchYN column.
	04/17/08 JonathanP - The result set now also returns CurrentState and AttachmentTypeID
*/


CREATE  proc [dbo].[vspHQGetAttachments]


(@uniqueattchid varchar(255) = null)
as

select AttachmentID, OrigFileName, Description, DocName, AddedBy, AddDate, HQCo, FormName, 
	KeyField,TableName, UniqueAttchID, DocAttchYN, CurrentState, AttachmentTypeID
	from HQAT 
	where UniqueAttchID =case when @uniqueattchid = '' then null else @uniqueattchid end

GO
GRANT EXECUTE ON  [dbo].[vspHQGetAttachments] TO [public]
GO
