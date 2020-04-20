SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspUserSitesUpdate
(
	@UserID int,
	@SiteID int,
	@RoleID int,
	@Original_SiteID int,
	@Original_UserID int,
	@Original_RoleID int
)
AS
	SET NOCOUNT OFF;
UPDATE pUserSites SET UserID = @UserID, SiteID = @SiteID, RoleID = @RoleID WHERE (SiteID = @Original_SiteID) AND (UserID = @Original_UserID) AND (RoleID = @Original_RoleID);
	SELECT UserID, SiteID, RoleID FROM pUserSites WHERE (SiteID = @SiteID) AND (UserID = @UserID)


GO
GRANT EXECUTE ON  [dbo].[vpspUserSitesUpdate] TO [VCSPortal]
GO
