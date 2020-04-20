SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE                                           procedure dbo.vpspGetMenuInformation
/************************************************************
* CREATED:     SDE 12/9/2004
* MODIFIED:    
*
* USAGE:
*   Returns: PageSiteControls, MenuSiteLinks and PortalControls
*   
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*        
*
* OUTPUT PARAMETERS
*   
* RETURN VALUE
*   
************************************************************/
as
set nocount on
--Get Menu Links
exec dbo.vpspMenuTemplateLinksGet
--Get Menu Master
exec dbo.vpspMenuTemplatesGet
--Get Menu Site Link Roles
exec dbo.vpspMenuSiteLinkRolesGet
--Get Menu Site Links
exec dbo.vpspMenuSiteLinksGet
--Get Menu Template Link Roles
exec dbo.vpspMenuTemplateLinkRolesGet


GO
GRANT EXECUTE ON  [dbo].[vpspGetMenuInformation] TO [VCSPortal]
GO
