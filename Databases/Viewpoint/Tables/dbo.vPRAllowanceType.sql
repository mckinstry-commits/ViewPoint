CREATE TABLE [dbo].[vPRAllowanceType]
(
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[AllowanceTypeName] [varchar] (16) COLLATE Latin1_General_BIN NOT NULL,
[AllowanceDescription] [dbo].[bDesc] NULL,
[TableName] [varchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[Notes] [dbo].[bNotes] NULL
) ON [PRIMARY]
ALTER TABLE [dbo].[vPRAllowanceType] ADD 
CONSTRAINT [PK_vPRAllowanceType] PRIMARY KEY CLUSTERED  ([AllowanceTypeName]) WITH (FILLFACTOR=80) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtPRAllowanceTyped] ON [dbo].[vPRAllowanceType] FOR DELETE AS

/*-----------------------------------------------------------------
* Created:		KK  11/06/2012 - B-11658
* Modified:		
*
*	This trigger validates deletions to vPRAllowanceType
*
*	Adds HQ Master Audit entry.
*/-----------------------------------------------------------------

IF @@ROWCOUNT = 0 RETURN
/************** Record deletion in HQMA *******************/
SET NOCOUNT ON
INSERT INTO dbo.bHQMA  (TableName,		
						KeyString, 
						Co,				
						RecType, 
						FieldName,		
						OldValue, 
						NewValue,		
						DateTime, 
						UserName)
				SELECT  'vPRAllowanceType',	
						'AllowanceTypeName:' + CONVERT(varchar(16),d.AllowanceTypeName)
						 + ' AllowanceDescription:' + CONVERT(varchar(30),dbo.vfToString(d.AllowanceDescription))
						 + ' TableName:' + CONVERT(varchar(128),d.TableName),
						NULL,			
						'D', 
						NULL,			
						NULL, 
						NULL,			
						GETDATE(), 
						SUSER_SNAME()
				FROM	deleted d
RETURN

 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtPRAllowanceTypesi] ON [dbo].[vPRAllowanceType] FOR INSERT AS
/*-----------------------------------------------------------------
* Created:		KK  11/06/2012 - B-11658
* Modified:		
*
*	This trigger validates insertions to vPRAllowanceType
*
*	Adds HQ Master Audit entry.
*/-----------------------------------------------------------------

IF @@ROWCOUNT = 0 RETURN

/************** Record insertions in HQMA *******************/
SET NOCOUNT ON
INSERT INTO dbo.bHQMA  (TableName,		
						KeyString, 
						Co,				
						RecType, 
						FieldName,		
						OldValue, 
						NewValue,		
						DateTime, 
						UserName)
				SELECT  'vPRAllowanceType',	
						'AllowanceTypeName:' + CONVERT(varchar(16),i.AllowanceTypeName)
						 + ' AllowanceDescription:' + CONVERT(varchar(30),dbo.vfToString(i.AllowanceDescription))
						 + ' TableName:' + CONVERT(varchar(128),i.TableName),
						NULL,			
						'A', 
						NULL,			
						NULL, 
						NULL,			
						GETDATE(), 
						SUSER_SNAME()
				FROM	inserted i
RETURN 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtPRAllowanceTypeu] ON [dbo].[vPRAllowanceType] FOR UPDATE AS
/*-----------------------------------------------------------------
* Created:		KK  11/06/2012 - B-11658
* Modified:		
*
*	This trigger validates updates to vPRAllowanceType
*
*	Adds HQ Master Audit entry.
*/-----------------------------------------------------------------

IF @@ROWCOUNT = 0 RETURN
DECLARE @errmsg varchar(255)

/************** Record updates in HQMA *******************/
SET NOCOUNT ON

--Company and DL Code and Employee are Key fields and cannot update
IF UPDATE (AllowanceTypeName)
BEGIN
	SELECT @errmsg = 'PR AllowanceTypeName cannot be updated, it is a key value - cannot update PR Allowance Type!'
	RAISERROR(@errmsg, 11, -1);
   	ROLLBACK TRANSACTION
   	RETURN
END

--IF EXISTS (SELECT * FROM inserted i JOIN dbo.bPRCO a WITH(NOLOCK) ON a.PRCo = i.PRCo WHERE a.AuditAllowances = 'Y')

IF UPDATE (TableName)
BEGIN
	INSERT INTO dbo.bHQMA
				   SELECT 'vPRAllowanceType',
						  'AllowanceTypeName:' + CONVERT(varchar(16),i.AllowanceTypeName),
						  NULL,			
						  'C', 
						  'TableName',			
						  CONVERT(varchar(128),d.TableName), 
						  CONVERT(varchar(128),i.TableName),			
						  GETDATE(), 
						  SUSER_SNAME()
					 FROM inserted i
					 JOIN deleted d 
					   ON i.AllowanceTypeName = d.AllowanceTypeName 
					WHERE i.TableName <> d.TableName
END

RETURN
 



GO

CREATE UNIQUE NONCLUSTERED INDEX [IX_vPRAllowanceType_KeyID] ON [dbo].[vPRAllowanceType] ([KeyID]) ON [PRIMARY]
GO
