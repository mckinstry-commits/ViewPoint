CREATE TABLE [dbo].[vWFProcessDetailApprover]
(
[DetailStepID] [bigint] NOT NULL,
[Approver] [dbo].[bVPUserName] NOT NULL,
[Status] [tinyint] NULL,
[ApprovalLimit] [dbo].[bDollar] NULL,
[ApproverOptional] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vWFProcessDetailApprover_ApproverOptional] DEFAULT ('N'),
[WFProcessStepID] [bigint] NULL,
[Notes] [dbo].[bNotes] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[Comments] [dbo].[bNotes] NULL,
[ReturnTo] [varchar] (140) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






 
/*********************************************/
CREATE trigger [dbo].[vtWFProcessDetailApproverd] on [dbo].[vWFProcessDetailApprover] for DELETE as
/*----------------------------------------------------------
* Created By:	GP 4/13/2012
* Modified By:	GP 5/24/2012 - TK-15149 Added history table insert
*				GF 06/11/2012 TK-15205 remove unused columns
*				GP 6/12/2012 - TK-15656 Removed LastUpdated column
*				GPT 6/28/2012 - TK-00000 Queue attachments for delete 
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
	select 'vWFProcessDetailApprover', 'DetailStepID: ' + cast(d.DetailStepID as varchar) + ' Approver: ' + d.Approver, null, 'D', null, null, null, getdate(), SUSER_SNAME()
	from deleted d
	
	INSERT dbo.vWFProcessDetailApproverHistory([Action], [DateTime], DetailStepID, Approver, [Status],
		ApprovalLimit, ApproverOptional, WFProcessStepID,
		Notes, UniqueAttchID, Comments, ReturnTo, KeyID)
	SELECT 'DELETE', GETDATE(), DetailStepID, Approver, [Status],
		ApprovalLimit, ApproverOptional, WFProcessStepID,
		Notes, UniqueAttchID, Comments, ReturnTo, KeyID
	FROM DELETED
	
	-- Delete attachments if they exist. Make sure UniqueAttchID is not null
	INSERT vDMAttachmentDeletionQueue (AttachmentID, UserName, DeletedFromRecord)
	SELECT AttachmentID, suser_name(), 'Y' 
		FROM bHQAT h JOIN deleted d ON h.UniqueAttchID = d.UniqueAttchID                  
		WHERE d.UniqueAttchID IS NOT NULL    
	
end try	


begin catch

	select @errmsg = @errmsg + ' - cannot delete WF Process Detail Approver!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   	
end catch   	
   
   
   
  
 








GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE trigger [dbo].[vtWFProcessDetailApproveri] on [dbo].[vWFProcessDetailApprover] for INSERT as
/*-----------------------------------------------------------------
* Created By:	GP 4/13/2012
* Modified By:	GP 5/24/2012 - TK-15149 Added history table insert
*				GF 06/11/2012 TK-15205 remove unused columns
*				GP 6/12/2012 - TK-15656 Removed LastUpdated column
*				
*
*
* This trigger audits insertion in vWFProcessDetailApprover
*
*
* Adds HQ Master Audit entry.
*/----------------------------------------------------------------
declare @errmsg varchar(255), @numrows int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

begin try

	/* add HQ Master Audit entry */
	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vWFProcessDetailApprover', 'DetailStepID: ' + cast(i.DetailStepID as varchar) + ' Approver: ' + i.Approver, null, 'A', null, null, null, getdate(), SUSER_SNAME()
	from inserted i
	
	INSERT dbo.vWFProcessDetailApproverHistory([Action], [DateTime], DetailStepID, Approver, [Status],
		ApprovalLimit, ApproverOptional, WFProcessStepID,
		Notes, UniqueAttchID, Comments, ReturnTo, KeyID)
	SELECT 'INSERT', GETDATE(), DetailStepID, Approver, [Status],
		ApprovalLimit, ApproverOptional, WFProcessStepID,
		Notes, UniqueAttchID, Comments, ReturnTo, KeyID
	FROM INSERTED
	
end try	


begin catch

	select @errmsg = @errmsg + ' - cannot insert WF Process Detail Approver!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
end catch   
  
 








GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







/**************************************/
CREATE trigger [dbo].[vtWFProcessDetailApproveru] on [dbo].[vWFProcessDetailApprover] for UPDATE as
/*-----------------------------------------------------------------
* Created By:	GP 4/13/2012
* Modified By:	GP 5/24/2012 - TK-15149 Added history table insert
*				GF 06/11/2012 TK-15205 remove unused columns
*				GP 6/12/2012 - TK-15656 Removed LastUpdated column
*
* No current error checks for update.	
*
* Adds records to HQ Master Audit.
*/----------------------------------------------------------------
declare @errmsg varchar(255), @numrows int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

begin try

	/* always update HQ Master Audit */
	if update(Status)
	begin
   		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'vWFProcessDetailApprover', 'DetailStepID: ' + cast(i.DetailStepID as varchar) + ' Approver: ' + i.Approver, null, 'C', 'Status', d.Status, i.Status, getdate(), SUSER_SNAME()
   		from inserted i join deleted d on i.DetailStepID = d.DetailStepID and i.Approver = d.Approver
   		
   		INSERT dbo.vWFProcessDetailApproverHistory([Action], [DateTime], DetailStepID, Approver, [Status],
			ApprovalLimit, ApproverOptional, WFProcessStepID,
			Notes, UniqueAttchID, Comments, ReturnTo, FieldName, KeyID)
		SELECT 'UPDATE', GETDATE(), DetailStepID, Approver, [Status],
			ApprovalLimit, ApproverOptional, WFProcessStepID,
			Notes, UniqueAttchID, Comments, ReturnTo, 'Status', KeyID
		FROM INSERTED	
	end
	
	if update(Comments)
	begin
   		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'vWFProcessDetailApprover', 'DetailStepID: ' + cast(i.DetailStepID as varchar) + ' Approver: ' + i.Approver, null, 'C', 'Comments', d.Comments, i.Comments, getdate(), SUSER_SNAME()
   		from inserted i join deleted d on i.DetailStepID = d.DetailStepID and i.Approver = d.Approver
   		
   		INSERT dbo.vWFProcessDetailApproverHistory([Action], [DateTime], DetailStepID, Approver, [Status],
			ApprovalLimit, ApproverOptional, WFProcessStepID,
			Notes, UniqueAttchID, Comments, ReturnTo, FieldName, KeyID)
		SELECT 'UPDATE', GETDATE(), DetailStepID, Approver, [Status],
			ApprovalLimit, ApproverOptional, WFProcessStepID,
			Notes, UniqueAttchID, Comments, ReturnTo, 'Comments', KeyID
		FROM INSERTED	
	end	
	
	if update(ReturnTo)
	begin
   		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		select 'vWFProcessDetailApprover', 'DetailStepID: ' + cast(i.DetailStepID as varchar) + ' Approver: ' + i.Approver, null, 'C', 'ReturnTo', d.ReturnTo, i.ReturnTo, getdate(), SUSER_SNAME()
   		from inserted i join deleted d on i.DetailStepID = d.DetailStepID and i.Approver = d.Approver
   		
   		INSERT dbo.vWFProcessDetailApproverHistory([Action], [DateTime], DetailStepID, Approver, [Status],
			ApprovalLimit, ApproverOptional, WFProcessStepID,
			Notes, UniqueAttchID, Comments, ReturnTo, FieldName, KeyID)
		SELECT 'UPDATE', GETDATE(), DetailStepID, Approver, [Status],
			ApprovalLimit, ApproverOptional,  WFProcessStepID,
			Notes, UniqueAttchID, Comments, ReturnTo, 'ReturnTo', KeyID
		FROM INSERTED
	end
	
	
	
end try	


begin catch

   	select @errmsg = @errmsg + ' - cannot update WF Process Detail Approver!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
end catch   
   
  
 








GO
ALTER TABLE [dbo].[vWFProcessDetailApprover] ADD CONSTRAINT [PK_vWFProcessDetailApprover] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [IX_vWFProcessDetailApprover_Approver] ON [dbo].[vWFProcessDetailApprover] ([DetailStepID], [Approver]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vWFProcessDetailApprover] WITH NOCHECK ADD CONSTRAINT [FK_vWFProcessDetailApprover_vWFProcessDetailStep] FOREIGN KEY ([DetailStepID]) REFERENCES [dbo].[vWFProcessDetailStep] ([KeyID])
GO
