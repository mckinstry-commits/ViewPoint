SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspUserSitesDelete
(
	@Original_SiteID int,
	@Original_UserID int,
	@Original_RoleID int
)
AS
	SET NOCOUNT OFF;
DELETE FROM pUserSites WHERE (SiteID = @Original_SiteID) AND (UserID = @Original_UserID) AND (RoleID = @Original_RoleID)


GO
GRANT EXECUTE ON  [dbo].[vpspUserSitesDelete] TO [VCSPortal]
GO
