SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspMenuSiteLinkRolesInsert
(
	@MenuSiteLinkID int,
	@SiteID int,
	@RoleID int,
	@AllowAccess bit
)
AS
	SET NOCOUNT OFF;
INSERT INTO pMenuSiteLinkRoles(MenuSiteLinkID, SiteID, RoleID, AllowAccess) VALUES (@MenuSiteLinkID, @SiteID, @RoleID, @AllowAccess);
	SELECT MenuSiteLinkID, SiteID, RoleID, AllowAccess FROM pMenuSiteLinkRoles WHERE (MenuSiteLinkID = @MenuSiteLinkID) AND (RoleID = @RoleID) AND (SiteID = @SiteID)


GO
GRANT EXECUTE ON  [dbo].[vpspMenuSiteLinkRolesInsert] TO [VCSPortal]
GO
