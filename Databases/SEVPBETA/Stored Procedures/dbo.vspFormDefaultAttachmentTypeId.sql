SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspFormDefaultAttachmentTypeId    Script Date: 8/28/99 9:34:49 AM ******/
CREATE       proc [dbo].vspFormDefaultAttachmentTypeId
/********************************
* Created: jd 11/16/09 
*
* Called from Attachments.AddAttachment(...) to default a new attachment type to 
* the value set in vDDFHc or the DDFU override value or zero if neither.
*
* Input:
*	form name
*
* Output:
*   @defaultAttachmentTypeId - id to use (or zero if none)
*	@msg - errmsg if one is encountered
*
* Return code:
*	0 = success, 1 = failure
*
*********************************/
(@form varchar(30), @errmsg varchar(60) output)
as
	set nocount on
	declare @rcode int
	select @rcode = 0

SELECT s.DefaultAttachmentTypeID AS systemDefaultAttachmentTypeId,
	   u.DefaultAttachmentTypeID AS userDefaultAttachmentTypeId
FROM dbo.vDDFHc s (nolock)
left outer join dbo.vDDFU u (nolock) on u.VPUserName = suser_sname() and u.Form = s.Form
Where s.Form = @form

bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspFormDefaultAttachmentTypeId] TO [public]
GO
