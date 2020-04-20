CREATE TABLE [dbo].[vEMDepartmentRole]
(
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[EMCo] [dbo].[bCompany] NOT NULL,
[Department] [dbo].[bDept] NOT NULL,
[VPUserName] [dbo].[bVPUserName] NOT NULL,
[Role] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[Lead] [dbo].[bYN] NOT NULL,
[Active] [dbo].[bYN] NOT NULL,
[Notes] [dbo].[bNotes] NULL,
[UniqueAttchID] [uniqueidentifier] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE trigger [dbo].[vtEMDepartmentRoled] on [dbo].[vEMDepartmentRole] for DELETE as
/*----------------------------------------------------------
* Created By:	NH 3/16/2012
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

	---- Audit EM Department Role deletions
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vEMDepartmentRole', 'EMCo: ' + cast(d.EMCo as varchar(3)) + ' Department: ' + d.Department + ' Role: ' + d.Role + ' VP User Name: ' + d.VPUserName, null, 'D', null, null, null, getdate(), SUSER_SNAME()
	from deleted d
	
end try	

begin catch

	select @errmsg = @errmsg + ' - cannot delete EM Department Role!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   	
end catch   	
   
   
   
  
 






GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE trigger [dbo].[vtEMDepartmentRolei] on [dbo].[vEMDepartmentRole] for INSERT as
/*-----------------------------------------------------------------
* Created By:	NH 3/16/2012
* Modified By:
*
*
* This trigger audits insertion in vEMDepartmentRole
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
	select 'vEMDepartmentRole', 'EMCo: ' + cast(i.EMCo as varchar(3)) + ' Department: ' + i.Department + ' Role: ' + i.Role + ' VP User Name: ' + i.VPUserName, null, 'A', null, null, null, getdate(), SUSER_SNAME()
	from inserted i
	
end try	


begin catch

	select @errmsg = @errmsg + ' - cannot insert EM Department Role!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
end catch   
  
 






GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/**************************************/
CREATE trigger [dbo].[vtEMDepartmentRoleu] on [dbo].[vEMDepartmentRole] for UPDATE as
/*-----------------------------------------------------------------
* Created By:	NH 3/16/2012
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
	if update(Lead)
	begin
   		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'vEMDepartmentRole', 'EMCo : ' + cast(i.EMCo as varchar(3)) + ' Department: ' + i.Department + ' Role: ' + i.Role + ' VP User Name: ' + i.VPUserName, null, 'C', 'Lead', d.Lead, i.Lead, getdate(), SUSER_SNAME()
   		from inserted i join deleted d on i.EMCo = d.EMCo and i.Department = d.Department and i.Role = d.Role and i.VPUserName = d.VPUserName
   		where isnull(i.Lead,'') <> isnull(d.Lead,'')
	end
	if update(Active)
	begin
   		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'vEMDepartmentRole', 'EMCo : ' + cast(i.EMCo as varchar(3)) + ' Department: ' + i.Department + ' Role: ' + i.Role + ' VP User Name: ' + i.VPUserName, null, 'C', 'Active', d.Active, i.Active, getdate(), SUSER_SNAME()
   		from inserted i join deleted d on i.EMCo = d.EMCo and i.Department = d.Department and i.Role = d.Role and i.VPUserName = d.VPUserName
   		where isnull(i.Active,'') <> isnull(d.Active,'')
	end
	
end try	

begin catch

   	select @errmsg = @errmsg + ' - cannot update EM Department Role!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
end catch   
   
  
 






GO
ALTER TABLE [dbo].[vEMDepartmentRole] ADD CONSTRAINT [PK_vEMDepartmentRole] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [IX_vEMDepartmentRole_Role] ON [dbo].[vEMDepartmentRole] ([EMCo], [Department], [VPUserName], [Role]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vEMDepartmentRole] WITH NOCHECK ADD CONSTRAINT [FK_vEMDepartmentRole_bEMDM] FOREIGN KEY ([EMCo], [Department]) REFERENCES [dbo].[bEMDM] ([EMCo], [Department])
GO
ALTER TABLE [dbo].[vEMDepartmentRole] WITH NOCHECK ADD CONSTRAINT [FK_vEMDepartmentRole_vHQRoles] FOREIGN KEY ([Role]) REFERENCES [dbo].[vHQRoles] ([Role])
GO
ALTER TABLE [dbo].[vEMDepartmentRole] NOCHECK CONSTRAINT [FK_vEMDepartmentRole_bEMDM]
GO
ALTER TABLE [dbo].[vEMDepartmentRole] NOCHECK CONSTRAINT [FK_vEMDepartmentRole_vHQRoles]
GO
