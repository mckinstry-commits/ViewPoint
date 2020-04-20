SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE dbo.vpspMenuTemplatesGet
AS
	SET NOCOUNT ON;
SELECT m.MenuTemplateID, m.RoleID, m.Name, m.Description, m.Notes, r.Name As 'RoleName'  
FROM pMenuTemplates m INNER JOIN pRoles r ON
m.RoleID = r.RoleID 


GO
GRANT EXECUTE ON  [dbo].[vpspMenuTemplatesGet] TO [VCSPortal]
GO
