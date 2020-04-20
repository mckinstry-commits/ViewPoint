CREATE TABLE [dbo].[vPRAUEmployerBAS]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[TaxYear] [char] (4) COLLATE Latin1_General_BIN NOT NULL,
[Seq] [int] NOT NULL,
[FormDueOn] [dbo].[bDate] NULL,
[PaymentDueOn] [dbo].[bDate] NULL,
[ContactPerson] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ContactPhone] [dbo].[bPhone] NULL,
[GSTMethod] [int] NULL,
[Signature] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ReportDate] [dbo].[bDate] NULL,
[ReturnCompletedFormTo] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[Hours] [tinyint] NULL,
[Min] [tinyint] NULL,
[GSTStartDate] [dbo].[bMonth] NULL,
[GSTEndDate] [dbo].[bMonth] NULL,
[GSTOption] [tinyint] NULL,
[G1IncludesGST] [dbo].[bYN] NOT NULL,
[G21] [dbo].[bDollar] NULL,
[G22] [dbo].[bDollar] NULL,
[G23] [dbo].[bDollar] NULL,
[G24ReasonCode] [tinyint] NULL,
[PAYGWthStartDate] [dbo].[bMonth] NULL,
[PAYGWthEndDate] [dbo].[bMonth] NULL,
[PAYGWth4] [dbo].[bDollar] NULL,
[PAYGWth3] [dbo].[bDollar] NULL,
[PAYGITaxStartDate] [dbo].[bDate] NULL,
[PAYGITaxEndDate] [dbo].[bDate] NULL,
[PAYGITaxOption] [tinyint] NULL,
[PAYGITaxT7] [dbo].[bDollar] NULL,
[PAYGITaxT8] [dbo].[bDollar] NULL,
[PAYGITaxT9] [dbo].[bDollar] NULL,
[PAYGITaxT1] [dbo].[bDollar] NULL,
[PAYGITaxT2] [dbo].[bPct] NULL,
[PAYGITaxT3] [dbo].[bPct] NULL,
[PAYGITaxT11] [dbo].[bDollar] NULL,
[PAYGITaxT4ReasonCode] [tinyint] NULL,
[FBTStartDate] [dbo].[bDate] NULL,
[FBTEndDate] [dbo].[bDate] NULL,
[FBTF1] [dbo].[bDollar] NULL,
[FBTF2] [dbo].[bDollar] NULL,
[FBTF3] [dbo].[bDollar] NULL,
[FBTF4ReasonCode] [tinyint] NULL,
[Summ1C] [dbo].[bDollar] NULL,
[Summ1E] [dbo].[bDollar] NULL,
[Summ7C] [dbo].[bDollar] NULL,
[Summ1D] [dbo].[bDollar] NULL,
[Summ1F] [dbo].[bDollar] NULL,
[Summ5B] [dbo].[bDollar] NULL,
[Summ6B] [dbo].[bDollar] NULL,
[Summ7D] [dbo].[bDollar] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[UniqueAttchID] [uniqueidentifier] NULL,
[LockBASAmounts] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vPRAUEmployerBAS_LockBASAmounts] DEFAULT ('N')
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[vtPRAUEmployerBASd] 
   ON  [dbo].[vPRAUEmployerBAS] 
   FOR DELETE AS 
/*-----------------------------------------------------------------
* Created:		MV	3/7/2011	#138181
* Modified: 
*
*	Update trigger for vPRAUEmployerBAS
*
*	Performs auditing via HQ Master Audit.
*/----------------------------------------------------------------

SET NOCOUNT ON

/* HQ Master Audit entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
SELECT 
	'vPRAUEmployerBAS', 
	'PRCo: ' + CAST(d.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + d.TaxYear + ', Seq: ' + CAST(d.Seq AS VARCHAR(10)),
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


CREATE TRIGGER [dbo].[vtPRAUEmployerBASi] 
	ON [dbo].[vPRAUEmployerBAS] 
	FOR INSERT AS
/*-----------------------------------------------------------------
* Created:		MV	3/7/2011	#138181
* Modified: 
*
*	Update trigger for vPRAUEmployerBAS
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------

SET NOCOUNT ON
 
/* add HQ Master Audit entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
SELECT 
	'vPRAUEmployerBAS', 
	'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear + ', Seq: ' + CAST(i.Seq AS VARCHAR(10)),
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



CREATE TRIGGER [dbo].[vtPRAUEmployerBASu] 
   ON  [dbo].[vPRAUEmployerBAS] 
   FOR UPDATE AS 
/*-----------------------------------------------------------------
* Created:		MV	3/7/2011	#138181
* Modified: 
*				
*
*	Update trigger for vPRAUEmployerBAS update
*
*	Performs auditing via HQ Master Audit.
*/----------------------------------------------------------------

SET NOCOUNT ON

 /* add HQ Master Audit entry */

IF UPDATE(FormDueOn)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerBAS', 
		'PRCo: ' + CAST(d.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + d.TaxYear + ', Seq: ' + CAST(d.Seq AS VARCHAR(10)),
		i.PRCo, 
		'C', 
		'Form Due On', 
		CAST(d.FormDueOn AS VARCHAR(10)), 
		CAST(i.FormDueOn AS VARCHAR(10)),
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear and i.Seq=d.Seq and i.Seq=d.Seq and i.Seq=d.Seq
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.FormDueOn, '') <> ISNULL(d.FormDueOn, '') AND a.W2AuditYN = 'Y'
END	

IF UPDATE(PaymentDueOn)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerBAS', 
		'PRCo: ' + CAST(d.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + d.TaxYear + ', Seq: ' + CAST(d.Seq AS VARCHAR(10)),
		i.PRCo, 
		'C', 
		'Paymt Due On', 
		CAST(d.PaymentDueOn AS VARCHAR(10)), 
		CAST(i.PaymentDueOn AS VARCHAR(10)),
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear and i.Seq=d.Seq and i.Seq=d.Seq and i.Seq=d.Seq
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.PaymentDueOn, '') <> ISNULL(d.PaymentDueOn, '') AND a.W2AuditYN = 'Y'
END	

IF UPDATE(ContactPerson)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerBAS', 
			'PRCo: ' + CAST(d.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + d.TaxYear + ', Seq: ' + CAST(d.Seq AS VARCHAR(10)),
		i.PRCo, 
		'C', 
		'Contact Person', 
		d.ContactPerson, 
		i.ContactPerson, 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear and i.Seq=d.Seq
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.ContactPerson, '') <> ISNULL(d.ContactPerson, '') AND a.W2AuditYN = 'Y'
END	

IF UPDATE(ContactPhone)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerBAS', 
			'PRCo: ' + CAST(d.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + d.TaxYear + ', Seq: ' + CAST(d.Seq AS VARCHAR(10)),
		i.PRCo, 
		'C', 
		'Contact hone', 
		d.ContactPhone, 
		i.ContactPhone, 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear and i.Seq=d.Seq
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.ContactPhone, '') <> ISNULL(d.ContactPhone, '') AND a.W2AuditYN = 'Y'
END	

IF UPDATE(GSTMethod)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerBAS', 
			'PRCo: ' + CAST(d.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + d.TaxYear + ', Seq: ' + CAST(d.Seq AS VARCHAR(10)),
		i.PRCo, 
		'C', 
		'GST Method', 
		CAST(d.GSTMethod AS VARCHAR(10)), 
		CAST(i.GSTMethod AS VARCHAR(10)), 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear and i.Seq=d.Seq
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.GSTMethod, 0) <> ISNULL(d.GSTMethod, 0) AND a.W2AuditYN = 'Y'
END	

IF UPDATE(Signature)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerBAS', 
			'PRCo: ' + CAST(d.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + d.TaxYear + ', Seq: ' + CAST(d.Seq AS VARCHAR(10)),
		i.PRCo, 
		'C', 
		'Signature', 
		d.Signature, 
		i.Signature, 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear and i.Seq=d.Seq
		JOIN dbo.bPRCO a (nolock) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.Signature, '') <> ISNULL(d.Signature, '') AND a.W2AuditYN = 'Y'
END	

IF UPDATE(ReportDate)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerBAS', 
		'PR Co#: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear,
		i.PRCo, 
		'C', 
		'Report Date', 
		CONVERT(VARCHAR,d.ReportDate,101), 
		CONVERT(VARCHAR,i.ReportDate,101), 
		GETDATE(), 
		SUSER_SNAME()
    FROM INSERTED i
        JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear and i.Seq=d.Seq
        JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.ReportDate,'') <> ISNULL(d.ReportDate,'') AND a.W2AuditYN = 'Y'
END

IF UPDATE(ReturnCompletedFormTo)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerBAS', 
			'PRCo: ' + CAST(d.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + d.TaxYear + ', Seq: ' + CAST(d.Seq AS VARCHAR(10)),
		i.PRCo, 
		'C', 
		'Return Completed Form To', 
		d.ReturnCompletedFormTo, 
		i.ReturnCompletedFormTo, 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear and i.Seq=d.Seq
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.ReturnCompletedFormTo, '') <> ISNULL(d.ReturnCompletedFormTo, '') AND a.W2AuditYN = 'Y'
END	

IF UPDATE(Hours)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerBAS', 
			'PRCo: ' + CAST(d.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + d.TaxYear + ', Seq: ' + CAST(d.Seq AS VARCHAR(10)),
		i.PRCo, 
		'C', 
		'Hours', 
		CAST(d.Hours AS VARCHAR(4)), 
		CAST(i.Hours AS VARCHAR(4)), 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear and i.Seq=d.Seq
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.Hours, 0) <> ISNULL(d.Hours, 0) AND a.W2AuditYN = 'Y'
END

IF UPDATE(Min)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerBAS', 
			'PRCo: ' + CAST(d.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + d.TaxYear + ', Seq: ' + CAST(d.Seq AS VARCHAR(10)),
		i.PRCo, 
		'C', 
		'Minutes', 
		CAST(d.Min AS VARCHAR(10)), 
		CAST(i.Min AS VARCHAR(10)), 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear and i.Seq=d.Seq
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.Min, 0) <> ISNULL(d.Min, 0) AND a.W2AuditYN = 'Y'
END

IF UPDATE(GSTStartDate)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerBAS', 
		'PR Co#: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear,
		i.PRCo, 
		'C', 
		'GST Start Date', 
		CONVERT(VARCHAR,d.GSTStartDate,101), 
		CONVERT(VARCHAR,i.GSTStartDate,101), 
		GETDATE(), 
		SUSER_SNAME()
    FROM INSERTED i
        JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear and i.Seq=d.Seq
        JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.GSTStartDate,'') <> ISNULL(d.GSTStartDate,'') AND a.W2AuditYN = 'Y'
END

IF UPDATE(GSTEndDate)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerBAS', 
		'PR Co#: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear,
		i.PRCo, 
		'C', 
		'GST End Date', 
		CONVERT(VARCHAR,d.GSTEndDate,101), 
		CONVERT(VARCHAR,i.GSTEndDate,101), 
		GETDATE(), 
		SUSER_SNAME()
    FROM INSERTED i
        JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear and i.Seq=d.Seq
        JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.GSTEndDate,'') <> ISNULL(d.GSTEndDate,'') AND a.W2AuditYN = 'Y'
END


IF UPDATE(GSTOption)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerBAS', 
			'PRCo: ' + CAST(d.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + d.TaxYear + ', Seq: ' + CAST(d.Seq AS VARCHAR(10)),
		i.PRCo, 
		'C', 
		'GST Option', 
		CAST(d.GSTOption AS VARCHAR(4)), 
		CAST(i.GSTOption AS VARCHAR(4)), 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear and i.Seq=d.Seq
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.GSTOption, 0) <> ISNULL(d.GSTOption, 0) AND a.W2AuditYN = 'Y'
END

IF UPDATE(G1IncludesGST)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerBAS', 
			'PRCo: ' + CAST(d.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + d.TaxYear + ', Seq: ' + CAST(d.Seq AS VARCHAR(10)),
		i.PRCo, 
		'C', 
		'G1 Include GST', 
		d.G1IncludesGST, 
		i.G1IncludesGST, 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear and i.Seq=d.Seq
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.G1IncludesGST, '') <> ISNULL(d.G1IncludesGST, '') AND a.W2AuditYN = 'Y'
END	

IF UPDATE(G21)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerBAS', 
			'PRCo: ' + CAST(d.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + d.TaxYear + ', Seq: ' + CAST(d.Seq AS VARCHAR(10)),
		i.PRCo, 
		'C', 
		'G21', 
		CAST(d.G21 AS VARCHAR(16)), 
		CAST(i.G21 AS VARCHAR(16)), 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear and i.Seq=d.Seq
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.G21, 0) <> ISNULL(d.G21,0) AND  a.W2AuditYN = 'Y'
END 

IF UPDATE(G22)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerBAS', 
			'PRCo: ' + CAST(d.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + d.TaxYear + ', Seq: ' + CAST(d.Seq AS VARCHAR(10)),
		i.PRCo, 
		'C', 
		'G22', 
		CAST(d.G22 AS VARCHAR(16)), 
		CAST(i.G22 AS VARCHAR(16)), 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear and i.Seq=d.Seq
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.G22, 0) <> ISNULL(d.G22,0) AND  a.W2AuditYN = 'Y'
END       

IF UPDATE(G23)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerBAS', 
			'PRCo: ' + CAST(d.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + d.TaxYear + ', Seq: ' + CAST(d.Seq AS VARCHAR(10)),
		i.PRCo, 
		'C', 
		'G23', 
		CAST(d.G23 AS VARCHAR(16)), 
		CAST(i.G23 AS VARCHAR(16)), 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear and i.Seq=d.Seq
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.G23, 0) <> ISNULL(d.G23,0) AND  a.W2AuditYN = 'Y'
END   
 
IF UPDATE(G24ReasonCode)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerBAS', 
			'PRCo: ' + CAST(d.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + d.TaxYear + ', Seq: ' + CAST(d.Seq AS VARCHAR(10)),
		i.PRCo, 
		'C', 
		'G24 Reason Code', 
		CAST(d.G24ReasonCode AS VARCHAR(4)), 
		CAST(i.G24ReasonCode AS VARCHAR(4)), 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear and i.Seq=d.Seq
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.G24ReasonCode, 0) <> ISNULL(d.G24ReasonCode, 0) AND a.W2AuditYN = 'Y'
END           

IF UPDATE(PAYGWthStartDate)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerBAS', 
		'PR Co#: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear,
		i.PRCo, 
		'C', 
		'PAYGWth Start Date', 
		CONVERT(VARCHAR,d.PAYGWthStartDate,101), 
		CONVERT(VARCHAR,i.PAYGWthStartDate,101), 
		GETDATE(), 
		SUSER_SNAME()
    FROM INSERTED i
        JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear and i.Seq=d.Seq
        JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.PAYGWthStartDate,'') <> ISNULL(d.PAYGWthStartDate,'') AND a.W2AuditYN = 'Y'
END

IF UPDATE(PAYGWthEndDate)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerBAS', 
		'PR Co#: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear,
		i.PRCo, 
		'C', 
		'PAYGWth End Date', 
		CONVERT(VARCHAR,d.PAYGWthEndDate,101), 
		CONVERT(VARCHAR,i.PAYGWthEndDate,101), 
		GETDATE(), 
		SUSER_SNAME()
    FROM INSERTED i
        JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear and i.Seq=d.Seq
        JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.PAYGWthEndDate,'') <> ISNULL(d.PAYGWthEndDate,'') AND a.W2AuditYN = 'Y'
END


IF UPDATE(PAYGWth4)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerBAS', 
			'PRCo: ' + CAST(d.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + d.TaxYear + ', Seq: ' + CAST(d.Seq AS VARCHAR(10)),
		i.PRCo, 
		'C', 
		'PAYGWth4', 
		CAST(d.PAYGWth4 AS VARCHAR(16)), 
		CAST(i.PAYGWth4 AS VARCHAR(16)), 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear and i.Seq=d.Seq
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.PAYGWth4, 0) <> ISNULL(d.PAYGWth4,0) AND  a.W2AuditYN = 'Y'
END  

IF UPDATE(PAYGWth3)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerBAS', 
			'PRCo: ' + CAST(d.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + d.TaxYear + ', Seq: ' + CAST(d.Seq AS VARCHAR(10)),
		i.PRCo, 
		'C', 
		'PAYGWth3', 
		CAST(d.PAYGWth3 AS VARCHAR(16)), 
		CAST(i.PAYGWth3 AS VARCHAR(16)), 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear and i.Seq=d.Seq
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.PAYGWth3, 0) <> ISNULL(d.PAYGWth3,0) AND  a.W2AuditYN = 'Y'
END 

IF UPDATE(PAYGITaxStartDate)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerBAS', 
		'PR Co#: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear,
		i.PRCo, 
		'C', 
		'PAYGITax Start Date', 
		CONVERT(VARCHAR,d.PAYGITaxStartDate,101), 
		CONVERT(VARCHAR,i.PAYGITaxStartDate,101), 
		GETDATE(), 
		SUSER_SNAME()
    FROM INSERTED i
        JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear and i.Seq=d.Seq
        JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.PAYGITaxStartDate,'') <> ISNULL(d.PAYGITaxStartDate,'') AND a.W2AuditYN = 'Y'
END

IF UPDATE(PAYGITaxEndDate)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerBAS', 
		'PR Co#: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear,
		i.PRCo, 
		'C', 
		'PAYGITax End Date', 
		CONVERT(VARCHAR,d.PAYGITaxEndDate,101), 
		CONVERT(VARCHAR,i.PAYGITaxEndDate,101), 
		GETDATE(), 
		SUSER_SNAME()
    FROM INSERTED i
        JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear and i.Seq=d.Seq
        JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.PAYGITaxEndDate,'') <> ISNULL(d.PAYGITaxEndDate,'') AND a.W2AuditYN = 'Y'
END

IF UPDATE(PAYGITaxOption)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerBAS', 
			'PRCo: ' + CAST(d.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + d.TaxYear + ', Seq: ' + CAST(d.Seq AS VARCHAR(10)),
		i.PRCo, 
		'C', 
		'PAYGITax Option', 
		CAST(d.PAYGITaxOption AS VARCHAR(4)), 
		CAST(i.PAYGITaxOption AS VARCHAR(4)), 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear and i.Seq=d.Seq
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.PAYGITaxOption, 0) <> ISNULL(d.PAYGITaxOption, 0) AND a.W2AuditYN = 'Y'
END

IF UPDATE(PAYGITaxT7)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerBAS', 
			'PRCo: ' + CAST(d.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + d.TaxYear + ', Seq: ' + CAST(d.Seq AS VARCHAR(10)),
		i.PRCo, 
		'C', 
		'PAYGITax T7', 
		CAST(d.PAYGITaxT7 AS VARCHAR(16)), 
		CAST(i.PAYGITaxT7 AS VARCHAR(16)), 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear and i.Seq=d.Seq
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.PAYGITaxT7, 0) <> ISNULL(d.PAYGITaxT7, 0) AND a.W2AuditYN = 'Y'
END 

IF UPDATE(PAYGITaxT8)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerBAS', 
			'PRCo: ' + CAST(d.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + d.TaxYear + ', Seq: ' + CAST(d.Seq AS VARCHAR(10)),
		i.PRCo, 
		'C', 
		'PAYGITax T8', 
		CAST(d.PAYGITaxT8 AS VARCHAR(16)), 
		CAST(i.PAYGITaxT8 AS VARCHAR(16)), 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear and i.Seq=d.Seq
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.PAYGITaxT8, 0) <> ISNULL(d.PAYGITaxT8, 0) AND a.W2AuditYN = 'Y'
END 

IF UPDATE(PAYGITaxT9)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerBAS', 
			'PRCo: ' + CAST(d.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + d.TaxYear + ', Seq: ' + CAST(d.Seq AS VARCHAR(10)),
		i.PRCo, 
		'C', 
		'PAYGITax T9', 
		CAST(d.PAYGITaxT9 AS VARCHAR(16)), 
		CAST(i.PAYGITaxT9 AS VARCHAR(16)), 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear and i.Seq=d.Seq
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.PAYGITaxT9, 0) <> ISNULL(d.PAYGITaxT9, 0) AND a.W2AuditYN = 'Y'
END 

IF UPDATE(PAYGITaxT1)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerBAS', 
			'PRCo: ' + CAST(d.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + d.TaxYear + ', Seq: ' + CAST(d.Seq AS VARCHAR(10)),
		i.PRCo, 
		'C', 
		'PAYGITax T1', 
		CAST(d.PAYGITaxT1 AS VARCHAR(16)), 
		CAST(i.PAYGITaxT1 AS VARCHAR(16)), 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear and i.Seq=d.Seq
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.PAYGITaxT1, 0) <> ISNULL(d.PAYGITaxT1, 0) AND a.W2AuditYN = 'Y'
END 

IF UPDATE(PAYGITaxT2)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerBAS', 
			'PRCo: ' + CAST(d.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + d.TaxYear + ', Seq: ' + CAST(d.Seq AS VARCHAR(10)),
		i.PRCo, 
		'C', 
		'PAYGITax T2', 
		CAST(d.PAYGITaxT2 AS VARCHAR(16)), 
		CAST(i.PAYGITaxT2 AS VARCHAR(16)), 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear and i.Seq=d.Seq
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.PAYGITaxT2, 0) <> ISNULL(d.PAYGITaxT2, 0) AND a.W2AuditYN = 'Y'
END 

IF UPDATE(PAYGITaxT3)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerBAS', 
			'PRCo: ' + CAST(d.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + d.TaxYear + ', Seq: ' + CAST(d.Seq AS VARCHAR(10)),
		i.PRCo, 
		'C', 
		'PAYGITax T3', 
		CAST(d.PAYGITaxT3 AS VARCHAR(16)), 
		CAST(i.PAYGITaxT3 AS VARCHAR(16)), 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear and i.Seq=d.Seq
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.PAYGITaxT3, 0) <> ISNULL(d.PAYGITaxT3, 0) AND a.W2AuditYN = 'Y'
END 

IF UPDATE(PAYGITaxT11)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerBAS', 
			'PRCo: ' + CAST(d.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + d.TaxYear + ', Seq: ' + CAST(d.Seq AS VARCHAR(10)),
		i.PRCo, 
		'C', 
		'PAYGITax T11', 
		CAST(d.PAYGITaxT11 AS VARCHAR(16)), 
		CAST(i.PAYGITaxT11 AS VARCHAR(16)), 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear and i.Seq=d.Seq
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.PAYGITaxT11, 0) <> ISNULL(d.PAYGITaxT11, 0) AND a.W2AuditYN = 'Y'
END 

IF UPDATE(PAYGITaxT4ReasonCode)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerBAS', 
			'PRCo: ' + CAST(d.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + d.TaxYear + ', Seq: ' + CAST(d.Seq AS VARCHAR(10)),
		i.PRCo, 
		'C', 
		'PAYGITaxT4Reason Code', 
		CAST(d.PAYGITaxT4ReasonCode AS VARCHAR(4)), 
		CAST(i.PAYGITaxT4ReasonCode AS VARCHAR(4)), 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear and i.Seq=d.Seq
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.PAYGITaxT4ReasonCode, 0) <> ISNULL(d.PAYGITaxT4ReasonCode, 0) AND a.W2AuditYN = 'Y'
END     

IF UPDATE(FBTStartDate)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerBAS', 
		'PR Co#: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear,
		i.PRCo, 
		'C', 
		'FBT Start Date', 
		CONVERT(VARCHAR,d.FBTStartDate,101), 
		CONVERT(VARCHAR,i.FBTStartDate,101), 
		GETDATE(), 
		SUSER_SNAME()
    FROM INSERTED i
        JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear and i.Seq=d.Seq
        JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.FBTStartDate,'') <> ISNULL(d.FBTStartDate,'') AND a.W2AuditYN = 'Y'
END

IF UPDATE(FBTEndDate)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerBAS', 
		'PR Co#: ' + CAST(i.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + i.TaxYear,
		i.PRCo, 
		'C', 
		'FBT End Date', 
		CONVERT(VARCHAR,d.FBTEndDate,101), 
		CONVERT(VARCHAR,i.FBTEndDate,101), 
		GETDATE(), 
		SUSER_SNAME()
    FROM INSERTED i
        JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear and i.Seq=d.Seq
        JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.FBTEndDate,'') <> ISNULL(d.FBTEndDate,'') AND a.W2AuditYN = 'Y'
END

IF UPDATE(FBTF1)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerBAS', 
			'PRCo: ' + CAST(d.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + d.TaxYear + ', Seq: ' + CAST(d.Seq AS VARCHAR(10)),
		i.PRCo, 
		'C', 
		'FBT F1', 
		CAST(d.FBTF1 AS VARCHAR(16)), 
		CAST(i.FBTF1 AS VARCHAR(16)), 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear and i.Seq=d.Seq
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.FBTF1, 0) <> ISNULL(d.FBTF1, 0) AND a.W2AuditYN = 'Y'
END 

IF UPDATE(FBTF2)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerBAS', 
			'PRCo: ' + CAST(d.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + d.TaxYear + ', Seq: ' + CAST(d.Seq AS VARCHAR(10)),
		i.PRCo, 
		'C', 
		'FBT F2', 
		CAST(d.FBTF2 AS VARCHAR(16)), 
		CAST(i.FBTF2 AS VARCHAR(16)), 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear and i.Seq=d.Seq
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.FBTF2, 0) <> ISNULL(d.FBTF2, 0) AND a.W2AuditYN = 'Y'
END 

IF UPDATE(FBTF3)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerBAS', 
			'PRCo: ' + CAST(d.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + d.TaxYear + ', Seq: ' + CAST(d.Seq AS VARCHAR(10)),
		i.PRCo, 
		'C', 
		'FBT F3', 
		CAST(d.FBTF3 AS VARCHAR(16)), 
		CAST(i.FBTF3 AS VARCHAR(16)), 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear and i.Seq=d.Seq
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.FBTF3, 0) <> ISNULL(d.FBTF3, 0) AND a.W2AuditYN = 'Y'
END 

IF UPDATE(FBTF4ReasonCode)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerBAS', 
			'PRCo: ' + CAST(d.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + d.TaxYear + ', Seq: ' + CAST(d.Seq AS VARCHAR(10)),
		i.PRCo, 
		'C', 
		'FBTF4 ReasonCode Code', 
		CAST(d.FBTF4ReasonCode AS VARCHAR(4)), 
		CAST(i.FBTF4ReasonCode AS VARCHAR(4)), 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear and i.Seq=d.Seq
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.FBTF4ReasonCode, 0) <> ISNULL(d.FBTF4ReasonCode, 0) AND a.W2AuditYN = 'Y'
END 

IF UPDATE(Summ1C)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerBAS', 
			'PRCo: ' + CAST(d.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + d.TaxYear + ', Seq: ' + CAST(d.Seq AS VARCHAR(10)),
		i.PRCo, 
		'C', 
		'Summary 1C', 
		CAST(d.Summ1C AS VARCHAR(16)), 
		CAST(i.Summ1C AS VARCHAR(16)), 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear and i.Seq=d.Seq
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.Summ1C, 0) <> ISNULL(d.Summ1C, 0) AND a.W2AuditYN = 'Y'
END 

IF UPDATE(Summ1E)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerBAS', 
			'PRCo: ' + CAST(d.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + d.TaxYear + ', Seq: ' + CAST(d.Seq AS VARCHAR(10)),
		i.PRCo, 
		'C', 
		'Summary 1E', 
		CAST(d.Summ1E AS VARCHAR(16)), 
		CAST(i.Summ1E AS VARCHAR(16)), 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear and i.Seq=d.Seq
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.Summ1E, 0) <> ISNULL(d.Summ1E, 0) AND a.W2AuditYN = 'Y'
END

IF UPDATE(Summ7C)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerBAS', 
			'PRCo: ' + CAST(d.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + d.TaxYear + ', Seq: ' + CAST(d.Seq AS VARCHAR(10)),
		i.PRCo, 
		'C', 
		'Summary 7C', 
		CAST(d.Summ7C AS VARCHAR(16)), 
		CAST(i.Summ7C AS VARCHAR(16)), 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear and i.Seq=d.Seq
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.Summ7C, 0) <> ISNULL(d.Summ7C, 0) AND a.W2AuditYN = 'Y'
END

IF UPDATE(Summ1D)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerBAS', 
			'PRCo: ' + CAST(d.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + d.TaxYear + ', Seq: ' + CAST(d.Seq AS VARCHAR(10)),
		i.PRCo, 
		'C', 
		'Summary 1D', 
		CAST(d.Summ1D AS VARCHAR(16)), 
		CAST(i.Summ1D AS VARCHAR(16)), 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear and i.Seq=d.Seq
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.Summ1D, 0) <> ISNULL(d.Summ1D, 0) AND a.W2AuditYN = 'Y'
END

IF UPDATE(Summ1F)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerBAS', 
			'PRCo: ' + CAST(d.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + d.TaxYear + ', Seq: ' + CAST(d.Seq AS VARCHAR(10)),
		i.PRCo, 
		'C', 
		'Summary 1F', 
		CAST(d.Summ1F AS VARCHAR(16)), 
		CAST(i.Summ1F AS VARCHAR(16)), 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear and i.Seq=d.Seq
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.Summ1F, 0) <> ISNULL(d.Summ1F, 0) AND a.W2AuditYN = 'Y'
END

IF UPDATE(Summ5B)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerBAS', 
			'PRCo: ' + CAST(d.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + d.TaxYear + ', Seq: ' + CAST(d.Seq AS VARCHAR(10)),
		i.PRCo, 
		'C', 
		'Summary 5B', 
		CAST(d.Summ5B AS VARCHAR(16)), 
		CAST(i.Summ5B AS VARCHAR(16)), 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear and i.Seq=d.Seq
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.Summ5B, 0) <> ISNULL(d.Summ5B, 0) AND a.W2AuditYN = 'Y'
END

IF UPDATE(Summ6B)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerBAS', 
			'PRCo: ' + CAST(d.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + d.TaxYear + ', Seq: ' + CAST(d.Seq AS VARCHAR(10)),
		i.PRCo, 
		'C', 
		'Summary 6B', 
		CAST(d.Summ6B AS VARCHAR(16)), 
		CAST(i.Summ6B AS VARCHAR(16)), 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear and i.Seq=d.Seq
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.Summ6B, 0) <> ISNULL(d.Summ6B, 0) AND a.W2AuditYN = 'Y'
END

IF UPDATE(Summ7D)
BEGIN
   	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 
		'vPRAUEmployerBAS', 
			'PRCo: ' + CAST(d.PRCo AS VARCHAR(10)) + ',  Tax Year: ' + d.TaxYear + ', Seq: ' + CAST(d.Seq AS VARCHAR(10)),
		i.PRCo, 
		'C', 
		'Summary 7D', 
		CAST(d.Summ7D AS VARCHAR(16)), 
		CAST(i.Summ7D AS VARCHAR(16)), 
		GETDATE(), 
		SUSER_SNAME() 
    FROM INSERTED i
		JOIN DELETED d ON i.PRCo = d.PRCo AND i.TaxYear = d.TaxYear and i.Seq=d.Seq
		JOIN dbo.bPRCO a (NOLOCK) ON i.PRCo = a.PRCo
    WHERE ISNULL(i.Summ7D, 0) <> ISNULL(d.Summ7D, 0) AND a.W2AuditYN = 'Y'
END

RETURN


GO
ALTER TABLE [dbo].[vPRAUEmployerBAS] ADD CONSTRAINT [PK_vPRAUEmployerBAS] PRIMARY KEY CLUSTERED  ([PRCo], [TaxYear], [Seq]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPRAUEmployerBAS] WITH NOCHECK ADD CONSTRAINT [FK_vPRAUEmployerBAS_vPRAUEmployerMaster] FOREIGN KEY ([PRCo], [TaxYear]) REFERENCES [dbo].[vPRAUEmployerMaster] ([PRCo], [TaxYear])
GO
