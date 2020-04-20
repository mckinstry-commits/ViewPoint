SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspMenuTemplateLinkSecurityApplyToChildren
(
	@MenuTemplateLinkID int,
	@MenuTemplateID int,
	@Parent bit = 1
)
	
AS
SET NOCOUNT OFF;
DECLARE @childmenutemplatelinkID int
SELECT @childmenutemplatelinkID = MIN(MenuTemplateLinkID) FROM pMenuTemplateLinks 
	WHERE ParentID = @MenuTemplateLinkID AND MenuTemplateID= @MenuTemplateID 
	AND (MenuTemplateLinkID > @childmenutemplatelinkID OR @childmenutemplatelinkID IS NULL)
WHILE @childmenutemplatelinkID IS NOT NULL
BEGIN
	DELETE pMenuTemplateLinkRoles WHERE MenuTemplateLinkID = @childmenutemplatelinkID AND MenuTemplateID = @MenuTemplateID
	
	INSERT INTO pMenuTemplateLinkRoles (MenuTemplateLinkID, RoleID, MenuTemplateID, AllowAccess)
		 (SELECT @childmenutemplatelinkID, RoleID, @MenuTemplateID, AllowAccess FROM pMenuTemplateLinkRoles
		  WHERE MenuTemplateLinkID = @MenuTemplateLinkID AND MenuTemplateID = @MenuTemplateID)
		
	PRINT 'SECURITY RECORDS INSERTED'
	IF EXISTS (SELECT Top 1 1 FROM pMenuTemplateLinks WHERE ParentID = @childmenutemplatelinkID AND MenuTemplateID = @MenuTemplateID)
	BEGIN
		exec vpspMenuTemplateLinkSecurityApplyToChildren @childmenutemplatelinkID, @MenuTemplateID, 0
		PRINT 'RECURSIVE CALL DONE'
	END
	SELECT @childmenutemplatelinkID = MIN(MenuTemplateLinkID) FROM pMenuTemplateLinks 
		WHERE ParentID = @MenuTemplateLinkID AND MenuTemplateID= @MenuTemplateID 
		AND (MenuTemplateLinkID > @childmenutemplatelinkID OR @childmenutemplatelinkID IS NULL)
END
IF @Parent = 1
BEGIN
	--Give full permission to Viewpoint, Portal Admin
	UPDATE pMenuTemplateLinkRoles SET AllowAccess = 1 WHERE RoleID = 0 OR RoleID = 1
	PRINT 'SECURITY RECORDS UPDATED FOR ADMINS'
END


GO
GRANT EXECUTE ON  [dbo].[vpspMenuTemplateLinkSecurityApplyToChildren] TO [VCSPortal]
GO
