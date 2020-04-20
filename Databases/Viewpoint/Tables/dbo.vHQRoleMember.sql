CREATE TABLE [dbo].[vHQRoleMember]
(
[Role] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[UserName] [dbo].[bVPUserName] NOT NULL,
[Active] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vHQRoleMember_Active] DEFAULT ('Y'),
[Notes] [dbo].[bNotes] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
ALTER TABLE [dbo].[vHQRoleMember] WITH NOCHECK ADD
CONSTRAINT [FK_vHQRoleMember_vDDUP] FOREIGN KEY ([UserName]) REFERENCES [dbo].[vDDUP] ([VPUserName])
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


 
/*********************************************/
CREATE trigger [dbo].[vtHQRoleMemberd] on [dbo].[vHQRoleMember] for DELETE as
/*----------------------------------------------------------
* Created By:	GP 2/23/2012
* Modified By:
*
*
*
*
*/---------------------------------------------------------
declare @errmsg varchar(255), @numrows int

select @numrows = @@rowcount
set nocount on
if @numrows = 0 return

begin try

	---- Audit HQ Company deletions
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vHQRoleMember', 'HQ Role: ' + d.Role + ' UserName: ' + d.UserName, null, 'D', null, null, null, getdate(), SUSER_SNAME()
	from deleted d
	
end try	


begin catch

	select @errmsg = @errmsg + ' - cannot delete HQ Role Member!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
end catch   
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE trigger [dbo].[vtHQRoleMemberi] on [dbo].[vHQRoleMember] for INSERT as
/*-----------------------------------------------------------------
* Created By:	GP 2/23/2012
* Modified By:
*
*
* This trigger audits insertion in vHQRoleMember
*
*
* Adds HQ Master Audit entry.
*/----------------------------------------------------------------
declare @errmsg varchar(255), @numrows int, @validcnt int, @nullcnt int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

begin try

	/* add HQ Master Audit entry */
	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vHQRoleMember', 'HQ Role: ' + i.Role + ' UserName: ' + i.UserName, null, 'A', null, null, null, getdate(), SUSER_SNAME()
	from inserted i
	
end try	


begin catch

	select @errmsg = @errmsg + ' - cannot insert HQ Role Member!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
end catch   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/**************************************/
CREATE trigger [dbo].[vtHQRoleMemberu] on [dbo].[vHQRoleMember] for UPDATE as
/*-----------------------------------------------------------------
* Created By:	GP 2/23/2012
* Modified By:
*
* No current error checks for update.	
*
* Adds records to HQ Master Audit.
*/----------------------------------------------------------------
declare @errmsg varchar(255), @numrows int, @validcnt int, @nullcnt int,
		@hqco bCompany, @name varchar(60), @oldname varchar(60)

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

begin try

	/* always update HQ Master Audit */
	if update(UserName)
	begin
   		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'vHQRoleMember', 'HQ Role: ' + i.Role + ' UserName: ' + i.UserName, null, 'C', 'UserName', d.UserName, i.UserName, getdate(), SUSER_SNAME()
   		from inserted i join deleted d on i.Role = d.Role and i.UserName = d.UserName
   		where isnull(i.UserName,'') <> isnull(d.UserName,'')
	end
	if update(Active)
	begin
   		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'vHQRoleMember', 'HQ Role: ' + i.Role + ' UserName: ' + i.UserName, null, 'C', 'Active', d.Active, i.Active, getdate(), SUSER_SNAME()
   		from inserted i join deleted d on i.Role = d.Role and i.UserName = d.UserName
   		where isnull(i.Active,'') <> isnull(d.Active,'')
	end
	
end try	


begin catch

   	select @errmsg = @errmsg + ' - cannot update HQ Role Member!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
end catch   
   
  
 




GO
ALTER TABLE [dbo].[vHQRoleMember] ADD CONSTRAINT [PK_vHQRoleMember] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vHQRoleMember] ADD CONSTRAINT [IX_vHQRoleMember_UserName] UNIQUE CLUSTERED  ([Role], [UserName]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vHQRoleMember] WITH NOCHECK ADD CONSTRAINT [FK_vHQRoleMember_vHQRoles] FOREIGN KEY ([Role]) REFERENCES [dbo].[vHQRoles] ([Role])
GO
