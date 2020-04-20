SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE    PROCEDURE dbo.vpspRolesCleanup
/************************************************************
* CREATED:     SDE 5/16/2005
* MODIFIED:    
*
* USAGE:
*   	Deletes all pointers to the RoleID that has been removed
*   	in other tables.
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
* 	RoleID
*
* OUTPUT PARAMETERS
*   
* RETURN VALUE
*   
************************************************************/
(
	@RoleID int
)
AS
	SET NOCOUNT OFF;
--MenuSiteLinkRoles
delete from pMenuSiteLinkRoles where RoleID = @RoleID
--MenuSiteLinks
delete from pMenuSiteLinks where RoleID = @RoleID
--MenuTemplateLinks
delete from pMenuTemplateLinks where RoleID = @RoleID
--MenuTemplates
delete from pMenuTemplates where RoleID = @RoleID
--PageSiteControls
delete from pPageSiteControls where RoleID = @RoleID
--PageTemplateControls
delete from pPageTemplateControls where RoleID = @RoleID
--PageTemplates
delete from pPageTemplates where RoleID = @RoleID
--UserSites
delete from pUserSites where RoleID = @RoleID


GO
GRANT EXECUTE ON  [dbo].[vpspRolesCleanup] TO [VCSPortal]
GO
