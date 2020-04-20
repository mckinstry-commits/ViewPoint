CREATE TABLE [dbo].[pSiteAttachmentSecurity]
(
[SiteID] [int] NOT NULL,
[RoleID] [int] NOT NULL,
[AllowAdd] [bit] NOT NULL,
[AllowDelete] [bit] NOT NULL,
[AllowView] [bit] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[pSiteAttachmentSecurity] ADD CONSTRAINT [PK_pSiteAttachmentSecurity] PRIMARY KEY CLUSTERED  ([SiteID], [RoleID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[pSiteAttachmentSecurity] WITH NOCHECK ADD CONSTRAINT [FK_pSiteAttachmentSecurity_pRoles] FOREIGN KEY ([RoleID]) REFERENCES [dbo].[pRoles] ([RoleID]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[pSiteAttachmentSecurity] WITH NOCHECK ADD CONSTRAINT [FK_pSiteAttachmentSecurity_pSites] FOREIGN KEY ([SiteID]) REFERENCES [dbo].[pSites] ([SiteID]) ON DELETE CASCADE
GO
GRANT SELECT ON  [dbo].[pSiteAttachmentSecurity] TO [VCSPortal]
GRANT INSERT ON  [dbo].[pSiteAttachmentSecurity] TO [VCSPortal]
GRANT DELETE ON  [dbo].[pSiteAttachmentSecurity] TO [VCSPortal]
GRANT UPDATE ON  [dbo].[pSiteAttachmentSecurity] TO [VCSPortal]
GRANT SELECT ON  [dbo].[pSiteAttachmentSecurity] TO [viewpointcs]
GRANT INSERT ON  [dbo].[pSiteAttachmentSecurity] TO [viewpointcs]
GRANT DELETE ON  [dbo].[pSiteAttachmentSecurity] TO [viewpointcs]
GRANT UPDATE ON  [dbo].[pSiteAttachmentSecurity] TO [viewpointcs]
GO
