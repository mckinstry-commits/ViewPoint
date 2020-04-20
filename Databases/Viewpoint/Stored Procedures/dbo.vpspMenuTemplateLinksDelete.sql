SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     PROCEDURE dbo.vpspMenuTemplateLinksDelete
(
	@Original_MenuTemplateID int,
	@Original_MenuTemplateLinkID int,
	@Original_Caption varchar(50),
	@Original_MenuLevel int,
	@Original_MenuOrder int,
	@Original_PageTemplateID int,
	@Original_ParentID int,
	@Original_RoleID int
)
AS
	SET NOCOUNT OFF;

IF @Original_PageTemplateID = -1 SET @Original_PageTemplateID = NULL

DELETE FROM pMenuTemplateLinkRoles WHERE RoleID <= 1 AND MenuTemplateLinkID = @Original_MenuTemplateLinkID
AND MenuTemplateID = @Original_MenuTemplateID

-- Delete any Template Links that are assigned to inactive roles
DELETE pMenuTemplateLinkRoles FROM pMenuTemplateLinkRoles 
	INNER JOIN pRoles ON pMenuTemplateLinkRoles.RoleID = pRoles.RoleID
	WHERE pMenuTemplateLinkRoles.MenuTemplateLinkID = @Original_MenuTemplateLinkID AND 
	pMenuTemplateLinkRoles.MenuTemplateID = @Original_MenuTemplateID

DELETE FROM pMenuTemplateLinks WHERE 
(MenuTemplateID = @Original_MenuTemplateID) AND 
(MenuTemplateLinkID = @Original_MenuTemplateLinkID) AND 
(Caption = @Original_Caption) AND 
(MenuLevel = @Original_MenuLevel) AND 
(MenuOrder = @Original_MenuOrder) AND 
(PageTemplateID = @Original_PageTemplateID OR @Original_PageTemplateID IS NULL AND PageTemplateID IS NULL) AND (ParentID = @Original_ParentID) AND (RoleID = @Original_RoleID)
GO
GRANT EXECUTE ON  [dbo].[vpspMenuTemplateLinksDelete] TO [VCSPortal]
GO
