SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspMenuTemplateLinkRolesGet
AS
	SET NOCOUNT ON;
SELECT MenuTemplateLinkID, MenuTemplateID, RoleID, AllowAccess FROM pMenuTemplateLinkRoles


GO
GRANT EXECUTE ON  [dbo].[vpspMenuTemplateLinkRolesGet] TO [VCSPortal]
GO
