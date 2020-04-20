SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- Create Procedure
CREATE         procedure [dbo].[vpspGetPageInformation]
/************************************************************
* CREATED:     GWC 03/24/2005
* MODIFIED:    TEJ 01/29/2010
*
* USAGE:
*   Returns: All the data from the following tables in the following order:
*            vpspPageTemplateControlsGet
*            vpspPageTemplatesGet
*            vpspPageSiteControlsGet
*            vpspPortalControlsGet
*            vpspPortalControlSecurityTemplateGet
*            vpspPageSiteTemplatesGet
*            vpspPageSiteControlSecurityGet
*            vpspPageTemplateControlSecurityGet
*            vpspPortalControlLicenseTypeGet 
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* RETURN VALUE
*   
************************************************************/
as
set nocount on
--Get PageControls
exec dbo.vpspPageTemplateControlsGet
--Get Pages
exec dbo.vpspPageTemplatesGet
--Get Page Site Controls
exec dbo.vpspPageSiteControlsGet
--Get PortalControls
exec dbo.vpspPortalControlsGet
--Get Portal Control Security Template
exec dbo.vpspPortalControlSecurityTemplateGet
--Get Page Site Templates
exec dbo.vpspPageSiteTemplatesGet
--Get PageSiteControl Security
exec dbo.vpspPageSiteControlSecurityGet
--Get PageTemplateControl Security
exec dbo.vpspPageTemplateControlSecurityGet
--Get PortalControl To LicenseType Links
exec dbo.vpspPortalControlLicenseTypeGet 

GO
GRANT EXECUTE ON  [dbo].[vpspGetPageInformation] TO [VCSPortal]
GO
