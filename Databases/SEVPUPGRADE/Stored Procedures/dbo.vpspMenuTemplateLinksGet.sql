SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE     PROCEDURE dbo.vpspMenuTemplateLinksGet
AS
	SET NOCOUNT ON;
SELECT MenuTemplateLinkID, MenuTemplateID, RoleID, Caption,
IsNull(PageTemplateID, -1) AS 'PageTemplateID', ParentID, MenuLevel, MenuOrder 
FROM pMenuTemplateLinks ORDER BY MenuTemplateID, MenuLevel, 
ParentID, MenuOrder



GO
GRANT EXECUTE ON  [dbo].[vpspMenuTemplateLinksGet] TO [VCSPortal]
GO
