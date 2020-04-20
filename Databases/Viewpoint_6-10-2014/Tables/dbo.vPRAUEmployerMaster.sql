CREATE TABLE [dbo].[vPRAUEmployerMaster]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[TaxYear] [char] (4) COLLATE Latin1_General_BIN NOT NULL,
[TaxFileNumber] [varchar] (11) COLLATE Latin1_General_BIN NULL,
[ABN] [varchar] (11) COLLATE Latin1_General_BIN NULL,
[CompanyName] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Address] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Address2] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[City] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[State] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[PostalCode] [dbo].[bZip] NULL,
[Country] [varchar] (2) COLLATE Latin1_General_BIN NULL,
[ContactSurname] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ContactGivenName] [varchar] (15) COLLATE Latin1_General_BIN NULL,
[ContactGivenName2] [varchar] (22) COLLATE Latin1_General_BIN NULL,
[ContactPhone] [dbo].[bPhone] NULL,
[ContactEmail] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[SignatureOfAuthPerson] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ReportDate] [dbo].[bDate] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[UniqueAttchID] [uniqueidentifier] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtPRAUEmployerMasterd] 
   ON  [dbo].[vPRAUEmployerMaster] 
   FOR DELETE AS 
/*-----------------------------------------------------------------
* Created:		CHS	02/21/2011	- #142027
* Modified: 
*
*	Update trigger for vtPRAUEmployerMasterd
*
*	Performs auditing via HQ Master Audit.
*/----------------------------------------------------------------

SET NOCOUNT ON

/* HQ Master Audit entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
SELECT 
	'vPRAUEmployerMaster', 
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


CREATE TRIGGER [dbo].[vtPRAUEmployerMasteri] 
	ON [dbo].[vPRAUEmployerMaster] 
	FOR INSERT AS
/*-----------------------------------------------------------------
* Created:		CHS	02/21/2011	- #142027
* Modified: 
*
*	Insert trigger for vPRAUEmployerMaster
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------

SET NOCOUNT ON
 
/* add HQ Master Audit entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
SELECT 
	'vPRAUEmployerMaster', 
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



CREATE TRIGGER [dbo].[vtPRAUEmployerMasteru] 
   ON  [dbo].[vPRAUEmployerMaster] 
   FOR UPDATE AS 
/*-----------------------------------------------------------------
* Created:		CHS	02/21/2011	- #142027
* Modified:
*
*	Update trigger for vPRAUEmployerMaster update
*
*	Performs auditing via HQ Master Audit.
*/----------------------------------------------------------------

SET NOCOUNT ON

 /* add HQ Master Audit entry */
IF UPDATE(TaxFileNumber)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerMaster', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'Tax File Number', 
		d.TaxFileNumber, 
		i.TaxFileNumber, 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.TaxFileNumber, '') <> ISNULL(d.TaxFileNumber, '') AND a.W2AuditYN = 'Y'
END	

IF UPDATE(ABN)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerMaster', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'ABN', 
		d.ABN, 
		i.ABN, 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.ABN, '') <> ISNULL(d.ABN, '') AND a.W2AuditYN = 'Y'
END	

IF UPDATE(CompanyName)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerMaster', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'Company Name', 
		d.CompanyName, 
		i.CompanyName, 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.CompanyName, '') <> ISNULL(d.CompanyName, '') AND a.W2AuditYN = 'Y'
END	

IF UPDATE(Address)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerMaster', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'Address', 
		d.Address, 
		i.Address, 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.Address, '') <> ISNULL(d.Address, '') AND a.W2AuditYN = 'Y'
END

IF UPDATE(Address2)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerMaster', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'Address 2', 
		d.Address2, 
		i.Address2, 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.Address2, '') <> ISNULL(d.Address2, '') AND a.W2AuditYN = 'Y'
END	
	

IF UPDATE(City)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerMaster', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'City', 
		d.City, 
		i.City, 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.City, '') <> ISNULL(d.City, '') AND a.W2AuditYN = 'Y'
END	

IF UPDATE(State)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerMaster', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'State', 
		d.State, 
		i.State, 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.State, '') <> ISNULL(d.State, '') AND a.W2AuditYN = 'Y'
END	

IF UPDATE(PostalCode)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerMaster', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'Postal Code', 
		d.PostalCode, 
		i.PostalCode, 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.PostalCode, '') <> ISNULL(d.PostalCode, '') AND a.W2AuditYN = 'Y'
END	

IF UPDATE(Country)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerMaster', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'Country', 
		d.Country, 
		i.Country, 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.Country, '') <> ISNULL(d.Country, '') AND a.W2AuditYN = 'Y'
END	

IF UPDATE(ContactSurname)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerMaster', 
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
		'vPRAUEmployerMaster', 
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
		'vPRAUEmployerMaster', 
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
		'vPRAUEmployerMaster', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'Contact Phone', 
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
		'vPRAUEmployerMaster', 
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

IF UPDATE(SignatureOfAuthPerson)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerMaster', 
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
		'vPRAUEmployerMaster', 
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

RETURN




GO
ALTER TABLE [dbo].[vPRAUEmployerMaster] ADD CONSTRAINT [PK_bPRAUEmployerMaster] PRIMARY KEY CLUSTERED  ([PRCo], [TaxYear]) ON [PRIMARY]
GO
