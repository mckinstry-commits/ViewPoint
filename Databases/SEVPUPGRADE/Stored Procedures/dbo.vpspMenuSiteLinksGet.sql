SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE       PROCEDURE dbo.vpspMenuSiteLinksGet
AS
SET NOCOUNT ON;
SELECT CAST(MenuSiteLinkID as varchar) As 'MenuSiteLinkID', SiteID, ISNULL(MenuTemplateID, -1) AS 'MenuTemplateID', RoleID, Caption, 
	ISNULL(PageSiteTemplateID, -1) AS 'PageSiteTemplateID', 
	CAST(ParentID as varchar) AS 'ParentID', 
	MenuLevel, MenuOrder 
	FROM pMenuSiteLinks
	ORDER BY SiteID, MenuLevel, ParentID, MenuOrder





GO
GRANT EXECUTE ON  [dbo].[vpspMenuSiteLinksGet] TO [VCSPortal]
GO
