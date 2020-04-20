CREATE TABLE [dbo].[bHRAG]
(
[HRCo] [dbo].[bCompany] NOT NULL,
[PTOAppvrGrp] [dbo].[bGroup] NOT NULL,
[AppvrGrpDesc] [dbo].[bDesc] NULL,
[PriAppvr] [dbo].[bHRRef] NOT NULL,
[PriNotifyYN] [dbo].[bYN] NULL,
[SecAppvr] [dbo].[bHRRef] NULL,
[SecNotifyYN] [dbo].[bYN] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*-----------------------------------------------------------------
 * Created: Dan Sochacki 03/04/2008
 *
 *	This trigger rejects deletions in bHRAG (HR Approval Group) if
 *	any of the following error conditions exist:
 *
 *	1. PTOAppvrGrp exists in bHRRM
 *
 * 	Audits updates in bHQMA
 *
 */----------------------------------------------------------------
--CREATE  TRIGGER [dbo].[btHRAGd] on [dbo].[bHRAG] for DELETE 
CREATE  TRIGGER [dbo].[btHRAGd] on [dbo].[bHRAG] for DELETE 
AS

DECLARE @numrows	int, 
		@errmsg		varchar(255)


	SELECT @numrows = @@ROWCOUNT
	IF @numrows = 0 RETURN 
 
	SET NOCOUNT ON

	--------------------------------
	-- CHECK FOR ENTRIES IN bHRRM --
	--------------------------------
	IF EXISTS(SELECT TOP 1 1 FROM deleted d JOIN dbo.bHRRM h ON d.HRCo = h.HRCo AND d.PTOAppvrGrp = h.PTOAppvrGrp)
			BEGIN
				SELECT @errmsg 'Resources are allocated to HR Approval Group '
				goto error
			END
    
    
	------------------
	-- INSERT AUDIT --
	------------------
	INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		 SELECT 'bHRAG', 
			    'HRCo: ' + ISNULL(CONVERT(CHAR(3), d.HRCo),0) + 
			    '  PTOAppvrGrp: ' + CONVERT(VARCHAR, d.PTOAppvrGrp), + 
				d.HRCo, 'D', '', NULL, NULL, getdate(), SUSER_SNAME() 
		   FROM Deleted d JOIN bHRCO h ON d.HRCo = h.HRCo
		  WHERE h.AuditPTOYN = 'Y'


RETURN
    
error:
        SELECT @errmsg = isnull(@errmsg,'') + ' - cannot delete HR Approval Group!'
        RAISERROR(@errmsg, 11, -1);
        ROLLBACK TRANSACTION

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*-----------------------------------------------------------------
 * Created: Dan Sochacki 03/04/2008
 *
 *	This trigger rejects insertion in bHRAG (HR Approval Group) if
 *	any of the following error conditions exist:
 *
 *	1. HRCo not valid
 *	2. Primay Approver not valid
 *	3. Secondary Approver not valid
 *
 * 	Audits insert in bHQMA
 *
 */----------------------------------------------------------------
--CREATE  TRIGGER [dbo].[btHRAGi] on [dbo].[bHRAG] for INSERT 
CREATE  TRIGGER [dbo].[btHRAGi] on [dbo].[bHRAG] for INSERT 
AS

DECLARE @numrows	int, 
		@validcnt	int, 
		@nullcnt	int,
		@errmsg		varchar(255)


	SELECT @numrows = @@ROWCOUNT, @validcnt = 0, @nullcnt = 0
	IF @numrows = 0 RETURN 
 
	SET NOCOUNT ON

	-------------------
	-- VALIDATE HRCO --
	-------------------
	SELECT @nullcnt = COUNT(*) FROM inserted i WHERE i.HRCo IS NULL
	SELECT @validcnt = COUNT(*) FROM dbo.bHRCO c (NOLOCK) JOIN inserted i ON c.HRCo = i.HRCo

	IF @nullcnt + @validcnt <> @numrows
		BEGIN
			SELECT @errmsg = 'Invalid HR Company #'
			GOTO error
		END

	----------------------------
	-- VALIDATE PRIMARY HRREF --
	----------------------------
	SELECT @nullcnt = count(*) FROM inserted i WHERE i.PriAppvr IS NULL
	SELECT @validcnt = count(*) FROM dbo.bHRRM r (NOLOCK) JOIN inserted i ON r.HRCo = i.HRCo AND r.HRRef = i.PriAppvr

	IF @nullcnt + @validcnt <> @numrows
		BEGIN
			SELECT @errmsg = 'Invalid Primary HR Resource'
			GOTO error
		END

	------------------------------
	-- VALIDATE SECONDARY HRREF --
	------------------------------
	SELECT @nullcnt = count(*) FROM inserted i WHERE i.SecAppvr IS NULL
	SELECT @validcnt = count(*) FROM dbo.bHRRM r (NOLOCK) JOIN inserted i ON r.HRCo = i.HRCo AND r.HRRef = i.SecAppvr

	IF @nullcnt + @validcnt <> @numrows
		BEGIN
			SELECT @errmsg = 'Invalid Secondary HR Resource'
			GOTO error
		END


	-------------------
	-- INSERT AUDITS --
	-------------------
	INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		 SELECT 'bHRAG', 
			    'HRCo: ' + CONVERT(CHAR(3), i.HRCo) + 
			    '  PTOAppvrGrp: ' + CONVERT(VARCHAR, i.PTOAppvrGrp), + 
				i.HRCo, 'A', '', NULL, NULL, getdate(), SUSER_SNAME() 
		   FROM Inserted i JOIN bHRCO h ON i.HRCo = h.HRCo
		  WHERE h.AuditPTOYN = 'Y'


RETURN
 
error:
	SELECT @errmsg = @errmsg + ' - cannot insert HR Approval Group!'
	RAISERROR(@errmsg, 11, -1);
	ROLLBACK TRANSACTION 

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*-----------------------------------------------------------------
 * Created: Dan Sochacki 03/04/2008
 *
 *	This trigger rejects updates in bHRAG (HR Approval Group) if
 *	any of the following error conditions exist:
 *
 *	1. Primay Approver not valid
 *	2. Secondary Approver not valid
 *
 * 	Audits updates in bHQMA
 *
 */----------------------------------------------------------------
--CREATE  TRIGGER [dbo].[btHRAGu] on [dbo].[bHRAG] for UPDATE 
CREATE  TRIGGER [dbo].[btHRAGu] on [dbo].[bHRAG] for UPDATE 
AS

DECLARE @numrows	int, 
		@validcnt	int, 
		@nullcnt	int,
		@errmsg		varchar(255)


	SELECT @numrows = @@ROWCOUNT, @validcnt = 0, @nullcnt = 0
	IF @numrows = 0 RETURN 
 
	SET NOCOUNT ON

	----------------------------
	-- VALIDATE PRIMARY HRREF --
	----------------------------
	SELECT @nullcnt = count(*) FROM inserted i WHERE i.PriAppvr IS NULL
	SELECT @validcnt = count(*) FROM dbo.bHRRM r (NOLOCK) JOIN inserted i ON r.HRCo = i.HRCo AND r.HRRef = i.PriAppvr

	IF @nullcnt + @validcnt <> @numrows
		BEGIN
			SELECT @errmsg = 'Invalid Primary HR Resource'
			GOTO error
		END

	------------------------------
	-- VALIDATE SECONDARY HRREF --
	------------------------------
	SELECT @nullcnt = count(*) FROM inserted i WHERE i.SecAppvr IS NULL
	SELECT @validcnt = count(*) FROM dbo.bHRRM r (NOLOCK) JOIN inserted i ON r.HRCo = i.HRCo AND r.HRRef = i.SecAppvr

	IF @nullcnt + @validcnt <> @numrows
		BEGIN
			SELECT @errmsg = 'Invalid Secondary HR Resource'
			GOTO error
		END


	-------------------
	-- INSERT AUDITS --
	-------------------
	IF UPDATE(PriAppvr)
		BEGIN
   			INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   				 SELECT 'bHRAG', 
				   	    'HRCo: ' + ISNULL(CONVERT(CHAR(3), i.HRCo),0) + 
				 	    '  PTOAppvrGrp: ' + CONVERT(VARCHAR, i.PTOAppvrGrp), +
						i.HRCo, 'C', 'PriAppvr', d.PriAppvr, i.PriAppvr, getdate(), SUSER_SNAME() 
   				   FROM inserted i
   				   JOIN deleted d ON i.HRCo = d.HRCo
                    AND i.PTOAppvrGrp = d.PTOAppvrGrp
		           JOIN bHRCO h ON i.HRCo = h.HRCo
                    AND h.AuditPTOYN = 'Y'
                  WHERE i.PriAppvr <> d.PriAppvr
		END

	IF UPDATE(SecAppvr)
		BEGIN
   			INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   				 SELECT 'bHRAG', 
				   	    'HRCo: ' + ISNULL(CONVERT(CHAR(3), i.HRCo),0) + 
				 	    '  PTOAppvrGrp: ' + CONVERT(VARCHAR, i.PTOAppvrGrp), +
						i.HRCo, 'C', 'SecAppvr', d.SecAppvr, i.SecAppvr, getdate(), SUSER_SNAME() 
   				   FROM inserted i
   				   JOIN deleted d ON i.HRCo = d.HRCo
                    AND i.PTOAppvrGrp = d.PTOAppvrGrp
		           JOIN bHRCO h ON i.HRCo = h.HRCo
                    AND h.AuditPTOYN = 'Y'
                  WHERE i.SecAppvr <> d.SecAppvr
		END


RETURN
  
error:
	SELECT @errmsg = isnull(@errmsg,'') + ' - cannot update HR Approval Group!'
    RAISERROR(@errmsg, 11, -1);
    ROLLBACK TRANSACTION

GO
CREATE UNIQUE CLUSTERED INDEX [biHRAG] ON [dbo].[bHRAG] ([HRCo], [PTOAppvrGrp]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHRAG] ([KeyID]) ON [PRIMARY]
GO
