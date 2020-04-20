CREATE TABLE [dbo].[vPCRegionCodes]
(
[VendorGroup] [dbo].[bGroup] NOT NULL,
[RegionCode] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Description] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[ActiveLookup] [dbo].[bYN] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPCRegionCodes] ADD CONSTRAINT [PK_vPCRegionCodes] PRIMARY KEY CLUSTERED  ([VendorGroup], [RegionCode]) ON [PRIMARY]
GO
