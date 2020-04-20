SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   Proc [dbo].[vspHQAFInsert]
/*******************************

	Created by: ???	
	Updated by: JonathanP 01/12/2010 - #137208 Add file type parameter.

*******************************/
(@attachmentid int, @attachmentdata image, @deleteexisting bYN, @append bYN, @filetype varchar(10), @msg varchar(255) = null output)
as

declare @rcode int
select @rcode=0
set @msg=null


if exists(select top 1 1 from HQAF where AttachmentID=@attachmentid)
begin
	if @deleteexisting = 'Y'
	begin
		delete HQAF where AttachmentID=@attachmentid
		insert HQAF(AttachmentID, AttachmentData, AttachmentFileType) values(@attachmentid, @attachmentdata, @filetype)
	end
	else
	begin
		if @append = 'Y'
		begin
			update HQAF 
				set AttachmentData = cast(AttachmentData as varbinary(max)) + cast(@attachmentdata as varbinary(max)),
					AttachmentFileType = @filetype 
				where AttachmentID = @attachmentid
		end
		else
		begin
			select @msg = 'Data already exists for this attachment', @rcode=1 --This should never happen, but just in case
			goto vspExit
		end
	end
end
else
begin
	insert HQAF(AttachmentID, AttachmentData, AttachmentFileType) values(@attachmentid, @attachmentdata, @filetype)
end

if @@rowcount <> 1
begin

	set @msg='Unable to insert attachment data'
	set @rcode=1
end

vspExit:

if @rcode<>0
	select @msg = @msg + ' - [vspHQAFInsert]'
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHQAFInsert] TO [public]
GO
