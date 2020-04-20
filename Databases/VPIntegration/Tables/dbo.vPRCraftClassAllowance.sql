CREATE TABLE [dbo].[vPRCraftClassAllowance]
(
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[PRCo] [dbo].[bCompany] NOT NULL,
[Craft] [dbo].[bCraft] NOT NULL,
[Class] [dbo].[bClass] NOT NULL,
[AllowanceTypeName] [varchar] (16) COLLATE Latin1_General_BIN NOT NULL,
[EarnCode] [dbo].[bEDLCode] NOT NULL,
[AllowanceRulesetName] [varchar] (16) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtPRCraftClassAllowanced] ON [dbo].[vPRCraftClassAllowance] FOR DELETE AS

/*-----------------------------------------------------------------
* Created:		KK  11/09/2012
* Modified:		
*
*	This trigger validates deletions to vPRCraftClassAllowance
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
				SELECT  'vPRCraftClassAllowance',	
						'Craft:' + CONVERT(varchar(10),d.Craft) 
							+ ' Class:' + CONVERT(varchar(10),d.Class) 
							+ ' AllowanceTypeName:' + CONVERT(varchar(16),d.AllowanceTypeName),
						d.PRCo,			
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
CREATE TRIGGER [dbo].[vtPRCraftClassAllowancei] ON [dbo].[vPRCraftClassAllowance] FOR INSERT AS
/*-----------------------------------------------------------------
* Created:		KK  11/09/2012
* Modified:		
*
*	This trigger validates insertions to vPRCraftClassAllowance
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
				SELECT  'vPRCraftClassAllowance',	
						'Craft:' + CONVERT(varchar(10),i.Craft) 
							+ ' Class:' + CONVERT(varchar(10),i.Class) 
							+ ' AllowanceTypeName:' + CONVERT(varchar(16),i.AllowanceTypeName),
						i.PRCo,			
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
CREATE TRIGGER [dbo].[vtPRCraftClassAllowanceu] ON [dbo].[vPRCraftClassAllowance] FOR UPDATE AS
/*-----------------------------------------------------------------
* Created:		KK  11/09/2012
* Modified:		
*
*	This trigger validates updates to vPRCraftClassAllowance
*
*	Adds HQ Master Audit entry.
*/-----------------------------------------------------------------

IF @@ROWCOUNT = 0 RETURN
DECLARE @errmsg varchar(255)

/************** Record updates in HQMA *******************/
SET NOCOUNT ON

/************* Validate fields before updating ************/    
--Company, Craft, Class and AllowanceTypeName are Key fields and cannot update
IF UPDATE (PRCo)
BEGIN
	SELECT @errmsg = 'PR Company cannot be updated, it is a key value - cannot update PR Craft Class Allowance!'
	RAISERROR(@errmsg, 11, -1);
   	ROLLBACK TRANSACTION
   	RETURN
END

IF UPDATE(Craft)
BEGIN
	SELECT @errmsg = 'Craft cannot be updated, it is a key value - cannot update PR Craft Class Allowance!'
	RAISERROR(@errmsg, 11, -1);
	ROLLBACK TRANSACTION
	RETURN
END

IF UPDATE(Class)
BEGIN
	SELECT @errmsg = 'Class cannot be updated, it is a key value - cannot update PR Craft Class Allowance!'
	RAISERROR(@errmsg, 11, -1);
	ROLLBACK TRANSACTION
	RETURN
END

IF UPDATE(AllowanceTypeName)
BEGIN
	SELECT @errmsg = 'AllowanceTypeName cannot be updated, it is a key value - cannot update PR Craft Class Allowance!'
	RAISERROR(@errmsg, 11, -1);
	ROLLBACK TRANSACTION
	RETURN
END

--IF EXISTS (SELECT * FROM inserted i JOIN dbo.bPRCO a WITH(NOLOCK) ON a.PRCo = i.PRCo WHERE a.AuditAllowances = 'Y')
IF UPDATE (EarnCode)
BEGIN
	INSERT INTO dbo.bHQMA
		SELECT  'vPRCraftClassAllowance',
			    'Craft:' + CONVERT(varchar(10),i.Craft)
					+ ' Class:' + CONVERT(varchar(10),i.Class)
					+ ' AllowanceTypeName:' + CONVERT(varchar(16),i.AllowanceTypeName),
				i.PRCo, 
				'C', 
				'EarnCode',			
				CONVERT(varchar(5),d.EarnCode), 
				CONVERT(varchar(5),i.EarnCode),			
				GETDATE(), 
				SUSER_SNAME()
		   FROM inserted i
		   JOIN deleted d 
		     ON i.PRCo = d.PRCo
				AND i.Craft = d.Craft 
				AND i.Class = d.Class
				AND i.AllowanceTypeName = d.AllowanceTypeName 
		  WHERE i.EarnCode <> d.EarnCode
END 

IF UPDATE (AllowanceRulesetName)
BEGIN
	INSERT INTO dbo.bHQMA
		SELECT  'vPRCraftClassAllowance',
			    'Craft:' + CONVERT(varchar(10),i.Craft)
					+ ' Class:' + CONVERT(varchar(10),i.Class)
					+ ' AllowanceTypeName:' + CONVERT(varchar(16),i.AllowanceTypeName),
				i.PRCo, 
				'C', 
				'AllowanceRulesetName',			
				CONVERT(varchar(16),d.AllowanceRulesetName), 
				CONVERT(varchar(16),i.AllowanceRulesetName),			
				GETDATE(), 
				SUSER_SNAME()
		   FROM inserted i
		   JOIN deleted d 
		     ON i.PRCo = d.PRCo
				AND i.Craft = d.Craft 
				AND i.Class = d.Class
				AND i.AllowanceTypeName = d.AllowanceTypeName 
		  WHERE i.AllowanceRulesetName <> d.AllowanceRulesetName
END 

RETURN

 



GO
ALTER TABLE [dbo].[vPRCraftClassAllowance] ADD CONSTRAINT [PK_vPRCraftClassAllowance] PRIMARY KEY CLUSTERED  ([PRCo], [Craft], [Class], [AllowanceTypeName]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_vPRCraftClassAllowance_AllowanceRulesetName] ON [dbo].[vPRCraftClassAllowance] ([AllowanceRulesetName]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_vPRCraftClassAllowance_KeyID] ON [dbo].[vPRCraftClassAllowance] ([KeyID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPRCraftClassAllowance] WITH NOCHECK ADD CONSTRAINT [FK_vPRCraftClassAllowance_vPRAllowanceType] FOREIGN KEY ([AllowanceTypeName]) REFERENCES [dbo].[vPRAllowanceType] ([AllowanceTypeName])
GO
ALTER TABLE [dbo].[vPRCraftClassAllowance] WITH NOCHECK ADD CONSTRAINT [FK_vPRCraftClassAllowance_vPRAllowanceRuleSet] FOREIGN KEY ([PRCo], [AllowanceRulesetName]) REFERENCES [dbo].[vPRAllowanceRuleSet] ([PRCo], [AllowanceRulesetName])
GO
ALTER TABLE [dbo].[vPRCraftClassAllowance] WITH NOCHECK ADD CONSTRAINT [FK_vPRCraftClassAllowance_bPRCC] FOREIGN KEY ([PRCo], [Craft], [Class]) REFERENCES [dbo].[bPRCC] ([PRCo], [Craft], [Class])
GO
