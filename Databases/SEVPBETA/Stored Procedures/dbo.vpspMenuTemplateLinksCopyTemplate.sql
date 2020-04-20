SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE    PROCEDURE dbo.vpspMenuTemplateLinksCopyTemplate
(
	@MenuTemplateID int,
	@MenuTemplateIDToCopy int
)
AS
SET NOCOUNT OFF;

--Delete all of the Menu Links for the current Menu Template
DELETE pMenuTemplateLinkRoles WHERE MenuTemplateID = @MenuTemplateID
DELETE pMenuTemplateLinks WHERE MenuTemplateID = @MenuTemplateID

--Copy the Template from MenuLinks
INSERT INTO pMenuTemplateLinks (MenuTemplateLinkID, MenuTemplateID, RoleID, Caption, PageTemplateID, ParentID, MenuLevel, MenuOrder)
(SELECT MenuTemplateLinkID, @MenuTemplateID, RoleID, Caption, 
PageTemplateID, ParentID, MenuLevel, MenuOrder FROM pMenuTemplateLinks WHERE MenuTemplateID = @MenuTemplateIDToCopy)

--Copy the Role Security records for the Menu Template
INSERT INTO pMenuTemplateLinkRoles (MenuTemplateLinkID, MenuTemplateID, RoleID, AllowAccess)
  (SELECT MenuTemplateLinkID, @MenuTemplateID, RoleID, AllowAccess FROM pMenuTemplateLinkRoles
  	WHERE MenuTemplateID = @MenuTemplateIDToCopy) 







GO
GRANT EXECUTE ON  [dbo].[vpspMenuTemplateLinksCopyTemplate] TO [VCSPortal]
GO
