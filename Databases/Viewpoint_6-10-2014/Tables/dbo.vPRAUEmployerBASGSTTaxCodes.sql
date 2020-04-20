CREATE TABLE [dbo].[vPRAUEmployerBASGSTTaxCodes]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[TaxYear] [char] (4) COLLATE Latin1_General_BIN NOT NULL,
[Seq] [int] NOT NULL,
[Item] [varchar] (3) COLLATE Latin1_General_BIN NOT NULL,
[TaxCode] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[ItemDesc] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[TaxGroup] [dbo].[bGroup] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE TRIGGER [dbo].[vtPRAUEmployerBASGSTTaxCodesd] 
   ON  [dbo].[vPRAUEmployerBASGSTTaxCodes] 
   FOR DELETE AS 
/*-----------------------------------------------------------------
* Created:		MV	3/7/2011	#138181
* Modified: 
*
*	Update trigger for vPRAUEmployerBASGSTTaxCodes
*
*	Performs auditing via HQ Master Audit.
*/----------------------------------------------------------------

SET NOCOUNT ON

/* HQ Master Audit entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
SELECT 
	'vPRAUEmployerBASGSTTaxCodes', 
	'PRCo: ' + CAST(d.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + d.TaxYear + ', Seq: ' + CAST(d.Seq AS VARCHAR(10)),
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



CREATE TRIGGER [dbo].[vtPRAUEmployerBASGSTTaxCodesi] 
	ON [dbo].[vPRAUEmployerBASGSTTaxCodes] 
	FOR INSERT AS
/*-----------------------------------------------------------------
* Created:		MV	3/7/2011	#138181
* Modified: 
*
*	Update trigger for vPRAUEmployerBASGSTTaxCodes
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------

SET NOCOUNT ON
 
/* add HQ Master Audit entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
SELECT 
	'vPRAUEmployerBASGSTTaxCodes', 
	'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear + ', Seq: ' + CAST(i.Seq AS VARCHAR(10)),
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




CREATE TRIGGER [dbo].[vtPRAUEmployerBASGSTTaxCodesu] 
   ON  [dbo].[vPRAUEmployerBASGSTTaxCodes] 
   FOR UPDATE AS 
/*-----------------------------------------------------------------
* Created:		MV	3/7/2011	#138181
* Modified: 
*				
*
*	Update trigger for vPRAUEmployerBASGSTTaxCodes update
*
*	Performs auditing via HQ Master Audit.
*/----------------------------------------------------------------

SET NOCOUNT ON

 /* add HQ Master Audit entry */
 
IF UPDATE(ItemDesc)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerBASGSTTaxCodes', 
			'PRCo: ' + CAST(d.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + d.TaxYear + ', Seq: ' + CAST(d.Seq AS VARCHAR(10)),
		i.PRCo, 
		'C', 
		'Item Desc', 
		d.ItemDesc, 
		i.ItemDesc, 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear and i.Seq=d.Seq
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.ItemDesc, '') <> ISNULL(d.ItemDesc, '') AND a.W2AuditYN = 'Y'
END	

RETURN



GO
ALTER TABLE [dbo].[vPRAUEmployerBASGSTTaxCodes] ADD CONSTRAINT [PK_vPRAUEmployerBASGSTTaxCodes] PRIMARY KEY CLUSTERED  ([PRCo], [TaxYear], [Seq], [Item], [TaxCode]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPRAUEmployerBASGSTTaxCodes] WITH NOCHECK ADD CONSTRAINT [FK_vPRAUEmployerBASGSTTaxCodes_vPRAUEmployerBAS] FOREIGN KEY ([PRCo], [TaxYear], [Seq]) REFERENCES [dbo].[vPRAUEmployerBAS] ([PRCo], [TaxYear], [Seq])
GO
ALTER TABLE [dbo].[vPRAUEmployerBASGSTTaxCodes] NOCHECK CONSTRAINT [FK_vPRAUEmployerBASGSTTaxCodes_vPRAUEmployerBAS]
GO
