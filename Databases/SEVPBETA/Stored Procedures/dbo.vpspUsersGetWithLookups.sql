SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE     PROCEDURE [dbo].[vpspUsersGetWithLookups]
/************************************************************
* CREATED:     2/1/06  SDE
* MODIFIED:    
*
* USAGE:
*   Returns a User or all Users and the associated Lookups.
*	
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    UserID 
*
* OUTPUT PARAMETERS
*   
* RETURN VALUE
*   
************************************************************/
(@UserID int)
AS
SET NOCOUNT ON;

DECLARE @defaultsiteid int
SET @defaultsiteid = 0

select pUsers.UserID, 
	pUsers.UserName, 
	pUsers.PID, 
	pUsers.SID, 
	IsNull(pUsers.LastPIDChange, 'Jan  1 1901 12:00:00:000AM') as 'LastPIDChange', 
	pUsers.FirstName, 
	pUsers.MiddleName, 
	pUsers.LastName, 
	IsNull(pUsers.LastLogin, 'Jan  1 1901 12:00:00:000AM') as 'LastLogin', 
	IsNull(pUsers.PRCo, -1) as 'PRCo', 
	IsNull(HQCOPayroll.Name, 'Not Set') as 'PRCoName', 
	IsNull(pUsers.PREmployee, -1) as 'PREmployee',
	IsNull(PREH.FirstName + ' ' + PREH.LastName, 'Not Set') as 'PREmployeeName', 
	IsNull(pUsers.HRCo, -1) as 'HRCo', 
	IsNull(HQCO.Name, 'Not Set') as 'HRCoName', 
	IsNull(pUsers.HRRef, -1) as 'HRRef', 
	IsNull(HRRM.FirstName + ' ' + HRRM.LastName, 'Not Set') as 'HRRefName', 
	IsNull(pUsers.VendorGroup, -1) as 'VendorGroup', 
	IsNull(HQGPVendor.Description, 'Not Set') as 'VendorGroupName', 
	IsNull(pUsers.Vendor, -1) as 'Vendor', 
	IsNull(APVM.Name, 'Not Set') as 'VendorName', 
	IsNull(pUsers.CustGroup, -1) as 'CustGroup', 
	IsNull(HQGP.Description, 'Not Set') as 'CustGroupName', 
	IsNull(pUsers.Customer, -1) as 'Customer', 
	IsNull(ARCM.Name, 'Not Set') as 'CustomerName', 
	IsNull(pUsers.FirmNumber, -1) as 'FirmNumber', 
	IsNull(PMFM.FirmName, 'Not Set') as 'FirmName', 
	IsNull(pUsers.Contact, -1) as 'Contact', 
	IsNull(PMPM.FirstName + ' ' + PMPM.LastName, 'Not Set') as 'ContactName', 
	IsNull(pUsers.DefaultSiteID, @defaultsiteid) as 'DefaultSiteID' 
	FROM pUsers with (nolock) 
	left join HQCO with (nolock) on HQCO.HQCo = pUsers.HRCo
	left join HQCO HQCOPayroll with (nolock) on HQCOPayroll.HQCo = pUsers.PRCo
	left join HRRM with (nolock) on HRRM.HRCo = pUsers.HRCo and HRRM.HRRef = pUsers.HRRef
	left join PREH with (nolock) on PREH.PRCo = pUsers.PRCo and PREH.Employee = pUsers.PREmployee
	left join HQGP with (nolock) on HQGP.Grp = pUsers.CustGroup
	left join HQGP HQGPVendor with (nolock) on HQGPVendor.Grp = pUsers.VendorGroup
	left join ARCM with (nolock) on ARCM.CustGroup = pUsers.CustGroup and ARCM.Customer = pUsers.Customer
	left join APVM with (nolock) on APVM.VendorGroup = pUsers.VendorGroup and APVM.Vendor = pUsers.Vendor
	left join PMFM with (nolock) on PMFM.VendorGroup = pUsers.VendorGroup and PMFM.FirmNumber = pUsers.FirmNumber
	left join PMPM with (nolock) on PMPM.VendorGroup = pUsers.VendorGroup and PMPM.FirmNumber = pUsers.FirmNumber and PMPM.ContactCode = pUsers.Contact
	where pUsers.UserID = IsNull(@UserID, pUsers.UserID)






GO
GRANT EXECUTE ON  [dbo].[vpspUsersGetWithLookups] TO [VCSPortal]
GO
