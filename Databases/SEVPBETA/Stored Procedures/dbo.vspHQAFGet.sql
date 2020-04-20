SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  Proc [dbo].[vspHQAFGet]
/*******************************
Modified by:    2009-03-25 JonathanP - The procedure now takes in an offset and length to return chunks of the image data.
                2012-03-30 Chris Crewdson - The procedure now treats a length of -1 the same as null: Return all bytes.
*******************************/
(@attachmentid int, @offset int = null, @length int = null)
as

if @offset = null or @offset = 0
begin
	set @offset = 1
end

if @length = null OR @length = -1
begin
	select @length = datalength(AttachmentData) from HQAF where AttachmentID = @attachmentid	
end


select substring(cast(AttachmentData as varbinary(max)), @offset, @length) as AttachmentData, 	   
	   'LastPacket' = case when datalength(AttachmentData) <= (@offset + @length) then 'Y' else 'N' end						   
	from HQAF where AttachmentID = @attachmentid	




GO
GRANT EXECUTE ON  [dbo].[vspHQAFGet] TO [public]
GO
