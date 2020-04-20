CREATE TABLE [dbo].[vPCWorkRegions]
(
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Vendor] [dbo].[bVendor] NOT NULL,
[RegionCode] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[WorkPrevious] [dbo].[bPct] NULL,
[WorkNext] [dbo].[bPct] NULL,
[NoPriorWork] [dbo].[bYN] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPCWorkRegions] ADD CONSTRAINT [PK_vPCWorkRegions] PRIMARY KEY CLUSTERED  ([VendorGroup], [Vendor], [RegionCode]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPCWorkRegions] WITH NOCHECK ADD CONSTRAINT [FK_vPCWorkRegions_vPCRegionCodes] FOREIGN KEY ([VendorGroup], [RegionCode]) REFERENCES [dbo].[vPCRegionCodes] ([VendorGroup], [RegionCode])
GO
