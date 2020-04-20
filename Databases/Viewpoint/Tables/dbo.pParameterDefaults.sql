CREATE TABLE [dbo].[pParameterDefaults]
(
[PageSiteControlID] [int] NOT NULL,
[ParameterName] [varchar] (255) COLLATE Latin1_General_BIN NOT NULL,
[ParameterDefaultValue] [varchar] (255) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[pParameterDefaults] TO [VCSPortal]
GRANT INSERT ON  [dbo].[pParameterDefaults] TO [VCSPortal]
GRANT DELETE ON  [dbo].[pParameterDefaults] TO [VCSPortal]
GRANT UPDATE ON  [dbo].[pParameterDefaults] TO [VCSPortal]
GRANT SELECT ON  [dbo].[pParameterDefaults] TO [viewpointcs]
GRANT INSERT ON  [dbo].[pParameterDefaults] TO [viewpointcs]
GRANT DELETE ON  [dbo].[pParameterDefaults] TO [viewpointcs]
GRANT UPDATE ON  [dbo].[pParameterDefaults] TO [viewpointcs]
GO
