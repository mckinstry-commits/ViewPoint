SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE      PROCEDURE dbo.vpspMenuSiteLinksDelete
(
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

IF @Original_PageSiteTemplateID = -1 SET @Original_PageSiteTemplateID = NULL
IF @Original_MenuTemplateID = -1 SET @Original_MenuTemplateID = NULL

DELETE FROM pMenuSiteLinks WHERE (MenuSiteLinkID = @Original_MenuSiteLinkID) 
	AND (SiteID = @Original_SiteID) 
	AND (Caption = @Original_Caption) 
	AND (MenuLevel = @Original_MenuLevel) 
	AND (MenuOrder = @Original_MenuOrder) 
	AND (MenuTemplateID = @Original_MenuTemplateID OR (@Original_MenuTemplateID IS NULL AND MenuTemplateID IS NULL))
	AND (PageSiteTemplateID = @Original_PageSiteTemplateID OR @Original_PageSiteTemplateID IS NULL AND PageSiteTemplateID IS NULL) 
	AND (ParentID = @Original_ParentID) 
	AND (RoleID = @Original_RoleID)





GO
GRANT EXECUTE ON  [dbo].[vpspMenuSiteLinksDelete] TO [VCSPortal]
GO
