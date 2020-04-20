SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vpspGetProjectFirmContacts]
/************************************************************
* CREATED:     SDE 8/16/2007
* MODIFIED:    
*
* USAGE:
*   Gets a list of Project Firm Contacts from PMPF to be used to initialize
*	Portal Site Users.  
*
*
* CALLED FROM:
*	Portal  
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

select PMPF.*, pSites.SiteID from PMPF with (nolock) 
	inner join pSites with (nolock)	on PMPF.PMCo = pSites.JCCo and PMPF.Project = pSites.Job 
	where PMPF.PortalSiteAccess = 'Y'
GO
GRANT EXECUTE ON  [dbo].[vpspGetProjectFirmContacts] TO [VCSPortal]
GO
