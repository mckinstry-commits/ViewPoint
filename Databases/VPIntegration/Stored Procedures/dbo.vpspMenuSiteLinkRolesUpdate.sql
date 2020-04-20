SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspMenuSiteLinkRolesUpdate
(
	@MenuSiteLinkID int,
	@SiteID int,
	@RoleID int,
	@AllowAccess bit,
	@Original_MenuSiteLinkID int,
	@Original_RoleID int,
	@Original_SiteID int,
	@Original_AllowAccess bit
)
AS
	SET NOCOUNT OFF;
UPDATE pMenuSiteLinkRoles SET MenuSiteLinkID = @MenuSiteLinkID, SiteID = @SiteID, RoleID = @RoleID, AllowAccess = @AllowAccess WHERE (MenuSiteLinkID = @Original_MenuSiteLinkID) AND (RoleID = @Original_RoleID) AND (SiteID = @Original_SiteID) AND (AllowAccess = @Original_AllowAccess);
	SELECT MenuSiteLinkID, SiteID, RoleID, AllowAccess FROM pMenuSiteLinkRoles WHERE (MenuSiteLinkID = @MenuSiteLinkID) AND (RoleID = @RoleID) AND (SiteID = @SiteID)


GO
GRANT EXECUTE ON  [dbo].[vpspMenuSiteLinkRolesUpdate] TO [VCSPortal]
GO
