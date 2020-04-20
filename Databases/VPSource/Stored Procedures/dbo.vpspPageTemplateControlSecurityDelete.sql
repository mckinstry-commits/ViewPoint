SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  PROCEDURE dbo.vpspPageTemplateControlSecurityDelete
(
	@Original_PageTemplateControlID int,
	@Original_RoleID int,
	@Original_AllowAdd bit,
	@Original_AllowDelete bit,
	@Original_AllowEdit bit,
	@Original_PageTemplateID int
)
AS
	SET NOCOUNT OFF;
DELETE FROM pPageTemplateControlSecurity WHERE (PageTemplateControlID = @Original_PageTemplateControlID) AND (RoleID = @Original_RoleID) AND (AllowAdd = @Original_AllowAdd) AND (AllowDelete = @Original_AllowDelete) AND (AllowEdit = @Original_AllowEdit) AND (PageTemplateID = @Original_PageTemplateID)


GO
GRANT EXECUTE ON  [dbo].[vpspPageTemplateControlSecurityDelete] TO [VCSPortal]
GO
