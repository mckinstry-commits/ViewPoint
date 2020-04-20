CREATE TABLE [dbo].[vPRCraftTemplateAllowance]
(
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[PRCo] [dbo].[bCompany] NOT NULL,
[Craft] [dbo].[bCraft] NOT NULL,
[Template] [smallint] NOT NULL,
[AllowanceTypeName] [varchar] (16) COLLATE Latin1_General_BIN NOT NULL,
[EarnCode] [dbo].[bEDLCode] NOT NULL,
[AllowanceRulesetName] [varchar] (16) COLLATE Latin1_General_BIN NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[ShiftRateOverride] [tinyint] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtPRCraftTemplateAllowanced] ON [dbo].[vPRCraftTemplateAllowance] FOR DELETE AS

/*-----------------------------------------------------------------
* Created:		KK  11/09/2012
* Modified:		
*
*	This trigger validates deletions to vPRCraftTemplateAllowance
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
				SELECT  'vPRCraftTemplateAllowance',	
						'Craft:' + CONVERT(varchar(10),d.Craft) 
							+ ' Template:' + CONVERT(varchar(4),d.Template)
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
CREATE TRIGGER [dbo].[vtPRCraftTemplateAllowancei] ON [dbo].[vPRCraftTemplateAllowance] FOR INSERT AS
/*-----------------------------------------------------------------
* Created:		KK  11/09/2012
* Modified:		
*
*	This trigger validates insertions to vPRCraftTemplateAllowance
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
				SELECT  'vPRCraftTemplateAllowance',	
						'Craft:' + CONVERT(varchar(10),i.Craft) 
							+ ' Template:' + CONVERT(varchar(4),i.Template)
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
CREATE TRIGGER [dbo].[vtPRCraftTemplateAllowanceu] ON [dbo].[vPRCraftTemplateAllowance] FOR UPDATE AS
/*-----------------------------------------------------------------
* Created:		KK  11/09/2012
* Modified:		KK  04/29/2013 TFS-46570 Added ShiftRateOverride column to vPRCraftTemplateAllowance
*
*	This trigger validates updates to vPRCraftTemplateAllowance
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
	SELECT @errmsg = 'PR Company cannot be updated, it is a key value - cannot update PR Craft Template Allowance!'
	RAISERROR(@errmsg, 11, -1);
   	ROLLBACK TRANSACTION
   	RETURN
END

IF UPDATE(Craft)
BEGIN
	SELECT @errmsg = 'Craft cannot be updated, it is a key value - cannot update PR Craft Template Allowance!'
	RAISERROR(@errmsg, 11, -1);
	ROLLBACK TRANSACTION
	RETURN
END

IF UPDATE(Template)
BEGIN
	SELECT @errmsg = 'Template cannot be updated, it is a key value - cannot update PR Craft Template Allowance!'
	RAISERROR(@errmsg, 11, -1);
	ROLLBACK TRANSACTION
	RETURN
END

IF UPDATE(AllowanceTypeName)
BEGIN
	SELECT @errmsg = 'AllowanceTypeName cannot be updated, it is a key value - cannot update PR Craft Template Allowance!'
	RAISERROR(@errmsg, 11, -1);
	ROLLBACK TRANSACTION
	RETURN
END

--IF EXISTS (SELECT * FROM inserted i JOIN dbo.bPRCO a WITH(NOLOCK) ON a.PRCo = i.PRCo WHERE a.AuditAllowances = 'Y')
IF UPDATE (EarnCode)
BEGIN
	INSERT INTO dbo.bHQMA
		SELECT  'vPRCraftTemplateAllowance',
			    'Craft:' + CONVERT(varchar(10),i.Craft)
					+ ' Template:' + CONVERT(varchar(4),i.Template)
					+ ' AllowanceTypeName:' + CONVERT(varchar(16),i.AllowanceTypeName),
				i.PRCo, 
				'C', 
				'EarnCode',			
				CONVERT(varchar(2),d.EarnCode), 
				CONVERT(varchar(2),i.EarnCode),			
				GETDATE(), 
				SUSER_SNAME()
		   FROM inserted i
		   JOIN deleted d 
		     ON i.PRCo = d.PRCo
				AND i.Craft = d.Craft 
				AND i.Template = d.Template
				AND i.AllowanceTypeName = d.AllowanceTypeName 
		  WHERE i.EarnCode <> d.EarnCode
END 

IF UPDATE (AllowanceRulesetName)
BEGIN
	INSERT INTO dbo.bHQMA
		SELECT  'vPRCraftTemplateAllowance',
			    'Craft:' + CONVERT(varchar(10),i.Craft)
					+ ' Template:' + CONVERT(varchar(4),i.Template)
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
				AND i.Template = d.Template
				AND i.AllowanceTypeName = d.AllowanceTypeName 
		  WHERE i.AllowanceRulesetName <> d.AllowanceRulesetName
END 

IF UPDATE (ShiftRateOverride)
BEGIN
	INSERT INTO dbo.bHQMA
		SELECT  'vPRCraftTemplateAllowance',
			    'Craft:' + CONVERT(varchar(10),i.Craft)
					+ ' Template:' + CONVERT(varchar(4),i.Template)
					+ ' AllowanceTypeName:' + CONVERT(varchar(16),i.AllowanceTypeName),
				i.PRCo, 
				'C', 
				'ShiftRateOverride',			
				CONVERT(varchar(16),d.ShiftRateOverride), 
				CONVERT(varchar(16),i.ShiftRateOverride),			
				GETDATE(), 
				SUSER_SNAME()
		   FROM inserted i
		   JOIN deleted d 
		     ON i.PRCo = d.PRCo
				AND i.Craft = d.Craft 
				AND i.Template = d.Template
				AND i.AllowanceTypeName = d.AllowanceTypeName 
		  WHERE i.ShiftRateOverride <> d.ShiftRateOverride
END 

RETURN

 



GO
ALTER TABLE [dbo].[vPRCraftTemplateAllowance] ADD CONSTRAINT [PK_vPRCraftTemplateAllowance] PRIMARY KEY CLUSTERED  ([PRCo], [Craft], [Template], [AllowanceTypeName]) WITH (FILLFACTOR=80) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_vPRCraftTemplateAllowance_AllowanceRulesetName] ON [dbo].[vPRCraftTemplateAllowance] ([AllowanceRulesetName]) WITH (FILLFACTOR=80) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_vPRCraftTemplateAllowance_KeyID] ON [dbo].[vPRCraftTemplateAllowance] ([KeyID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPRCraftTemplateAllowance] WITH NOCHECK ADD CONSTRAINT [FK_vPRCraftTemplateAllowance_vPRAllowanceTypes] FOREIGN KEY ([AllowanceTypeName]) REFERENCES [dbo].[vPRAllowanceType] ([AllowanceTypeName])
GO
ALTER TABLE [dbo].[vPRCraftTemplateAllowance] WITH NOCHECK ADD CONSTRAINT [FK_vPRCraftTemplateAllowance_vPRAllowanceRuleSet] FOREIGN KEY ([PRCo], [AllowanceRulesetName]) REFERENCES [dbo].[vPRAllowanceRuleSet] ([PRCo], [AllowanceRulesetName])
GO
ALTER TABLE [dbo].[vPRCraftTemplateAllowance] WITH NOCHECK ADD CONSTRAINT [FK_vPRCraftTemplateAllowance_bPRCT] FOREIGN KEY ([PRCo], [Craft], [Template]) REFERENCES [dbo].[bPRCT] ([PRCo], [Craft], [Template])
GO
ALTER TABLE [dbo].[vPRCraftTemplateAllowance] NOCHECK CONSTRAINT [FK_vPRCraftTemplateAllowance_vPRAllowanceTypes]
GO
ALTER TABLE [dbo].[vPRCraftTemplateAllowance] NOCHECK CONSTRAINT [FK_vPRCraftTemplateAllowance_vPRAllowanceRuleSet]
GO
ALTER TABLE [dbo].[vPRCraftTemplateAllowance] NOCHECK CONSTRAINT [FK_vPRCraftTemplateAllowance_bPRCT]
GO
