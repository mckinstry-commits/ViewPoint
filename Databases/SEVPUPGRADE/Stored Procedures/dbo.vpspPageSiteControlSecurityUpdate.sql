SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspPageSiteControlSecurityUpdate
(
	@PageSiteControlID int,
	@RoleID int,
	@SiteID int,
	@AllowAdd bit,
	@AllowEdit bit,
	@AllowDelete bit,
	@Original_PageSiteControlID int,
	@Original_RoleID int,
	@Original_AllowAdd bit,
	@Original_AllowDelete bit,
	@Original_AllowEdit bit,
	@Original_SiteID int
)
AS
	SET NOCOUNT OFF;
UPDATE pPageSiteControlSecurity SET PageSiteControlID = @PageSiteControlID, RoleID = @RoleID, SiteID = @SiteID, AllowAdd = @AllowAdd, AllowEdit = @AllowEdit, AllowDelete = @AllowDelete WHERE (PageSiteControlID = @Original_PageSiteControlID) AND (RoleID = @Original_RoleID) AND (AllowAdd = @Original_AllowAdd) AND (AllowDelete = @Original_AllowDelete) AND (AllowEdit = @Original_AllowEdit) AND (SiteID = @Original_SiteID);
	SELECT PageSiteControlID, RoleID, SiteID, AllowAdd, AllowEdit, AllowDelete FROM pPageSiteControlSecurity WHERE (PageSiteControlID = @PageSiteControlID) AND (RoleID = @RoleID)


GO
GRANT EXECUTE ON  [dbo].[vpspPageSiteControlSecurityUpdate] TO [VCSPortal]
GO
