CREATE TABLE [dbo].[vAPVendorMasterOnCost]
(
[APCo] [dbo].[bCompany] NOT NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Vendor] [dbo].[bVendor] NOT NULL,
[OnCostID] [tinyint] NOT NULL,
[CalcMethod] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[Rate] [dbo].[bUnitCost] NULL,
[Amount] [dbo].[bDollar] NULL,
[PayType] [tinyint] NULL,
[OnCostVendor] [dbo].[bVendor] NULL,
[ATOCategory] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[SchemeID] [smallint] NULL,
[MemberShipNumber] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [IX_vAPVendorMasterOnCost_ALL] ON [dbo].[vAPVendorMasterOnCost] ([APCo], [VendorGroup], [Vendor], [OnCostID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[vtAPVendorMasterOnCostd] 
	ON [dbo].[vAPVendorMasterOnCost] 
	FOR DELETE AS
/*-----------------------------------------------------------------
* Created:		CHS	01/19/2012		B-08285
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
	'vAPVendorMasterOnCost', 
	'VendorGroup: ' + CAST(d.VendorGroup AS VARCHAR(10)) 
		+ '   Vendor: ' + CAST(d.Vendor AS VARCHAR(10)) 
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


CREATE TRIGGER [dbo].[vtAPVendorMasterOnCosti] 
	ON [dbo].[vAPVendorMasterOnCost] 
	FOR INSERT AS
/*-----------------------------------------------------------------
* Created:		CHS	01/19/2012		B-08285
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
	'vAPVendorMasterOnCost', 
	'VendorGroup: ' + CAST(i.VendorGroup AS VARCHAR(10)) 
		+ '   Vendor: ' + CAST(i.Vendor AS VARCHAR(10)) 
		+ ',  OnCostID: ' + CAST(i.OnCostID AS VARCHAR(10)),	
		
	i.APCo,
	'A', 
	NULL, 
	NULL, 
	NULL, 
	GETDATE(), 
	SUSER_SNAME() 
FROM INSERTED i

  
RETURN
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[vtAPVendorMasterOnCostu] 
	ON [dbo].[vAPVendorMasterOnCost] 
	FOR UPDATE AS
/*-----------------------------------------------------------------
* Created:		CHS	01/05/2012	B-08282
* Modified:		
*
*	Update trigger for PR Australian PAYG Employees
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------

SET NOCOUNT ON

/* add CalcMethod entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
SELECT 
	'vAPVendorMasterOnCost', 
	'VendorGroup: ' + CAST(d.VendorGroup AS VARCHAR(10)) 
		+ '   Vendor: ' + CAST(d.Vendor AS VARCHAR(10)) 
		+ ',  OnCostID: ' + CAST(d.OnCostID AS VARCHAR(10)),		
	i.APCo,
	'C', 
	'CalcMethod', 
	d.CalcMethod, 
	i.CalcMethod, 
	GETDATE(), 
	SUSER_SNAME() 
FROM inserted i
	JOIN deleted d ON i.VendorGroup = d.VendorGroup AND i.Vendor = d.Vendor
WHERE ISNULL(i.CalcMethod,'') <> ISNULL(d.CalcMethod,'') 		


/* add Rate entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
SELECT 
	'vAPVendorMasterOnCost', 
	'VendorGroup: ' + CAST(d.VendorGroup AS VARCHAR(10)) 
		+ '   Vendor: ' + CAST(d.Vendor AS VARCHAR(10)) 
		+ ',  OnCostID: ' + CAST(d.OnCostID AS VARCHAR(10)),		
	i.APCo,
	'C', 
	'Rate', 
	d.Rate, 
	i.Rate, 
	GETDATE(), 
	SUSER_SNAME() 
FROM inserted i
	JOIN deleted d ON i.VendorGroup = d.VendorGroup AND i.Vendor = d.Vendor
WHERE ISNULL(i.Rate,'') <> ISNULL(d.Rate,'') 


/* add Amount entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
SELECT 
	'vAPVendorMasterOnCost', 
	'VendorGroup: ' + CAST(d.VendorGroup AS VARCHAR(10)) 
		+ '   Vendor: ' + CAST(d.Vendor AS VARCHAR(10)) 
		+ ',  OnCostID: ' + CAST(d.OnCostID AS VARCHAR(10)),		
	i.APCo,
	'C', 
	'Amount', 
	d.Amount, 
	i.Amount, 
	GETDATE(), 
	SUSER_SNAME() 
FROM inserted i
	JOIN deleted d ON i.VendorGroup = d.VendorGroup AND i.Vendor = d.Vendor
WHERE ISNULL(i.Amount,'') <> ISNULL(d.Amount,'') 

  
/* add PayType entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
SELECT 
	'vAPVendorMasterOnCost', 
	'VendorGroup: ' + CAST(d.VendorGroup AS VARCHAR(10)) 
		+ '   Vendor: ' + CAST(d.Vendor AS VARCHAR(10)) 
		+ ',  OnCostID: ' + CAST(d.OnCostID AS VARCHAR(10)),		
	i.APCo,
	'C', 
	'PayType', 
	d.PayType, 
	i.PayType, 
	GETDATE(), 
	SUSER_SNAME() 
FROM inserted i
	JOIN deleted d ON i.VendorGroup = d.VendorGroup AND i.Vendor = d.Vendor
WHERE ISNULL(i.PayType,'') <> ISNULL(d.PayType,'')   
  

/* add ATOCategory entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
SELECT 
	'vAPVendorMasterOnCost', 
	'VendorGroup: ' + CAST(d.VendorGroup AS VARCHAR(10)) 
		+ '   Vendor: ' + CAST(d.Vendor AS VARCHAR(10)) 
		+ ',  OnCostID: ' + CAST(d.OnCostID AS VARCHAR(10)),		
	i.APCo,
	'C', 
	'ATOCategory', 
	d.ATOCategory, 
	i.ATOCategory, 
	GETDATE(), 
	SUSER_SNAME() 
FROM inserted i
	JOIN deleted d ON i.VendorGroup = d.VendorGroup AND i.Vendor = d.Vendor
WHERE ISNULL(i.ATOCategory,'') <> ISNULL(d.ATOCategory,'')  

 
/* add OnCostVendor entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
SELECT 
	'vAPVendorMasterOnCost', 
	'VendorGroup: ' + CAST(d.VendorGroup AS VARCHAR(10)) 
		+ '   Vendor: ' + CAST(d.Vendor AS VARCHAR(10)) 
		+ ',  OnCostID: ' + CAST(d.OnCostID AS VARCHAR(10)),		
	i.APCo,
	'C', 
	'OnCostVendor', 
	d.OnCostVendor, 
	i.OnCostVendor, 
	GETDATE(), 
	SUSER_SNAME() 
FROM inserted i
	JOIN deleted d ON i.VendorGroup = d.VendorGroup AND i.Vendor = d.Vendor
WHERE ISNULL(i.OnCostVendor,'') <> ISNULL(d.OnCostVendor,'')    


/* add SchemeID entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
SELECT 
	'vAPVendorMasterOnCost', 
	'VendorGroup: ' + CAST(d.VendorGroup AS VARCHAR(10)) 
		+ '   Vendor: ' + CAST(d.Vendor AS VARCHAR(10)) 
		+ ',  OnCostID: ' + CAST(d.OnCostID AS VARCHAR(10)),		
	i.APCo,
	'C', 
	'SchemeID', 
	d.SchemeID, 
	i.SchemeID, 
	GETDATE(), 
	SUSER_SNAME() 
FROM inserted i
	JOIN deleted d ON i.VendorGroup = d.VendorGroup AND i.Vendor = d.Vendor
WHERE ISNULL(i.SchemeID,'') <> ISNULL(d.SchemeID,'')    


/* add MemeberShipNumber entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
SELECT 
	'vAPVendorMasterOnCost', 
	'VendorGroup: ' + CAST(d.VendorGroup AS VARCHAR(10)) 
		+ '   Vendor: ' + CAST(d.Vendor AS VARCHAR(10)) 
		+ ',  OnCostID: ' + CAST(d.OnCostID AS VARCHAR(10)),		
	i.APCo,
	'C', 
	'MemberShipNumber', 
	d.MemberShipNumber, 
	i.MemberShipNumber, 
	GETDATE(), 
	SUSER_SNAME() 
FROM inserted i
	JOIN deleted d ON i.VendorGroup = d.VendorGroup AND i.Vendor = d.Vendor
WHERE ISNULL(i.MemberShipNumber,'') <> ISNULL(d.MemberShipNumber,'')    

RETURN

GO
ALTER TABLE [dbo].[vAPVendorMasterOnCost] ADD CONSTRAINT [PK_vAPVendorMasterOnCost] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
