CREATE TABLE [dbo].[tmp_mvwCreateACheckVendorExport]
(
[VendorID] [dbo].[bVendor] NOT NULL,
[VendorName] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[AddressLine1] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[AddressLine2] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[AddressLine3] [int] NULL,
[City] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[State] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[Country] [varchar] (2) COLLATE Latin1_General_BIN NULL,
[PostalCode] [dbo].[bZip] NULL,
[PhoneNumber] [dbo].[bPhone] NULL,
[EmailAddress] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[UseEmail] [varchar] (1) COLLATE Latin1_General_BIN NOT NULL,
[GLAcct] [int] NULL,
[Memo] [varchar] (33) COLLATE Latin1_General_BIN NOT NULL,
[CustomData1] [varchar] (21) COLLATE Latin1_General_BIN NULL,
[CustomData2] [int] NULL,
[ExcludeFromACH_YN] [varchar] (1) COLLATE Latin1_General_BIN NOT NULL,
[BankAccountNumber] [varchar] (35) COLLATE Latin1_General_BIN NULL,
[SECCode] [varchar] (3) COLLATE Latin1_General_BIN NULL,
[RoutingNumber] [varchar] (34) COLLATE Latin1_General_BIN NULL,
[TransactionType] [varchar] (23) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
