SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
History:	
	07/21/09 JonathanP - 134047: Created from vspHQGetAttachments. Returns all the HQAT attachment
					     information for the passed in unique attachment IDs.
					     
	@uniqueAttachIDs varchar(max) - A comma delimited list of unique attachment IDs. 					    
*/


CREATE  proc [dbo].[vspDMGetAttachments]


(@uniqueAttachmentIDs varchar(max))
as

select h.AttachmentID, h.OrigFileName, h.[Description], h.DocName, h.AddedBy, h.AddDate, 
	   h.HQCo, h.FormName, h.KeyField,TableName, h.UniqueAttchID, h.DocAttchYN, h.CurrentState, 
	   h.AttachmentTypeID
	from dbo.HQAT h
	join dbo.vfTableFromArray(@uniqueAttachmentIDs) u on h.UniqueAttchID = u.Names 
	where h.UniqueAttchID is not null and h.CurrentState = 'A'

GO
GRANT EXECUTE ON  [dbo].[vspDMGetAttachments] TO [public]
GO
