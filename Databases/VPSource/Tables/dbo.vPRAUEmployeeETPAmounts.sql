CREATE TABLE [dbo].[vPRAUEmployeeETPAmounts]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[TaxYear] [char] (4) COLLATE Latin1_General_BIN NOT NULL,
[Employee] [dbo].[bEmployee] NOT NULL,
[Seq] [int] NOT NULL,
[Address] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[City] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[State] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[Postcode] [dbo].[bZip] NULL,
[DateofBirth] [dbo].[bDate] NULL,
[DateOfPayment] [dbo].[bDate] NULL,
[TaxFileNumber] [varchar] (11) COLLATE Latin1_General_BIN NULL,
[TotalTaxWithheld] [dbo].[bDollar] NULL,
[TaxableComponent] [dbo].[bDollar] NULL,
[TaxFreeComponent] [dbo].[bDollar] NULL,
[TransitionalPaymentYN] [dbo].[bYN] NULL,
[PartialPaymentYN] [dbo].[bYN] NULL,
[DeathBenefitYN] [dbo].[bYN] NULL,
[DeathBenefitType] [char] (1) COLLATE Latin1_General_BIN NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[UniqueAttchID] [uniqueidentifier] NULL,
[Amended] [dbo].[bYN] NOT NULL CONSTRAINT [DF__vPRAUEmpl__Amend__2E1A775E] DEFAULT ('N'),
[AmendedATO] [dbo].[bYN] NOT NULL CONSTRAINT [DF__vPRAUEmpl__Amend__2F0E9B97] DEFAULT ('N'),
[CompleteYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF__vPRAUEmpl__Compl__3002BFD0] DEFAULT ('N'),
[GivenName2] [varchar] (22) COLLATE Latin1_General_BIN NULL,
[Surname] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[GivenName] [varchar] (15) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtPRAUEmployeeETPAmountsd] 
   ON  [dbo].[vPRAUEmployeeETPAmounts] 
   FOR DELETE AS 
/*-----------------------------------------------------------------
* Created:		MV	03/29/11 PR AU ETP Epic
* Modified: 
*
*	Update trigger for vPRAUEmployeeETPAmounts
*
*	Performs auditing via HQ Master Audit.
*/----------------------------------------------------------------

SET NOCOUNT ON

/* HQ Master Audit entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
SELECT 
	'vPRAUEmployeeETPAmounts', 
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
CREATE TRIGGER [dbo].[vtPRAUEmployeeETPAmountsi] 
	ON [dbo].[vPRAUEmployeeETPAmounts] 
	FOR INSERT AS
/*-----------------------------------------------------------------
* Created:		MV	03/29/11 PR AU ETP Epic
* Modified: 
*
*	Insert trigger for vPRAUEmployeeETPAmounts
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------

SET NOCOUNT ON
 
/* add HQ Master Audit entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
SELECT 
	'vPRAUEmployeeETPAmounts', 
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
CREATE TRIGGER [dbo].[vtPRAUEmployeeETPAmountsu] 
   ON  [dbo].[vPRAUEmployeeETPAmounts] 
   FOR UPDATE AS 
/*-----------------------------------------------------------------
* Created:		MV	03/29/11 PR AU ETP Epic	
* Modified:		
*				
*
*	Update trigger for vPRAUEmployeeETPAmounts update
*
*	Performs auditing via HQ Master Audit.
*/----------------------------------------------------------------

SET NOCOUNT ON

 /* add HQ Master Audit entry */

IF UPDATE(Surname)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployeeETPAmounts', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'Surname', 
		d.Surname, 
		i.Surname, 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.Surname, '') <> ISNULL(d.Surname, '') AND a.W2AuditYN = 'Y'
END	

IF UPDATE(GivenName)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployeeETPAmounts', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'Given Name', 
		d.GivenName, 
		i.GivenName, 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.GivenName, '') <> ISNULL(d.GivenName, '') AND a.W2AuditYN = 'Y'
END	

IF UPDATE(GivenName2)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployeeETPAmounts', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'Given Name 2', 
		d.GivenName2, 
		i.GivenName2, 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.GivenName2, '') <> ISNULL(d.GivenName2, '') AND a.W2AuditYN = 'Y'
END	

IF UPDATE(Address)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployeeETPAmounts', 
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

IF UPDATE(City)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployeeETPAmounts', 
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
		'vPRAUEmployeeETPAmounts', 
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
IF UPDATE(Postcode)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployeeETPAmounts', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'Post code', 
		d.Postcode, 
		i.Postcode, 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.Postcode, '') <> ISNULL(d.Postcode, '') AND a.W2AuditYN = 'Y'
END	

IF UPDATE(DateofBirth)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployeeETPAmounts', 
		'PR Co#: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear,
		i.PRCo, 
		'C', 
		'DateofBirth', 
		CONVERT(VARCHAR,d.DateofBirth,101), 
		CONVERT(VARCHAR,i.DateofBirth,101), 
		GETDATE(), 
		SUSER_SNAME()
    FROM INSERTED i
        JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear
        JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.DateofBirth,'') <> ISNULL(d.DateofBirth,'') AND a.W2AuditYN = 'Y'
END

IF UPDATE(DateOfPayment)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployeeETPAmounts', 
		'PR Co#: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear,
		i.PRCo, 
		'C', 
		'DateOfPayment', 
		CONVERT(VARCHAR,d.DateOfPayment,101), 
		CONVERT(VARCHAR,i.DateOfPayment,101), 
		GETDATE(), 
		SUSER_SNAME()
    FROM INSERTED i
        JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear
        JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.DateOfPayment,'') <> ISNULL(d.DateOfPayment,'') AND a.W2AuditYN = 'Y'
END

IF UPDATE(TaxFileNumber)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployeeETPAmounts', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'TaxFileNumber', 
		d.TaxFileNumber, 
		i.TaxFileNumber, 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.TaxFileNumber, '') <> ISNULL(d.TaxFileNumber, '') AND a.W2AuditYN = 'Y'
END	

IF UPDATE(TotalTaxWithheld)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployeeETPAmounts', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'TotalTaxWithheld', 
		CAST(d.TotalTaxWithheld AS VARCHAR(16)), 
		CAST(i.TotalTaxWithheld AS VARCHAR(16)), 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.TotalTaxWithheld, 0) <> ISNULL(d.TotalTaxWithheld,0) AND  a.W2AuditYN = 'Y'
END 

IF UPDATE(TaxableComponent)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployeeETPAmounts', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'TaxableComponent', 
		CAST(d.TaxableComponent AS VARCHAR(16)), 
		CAST(i.TaxableComponent AS VARCHAR(16)), 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.TaxableComponent, 0) <> ISNULL(d.TaxableComponent,0) AND  a.W2AuditYN = 'Y'
END 

IF UPDATE(TaxFreeComponent)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployeeETPAmounts', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'TaxFreeComponent', 
		CAST(d.TaxFreeComponent AS VARCHAR(16)), 
		CAST(i.TaxFreeComponent AS VARCHAR(16)), 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.TaxFreeComponent, 0) <> ISNULL(d.TaxFreeComponent,0) AND  a.W2AuditYN = 'Y'
END 


IF UPDATE(TransitionalPaymentYN)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployeeETPAmounts', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'TransitionalPaymentYN', 
		d.TransitionalPaymentYN, 
		i.TransitionalPaymentYN, 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.TransitionalPaymentYN, '') <> ISNULL(d.TransitionalPaymentYN, '') AND a.W2AuditYN = 'Y'
END	

IF UPDATE(PartialPaymentYN)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployeeETPAmounts', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'PartialPaymentYN', 
		d.PartialPaymentYN, 
		i.PartialPaymentYN, 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.PartialPaymentYN, '') <> ISNULL(d.PartialPaymentYN, '') AND a.W2AuditYN = 'Y'
END	

IF UPDATE(DeathBenefitYN)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployeeETPAmounts', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'DeathBenefitYN', 
		d.DeathBenefitYN, 
		i.DeathBenefitYN, 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.DeathBenefitYN, '') <> ISNULL(d.DeathBenefitYN, '') AND a.W2AuditYN = 'Y'
END	

IF UPDATE(DeathBenefitType)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployeeETPAmounts', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'DeathBenefitType', 
		d.DeathBenefitType, 
		i.DeathBenefitType, 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.DeathBenefitType, '') <> ISNULL(d.DeathBenefitType, '') AND a.W2AuditYN = 'Y'
END	

IF UPDATE(CompleteYN)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployeeETPAmounts', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'CompleteYN', 
		d.CompleteYN, 
		i.CompleteYN, 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.CompleteYN, '') <> ISNULL(d.CompleteYN, '') AND a.W2AuditYN = 'Y'
END	

IF UPDATE(Amended)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployeeETPAmounts', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'Amended', 
		d.Amended, 
		i.Amended, 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.Amended, '') <> ISNULL(d.Amended, '') AND a.W2AuditYN = 'Y'
END	

IF UPDATE(AmendedATO)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployeeETPAmounts', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear, 
		i.PRCo, 
		'C', 
		'AmendedATO', 
		d.AmendedATO, 
		i.AmendedATO, 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.AmendedATO, '') <> ISNULL(d.AmendedATO, '') AND a.W2AuditYN = 'Y'
END		




RETURN

GO
ALTER TABLE [dbo].[vPRAUEmployeeETPAmounts] ADD CONSTRAINT [PK_vPRAUEmployeeETPAmounts] PRIMARY KEY CLUSTERED  ([PRCo], [TaxYear], [Employee], [Seq]) ON [PRIMARY]
GO
