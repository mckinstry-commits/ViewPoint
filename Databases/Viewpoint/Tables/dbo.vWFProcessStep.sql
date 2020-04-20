CREATE TABLE [dbo].[vWFProcessStep]
(
[Process] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[Seq] [int] NOT NULL,
[ApproverType] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[UserName] [dbo].[bVPUserName] NULL,
[Role] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[Step] [int] NOT NULL,
[ApprovalLimit] [dbo].[bDollar] NOT NULL,
[ApproverOptional] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vWFProcessStep_ApproverOptional] DEFAULT ('N'),
[Notes] [dbo].[bNotes] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
ALTER TABLE [dbo].[vWFProcessStep] WITH NOCHECK ADD
CONSTRAINT [FK_vWFProcessStep_vDDUP] FOREIGN KEY ([UserName]) REFERENCES [dbo].[vDDUP] ([VPUserName])
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




 
/*********************************************/
CREATE trigger [dbo].[vtWFProcessStepd] on [dbo].[vWFProcessStep] for DELETE as
/*----------------------------------------------------------
* Created By:	JG 3/05/2012
* Modified By:
*				JG 3/13/2012 - TK-00000 - Modified based on DocType changes.
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
	select 'vWFProcessStep', 'Process: ' + d.Process + ' Seq: ' + CONVERT(VARCHAR, d.Seq), null, 'D', null, null, null, getdate(), SUSER_SNAME()
	from deleted d
	
end try	


begin catch

	select @errmsg = @errmsg + ' - cannot delete WF Process Step!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   	
end catch   	
   
   
   
  
 






GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE trigger [dbo].[vtWFProcessStepi] on [dbo].[vWFProcessStep] for INSERT as
/*-----------------------------------------------------------------
* Created By:	JG 3/05/2012
* Modified By:
*				JG 3/13/2012 - TK-00000 - Modified based on DocType changes.
*
*
* This trigger audits insertion in vWFProcessStep
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
	select 'vWFProcessStep', 'Process: ' + i.Process + ' Seq: ' + CONVERT(VARCHAR, i.Seq), null, 'A', null, null, null, getdate(), SUSER_SNAME()
	from inserted i
	
end try	


begin catch

	select @errmsg = @errmsg + ' - cannot insert WF Process Step!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
end catch   
  
 






GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






/**************************************/
CREATE trigger [dbo].[vtWFProcessStepu] on [dbo].[vWFProcessStep] for UPDATE as
/*-----------------------------------------------------------------
* Created By:	JG 3/05/2012
* Modified By:  JG 3/09/2012 - TK-13121 - Removed Actions and added ApproverOptional flag.
*				JG 3/13/2012 - TK-00000 - Modified based on DocType changes.
*				GF 06/11/2012 TK-15205 remove unused columns
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
   		select 'vWFProcessStep', 'Process: ' + i.Process + ' Seq: ' + CONVERT(VARCHAR, i.Seq), null, 'C', 'Process', d.Process, i.Process, getdate(), SUSER_SNAME()
   		from inserted i join deleted d on i.Process = d.Process AND i.Seq = d.Seq
   		where isnull(i.Process,'') <> isnull(d.Process,'')
	end
	if update(Seq)
	begin
   		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'vWFProcessStep', 'Process: ' + i.Process + ' Seq: ' + CONVERT(VARCHAR, i.Seq), null, 'C', 'Seq', d.Seq, i.Seq, getdate(), SUSER_SNAME()
   		from inserted i join deleted d on i.Process = d.Process AND i.Seq = d.Seq
   		where isnull(i.Seq,'') <> isnull(d.Seq,'')
	end
	if update(ApproverType)
	begin
   		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'vWFProcessStep', 'Process: ' + i.Process + ' Seq: ' + CONVERT(VARCHAR, i.Seq), null, 'C', 'ApproverType', d.ApproverType, i.ApproverType, getdate(), SUSER_SNAME()
   		from inserted i join deleted d on i.Process = d.Process AND i.Seq = d.Seq
   		where isnull(i.ApproverType,'') <> isnull(d.ApproverType,'')
	end
	if update(UserName)
	begin
   		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'vWFProcessStep', 'Process: ' + i.Process + ' Seq: ' + CONVERT(VARCHAR, i.Seq), null, 'C', 'UserName', d.UserName, i.UserName, getdate(), SUSER_SNAME()
   		from inserted i join deleted d on i.Process = d.Process AND i.Seq = d.Seq
   		where isnull(i.UserName,'') <> isnull(d.UserName,'')
	end
	if update(Role)
	begin
   		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'vWFProcessStep', 'Process: ' + i.Process + ' Seq: ' + CONVERT(VARCHAR, i.Seq), null, 'C', 'Role', d.Role, i.Role, getdate(), SUSER_SNAME()
   		from inserted i join deleted d on i.Process = d.Process AND i.Seq = d.Seq
   		where isnull(i.Role,'') <> isnull(d.Role,'')
	end
	if update(Step)
	begin
   		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'vWFProcessStep', 'Process: ' + i.Process + ' Seq: ' + CONVERT(VARCHAR, i.Seq), null, 'C', 'Step', d.Step, i.Step, getdate(), SUSER_SNAME()
   		from inserted i join deleted d on i.Process = d.Process AND i.Seq = d.Seq
   		where isnull(i.Step,'') <> isnull(d.Step,'')
	end
	if update(ApprovalLimit)
	begin
   		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'vWFProcessStep', 'Process: ' + i.Process + ' Seq: ' + CONVERT(VARCHAR, i.Seq), null, 'C', 'ApprovalLimit', d.ApprovalLimit, i.ApprovalLimit, getdate(), SUSER_SNAME()
   		from inserted i join deleted d on i.Process = d.Process AND i.Seq = d.Seq
   		where isnull(i.ApprovalLimit,'') <> isnull(d.ApprovalLimit,'')
	end
	if update(ApproverOptional)
	begin
   		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'vWFProcessStep', 'Process: ' + i.Process + ' Seq: ' + CONVERT(VARCHAR, i.Seq), null, 'C', 'ApproverOptional', d.ApproverOptional, i.ApproverOptional, getdate(), SUSER_SNAME()
   		from inserted i join deleted d on i.Process = d.Process AND i.Seq = d.Seq
   		where isnull(i.ApproverOptional,'') <> isnull(d.ApproverOptional,'')
	end

end try	


begin catch

   	select @errmsg = @errmsg + ' - cannot update WF Process Step!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
end catch

GO
ALTER TABLE [dbo].[vWFProcessStep] ADD CONSTRAINT [PK_vWFProcessStep] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vWFProcessStep] ADD CONSTRAINT [IX_vWFProcessStep_ProcessSeq] UNIQUE CLUSTERED  ([Process], [Seq]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vWFProcessStep] WITH NOCHECK ADD CONSTRAINT [FK_vWFProcessStep_vWFProcess] FOREIGN KEY ([Process]) REFERENCES [dbo].[vWFProcess] ([Process])
GO
ALTER TABLE [dbo].[vWFProcessStep] WITH NOCHECK ADD CONSTRAINT [FK_vWFProcessStep_vHQRoles] FOREIGN KEY ([Role]) REFERENCES [dbo].[vHQRoles] ([Role])
GO
