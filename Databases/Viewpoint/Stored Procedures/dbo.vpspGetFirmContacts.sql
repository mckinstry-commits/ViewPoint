SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vpspGetFirmContacts]
/************************************************************
* CREATED:     SDE 8/16/2007
* MODIFIED:    
*
* USAGE:
*   Gets a list of Firm Contacts from PMPM to be used to initialize
*	Portal Users.
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

select PMPM.VendorGroup, PMPM.FirmNumber, PMPM.ContactCode, PMPM.SortName, PMPM.LastName, 
	PMPM.FirstName, PMPM.MiddleInit, PMPM.Title, PMPM.Phone, PMPM.PhoneExt, PMPM.MobilePhone, 
	PMPM.Fax, PMPM.EMail, PMPM.PrefMethod, PMPM.Notes, PMPM.UniqueAttchID, PMPM.ExcludeYN,
	PMPM.AllowPortalAccess, PMPM.PortalUserName, PMPM.PortalPassword, 
	IsNull(PMPM.PortalDefaultRole, -1) as PortalDefaultRole, PMFM.Vendor, PMPM.KeyID
	from PMPM with (nolock) 
	inner join PMFM with (nolock) on PMPM.VendorGroup = PMFM.VendorGroup and PMPM.FirmNumber = PMFM.FirmNumber 
	where PMPM.ExcludeYN = 'N' and PMPM.AllowPortalAccess = 'Y' and PMPM.EMail Is Not Null and PMPM.PortalPassword Is Not Null


GO
GRANT EXECUTE ON  [dbo].[vpspGetFirmContacts] TO [VCSPortal]
GO
