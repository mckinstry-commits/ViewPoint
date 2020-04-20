CREATE TABLE [dbo].[vJCJobApprovalProcess]
(
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[JCCo] [dbo].[bCompany] NOT NULL,
[Job] [dbo].[bJob] NOT NULL,
[DocType] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Process] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[Active] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vJCJobApprovalProcess_Active] DEFAULT ('Y'),
[Notes] [dbo].[bNotes] NULL,
[UniqueAttchID] [uniqueidentifier] NULL
) ON [PRIMARY]
ALTER TABLE [dbo].[vJCJobApprovalProcess] WITH NOCHECK ADD
CONSTRAINT [FK_vJCJobApprovalProcess_bJCJM_Job] FOREIGN KEY ([JCCo], [Job]) REFERENCES [dbo].[bJCJM] ([JCCo], [Job])
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


 
CREATE trigger [dbo].[vtJCJobApprovalProcessd] on [dbo].[vJCJobApprovalProcess] for DELETE as
/*----------------------------------------------------------
* Created By:	NH 3/27/2012
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
	select 'vJCJobApprovalProcess', 'JCCo: ' + cast(d.JCCo as varchar(3)) + ' Job: ' + d.Job + ' DocType: ' + d.DocType + 'Process: ' + d.Process, d.JCCo, 'D', null, null, null, getdate(), SUSER_SNAME()
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



CREATE trigger [dbo].[vtJCJobApprovalProcessi] on [dbo].[vJCJobApprovalProcess] for INSERT as
/*-----------------------------------------------------------------
* Created By:	NH 3/27/2012
* Modified By:
*
*
*
* This trigger audits insertion in vJCJobApprovalProcess
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
	select 'vJCJobApprovalProcess',
	'JCCo: ' + cast(i.JCCo as varchar(3)) + ' Job: ' + i.Job + ' DocType: ' + i.DocType + ' Process: ' + i.Process,
	i.JCCo, 'A', null, null, null, getdate(), SUSER_SNAME()
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



CREATE trigger [dbo].[vtJCJobApprovalProcessu] on [dbo].[vJCJobApprovalProcess] for UPDATE as
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
   		select 'vJCJobApprovalProcess', 'JCCo: ' + cast(i.JCCo as varchar(3)) + ' Job: ' + i.Job + ' DocType: ' + i.DocType + ' Process: ' + i.Process, i.JCCo, 'C', 'Process', d.Process, i.Process, getdate(), SUSER_SNAME()
   		from inserted i join deleted d on i.JCCo = d.JCCo and i.Job = d.Job and i.DocType = d.DocType
   		where isnull(i.Process,'') <> isnull(d.Process,'')
	end
	if update(Active)
	begin
   		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'vJCJobApprovalProcess', 'JCCo: ' + cast(i.JCCo as varchar(3)) + ' Job: ' + i.Job + ' DocType: ' + i.DocType + ' Process: ' + i.Process, i.JCCo, 'C', 'Active', d.Active, i.Active, getdate(), SUSER_SNAME()
   		from inserted i join deleted d on i.JCCo = d.JCCo and i.Job = d.Job and i.DocType = d.DocType
   		where isnull(i.Active,'') <> isnull(d.Active,'')
	end
end try	


begin catch

   	select @errmsg = @errmsg + ' - cannot update HQ Approval Process!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
end catch   
   
  
 










GO
ALTER TABLE [dbo].[vJCJobApprovalProcess] ADD CONSTRAINT [PK_vJCJobApprovalProcess] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [IX_vJCJobApprovalProcess_Process] ON [dbo].[vJCJobApprovalProcess] ([JCCo], [Job], [DocType], [Process]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_vJCJobApprovalProcess_ProcessOnly] ON [dbo].[vJCJobApprovalProcess] ([Process]) ON [PRIMARY]
GO

ALTER TABLE [dbo].[vJCJobApprovalProcess] WITH NOCHECK ADD CONSTRAINT [FK_vJCJobApprovalProcess_vWFProcess_Process] FOREIGN KEY ([Process]) REFERENCES [dbo].[vWFProcess] ([Process])
GO
