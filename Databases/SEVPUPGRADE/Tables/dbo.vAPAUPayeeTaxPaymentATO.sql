CREATE TABLE [dbo].[vAPAUPayeeTaxPaymentATO]
(
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[APCo] [dbo].[bCompany] NOT NULL,
[TaxYear] [char] (4) COLLATE Latin1_General_BIN NOT NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Vendor] [dbo].[bVendor] NOT NULL,
[PayeeName] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[AusBusNbr] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[Address] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Address2] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[City] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[State] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[PostalCode] [dbo].[bZip] NULL,
[Country] [varchar] (2) COLLATE Latin1_General_BIN NULL,
[Phone] [varchar] (15) COLLATE Latin1_General_BIN NULL,
[TotalNoABNTax] [dbo].[bDollar] NULL CONSTRAINT [DF_vAPAUPayeeTaxPaymentATO_TotalNoABNTax] DEFAULT ((0)),
[TotalGST] [dbo].[bDollar] NULL CONSTRAINT [DF_vAPAUPayeeTaxPaymentATO_TotalGST] DEFAULT ((0)),
[TotalPaid] [dbo].[bDollar] NULL CONSTRAINT [DF_vAPAUPayeeTaxPaymentATO_TotalPaid] DEFAULT ((0)),
[AmendedDate] [dbo].[bDate] NULL,
[UniqueAttchID] [uniqueidentifier] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vAPAUPayeeTaxPaymentATO] ADD CONSTRAINT [PK_vAPAUPayeeTaxPaymentATO] PRIMARY KEY CLUSTERED  ([APCo], [TaxYear], [VendorGroup], [Vendor]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vAPAUPayeeTaxPaymentATO] ADD CONSTRAINT [FK_vAPAUPayeeTaxPaymentATO_vAPAUPayerTaxPaymentATO] FOREIGN KEY ([APCo], [TaxYear]) REFERENCES [dbo].[vAPAUPayerTaxPaymentATO] ([APCo], [TaxYear]) ON DELETE CASCADE
GO
GRANT SELECT ON  [dbo].[vAPAUPayeeTaxPaymentATO] TO [public]
GRANT INSERT ON  [dbo].[vAPAUPayeeTaxPaymentATO] TO [public]
GRANT DELETE ON  [dbo].[vAPAUPayeeTaxPaymentATO] TO [public]
GRANT UPDATE ON  [dbo].[vAPAUPayeeTaxPaymentATO] TO [public]
GO
