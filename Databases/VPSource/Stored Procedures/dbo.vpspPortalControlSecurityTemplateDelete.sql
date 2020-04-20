SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspPortalControlSecurityTemplateDelete
(
	@Original_PortalControlID int,
	@Original_RoleID int,
	@Original_AllowAdd bit,
	@Original_AllowDelete bit,
	@Original_AllowEdit bit
)
AS
	SET NOCOUNT OFF;
DELETE FROM pPortalControlSecurityTemplate WHERE (PortalControlID = @Original_PortalControlID) AND (RoleID = @Original_RoleID) AND (AllowAdd = @Original_AllowAdd) AND (AllowDelete = @Original_AllowDelete) AND (AllowEdit = @Original_AllowEdit)


GO
GRANT EXECUTE ON  [dbo].[vpspPortalControlSecurityTemplateDelete] TO [VCSPortal]
GO
