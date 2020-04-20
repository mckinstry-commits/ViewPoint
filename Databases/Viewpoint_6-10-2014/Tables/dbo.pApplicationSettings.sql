CREATE TABLE [dbo].[pApplicationSettings]
(
[Key] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[Value] [varchar] (max) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[pApplicationSettings] ADD CONSTRAINT [PK_pApplicationSettings] PRIMARY KEY CLUSTERED  ([Key]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[pApplicationSettings] TO [VCSPortal]
GRANT INSERT ON  [dbo].[pApplicationSettings] TO [VCSPortal]
GRANT DELETE ON  [dbo].[pApplicationSettings] TO [VCSPortal]
GRANT UPDATE ON  [dbo].[pApplicationSettings] TO [VCSPortal]
GRANT SELECT ON  [dbo].[pApplicationSettings] TO [viewpointcs]
GRANT INSERT ON  [dbo].[pApplicationSettings] TO [viewpointcs]
GRANT DELETE ON  [dbo].[pApplicationSettings] TO [viewpointcs]
GRANT UPDATE ON  [dbo].[pApplicationSettings] TO [viewpointcs]
GO
