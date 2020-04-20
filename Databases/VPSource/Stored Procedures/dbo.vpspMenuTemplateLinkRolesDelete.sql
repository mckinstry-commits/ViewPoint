SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspMenuTemplateLinkRolesDelete
(
	@Original_MenuTemplateID int,
	@Original_MenuTemplateLinkID int,
	@Original_RoleID int,
	@Original_AllowAccess bit
)
AS
	SET NOCOUNT OFF;
DELETE FROM pMenuTemplateLinkRoles WHERE (MenuTemplateID = @Original_MenuTemplateID) AND (MenuTemplateLinkID = @Original_MenuTemplateLinkID) AND (RoleID = @Original_RoleID) AND (AllowAccess = @Original_AllowAccess)


GO
GRANT EXECUTE ON  [dbo].[vpspMenuTemplateLinkRolesDelete] TO [VCSPortal]
GO
