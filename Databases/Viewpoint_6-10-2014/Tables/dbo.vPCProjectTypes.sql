CREATE TABLE [dbo].[vPCProjectTypes]
(
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Vendor] [dbo].[bVendor] NOT NULL,
[ProjectTypeCode] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[WorkPrevious] [dbo].[bPct] NULL,
[WorkNext] [dbo].[bPct] NULL,
[NoPriorWork] [dbo].[bYN] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPCProjectTypes] ADD CONSTRAINT [PK_vPCProjectTypes] PRIMARY KEY CLUSTERED  ([VendorGroup], [Vendor], [ProjectTypeCode]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPCProjectTypes] WITH NOCHECK ADD CONSTRAINT [FK_vPCProjectTypes_vPCProjectTypeCodes] FOREIGN KEY ([VendorGroup], [ProjectTypeCode]) REFERENCES [dbo].[vPCProjectTypeCodes] ([VendorGroup], [ProjectTypeCode])
GO
ALTER TABLE [dbo].[vPCProjectTypes] NOCHECK CONSTRAINT [FK_vPCProjectTypes_vPCProjectTypeCodes]
GO
