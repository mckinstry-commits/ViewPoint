CREATE TABLE [dbo].[vPRAUEmployerSuperItems]
(
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[PRCo] [dbo].[bCompany] NOT NULL,
[TaxYear] [char] (4) COLLATE Latin1_General_BIN NOT NULL,
[ItemCode] [char] (4) COLLATE Latin1_General_BIN NOT NULL,
[DLType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[DLCode] [dbo].[bEDLCode] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtPRAUEmployerSuperItemsd] 
   ON  [dbo].[vPRAUEmployerSuperItems] 
   FOR DELETE AS 
/*-----------------------------------------------------------------
* Created:		LS	1/11/2011	#127269
* Modified:		EN 1/26/2011  #127269 fixed data conversion bug in HQMA Auditing
*
*	Delete trigger for PR Australia PAYG Superannuation Item Setup
*
*	Performs auditing via HQ Master Audit.
*/----------------------------------------------------------------

SET NOCOUNT ON

/* HQ Master Audit entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
SELECT 
	'vPRAUEmployerSuperItems', 
	'PRCo: ' + CAST(d.PRCo AS VARCHAR(10)) 
		+ ',  Tax Year: ' + d.TaxYear 
		+ ',  ItemCode: ' + d.ItemCode
		+ ',  DLType: ' + d.DLType 
		+ ',  DLCode: ' + CAST(d.DLCode AS VARCHAR(10)), 
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

CREATE TRIGGER [dbo].[vtPRAUEmployerSuperItemsi] 
	ON [dbo].[vPRAUEmployerSuperItems] 
	FOR INSERT AS
/*-----------------------------------------------------------------
* Created:		LS	1/11/2011	#127269
* Modified:		EN 1/26/2011  #127269 fixed data conversion bug in HQMA Auditing
*
*	Insert trigger for PR Australian PAYG Superannuation Item Setup
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------

SET NOCOUNT ON

/* add HQ Master Audit entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
SELECT 
	'vPRAUEmployerSuperItems', 
	'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
		+ ',  Tax Year: ' + i.TaxYear 
		+ ',  ItemCode: ' + i.ItemCode
		+ ',  DLType: ' + i.DLType 
		+ ',  DLCode: ' + CAST(i.DLCode AS VARCHAR(10)), 
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
ALTER TABLE [dbo].[vPRAUEmployerSuperItems] ADD CONSTRAINT [PK_vPRAUEmployerSuperItems_KeyID] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_vPRAUEmployerSuperItems_All] ON [dbo].[vPRAUEmployerSuperItems] ([PRCo], [TaxYear], [ItemCode], [DLType], [DLCode]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPRAUEmployerSuperItems] WITH NOCHECK ADD CONSTRAINT [FK_vPRAUItems_vPRAUEmployerSuperItems_ItemCode] FOREIGN KEY ([ItemCode]) REFERENCES [dbo].[vPRAUItems] ([ItemCode])
GO
ALTER TABLE [dbo].[vPRAUEmployerSuperItems] WITH NOCHECK ADD CONSTRAINT [FK_vPRAUEmployerSuperItems_bPRDL_DLCode] FOREIGN KEY ([PRCo], [DLCode]) REFERENCES [dbo].[bPRDL] ([PRCo], [DLCode])
GO
ALTER TABLE [dbo].[vPRAUEmployerSuperItems] WITH NOCHECK ADD CONSTRAINT [FK_vPRAUEmployer_vPRAUEmployerSuperItems_PRCo_TaxYear] FOREIGN KEY ([PRCo], [TaxYear]) REFERENCES [dbo].[vPRAUEmployer] ([PRCo], [TaxYear])
GO
ALTER TABLE [dbo].[vPRAUEmployerSuperItems] NOCHECK CONSTRAINT [FK_vPRAUItems_vPRAUEmployerSuperItems_ItemCode]
GO
ALTER TABLE [dbo].[vPRAUEmployerSuperItems] NOCHECK CONSTRAINT [FK_vPRAUEmployerSuperItems_bPRDL_DLCode]
GO
ALTER TABLE [dbo].[vPRAUEmployerSuperItems] NOCHECK CONSTRAINT [FK_vPRAUEmployer_vPRAUEmployerSuperItems_PRCo_TaxYear]
GO
