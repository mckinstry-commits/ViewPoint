SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspPortalControlSecurityTemplateInsert
(
	@RoleID int,
	@PortalControlID int,
	@AllowAdd bit,
	@AllowEdit bit,
	@AllowDelete bit
)
AS
	SET NOCOUNT OFF;
INSERT INTO pPortalControlSecurityTemplate(RoleID, PortalControlID, AllowAdd, AllowEdit, AllowDelete) VALUES (@RoleID, @PortalControlID, @AllowAdd, @AllowEdit, @AllowDelete);
	SELECT RoleID, PortalControlID, AllowAdd, AllowEdit, AllowDelete FROM pPortalControlSecurityTemplate WHERE (PortalControlID = @PortalControlID) AND (RoleID = @RoleID)


GO
GRANT EXECUTE ON  [dbo].[vpspPortalControlSecurityTemplateInsert] TO [VCSPortal]
GO
