CREATE TABLE [dbo].[vPCContacts]
(
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Vendor] [dbo].[bVendor] NOT NULL,
[Seq] [tinyint] NOT NULL,
[Name] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[Title] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[CompanyYears] [tinyint] NULL,
[RoleYears] [tinyint] NULL,
[Phone] [dbo].[bPhone] NULL,
[Cell] [dbo].[bPhone] NULL,
[Email] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[ContactTypeCode] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[Fax] [dbo].[bPhone] NULL,
[PrefMethod] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vPCContacts_PrefMethod] DEFAULT ('M'),
[IsBidContact] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vPCContacts_IsBidContact] DEFAULT ('N'),
[FormattedFax] [varchar] (128) COLLATE Latin1_General_BIN NULL,
[UseFaxServerName] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vPCContacts_UseFaxServerName] DEFAULT ('N')
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPCContacts] ADD CONSTRAINT [CK_vPCContacts_IsBidContact] CHECK (([IsBidContact]='N' OR [IsBidContact]='Y'))
GO
ALTER TABLE [dbo].[vPCContacts] ADD CONSTRAINT [CK_vPCContacts_PrefMethod] CHECK (([PrefMethod]='F' OR [PrefMethod]='E' OR [PrefMethod]='M'))
GO
ALTER TABLE [dbo].[vPCContacts] ADD CONSTRAINT [PK_vPCContacts] PRIMARY KEY CLUSTERED  ([VendorGroup], [Vendor], [Seq]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPCContacts] WITH NOCHECK ADD CONSTRAINT [FK_vPCContacts_vPCContactTypeCodes] FOREIGN KEY ([VendorGroup], [ContactTypeCode]) REFERENCES [dbo].[vPCContactTypeCodes] ([VendorGroup], [ContactTypeCode])
GO
