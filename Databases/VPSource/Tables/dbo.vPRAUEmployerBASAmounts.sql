CREATE TABLE [dbo].[vPRAUEmployerBASAmounts]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[TaxYear] [char] (4) COLLATE Latin1_General_BIN NOT NULL,
[Seq] [int] NOT NULL,
[Item] [varchar] (3) COLLATE Latin1_General_BIN NOT NULL,
[ItemDesc] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[SalesOrPurchAmt] [dbo].[bDollar] NULL,
[SalesOrPurchAmtGST] [dbo].[bDollar] NULL,
[GSTTaxAmt] [dbo].[bDollar] NULL,
[WithholdingAmt] [dbo].[bDollar] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE TRIGGER [dbo].[vtPRAUEmployerBASAmountsu] 
   ON  [dbo].[vPRAUEmployerBASAmounts] 
   FOR UPDATE AS 
/*-----------------------------------------------------------------
* Created:		MV	3/11/2011	#138181
* Modified: 
*				
*
*	Update trigger for vPRAUEmployerBASAmounts update
*
*	Performs auditing via HQ Master Audit.
*/----------------------------------------------------------------

SET NOCOUNT ON

 /* add HQ Master Audit entry */
 
IF UPDATE(SalesOrPurchAmtGST)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerBASAmounts', 
			'PRCo: ' + CAST(d.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + d.TaxYear + ', Seq: ' + CAST(d.Seq AS VARCHAR(10)),
		i.PRCo, 
		'C', 
		'SalesOrPurchAmtGST', 
		CAST(d.SalesOrPurchAmtGST AS VARCHAR(16)), 
		CAST(i.SalesOrPurchAmtGST AS VARCHAR(16)), 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear and i.Seq=d.Seq
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.SalesOrPurchAmtGST, 0) <> ISNULL(d.SalesOrPurchAmtGST, 0) AND a.W2AuditYN = 'Y'
END	
IF UPDATE(SalesOrPurchAmtGST)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerBASAmounts', 
			'PRCo: ' + CAST(d.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + d.TaxYear + ', Seq: ' + CAST(d.Seq AS VARCHAR(10)),
		i.PRCo, 
		'C', 
		'SalesOrPurchAmtGST', 
		CAST(d.SalesOrPurchAmtGST AS VARCHAR(16)), 
		CAST(i.SalesOrPurchAmtGST AS VARCHAR(16)), 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear and i.Seq=d.Seq
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.SalesOrPurchAmtGST, 0) <> ISNULL(d.SalesOrPurchAmtGST, 0) AND a.W2AuditYN = 'Y'
END	

IF UPDATE(GSTTaxAmt)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerBASAmounts', 
			'PRCo: ' + CAST(d.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + d.TaxYear + ', Seq: ' + CAST(d.Seq AS VARCHAR(10)),
		i.PRCo, 
		'C', 
		'GSTTaxAmt', 
		CAST(d.GSTTaxAmt AS VARCHAR(16)), 
		CAST(i.GSTTaxAmt AS VARCHAR(16)), 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear and i.Seq=d.Seq
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.GSTTaxAmt, 0) <> ISNULL(d.GSTTaxAmt, 0) AND a.W2AuditYN = 'Y'
END

IF UPDATE(WithholdingAmt)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerBASAmounts', 
			'PRCo: ' + CAST(d.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + d.TaxYear + ', Seq: ' + CAST(d.Seq AS VARCHAR(10)),
		i.PRCo, 
		'C', 
		'WithholdingAmt', 
		CAST(d.WithholdingAmt AS VARCHAR(16)), 
		CAST(i.WithholdingAmt AS VARCHAR(16)), 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear and i.Seq=d.Seq
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.WithholdingAmt, 0) <> ISNULL(d.WithholdingAmt, 0) AND a.W2AuditYN = 'Y'
END	
	
RETURN



GO
ALTER TABLE [dbo].[vPRAUEmployerBASAmounts] ADD CONSTRAINT [PK_vPRAUEmployerBASAmounts] PRIMARY KEY CLUSTERED  ([PRCo], [TaxYear], [Seq], [Item]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPRAUEmployerBASAmounts] WITH NOCHECK ADD CONSTRAINT [FK_vPRAUEmployerBASAmounts_vPRAUEmployerBAS] FOREIGN KEY ([PRCo], [TaxYear], [Seq]) REFERENCES [dbo].[vPRAUEmployerBAS] ([PRCo], [TaxYear], [Seq])
GO
