CREATE TABLE [dbo].[vINLocationApprovalProcess]
(
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[INCo] [dbo].[bCompany] NOT NULL,
[Loc] [dbo].[bLoc] NOT NULL,
[DocType] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Process] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[Active] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vINLocationApprovalProcess_Active] DEFAULT ('Y'),
[Notes] [dbo].[bNotes] NULL,
[UniqueAttchID] [uniqueidentifier] NULL
) ON [PRIMARY]
ALTER TABLE [dbo].[vINLocationApprovalProcess] WITH NOCHECK ADD
CONSTRAINT [FK_vINLocationApprovalProcess_bINLM_Loc] FOREIGN KEY ([INCo], [Loc]) REFERENCES [dbo].[bINLM] ([INCo], [Loc])
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


 
CREATE TRIGGER [dbo].[vtINLocationApprovalProcessd] on [dbo].[vINLocationApprovalProcess] for DELETE as
/*----------------------------------------------------------
* Created By:	Dan So 3/27/2012 - B-08870 - POWF - Assign Inventory Location specific PO/Req process (Audit Only)
* Modified By:
*
*
*/---------------------------------------------------------
	DECLARE @errmsg VARCHAR(255), @numrows INT

	SET @numrows = @@rowcount
	SET NOCOUNT ON
	IF @numrows = 0 RETURN

	BEGIN TRY

		--------------
		-- AUDITING --
		--------------
		INSERT  dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		SELECT  'vINLocationApprovalProcess', 
				'INCo: ' + CAST(d.INCo AS VARCHAR(3)) + ' Loc: ' + d.Loc + ' DocType: ' + d.DocType + 'Process: ' + d.Process, 
				d.INCo, 'D', NULL, NULL, NULL, GETDATE(), SUSER_SNAME()
		  FROM  DELETED d
		
	END TRY	

	BEGIN CATCH

		SET @errmsg = @errmsg + ' - cannot delete IN Location Approval Process!'
   		RAISERROR(@errmsg, 11, -1);
   		ROLLBACK TRANSACTION
	   	
	END CATCH   	
   
   
   
  
 










GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

 
 
CREATE trigger [dbo].[vtINLocationApprovalProcessi] on [dbo].[vINLocationApprovalProcess] for INSERT as
/*----------------------------------------------------------
* Created By:	Dan So 3/27/2012 - B-08870 - POWF - Assign Inventory Location specific PO/Req process (Audit Only)
* Modified By:
*
*
*/---------------------------------------------------------
	DECLARE @errmsg VARCHAR(255), @numrows INT

	SET @numrows = @@rowcount
	SET NOCOUNT ON
	IF @numrows = 0 RETURN

	BEGIN TRY

		--------------
		-- AUDITING --
		--------------
		INSERT  dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		SELECT  'vINLocationApprovalProcess', 
				'INCo: ' + CAST(i.INCo AS VARCHAR(3)) + ' Loc: ' + i.Loc + ' DocType: ' + i.DocType + 'Process: ' + i.Process, 
				i.INCo, 'A', NULL, NULL, NULL, GETDATE(), SUSER_SNAME()
		  FROM  INSERTED i
		
	END TRY	

	BEGIN CATCH

		SET @errmsg = @errmsg + ' - cannot insert IN Location Approval Process!'
   		RAISERROR(@errmsg, 11, -1);
   		ROLLBACK TRANSACTION
	   	
	END CATCH   	
   









GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE TRIGGER [dbo].[vtINLocationApprovalProcessu] on [dbo].[vINLocationApprovalProcess] for UPDATE as
/*----------------------------------------------------------
* Created By:	Dan So 3/27/2012 - B-08870 - POWF - Assign Inventory Location specific PO/Req process (Audit Only)
* Modified By:
*
*
*/---------------------------------------------------------
	DECLARE	@numrows INT, @validcnt INT, @nullcnt INT, @hqco bCompany, 
			@name VARCHAR(60), @oldname VARCHAR(60), @errmsg VARCHAR(255)

	SET @numrows = @@rowcount
	SET NOCOUNT ON
	IF @numrows = 0 RETURN

	BEGIN TRY


		--------------
		-- AUDITING --
		--------------
		IF UPDATE (Process)
			BEGIN
   			    INSERT  dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
				SELECT  'vINLocationApprovalProcess', 
						'INCo: ' + CAST(i.INCo AS VARCHAR(3)) + ' Loc: ' + i.Loc + ' DocType: ' + i.DocType + 'Process: ' + i.Process, 
						i.INCo, 'C', 'Process', d.Process, i.Process, GETDATE(), SUSER_SNAME()	
   	   			  FROM	INSERTED i 
   	   			  JOIN	DELETED d ON i.INCo = d.INCo AND i.Loc = d.Loc AND i.DocType = d.DocType
   			     WHERE	ISNULL(i.Process,'') <> ISNULL(d.Process,'')	
			END
		
		IF UPDATE(Active)
			BEGIN
   			    INSERT  dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
				SELECT  'vINLocationApprovalProcess', 
						'INCo: ' + CAST(i.INCo AS VARCHAR(3)) + ' Loc: ' + i.Loc + ' DocType: ' + i.DocType + 'Process: ' + i.Process, 
						i.INCo, 'C', 'Active', d.Active, i.Active, GETDATE(), SUSER_SNAME()	
   	   			  FROM	INSERTED i 
   	   			  JOIN	DELETED d ON i.INCo = d.INCo AND i.Loc = d.Loc AND i.DocType = d.DocType
   			     WHERE	ISNULL(i.Active,'') <> ISNULL(d.Active,'')
			END
	
	END TRY	

	BEGIN CATCH

		SET @errmsg = @errmsg + ' - cannot update IN Location Approval Process!'
   		RAISERROR(@errmsg, 11, -1);
   		ROLLBACK TRANSACTION
	   	
	END CATCH  
   
  
 










GO
ALTER TABLE [dbo].[vINLocationApprovalProcess] ADD CONSTRAINT [PK_vINLocationApprovalProcess] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [IX_vINLocationApprovalProcess_DocType] ON [dbo].[vINLocationApprovalProcess] ([INCo], [Loc], [DocType]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_vINLocationApprovalProcess_ProcessOnly] ON [dbo].[vINLocationApprovalProcess] ([Process]) ON [PRIMARY]
GO

ALTER TABLE [dbo].[vINLocationApprovalProcess] WITH NOCHECK ADD CONSTRAINT [FK_vINLocationApprovalProcess_vWFProcess_Process] FOREIGN KEY ([Process]) REFERENCES [dbo].[vWFProcess] ([Process])
GO
