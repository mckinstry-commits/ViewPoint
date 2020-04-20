SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


(
	@UserID int,
	@SiteID int,
	@RoleID int
)
AS
	SET NOCOUNT OFF;
INSERT INTO pUserSites(UserID, SiteID, RoleID) VALUES (@UserID, @SiteID, @RoleID);
	SELECT UserID, SiteID, RoleID FROM pUserSites WHERE (SiteID = @SiteID) AND (UserID = @UserID)


GO
GRANT EXECUTE ON  [dbo].[vpspUserSitesInsert] TO [VCSPortal]
GO