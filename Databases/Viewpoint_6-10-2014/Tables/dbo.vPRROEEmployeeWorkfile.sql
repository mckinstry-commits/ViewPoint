CREATE TABLE [dbo].[vPRROEEmployeeWorkfile]
(
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[PRCo] [dbo].[bCompany] NOT NULL,
[Employee] [dbo].[bEmployee] NOT NULL,
[ROEDate] [dbo].[bDate] NOT NULL,
[ProcessYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vPRROEEmployeeWorkfile_ProcessYN] DEFAULT ('N'),
[ReasonForROE] [char] (1) COLLATE Latin1_General_BIN NULL,
[ContactFirstName] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[ContactLastName] [varchar] (28) COLLATE Latin1_General_BIN NULL,
[ContactAreaCode] [varchar] (3) COLLATE Latin1_General_BIN NULL,
[ContactPhoneNbr] [varchar] (8) COLLATE Latin1_General_BIN NULL,
[ContactPhoneExt] [varchar] (5) COLLATE Latin1_General_BIN NULL,
[ExpectedRecallCode] [char] (1) COLLATE Latin1_General_BIN NULL,
[ExpectedRecallDate] [dbo].[bDate] NULL,
[SpecialPaymentsStartDate] [dbo].[bDate] NULL,
[Comments] [varchar] (160) COLLATE Latin1_General_BIN NULL,
[Language] [char] (1) COLLATE Latin1_General_BIN NULL,
[ErrorMessage] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[ValidationTier] [tinyint] NULL,
[VPUserName] [dbo].[bVPUserName] NOT NULL CONSTRAINT [DF_vPRROEEmployeeWorkfile_VPUserName] DEFAULT (suser_sname())
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[vtPRROEEmployeeWorkfiled] 
   ON  [dbo].[vPRROEEmployeeWorkfile] 
   FOR DELETE AS 
/*-----------------------------------------------------------------
* Created:		MV	03/11/2013 TFS#43040 PR ROE Project
* Modified:		
*
*	Delete trigger for PR ROE Employee Workfile
*
*	Performs auditing via HQ Master Audit.
*/----------------------------------------------------------------

SET NOCOUNT ON

/* HQ Master Audit entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
SELECT 
	'vPRROEEmployeeWorkfile', 
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


CREATE TRIGGER [dbo].[vtPRROEEmployeeWorkfilei] 
	ON [dbo].[vPRROEEmployeeWorkfile] 
	FOR INSERT AS
/*-----------------------------------------------------------------
* Created:		MV	03/11/2013  TFS#43040 PR ROE 
* Modified:		
*
*	Insert trigger for PR ROE Employee Workfile
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------

SET NOCOUNT ON

/* add HQ Master Audit entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
SELECT 
	'vPRROEEmployeeWorkfile', 
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

CREATE TRIGGER [dbo].[vtPRROEEmployeeWorkfileu] 
   ON  [dbo].[vPRROEEmployeeWorkfile] 
   FOR UPDATE AS 
/*-----------------------------------------------------------------
* Created:		MV	03/11/2013  TFS#43040 PR ROE Project
* Modified: 
*
*	Update trigger for PR ROE Employee Workfile
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

		-- ExpectedRecallCode
	INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 
		'vPRROEEmployeeWorkfile', 
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
		'vPRROEEmployeeWorkfile', 
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

		--ReasonForROE
	INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 
		'vPRROEEmployeeWorkfile', 
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
		'vPRROEEmployeeWorkfile', 
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
		'vPRROEEmployeeWorkfile', 
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
		'vPRROEEmployeeWorkfile', 
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
		'vPRROEEmployeeWorkfile', 
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
		'vPRROEEmployeeWorkfile', 
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
		'vPRROEEmployeeWorkfile', 
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

		--Language
		INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 
		'vPRROEEmployeeWorkfile', 
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

--SpecialPaymentsStartDate
		INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 
		'vPRROEEmployeeWorkfile', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
		+ ',  Employee: ' + CAST(i.Employee AS VARCHAR(10))
		+ ',  ROEDate: ' + CAST(i.ROEDate AS VARCHAR(10)), 
		i.PRCo, 
		'C',
		'Comments',
		d.SpecialPaymentsStartDate,
		i.SpecialPaymentsStartDate,
		GETDATE(), 
		SUSER_SNAME() 
	FROM inserted i
        JOIN deleted d ON i.PRCo = d.PRCo AND i.ROEDate = d.ROEDate AND i.Employee = d.Employee
        WHERE ISNULL(i.SpecialPaymentsStartDate,'') <> ISNULL(d.SpecialPaymentsStartDate,'') 


RETURN
GO
ALTER TABLE [dbo].[vPRROEEmployeeWorkfile] ADD CONSTRAINT [PK_vPRROEEmployeeWorkfile_KeyID] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_vPRROEEmployeeWorkfile_PRCo_Employee_ROEDate_VPUserName] ON [dbo].[vPRROEEmployeeWorkfile] ([PRCo], [Employee], [ROEDate], [VPUserName]) ON [PRIMARY]
GO
