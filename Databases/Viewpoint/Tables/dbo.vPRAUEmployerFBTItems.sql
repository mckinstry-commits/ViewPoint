CREATE TABLE [dbo].[vPRAUEmployerFBTItems]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[TaxYear] [char] (4) COLLATE Latin1_General_BIN NOT NULL,
[FBTType] [varchar] (4) COLLATE Latin1_General_BIN NOT NULL,
[EDLType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[EDLCode] [dbo].[bEDLCode] NOT NULL,
[Category] [char] (1) COLLATE Latin1_General_BIN NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[UniqueAttchID] [uniqueidentifier] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create TRIGGER [dbo].[vtPRAUEmployerFBTItemsd] 
   ON  [dbo].[vPRAUEmployerFBTItems] 
   FOR DELETE AS 
/*-----------------------------------------------------------------
* Created:		CHS	01/07/2010	#142027
* Modified: 
*
*	Update trigger for vPRAUEmployerFBTItems
*
*	Performs auditing via HQ Master Audit.
*/----------------------------------------------------------------

SET NOCOUNT ON

/* HQ Master Audit entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
SELECT 
	'vPRAUEmployerFBTItems', 
	'PRCo: ' + CAST(d.PRCo AS VARCHAR(10)) 
			+ ',  Tax Year: ' + d.TaxYear 
			+ ',  FBT Type: ' + d.FBTType
			+ ',  EDL Type: ' + d.EDLType
			+ ',  EDL Code: ' + CAST(d.EDLCode as varchar(10)), 
	d.PRCo, 
	'D', 
	'Category', 
	d.Category, 
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

create TRIGGER [dbo].[vtPRAUEmployerFBTItemsi] 
	ON [dbo].[vPRAUEmployerFBTItems] 
	FOR INSERT AS
/*-----------------------------------------------------------------
* Created:		CHS	01/07/2010	#142027
* Modified: 
*
*	Insert trigger for vPRAUEmployerFBTItems
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------

SET NOCOUNT ON
 
/* add HQ Master Audit entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
SELECT 
	'vPRAUEmployerFBTItems', 
	'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
			+ ',  Tax Year: ' + i.TaxYear 
			+ ',  FBT Type: ' + i.FBTType
			+ ',  EDL Type: ' + i.EDLType
			+ ',  EDL Code: ' + CAST(i.EDLCode as varchar(10)), 
	i.PRCo, 
	'A', 
	'Category', 
	NULL, 	
	i.Category, 
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

create TRIGGER [dbo].[vtPRAUEmployerFBTItemsu] 
   ON  [dbo].[vPRAUEmployerFBTItems] 
   FOR UPDATE AS 
/*-----------------------------------------------------------------
* Created:		CHS	01/07/2010	#142027
* Modified: 
*
*	Update trigger for vPRAUEmployerFBTItems update
*
*	Performs auditing via HQ Master Audit.
*/----------------------------------------------------------------

SET NOCOUNT ON

 /* add HQ Master Audit entry */
IF UPDATE(Category)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerFBTItems', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
				+ ',  Tax Year: ' + i.TaxYear 
				+ ',  FBT Type: ' + i.FBTType
				+ ',  EDL Type: ' + i.EDLType
				+ ',  EDL Code: ' + CAST(i.EDLCode as varchar(10)), 
		i.PRCo, 
		'C', 
		'Category', 
		d.Category, 
		i.Category, 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.Category, '') <> ISNULL(d.Category, '') AND a.W2AuditYN = 'Y'
END	

RETURN


GO
ALTER TABLE [dbo].[vPRAUEmployerFBTItems] ADD CONSTRAINT [PK_vPRAUEmployerFBTItems] PRIMARY KEY CLUSTERED  ([PRCo], [TaxYear], [FBTType], [EDLType], [EDLCode]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPRAUEmployerFBTItems] WITH NOCHECK ADD CONSTRAINT [FK_vPRAUEmployerFBT_vPRAUEmployerFBTItems] FOREIGN KEY ([PRCo], [TaxYear]) REFERENCES [dbo].[vPRAUEmployerFBT] ([PRCo], [TaxYear])
GO
