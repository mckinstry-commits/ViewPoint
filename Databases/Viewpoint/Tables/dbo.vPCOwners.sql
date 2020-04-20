CREATE TABLE [dbo].[vPCOwners]
(
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Vendor] [dbo].[bVendor] NOT NULL,
[Seq] [tinyint] NOT NULL,
[Name] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Role] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[BirthYear] [smallint] NULL,
[Ownership] [dbo].[bPct] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPCOwners] ADD CONSTRAINT [PK_vPCOwner] PRIMARY KEY CLUSTERED  ([VendorGroup], [Vendor], [Seq]) ON [PRIMARY]
GO
