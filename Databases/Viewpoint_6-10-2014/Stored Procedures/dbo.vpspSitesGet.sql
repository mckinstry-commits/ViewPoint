SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE            PROCEDURE [dbo].[vpspSitesGet]
/************************************************************
* CREATED:     2/8/06  SDE
* MODIFIED:    
*
* USAGE:
*	Gets all Sites and the associated Lookups
*	
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    SiteID
*
* OUTPUT PARAMETERS
*   
* RETURN VALUE
*   
************************************************************/
(@SiteID int = Null)
AS
	SET NOCOUNT ON;
select pSites.SiteID, 
	pSites.Name, 
	IsNull(pSites.JCCo, -1) as 'JCCo', 
	IsNull(HQCO.Name, 'Not Set') as 'JCCoAsString',
	IsNull(pSites.Job, 'Not Set') as 'Job', 
	IsNull(JCJM.Description, 'Not Set') as 'JobAsString',
	pSites.DateCreated, 
	pSites.UserID, 
	pSites.HeaderText, 
	IsNull(pSites.IdleTimeout, -1) as 'IdleTimeout', 
	IsNull(pSites.PageSiteTemplateID, -1) as 'PageSiteTemplateID', 
	pSites.Description, 
	pSites.Notes, 
	pSites.Active, 
	IsNull(pSites.SiteAttachmentID, -1) as 'SiteAttachmentID', 
	IsNull(pSites.MaxAttachmentSize, -1) as 'MaxAttachmentSize',
	IsNull(ISNULL(JCJM.OurFirm, PMCO.OurFirm), -1) As 'OurFirm',
	IsNull(CAST(JCJM.VendorGroup As Int), -1) As 'VendorGroup',
	IsNull(DDCL.KeyID, 1) As 'CultureID'
	FROM pSites  with (nolock)
	left join HQCO with (nolock) on pSites.JCCo = HQCO.HQCo 
	left join JCJM with (nolock) on pSites.Job = JCJM.Job and pSites.JCCo = JCJM.JCCo
    left join PMCO with (nolock) on pSites.JCCo = PMCO.PMCo
    left join DDCL with (nolock) on HQCO.DefaultCountry = RIGHT(DDCL.Culture,2)
	where pSites.SiteID = IsNull(@SiteID, pSites.SiteID)
GO
GRANT EXECUTE ON  [dbo].[vpspSitesGet] TO [VCSPortal]
GO
