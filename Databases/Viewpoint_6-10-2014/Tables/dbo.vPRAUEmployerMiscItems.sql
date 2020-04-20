CREATE TABLE [dbo].[vPRAUEmployerMiscItems]
(
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[PRCo] [dbo].[bCompany] NOT NULL,
[TaxYear] [char] (4) COLLATE Latin1_General_BIN NOT NULL,
[ItemCode] [char] (4) COLLATE Latin1_General_BIN NOT NULL,
[EDLType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[EDLCode] [dbo].[bEDLCode] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtPRAUEmployerMiscItemsd] 
   ON  [dbo].[vPRAUEmployerMiscItems] 
   FOR DELETE AS 
/*-----------------------------------------------------------------
* Created:		LS	1/21/2011	#127269
* Modified:		EN 1/24/2011  #127269 fixed data conversion bug in HQMA Auditing
*
*	Delete trigger for PR Australia PAYG Misc Item Setup
*
*	Performs auditing via HQ Master Audit.
*/----------------------------------------------------------------

SET NOCOUNT ON

/* HQ Master Audit entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
SELECT 
	'vPRAUEmployerMiscItems', 
	'PRCo: ' + CAST(d.PRCo AS VARCHAR(10)) 
		+ ',  Tax Year: ' + d.TaxYear 
		+ ',  ItemCode: ' + d.ItemCode
		+ ',  EDLType: ' + d.EDLType 
		+ ',  EDLCode: ' + CAST(d.EDLCode AS VARCHAR(10)), 
	d.PRCo, 
	'D', 
	NULL, 
	NULL, 
	NULL, 
	GETDATE(), 
	SUSER_SNAME() 
FROM DELETED d
JOIN dbo.bPRCO c (NOLOCK) ON d.PRCo = c.PRCo
WHERE c.W2AuditYN = 'Y'	
	
RETURN


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtPRAUEmployerMiscItemsi] 
	ON [dbo].[vPRAUEmployerMiscItems] 
	FOR INSERT AS
/*-----------------------------------------------------------------
* Created:		LS	1/21/2011	#127269
* Modified:		EN 1/24/2011  #127269 fixed data conversion bug in HQMA Auditing
*				LS 2/17/2011  #127269 Don't check EDL, if Type is not provided.
*
*	Insert trigger for PR Australian PAYG Misc Item Setup
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------

SET NOCOUNT ON

-- Verify Earnings Code  
IF EXISTS (SELECT 1 FROM inserted i WHERE i.EDLType = 'E')
BEGIN
	IF NOT EXISTS(SELECT 1 FROM bPREC e JOIN inserted i ON e.PRCo = i.PRCo AND e.EarnCode = i.EDLCode)
	BEGIN
		RAISERROR('Earnings Code has not been setup or does not match type.', 11, -1)
		ROLLBACK TRANSACTION
	END
 END
 -- Verify Deduction / Liability Code
 ELSE IF EXISTS (SELECT 1 FROM inserted i WHERE i.EDLType IN ('D', 'L'))
 BEGIN
	IF NOT EXISTS(SELECT 1 FROM bPRDL e JOIN inserted i ON e.PRCo = i.PRCo AND e.DLCode = i.EDLCode) 
	BEGIN
		RAISERROR('Deductions / Liabilities Code has not been setup or does not match type.', 11, -1)
		ROLLBACK TRANSACTION
	END
 END

 
/* add HQ Master Audit entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
SELECT 
	'vPRAUEmployerMiscItems', 
	'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
		+ ',  Tax Year: ' + i.TaxYear 
		+ ',  ItemCode: ' + i.ItemCode
		+ ',  EDLType: ' + i.EDLType 
		+ ',  EDLCode: ' + CAST(i.EDLCode AS VARCHAR(10)), 
	i.PRCo, 
	'A', 
	NULL, 
	NULL, 
	NULL, 
	GETDATE(), 
	SUSER_SNAME() 
FROM inserted i
JOIN dbo.bPRCO c (NOLOCK) ON i.PRCo = c.PRCo
WHERE c.W2AuditYN = 'Y'
  
RETURN


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtPRAUEmployerMiscItemsu] 
   ON  [dbo].[vPRAUEmployerMiscItems] 
   FOR UPDATE AS 
/*-----------------------------------------------------------------
* Created:		LS	1/21/2011	#127269
* Modified: 
*
*	Update trigger for PR Australia PAYG Misc Item Setup
*	Constraints are handled by Foreign Keys, and Unique Index (see those before adding additional triggers)
*
*	Note: No Auditing via HQ Master Audit - All columns are the key (only Add & Delete, no updates)
*/----------------------------------------------------------------

SET NOCOUNT ON

-- Verify Earnings Code  
IF EXISTS (SELECT 1 FROM inserted i WHERE i.EDLType = 'E')
BEGIN
	IF NOT EXISTS(SELECT 1 FROM bPREC e JOIN inserted i ON e.PRCo = i.PRCo AND e.EarnCode = i.EDLCode)
	BEGIN
		RAISERROR('Earnings Code has not been setup or does not match type.', 11, -1)
		ROLLBACK TRANSACTION
	END
 END
 -- Verify Deduction / Liability Code
 ELSE --IF EXISTS (SELECT 1 FROM inserted i WHERE i.EDLType IN ('D', 'L'))
 BEGIN
	IF NOT EXISTS(SELECT 1 FROM bPRDL e JOIN inserted i ON e.PRCo = i.PRCo AND e.DLCode = i.EDLCode) 
	BEGIN
		RAISERROR('Deductions / Liabilities Code has not been setup or does not match type.', 11, -1)
		ROLLBACK TRANSACTION
	END
 END

RETURN


GO
ALTER TABLE [dbo].[vPRAUEmployerMiscItems] ADD CONSTRAINT [PK_vPRAUEmployerMiscItems_KeyID] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_vPRAUEmployerMiscItems_All] ON [dbo].[vPRAUEmployerMiscItems] ([PRCo], [TaxYear], [ItemCode], [EDLType], [EDLCode]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPRAUEmployerMiscItems] WITH NOCHECK ADD CONSTRAINT [FK_vPRAUEmployerMiscItems_vPRAUItems_ItemCode] FOREIGN KEY ([ItemCode]) REFERENCES [dbo].[vPRAUItems] ([ItemCode])
GO
ALTER TABLE [dbo].[vPRAUEmployerMiscItems] WITH NOCHECK ADD CONSTRAINT [FK_vPRAUEmployerMiscItems_vPRAUEmployer_PRCo_TaxYear] FOREIGN KEY ([PRCo], [TaxYear]) REFERENCES [dbo].[vPRAUEmployer] ([PRCo], [TaxYear])
GO
ALTER TABLE [dbo].[vPRAUEmployerMiscItems] NOCHECK CONSTRAINT [FK_vPRAUEmployerMiscItems_vPRAUItems_ItemCode]
GO
ALTER TABLE [dbo].[vPRAUEmployerMiscItems] NOCHECK CONSTRAINT [FK_vPRAUEmployerMiscItems_vPRAUEmployer_PRCo_TaxYear]
GO
