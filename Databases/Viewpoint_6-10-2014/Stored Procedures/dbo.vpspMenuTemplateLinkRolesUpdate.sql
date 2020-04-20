SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspMenuTemplateLinkRolesUpdate
(
	@MenuTemplateLinkID int,
	@MenuTemplateID int,
	@RoleID int,
	@AllowAccess bit,
	@Original_MenuTemplateID int,
	@Original_MenuTemplateLinkID int,
	@Original_RoleID int,
	@Original_AllowAccess bit
)
AS
	SET NOCOUNT OFF;
UPDATE pMenuTemplateLinkRoles SET MenuTemplateLinkID = @MenuTemplateLinkID, MenuTemplateID = @MenuTemplateID, RoleID = @RoleID, AllowAccess = @AllowAccess WHERE (MenuTemplateID = @Original_MenuTemplateID) AND (MenuTemplateLinkID = @Original_MenuTemplateLinkID) AND (RoleID = @Original_RoleID) AND (AllowAccess = @Original_AllowAccess);
	SELECT MenuTemplateLinkID, MenuTemplateID, RoleID, AllowAccess FROM pMenuTemplateLinkRoles WHERE (MenuTemplateID = @MenuTemplateID) AND (MenuTemplateLinkID = @MenuTemplateLinkID) AND (RoleID = @RoleID)


GO
GRANT EXECUTE ON  [dbo].[vpspMenuTemplateLinkRolesUpdate] TO [VCSPortal]
GO
