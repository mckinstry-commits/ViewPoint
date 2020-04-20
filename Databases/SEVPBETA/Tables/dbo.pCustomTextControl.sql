CREATE TABLE [dbo].[pCustomTextControl]
(
[PageSiteControlID] [int] NOT NULL,
[SiteID] [int] NOT NULL,
[ControlText] [nvarchar] (max) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[pCustomTextControl] ADD CONSTRAINT [PK_pCustomTextControl] PRIMARY KEY CLUSTERED  ([PageSiteControlID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[pCustomTextControl] WITH NOCHECK ADD CONSTRAINT [FK_pCustomTextControl_pPageSiteControl] FOREIGN KEY ([PageSiteControlID]) REFERENCES [dbo].[pPageSiteControls] ([PageSiteControlID]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[pCustomTextControl] WITH NOCHECK ADD CONSTRAINT [FK_pCustomTextControl_pSites] FOREIGN KEY ([SiteID]) REFERENCES [dbo].[pSites] ([SiteID])
GO
GRANT SELECT ON  [dbo].[pCustomTextControl] TO [VCSPortal]
GRANT INSERT ON  [dbo].[pCustomTextControl] TO [VCSPortal]
GRANT DELETE ON  [dbo].[pCustomTextControl] TO [VCSPortal]
GRANT UPDATE ON  [dbo].[pCustomTextControl] TO [VCSPortal]
GRANT SELECT ON  [dbo].[pCustomTextControl] TO [viewpointcs]
GRANT INSERT ON  [dbo].[pCustomTextControl] TO [viewpointcs]
GRANT DELETE ON  [dbo].[pCustomTextControl] TO [viewpointcs]
GRANT UPDATE ON  [dbo].[pCustomTextControl] TO [viewpointcs]
GO
