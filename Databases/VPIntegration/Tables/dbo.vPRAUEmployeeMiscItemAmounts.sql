CREATE TABLE [dbo].[vPRAUEmployeeMiscItemAmounts]
(
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[PRCo] [dbo].[bCompany] NOT NULL,
[TaxYear] [char] (4) COLLATE Latin1_General_BIN NOT NULL,
[Employee] [dbo].[bEmployee] NOT NULL,
[BeginDate] [smalldatetime] NOT NULL,
[EndDate] [smalldatetime] NOT NULL,
[SummarySeq] [tinyint] NOT NULL,
[ItemCode] [char] (4) COLLATE Latin1_General_BIN NOT NULL,
[EDLType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[EDLCode] [dbo].[bEDLCode] NOT NULL,
[Amount] [dbo].[bDollar] NULL,
[OrganizationName] [dbo].[bDesc] NULL,
[AllowanceDesc] [dbo].[bDesc] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create TRIGGER [dbo].[vtPRAUEmployeeMiscItemAmountsd] 
   ON  [dbo].[vPRAUEmployeeMiscItemAmounts] 
   FOR DELETE AS 
/*-----------------------------------------------------------------
* Created:		EN	3/8/2011	#127269
* Modified:		
*
*	Delete trigger for PR Australia PAYG Employee Misc Item Amounts
*
*	Performs auditing via HQ Master Audit.
*/----------------------------------------------------------------

SET NOCOUNT ON

/* HQ Master Audit entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
SELECT 
	'vPRAUEmployeeMiscItemAmounts', 
	'PRCo: ' + CAST(d.PRCo AS VARCHAR(10)) 
		+ ',  Tax Year: ' + d.TaxYear 
		+ ',  Employee: ' + CAST(d.Employee AS VARCHAR(10))
		+ ',  SummarySeq: ' + CAST(d.SummarySeq AS VARCHAR(10))
		+ ',  BeginDate: ' + CAST(d.BeginDate AS VARCHAR(8))
		+ ',  EndDate: ' + CAST(d.EndDate AS VARCHAR(8))
		+ ',  ItemCode: ' + d.ItemCode
		+ ',  EDL Type: ' + d.EDLType
		+ ',  EDL Code: ' + CAST(d.EDLCode AS VARCHAR(10)), 
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


create TRIGGER [dbo].[vtPRAUEmployeeMiscItemAmountsi] 
	ON [dbo].[vPRAUEmployeeMiscItemAmounts] 
	FOR INSERT AS
/*-----------------------------------------------------------------
* Created:		EN	3/8/2011	#127269
* Modified:		
*
*	Insert trigger for PR Australian PAYG Employee Misc Item Amounts
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------

SET NOCOUNT ON

/* add HQ Master Audit entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
SELECT 
	'vPRAUEmployeeMiscItemAmounts', 
	'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
		+ ',  Tax Year: ' + i.TaxYear 
		+ ',  Employee: ' + CAST(i.Employee AS VARCHAR(10))
		+ ',  SummarySeq: ' + CAST(i.SummarySeq AS VARCHAR(10))
		+ ',  BeginDate: ' + CAST(i.BeginDate AS VARCHAR(8))
		+ ',  EndDate: ' + CAST(i.EndDate AS VARCHAR(8))
		+ ',  ItemCode: ' + i.ItemCode
		+ ',  EDL Type: ' + i.EDLType
		+ ',  EDL Code: ' + CAST(i.EDLCode AS VARCHAR(10)), 
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

create TRIGGER [dbo].[vtPRAUEmployeeMiscItemAmountsu] 
   ON  [dbo].[vPRAUEmployeeMiscItemAmounts] 
   FOR UPDATE AS 
/*-----------------------------------------------------------------
* Created:		EN	3/8/2011	#127269
* Modified:		EN  3/31/2011	Added auditing for AllowanceDesc
*
*	Update trigger for PR Australia PAYG Employee Misc Item Amounts
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

IF UPDATE(BeginDate)
BEGIN
	RAISERROR('Begin Date cannot be updated, it is a Key Value.', 11, -1)
    ROLLBACK TRANSACTION
END

IF UPDATE(EndDate)
BEGIN
	RAISERROR('End Date cannot be updated, it is a Key Value.', 11, -1)
    ROLLBACK TRANSACTION
END

IF UPDATE(ItemCode)
BEGIN
	RAISERROR('Item Code cannot be updated, it is a Key Value.', 11, -1)
    ROLLBACK TRANSACTION
END

IF UPDATE(EDLType)
BEGIN
	RAISERROR('EDL Type cannot be updated, it is a Key Value.', 11, -1)
    ROLLBACK TRANSACTION
END

IF UPDATE(EDLCode)
BEGIN
	RAISERROR('EDL Code cannot be updated, it is a Key Value.', 11, -1)
    ROLLBACK TRANSACTION
END

/* add HQ Master Audit entry */

-- Amount
IF UPDATE(Amount)
BEGIN
	INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		SELECT 
			'vPRAUEmployeeMiscItemAmounts', 
			'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
			+ ',  Tax Year: ' + i.TaxYear 
			+ ',  Employee: ' + CAST(i.Employee AS VARCHAR(10))
			+ ',  SummarySeq: ' + CAST(i.SummarySeq AS VARCHAR(10))
			+ ',  BeginDate: ' + CAST(i.BeginDate AS VARCHAR(8))
			+ ',  EndDate: ' + CAST(i.EndDate AS VARCHAR(8))
			+ ',  ItemCode: ' + i.ItemCode
			+ ',  EDL Type: ' + i.EDLType
			+ ',  EDL Code: ' + CAST(i.EDLCode AS VARCHAR(10)), 
			i.PRCo, 
			'C',
			'Amount',
			CAST(d.Amount AS VARCHAR(20)),
			CAST(i.Amount AS VARCHAR(20)),
			GETDATE(), 
			SUSER_SNAME() 
		FROM inserted i
			JOIN deleted d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear AND i.Employee = d.Employee 
				AND i.SummarySeq = d.SummarySeq AND i.ItemCode = d.ItemCode
			JOIN dbo.bPRCO c (NOLOCK) ON i.PRCo = c.PRCo
			WHERE ISNULL(i.Amount,0) <> ISNULL(d.Amount,0) 
				  AND  c.W2AuditYN = 'Y'
END

IF UPDATE(OrganizationName)
BEGIN
	INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		SELECT 
			'vPRAUEmployeeMiscItemAmounts', 
			'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
			+ ',  Tax Year: ' + i.TaxYear 
			+ ',  Employee: ' + CAST(i.Employee AS VARCHAR(10))
			+ ',  SummarySeq: ' + CAST(i.SummarySeq AS VARCHAR(10))
			+ ',  BeginDate: ' + CAST(i.BeginDate AS VARCHAR(8))
			+ ',  EndDate: ' + CAST(i.EndDate AS VARCHAR(8))
			+ ',  ItemCode: ' + i.ItemCode
			+ ',  EDL Type: ' + i.EDLType
			+ ',  EDL Code: ' + CAST(i.EDLCode AS VARCHAR(10)), 
			i.PRCo, 
			'C',
			'OrganizationName',
			d.OrganizationName,
			i.OrganizationName,
			GETDATE(), 
			SUSER_SNAME() 
		FROM inserted i
			JOIN deleted d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear AND i.Employee = d.Employee 
				AND i.SummarySeq = d.SummarySeq AND i.ItemCode = d.ItemCode
			JOIN dbo.bPRCO c (NOLOCK) ON i.PRCo = c.PRCo
			WHERE ISNULL(i.Amount,0) <> ISNULL(d.Amount,0) 
				  AND  c.W2AuditYN = 'Y'
END

IF UPDATE(AllowanceDesc)
BEGIN
	INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		SELECT 
			'vPRAUEmployeeMiscItemAmounts', 
			'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
			+ ',  Tax Year: ' + i.TaxYear 
			+ ',  Employee: ' + CAST(i.Employee AS VARCHAR(10))
			+ ',  SummarySeq: ' + CAST(i.SummarySeq AS VARCHAR(10))
			+ ',  BeginDate: ' + CAST(i.BeginDate AS VARCHAR(8))
			+ ',  EndDate: ' + CAST(i.EndDate AS VARCHAR(8))
			+ ',  ItemCode: ' + i.ItemCode
			+ ',  EDL Type: ' + i.EDLType
			+ ',  EDL Code: ' + CAST(i.EDLCode AS VARCHAR(10)), 
			i.PRCo, 
			'C',
			'AllowanceDesc',
			d.AllowanceDesc,
			i.AllowanceDesc,
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
ALTER TABLE [dbo].[vPRAUEmployeeMiscItemAmounts] ADD CONSTRAINT [PK_vPRAUEmployeeMiscItemAmounts_KeyID] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_vPRAUEmployeeMiscItemAmounts_PRCo_TaxYear_Employee_SummarySeq_ItemCode_EDLType_EDLCode] ON [dbo].[vPRAUEmployeeMiscItemAmounts] ([PRCo], [TaxYear], [Employee], [SummarySeq], [ItemCode], [EDLType], [EDLCode]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPRAUEmployeeMiscItemAmounts] WITH NOCHECK ADD CONSTRAINT [FK_vPRAUItems_vPRAUEmployeeMiscItemAmounts_ItemCode] FOREIGN KEY ([ItemCode]) REFERENCES [dbo].[vPRAUItems] ([ItemCode])
GO
ALTER TABLE [dbo].[vPRAUEmployeeMiscItemAmounts] WITH NOCHECK ADD CONSTRAINT [FK_vPRAUEmployees_vPRAUEmployeeMiscItemAmounts_PRCo_TaxYear_Employee] FOREIGN KEY ([PRCo], [TaxYear], [Employee]) REFERENCES [dbo].[vPRAUEmployees] ([PRCo], [TaxYear], [Employee])
GO
