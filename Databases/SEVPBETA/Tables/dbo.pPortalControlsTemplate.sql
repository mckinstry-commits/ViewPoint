CREATE TABLE [dbo].[pPortalControlsTemplate]
(
[PortalControlID] [int] NOT NULL,
[CustomHelpPath] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[Notes] [varchar] (3000) COLLATE Latin1_General_BIN NULL,
[HeaderText] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[FooterText] [varchar] (max) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[pPortalControlsTemplate] ADD CONSTRAINT [PK_pPortalControlsTemplate] PRIMARY KEY CLUSTERED  ([PortalControlID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[pPortalControlsTemplate] WITH NOCHECK ADD CONSTRAINT [FK_pPortalControlsTemplate_pPortalControls] FOREIGN KEY ([PortalControlID]) REFERENCES [dbo].[pPortalControls] ([PortalControlID])
GO
GRANT SELECT ON  [dbo].[pPortalControlsTemplate] TO [VCSPortal]
GRANT INSERT ON  [dbo].[pPortalControlsTemplate] TO [VCSPortal]
GRANT DELETE ON  [dbo].[pPortalControlsTemplate] TO [VCSPortal]
GRANT UPDATE ON  [dbo].[pPortalControlsTemplate] TO [VCSPortal]
GRANT SELECT ON  [dbo].[pPortalControlsTemplate] TO [viewpointcs]
GRANT INSERT ON  [dbo].[pPortalControlsTemplate] TO [viewpointcs]
GRANT DELETE ON  [dbo].[pPortalControlsTemplate] TO [viewpointcs]
GRANT UPDATE ON  [dbo].[pPortalControlsTemplate] TO [viewpointcs]
GO
