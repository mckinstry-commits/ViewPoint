SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspFormPropertyUpdate]
/********************************
* Created: kb 06/14/03 
* Modified:	JD 11/13/09  131937 - Default Attachment Type by Form, User (vDDFU) 
*                                 and System Wide (vDDFHc) default attachment type ID added
*			CC 2010-01-07 #135020 - Add update for form filtering
*
* Called from FieldProperty form to update properties to vDDFIc, vDDUI, vDDFHc, vDDFU
*
* Input:
*	no inputs
* Output:
*	@msg - errmsg if one is encountered

* Return code:
*	0 = success, 1 = failure
*
*********************************/
(
	@form varchar(30), 
	@defaulttab tinyint, 
	@iconkey varchar(30), 
	@progressclip varchar(30), 
	@userDefaultAttachmentTypeId integer, 
	@systemDefaultAttachmentTypeId integer, 
	@LimitRecords	bYN = 'N',
	@errmsg varchar(60) output
)
as
	set nocount on
	declare @rcode int
	select @rcode = 0

update vDDFU
set DefaultTabPage = @defaulttab, DefaultAttachmentTypeID = @userDefaultAttachmentTypeId, LimitRecords = @LimitRecords
from vDDFU where Form = @form 
  and VPUserName = suser_sname()

if @@rowcount = 0
	begin
	insert vDDFU (Form,VPUserName,DefaultTabPage,DefaultAttachmentTypeID, LimitRecords)
	select @form, suser_sname(), @defaulttab, @userDefaultAttachmentTypeId, @LimitRecords
	end

update vDDFHc
set IconKey = @iconkey, ProgressClip = @progressclip, DefaultAttachmentTypeID = @systemDefaultAttachmentTypeId
from vDDFHc where Form = @form 
if @@rowcount = 0
	begin
	insert vDDFHc (Form,IconKey,ProgressClip,DefaultAttachmentTypeID)
	select @form, @iconkey, @progressclip, @systemDefaultAttachmentTypeId
	end

bspexit:
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspFormPropertyUpdate] TO [public]
GO
