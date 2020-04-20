SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE    PROCEDURE dbo.vpspPageSiteTemplatesGet
AS
SET NOCOUNT ON;
SELECT PageSiteTemplateID, SiteID, ISNULL(PageTemplateID, -1) AS PageTemplateID, RoleID, AvailableToMenu, Name, Description, Notes 
	FROM pPageSiteTemplates



GO
GRANT EXECUTE ON  [dbo].[vpspPageSiteTemplatesGet] TO [VCSPortal]
GO
