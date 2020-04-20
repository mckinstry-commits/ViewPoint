CREATE TABLE [dbo].[vDDTS]
(
[Co] [smallint] NOT NULL,
[Form] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Tab] [tinyint] NOT NULL,
[SecurityGroup] [int] NOT NULL,
[VPUserName] [dbo].[bVPUserName] NOT NULL,
[Access] [tinyint] NOT NULL
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [viDDTS] ON [dbo].[vDDTS] ([Co], [Form], [Tab], [SecurityGroup], [VPUserName]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE trigger [dbo].[vtDDTSd] on [dbo].[vDDTS] for Delete 
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
select 'vDDTS', 'D', 'Co: ' + rtrim(Co) + ' Form: ' + rtrim(Form) + ' VPUserName: ' + rtrim(VPUserName) + ' SecurityGroup: ' + rtrim(SecurityGroup) + ' Tab: ' + rtrim(Tab), null, null,
	null, getdate(), SUSER_SNAME() from deleted
return
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  trigger [dbo].[vtDDTSi] on [dbo].[vDDTS] for INSERT 
/*-----------------------------------------------------------------
 * Created: GG 8/19/07
 * Modified: AL - 3/2/09 Added HQMA Audit
 *
 *	This trigger rejects insertion in vDDTS (Tab Security) if
 *	any of the following error conditions exist:
 *
 *		Invalid Company	(must be in bHQCO)
 *		Invalid Form	(must be in DDFHShared)
 *		Invalid Tab		(must be in DDFTShared and not 0=grid)
 *		Invalid Security Group (must -1 or in vDDSG)
 *		Invalid User	(must be '' or in vDDUP)
 *		Invalid Form Access	(0 = Allowed, 1 = read Only, 2 = Denied)
 *
 */----------------------------------------------------------------
as


declare @errmsg varchar(255), @numrows int, @validcnt int, @usercnt int

select @numrows = @@rowcount
if @numrows = 0 return 
 
set nocount on
 
-- validate Companies
select @usercnt = count(*) from inserted where Co = -1		-- all company entries
select @validcnt = count(*)
from dbo.bHQCO c (nolock)
join inserted i on c.HQCo = i.Co
if @validcnt + @usercnt <> @numrows
	begin
 	select @errmsg = 'Invalid Company'
 	goto error
 	end
 
-- validate Forms 
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
 
-- validate User 
select @validcnt = count(*)
from dbo.vDDUP u (nolock)
join inserted i on u.VPUserName = i.VPUserName
if @validcnt <> @usercnt
 	begin
 	select @errmsg = 'Invalid user'
 	goto error
 	end

-- validate Tab
if exists(select top 1 1 from inserted where Tab = 0)
	begin
	select @errmsg = 'Cannot secure Grid tab'
	goto error
	end
select @validcnt = count(*)
from dbo.DDFTShared t (nolock)
join inserted i on i.Form = t.Form and i.Tab = t.Tab
if @validcnt <> @numrows
 	begin
 	select @errmsg = 'Invalid Tab'
 	goto error
 	end

-- validate Tab Access (0=full,1=read only,2=denied)
if exists(select top 1 1 from inserted where Access not in (0,1,2))
	begin
	select @errmsg = 'Invalid Tab Access level, must be 0=full, 1=read only, or 2=denied'
	goto error
	end
if exists(select top 1 1 from inserted where Access = 2 and SecurityGroup <> -1)
	begin
	select @errmsg = 'Access level ''2=denied'' not valid for Security Groups'
	goto error
	end
 
 	-- HQMA Audit	 	 	 
insert bHQMA (TableName, RecType, KeyString, FieldName, OldValue, 
  	NewValue, DateTime, UserName)
select 'vDDTS', 'I', 'Co: ' + rtrim(Co) + ' Form: ' + rtrim(Form) + ' VPUserName: ' + rtrim(VPUserName) + ' SecurityGroup: ' + rtrim(SecurityGroup) + ' Tab: ' + rtrim(Tab), null, null,
	null, getdate(), SUSER_SNAME() from inserted
return
 
error:
	select @errmsg = @errmsg + ' - cannot insert Tab Security!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE trigger [dbo].[vtDDTSu] on [dbo].[vDDTS] for UPDATE 
/*-----------------------------------------------------------------
 *	Created: GG 8/19/07
 *	Modified: AL Added HQMA Auditing
 *
 *	This trigger rejects update in vDDTS (Tab Security) if any
 *	of the following error conditions exist:
 *
 *		Cannot change primary index - Company, Form, Tab, Security Group, or User
 *		Invalid Tab Access 	(0 = Allowed, 1 = Read Only, 2 = Denied)
 *		Tab Security exists but Form Access not By Tab 
 *		Invalid Record Access (must be Y or N, must be N if Form Access denied)
 *
 */----------------------------------------------------------------
as


declare @errmsg varchar(255), @numrows int, @validcnt int

select @numrows = @@rowcount
if @numrows = 0 return

set nocount on 
 
/* check for changes to Company, Form, Tab, Security Group or User */
select @validcnt = count(*) from
inserted i
join deleted d on i.Co = d.Co and i.Form = d.Form and i.Tab = d.Tab 
	and i.SecurityGroup = d.SecurityGroup and i.VPUserName = d.VPUserName 
select @validcnt, @numrows
if @validcnt <> @numrows
 	begin
 	select @errmsg = 'Cannot change Company, Form, Tab, Security Group, or User'
 	goto error
 	end

-- validate Access (0=full,1=read only,2=denied
if update(Access)
	begin
	if exists(select top 1 1 from inserted where Access not in (0,1,2))
		begin
		select @errmsg = 'Invalid Access level, must be 0=full, 1=read only, or 2=denied'
		goto error
		end
	-- check access level for Security Groups
	if exists(select top 1 1 from inserted where Access = 2 and SecurityGroup <> -1)
		begin
		select @errmsg = 'Access level ''2=denied'' not valid for Security Groups'
		goto error
		end
	end

if update(Access)
	insert dbo.bHQMA(TableName, RecType, KeyString, FieldName,
		OldValue, NewValue, DateTime, UserName)
	select  'vDDTS', 'U', 'Co: ' + rtrim(i.Co) + ' Form: ' + rtrim(i.Form) + ' VPUserName: ' + rtrim(i.VPUserName) + ' SecurityGroup: ' + rtrim(i.SecurityGroup) + ' Tab: ' + rtrim(i.Tab), 'Access',
		d.Access, i.Access, getdate(), SUSER_SNAME()
  	from inserted i
  	join deleted d on i.SecurityGroup = d.SecurityGroup and i.Co = d.Co and i.VPUserName = d.VPUserName and i.Form = d.Form 
  	where isnull(i.Access,'') <> isnull(d.Access,'')
  	

return
 
error:
     select @errmsg = @errmsg + ' - cannot update Tab Security!'
     RAISERROR(@errmsg, 11, -1);
     rollback transaction


GO
