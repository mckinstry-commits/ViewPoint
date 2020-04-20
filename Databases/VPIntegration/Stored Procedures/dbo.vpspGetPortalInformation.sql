SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- Create Procedure
CREATE   procedure [dbo].[vpspGetPortalInformation]
/************************************************************
* CREATED:     SDE 10/26/2005
* MODIFIED:    TEJ 01/29/2010
*
* USAGE: 
*   Returns: All the data from the following tables in the following order:
*	Sites from vpspSitesGet, 
*   SiteFooterLinks from vpspSiteFooterLinksGet,
*	SiteAttachments from vpspSiteAttachmentsGet,
*	AttachmentTypes from vpspAttachmentTypesGet,
*	ContactInfoTypes from vpspContactTypesGet,
*	PasswordRules from vpspPasswordRulesGet,
*	Lookups from vpspLookupsGet,
*	LookupColumns from vpspLookupColumnsGet,
*	LinkTypes from pLinkTypesGet,
*   DateTemplates from pDates,
*   LicenseTypes from pLicenseTypes
*
* CALLED FROM:
*	ViewpointCS Portal  
*   
* RETURN VALUE
************************************************************/
as
set nocount on
--Get Sites
exec dbo.vpspSitesGet
--Get SiteFooterLinks
exec dbo.vpspSiteFooterLinksGet
--Get SiteAttachments
exec dbo.vpspSiteAttachmentsGet
--Get SiteAttachmentTypes
exec dbo.vpspAttachmentTypesGet
--Get ContactInfoTypes
exec dbo.vpspContactTypesGet
--Get PasswordRules
exec dbo.vpspPasswordRulesGet
--Get Lookups
exec dbo.vpspLookupsGet
--Get LookupColumns
exec dbo.vpspLookupColumnsGet
--Get LinkTypes
exec dbo.vpspLinkTypesGet
--Get Date Templates
exec dbo.vpspDatesGet
--Get License Types
exec dbo.vpspLicenseTypeGet 
GO
GRANT EXECUTE ON  [dbo].[vpspGetPortalInformation] TO [VCSPortal]
GO
