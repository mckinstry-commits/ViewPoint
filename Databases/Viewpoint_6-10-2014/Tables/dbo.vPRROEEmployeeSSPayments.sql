CREATE TABLE [dbo].[vPRROEEmployeeSSPayments]
(
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[PRCo] [dbo].[bCompany] NOT NULL,
[Employee] [dbo].[bEmployee] NOT NULL,
[ROEDate] [dbo].[bDate] NOT NULL,
[Category] [varchar] (2) COLLATE Latin1_General_BIN NOT NULL,
[Number] [tinyint] NOT NULL,
[StatutoryHolidayPaymentDate] [dbo].[bDate] NULL,
[OtherMoniesCode] [char] (1) COLLATE Latin1_General_BIN NULL,
[SpecialPaymentStartDate] [dbo].[bDate] NULL,
[SpecialPaymentCode] [char] (3) COLLATE Latin1_General_BIN NULL,
[SpecialPaymentPeriod] [char] (1) COLLATE Latin1_General_BIN NULL,
[Amount] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_vPRROEEmployeeSSPayments_Amount] DEFAULT ((0))
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[vtPRROEEmployeeSSPaymentsd] 
   ON  [dbo].[vPRROEEmployeeSSPayments] 
   FOR DELETE AS 
/*-----------------------------------------------------------------
* Created:		MV	02/19/2013  TFS#41317 PR ROE 
* Modified:		
*
*	Delete trigger for PR ROE Employee SSPayments
*
*	Performs auditing via HQ Master Audit.
*/----------------------------------------------------------------

SET NOCOUNT ON

/* HQ Master Audit entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
SELECT 
	'vPRROEEmployeeSSPayments', 
	'PRCo: ' + CAST(d.PRCo AS VARCHAR(10)) 
		+ ',  Employee: ' + CAST(d.Employee AS VARCHAR(10))
		+ ', ROEDate: ' + CAST(d.ROEDate AS varchar(10))
		+ ',  Category: '  + CAST(d.Category AS VARCHAR(10))
		+ ',  Number: ' + CAST(d.Number AS VARCHAR(10)),  
	d.PRCo, 
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
CREATE TRIGGER [dbo].[vtPRROEEmployeeSSPaymentsi] 
	ON [dbo].[vPRROEEmployeeSSPayments] 
	FOR INSERT AS
/*-----------------------------------------------------------------
* Created:		MV	02/19/2013  TFS#41317 PR ROE 
* Modified:		
*
*	Insert trigger for PR ROE Employee SSPayments
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------

SET NOCOUNT ON

/* add HQ Master Audit entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
SELECT 
	'vPRROEEmployeeSSPayments', 
	'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
		+ ',  Employee: ' + CAST(i.Employee AS VARCHAR(10))
		+ ',  ROEDate: ' + CAST(i.ROEDate AS VARCHAR(10))
		+ ',  Category: '  + CAST(i.Category AS VARCHAR(10))
		+ ',  Number: ' + CAST(i.Number AS VARCHAR(10)), 
	i.PRCo, 
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

CREATE TRIGGER [dbo].[vtPRROEEmployeeSSPaymentsu] 
   ON  [dbo].[vPRROEEmployeeSSPayments] 
   FOR UPDATE AS 
/*-----------------------------------------------------------------
* Created:		MV	02/19/2013  TFS#41317 PR ROE 
* Modified: 
*
*	Update trigger for PR ROE Employee SSPayments
*	Constraints are handled by Foreign Keys, and Unique Index (see those before adding additional triggers)
*
*	Performs auditing via HQ Master Audit.
*/----------------------------------------------------------------

SET NOCOUNT ON

IF UPDATE(ROEDate)
BEGIN
	RAISERROR('ROEDate cannot be updated, it is part of a Key Value.', 11, -1)
    ROLLBACK TRANSACTION
END

IF UPDATE(Employee)
BEGIN
	RAISERROR('Employee ID cannot be updated, it is a Key Value.', 11, -1)
    ROLLBACK TRANSACTION
END

IF UPDATE(Category)
BEGIN
	RAISERROR('Category cannot be updated, it is a Key Value.', 11, -1)
    ROLLBACK TRANSACTION
END

IF UPDATE(Number)
BEGIN
	RAISERROR('Number cannot be updated, it is a Key Value.', 11, -1)
    ROLLBACK TRANSACTION
END


/* add HQ Master Audit entry */

-- StatutoryHolidayPaymentDate
INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 
		'vPRROEEmployeeSSPayments', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
		+ ',  Employee: ' + CAST(i.Employee AS VARCHAR(10))
		+ ',  ROEDate: ' + CAST(i.ROEDate AS VARCHAR(10))
		+ ',  Category: '  + CAST(i.Category AS VARCHAR(10))
		+ ',  Number: ' + CAST(i.Number AS VARCHAR(10)), 
		i.PRCo, 
		'C',
		'StatutoryHolidayPaymentDate',
		d.StatutoryHolidayPaymentDate,
		i.StatutoryHolidayPaymentDate,
		GETDATE(), 
		SUSER_SNAME() 
	FROM inserted i
        JOIN deleted d ON i.PRCo = d.PRCo AND i.ROEDate = d.ROEDate AND i.Employee = d.Employee AND i.Category = d.Category AND i.Number = d.Number
        WHERE ISNULL(i.StatutoryHolidayPaymentDate,'') <> ISNULL(d.StatutoryHolidayPaymentDate,'') 

	-- OtherMoniesCode
INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 
		'vPRROEEmployeeSSPayments', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
		+ ',  Employee: ' + CAST(i.Employee AS VARCHAR(10))
		+ ',  ROEDate: ' + CAST(i.ROEDate AS VARCHAR(10))
		+ ',  Category: '  + CAST(i.Category AS VARCHAR(10))
		+ ',  Number: ' + CAST(i.Number AS VARCHAR(10)), 
		i.PRCo, 
		'C',
		'OtherMoniesCode',
		d.OtherMoniesCode,
		i.OtherMoniesCode,
		GETDATE(), 
		SUSER_SNAME() 
	FROM inserted i
        JOIN deleted d ON i.PRCo = d.PRCo AND i.ROEDate = d.ROEDate AND i.Employee = d.Employee AND i.Category = d.Category AND i.Number = d.Number
        WHERE ISNULL(i.OtherMoniesCode,'') <> ISNULL(d.OtherMoniesCode,'') 

		-- SpecialPaymentStartDate
INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 
		'vPRROEEmployeeSSPayments', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
		+ ',  Employee: ' + CAST(i.Employee AS VARCHAR(10))
		+ ',  ROEDate: ' + CAST(i.ROEDate AS VARCHAR(10))
		+ ',  Category: '  + CAST(i.Category AS VARCHAR(10))
		+ ',  Number: ' + CAST(i.Number AS VARCHAR(10)), 
		i.PRCo, 
		'C',
		'SpecialPaymentStartDate',
		d.SpecialPaymentStartDate,
		i.SpecialPaymentStartDate,
		GETDATE(), 
		SUSER_SNAME() 
	FROM inserted i
        JOIN deleted d ON i.PRCo = d.PRCo AND i.ROEDate = d.ROEDate AND i.Employee = d.Employee AND i.Category = d.Category AND i.Number = d.Number
        WHERE ISNULL(i.SpecialPaymentStartDate,'') <> ISNULL(d.SpecialPaymentStartDate,'') 


-- SpecialPaymentCode
INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 
		'vPRROEEmployeeSSPayments', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
		+ ',  Employee: ' + CAST(i.Employee AS VARCHAR(10))
		+ ',  ROEDate: ' + CAST(i.ROEDate AS VARCHAR(10))
		+ ',  Category: '  + CAST(i.Category AS VARCHAR(10))
		+ ',  Number: ' + CAST(i.Number AS VARCHAR(10)), 
		i.PRCo, 
		'C',
		'SpecialPaymentCode',
		d.SpecialPaymentCode,
		i.SpecialPaymentCode,
		GETDATE(), 
		SUSER_SNAME() 
	FROM inserted i
        JOIN deleted d ON i.PRCo = d.PRCo AND i.ROEDate = d.ROEDate AND i.Employee = d.Employee AND i.Category = d.Category AND i.Number = d.Number
        WHERE ISNULL(i.SpecialPaymentCode,'') <> ISNULL(d.SpecialPaymentCode,'') 
			  
-- SpecialPaymentPeriod
INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 
		'vPRROEEmployeeSSPayments', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
	+ ',  Employee: ' + CAST(i.Employee AS VARCHAR(10))
		+ ',  ROEDate: ' + CAST(i.ROEDate AS VARCHAR(10))
		+ ',  Category: '  + CAST(i.Category AS VARCHAR(10))
		+ ',  Number: ' + CAST(i.Number AS VARCHAR(10)), 
		i.PRCo, 
		'C',
		'SpecialPaymentPeriod',
		d.SpecialPaymentPeriod,
		i.SpecialPaymentPeriod,
		GETDATE(), 
		SUSER_SNAME() 
	FROM inserted i
        JOIN deleted d ON i.PRCo = d.PRCo AND i.ROEDate = d.ROEDate AND i.Employee = d.Employee AND i.Category = d.Category AND i.Number = d.Number
        WHERE ISNULL(i.SpecialPaymentPeriod,'') <> ISNULL(d.SpecialPaymentPeriod,'')
		
-- Amount
INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 
		'vPRROEEmployeeSSPayments', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
		+ ',  Employee: ' + CAST(i.Employee AS VARCHAR(10))
		+ ',  ROEDate: ' + CAST(i.ROEDate AS VARCHAR(10))
		+ ',  Category: '  + CAST(i.Category AS VARCHAR(10))
		+ ',  Number: ' + CAST(i.Number AS VARCHAR(10)), 
		i.PRCo, 
		'C',
		'Amount',
		d.Amount,
		i.Amount,
		GETDATE(), 
		SUSER_SNAME() 
	FROM inserted i
        JOIN deleted d ON i.PRCo = d.PRCo AND i.ROEDate = d.ROEDate AND i.Employee = d.Employee AND i.Category = d.Category AND i.Number = d.Number
        WHERE ISNULL(i.Amount,'') <> ISNULL(d.Amount,'') 
 

RETURN
GO
ALTER TABLE [dbo].[vPRROEEmployeeSSPayments] WITH NOCHECK ADD CONSTRAINT [CK_vPRROEEmployeeSSPayments_OtherMoniesCode] CHECK (([OtherMoniesCode]='Y' OR [OtherMoniesCode]='U' OR [OtherMoniesCode]='S' OR [OtherMoniesCode]='R' OR [OtherMoniesCode]='O' OR [OtherMoniesCode]='I' OR [OtherMoniesCode]='H' OR [OtherMoniesCode]='G' OR [OtherMoniesCode]='E' OR [OtherMoniesCode]='B' OR [OtherMoniesCode]='A' OR [OtherMoniesCode] IS NULL))
GO
ALTER TABLE [dbo].[vPRROEEmployeeSSPayments] WITH NOCHECK ADD CONSTRAINT [CK_vPRROEEmployeeSSPayments_SpecialPaymentPeriod] CHECK ((([SpecialPaymentPeriod]='W' OR [SpecialPaymentPeriod]='D') AND [Category]='SP' OR [SpecialPaymentPeriod] IS NULL AND [Category]<>'SP'))
GO
ALTER TABLE [dbo].[vPRROEEmployeeSSPayments] ADD CONSTRAINT [PK_vPRROEEmployeeSSPayments_KeyID] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_vPRROEEmployeeSSPayments_PRCo_Employee_ROEDate_Category_Number] ON [dbo].[vPRROEEmployeeSSPayments] ([PRCo], [Employee], [ROEDate], [Category], [Number]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPRROEEmployeeSSPayments] WITH NOCHECK ADD CONSTRAINT [FK_vPRROEEmployeeSSPayments_vPRROEEmployeeHistory] FOREIGN KEY ([PRCo], [Employee], [ROEDate]) REFERENCES [dbo].[vPRROEEmployeeHistory] ([PRCo], [Employee], [ROEDate]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[vPRROEEmployeeSSPayments] NOCHECK CONSTRAINT [FK_vPRROEEmployeeSSPayments_vPRROEEmployeeHistory]
GO
