CREATE TABLE [dbo].[vPRAUEmployerETP]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[TaxYear] [char] (4) COLLATE Latin1_General_BIN NOT NULL,
[BranchNbr] [int] NULL,
[SignatureOfAuthPerson] [varchar] (35) COLLATE Latin1_General_BIN NULL,
[Date] [dbo].[bDate] NULL,
[LockETPAmounts] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vPRAUEmployerETP_LockETPAmounts] DEFAULT ('N'),
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[UniqueAttchID] [uniqueidentifier] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[vtPRAUEmployerETPd] 
   ON  [dbo].[vPRAUEmployerETP] 
   FOR DELETE AS 
/*-----------------------------------------------------------------
* Created:		MV	03/28/2011 PR AU EmployerETP
* Modified: 
*
*	Update trigger for vPRAUEmployerETP
*
*	Performs auditing via HQ Master Audit.
*/----------------------------------------------------------------

SET NOCOUNT ON

/* HQ Master Audit entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
SELECT 
	'vPRAUEmployerETP', 
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


CREATE TRIGGER [dbo].[vtPRAUEmployerETPi] 
	ON [dbo].[vPRAUEmployerETP] 
	FOR INSERT AS
/*-----------------------------------------------------------------
* Created:		MV	03/28/2011 PR AU EmployerETP
* Modified: 
*
*	Insert trigger for vPRAUEmployerETP
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------

SET NOCOUNT ON
 
/* add HQ Master Audit entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
SELECT 
	'vPRAUEmployerETP', 
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


CREATE TRIGGER [dbo].[vtPRAUEmployerETPu] 
   ON  [dbo].[vPRAUEmployerETP] 
   FOR UPDATE AS 
/*-----------------------------------------------------------------
* Created:		MV	03/28/2011 PR AU EmployerETP
* Modified:		
*
*	Update trigger for vPRAUEmployerETP update
*
*	Performs auditing via HQ Master Audit.
*/----------------------------------------------------------------

SET NOCOUNT ON

 /* add HQ Master Audit entry */


IF UPDATE(BranchNbr)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerETP', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'Branch #', 
		CAST(d.BranchNbr AS VARCHAR(16)), 
		CAST(i.BranchNbr AS VARCHAR(16)), 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.BranchNbr, 0) <> ISNULL(d.BranchNbr, 0) AND a.W2AuditYN = 'Y'
END

IF UPDATE(SignatureOfAuthPerson)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerETP', 
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

IF UPDATE(Date)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerETP', 
		'PR Co#: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear,
		i.PRCo, 
		'C', 
		'Date', 
		CONVERT(VARCHAR,d.Date,101), 
		CONVERT(VARCHAR,i.Date,101), 
		GETDATE(), 
		SUSER_SNAME()
    FROM INSERTED i
        JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear
        JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.Date,'') <> ISNULL(d.Date,'') AND a.W2AuditYN = 'Y'
END


IF UPDATE(LockETPAmounts)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerETP', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'Lock ETP Amounts', 
		d.LockETPAmounts, 
		i.LockETPAmounts, 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.LockETPAmounts, 0) <> ISNULL(d.LockETPAmounts, 0) AND a.W2AuditYN = 'Y'
END 

RETURN


GO
ALTER TABLE [dbo].[vPRAUEmployerETP] ADD CONSTRAINT [PK_bPRAUEmployerETP] PRIMARY KEY CLUSTERED  ([PRCo], [TaxYear]) ON [PRIMARY]
GO
