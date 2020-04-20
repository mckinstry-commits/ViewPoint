SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  PROCEDURE dbo.vpspPageTemplateControlSecurityUpdate
(
	@PageTemplateControlID int,
	@RoleID int,
	@PageTemplateID int,
	@AllowAdd bit,
	@AllowEdit bit,
	@AllowDelete bit,
	@Original_PageTemplateControlID int,
	@Original_RoleID int,
	@Original_AllowAdd bit,
	@Original_AllowDelete bit,
	@Original_AllowEdit bit,
	@Original_PageTemplateID int
)
AS
	SET NOCOUNT OFF;
UPDATE pPageTemplateControlSecurity SET PageTemplateControlID = @PageTemplateControlID, RoleID = @RoleID, PageTemplateID = @PageTemplateID, AllowAdd = @AllowAdd, AllowEdit = @AllowEdit, AllowDelete = @AllowDelete WHERE (PageTemplateControlID = @Original_PageTemplateControlID) AND (RoleID = @Original_RoleID) AND (AllowAdd = @Original_AllowAdd) AND (AllowDelete = @Original_AllowDelete) AND (AllowEdit = @Original_AllowEdit) AND (PageTemplateID = @Original_PageTemplateID);
	SELECT PageTemplateControlID, RoleID, PageTemplateID, AllowAdd, AllowEdit, AllowDelete FROM pPageTemplateControlSecurity WHERE (PageTemplateControlID = @PageTemplateControlID) AND (RoleID = @RoleID)


GO
GRANT EXECUTE ON  [dbo].[vpspPageTemplateControlSecurityUpdate] TO [VCSPortal]
GO
