SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspUserSitesGet
AS
	SET NOCOUNT ON;
SELECT u.UserID, u.SiteID, u.RoleID, s.Active FROM pUserSites u inner join pSites s on u.SiteID = s.SiteID


GO
GRANT EXECUTE ON  [dbo].[vpspUserSitesGet] TO [VCSPortal]
GO
