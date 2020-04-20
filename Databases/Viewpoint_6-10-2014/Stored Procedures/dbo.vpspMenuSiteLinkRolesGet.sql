SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspMenuSiteLinkRolesGet
AS
	SET NOCOUNT ON;
SELECT MenuSiteLinkID, SiteID, RoleID, AllowAccess FROM pMenuSiteLinkRoles


GO
GRANT EXECUTE ON  [dbo].[vpspMenuSiteLinkRolesGet] TO [VCSPortal]
GO
