CREATE TABLE [dbo].[vPRAUEmployer]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[TaxYear] [char] (4) COLLATE Latin1_General_BIN NOT NULL,
[BranchNumber] [varchar] (3) COLLATE Latin1_General_BIN NULL,
[BeginDate] [smalldatetime] NULL,
[EndDate] [smalldatetime] NULL,
[AuthorizedPerson] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[ReportDate] [smalldatetime] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[ContactFax] [dbo].[bPhone] NULL,
[LockPAYGTaxYear] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vPRAUEmployer_LockPAYGTaxYear] DEFAULT ('N')
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtPRAUEmployerd] 
   ON  [dbo].[vPRAUEmployer] 
   FOR DELETE AS 
/*-----------------------------------------------------------------
* Created:		EN	12/03/2010	#127269
* Modified: 
*
*	Update trigger for PR Australian Header table
*
*	Performs auditing via HQ Master Audit.
*/----------------------------------------------------------------

SET NOCOUNT ON

/* HQ Master Audit entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
SELECT 
	'vPRAUEmployer', 
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
CREATE TRIGGER [dbo].[vtPRAUEmployeri] 
	ON [dbo].[vPRAUEmployer] 
	FOR INSERT AS
/*-----------------------------------------------------------------
* Created:		EN	12/02/2010	#127269
* Modified: 
*
*	Insert trigger for PR Australian Header table
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------

SET NOCOUNT ON
 
/* add HQ Master Audit entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
SELECT 
	'vPRAUEmployer', 
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
CREATE TRIGGER [dbo].[vtPRAUEmployeru] 
   ON  [dbo].[vPRAUEmployer] 
   FOR UPDATE AS 
/*-----------------------------------------------------------------
* Created:		EN	12/02/2010	#127269
* Modified:		EN	3/17/2011 #127269/TK-02739 Modified list of fields to check
*				CHS	04/19/2011	TK-04337 - added Lock PAYG Tax Year
*	Update trigger for PR Australian Header table
*
*	Performs auditing via HQ Master Audit.
*/----------------------------------------------------------------

SET NOCOUNT ON

 /* add HQ Master Audit entry */
IF UPDATE(BranchNumber)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployer', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'BranchNumber', 
		d.BranchNumber, 
		i.BranchNumber, 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.BranchNumber, '') <> ISNULL(d.BranchNumber, '') AND a.W2AuditYN = 'Y'
END	

IF UPDATE(BeginDate)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployer', 
		'PR Co#: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear,
		i.PRCo, 
		'C', 
		'BeginDate', 
		CONVERT(VARCHAR,d.BeginDate,101), 
		CONVERT(VARCHAR,i.BeginDate,101), 
		GETDATE(), 
		SUSER_SNAME()
    FROM INSERTED i
        JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear
        JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.BeginDate,'') <> ISNULL(d.BeginDate,'') AND a.W2AuditYN = 'Y'
END

IF UPDATE(EndDate)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployer', 
		'PR Co#: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear,
		i.PRCo, 
		'C', 
		'EndDate', 
		CONVERT(VARCHAR,d.EndDate,101), 
		CONVERT(VARCHAR,i.EndDate,101), 
		GETDATE(), 
		SUSER_SNAME()
    FROM INSERTED i
        JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear
        JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.EndDate,'') <> ISNULL(d.EndDate,'') AND a.W2AuditYN = 'Y'
END

IF UPDATE(AuthorizedPerson)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployer', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'AuthorizedPerson', 
		d.AuthorizedPerson, 
		i.AuthorizedPerson, 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear
		JOIN dbo.bPRCO a (nolock) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.AuthorizedPerson, '') <> ISNULL(d.AuthorizedPerson, '') AND a.W2AuditYN = 'Y'
END	

IF UPDATE(ReportDate)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployer', 
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

IF UPDATE(ContactFax)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployer', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'ContactFax', 
		d.ContactFax, 
		i.ContactFax, 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.ContactFax, '') <> ISNULL(d.ContactFax, '') AND a.W2AuditYN = 'Y'
END

IF UPDATE(LockPAYGTaxYear)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployer', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'LockPAYGTaxYear', 
		d.LockPAYGTaxYear, 
		i.LockPAYGTaxYear, 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.LockPAYGTaxYear, '') <> ISNULL(d.LockPAYGTaxYear, '') AND a.W2AuditYN = 'Y'
END
	
RETURN

GO
ALTER TABLE [dbo].[vPRAUEmployer] ADD CONSTRAINT [PK_vPRAUEmployer_PRCo_TaxYear] PRIMARY KEY NONCLUSTERED  ([PRCo], [TaxYear]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_vPRAUEmployer_KeyID] ON [dbo].[vPRAUEmployer] ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [IX_vPRAUEmployer_] ON [dbo].[vPRAUEmployer] ([PRCo], [TaxYear]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPRAUEmployer] WITH NOCHECK ADD CONSTRAINT [FK_bPRCO_vPRAUEmployer_PRCo] FOREIGN KEY ([PRCo]) REFERENCES [dbo].[bPRCO] ([PRCo])
GO
ALTER TABLE [dbo].[vPRAUEmployer] WITH NOCHECK ADD CONSTRAINT [FK_vPRAUEmployer_vPRAUEmployerMaster] FOREIGN KEY ([PRCo], [TaxYear]) REFERENCES [dbo].[vPRAUEmployerMaster] ([PRCo], [TaxYear])
GO
ALTER TABLE [dbo].[vPRAUEmployer] NOCHECK CONSTRAINT [FK_bPRCO_vPRAUEmployer_PRCo]
GO
ALTER TABLE [dbo].[vPRAUEmployer] NOCHECK CONSTRAINT [FK_vPRAUEmployer_vPRAUEmployerMaster]
GO
