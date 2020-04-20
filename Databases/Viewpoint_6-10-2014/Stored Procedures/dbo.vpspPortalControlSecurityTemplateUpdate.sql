SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspPortalControlSecurityTemplateUpdate
(
	@RoleID int,
	@PortalControlID int,
	@AllowAdd bit,
	@AllowEdit bit,
	@AllowDelete bit,
	@Original_PortalControlID int,
	@Original_RoleID int,
	@Original_AllowAdd bit,
	@Original_AllowDelete bit,
	@Original_AllowEdit bit
)
AS
	SET NOCOUNT OFF;
UPDATE pPortalControlSecurityTemplate SET RoleID = @RoleID, PortalControlID = @PortalControlID, AllowAdd = @AllowAdd, AllowEdit = @AllowEdit, AllowDelete = @AllowDelete WHERE (PortalControlID = @Original_PortalControlID) AND (RoleID = @Original_RoleID) AND (AllowAdd = @Original_AllowAdd) AND (AllowDelete = @Original_AllowDelete) AND (AllowEdit = @Original_AllowEdit);
	SELECT RoleID, PortalControlID, AllowAdd, AllowEdit, AllowDelete FROM pPortalControlSecurityTemplate WHERE (PortalControlID = @PortalControlID) AND (RoleID = @RoleID)


GO
GRANT EXECUTE ON  [dbo].[vpspPortalControlSecurityTemplateUpdate] TO [VCSPortal]
GO
