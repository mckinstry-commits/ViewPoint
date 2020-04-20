CREATE TABLE [dbo].[vPCScopeCodes]
(
[VendorGroup] [dbo].[bGroup] NOT NULL,
[ScopeCode] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Description] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[ActiveLookup] [dbo].[bYN] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPCScopeCodes] ADD CONSTRAINT [PK_vPCScopeCodes] PRIMARY KEY CLUSTERED  ([VendorGroup], [ScopeCode]) ON [PRIMARY]
GO
