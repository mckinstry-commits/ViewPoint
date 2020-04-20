SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.VCUserSites
AS
SELECT     dbo.pUserSites.*
FROM         dbo.pUserSites

GO
GRANT SELECT ON  [dbo].[VCUserSites] TO [public]
GRANT INSERT ON  [dbo].[VCUserSites] TO [public]
GRANT DELETE ON  [dbo].[VCUserSites] TO [public]
GRANT UPDATE ON  [dbo].[VCUserSites] TO [public]
GRANT SELECT ON  [dbo].[VCUserSites] TO [Viewpoint]
GRANT INSERT ON  [dbo].[VCUserSites] TO [Viewpoint]
GRANT DELETE ON  [dbo].[VCUserSites] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[VCUserSites] TO [Viewpoint]
GO
