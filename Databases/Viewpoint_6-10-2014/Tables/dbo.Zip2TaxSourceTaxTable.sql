CREATE TABLE [dbo].[Zip2TaxSourceTaxTable]
(
[z2t_ID] [int] NOT NULL,
[ZipCode] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[SalesTaxRate] [numeric] (18, 3) NOT NULL CONSTRAINT [DF__Zip2TaxSo__Sales__384C5660] DEFAULT ((0.00)),
[RateState] [numeric] (18, 3) NOT NULL CONSTRAINT [DF__Zip2TaxSo__RateS__39407A99] DEFAULT ((0.00)),
[ReportingCodeState] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[RateCounty] [numeric] (18, 3) NOT NULL CONSTRAINT [DF__Zip2TaxSo__RateC__3A349ED2] DEFAULT ((0.00)),
[ReportingCodeCounty] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[RateCity] [numeric] (18, 3) NOT NULL CONSTRAINT [DF__Zip2TaxSo__RateC__3B28C30B] DEFAULT ((0.00)),
[ReportingCodeCity] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[RateSpecialDistrict] [numeric] (18, 3) NOT NULL CONSTRAINT [DF__Zip2TaxSo__RateS__3C1CE744] DEFAULT ((0.00)),
[ReportingCodeSpecialDistrict] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[City] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[PostOffice] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[State] [char] (5) COLLATE Latin1_General_BIN NOT NULL,
[County] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[ShippingTaxable] [int] NOT NULL CONSTRAINT [DF__Zip2TaxSo__Shipp__3D110B7D] DEFAULT ((0)),
[PrimaryRecord] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF__Zip2TaxSo__Prima__3E052FB6] DEFAULT ((0)),
[MatchString] [varchar] (75) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
