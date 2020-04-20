CREATE TABLE [dbo].[vPRAUEmployeeItemAmounts]
(
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[PRCo] [dbo].[bCompany] NOT NULL,
[TaxYear] [char] (4) COLLATE Latin1_General_BIN NOT NULL,
[Employee] [dbo].[bEmployee] NOT NULL,
[BeginDate] [smalldatetime] NOT NULL,
[EndDate] [smalldatetime] NOT NULL,
[SummarySeq] [tinyint] NOT NULL,
[ItemCode] [char] (4) COLLATE Latin1_General_BIN NOT NULL,
[Amount] [dbo].[bDollar] NULL,
[LSAType] [char] (1) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[vtPRAUEmployeeItemAmountsd] 
   ON  [dbo].[vPRAUEmployeeItemAmounts] 
   FOR DELETE AS 
/*-----------------------------------------------------------------
* Created:		LS	3/4/2011	#127269
* Modified:		
*
*	Delete trigger for PR Australia PAYG Employee Item Amounts
*
*	Performs auditing via HQ Master Audit.
*/----------------------------------------------------------------

SET NOCOUNT ON

/* HQ Master Audit entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
SELECT 
	'vPRAUEmployeeItemAmounts', 
	'PRCo: ' + CAST(d.PRCo AS VARCHAR(10)) 
		+ ',  Tax Year: ' + d.TaxYear 
		+ ',  Employee: ' + CAST(d.Employee AS VARCHAR(10))
		+ ',  SummarySeq: ' + CAST(d.SummarySeq AS VARCHAR(10))
		+ ',  ItemCode: ' + d.ItemCode, 
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


CREATE TRIGGER [dbo].[vtPRAUEmployeeItemAmountsi] 
	ON [dbo].[vPRAUEmployeeItemAmounts] 
	FOR INSERT AS
/*-----------------------------------------------------------------
* Created:		LS	3/4/2011	#127269
* Modified:		
*
*	Insert trigger for PR Australian PAYG Employee Item Amounts
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------

SET NOCOUNT ON

/* add HQ Master Audit entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
SELECT 
	'vPRAUEmployeeItemAmounts', 
	'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
		+ ',  Tax Year: ' + i.TaxYear 
		+ ',  Employee: ' + CAST(i.Employee AS VARCHAR(10))
		+ ',  SummarySeq: ' + CAST(i.SummarySeq AS VARCHAR(10))
		+ ',  ItemCode: ' + i.ItemCode, 
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

CREATE TRIGGER [dbo].[vtPRAUEmployeeItemAmountsu] 
   ON  [dbo].[vPRAUEmployeeItemAmounts] 
   FOR UPDATE AS 
/*-----------------------------------------------------------------
* Created:		LS	3/4/2011	#127269
* Modified: 
*
*	Update trigger for PR Australia PAYG Employee Item Amounts
*	Constraints are handled by Foreign Keys, and Unique Index (see those before adding additional triggers)
*
*	Performs auditing via HQ Master Audit.
*/----------------------------------------------------------------

SET NOCOUNT ON

IF UPDATE(TaxYear)
BEGIN
	RAISERROR('TaxYear cannot be updated, it is part of a Key Value.', 11, -1)
    ROLLBACK TRANSACTION
END

IF UPDATE(Employee)
BEGIN
	RAISERROR('Employee ID cannot be updated, it is a Key Value.', 11, -1)
    ROLLBACK TRANSACTION
END

IF UPDATE(SummarySeq)
BEGIN
	RAISERROR('Summary Seq cannot be updated, it is a Key Value.', 11, -1)
    ROLLBACK TRANSACTION
END

IF UPDATE(ItemCode)
BEGIN
	RAISERROR('Item Code cannot be updated, it is a Key Value.', 11, -1)
    ROLLBACK TRANSACTION
END

/* add HQ Master Audit entry */

-- Begin Date
IF UPDATE(BeginDate)
BEGIN
	INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		SELECT 
			'vPRAUEmployeeItemAmounts', 
			'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
			+ ',  Tax Year: ' + i.TaxYear 
			+ ',  Employee: ' + CAST(i.Employee AS VARCHAR(10))
			+ ',  SummarySeq: ' + CAST(i.SummarySeq AS VARCHAR(10))
			+ ',  ItemCode: ' + i.ItemCode, 
			i.PRCo, 
			'C',
			'BeginDate',
			d.BeginDate,
			i.BeginDate,
			GETDATE(), 
			SUSER_SNAME() 
		FROM inserted i
			JOIN deleted d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear AND i.Employee = d.Employee 
				AND i.SummarySeq = d.SummarySeq AND i.ItemCode = d.ItemCode
			JOIN dbo.bPRCO c (NOLOCK) ON i.PRCo = c.PRCo
			WHERE ISNULL(i.BeginDate,'') <> ISNULL(d.BeginDate,'') 
				  AND c.W2AuditYN = 'Y'
END

-- End Date
IF UPDATE(EndDate)
BEGIN
	INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		SELECT 
			'vPRAUEmployeeItemAmounts', 
			'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
			+ ',  Tax Year: ' + i.TaxYear 
			+ ',  Employee: ' + CAST(i.Employee AS VARCHAR(10))
			+ ',  SummarySeq: ' + CAST(i.SummarySeq AS VARCHAR(10))
			+ ',  ItemCode: ' + i.ItemCode, 
			i.PRCo, 
			'C',
			'EndDate',
			d.EndDate,
			i.EndDate,
			GETDATE(), 
			SUSER_SNAME() 
		FROM inserted i
			JOIN deleted d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear AND i.Employee = d.Employee 
				AND i.SummarySeq = d.SummarySeq AND i.ItemCode = d.ItemCode
			JOIN dbo.bPRCO c (NOLOCK) ON i.PRCo = c.PRCo
			WHERE ISNULL(i.EndDate,'') <> ISNULL(d.EndDate,'') 
				  AND c.W2AuditYN = 'Y'
END
			  
-- Amount
IF UPDATE(Amount)
BEGIN
	INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		SELECT 
			'vPRAUEmployeeItemAmounts', 
			'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
			+ ',  Tax Year: ' + i.TaxYear 
			+ ',  Employee: ' + CAST(i.Employee AS VARCHAR(10))
			+ ',  SummarySeq: ' + CAST(i.SummarySeq AS VARCHAR(10))
			+ ',  ItemCode: ' + i.ItemCode, 
			i.PRCo, 
			'C',
			'Amount',
			d.Amount,
			i.Amount,
			GETDATE(), 
			SUSER_SNAME() 
		FROM inserted i
			JOIN deleted d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear AND i.Employee = d.Employee 
				AND i.SummarySeq = d.SummarySeq AND i.ItemCode = d.ItemCode
			JOIN dbo.bPRCO c (NOLOCK) ON i.PRCo = c.PRCo
			WHERE ISNULL(i.Amount,0) <> ISNULL(d.Amount,0) 
				  AND  c.W2AuditYN = 'Y'
END

RETURN



GO
ALTER TABLE [dbo].[vPRAUEmployeeItemAmounts] ADD CONSTRAINT [PK_vPRAUEmployeeItemAmounts_KeyID] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_vPRAUEmployeeItemAmounts_PRCo_TaxYear_Employee_SummarySeq_ItemCode] ON [dbo].[vPRAUEmployeeItemAmounts] ([PRCo], [TaxYear], [Employee], [SummarySeq], [ItemCode]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPRAUEmployeeItemAmounts] WITH NOCHECK ADD CONSTRAINT [FK_vPRAUItems_vPRAUEmployeeItemAmounts_ItemCode] FOREIGN KEY ([ItemCode]) REFERENCES [dbo].[vPRAUItems] ([ItemCode])
GO
ALTER TABLE [dbo].[vPRAUEmployeeItemAmounts] WITH NOCHECK ADD CONSTRAINT [FK_vPRAUEmployees_vPRAUEmployeeItemAmounts_PRCo_TaxYear_Employee] FOREIGN KEY ([PRCo], [TaxYear], [Employee]) REFERENCES [dbo].[vPRAUEmployees] ([PRCo], [TaxYear], [Employee])
GO
