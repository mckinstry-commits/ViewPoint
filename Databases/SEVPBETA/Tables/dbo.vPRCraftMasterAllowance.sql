CREATE TABLE [dbo].[vPRCraftMasterAllowance]
(
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[PRCo] [dbo].[bCompany] NOT NULL,
[Craft] [dbo].[bCraft] NOT NULL,
[AllowanceTypeName] [varchar] (16) COLLATE Latin1_General_BIN NOT NULL,
[EarnCode] [dbo].[bEDLCode] NOT NULL,
[AllowanceRulesetName] [varchar] (16) COLLATE Latin1_General_BIN NOT NULL,
[ShiftRateOverride] [tinyint] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtPRCraftMasterAllowanced] ON [dbo].[vPRCraftMasterAllowance] FOR DELETE AS

/*-----------------------------------------------------------------
* Created:		MV  11/08/2012
* Modified:		
*
*	This trigger audits deletions to vPRCraftMasterAllowance 
*
*	Adds HQ Master Audit entry.
*/-----------------------------------------------------------------

IF @@ROWCOUNT = 0 RETURN

/************** Record deletion in HQMA *******************/
SET NOCOUNT ON
-- Do not audit records coming from processing: End Date, PR Group and Pay Seq are NULL 
INSERT INTO dbo.bHQMA  (TableName,		
						KeyString, 
						Co,				
						RecType, 
						FieldName,		
						OldValue, 
						NewValue,		
						DateTime, 
						UserName)
				SELECT  'vPRCraftMasterAllowance',	
						'Craft:' + d.Craft + ' AllowanceTypeName:' + d.AllowanceTypeName, 
						d.PRCo,			
						'D', 
						NULL,			
						NULL, 
						NULL,			
						GETDATE(), 
						SUSER_SNAME()
				FROM  deleted d
				
RETURN

 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtPRCraftMasterAllowancei] ON [dbo].[vPRCraftMasterAllowance] FOR INSERT AS

/*-----------------------------------------------------------------
* Created:  MV  11/08/2012
* Modified: 
*
*	This trigger audits insertion in vPRCraftMasterAllowance 
*	
*/-----------------------------------------------------------------

DECLARE @numrows int 
		
SELECT @numrows = @@rowcount

IF @numrows = 0 RETURN
SET NOCOUNT ON


/************* Insert HQ Master Audit Entry ***********************************/      
INSERT INTO dbo.bHQMA  (TableName,		
						KeyString, 
						Co,				
						RecType, 
						FieldName,		
						OldValue, 
						NewValue,		
						DateTime, 
						UserName)
				SELECT  'vPRCraftMasterAllowance',	
						'Craft:' + i.Craft + ' AllowanceTypeName:' + i.AllowanceTypeName, 
						i.PRCo,			
						'A', 
						NULL,			
						NULL, 
						NULL,			
						GETDATE(), 
						SUSER_SNAME()
				FROM inserted i
				
RETURN

   
   
   
   
   
   
  
GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtPRCraftMasterAllowanceu] ON [dbo].[vPRCraftMasterAllowance] FOR UPDATE AS

/*-----------------------------------------------------------------
* Created:		KK  11/08/2012
* Modified:		KK  04/29/2013 TFS-46570 Added ShiftRateOverride column to vPRCraftMasterAllowance
*
*	This trigger validates UPDATES to vPRCraftMasterAllowance 
*	
*/-----------------------------------------------------------------
    
DECLARE @errmsg varchar(255), 
		@numrows int   
SELECT @numrows = @@rowcount
IF @numrows = 0 RETURN

SET NOCOUNT ON    
    
/************* Validate fields before updating ************/    

--Company and DL Code and Employee are Key fields and cannot update
IF UPDATE(PRCo)
BEGIN
	SELECT @errmsg = 'PR Company cannot be updated, it is a key value '
	GOTO ERROR
END

IF UPDATE(Craft)
BEGIN
	SELECT @errmsg = 'Craft cannot be updated, it is a key value '
	GOTO ERROR
END

IF UPDATE(AllowanceTypeName)
BEGIN
	SELECT @errmsg = 'AllowanceTypeName cannot be updated, it is a key value '
	GOTO ERROR
END 


/************* Update HQ Master Audit entry **********************************/
IF UPDATE (EarnCode)
BEGIN
	INSERT INTO dbo.bHQMA (TableName,		
						   KeyString, 
						   Co,				
						   RecType, 
						   FieldName,		
						   OldValue, 
						   NewValue,		
						   DateTime, 
						   UserName)
	SELECT 'vPRCraftMasterAllowance',	
			'Craft:' + i.Craft + ' AllowanceTypeName:' + i.AllowanceTypeName, 
			i.PRCo,			
			'C', 
			'EarnCode',			
			d.EarnCode, 
			i.EarnCode,			
			GETDATE(), 
			SUSER_SNAME()
	FROM inserted i
		JOIN deleted d 
		ON i.PRCo = d.PRCo 
		AND i.Craft = d.Craft 
		AND i.AllowanceTypeName = d.AllowanceTypeName
	WHERE i.EarnCode <> d.EarnCode
END
		
IF UPDATE (AllowanceRulesetName)
BEGIN
	INSERT INTO dbo.bHQMA (TableName,		
						   KeyString,
						   Co,
						   RecType,
						   FieldName,
						   OldValue,
						   NewValue,
						   DateTime,
						   UserName)
	SELECT 'vPRCraftMasterAllowance',	
			'Craft:' + i.Craft + ' AllowanceTypeName:' + i.AllowanceTypeName, 
			i.PRCo,			
			'C', 
			'AllowanceRulesetName',			
			d.AllowanceRulesetName, 
			i.AllowanceRulesetName,			
			GETDATE(), 
			SUSER_SNAME()
	FROM inserted i
		JOIN deleted d 
		ON i.PRCo = d.PRCo 
		AND i.Craft = d.Craft 
		AND i.AllowanceTypeName = d.AllowanceTypeName
	WHERE i.AllowanceRulesetName <> d.AllowanceRulesetName
END
		
IF UPDATE (ShiftRateOverride)
BEGIN
	INSERT INTO dbo.bHQMA (TableName,		
						   KeyString,
						   Co,
						   RecType,
						   FieldName,
						   OldValue,
						   NewValue,
						   DateTime,
						   UserName)
	SELECT 'vPRCraftMasterAllowance',	
			'Craft:' + i.Craft + ' AllowanceTypeName:' + i.AllowanceTypeName, 
			i.PRCo,			
			'C', 
			'ShiftRateOverride',			
			d.ShiftRateOverride, 
			i.ShiftRateOverride,			
			GETDATE(), 
			SUSER_SNAME()
	FROM inserted i
		JOIN deleted d 
		ON i.PRCo = d.PRCo 
		AND i.Craft = d.Craft 
		AND i.AllowanceTypeName = d.AllowanceTypeName
	WHERE i.ShiftRateOverride <> d.ShiftRateOverride
END
     
RETURN 
ERROR:
SELECT @errmsg = ISNULL(@errmsg,'') + ' - cannot UPDATE PR Craft Master Allowance!'
	RAISERROR(@errmsg, 11, -1);
	ROLLBACK TRANSACTION
     
     
     
    
    
    
   
   
   
   
   
   
   
   
GO

ALTER TABLE [dbo].[vPRCraftMasterAllowance] ADD CONSTRAINT [PK_vPRCraftMasterAllowance] PRIMARY KEY CLUSTERED  ([PRCo], [Craft], [AllowanceTypeName]) WITH (FILLFACTOR=80) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_vPRCraftMasterAllowance_AllowanceRulesetName] ON [dbo].[vPRCraftMasterAllowance] ([AllowanceRulesetName]) WITH (FILLFACTOR=80) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_vPRCraftMasterAllowance_KeyID] ON [dbo].[vPRCraftMasterAllowance] ([KeyID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPRCraftMasterAllowance] WITH NOCHECK ADD CONSTRAINT [FK_vPRCraftMasterAllowance_vPRAllowanceTypes] FOREIGN KEY ([AllowanceTypeName]) REFERENCES [dbo].[vPRAllowanceType] ([AllowanceTypeName])
GO
ALTER TABLE [dbo].[vPRCraftMasterAllowance] WITH NOCHECK ADD CONSTRAINT [FK_vPRCraftMasterAllowance_vPRAllowanceRuleSet] FOREIGN KEY ([PRCo], [AllowanceRulesetName]) REFERENCES [dbo].[vPRAllowanceRuleSet] ([PRCo], [AllowanceRulesetName])
GO
ALTER TABLE [dbo].[vPRCraftMasterAllowance] WITH NOCHECK ADD CONSTRAINT [FK_vPRCraftMasterAllowance_bPRCM] FOREIGN KEY ([PRCo], [Craft]) REFERENCES [dbo].[bPRCM] ([PRCo], [Craft])
GO
