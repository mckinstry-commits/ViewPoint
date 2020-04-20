SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspPageSiteControlSecurityDelete
(
	@Original_PageSiteControlID int,
	@Original_RoleID int,
	@Original_AllowAdd bit,
	@Original_AllowDelete bit,
	@Original_AllowEdit bit,
	@Original_SiteID int
)
AS
	SET NOCOUNT OFF;
DELETE FROM pPageSiteControlSecurity WHERE (PageSiteControlID = @Original_PageSiteControlID) AND (RoleID = @Original_RoleID) AND (AllowAdd = @Original_AllowAdd) AND (AllowDelete = @Original_AllowDelete) AND (AllowEdit = @Original_AllowEdit) AND (SiteID = @Original_SiteID)


GO
GRANT EXECUTE ON  [dbo].[vpspPageSiteControlSecurityDelete] TO [VCSPortal]
GO
