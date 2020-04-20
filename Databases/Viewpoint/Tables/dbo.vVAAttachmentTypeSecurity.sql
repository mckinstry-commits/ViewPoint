CREATE TABLE [dbo].[vVAAttachmentTypeSecurity]
(
[Co] [smallint] NOT NULL,
[AttachmentTypeID] [int] NOT NULL,
[SecurityGroup] [int] NOT NULL,
[VPUserName] [dbo].[bVPUserName] NOT NULL,
[Access] [tinyint] NOT NULL
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [viVAAttachmentTypeSecurity] ON [dbo].[vVAAttachmentTypeSecurity] ([Co], [AttachmentTypeID], [SecurityGroup], [VPUserName]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE trigger [dbo].[vtVAAttachmentTypeSecurityd] on [dbo].[vVAAttachmentTypeSecurity] for Delete
/*-----------------------------------------------------------------
 * Created: AL - 3/2/09 
 *
 *	
 *
 */----------------------------------------------------------------
as



 	-- HQMA Audit	 	 	 
insert bHQMA (TableName, RecType, KeyString, FieldName, OldValue, 
  	NewValue, DateTime, UserName)
select 'vVAAttachmentTypeSecurity', 'D','AttachmentTypeID: ' + rtrim(i.AttachmentTypeID) + ' SecurityGroup: ' + rtrim(i.SecurityGroup) + ' VPUserName: ' + rtrim(i.VPUserName) + ' Co: ' + rtrim(i.Co), null, null,
	null, getdate(), SUSER_SNAME() from Deleted i
return

 
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE trigger [dbo].[vtVAAttachmentTypeSecurityi] on [dbo].[vVAAttachmentTypeSecurity] for Insert
/*-----------------------------------------------------------------
 * Created: AL - 3/2/09 
 *
 *	
 *
 */----------------------------------------------------------------
as



 	-- HQMA Audit	 	 	 
insert bHQMA (TableName, RecType, KeyString, FieldName, OldValue, 
  	NewValue, DateTime, UserName)
select 'vVAAttachmentTypeSecurity', 'I','AttachmentTypeID: ' + rtrim(i.AttachmentTypeID) + ' SecurityGroup: ' + rtrim(i.SecurityGroup) + ' VPUserName: ' + rtrim(i.VPUserName) + ' Co: ' + rtrim(i.Co), null, null,
	null, getdate(), SUSER_SNAME() from inserted i
return

 

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE trigger [dbo].[vtVAAttachmentTypeSecurityu] on [dbo].[vVAAttachmentTypeSecurity] for UPDATE 
/*-----------------------------------------------------------------
 *	Created: AL 3/02/09
 *
 *
 */----------------------------------------------------------------
as



if update(Access)
	insert dbo.bHQMA(TableName, RecType, KeyString, FieldName,
		OldValue, NewValue, DateTime, UserName)
	select  'vVAAttachmentTypeSecurity', 'U', 'AttachmentTypeID: ' + rtrim(i.AttachmentTypeID) + ' SecurityGroup: ' + rtrim(i.SecurityGroup) + ' VPUserName: ' + rtrim(i.VPUserName) + ' Co: ' + rtrim(i.Co), 'Access',
		d.Access, i.Access, getdate(), SUSER_SNAME()
  	from inserted i
  	join deleted d on i.AttachmentTypeID = d.AttachmentTypeID and i.SecurityGroup = d.SecurityGroup and i.Co = d.Co and i.VPUserName = d.VPUserName
  	where isnull(i.Access,'') <> isnull(d.Access,'')
  	

return
 

GO
