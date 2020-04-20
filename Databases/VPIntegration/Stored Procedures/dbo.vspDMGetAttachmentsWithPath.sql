SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
Created:
	06/21/07 JonathanP - Returns a result set of all the AttachmentIDs in HQAT with the given path (includes those with subfolders)

History:	

Inputs:
	@copyfrompath - The path of the attachments to return. Examples: 'C:\SomeRepository\SomeFolder' or '\\Devel\ScannedDocs'
*/

CREATE  proc [dbo].[vspDMGetAttachmentsWithPath]

(@copyfrompath as varchar(1000), @msg as varchar(255) = '' output)
as

declare @rcode as int
select @rcode = 0

Select AttachmentID, DocName From HQAT 
Where UPPER(DocName) Like UPPER(@copyfrompath) + '%'
order by AttachmentID

return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDMGetAttachmentsWithPath] TO [public]
GO
