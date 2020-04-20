SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[pvUserSites]
AS
SELECT     *
FROM         dbo.pUserSites




GO
GRANT SELECT ON  [dbo].[pvUserSites] TO [public]
GRANT INSERT ON  [dbo].[pvUserSites] TO [public]
GRANT DELETE ON  [dbo].[pvUserSites] TO [public]
GRANT UPDATE ON  [dbo].[pvUserSites] TO [public]
GRANT SELECT ON  [dbo].[pvUserSites] TO [VCSPortal]
GO
