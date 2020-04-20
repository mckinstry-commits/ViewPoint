SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:                            Joe AmRhein
-- Create date: 2011-09-08
-- Modified date: 2011-11-17 TEJ Changed the queries to determine what records should be added - creates base security
--                               records for every control in the templates and every site control on pages
--
-- Description:   Inserts portalControl relationships for new role
-- =============================================
CREATE PROCEDURE [dbo].[vpspRolesInsertPortalControlRel]
(
	@RoleID int
)
AS
	SET NOCOUNT OFF;

INSERT INTO pPortalControlSecurityTemplate ([PortalControlID],[RoleID],[AllowAdd],[AllowEdit],[AllowDelete],[ClientModified])
SELECT PortalControlID, @RoleID, '0', '0', '0', '0'
  FROM [pPortalControls];

INSERT INTO pPageSiteControlSecurity ([PageSiteControlID],[RoleID],[SiteID],[AllowAdd],[AllowEdit],[AllowDelete])
SELECT PageSiteControlID, @RoleID, SiteID, '0', '0', '0' 
  FROM [pPageSiteControls];
	

GO
GRANT EXECUTE ON  [dbo].[vpspRolesInsertPortalControlRel] TO [VCSPortal]
GO
