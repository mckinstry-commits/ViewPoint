CREATE TABLE [dbo].[vSMCustomer_bak]
(
[SMCustomerID] [bigint] NOT NULL IDENTITY(1, 1),
[SMCo] [dbo].[bCompany] NOT NULL,
[CustGroup] [dbo].[bGroup] NOT NULL,
[Customer] [dbo].[bCustomer] NOT NULL,
[Active] [dbo].[bYN] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[RateTemplate] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[BillToARCustomer] [dbo].[bCustomer] NULL,
[ReportID] [int] NULL,
[SMRateOverrideID] [bigint] NULL,
[SMStandardItemDefaultID] [bigint] NULL,
[CustomerPOSetting] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[PrimaryTechnician] [varchar] (15) COLLATE Latin1_General_BIN NULL,
[InvoiceGrouping] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[InvoiceSummaryLevel] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[udConvertedYN] [dbo].[bYN] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
