SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE VIEW [dbo].[pvPortalControlSecurityTemplate]
AS
SELECT     *
FROM         dbo.pPortalControlSecurityTemplate




GO
GRANT SELECT ON  [dbo].[pvPortalControlSecurityTemplate] TO [public]
GRANT INSERT ON  [dbo].[pvPortalControlSecurityTemplate] TO [public]
GRANT DELETE ON  [dbo].[pvPortalControlSecurityTemplate] TO [public]
GRANT UPDATE ON  [dbo].[pvPortalControlSecurityTemplate] TO [public]
GRANT SELECT ON  [dbo].[pvPortalControlSecurityTemplate] TO [VCSPortal]
GRANT SELECT ON  [dbo].[pvPortalControlSecurityTemplate] TO [Viewpoint]
GRANT INSERT ON  [dbo].[pvPortalControlSecurityTemplate] TO [Viewpoint]
GRANT DELETE ON  [dbo].[pvPortalControlSecurityTemplate] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[pvPortalControlSecurityTemplate] TO [Viewpoint]
GO
