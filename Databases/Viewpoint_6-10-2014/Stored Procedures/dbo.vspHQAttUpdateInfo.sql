SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
Created:
	05/25/07 JonathanP - Returns attachment information for the Attachment Update form.

History:
*/

CREATE  proc [dbo].[vspHQAttUpdateInfo]
(@databaseAttachmentCount as integer output, @fileSystemAttachmentCount as integer output, 
 @saveToDatabase as bYN output, @errorMessage as varchar(255) = '' output)

as

declare @returnCode as int
select @returnCode = 0

-- Get the total number of file system and database attachments.
select @fileSystemAttachmentCount = count(AttachmentID) from HQAT with (nolock) where DocName <> 'Database'
select @databaseAttachmentCount = count(AttachmentID) from HQAT with (nolock) where DocName = 'Database'

-- Check if we are going to save to the database or file system.
select top 1 @saveToDatabase = SaveToDatabase from HQAO

-- If there are no records in HQAO, then we can not get the SaveToDatabase data (HQAO should only have 1 record)
if @@rowcount = 0
begin
	select @errorMessage = 'Error: There is no attachment option record in the attachment options table (HQAO).'
	select @returnCode = 1
end

vspexit:
	if @returnCode <> 0 select @errorMessage = @errorMessage + char(13) + char(10) + '[vspHQAttUpdateInfo]'
	return @returnCode

GO
GRANT EXECUTE ON  [dbo].[vspHQAttUpdateInfo] TO [public]
GO
