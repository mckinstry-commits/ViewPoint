CREATE TABLE [dbo].[vPRAllowanceRuleSet]
(
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[PRCo] [dbo].[bCompany] NOT NULL,
[AllowanceRulesetName] [varchar] (16) COLLATE Latin1_General_BIN NOT NULL,
[AllowanceRulesetDesc] [dbo].[bDesc] NULL,
[ThresholdPeriod] [tinyint] NOT NULL CONSTRAINT [DF_vPRAllowanceRuleSet_ThresholdPeriod] DEFAULT ((2)),
[Notes] [dbo].[bNotes] NULL,
[UniqueAttchID] [uniqueidentifier] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtPRAllowanceRuleSetd] ON [dbo].[vPRAllowanceRuleSet] FOR DELETE AS

/*-----------------------------------------------------------------
* Created:		KK  11/06/2012 - B-11658
* Modified:		
*
*	This trigger validates deletions to vPRAllowanceRuleSet
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
				SELECT  'vPRAllowanceRuleSet',	
						'AllowanceRulesetName:' + CONVERT(varchar(16),d.AllowanceRulesetName),
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
CREATE TRIGGER [dbo].[vtPRAllowanceRuleSeti] ON [dbo].[vPRAllowanceRuleSet] FOR INSERT AS
/*-----------------------------------------------------------------
* Created:		KK  11/06/2012 - B-11658
* Modified:		
*
*	This trigger validates insertions to vPRAllowanceRuleSet
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
				SELECT  'vPRAllowanceRuleSet',	
						'AllowanceRulesetName:' + CONVERT(varchar(16),i.AllowanceRulesetName),
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
CREATE TRIGGER [dbo].[vtPRAllowanceRuleSetu] ON [dbo].[vPRAllowanceRuleSet] FOR UPDATE AS
/*-----------------------------------------------------------------
* Created:		KK  11/06/2012 - B-11658
* Modified:		DAN SO 12/03/2012 - B-11891 - add ThresholdPeriod column
*
*	This trigger validates updates to vPRAllowanceRuleSet
*
*	Adds HQ Master Audit entry.
*/-----------------------------------------------------------------

IF @@ROWCOUNT = 0 RETURN
DECLARE @errmsg varchar(255)

/************** Record updates in HQMA *******************/
SET NOCOUNT ON

/************* Validate fields before updating ************/    
--Company and AllowanceRulesetName are Key fields and cannot update
IF UPDATE (PRCo)
BEGIN
	SELECT @errmsg = 'PR Company cannot be updated, it is a key value - cannot update PR Allowance Rule Set!'
	RAISERROR(@errmsg, 11, -1);
   	ROLLBACK TRANSACTION
   	RETURN
END

IF UPDATE(AllowanceRulesetName)
BEGIN
	SELECT @errmsg = 'AllowanceRulesetName cannot be updated, it is a key value - cannot update PR Allowance Rule Set!'
	RAISERROR(@errmsg, 11, -1);
	ROLLBACK TRANSACTION
	RETURN
END

--IF EXISTS (SELECT * FROM inserted i JOIN dbo.bPRCO a WITH(NOLOCK) ON a.PRCo = i.PRCo WHERE a.AuditAllowances = 'Y')

IF UPDATE (AllowanceRulesetDesc)
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
				   SELECT 'vPRAllowanceRuleSet',
						  'AllowanceRulesetName:' + CONVERT(varchar(16),i.AllowanceRulesetName) + ' PRCo:' + CONVERT(varchar(5),i.PRCo),
						  i.PRCo,			
						  'C', 
						  'AllowanceRulesetDesc',			
						  CONVERT(varchar(10),d.AllowanceRulesetDesc), 
						  CONVERT(varchar(10),i.AllowanceRulesetDesc),			
						  GETDATE(), 
						  SUSER_SNAME()
					 FROM inserted i
					 JOIN deleted d 
					   ON i.AllowanceRulesetName = d.AllowanceRulesetName 
					      AND i.PRCo = d.PRCo 
					WHERE i.AllowanceRulesetDesc <> d.AllowanceRulesetDesc
END

IF UPDATE (ThresholdPeriod)
BEGIN
	INSERT INTO dbo.bHQMA	
	   SELECT 'vPRAllowanceRuleSet',
			  'AllowanceRulesetName:' + CONVERT(varchar(16),i.AllowanceRulesetName) + ' PRCo:' + CONVERT(varchar(5),i.PRCo),
			  i.PRCo,			
			  'C', 
			  'ThresholdPeriod',			
			  CONVERT(varchar(10),d.ThresholdPeriod), 
			  CONVERT(varchar(10),i.ThresholdPeriod),			
			  GETDATE(), 
			  SUSER_SNAME()
		 FROM inserted i
		 JOIN deleted d 
		   ON i.AllowanceRulesetName = d.AllowanceRulesetName 
		      AND i.PRCo = d.PRCo 
		WHERE i.ThresholdPeriod <> d.ThresholdPeriod
END

RETURN

 



GO
ALTER TABLE [dbo].[vPRAllowanceRuleSet] ADD CONSTRAINT [PK_vPRAllowanceRuleSet] PRIMARY KEY CLUSTERED  ([PRCo], [AllowanceRulesetName]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_vPRAllowanceRuleSet_KeyID] ON [dbo].[vPRAllowanceRuleSet] ([KeyID]) ON [PRIMARY]
GO
