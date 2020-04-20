SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspMenuSiteLinkRolesDelete
(
	@Original_MenuSiteLinkID int,
	@Original_RoleID int,
	@Original_SiteID int,
	@Original_AllowAccess bit
)
AS
	SET NOCOUNT OFF;
DELETE FROM pMenuSiteLinkRoles WHERE (MenuSiteLinkID = @Original_MenuSiteLinkID) AND (RoleID = @Original_RoleID) AND (SiteID = @Original_SiteID) AND (AllowAccess = @Original_AllowAccess)


GO
GRANT EXECUTE ON  [dbo].[vpspMenuSiteLinkRolesDelete] TO [VCSPortal]
GO
