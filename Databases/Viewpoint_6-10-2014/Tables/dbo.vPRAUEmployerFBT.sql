CREATE TABLE [dbo].[vPRAUEmployerFBT]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[TaxYear] [char] (4) COLLATE Latin1_General_BIN NOT NULL,
[ContactSurname] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ContactGivenName] [varchar] (15) COLLATE Latin1_General_BIN NULL,
[ContactGivenName2] [varchar] (22) COLLATE Latin1_General_BIN NULL,
[ContactPhone] [dbo].[bPhone] NULL,
[ContactEmail] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[NbrOfEmployeesRecFB] [int] NULL,
[HoursToPrepare] [int] NULL,
[LodgingFBTReturnYN] [dbo].[bYN] NOT NULL,
[SignatureOfAuthPerson] [varchar] (35) COLLATE Latin1_General_BIN NULL,
[ReportDate] [dbo].[bDate] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[UniqueAttchID] [uniqueidentifier] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[NumberA] [int] NULL,
[NumberB] [int] NULL,
[NumberC] [int] NULL,
[NumberF] [int] NULL,
[NumberG] [int] NULL,
[BASAmount1] [dbo].[bDollar] NULL,
[BASAmount2] [dbo].[bDollar] NULL,
[BASAmount3] [dbo].[bDollar] NULL,
[LockFBTAmounts] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vPRAUEmployerFBT_LockFBTAmounts] DEFAULT ('N'),
[BASAmount4] [dbo].[bDollar] NULL,
[CMAcct] [dbo].[bCMAcct] NULL,
[BSBNumber] [varchar] (6) COLLATE Latin1_General_BIN NULL,
[CMBankAcct] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[CMAUAcctName] [varchar] (26) COLLATE Latin1_General_BIN NULL,
[CMCo] [dbo].[bCompany] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[vtPRAUEmployerFBTd] 
   ON  [dbo].[vPRAUEmployerFBT] 
   FOR DELETE AS 
/*-----------------------------------------------------------------
* Created:		MV	12/13/2010	#142027
* Modified: 
*
*	Update trigger for vPRAUEmployerFBT
*
*	Performs auditing via HQ Master Audit.
*/----------------------------------------------------------------

SET NOCOUNT ON

/* HQ Master Audit entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
SELECT 
	'vPRAUEmployerFBT', 
	'PRCo: ' + CAST(d.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + d.TaxYear, 
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


CREATE TRIGGER [dbo].[vtPRAUEmployerFBTi] 
	ON [dbo].[vPRAUEmployerFBT] 
	FOR INSERT AS
/*-----------------------------------------------------------------
* Created:		MV	12/13/2010	#142027
* Modified: 
*
*	Insert trigger for vPRAUEmployerFBT
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------

SET NOCOUNT ON
 
/* add HQ Master Audit entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
SELECT 
	'vPRAUEmployerFBT', 
	'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear, 
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


CREATE TRIGGER [dbo].[vtPRAUEmployerFBTu] 
   ON  [dbo].[vPRAUEmployerFBT] 
   FOR UPDATE AS 
/*-----------------------------------------------------------------
* Created:		MV	12/13/2010	#142027
* Modified:		MV	01/26/11	#142027 added new columns
*				CHS 02/23/2011	#142027 removed columns
*				MV	03/17/11	added CM columns
*
*	Update trigger for vPRAUEmployerFBT update
*
*	Performs auditing via HQ Master Audit.
*/----------------------------------------------------------------

SET NOCOUNT ON

 /* add HQ Master Audit entry */

IF UPDATE(ContactSurname)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerFBT', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'Contact Surname', 
		d.ContactSurname, 
		i.ContactSurname, 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.ContactSurname, '') <> ISNULL(d.ContactSurname, '') AND a.W2AuditYN = 'Y'
END	

IF UPDATE(ContactGivenName)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerFBT', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'Contact Given Name', 
		d.ContactGivenName, 
		i.ContactGivenName, 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.ContactGivenName, '') <> ISNULL(d.ContactGivenName, '') AND a.W2AuditYN = 'Y'
END	

IF UPDATE(ContactGivenName2)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerFBT', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'Addl Contact Names', 
		d.ContactGivenName2, 
		i.ContactGivenName2, 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.ContactGivenName2, '') <> ISNULL(d.ContactGivenName2, '') AND a.W2AuditYN = 'Y'
END	

IF UPDATE(ContactPhone)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerFBT', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'Contact hone', 
		d.ContactPhone, 
		i.ContactPhone, 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.ContactPhone, '') <> ISNULL(d.ContactPhone, '') AND a.W2AuditYN = 'Y'
END	

IF UPDATE(ContactEmail)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerFBT', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'Contact Email', 
		d.ContactEmail, 
		i.ContactEmail, 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.ContactEmail, '') <> ISNULL(d.ContactEmail, '') AND a.W2AuditYN = 'Y'
END	

IF UPDATE(NbrOfEmployeesRecFB)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerFBT', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'# of Employees Receiving FB', 
		CAST(d.NbrOfEmployeesRecFB AS VARCHAR(10)), 
		CAST(i.NbrOfEmployeesRecFB AS VARCHAR(10)), 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.NbrOfEmployeesRecFB, '') <> ISNULL(d.NbrOfEmployeesRecFB, '') AND a.W2AuditYN = 'Y'
END

IF UPDATE(HoursToPrepare)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerFBT', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'Hours To Prepare', 
		CAST(d.HoursToPrepare AS VARCHAR(10)), 
		CAST(i.HoursToPrepare AS VARCHAR(10)), 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.HoursToPrepare, '') <> ISNULL(d.HoursToPrepare, '') AND a.W2AuditYN = 'Y'
END

IF UPDATE(LodgingFBTReturnYN)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerFBT', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'Lodging FBT Return', 
		d.LodgingFBTReturnYN, 
		i.LodgingFBTReturnYN, 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.LodgingFBTReturnYN, '') <> ISNULL(d.LodgingFBTReturnYN, '') AND a.W2AuditYN = 'Y'
END	

IF UPDATE(SignatureOfAuthPerson)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerFBT', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'Signature of Auth Person', 
		d.SignatureOfAuthPerson, 
		i.SignatureOfAuthPerson, 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear
		JOIN dbo.bPRCO a (nolock) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.SignatureOfAuthPerson, '') <> ISNULL(d.SignatureOfAuthPerson, '') AND a.W2AuditYN = 'Y'
END	

IF UPDATE(ReportDate)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerFBT', 
		'PR Co#: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear,
		i.PRCo, 
		'C', 
		'EndDate', 
		CONVERT(VARCHAR,d.ReportDate,101), 
		CONVERT(VARCHAR,i.ReportDate,101), 
		GETDATE(), 
		SUSER_SNAME()
    FROM INSERTED i
        JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear
        JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.ReportDate,'') <> ISNULL(d.ReportDate,'') AND a.W2AuditYN = 'Y'
END

IF UPDATE(NumberA)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerFBT', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'Number A', 
		CAST(d.NumberA AS VARCHAR(10)), 
		CAST(i.NumberA AS VARCHAR(10)), 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.NumberA, '') <> ISNULL(d.NumberA, '') AND a.W2AuditYN = 'Y'
END       

IF UPDATE(NumberB)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerFBT', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'Number B', 
		CAST(d.NumberB AS VARCHAR(10)), 
		CAST(i.NumberB AS VARCHAR(10)), 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.NumberB, '') <> ISNULL(d.NumberB, '') AND a.W2AuditYN = 'Y'
END
 
IF UPDATE(NumberC)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerFBT', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'Number C', 
		CAST(d.NumberC AS VARCHAR(10)), 
		CAST(i.NumberC AS VARCHAR(10)), 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.NumberC, '') <> ISNULL(d.NumberC, '') AND a.W2AuditYN = 'Y'
END           

IF UPDATE(NumberF)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerFBT', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'Number F', 
		CAST(d.NumberF AS VARCHAR(10)), 
		CAST(i.NumberF AS VARCHAR(10)), 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.NumberF, '') <> ISNULL(d.NumberF, '') AND a.W2AuditYN = 'Y'
END 

IF UPDATE(NumberG)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerFBT', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'Number G', 
		CAST(d.NumberG AS VARCHAR(10)), 
		CAST(i.NumberG AS VARCHAR(10)), 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.NumberG, '') <> ISNULL(d.NumberG, '') AND a.W2AuditYN = 'Y'
END 

IF UPDATE(BASAmount1)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerFBT', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'BAS Amount 1', 
		CAST(d.BASAmount1 AS VARCHAR(16)), 
		CAST(i.BASAmount1 AS VARCHAR(16)), 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.BASAmount1, 0) <> ISNULL(d.BASAmount1,0) AND  a.W2AuditYN = 'Y'
END 

IF UPDATE(BASAmount2)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerFBT', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'BAS Amount 2', 
		CAST(d.BASAmount2 AS VARCHAR(16)), 
		CAST(i.BASAmount2 AS VARCHAR(16)), 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.BASAmount2, 0) <> ISNULL(d.BASAmount2, 0) AND a.W2AuditYN = 'Y'
END 

IF UPDATE(BASAmount3)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerFBT', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'BAS Amount 3', 
		CAST(d.BASAmount3 AS VARCHAR(16)), 
		CAST(i.BASAmount3 AS VARCHAR(16)), 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.BASAmount3, 0) <> ISNULL(d.BASAmount3, 0) AND a.W2AuditYN = 'Y'
END 

IF UPDATE(BASAmount4)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerFBT', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'BAS Amount 4', 
		CAST(d.BASAmount4 AS VARCHAR(16)), 
		CAST(i.BASAmount4 AS VARCHAR(16)), 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.BASAmount4, 0) <> ISNULL(d.BASAmount4, 0) AND a.W2AuditYN = 'Y'
END 

IF UPDATE(LockFBTAmounts)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerFBT', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'Lock FBT Amounts', 
		d.LockFBTAmounts, 
		i.LockFBTAmounts, 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.LockFBTAmounts, 0) <> ISNULL(d.LockFBTAmounts, 0) AND a.W2AuditYN = 'Y'
END 

IF UPDATE(CMAcct)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerFBT', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'CM Acct', 
		CAST(d.CMAcct AS VARCHAR(10)), 
		CAST(i.CMAcct AS VARCHAR(10)), 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.CMAcct, 0) <> ISNULL(d.CMAcct, 0) AND a.W2AuditYN = 'Y'
END 

IF UPDATE(BSBNumber)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerFBT', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'CM BSB Number', 
		d.BSBNumber, 
		i.BSBNumber, 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.BSBNumber, '') <> ISNULL(d.BSBNumber, '') AND a.W2AuditYN = 'Y'
END 

IF UPDATE(CMBankAcct)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerFBT', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'CM BankAcct', 
		d.CMBankAcct, 
		i.CMBankAcct, 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.CMBankAcct, '') <> ISNULL(d.CMBankAcct, '') AND a.W2AuditYN = 'Y'
END 

IF UPDATE(CMAUAcctName)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerFBT', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'CM AUAcctName', 
		d.CMAUAcctName, 
		i.CMAUAcctName, 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.CMAUAcctName, '') <> ISNULL(d.CMAUAcctName, '') AND a.W2AuditYN = 'Y'
END

RETURN



GO
ALTER TABLE [dbo].[vPRAUEmployerFBT] ADD CONSTRAINT [PK_bPRAUEmployerFBT] PRIMARY KEY CLUSTERED  ([PRCo], [TaxYear]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPRAUEmployerFBT] WITH NOCHECK ADD CONSTRAINT [FK_vPRAUEmployerFBT_vPRAUEmployerMaster] FOREIGN KEY ([PRCo], [TaxYear]) REFERENCES [dbo].[vPRAUEmployerMaster] ([PRCo], [TaxYear])
GO
ALTER TABLE [dbo].[vPRAUEmployerFBT] NOCHECK CONSTRAINT [FK_vPRAUEmployerFBT_vPRAUEmployerMaster]
GO
