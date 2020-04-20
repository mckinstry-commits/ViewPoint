SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspPageTemplateControlSecurityGet
AS
	SET NOCOUNT ON;
SELECT PageTemplateControlID, RoleID, PageTemplateID, AllowAdd, AllowEdit, AllowDelete FROM pPageTemplateControlSecurity


GO
GRANT EXECUTE ON  [dbo].[vpspPageTemplateControlSecurityGet] TO [VCSPortal]
GO
