SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


AS
	SET NOCOUNT ON;
SELECT RoleID, PortalControlID, AllowAdd, AllowEdit, AllowDelete FROM pPortalControlSecurityTemplate


GO
GRANT EXECUTE ON  [dbo].[vpspPortalControlSecurityTemplateGet] TO [VCSPortal]
GO