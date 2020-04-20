SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[pvSites]
AS
SELECT     *
FROM         dbo.pSites



GO
GRANT SELECT ON  [dbo].[pvSites] TO [public]
GRANT INSERT ON  [dbo].[pvSites] TO [public]
GRANT DELETE ON  [dbo].[pvSites] TO [public]
GRANT UPDATE ON  [dbo].[pvSites] TO [public]
GRANT SELECT ON  [dbo].[pvSites] TO [VCSPortal]
GRANT SELECT ON  [dbo].[pvSites] TO [Viewpoint]
GRANT INSERT ON  [dbo].[pvSites] TO [Viewpoint]
GRANT DELETE ON  [dbo].[pvSites] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[pvSites] TO [Viewpoint]
GO
