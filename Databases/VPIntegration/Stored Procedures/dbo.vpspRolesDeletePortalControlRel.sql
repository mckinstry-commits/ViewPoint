SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:                            Joe AmRhein
-- Create date: 2011-09-08
-- Description:   Deletes portalControl relationships from Role
-- =============================================
CREATE PROCEDURE [dbo].[vpspRolesDeletePortalControlRel]
(
	@RoleID int
)
AS
	SET NOCOUNT OFF;
DELETE FROM pPageSiteControlSecurity WHERE RoleID = @RoleID
DELETE FROM pMenuSiteLinkRoles WHERE RoleID = @RoleID	
DELETE FROM pPortalControlSecurityTemplate WHERE RoleID = @RoleID;

GO
GRANT EXECUTE ON  [dbo].[vpspRolesDeletePortalControlRel] TO [VCSPortal]
GO
