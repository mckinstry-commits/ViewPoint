SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


AS
	SET NOCOUNT ON;
SELECT PageSiteControlID, RoleID, SiteID, AllowAdd, AllowEdit, AllowDelete FROM pPageSiteControlSecurity


GO
GRANT EXECUTE ON  [dbo].[vpspPageSiteControlSecurityGet] TO [VCSPortal]
GO