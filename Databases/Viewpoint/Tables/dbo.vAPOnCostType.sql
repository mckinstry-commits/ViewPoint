CREATE TABLE [dbo].[vAPOnCostType]
(
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[APCo] [dbo].[bCompany] NOT NULL,
[OnCostID] [tinyint] NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[CalcMethod] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[Rate] [dbo].[bUnitCost] NOT NULL,
[Amount] [dbo].[bDollar] NOT NULL,
[PayType] [tinyint] NOT NULL,
[ATOCategory] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[VendorGrp] [dbo].[bGroup] NOT NULL,
[OnCostVendor] [dbo].[bVendor] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[JobExpOpt] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vAPOnCostType_JobExpOpt] DEFAULT ('I'),
[CostType] [dbo].[bJCCType] NULL,
[JobExpAcct] [dbo].[bGLAcct] NULL,
[ExpAcct] [dbo].[bGLAcct] NULL,
[NonJobExpOpt] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vAPOnCostType_NonJobExpOpt] DEFAULT ('I')
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [IX_vAPOnCostType_ALL] ON [dbo].[vAPOnCostType] ([APCo], [OnCostID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[vtAPOnCostTyped] 
	ON [dbo].[vAPOnCostType] 
	FOR DELETE AS
/*-----------------------------------------------------------------
* Created:		CHS	01/05/2012		B-08282
* Modified:		
*
*	Insert trigger for PR Australian PAYG Employees
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------

SET NOCOUNT ON

/* add HQ Master Audit entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
SELECT 
	'vAPOnCostType', 
	'APCo: ' + CAST(d.APCo AS VARCHAR(10)) 
		+ ',  OnCostID: ' + CAST(d.OnCostID AS VARCHAR(10)),	
		
	d.APCo,
	'D', 
	NULL, 
	NULL, 
	NULL, 
	GETDATE(), 
	SUSER_SNAME() 
FROM DELETED d

  
RETURN
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtAPOnCostTypei] 
	ON [dbo].[vAPOnCostType] 
	FOR INSERT AS
/*-----------------------------------------------------------------
* Created:		CHS	01/05/2012		B-08282
* Modified:		CHS	02/20/2012		B-08457	
*
*	Insert trigger for PR Australian PAYG Employees
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------

SET NOCOUNT ON

/* add HQ Master Audit entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
SELECT 
	'vAPOnCostType', 
	'APCo: ' + CAST(i.APCo AS VARCHAR(10)) 
		+ ',  OnCostID: ' + CAST(i.OnCostID AS VARCHAR(10))	
		+ ',  Description: ' + ISNULL(i.Description, '')
		+ ',  CalcMethod: ' + CAST(i.CalcMethod AS VARCHAR(10))
		+ ',  Rate: ' + CAST(i.Rate AS VARCHAR(10))
		+ ',  Amount: ' + CAST(i.Amount AS VARCHAR(10))
		+ ',  PayType: ' + CAST(i.PayType AS VARCHAR(10))
		+ ',  ATOCategory: ' + CAST(ISNULL(i.ATOCategory, '') AS VARCHAR(10))
		+ ',  OnCostVendor: ' + CAST(i.OnCostVendor AS VARCHAR(10))
		+ ',  JobExpOpt: ' + i.JobExpOpt
		+ ',  CostType: ' + ISNULL(CAST(i.CostType AS VARCHAR(10)), '')
		+ ',  JobExpAcct: ' + ISNULL(CAST(i.JobExpAcct AS VARCHAR(20)), '')
		+ ',  ExpAcct: ' + ISNULL(CAST(i.ExpAcct AS VARCHAR(20)), '')
		+ ',  NonJobExpOpt: ' + i.NonJobExpOpt									
		, 			
	i.APCo,
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


CREATE TRIGGER [dbo].[vtAPOnCostTypeu] 
	ON [dbo].[vAPOnCostType] 
	FOR UPDATE AS
/*-----------------------------------------------------------------
* Created:		CHS	01/05/2012	B-08282
* Modified:		CHS	02/20/2012	B-08457		
*
*	Update trigger for PR Australian PAYG Employees
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------

SET NOCOUNT ON

/* add Description entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
SELECT 
	'vAPOnCostType', 
	'APCo: ' + CAST(i.APCo AS VARCHAR(10)) 
		+ ',  OnCostID: ' + CAST(i.OnCostID AS VARCHAR(10)), 		
	i.APCo,
	'C', 
	'Description', 
	d.Description, 
	i.Description, 
	GETDATE(), 
	SUSER_SNAME() 
FROM inserted i
	JOIN deleted d ON i.APCo = d.APCo AND i.OnCostID = d.OnCostID
WHERE ISNULL(i.Description,'') <> ISNULL(d.Description,'') 	

	
/* add CalcMethod entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
SELECT 
	'vAPOnCostType', 
	'APCo: ' + CAST(i.APCo AS VARCHAR(10)) 
		+ ',  OnCostID: ' + CAST(i.OnCostID AS VARCHAR(10)), 
	i.APCo,
	'C', 
	'CalcMethod', 
	d.CalcMethod, 
	i.CalcMethod, 
	GETDATE(), 
	SUSER_SNAME() 
FROM inserted i
	JOIN deleted d ON i.APCo = d.APCo AND i.OnCostID = d.OnCostID	
WHERE ISNULL(i.CalcMethod,'') <> ISNULL(d.CalcMethod,'') 		


/* add Rate entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
SELECT 
	'vAPOnCostType', 
	'APCo: ' + CAST(i.APCo AS VARCHAR(10)) 
		+ ',  OnCostID: ' + CAST(i.OnCostID AS VARCHAR(10)), 
	i.APCo,
	'C', 
	'Rate', 
	d.Rate, 
	i.Rate, 
	GETDATE(), 
	SUSER_SNAME() 
FROM inserted i
	JOIN deleted d ON i.APCo = d.APCo AND i.OnCostID = d.OnCostID	
WHERE ISNULL(i.Rate,'') <> ISNULL(d.Rate,'') 


/* add Amount entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
SELECT 
	'vAPOnCostType', 
	'APCo: ' + CAST(i.APCo AS VARCHAR(10)) 
		+ ',  OnCostID: ' + CAST(i.OnCostID AS VARCHAR(10)), 
	i.APCo,
	'C', 
	'Amount', 
	d.Amount, 
	i.Amount, 
	GETDATE(), 
	SUSER_SNAME() 
FROM inserted i
	JOIN deleted d ON i.APCo = d.APCo AND i.OnCostID = d.OnCostID	
WHERE ISNULL(i.Amount,'') <> ISNULL(d.Amount,'') 

  
/* add PayType entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
SELECT 
	'vAPOnCostType', 
	'APCo: ' + CAST(i.APCo AS VARCHAR(10)) 
		+ ',  OnCostID: ' + CAST(i.OnCostID AS VARCHAR(10)), 	
	i.APCo,
	'C', 
	'PayType', 
	d.PayType, 
	i.PayType, 
	GETDATE(), 
	SUSER_SNAME() 
FROM inserted i
	JOIN deleted d ON i.APCo = d.APCo AND i.OnCostID = d.OnCostID	
WHERE ISNULL(i.PayType,'') <> ISNULL(d.PayType,'')   
  

/* add ATOCategory entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
SELECT 
	'vAPOnCostType', 
	'APCo: ' + CAST(i.APCo AS VARCHAR(10)) 
		+ ',  OnCostID: ' + CAST(i.OnCostID AS VARCHAR(10)), 		
	i.APCo,
	'C', 
	'ATOCategory', 
	d.ATOCategory, 
	i.ATOCategory, 
	GETDATE(), 
	SUSER_SNAME() 
FROM inserted i
	JOIN deleted d ON i.APCo = d.APCo AND i.OnCostID = d.OnCostID	
WHERE ISNULL(i.ATOCategory,'') <> ISNULL(d.ATOCategory,'')  

 
/* add OnCostVendor entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
SELECT 
	'vAPOnCostType', 
	'APCo: ' + CAST(i.APCo AS VARCHAR(10)) 
		+ ',  OnCostID: ' + CAST(i.OnCostID AS VARCHAR(10)), 		
	i.APCo,
	'C', 
	'OnCostVendor', 
	d.OnCostVendor, 
	i.OnCostVendor, 
	GETDATE(), 
	SUSER_SNAME() 
FROM inserted i
	JOIN deleted d ON i.APCo = d.APCo AND i.OnCostID = d.OnCostID	
WHERE ISNULL(i.OnCostVendor,'') <> ISNULL(d.OnCostVendor,'')    


/* add JobExpOpt entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
SELECT 
	'vAPOnCostType', 
	'APCo: ' + CAST(i.APCo AS VARCHAR(10)) 
		+ ',  OnCostID: ' + CAST(i.OnCostID AS VARCHAR(10)), 		
	i.APCo,
	'C', 
	'JobExpOpt', 
	d.JobExpOpt, 
	i.JobExpOpt, 
	GETDATE(), 
	SUSER_SNAME() 
FROM inserted i
	JOIN deleted d ON i.APCo = d.APCo AND i.OnCostID = d.OnCostID	
WHERE ISNULL(i.JobExpOpt,'') <> ISNULL(d.JobExpOpt,'') 
   

/* add CostType entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
SELECT 
	'vAPOnCostType', 
	'APCo: ' + CAST(i.APCo AS VARCHAR(10)) 
		+ ',  OnCostID: ' + CAST(i.OnCostID AS VARCHAR(10)), 		
	i.APCo,
	'C', 
	'CostType', 
	d.CostType, 
	i.CostType, 
	GETDATE(), 
	SUSER_SNAME() 
FROM inserted i
	JOIN deleted d ON i.APCo = d.APCo AND i.OnCostID = d.OnCostID	
WHERE ISNULL(i.CostType,'') <> ISNULL(d.CostType,'')  
  

/* add JobExpAcct entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
SELECT 
	'vAPOnCostType', 
	'APCo: ' + CAST(i.APCo AS VARCHAR(10)) 
		+ ',  OnCostID: ' + CAST(i.OnCostID AS VARCHAR(10)), 		
	i.APCo,
	'C', 
	'JobExpAcct', 
	d.JobExpAcct, 
	i.JobExpAcct, 
	GETDATE(), 
	SUSER_SNAME() 
FROM inserted i
	JOIN deleted d ON i.APCo = d.APCo AND i.OnCostID = d.OnCostID	
WHERE ISNULL(i.JobExpAcct,'') <> ISNULL(d.JobExpAcct,'')    


/* add ExpAcct entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
SELECT 
	'vAPOnCostType', 
	'APCo: ' + CAST(i.APCo AS VARCHAR(10)) 
		+ ',  OnCostID: ' + CAST(i.OnCostID AS VARCHAR(10)), 		
	i.APCo,
	'C', 
	'ExpAcct', 
	d.ExpAcct, 
	i.ExpAcct, 
	GETDATE(), 
	SUSER_SNAME() 
FROM inserted i
	JOIN deleted d ON i.APCo = d.APCo AND i.OnCostID = d.OnCostID	
WHERE ISNULL(i.ExpAcct,'') <> ISNULL(d.ExpAcct,'')    


/* add NonJobExpOpt entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
SELECT 
	'vAPOnCostType', 
	'APCo: ' + CAST(i.APCo AS VARCHAR(10)) 
		+ ',  OnCostID: ' + CAST(i.OnCostID AS VARCHAR(10)), 		
	i.APCo,
	'C', 
	'NonJobExpOpt', 
	d.NonJobExpOpt, 
	i.NonJobExpOpt, 
	GETDATE(), 
	SUSER_SNAME() 
FROM inserted i
	JOIN deleted d ON i.APCo = d.APCo AND i.OnCostID = d.OnCostID	
WHERE ISNULL(i.NonJobExpOpt,'') <> ISNULL(d.NonJobExpOpt,'')    


RETURN

GO
ALTER TABLE [dbo].[vAPOnCostType] ADD CONSTRAINT [PK_vAPOnCostType] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
