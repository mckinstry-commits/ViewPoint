CREATE TABLE [dbo].[vEMDepartmentApprovalProcess]
(
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[EMCo] [dbo].[bCompany] NOT NULL,
[Department] [dbo].[bDept] NOT NULL,
[DocType] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Process] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[Active] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vEMDepartmentApprovalProcess_Active] DEFAULT ('Y'),
[Notes] [dbo].[bNotes] NULL,
[UniqueAttchID] [uniqueidentifier] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




 
CREATE trigger [dbo].[vtEMDepartmentApprovalProcessd] on [dbo].[vEMDepartmentApprovalProcess] for DELETE as
/*----------------------------------------------------------
* Created By:	NH 3/29/2012
* Modified By:
*
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
	select 'vEMDepartmentApprovalProcess', 'EMCo: ' + cast(d.EMCo as varchar(3)) + ' Department: ' + d.Department + ' DocType: ' + d.DocType + 'Process: ' + d.Process, d.EMCo, 'D', null, null, null, getdate(), SUSER_SNAME()
	from deleted d
	
end try	


begin catch

	select @errmsg = @errmsg + ' - cannot delete HQ Approval Process!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   	
end catch   	
   
   
   
  
 












GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE trigger [dbo].[vtEMDepartmentApprovalProcessi] on [dbo].[vEMDepartmentApprovalProcess] for INSERT as
/*-----------------------------------------------------------------
* Created By:	NH 3/27/2012
* Modified By:
*
*
*
* This trigger audits insertion in vEMDepartmentApprovalProcess
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
	select 'vEMDepartmentApprovalProcess',
	'EMCo: ' + cast(i.EMCo as varchar(3)) + ' Department: ' + i.Department + ' DocType: ' + i.DocType + ' Process: ' + i.Process,
	i.EMCo, 'A', null, null, null, getdate(), SUSER_SNAME()
	from inserted i
	
end try	


begin catch

	select @errmsg = @errmsg + ' - cannot insert HQ Approval Process!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
end catch   
  
 












GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE trigger [dbo].[vtEMDepartmentApprovalProcessu] on [dbo].[vEMDepartmentApprovalProcess] for UPDATE as
/*-----------------------------------------------------------------
* Created By:	NH 3/27/2012
* Modified By:
*
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
	if update(Process)
	begin
   		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'vEMDepartmentApprovalProcess', 'EMCo: ' + cast(i.EMCo as varchar(3)) + ' Department: ' + i.Department + ' DocType: ' + i.DocType + ' Process: ' + i.Process, i.EMCo, 'C', 'Process', d.Process, i.Process, getdate(), SUSER_SNAME()
   		from inserted i join deleted d on i.EMCo = d.EMCo and i.Department = d.Department and i.DocType = d.DocType
   		where isnull(i.Process,'') <> isnull(d.Process,'')
	end
	if update(Active)
	begin
   		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'vEMDepartmentApprovalProcess', 'EMCo: ' + cast(i.EMCo as varchar(3)) + ' Department: ' + i.Department + ' DocType: ' + i.DocType + ' Process: ' + i.Process, i.EMCo, 'C', 'Active', d.Active, i.Active, getdate(), SUSER_SNAME()
   		from inserted i join deleted d on i.EMCo = d.EMCo and i.Department = d.Department and i.DocType = d.DocType
   		where isnull(i.Active,'') <> isnull(d.Active,'')
	end
end try	


begin catch

   	select @errmsg = @errmsg + ' - cannot update HQ Approval Process!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
end catch   
GO
ALTER TABLE [dbo].[vEMDepartmentApprovalProcess] ADD CONSTRAINT [PK_vEMDepartmentApprovalProcess] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [IX_vEMDepartmentApprovalProcess_Process] ON [dbo].[vEMDepartmentApprovalProcess] ([EMCo], [Department], [DocType], [Process]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_vEMDepartmentApprovalProcess_ProcessOnly] ON [dbo].[vEMDepartmentApprovalProcess] ([Process]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vEMDepartmentApprovalProcess] WITH NOCHECK ADD CONSTRAINT [FK_vEMDepartmentApprovalProcess_bEMDM_Department] FOREIGN KEY ([EMCo], [Department]) REFERENCES [dbo].[bEMDM] ([EMCo], [Department])
GO
ALTER TABLE [dbo].[vEMDepartmentApprovalProcess] WITH NOCHECK ADD CONSTRAINT [FK_vEMDepartmentApprovalProcess_vWFProcess_Process] FOREIGN KEY ([Process]) REFERENCES [dbo].[vWFProcess] ([Process])
GO
ALTER TABLE [dbo].[vEMDepartmentApprovalProcess] NOCHECK CONSTRAINT [FK_vEMDepartmentApprovalProcess_bEMDM_Department]
GO
ALTER TABLE [dbo].[vEMDepartmentApprovalProcess] NOCHECK CONSTRAINT [FK_vEMDepartmentApprovalProcess_vWFProcess_Process]
GO
