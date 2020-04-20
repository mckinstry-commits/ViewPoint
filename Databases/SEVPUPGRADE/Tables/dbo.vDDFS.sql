CREATE TABLE [dbo].[vDDFS]
(
[Co] [smallint] NOT NULL,
[Form] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[SecurityGroup] [int] NOT NULL,
[VPUserName] [dbo].[bVPUserName] NOT NULL,
[Access] [tinyint] NOT NULL,
[RecAdd] [dbo].[bYN] NOT NULL,
[RecUpdate] [dbo].[bYN] NOT NULL,
[RecDelete] [dbo].[bYN] NOT NULL,
[AttachmentSecurityLevel] [tinyint] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE trigger [dbo].[vtDDFSd] on [dbo].[vDDFS] for delete 
/*-----------------------------------------------------------------
 *	Created: GG 08/01/03
 *	Modified: AL 3/2/09 Added HQMA Audit
 *
 *	This trigger rejects delete in vDDFS (Form Security) if any of the
 *	following error conditions exist:
 *
 *		Tab Security exists
 *
 */----------------------------------------------------------------
 
as



declare @errmsg varchar(255)
if @@rowcount = 0 return

set nocount on
 
-- check Tab Security
if exists (select top 1 1 from deleted d
			join vDDTS s on s.Co = d.Co and s.Form = d.Form
				and s.SecurityGroup = d.SecurityGroup and s.VPUserName = d.VPUserName)
 	begin
 	select @errmsg = 'Tab Security assigned'
 	goto error
 	end
 	
 	-- HQMA Audit	 	 	 
insert bHQMA (TableName, RecType, KeyString, FieldName, OldValue, 
  	NewValue, DateTime, UserName)
select 'vDDFS', 'D', 'Co: ' + rtrim(Co) + ' Form: ' + rtrim(Form) + ' VPUserName: ' + rtrim(VPUserName) + ' SecurityGroup: ' + rtrim(SecurityGroup), null, null,
	null, getdate(), SUSER_SNAME() from deleted

return
 
error:
	select @errmsg = @errmsg + ' - cannot delete Form Security!'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     trigger [dbo].[vtDDFSi] on [dbo].[vDDFS] for INSERT 
/*-----------------------------------------------------------------
 * Created: GG 7/31/03
 * Modified: GG 1/21/05 - allow -1 Company #
 *			GG 06/19/07 - added AllowAttachments validation, corrected Access validation
 *
 *	This trigger rejects insertion in vDDFS (Form Security) if
 *	any of the following error conditions exist:
 *
 *		Invalid Company	(must be in bHQCO)
 *		Invalid Form	(must be in DDFHShared)
 *		Invalid Security Group (must -1 or in vDDSG)
 *		Invalid User	(must be in vDDUP)
 *		Invalid Form Access	(0 = Allowed, 1 = By Tab, 2 = Denied)
 *		Invalid Record Access (must be Y or N, must be N if Form Access denied)
 *
 */----------------------------------------------------------------
as


declare @errmsg varchar(255), @numrows int, @validcnt int, @usercnt int

select @numrows = @@rowcount
if @numrows = 0 return 
 
set nocount on
 
/* check for valid Companies */
select @usercnt = count(*) from inserted where Co = -1		-- all company entries
select @validcnt = count(*)
from dbo.bHQCO c (nolock)
join inserted i on c.HQCo = i.Co
if @validcnt + @usercnt <> @numrows
	begin
 	select @errmsg = 'Invalid Company'
 	goto error
 	end
 
/* check for valid Forms */
select @validcnt = count(*)
from dbo.DDFHShared f (nolock)
join inserted i on f.Form = i.Form
if @validcnt <> @numrows
 	begin
 	select @errmsg = 'Invalid Form'
 	goto error
 	end
-- validate Security Group
select @usercnt = count(*) from inserted where SecurityGroup = -1	-- user override entries
select @validcnt = count(*)
from inserted i
join dbo.vDDSG g (nolock) on i.SecurityGroup = g.SecurityGroup
where g.GroupType = 1	-- forms group
if @usercnt + @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid Security Group'
	goto error
	end
 
/* check for valid User */
select @validcnt = count(*)
from vDDUP u
join inserted i on u.VPUserName = i.VPUserName
if @validcnt <> @usercnt
 	begin
 		select @errmsg = 'Invalid user'
 		goto error
 	end

-- validate Form Access (0=full,1=tab,2=denied)
if exists(select top 1 1 from inserted where Access not in (0,1,2))
	begin
	select @errmsg = 'Invalid Form Access level, must be 0=full, 1=tab, or 2=denied'
	goto error
	end
if exists(select top 1 1 from inserted where Access = 2 and SecurityGroup <> -1)
	begin
	select @errmsg = 'Access level ''2=denied'' not valid for Security Groups'
	goto error
	end

-- validate RecAdd, RecUpdate, RecDelete
if exists (select top 1 1 from inserted where
		RecAdd not in ('Y','N') or RecUpdate not in ('Y','N') or RecDelete not in ('Y','N'))
	begin
	select @errmsg = 'Invalid Record Access, each must be ''Y'' or ''N'''
	goto error
	end
if exists(select top 1 1 from inserted where
		Access = 2 and (RecAdd = 'Y' or RecUpdate = 'Y' or RecDelete = 'Y'))
	begin
	select @errmsg = 'Record Access must be ''N'' if Form Access is denied'
	goto error
	end
	
-- validate Allow Attachments option
--if exists(select top 1 1 from dbo.DDFHShared f (nolock) join inserted i on f.Form = i.Form
--			where f.AllowAttachments = 'N' and i.AllowAttachments = 'Y')
--	begin
--	select @errmsg = 'Form does not allow Attachments'
--	goto error
--	end 
 
 -- validate Attachment option
if exists(select top 1 1 from dbo.DDFHShared f (nolock) join inserted i on f.Form = i.Form
			where f.AllowAttachments = 'N' and i.AttachmentSecurityLevel <> Null)
	begin
	select @errmsg = 'Form does not allow Attachments'
	goto error
	end 

 	-- HQMA Audit	 	 	 
insert bHQMA (TableName, RecType, KeyString, FieldName, OldValue, 
  	NewValue, DateTime, UserName)
select 'vDDFS', 'I', 'Co: ' + rtrim(Co) + ' Form: ' + rtrim(Form) + ' VPUserName: ' + rtrim(VPUserName) + ' SecurityGroup: ' + rtrim(SecurityGroup), null, null,
	null, getdate(), SUSER_SNAME() from inserted

return
 
error:
	select @errmsg = @errmsg + ' - cannot insert Form Security!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  trigger [dbo].[vtDDFSu] on [dbo].[vDDFS] for UPDATE 
/*-----------------------------------------------------------------
 *	Created: GG 7/31/03
 *	Modified: GG 06/19/07 - added AllowAttachments validation, corrected Access validation
 *           AL - 3/2/09 Added HQMA Audit
 *	This trigger rejects update in vDDFS (Form Security) if any
 *	of the following error conditions exist:
 *
 *		Cannot change primary index - Company, Form, Security Group, or User
 *		Invalid Form Access 	(0 = Allowed, 1 = By Tab, 2 = Denied)
 *		Tab Security exists but Form Access not By Tab 
 *		Invalid Record Access (must be Y or N, must be N if Form Access denied)
 *
 */----------------------------------------------------------------
as


declare @errmsg varchar(255), @numrows int, @validcnt int

select @numrows = @@rowcount
if @numrows = 0 return

set nocount on 
 
/* check for changes to Company, Form, Security Group or User */
select @validcnt = count(*) from
inserted i
join deleted d on i.Co = d.Co and i.Form = d.Form and i.SecurityGroup = d.SecurityGroup
	and i.VPUserName = d.VPUserName 
select @validcnt, @numrows
if @validcnt <> @numrows
 	begin
 	select @errmsg = 'Cannot change Company, Form, Security Group, or User'
 	goto error
 	end

-- validate Access (0=full,1=tab,2=denied
if update(Access)
	begin
	if exists(select top 1 1 from inserted where Access not in (0,1,2))
		begin
		select @errmsg = 'Invalid Access level, must be 0=full, 1=tab, or 2=denied'
		goto error
		end
	-- check for Tab Security entries
	if exists(select top 1 1 from inserted i
			join vDDTS t on i.Co = t.Co and i.Form = t.Form and i.SecurityGroup = t.SecurityGroup
				and i.VPUserName = t.VPUserName
			where i.Access <> 1)
	 	begin
	 	select @errmsg = 'Tab Security entries exist, Form Access must be ''1=tab'''
	 	goto error
	 	end
	-- check access level for Security Groups
	if exists(select top 1 1 from inserted where Access = 2 and SecurityGroup <> -1)
		begin
		select @errmsg = 'Access level ''2=denied'' not valid for Security Groups'
		goto error
		end
	end

-- validate Record Access
if update(RecAdd) or update(RecUpdate) or update(RecDelete) or update(Access)
	begin
	if exists (select top 1 1 from inserted where
		RecAdd not in ('Y','N') or RecUpdate not in ('Y','N') or RecDelete not in ('Y','N'))
		begin
		select @errmsg = 'Invalid Record Access, each must be ''Y'' or ''N'''
		goto error
		end
	if exists(select top 1 1 from inserted where
			Access = 2 and (RecAdd = 'Y' or RecUpdate = 'Y' or RecDelete = 'Y'))
		begin
		select @errmsg = 'Record Access must be ''N'' if Form Access denied'
		goto error
		end
	end

if update(AttachmentSecurityLevel)
if exists(select top 1 1 from dbo.DDFHShared f (nolock) join inserted i on f.Form = i.Form
where f.AllowAttachments = 'N' and i.AttachmentSecurityLevel <> Null)
				begin
				select @errmsg = 'Form does not allow Attachments'
				goto error
end

--HQMA Audit
if update(Access)
	insert dbo.bHQMA(TableName, RecType, KeyString, FieldName,
		OldValue, NewValue, DateTime, UserName)
	select  'vDDFS', 'U','Co: ' + rtrim(i.Co) + ' Form: ' + rtrim(i.Form) + ' VPUserName: ' + rtrim(i.VPUserName) + ' SecurityGroup: ' + rtrim(i.SecurityGroup), 'Access',
		d.Access, i.Access, getdate(), SUSER_SNAME()
  	from inserted i
  	join deleted d on i.SecurityGroup = d.SecurityGroup and i.Co = d.Co and i.VPUserName = d.VPUserName and i.Form = d.Form 
  	where isnull(i.Access,'') <> isnull(d.Access,'')
  	
if update(RecAdd)
	insert dbo.bHQMA(TableName, RecType, KeyString, FieldName,
		OldValue, NewValue, DateTime, UserName)
	select  'vDDFS', 'U', 'Co: ' + rtrim(i.Co) + ' Form: ' + rtrim(i.Form) + ' VPUserName: ' + rtrim(i.VPUserName) + ' SecurityGroup: ' + rtrim(i.SecurityGroup), 'RecAdd',
		d.RecAdd, i.RecAdd, getdate(), SUSER_SNAME()
  	from inserted i
  	join deleted d on i.SecurityGroup = d.SecurityGroup and i.Co = d.Co and i.VPUserName = d.VPUserName and i.Form = d.Form 
  	where isnull(i.RecAdd,'') <> isnull(d.RecAdd,'')
  	
if update(RecUpdate)
	insert dbo.bHQMA(TableName, RecType, KeyString, FieldName,
		OldValue, NewValue, DateTime, UserName)
	select  'vDDFS', 'U', 'Co: ' + rtrim(i.Co) + ' Form: ' + rtrim(i.Form) + ' VPUserName: ' + rtrim(i.VPUserName) + ' SecurityGroup: ' + rtrim(i.SecurityGroup), 'RecUpdate',
		d.RecUpdate, i.RecUpdate, getdate(), SUSER_SNAME()
  	from inserted i
  	join deleted d on i.SecurityGroup = d.SecurityGroup and i.Co = d.Co and i.VPUserName = d.VPUserName and i.Form = d.Form 
  	where isnull(i.RecUpdate,'') <> isnull(d.RecUpdate,'')
  	
if update(RecDelete)
	insert dbo.bHQMA(TableName, RecType, KeyString, FieldName,
		OldValue, NewValue, DateTime, UserName)
	select  'vDDFS', 'U', 'Co: ' + rtrim(i.Co) + ' Form: ' + rtrim(i.Form) + ' VPUserName: ' + rtrim(i.VPUserName) + ' SecurityGroup: ' + rtrim(i.SecurityGroup),
	'RecDelete', d.RecDelete, i.RecDelete, getdate(), SUSER_SNAME()
  	from inserted i
  	join deleted d on i.SecurityGroup = d.SecurityGroup and i.Co = d.Co and i.VPUserName = d.VPUserName and i.Form = d.Form 
  	where isnull(i.RecDelete,'') <> isnull(d.RecDelete,'')
  	
if update(AttachmentSecurityLevel)
	insert dbo.bHQMA(TableName, RecType, KeyString, FieldName,
		OldValue, NewValue, DateTime, UserName)
	select  'vDDFS', 'U', 'Co: ' + rtrim(i.Co) + ' Form: ' + rtrim(i.Form) + ' VPUserName: ' + rtrim(i.VPUserName) + ' SecurityGroup: ' + rtrim(i.SecurityGroup), 'AttachmentSecurityLevel',
		d.AttachmentSecurityLevel, i.AttachmentSecurityLevel, getdate(), SUSER_SNAME()
  	from inserted i
  	join deleted d on i.SecurityGroup = d.SecurityGroup and i.Co = d.Co and i.VPUserName = d.VPUserName and i.Form = d.Form 
  	where isnull(i.AttachmentSecurityLevel,'') <> isnull(d.AttachmentSecurityLevel,'')
  	
  	
return
 
error:
     select @errmsg = @errmsg + ' - cannot update Form Security!'
     RAISERROR(@errmsg, 11, -1);
     rollback transaction


GO
CREATE UNIQUE CLUSTERED INDEX [viDDFS] ON [dbo].[vDDFS] ([Co], [Form], [SecurityGroup], [VPUserName]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [viDDFSUserForm] ON [dbo].[vDDFS] ([VPUserName], [Co], [Access]) INCLUDE ([AttachmentSecurityLevel], [Form], [RecAdd], [RecDelete], [RecUpdate], [SecurityGroup]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[vDDFS].[RecAdd]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[vDDFS].[RecUpdate]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[vDDFS].[RecDelete]'
GO
