SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE     PROCEDURE dbo.vpspPageTemplatesGet
AS
	
SET NOCOUNT ON;
SELECT PageTemplateID, RoleID, ISNULL(PatriarchID, -1) as 'PatriarchID', AvailableToMenu, Name, Description, Notes 
	FROM pPageTemplates



GO
GRANT EXECUTE ON  [dbo].[vpspPageTemplatesGet] TO [VCSPortal]
GO
