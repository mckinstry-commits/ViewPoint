CREATE TABLE [dbo].[vPCContactTypeCodes]
(
[VendorGroup] [dbo].[bGroup] NOT NULL,
[ContactTypeCode] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Description] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[ActiveLookup] [dbo].[bYN] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPCContactTypeCodes] ADD CONSTRAINT [PK_vPCContactTypeCodes] PRIMARY KEY CLUSTERED  ([VendorGroup], [ContactTypeCode]) ON [PRIMARY]
GO
