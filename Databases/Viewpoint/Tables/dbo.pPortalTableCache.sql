CREATE TABLE [dbo].[pPortalTableCache]
(
[TableName] [varchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[LastUpdatedDate] [datetime] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[pPortalTableCache] ADD CONSTRAINT [PK_pPortalTableCache] PRIMARY KEY CLUSTERED  ([TableName]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[pPortalTableCache] TO [VCSPortal]
GRANT INSERT ON  [dbo].[pPortalTableCache] TO [VCSPortal]
GRANT DELETE ON  [dbo].[pPortalTableCache] TO [VCSPortal]
GRANT UPDATE ON  [dbo].[pPortalTableCache] TO [VCSPortal]
GRANT SELECT ON  [dbo].[pPortalTableCache] TO [viewpointcs]
GRANT INSERT ON  [dbo].[pPortalTableCache] TO [viewpointcs]
GRANT DELETE ON  [dbo].[pPortalTableCache] TO [viewpointcs]
GRANT UPDATE ON  [dbo].[pPortalTableCache] TO [viewpointcs]
GO
