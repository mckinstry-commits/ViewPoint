SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Created by: JonathanP 01/21/08
-- Description: This method will insert a record in the attachment audit table.

CREATE proc [dbo].[vspDMAttachmentAuditLogInsert]
(@attachmentID int, @userName bVPUserName = null, @fieldName varchar(30) = NULL, @oldValue varchar(255) = null,
 @newValue varchar(255) = null, @event varchar(50), @errorMessage varchar(255) output)

as 

set nocount on

declare @returnCode int
select @returnCode = 0

IF @userName IS NULL
BEGIN
	SELECT @userName = SUSER_NAME()
END	

-- Insert into the audit table.
insert 
	dbo.vDMAttachmentAuditLog (AttachmentID, [DateTime], UserName, FieldName, OldValue, NewValue, [Event])
values (@attachmentID, GETDATE(), @userName, @fieldName, @oldValue, @newValue, @event)

if @@rowcount = 0
begin
	select @returnCode = 1
	select @errorMessage = 'Could not insert into the attachment audit log table.'	
	goto exitLabel
end

exitLabel:
	return @returnCode

GO
GRANT EXECUTE ON  [dbo].[vspDMAttachmentAuditLogInsert] TO [public]
GO
