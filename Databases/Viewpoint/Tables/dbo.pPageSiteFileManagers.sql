CREATE TABLE [dbo].[pPageSiteFileManagers]
(
[PageSiteFileManagerID] [int] NOT NULL IDENTITY(1, 1),
[PageSiteControlID] [int] NOT NULL,
[RootVirtualPath] [varchar] (max) COLLATE Latin1_General_BIN NOT NULL,
[FolderType] [tinyint] NOT NULL CONSTRAINT [DF_pPageSiteFileManagers_FolderType] DEFAULT ((0)),
[SiteID] [int] NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[pPageSiteFileManagers] ADD CONSTRAINT [PK_pPageSiteFileManagers] PRIMARY KEY CLUSTERED  ([PageSiteFileManagerID]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[pPageSiteFileManagers] TO [VCSPortal]
GRANT INSERT ON  [dbo].[pPageSiteFileManagers] TO [VCSPortal]
GRANT DELETE ON  [dbo].[pPageSiteFileManagers] TO [VCSPortal]
GRANT UPDATE ON  [dbo].[pPageSiteFileManagers] TO [VCSPortal]
GRANT SELECT ON  [dbo].[pPageSiteFileManagers] TO [viewpointcs]
GRANT INSERT ON  [dbo].[pPageSiteFileManagers] TO [viewpointcs]
GRANT DELETE ON  [dbo].[pPageSiteFileManagers] TO [viewpointcs]
GRANT UPDATE ON  [dbo].[pPageSiteFileManagers] TO [viewpointcs]
GO
