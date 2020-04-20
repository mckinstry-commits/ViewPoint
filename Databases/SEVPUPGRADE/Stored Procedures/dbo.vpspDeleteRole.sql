SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  PROCEDURE [dbo].[vpspDeleteRole]
 (
 	@RoleID int,
	@Message varchar(255) OUTPUT
 )
 AS
 	
SET NOCOUNT OFF;

SELECT @Message = ''

--Check to make sure the role has been marked as InActive, that there are 
--currently no users assigned to this role and that the role is not marked as static
IF EXISTS (SELECT * FROM pRoles WHERE RoleID = @RoleID AND Active = 1)
	BEGIN
	--PRINT 'Still Active'
	SELECT @Message = 'Cannot delete a Role that is still active.'
	GOTO vpspExit
	END

IF EXISTS (SELECT * FROM pRoles WHERE RoleID = @RoleID AND Static = 1)
	BEGIN
	--PRINT 'Static Role'
	SELECT @Message = 'Cannot delete a Role that has been marked as static.'
	GOTO vpspExit
	END

IF EXISTS (SELECT * FROM pUserSites WHERE RoleID = @RoleID)
	BEGIN
	SELECT @Message = 'Cannot delete a Role that still has users assigned.'
	GOTO vpspExit
	END

DELETE FROM pPageTemplateControlSecurity WHERE RoleID = @RoleID
DELETE FROM pPortalControlSecurityTemplate WHERE RoleID = @RoleID
DELETE FROM pMenuTemplateLinkRoles WHERE RoleID = @RoleID
DELETE FROM pPageSiteControlSecurity WHERE RoleID = @RoleID
DELETE FROM pMenuSiteLinkRoles WHERE RoleID = @RoleID

UPDATE pPageTemplateControls SET RoleID = 2 WHERE RoleID = @RoleID
UPDATE pMenuTemplateLinks SET RoleID = 2 WHERE RoleID = @RoleID
UPDATE pMenuTemplates SET RoleID = 2 WHERE RoleID = @RoleID
UPDATE pPageTemplates SET RoleID = 2 WHERE RoleID = @RoleID
UPDATE pPageSiteControls SET RoleID = 2 WHERE RoleID = @RoleID
UPDATE pPortalControlButtons SET RoleID = 2 WHERE RoleID = @RoleID
UPDATE pPageSiteTemplates SET RoleID = 2 WHERE RoleID = @RoleID
UPDATE pMenuSiteLinks SET RoleID = 2 WHERE RoleID = @RoleID
UPDATE pPageTemplateControls SET RoleID = 2 WHERE RoleID = @RoleID
  
vpspExit:
	RETURN

GO
GRANT EXECUTE ON  [dbo].[vpspDeleteRole] TO [VCSPortal]
GO
