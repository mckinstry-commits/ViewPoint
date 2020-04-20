SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
Created:
	05/24/07 JonathanP - Returns a result set of all the AttachmentIDs in HQAT

History:
*/

CREATE  proc [dbo].[vspHQGetAllAttachments]
as

select AttachmentID From HQAT
order by AttachmentID


GO
GRANT EXECUTE ON  [dbo].[vspHQGetAllAttachments] TO [public]
GO
