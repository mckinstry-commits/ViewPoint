SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[vpspUsersGet]
/************************************************************
* CREATED:		2006/02/01 SDE
* MODIFIED:		2006/10/19 CHS
*				2009/05/18 JB		#132516 - Fixed Incorrect HRRefName coming back
*				2009/07/06 JB		Added DDUP Reference - PRCo, PREmployee, HRCo, HRRef now come from DDUP
*               2011/09/19 TEJ      Added Administer Portal Column to pUsers
*
* USAGE:
*	Gets all Users and the associated Lookups
*	
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*  UserID 
*
* OUTPUT PARAMETERS
*   
* RETURN VALUE
*   
************************************************************/
(@UserID INT = Null)
AS
	SET NOCOUNT ON;

DECLARE @defaultsiteid INT

SET @defaultsiteid = 0

SELECT pUsers.UserID, 
	pUsers.UserName, 
	pUsers.PID, 
	pUsers.SID, 
	pUsers.LastPIDChange, 
	pUsers.FirstName, 
	pUsers.MiddleName, 
	pUsers.LastName, 
	pUsers.LastLogin,
	
	pUsers.VPUserName,
	DDUP.UserType,
	ISNULL(CAST(DDUP.PRCo AS INT), -1) AS 'PRCo',
	ISNULL(HQCOPayroll.Name, 'Not Set') AS 'PRCoName',
	ISNULL(DDUP.Employee, -1) AS 'PREmployee',
	ISNULL(PREH.LastName + ', ' + PREH.FirstName, 'Not Set') as 'PREmployeeName',
	ISNULL(CAST(DDUP.HRCo AS INT), -1) AS 'HRCo', 
	ISNULL(HQCO.Name, 'Not Set') AS 'HRCoName', 
	ISNULL(DDUP.HRRef, -1) AS 'HRRef', 
	ISNULL(HRRM.LastName  + ', ' + HRRM.FirstName + ISNULL(' ' + HRRM.MiddleName, '') + ISNULL(' ' + HRRM.Suffix, ''), 'Not Set') AS 'HRRefName',

	ISNULL(pUsers.VendorGroup, -1) as 'VendorGroup', 
	ISNULL(HQGPVendor.Description, 'Not Set') as 'VendorGroupName', 
	ISNULL(pUsers.Vendor, -1) as 'Vendor', 
	ISNULL(APVM.Name, 'Not Set') as 'VendorName', 
	ISNULL(pUsers.CustGroup, -1) as 'CustGroup', 
	ISNULL(HQGP.Description, 'Not Set') as 'CustGroupName', 
	ISNULL(pUsers.Customer, -1) as 'Customer', 
	ISNULL(ARCM.Name, 'Not Set') as 'CustomerName', 
	ISNULL(pUsers.FirmNumber, -1) as 'FirmNumber', 
	ISNULL(PMFM.FirmName, 'Not Set') as 'FirmName', 
	ISNULL(pUsers.Contact, -1) as 'Contact', 
	ISNULL(PMPM.FirstName + ' ' + PMPM.LastName, 'Not Set') as 'ContactName', 
	ISNULL(pUsers.DefaultSiteID, @defaultsiteid) as 'DefaultSiteID',
	ISNULL(pSites.Name, 'Not Set') as 'DefaultSiteName',
	pUsers.AdministerPortal 
	
	FROM pUsers WITH (NOLOCK) 
	left join DDUP WITH (NOLOCK) ON DDUP.VPUserName = pUsers.VPUserName
	left join HQCO WITH (NOLOCK) ON HQCO.HQCo = DDUP.HRCo
	left join HQCO HQCOPayroll WITH (NOLOCK) ON HQCOPayroll.HQCo = DDUP.PRCo
	left join PREH WITH (NOLOCK) ON PREH.PRCo = DDUP.PRCo and PREH.Employee = DDUP.Employee
	left join HRRM WITH (NOLOCK) ON HRRM.HRCo = DDUP.HRCo and HRRM.HRRef = DDUP.HRRef
	left join pSites WITH (NOLOCK) ON pSites.SiteID = pUsers.DefaultSiteID
	left join HQGP WITH (NOLOCK) ON HQGP.Grp = pUsers.CustGroup
	left join HQGP HQGPVendor WITH (NOLOCK) ON HQGPVendor.Grp = pUsers.VendorGroup
	left join ARCM WITH (NOLOCK) ON ARCM.CustGroup = pUsers.CustGroup and ARCM.Customer = pUsers.Customer
	left join APVM WITH (NOLOCK) ON APVM.VendorGroup = pUsers.VendorGroup and APVM.Vendor = pUsers.Vendor
	left join PMFM WITH (NOLOCK) ON PMFM.VendorGroup = pUsers.VendorGroup and PMFM.FirmNumber = pUsers.FirmNumber
	left join PMPM WITH (NOLOCK) ON PMPM.VendorGroup = pUsers.VendorGroup and PMPM.FirmNumber = pUsers.FirmNumber and PMPM.ContactCode = pUsers.Contact
	
	
	WHERE pUsers.UserID = ISNULL(@UserID, pUsers.UserID)
GO
GRANT EXECUTE ON  [dbo].[vpspUsersGet] TO [VCSPortal]
GO
