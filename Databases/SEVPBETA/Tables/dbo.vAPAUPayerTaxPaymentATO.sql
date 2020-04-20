CREATE TABLE [dbo].[vAPAUPayerTaxPaymentATO]
(
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[APCo] [dbo].[bCompany] NOT NULL,
[TaxYear] [char] (4) COLLATE Latin1_General_BIN NOT NULL,
[ContactName] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[ContactPhone] [varchar] (15) COLLATE Latin1_General_BIN NULL,
[SignatureOfAuthPerson] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[ReportDate] [dbo].[bDate] NULL,
[TaxYearClosed] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vAPAUPayerTaxPaymentATO_TaxYearClosed] DEFAULT ('N'),
[UniqueAttchID] [uniqueidentifier] NULL,
[ABN] [varchar] (11) COLLATE Latin1_General_BIN NULL,
[BranchNo] [varchar] (3) COLLATE Latin1_General_BIN NULL,
[CompanyName] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Address] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Address2] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[City] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[State] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[PostalCode] [dbo].[bZip] NULL,
[Country] [varchar] (2) COLLATE Latin1_General_BIN NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[vAPAUPayerTaxPaymentATO] ADD CONSTRAINT [PK_vAPAUPayerTaxPaymentATO] PRIMARY KEY CLUSTERED  ([APCo], [TaxYear]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[vAPAUPayerTaxPaymentATO] TO [public]
GRANT INSERT ON  [dbo].[vAPAUPayerTaxPaymentATO] TO [public]
GRANT DELETE ON  [dbo].[vAPAUPayerTaxPaymentATO] TO [public]
GRANT UPDATE ON  [dbo].[vAPAUPayerTaxPaymentATO] TO [public]
GO
