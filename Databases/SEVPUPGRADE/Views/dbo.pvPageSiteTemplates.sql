SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[pvPageSiteTemplates]
AS
SELECT     *
FROM         dbo.pPageSiteTemplates



GO
GRANT SELECT ON  [dbo].[pvPageSiteTemplates] TO [public]
GRANT INSERT ON  [dbo].[pvPageSiteTemplates] TO [public]
GRANT DELETE ON  [dbo].[pvPageSiteTemplates] TO [public]
GRANT UPDATE ON  [dbo].[pvPageSiteTemplates] TO [public]
GRANT SELECT ON  [dbo].[pvPageSiteTemplates] TO [VCSPortal]
GO
