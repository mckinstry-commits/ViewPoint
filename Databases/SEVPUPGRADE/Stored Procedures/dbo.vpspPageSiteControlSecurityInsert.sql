SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspPageSiteControlSecurityInsert
(
	@PageSiteControlID int,
	@RoleID int,
	@SiteID int,
	@AllowAdd bit,
	@AllowEdit bit,
	@AllowDelete bit
)
AS
	SET NOCOUNT OFF;
INSERT INTO pPageSiteControlSecurity(PageSiteControlID, RoleID, SiteID, AllowAdd, AllowEdit, AllowDelete) VALUES (@PageSiteControlID, @RoleID, @SiteID, @AllowAdd, @AllowEdit, @AllowDelete);
	SELECT PageSiteControlID, RoleID, SiteID, AllowAdd, AllowEdit, AllowDelete FROM pPageSiteControlSecurity WHERE (PageSiteControlID = @PageSiteControlID) AND (RoleID = @RoleID)


GO
GRANT EXECUTE ON  [dbo].[vpspPageSiteControlSecurityInsert] TO [VCSPortal]
GO
