SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspMenuTemplateLinkRolesInsert
(
	@MenuTemplateLinkID int,
	@MenuTemplateID int,
	@RoleID int,
	@AllowAccess bit
)
AS
	SET NOCOUNT OFF;
INSERT INTO pMenuTemplateLinkRoles(MenuTemplateLinkID, MenuTemplateID, RoleID, AllowAccess) VALUES (@MenuTemplateLinkID, @MenuTemplateID, @RoleID, @AllowAccess);
	SELECT MenuTemplateLinkID, MenuTemplateID, RoleID, AllowAccess FROM pMenuTemplateLinkRoles WHERE (MenuTemplateID = @MenuTemplateID) AND (MenuTemplateLinkID = @MenuTemplateLinkID) AND (RoleID = @RoleID)


GO
GRANT EXECUTE ON  [dbo].[vpspMenuTemplateLinkRolesInsert] TO [VCSPortal]
GO
