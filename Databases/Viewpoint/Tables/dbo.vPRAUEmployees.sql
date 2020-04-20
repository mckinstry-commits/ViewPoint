CREATE TABLE [dbo].[vPRAUEmployees]
(
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[PRCo] [dbo].[bCompany] NOT NULL,
[TaxYear] [char] (4) COLLATE Latin1_General_BIN NOT NULL,
[Employee] [dbo].[bEmployee] NOT NULL,
[Surname] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[GivenName] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[Address] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[City] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[State] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[Postcode] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[BirthDate] [smalldatetime] NULL,
[TaxFileNumber] [varchar] (11) COLLATE Latin1_General_BIN NOT NULL,
[PensionAnnuity] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vPRAUEmployees_PensionAnnuity] DEFAULT ('N'),
[AmendedReport] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vPRAUEmployees_AmendedReport] DEFAULT ('N'),
[AmendedEFile] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vPRAUEmployees_AmendedEFile] DEFAULT ('N'),
[UniqueAttchID] [uniqueidentifier] NULL
) ON [PRIMARY]
ALTER TABLE [dbo].[vPRAUEmployees] WITH NOCHECK ADD
CONSTRAINT [FK_bPREH_vPRAUEmployees_Employee] FOREIGN KEY ([PRCo], [Employee]) REFERENCES [dbo].[bPREH] ([PRCo], [Employee])
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[vtPRAUEmployeesd] 
   ON  [dbo].[vPRAUEmployees] 
   FOR DELETE AS 
/*-----------------------------------------------------------------
* Created:		LS	2/23/2011	#127269
* Modified:		
*
*	Delete trigger for PR Australia PAYG Employees
*
*	Performs auditing via HQ Master Audit.
*/----------------------------------------------------------------

SET NOCOUNT ON

/* HQ Master Audit entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
SELECT 
	'vPRAUEmployees', 
	'PRCo: ' + CAST(d.PRCo AS VARCHAR(10)) 
		+ ',  Tax Year: ' + d.TaxYear 
		+ ',  Employee: ' + CAST(d.Employee AS VARCHAR(10)),  
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


CREATE TRIGGER [dbo].[vtPRAUEmployeesi] 
	ON [dbo].[vPRAUEmployees] 
	FOR INSERT AS
/*-----------------------------------------------------------------
* Created:		LS	2/23/2011	#127269
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
	'vPRAUEmployees', 
	'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
		+ ',  Tax Year: ' + i.TaxYear 
		+ ',  Employee: ' + CAST(i.Employee AS VARCHAR(10)), 
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

CREATE TRIGGER [dbo].[vtPRAUEmployeesu] 
   ON  [dbo].[vPRAUEmployees] 
   FOR UPDATE AS 
/*-----------------------------------------------------------------
* Created:		LS	2/23/2011	#127269
* Modified: 
*
*	Update trigger for PR Australia PAYG Employees
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

/* add HQ Master Audit entry */

-- Surname Field (Last Name)
INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 
		'vPRAUEmployees', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
		+ ',  Tax Year: ' + i.TaxYear 
		+ ',  Employee: ' + CAST(i.Employee AS VARCHAR(10)),
		i.PRCo, 
		'C',
		'Surname',
		d.Surname,
		i.Surname,
		GETDATE(), 
		SUSER_SNAME() 
	FROM inserted i
        JOIN deleted d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear AND i.Employee = d.Employee
        JOIN dbo.bPRCO c (NOLOCK) ON i.PRCo = c.PRCo
        WHERE ISNULL(i.Surname,'') <> ISNULL(d.Surname,'') 
			  AND c.W2AuditYN = 'Y'

-- Given Name (First Name)
INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 
		'vPRAUEmployees', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
		+ ',  Tax Year: ' + i.TaxYear 
		+ ',  Employee: ' + CAST(i.Employee AS VARCHAR(10)),
		i.PRCo, 
		'C',
		'GivenName',
		d.GivenName,
		i.GivenName,
		GETDATE(), 
		SUSER_SNAME() 
	FROM inserted i
        JOIN deleted d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear AND i.Employee = d.Employee
        JOIN dbo.bPRCO c (NOLOCK) ON i.PRCo = c.PRCo
        WHERE ISNULL(i.GivenName,'') <> ISNULL(d.GivenName,'') 
			  AND c.W2AuditYN = 'Y'
			  
-- Address
INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 
		'vPRAUEmployees', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
		+ ',  Tax Year: ' + i.TaxYear 
		+ ',  Employee: ' + CAST(i.Employee AS VARCHAR(10)),
		i.PRCo, 
		'C',
		'Address',
		d.[Address],
		i.[Address],
		GETDATE(), 
		SUSER_SNAME() 
	FROM inserted i
        JOIN deleted d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear AND i.Employee = d.Employee
        JOIN dbo.bPRCO c (NOLOCK) ON i.PRCo = c.PRCo
        WHERE ISNULL(i.[Address],'') <> ISNULL(d.[Address],'') 
			  AND c.W2AuditYN = 'Y'

-- City
INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 
		'vPRAUEmployees', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
		+ ',  Tax Year: ' + i.TaxYear 
		+ ',  Employee: ' + CAST(i.Employee AS VARCHAR(10)),
		i.PRCo, 
		'C',
		'City',
		d.City,
		i.City,
		GETDATE(), 
		SUSER_SNAME() 
	FROM inserted i
        JOIN deleted d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear AND i.Employee = d.Employee
        JOIN dbo.bPRCO c (NOLOCK) ON i.PRCo = c.PRCo
        WHERE ISNULL(i.City,'') <> ISNULL(d.City,'') 
			  AND c.W2AuditYN = 'Y'

-- State
INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 
		'vPRAUEmployees', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
		+ ',  Tax Year: ' + i.TaxYear 
		+ ',  Employee: ' + CAST(i.Employee AS VARCHAR(10)),
		i.PRCo, 
		'C',
		'State',
		d.[State],
		i.[State],
		GETDATE(), 
		SUSER_SNAME() 
	FROM inserted i
        JOIN deleted d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear AND i.Employee = d.Employee
        JOIN dbo.bPRCO c (NOLOCK) ON i.PRCo = c.PRCo
        WHERE ISNULL(i.[State],'') <> ISNULL(d.[State],'') 
			  AND c.W2AuditYN = 'Y'

-- Postcode
INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 
		'vPRAUEmployees', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
		+ ',  Tax Year: ' + i.TaxYear 
		+ ',  Employee: ' + CAST(i.Employee AS VARCHAR(10)),
		i.PRCo, 
		'C',
		'Postcode',
		d.Postcode,
		i.Postcode,
		GETDATE(), 
		SUSER_SNAME() 
	FROM inserted i
        JOIN deleted d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear AND i.Employee = d.Employee
        JOIN dbo.bPRCO c (NOLOCK) ON i.PRCo = c.PRCo
        WHERE ISNULL(i.Postcode,'') <> ISNULL(d.Postcode,'') 
			  AND c.W2AuditYN = 'Y'

-- BirthDate
INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 
		'vPRAUEmployees', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
		+ ',  Tax Year: ' + i.TaxYear 
		+ ',  Employee: ' + CAST(i.Employee AS VARCHAR(10)),
		i.PRCo, 
		'C',
		'BirthDate',
		d.BirthDate,
		i.BirthDate,
		GETDATE(), 
		SUSER_SNAME() 
	FROM inserted i
        JOIN deleted d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear AND i.Employee = d.Employee
        JOIN dbo.bPRCO c (NOLOCK) ON i.PRCo = c.PRCo
        WHERE ISNULL(i.BirthDate,'') <> ISNULL(d.BirthDate,'') 
			  AND c.W2AuditYN = 'Y'

-- Tax File Number
INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 
		'vPRAUEmployees', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
		+ ',  Tax Year: ' + i.TaxYear 
		+ ',  Employee: ' + CAST(i.Employee AS VARCHAR(10)),
		i.PRCo, 
		'C',
		'TaxFileNumber',
		d.TaxFileNumber,
		i.TaxFileNumber,
		GETDATE(), 
		SUSER_SNAME() 
	FROM inserted i
        JOIN deleted d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear AND i.Employee = d.Employee
        JOIN dbo.bPRCO c (NOLOCK) ON i.PRCo = c.PRCo
        WHERE ISNULL(i.TaxFileNumber,'') <> ISNULL(d.TaxFileNumber,'') 
			  AND c.W2AuditYN = 'Y'
			  
-- Pension or Annuity
INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 
		'vPRAUEmployees', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
		+ ',  Tax Year: ' + i.TaxYear 
		+ ',  Employee: ' + CAST(i.Employee AS VARCHAR(10)),
		i.PRCo, 
		'C',
		'PensionAnnuity',
		d.PensionAnnuity,
		i.PensionAnnuity,
		GETDATE(), 
		SUSER_SNAME() 
	FROM inserted i
        JOIN deleted d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear AND i.Employee = d.Employee
        JOIN dbo.bPRCO c (NOLOCK) ON i.PRCo = c.PRCo
        WHERE ISNULL(i.PensionAnnuity,'') <> ISNULL(d.PensionAnnuity,'') 
			  AND c.W2AuditYN = 'Y'
	
-- Amended Report
INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 
		'vPRAUEmployees', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
		+ ',  Tax Year: ' + i.TaxYear 
		+ ',  Employee: ' + CAST(i.Employee AS VARCHAR(10)),
		i.PRCo, 
		'C',
		'AmendedReport',
		d.AmendedReport,
		i.AmendedReport,
		GETDATE(), 
		SUSER_SNAME() 
	FROM inserted i
        JOIN deleted d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear AND i.Employee = d.Employee
        JOIN dbo.bPRCO c (NOLOCK) ON i.PRCo = c.PRCo
        WHERE ISNULL(i.AmendedReport,'') <> ISNULL(d.AmendedReport,'') 
			  AND c.W2AuditYN = 'Y'		  

-- Amended E-File
INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 
		'vPRAUEmployees', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
		+ ',  Tax Year: ' + i.TaxYear 
		+ ',  Employee: ' + CAST(i.Employee AS VARCHAR(10)),
		i.PRCo, 
		'C',
		'AmendedEFile',
		d.AmendedEFile,
		i.AmendedEFile,
		GETDATE(), 
		SUSER_SNAME() 
	FROM inserted i
        JOIN deleted d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear AND i.Employee = d.Employee
        JOIN dbo.bPRCO c (NOLOCK) ON i.PRCo = c.PRCo
        WHERE ISNULL(i.AmendedEFile,'') <> ISNULL(d.AmendedEFile,'') 
			  AND c.W2AuditYN = 'Y'

RETURN



GO
ALTER TABLE [dbo].[vPRAUEmployees] ADD CONSTRAINT [PK_vPRAUEmployees_KeyID] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_vPRAUEmployees_PRCo_TaxYear_Employee] ON [dbo].[vPRAUEmployees] ([PRCo], [TaxYear], [Employee]) ON [PRIMARY]
GO

ALTER TABLE [dbo].[vPRAUEmployees] WITH NOCHECK ADD CONSTRAINT [FK_vPRAUEmployer_vPRAUEmployees_PRCo_TaxYear] FOREIGN KEY ([PRCo], [TaxYear]) REFERENCES [dbo].[vPRAUEmployer] ([PRCo], [TaxYear])
GO
