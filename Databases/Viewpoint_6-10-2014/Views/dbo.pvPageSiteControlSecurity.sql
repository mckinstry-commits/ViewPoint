SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[pvPageSiteControlSecurity]
AS
SELECT     *
FROM         dbo.pPageSiteControlSecurity



GO
GRANT SELECT ON  [dbo].[pvPageSiteControlSecurity] TO [public]
GRANT INSERT ON  [dbo].[pvPageSiteControlSecurity] TO [public]
GRANT DELETE ON  [dbo].[pvPageSiteControlSecurity] TO [public]
GRANT UPDATE ON  [dbo].[pvPageSiteControlSecurity] TO [public]
GRANT SELECT ON  [dbo].[pvPageSiteControlSecurity] TO [VCSPortal]
GRANT SELECT ON  [dbo].[pvPageSiteControlSecurity] TO [Viewpoint]
GRANT INSERT ON  [dbo].[pvPageSiteControlSecurity] TO [Viewpoint]
GRANT DELETE ON  [dbo].[pvPageSiteControlSecurity] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[pvPageSiteControlSecurity] TO [Viewpoint]
GO
