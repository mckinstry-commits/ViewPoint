SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE      PROCEDURE dbo.vpspMenuTemplateLinksInsert
(
	@MenuTemplateLinkID int,
	@MenuTemplateID int,
	@RoleID int,
	@Caption varchar(50),
	@PageTemplateID int,
	@ParentID int,
	@MenuLevel int,
	@MenuOrder int
)
AS
DECLARE @newmenutemplatelinkid int
SET NOCOUNT OFF;
if @MenuTemplateLinkID < 0 
	begin
	select @newmenutemplatelinkid = isnull(max(MenuTemplateLinkID), 0) + 1 
	from pMenuTemplateLinks where MenuTemplateID = @MenuTemplateID
	end
if @MenuTemplateLinkID > 0
	begin
	select @newmenutemplatelinkid = @MenuTemplateLinkID
	end

IF @PageTemplateID = -1 SET @PageTemplateID = NULL

INSERT INTO pMenuTemplateLinks(MenuTemplateLinkID, MenuTemplateID, RoleID, Caption, PageTemplateID, 
ParentID, MenuLevel, MenuOrder) VALUES (@newmenutemplatelinkid, @MenuTemplateID, @RoleID, @Caption, 
@PageTemplateID, @ParentID, @MenuLevel, @MenuOrder);
SELECT MenuTemplateLinkID, MenuTemplateID, RoleID, Caption, PageTemplateID, ParentID, MenuLevel, 
MenuOrder FROM pMenuTemplateLinks WHERE (MenuTemplateID = @MenuTemplateID) 
AND (MenuTemplateLinkID = @newmenutemplatelinkid)



GO
GRANT EXECUTE ON  [dbo].[vpspMenuTemplateLinksInsert] TO [VCSPortal]
GO
