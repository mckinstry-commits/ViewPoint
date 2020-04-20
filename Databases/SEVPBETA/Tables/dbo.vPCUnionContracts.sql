CREATE TABLE [dbo].[vPCUnionContracts]
(
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Vendor] [dbo].[bVendor] NOT NULL,
[Seq] [tinyint] NOT NULL,
[LocalNumber] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Name] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Expiration] [dbo].[bDate] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPCUnionContracts] ADD CONSTRAINT [PK_vPCUnionContracts] PRIMARY KEY CLUSTERED  ([VendorGroup], [Vendor], [Seq]) ON [PRIMARY]
GO
