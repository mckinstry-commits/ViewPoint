CREATE TABLE [dbo].[vPRROEEmployeeHistory]
(
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[PRCo] [dbo].[bCompany] NOT NULL,
[Employee] [dbo].[bEmployee] NOT NULL,
[ROEDate] [dbo].[bDate] NOT NULL,
[ROE_SN] [varchar] (9) COLLATE Latin1_General_BIN NULL,
[SIN] [varchar] (9) COLLATE Latin1_General_BIN NOT NULL,
[FirstName] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[MiddleInitial] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[LastName] [varchar] (28) COLLATE Latin1_General_BIN NOT NULL,
[AddressLine1] [varchar] (35) COLLATE Latin1_General_BIN NOT NULL,
[AddressLine2] [varchar] (35) COLLATE Latin1_General_BIN NULL,
[AddressLine3] [varchar] (35) COLLATE Latin1_General_BIN NULL,
[EmployeeOccupation] [varchar] (40) COLLATE Latin1_General_BIN NULL,
[FirstDayWorked] [dbo].[bDate] NOT NULL,
[LastDayPaid] [dbo].[bDate] NOT NULL,
[FinalPayPeriodEndDate] [dbo].[bDate] NOT NULL,
[ExpectedRecallCode] [char] (1) COLLATE Latin1_General_BIN NULL,
[ExpectedRecallDate] [dbo].[bDate] NULL,
[TotalInsurableHours] [smallint] NOT NULL CONSTRAINT [DF_vPRROEEmployeeHistory_TotalInsurableHours] DEFAULT ((0)),
[TotalInsurableEarnings] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_vPRROEEmployeeHistory_TotalInsurableEarnings] DEFAULT ((0)),
[ReasonForROE] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[ContactFirstName] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[ContactLastName] [varchar] (28) COLLATE Latin1_General_BIN NOT NULL,
[ContactAreaCode] [varchar] (3) COLLATE Latin1_General_BIN NOT NULL,
[ContactPhoneNbr] [varchar] (8) COLLATE Latin1_General_BIN NOT NULL,
[ContactPhoneExt] [varchar] (5) COLLATE Latin1_General_BIN NULL,
[Comments] [varchar] (160) COLLATE Latin1_General_BIN NULL,
[AmendedDate] [dbo].[bDate] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[PayPeriodType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[Language] [char] (1) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[vtPRROEEmployeeHistoryd] 
   ON  [dbo].[vPRROEEmployeeHistory] 
   FOR DELETE AS 
/*-----------------------------------------------------------------
* Created:		MV	TFS#40977 PR ROE Project
* Modified:		
*
*	Delete trigger for PR ROE Employee History
*
*	Performs auditing via HQ Master Audit.
*/----------------------------------------------------------------

SET NOCOUNT ON

/* HQ Master Audit entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
SELECT 
	'vPRROEEmployeeHistory', 
	'PRCo: ' + CAST(d.PRCo AS VARCHAR(10)) 
		+ ',  Employee: ' + CAST(d.Employee AS VARCHAR(10))
		+ ', ROEDate: ' + CAST(d.ROEDate AS varchar(10)),
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


CREATE TRIGGER [dbo].[vtPRROEEmployeeHistoryi] 
	ON [dbo].[vPRROEEmployeeHistory] 
	FOR INSERT AS
/*-----------------------------------------------------------------
* Created:		MV	02/14/2013  TFS#40977 PR ROE 
* Modified:		
*
*	Insert trigger for PR ROE Employee History
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------

SET NOCOUNT ON

/* add HQ Master Audit entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
SELECT 
	'vPRROEEmployeeHistory', 
	'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
		+ ',  Employee: ' + CAST(i.Employee AS VARCHAR(10))
		+ ',  ROEDate: ' + CAST(i.ROEDate AS VARCHAR(10)), 
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

CREATE TRIGGER [dbo].[vtPRROEEmployeeHistoryu] 
   ON  [dbo].[vPRROEEmployeeHistory] 
   FOR UPDATE AS 
/*-----------------------------------------------------------------
* Created:		MV	02/14/2013  TFS#40977 PR ROE
* Modified: 
*
*	Update trigger for PR ROE Employee History
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

/* add HQ Master Audit entry */

-- LastName
INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 
		'vPRROEEmployeeHistory', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
		+ ',  Employee: ' + CAST(i.Employee AS VARCHAR(10))
		+ ',  ROEDate: ' + CAST(i.ROEDate AS VARCHAR(10)), 
		i.PRCo, 
		'C',
		'LastName',
		d.LastName,
		i.LastName,
		GETDATE(), 
		SUSER_SNAME() 
	FROM inserted i
        JOIN deleted d ON i.PRCo = d.PRCo AND i.ROEDate = d.ROEDate AND i.Employee = d.Employee
        WHERE ISNULL(i.LastName,'') <> ISNULL(d.LastName,'') 

-- First Name
INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 
		'vPRROEEmployeeHistory', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
		+ ',  Employee: ' + CAST(i.Employee AS VARCHAR(10))
		+ ',  ROEDate: ' + CAST(i.ROEDate AS VARCHAR(10)), 
		i.PRCo, 
		'C',
		'FirstName',
		d.FirstName,
		i.FirstName,
		GETDATE(), 
		SUSER_SNAME() 
	FROM inserted i
        JOIN deleted d ON i.PRCo = d.PRCo AND i.ROEDate = d.ROEDate AND i.Employee = d.Employee
        WHERE ISNULL(i.FirstName,'') <> ISNULL(d.FirstName,'') 
			  
	-- Midlle Initial
INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 
		'vPRROEEmployeeHistory', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
		+ ',  Employee: ' + CAST(i.Employee AS VARCHAR(10))
		+ ',  ROEDate: ' + CAST(i.ROEDate AS VARCHAR(10)), 
		i.PRCo, 
		'C',
		'MiddleInitial',
		d.MiddleInitial,
		i.MiddleInitial,
		GETDATE(), 
		SUSER_SNAME() 
	FROM inserted i
        JOIN deleted d ON i.PRCo = d.PRCo AND i.ROEDate = d.ROEDate AND i.Employee = d.Employee
        WHERE ISNULL(i.MiddleInitial,'') <> ISNULL(d.MiddleInitial,'') 
			  
-- AddressLine1
INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 
		'vPRROEEmployeeHistory', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
		+ ',  Employee: ' + CAST(i.Employee AS VARCHAR(10))
		+ ',  ROEDate: ' + CAST(i.ROEDate AS VARCHAR(10)), 
		i.PRCo, 
		'C',
		'AddressLine1',
		d.[AddressLine1],
		i.[AddressLine1],
		GETDATE(), 
		SUSER_SNAME() 
	FROM inserted i
        JOIN deleted d ON i.PRCo = d.PRCo AND i.ROEDate = d.ROEDate AND i.Employee = d.Employee
        WHERE ISNULL(i.[AddressLine1],'') <> ISNULL(d.[AddressLine1],'') 

-- AddressLine2
INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 
		'vPRROEEmployeeHistory', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
		+ ',  Employee: ' + CAST(i.Employee AS VARCHAR(10))
		+ ',  ROEDate: ' + CAST(i.ROEDate AS VARCHAR(10)), 
		i.PRCo, 
		'C',
		'AddressLine2',
		d.[AddressLine2],
		i.[AddressLine2],
		GETDATE(), 
		SUSER_SNAME() 
	FROM inserted i
        JOIN deleted d ON i.PRCo = d.PRCo AND i.ROEDate = d.ROEDate AND i.Employee = d.Employee
        WHERE ISNULL(i.[AddressLine2],'') <> ISNULL(d.[AddressLine2],'') 

-- AddressLine3
INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 
		'vPRROEEmployeeHistory', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
		+ ',  Employee: ' + CAST(i.Employee AS VARCHAR(10))
		+ ',  ROEDate: ' + CAST(i.ROEDate AS VARCHAR(10)), 
		i.PRCo, 
		'C',
		'AddressLine3',
		d.[AddressLine3],
		i.[AddressLine3],
		GETDATE(), 
		SUSER_SNAME() 
	FROM inserted i
        JOIN deleted d ON i.PRCo = d.PRCo AND i.ROEDate = d.ROEDate AND i.Employee = d.Employee
        WHERE ISNULL(i.[AddressLine3],'') <> ISNULL(d.[AddressLine3],'') 


-- FirstDayWorked
INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 
		'vPRROEEmployeeHistory', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
		+ ',  Employee: ' + CAST(i.Employee AS VARCHAR(10))
		+ ',  ROEDate: ' + CAST(i.ROEDate AS VARCHAR(10)), 
		i.PRCo, 
		'C',
		'FirstDayWorked',
		d.FirstDayWorked,
		i.FirstDayWorked,
		GETDATE(), 
		SUSER_SNAME() 
	FROM inserted i
        JOIN deleted d ON i.PRCo = d.PRCo AND i.ROEDate = d.ROEDate AND i.Employee = d.Employee
        WHERE ISNULL(i.FirstDayWorked,'') <> ISNULL(d.FirstDayWorked,'') 

-- LastDayPaid
INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 
		'vPRROEEmployeeHistory', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
		+ ',  Employee: ' + CAST(i.Employee AS VARCHAR(10))
		+ ',  ROEDate: ' + CAST(i.ROEDate AS VARCHAR(10)), 
		i.PRCo, 
		'C',
		'LastDayPaid',
		d.LastDayPaid,
		i.LastDayPaid,
		GETDATE(), 
		SUSER_SNAME() 
	FROM inserted i
        JOIN deleted d ON i.PRCo = d.PRCo AND i.ROEDate = d.ROEDate AND i.Employee = d.Employee
        WHERE ISNULL(i.LastDayPaid,'') <> ISNULL(d.LastDayPaid,'') 

		-- FinalPayPeriodEndDate
INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 
		'vPRROEEmployeeHistory', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
		+ ',  Employee: ' + CAST(i.Employee AS VARCHAR(10))
		+ ',  ROEDate: ' + CAST(i.ROEDate AS VARCHAR(10)), 
		i.PRCo, 
		'C',
		'FinalPayPeriodEndDate',
		d.FinalPayPeriodEndDate,
		i.FinalPayPeriodEndDate,
		GETDATE(), 
		SUSER_SNAME() 
	FROM inserted i
        JOIN deleted d ON i.PRCo = d.PRCo AND i.ROEDate = d.ROEDate AND i.Employee = d.Employee
        WHERE ISNULL(i.FinalPayPeriodEndDate,'') <> ISNULL(d.FinalPayPeriodEndDate,'') 


-- SIN
INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 
		'vPRROEEmployeeHistory', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
		+ ',  Employee: ' + CAST(i.Employee AS VARCHAR(10))
		+ ',  ROEDate: ' + CAST(i.ROEDate AS VARCHAR(10)), 
		i.PRCo, 
		'C',
		'SIN',
		d.SIN,
		i.SIN,
		GETDATE(), 
		SUSER_SNAME() 
	FROM inserted i
        JOIN deleted d ON i.PRCo = d.PRCo AND i.ROEDate = d.ROEDate AND i.Employee = d.Employee
        WHERE ISNULL(i.SIN,'') <> ISNULL(d.SIN,'') 
			  
-- ROE_SN
INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 
		'vPRROEEmployeeHistory', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
		+ ',  Employee: ' + CAST(i.Employee AS VARCHAR(10))
		+ ',  ROEDate: ' + CAST(i.ROEDate AS VARCHAR(10)), 
		i.PRCo, 
		'C',
		'ROE_SN',
		d.ROE_SN,
		i.ROE_SN,
		GETDATE(), 
		SUSER_SNAME() 
	FROM inserted i
        JOIN deleted d ON i.PRCo = d.PRCo AND i.ROEDate = d.ROEDate AND i.Employee = d.Employee
        WHERE ISNULL(i.ROE_SN,'') <> ISNULL(d.ROE_SN,'')
		
-- EmployeeOccupation
INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 
		'vPRROEEmployeeHistory', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
		+ ',  Employee: ' + CAST(i.Employee AS VARCHAR(10))
		+ ',  ROEDate: ' + CAST(i.ROEDate AS VARCHAR(10)), 
		i.PRCo, 
		'C',
		'EmployeeOccupation',
		d.EmployeeOccupation,
		i.EmployeeOccupation,
		GETDATE(), 
		SUSER_SNAME() 
	FROM inserted i
        JOIN deleted d ON i.PRCo = d.PRCo AND i.ROEDate = d.ROEDate AND i.Employee = d.Employee
        WHERE ISNULL(i.EmployeeOccupation,'') <> ISNULL(d.EmployeeOccupation,'') 
 
		-- ExpectedRecallCode
INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 
		'vPRROEEmployeeHistory', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
		+ ',  Employee: ' + CAST(i.Employee AS VARCHAR(10))
		+ ',  ROEDate: ' + CAST(i.ROEDate AS VARCHAR(10)), 
		i.PRCo, 
		'C',
		'ExpectedRecallCode',
		d.ExpectedRecallCode,
		i.ExpectedRecallCode,
		GETDATE(), 
		SUSER_SNAME() 
	FROM inserted i
        JOIN deleted d ON i.PRCo = d.PRCo AND i.ROEDate = d.ROEDate AND i.Employee = d.Employee
        WHERE ISNULL(i.ExpectedRecallCode,'') <> ISNULL(d.ExpectedRecallCode,'') 

		-- ExpectedRecallDate
INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 
		'vPRROEEmployeeHistory', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
		+ ',  Employee: ' + CAST(i.Employee AS VARCHAR(10))
		+ ',  ROEDate: ' + CAST(i.ROEDate AS VARCHAR(10)), 
		i.PRCo, 
		'C',
		'ExpectedRecallDate',
		d.ExpectedRecallDate,
		i.ExpectedRecallDate,
		GETDATE(), 
		SUSER_SNAME() 
	FROM inserted i
        JOIN deleted d ON i.PRCo = d.PRCo AND i.ROEDate = d.ROEDate AND i.Employee = d.Employee
        WHERE ISNULL(i.ExpectedRecallDate,'') <> ISNULL(d.ExpectedRecallDate,'') 

	--TotalInsurableHours
		INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 
		'vPRROEEmployeeHistory', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
		+ ',  Employee: ' + CAST(i.Employee AS VARCHAR(10))
		+ ',  ROEDate: ' + CAST(i.ROEDate AS VARCHAR(10)), 
		i.PRCo, 
		'C',
		'TotalInsurableHours',
		d.TotalInsurableHours,
		i.TotalInsurableHours,
		GETDATE(), 
		SUSER_SNAME() 
	FROM inserted i
        JOIN deleted d ON i.PRCo = d.PRCo AND i.ROEDate = d.ROEDate AND i.Employee = d.Employee
        WHERE ISNULL(i.TotalInsurableHours,'') <> ISNULL(d.TotalInsurableHours,'') 

			--TotalInsurableEarnings
		INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 
		'vPRROEEmployeeHistory', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
		+ ',  Employee: ' + CAST(i.Employee AS VARCHAR(10))
		+ ',  ROEDate: ' + CAST(i.ROEDate AS VARCHAR(10)), 
		i.PRCo, 
		'C',
		'TotalInsurableEarnings',
		d.TotalInsurableEarnings,
		i.TotalInsurableEarnings,
		GETDATE(), 
		SUSER_SNAME() 
	FROM inserted i
        JOIN deleted d ON i.PRCo = d.PRCo AND i.ROEDate = d.ROEDate AND i.Employee = d.Employee
        WHERE ISNULL(i.TotalInsurableEarnings,'') <> ISNULL(d.TotalInsurableEarnings,'') 

		--ReasonForROE
		INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 
		'vPRROEEmployeeHistory', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
		+ ',  Employee: ' + CAST(i.Employee AS VARCHAR(10))
		+ ',  ROEDate: ' + CAST(i.ROEDate AS VARCHAR(10)), 
		i.PRCo, 
		'C',
		'ReasonForROE',
		d.ReasonForROE,
		i.ReasonForROE,
		GETDATE(), 
		SUSER_SNAME() 
	FROM inserted i
        JOIN deleted d ON i.PRCo = d.PRCo AND i.ROEDate = d.ROEDate AND i.Employee = d.Employee
        WHERE ISNULL(i.ReasonForROE,'') <> ISNULL(d.ReasonForROE,'') 

		--ContactFirstName
		INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 
		'vPRROEEmployeeHistory', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
		+ ',  Employee: ' + CAST(i.Employee AS VARCHAR(10))
		+ ',  ROEDate: ' + CAST(i.ROEDate AS VARCHAR(10)), 
		i.PRCo, 
		'C',
		'ContactFirstName',
		d.ContactFirstName,
		i.ContactFirstName,
		GETDATE(), 
		SUSER_SNAME() 
	FROM inserted i
        JOIN deleted d ON i.PRCo = d.PRCo AND i.ROEDate = d.ROEDate AND i.Employee = d.Employee
        WHERE ISNULL(i.ContactFirstName,'') <> ISNULL(d.ContactFirstName,'') 

		--ContactLastName
		INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 
		'vPRROEEmployeeHistory', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
		+ ',  Employee: ' + CAST(i.Employee AS VARCHAR(10))
		+ ',  ROEDate: ' + CAST(i.ROEDate AS VARCHAR(10)), 
		i.PRCo, 
		'C',
		'ContactLastName',
		d.ContactLastName,
		i.ContactLastName,
		GETDATE(), 
		SUSER_SNAME() 
	FROM inserted i
        JOIN deleted d ON i.PRCo = d.PRCo AND i.ROEDate = d.ROEDate AND i.Employee = d.Employee
        WHERE ISNULL(i.ContactLastName,'') <> ISNULL(d.ContactLastName,'') 

		--ContactAreaCode
		INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 
		'vPRROEEmployeeHistory', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
		+ ',  Employee: ' + CAST(i.Employee AS VARCHAR(10))
		+ ',  ROEDate: ' + CAST(i.ROEDate AS VARCHAR(10)), 
		i.PRCo, 
		'C',
		'ContactAreaCode',
		d.ContactAreaCode,
		i.ContactAreaCode,
		GETDATE(), 
		SUSER_SNAME() 
	FROM inserted i
        JOIN deleted d ON i.PRCo = d.PRCo AND i.ROEDate = d.ROEDate AND i.Employee = d.Employee
        WHERE ISNULL(i.ContactAreaCode,'') <> ISNULL(d.ContactAreaCode,'') 

		--ContactPhoneNbr
		INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 
		'vPRROEEmployeeHistory', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
		+ ',  Employee: ' + CAST(i.Employee AS VARCHAR(10))
		+ ',  ROEDate: ' + CAST(i.ROEDate AS VARCHAR(10)), 
		i.PRCo, 
		'C',
		'ContactPhoneNbr',
		d.ContactPhoneNbr,
		i.ContactPhoneNbr,
		GETDATE(), 
		SUSER_SNAME() 
	FROM inserted i
        JOIN deleted d ON i.PRCo = d.PRCo AND i.ROEDate = d.ROEDate AND i.Employee = d.Employee
        WHERE ISNULL(i.ContactPhoneNbr,'') <> ISNULL(d.ContactPhoneNbr,'') 

		--ContactPhoneExt
		INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 
		'vPRROEEmployeeHistory', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
		+ ',  Employee: ' + CAST(i.Employee AS VARCHAR(10))
		+ ',  ROEDate: ' + CAST(i.ROEDate AS VARCHAR(10)), 
		i.PRCo, 
		'C',
		'ContactPhoneExt',
		d.ContactPhoneExt,
		i.ContactPhoneExt,
		GETDATE(), 
		SUSER_SNAME() 
	FROM inserted i
        JOIN deleted d ON i.PRCo = d.PRCo AND i.ROEDate = d.ROEDate AND i.Employee = d.Employee
        WHERE ISNULL(i.ContactPhoneExt,'') <> ISNULL(d.ContactPhoneExt,'') 

		--Comments
		INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 
		'vPRROEEmployeeHistory', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
		+ ',  Employee: ' + CAST(i.Employee AS VARCHAR(10))
		+ ',  ROEDate: ' + CAST(i.ROEDate AS VARCHAR(10)), 
		i.PRCo, 
		'C',
		'Comments',
		d.Comments,
		i.Comments,
		GETDATE(), 
		SUSER_SNAME() 
	FROM inserted i
        JOIN deleted d ON i.PRCo = d.PRCo AND i.ROEDate = d.ROEDate AND i.Employee = d.Employee
        WHERE ISNULL(i.Comments,'') <> ISNULL(d.Comments,'') 

		--AmendedDate
		INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 
		'vPRROEEmployeeHistory', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
		+ ',  Employee: ' + CAST(i.Employee AS VARCHAR(10))
		+ ',  ROEDate: ' + CAST(i.ROEDate AS VARCHAR(10)), 
		i.PRCo, 
		'C',
		'AmendedDate',
		d.AmendedDate,
		i.AmendedDate,
		GETDATE(), 
		SUSER_SNAME() 
	FROM inserted i
        JOIN deleted d ON i.PRCo = d.PRCo AND i.ROEDate = d.ROEDate AND i.Employee = d.Employee
        WHERE ISNULL(i.AmendedDate,'') <> ISNULL(d.AmendedDate,'') 

		--PayPeriodType
		INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 
		'vPRROEEmployeeHistory', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
		+ ',  Employee: ' + CAST(i.Employee AS VARCHAR(10))
		+ ',  ROEDate: ' + CAST(i.ROEDate AS VARCHAR(10)), 
		i.PRCo, 
		'C',
		'PayPeriodType',
		d.PayPeriodType,
		i.PayPeriodType,
		GETDATE(), 
		SUSER_SNAME() 
	FROM inserted i
        JOIN deleted d ON i.PRCo = d.PRCo AND i.ROEDate = d.ROEDate AND i.Employee = d.Employee
        WHERE ISNULL(i.PayPeriodType,'') <> ISNULL(d.PayPeriodType,'') 

		--Language
		INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 
		'vPRROEEmployeeHistory', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
		+ ',  Employee: ' + CAST(i.Employee AS VARCHAR(10))
		+ ',  ROEDate: ' + CAST(i.ROEDate AS VARCHAR(10)), 
		i.PRCo, 
		'C',
		'Language',
		d.Language,
		i.Language,
		GETDATE(), 
		SUSER_SNAME() 
	FROM inserted i
        JOIN deleted d ON i.PRCo = d.PRCo AND i.ROEDate = d.ROEDate AND i.Employee = d.Employee
        WHERE ISNULL(i.Language,'') <> ISNULL(d.Language,'') 




RETURN
GO
ALTER TABLE [dbo].[vPRROEEmployeeHistory] WITH NOCHECK ADD CONSTRAINT [CK_vPRROEEmployeeHistory_Comments] CHECK (([ReasonForROE]='K' AND [Comments] IS NOT NULL OR [ReasonForROE]<>'K'))
GO
ALTER TABLE [dbo].[vPRROEEmployeeHistory] WITH NOCHECK ADD CONSTRAINT [CK_vPRROEEmployeeHistory_ExpectedRecallCode] CHECK (([ExpectedRecallCode]='S' OR [ExpectedRecallCode]='U' OR [ExpectedRecallCode]='N' OR [ExpectedRecallCode]='Y' OR [ExpectedRecallCode] IS NULL))
GO
ALTER TABLE [dbo].[vPRROEEmployeeHistory] WITH NOCHECK ADD CONSTRAINT [CK_vPRROEEmployeeHistory_ExpectedRecallDate] CHECK ((([ExpectedRecallDate] IS NULL AND ([ReasonForROE]='M' OR [ReasonForROE]='G' OR [ReasonForROE]='E') OR NOT ([ReasonForROE]='M' OR [ReasonForROE]='G' OR [ReasonForROE]='E')) AND ([ExpectedRecallDate] IS NOT NULL AND [ExpectedRecallCode]='Y' OR isnull([ExpectedRecallCode],'')<>'Y') AND ([ExpectedRecallDate] IS NOT NULL AND [ExpectedRecallDate]>[LastDayPaid] OR [ExpectedRecallDate] IS NULL)))
GO
ALTER TABLE [dbo].[vPRROEEmployeeHistory] WITH NOCHECK ADD CONSTRAINT [CK_vPRROEEmployeeHistory_Language] CHECK (([Language]='F' OR [Language]='E' OR [Language] IS NULL))
GO
ALTER TABLE [dbo].[vPRROEEmployeeHistory] WITH NOCHECK ADD CONSTRAINT [CK_vPRROEEmployeeHistory_ReasonForROE] CHECK (([ReasonForROE]='Z' OR [ReasonForROE]='P' OR [ReasonForROE]='N' OR [ReasonForROE]='M' OR [ReasonForROE]='K' OR [ReasonForROE]='J' OR [ReasonForROE]='H' OR [ReasonForROE]='G' OR [ReasonForROE]='F' OR [ReasonForROE]='E' OR [ReasonForROE]='D' OR [ReasonForROE]='C' OR [ReasonForROE]='B' OR [ReasonForROE]='A'))
GO
ALTER TABLE [dbo].[vPRROEEmployeeHistory] ADD CONSTRAINT [PK_vPRROEEmployeeHistory_KeyID] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_vPRROEEmployeeHistory_PRCo_Employee_FirstDayWorked_LastDayPaid] ON [dbo].[vPRROEEmployeeHistory] ([PRCo], [Employee], [FirstDayWorked], [LastDayPaid]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_vPRROEEmployeeHistory_PRCo_Employee_ROEDate] ON [dbo].[vPRROEEmployeeHistory] ([PRCo], [Employee], [ROEDate]) ON [PRIMARY]
GO
