CREATE TABLE [dbo].[vPCProjectTypeCodes]
(
[VendorGroup] [dbo].[bGroup] NOT NULL,
[ProjectTypeCode] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Description] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[ActiveLookup] [dbo].[bYN] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPCProjectTypeCodes] ADD CONSTRAINT [PK_vPCProjectTypeCodes] PRIMARY KEY CLUSTERED  ([VendorGroup], [ProjectTypeCode]) ON [PRIMARY]
GO
