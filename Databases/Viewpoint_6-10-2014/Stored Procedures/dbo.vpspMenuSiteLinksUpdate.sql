SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE       PROCEDURE dbo.vpspMenuSiteLinksUpdate
(
	@MenuSiteLinkID int,
	@SiteID int,
	@MenuTemplateID int,
	@RoleID int,
	@Caption varchar(50),
	@PageSiteTemplateID int,
	@ParentID int,
	@MenuLevel int,
	@MenuOrder int,
	@Original_MenuSiteLinkID int,
	@Original_SiteID int,
	@Original_Caption varchar(50),
	@Original_MenuLevel int,
	@Original_MenuOrder int,
	@Original_MenuTemplateID int,
	@Original_PageSiteTemplateID int,
	@Original_ParentID int,
	@Original_RoleID int
)
AS
SET NOCOUNT OFF;

IF @PageSiteTemplateID = -1 SET @PageSiteTemplateID = NULL
IF @Original_PageSiteTemplateID = -1 SET @Original_PageSiteTemplateID = NULL

IF @MenuTemplateID = -1 SET @MenuTemplateID = NULL
IF @Original_MenuTemplateID = -1 SET @Original_MenuTemplateID = NULL

UPDATE pMenuSiteLinks SET MenuSiteLinkID = @MenuSiteLinkID, SiteID = @SiteID, 
	MenuTemplateID = @MenuTemplateID, RoleID = @RoleID, Caption = @Caption, 
	PageSiteTemplateID = @PageSiteTemplateID, ParentID = @ParentID, MenuLevel = @MenuLevel, 
	MenuOrder = @MenuOrder 
	WHERE 
		(MenuSiteLinkID = @Original_MenuSiteLinkID) AND 
		(SiteID = @Original_SiteID) AND 
		(Caption = @Original_Caption) AND 
		(MenuLevel = @Original_MenuLevel) AND 
		(MenuOrder = @Original_MenuOrder) AND 
		(MenuTemplateID = @Original_MenuTemplateID OR (@Original_MenuTemplateID IS NULL AND MenuTemplateID IS NULL)) AND 
		(ParentID = @Original_ParentID) AND 
        (RoleID = @Original_RoleID);
	
SELECT MenuSiteLinkID, SiteID, MenuTemplateID, RoleID, Caption, PageSiteTemplateID, ParentID, 
	MenuLevel, MenuOrder 
	FROM pMenuSiteLinks 
	WHERE (MenuSiteLinkID = @MenuSiteLinkID) AND (SiteID = @SiteID)






GO
GRANT EXECUTE ON  [dbo].[vpspMenuSiteLinksUpdate] TO [VCSPortal]
GO
