CREATE TABLE [dbo].[vDDSU]
(
[SecurityGroup] [int] NOT NULL,
[VPUserName] [dbo].[bVPUserName] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE  trigger [dbo].[vtDDSUd] on [dbo].[vDDSU] for DELETE 
/*-----------------------------------------------------------------
 *	Created: GG 7/31/03
 *	Modified: AL Added HQMA Auditing
 *
 *	This trigger deletes entries in vDDDU (Data Security Users) if  
 *	a delete was made to vDDSU (Security Groups Users) and that
 *	group exists in vDDDS
 *		
 *		
 *
 */----------------------------------------------------------------
as


declare @errmsg varchar(255), @validcnt int

if @@rowcount = 0 return
set nocount on

-- remove User Data Security for the deleted SecurityGroup and User
delete dbo.vDDDU
from deleted t
join dbo.vDDDS s (nolock) on s.SecurityGroup = t.SecurityGroup
join dbo.vDDDU u on s.Datatype = u.Datatype and s.Qualifier = u.Qualifier and s.Instance = u.Instance
		and u.VPUserName = t.VPUserName
where not exists(select top 1 1 from dbo.vDDSU d
					join dbo.vDDDS s2 on s2.SecurityGroup = d.SecurityGroup and s2.Datatype = u.Datatype
						and s2.Qualifier = u.Qualifier and s2.Instance = u.Instance and u.VPUserName=d.VPUserName
					where s2.SecurityGroup <> t.SecurityGroup)
					
	
	-- HQMA Audit	 	 	 
insert bHQMA (TableName, RecType, KeyString, FieldName, OldValue, 
  	NewValue, DateTime, UserName)
select 'vDDSU', 'D', 'SecurityGroup: ' + rtrim(SecurityGroup) + ' VPUserName: ' + rtrim(VPUserName), null, null,
	null, getdate(), SUSER_SNAME() from deleted
 
return






GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE  trigger [dbo].[vtDDSUi] on [dbo].[vDDSU] for INSERT 
/*-----------------------------------------------------------------
 *	Created GG 7/31/03
 *	Modified: AL 9/2/08: Added distinct check to avoid duplicate inserts.
 *						 Issue #129688
 *										 AL 03/02/09 - Added HQMA auditing 
 *	This trigger rejects insertion in vDDSU (Security Group Users) if
 *	any of the following error conditions exist:
 *
 *		Invalid Security Group
 *		Invalid User
 * 
 *	Add entries to vDDDU (Data Security Users) for all instances
 *	of secured data based on inserted Security Group and User
 *
 */----------------------------------------------------------------

as


declare @errmsg varchar(255), @numrows int, @validcnt int

select @numrows = @@rowcount
if @numrows = 0 return

set nocount on
 
-- validate Security Group
select @validcnt = count(*) from dbo.vDDSG g (nolock)
join inserted i on g.SecurityGroup = i.SecurityGroup
if @validcnt <> @numrows
	begin
  	select @errmsg = 'Invalid Security Group'
  	goto error
  	end
 
-- validate User 
select @validcnt = count(*) from dbo.vDDUP u (nolock)
join inserted i on  u.VPUserName = i.VPUserName
if @validcnt <> @numrows
	begin
  	select @errmsg = 'Invalid User'
  	goto error
  	end
 
-- HQMA Audit	 	 	 
insert bHQMA (TableName, RecType, KeyString, FieldName, OldValue, 
  	NewValue, DateTime, UserName)
select 'vDDSU', 'I', 'SecurityGroup: ' + rtrim(SecurityGroup) + ' VPUserName: ' + rtrim(VPUserName), null, null,
	null, getdate(), SUSER_SNAME() from inserted

-- add User Data Security for data accessible by the Security Group
insert dbo.vDDDU (Datatype, Qualifier, Instance, VPUserName)
select distinct s.Datatype, s.Qualifier, s.Instance, i.VPUserName -- added distinct to prevent duplicates
from inserted i
join dbo.vDDDS s (nolock) on i.SecurityGroup = s.SecurityGroup
      and not exists (select top 1 1 from dbo.vDDDU u
                                    where u.Datatype = s.Datatype and u.Qualifier = s.Qualifier
                                          and u.Instance = s.Instance and u.VPUserName = i.VPUserName)


return
 
error:
	select @errmsg = @errmsg + ' - cannot insert in Security Group User!'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
 
 
 





GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE   trigger [dbo].[vtDDSUu] on [dbo].[vDDSU] for UPDATE 
/*-----------------------------------------------------------------
 *	Created: GG 7/31/03	
 *	Modified:
 *
 *	This trigger rejects update in vDDSU (Security Group Users) if any
 *	of the following error conditions exist:
 *
 *		Cannot change Security Group or User
 *
 */----------------------------------------------------------------
as


declare @errmsg varchar(255), @numrows int, @validcnt int

select @numrows = @@rowcount
if @numrows = 0 return

set nocount on
 
/* check for changes to Security Group Users */
select @validcnt = count(*)
from inserted i
join deleted d	on i.SecurityGroup = d.SecurityGroup and i.VPUserName = d.VPUserName
if @validcnt <> @numrows
	begin
 	select @errmsg = 'Cannot change Security Group or User'
 	goto error
 	end
 
return
 
error:
     select @errmsg = @errmsg + ' - cannot update Security Group Users!'
     RAISERROR(@errmsg, 11, -1);
     rollback transaction
 
 






GO
CREATE UNIQUE CLUSTERED INDEX [viDDSU] ON [dbo].[vDDSU] ([SecurityGroup], [VPUserName]) ON [PRIMARY]
GO
