SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE    PROCEDURE dbo.vpspMenuTemplateLinksUpdate
(
	@MenuTemplateLinkID int,
	@MenuTemplateID int,
	@RoleID int,
	@Caption varchar(50),
	@PageTemplateID int,
	@ParentID int,
	@MenuLevel int,
	@MenuOrder int,
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

IF @PageTemplateID = -1 SET @PageTemplateID = NULL
IF @Original_PageTemplateID = -1 SET @Original_PageTemplateID = NULL

UPDATE pMenuTemplateLinks SET MenuTemplateLinkID = @MenuTemplateLinkID, 
	MenuTemplateID = @MenuTemplateID, RoleID = @RoleID, Caption = @Caption, 
	PageTemplateID = @PageTemplateID, ParentID = @ParentID, MenuLevel = @MenuLevel, 
	MenuOrder = @MenuOrder 
WHERE 
	(MenuTemplateID = @Original_MenuTemplateID) AND 
	(MenuTemplateLinkID = @Original_MenuTemplateLinkID) AND 
	(Caption = @Original_Caption) AND 
	(MenuLevel = @Original_MenuLevel) AND 
	(MenuOrder = @Original_MenuOrder) AND 
	(PageTemplateID = @Original_PageTemplateID OR (@Original_PageTemplateID IS NULL AND PageTemplateID IS NULL)) AND 
	(ParentID = @Original_ParentID) AND 
	(RoleID = @Original_RoleID);
	SELECT MenuTemplateLinkID, MenuTemplateID, RoleID, Caption, PageTemplateID, ParentID, 
		MenuLevel, MenuOrder FROM pMenuTemplateLinks 
	WHERE (MenuTemplateID = @MenuTemplateID) AND (MenuTemplateLinkID = @MenuTemplateLinkID)




GO
GRANT EXECUTE ON  [dbo].[vpspMenuTemplateLinksUpdate] TO [VCSPortal]
GO
