SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[pvPageSiteControls]
AS
SELECT     *
FROM         dbo.pPageSiteControls



GO
GRANT SELECT ON  [dbo].[pvPageSiteControls] TO [public]
GRANT INSERT ON  [dbo].[pvPageSiteControls] TO [public]
GRANT DELETE ON  [dbo].[pvPageSiteControls] TO [public]
GRANT UPDATE ON  [dbo].[pvPageSiteControls] TO [public]
GRANT SELECT ON  [dbo].[pvPageSiteControls] TO [VCSPortal]
GO
