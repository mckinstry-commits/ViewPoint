SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspDMPurgeAttachmentTypeSecurity]
/*******************************************
Created By: Rick M 10/27/2009

Purpose:  This procedure will delete all attachment type security for an attachment type.
		  It is used when they change an attachment type from secured, to unsecured.

*******************************************/
(@attachmenttypeid int, @errmsg varchar(255)=null output)
as

declare @rcode int
select @rcode = 0

delete from VAAttachmentTypeSecurity where AttachmentTypeID = @attachmenttypeid

return @rcode



GO
GRANT EXECUTE ON  [dbo].[vspDMPurgeAttachmentTypeSecurity] TO [public]
GO
