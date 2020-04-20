SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  PROCEDURE dbo.vpspPageTemplateControlSecurityInsert
(
	@PageTemplateControlID int,
	@RoleID int,
	@PageTemplateID int,
	@AllowAdd bit,
	@AllowEdit bit,
	@AllowDelete bit
)
AS
	SET NOCOUNT OFF;
INSERT INTO pPageTemplateControlSecurity(PageTemplateControlID, RoleID, PageTemplateID, AllowAdd, AllowEdit, AllowDelete) VALUES (@PageTemplateControlID, @RoleID, @PageTemplateID, @AllowAdd, @AllowEdit, @AllowDelete);
	SELECT PageTemplateControlID, RoleID, PageTemplateID, AllowAdd, AllowEdit, AllowDelete FROM pPageTemplateControlSecurity WHERE (PageTemplateControlID = @PageTemplateControlID) AND (RoleID = @RoleID)


GO
GRANT EXECUTE ON  [dbo].[vpspPageTemplateControlSecurityInsert] TO [VCSPortal]
GO
