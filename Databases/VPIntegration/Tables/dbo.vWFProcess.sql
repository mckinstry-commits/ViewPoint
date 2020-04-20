CREATE TABLE [dbo].[vWFProcess]
(
[Process] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[DocType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Description] [dbo].[bItemDesc] NULL,
[Active] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vWFProcess_Active] DEFAULT ('Y'),
[DaysPerStep] [smallint] NOT NULL CONSTRAINT [DF_vWFProcess_DaysPerStep] DEFAULT ((0)),
[DaysToRemind] [smallint] NOT NULL CONSTRAINT [DF_vWFProcess_DaysToRemind] DEFAULT ((0)),
[Notes] [dbo].[bNotes] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[ApproveTotal] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vWFProcess_ApproveTotal] DEFAULT ('Y')
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




 
/*********************************************/
CREATE trigger [dbo].[vtWFProcessd] on [dbo].[vWFProcess] for DELETE as
/*----------------------------------------------------------
* Created By:	GP 2/27/2012
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
	select 'vWFProcess', 'Process: ' + d.Process, null, 'D', null, null, null, getdate(), SUSER_SNAME()
	from deleted d
	
end try	


begin catch

	select @errmsg = @errmsg + ' - cannot delete WF Process!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   	
end catch   	
   
   
   
  
 






GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE trigger [dbo].[vtWFProcessi] on [dbo].[vWFProcess] for INSERT as
/*-----------------------------------------------------------------
* Created By:	GP 2/27/2012
* Modified By:
*				JG 3/13/2012 - TK-00000 - Modified based on DocType changes.
*
*
* This trigger audits insertion in vWFProcess
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
	select 'vWFProcess', 'Process: ' + i.Process, null, 'A', null, null, null, getdate(), SUSER_SNAME()
	from inserted i
	
end try	


begin catch

	select @errmsg = @errmsg + ' - cannot insert WF Process!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
end catch   
  
 






GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





/**************************************/
CREATE trigger [dbo].[vtWFProcessu] on [dbo].[vWFProcess] for UPDATE as
/*-----------------------------------------------------------------
* Created By:	GP 2/27/2012
* Modified By:	JG 3/09/2012 - TK-13137 - Added DaysPerStep and DaysToRemind.
*				JG 3/13/2012 - TK-00000 - Modified based on DocType changes.
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
   		select 'vWFProcess', 'Process: ' + i.Process, null, 'C', 'Process', d.Process, i.Process, getdate(), SUSER_SNAME()
   		from inserted i join deleted d on i.Process = d.Process
   		where isnull(i.Process,'') <> isnull(d.Process,'')
	end
	if update(DocType)
	begin
   		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'vWFProcess', 'Process: ' + i.Process, null, 'C', 'DocType', d.DocType, i.DocType, getdate(), SUSER_SNAME()
   		from inserted i join deleted d on i.Process = d.Process
   		where isnull(i.DocType,'') <> isnull(d.DocType,'')
	end
	if update(Description)
	begin
   		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'vWFProcess', 'Process: ' + i.Process, null, 'C', 'Description', d.Description, i.Description, getdate(), SUSER_SNAME()
   		from inserted i join deleted d on i.Process = d.Process
   		where isnull(i.Description,'') <> isnull(d.Description,'')
	end
	if update(Active)
	begin
   		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'vWFProcess', 'Process: ' + i.Process, null, 'C', 'Active', d.Active, i.Active, getdate(), SUSER_SNAME()
   		from inserted i join deleted d on i.Process = d.Process
   		where isnull(i.Active,'') <> isnull(d.Active,'')
	end
	if update(DaysPerStep)
	begin
   		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'vWFProcess', 'Process: ' + i.Process, null, 'C', 'DaysPerStep', d.DaysPerStep, i.DaysPerStep, getdate(), SUSER_SNAME()
   		from inserted i join deleted d on i.Process = d.Process
   		where isnull(i.DaysPerStep,'') <> isnull(d.DaysPerStep,'')
	end
	if update(DaysToRemind)
	begin
   		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'vWFProcess', 'Process: ' + i.Process, null, 'C', 'DaysToRemind', d.DaysToRemind, i.DaysToRemind, getdate(), SUSER_SNAME()
   		from inserted i join deleted d on i.Process = d.Process
   		where isnull(i.DaysToRemind,'') <> isnull(d.DaysToRemind,'')
	end
end try	


begin catch

   	select @errmsg = @errmsg + ' - cannot update WF Process!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
end catch   
   
  
 






GO
ALTER TABLE [dbo].[vWFProcess] ADD CONSTRAINT [PK_vWFProcess] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vWFProcess] ADD CONSTRAINT [IX_vWFProcess_Process] UNIQUE CLUSTERED  ([Process]) ON [PRIMARY]
GO
