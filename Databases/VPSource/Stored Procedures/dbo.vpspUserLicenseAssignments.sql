SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Chris G
-- Create date: 2/03/2010
-- Description:	
--		Procedure to retrieve Portal users and their associated license assignments.
-- Inputs:
--	Currently no inputs.  In the future additional filtering options can be added here.
--
-- Outputs:
--	All users and associated information and license types.
--	@msg				Error message
--
-- Return code:
--	0 = success, 1 = error w/messsge
-- =============================================
CREATE PROCEDURE [dbo].[vpspUserLicenseAssignments] 
	(@msg varchar(255) output)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Uses a Pivot table to turn the license assignments from rows in the pLicenseType
	-- table to columns in the returned data.  Licenses type IDs are hard coded so
	-- if additional license types are added, the IDs need to be added to the pivot table.
	SELECT
		UserID AS 'User ID', 
		UserName AS 'User Name',
		-----------------------------------------------------------------
	   -- License Type columns.  Format as 'LTID[X]' where X is the license
	   -- type ID from pLicenseType.  The code replaces the name with
	   -- the abbreviated description by matching X to the ID in the
	   -- pLicenseType table to make them somewhat dynamic.
	   [1] AS 'LTID1',
	   [2] AS 'LTID2',
	   [3] AS 'LTID3',
	   -----------------------------------------------------------------
		FirstName AS 'First Name', 
		MiddleName AS 'Middle Name', 
		LastName AS 'Last Name',
		VPUserName As 'VP User Name',	
		ISNULL(CAST(PRCo AS INT), NULL) AS 'PR Company',
		PRCoName AS 'PR Company Name',
		PREmployee AS 'Employee',
		ISNULL(PREmployeeLastName + ', ' + PREmployeeFirstName, NULL) as 'Employee Name',
		ISNULL(CAST(HRCo AS INT), NULL) AS 'HR Company', 
		HRCoName AS 'HR Company Name', 
		HRRef 'HR Ref', 
		ISNULL(HRRefLastName  + ', ' + HRRefFirstName + ISNULL(' ' + HRRefMiddleName, '') + ISNULL(' ' + HRRefNameSuffix, ''), NULL) AS 'HR Ref Name',
		VendorGroup AS 'Vendor Group', 
		VendorGroupName As 'Vendor Group Name',
		Vendor, 
		VendorName AS 'Vendor Name', 
		CustGroup As 'Customer Group',
		CustGroupName AS 'Customer Group Name',
		Customer,
		CustomerName AS 'Customer Name',
		FirmNumber AS 'Firm',
		FirmName AS 'Firm Name',
		Contact,
		ISNULL(ContactFirstName + ' ' + ContactLastName, NULL) as 'Contact Name'
	FROM
		(
		SELECT pUsers.UserID, 
		pUsers.UserName,
		pUsers.FirstName, 
		pUsers.MiddleName, 
		pUsers.LastName,
		pUsers.VPUserName,
		pUserLicenseType.LicenseTypeID As 'LicenseTypeID',
		DDUP.PRCo AS 'PRCo',
		HQCOPayroll.Name AS 'PRCoName',
		DDUP.Employee AS 'PREmployee',
		PREH.LastName AS 'PREmployeeLastName',
		PREH.FirstName AS 'PREmployeeFirstName',
		DDUP.HRCo AS 'HRCo', 
		HQCO.Name AS 'HRCoName', 
		DDUP.HRRef AS 'HRRef', 
		HRRM.LastName AS 'HRRefLastName',
		HRRM.FirstName AS 'HRRefFirstName', 
		HRRM.MiddleName AS 'HRRefMiddleName', 
		HRRM.Suffix AS 'HRRefNameSuffix',
		pUsers.VendorGroup AS 'VendorGroup', 
		HQGPVendor.Description as 'VendorGroupName', 
		pUsers.Vendor as 'Vendor', 
		APVM.Name as 'VendorName', 
		pUsers.CustGroup as 'CustGroup', 
		HQGP.Description as 'CustGroupName', 
		pUsers.Customer as 'Customer', 
		ARCM.Name as 'CustomerName', 
		pUsers.FirmNumber as 'FirmNumber', 
		PMFM.FirmName as 'FirmName', 
		pUsers.Contact as 'Contact', 
		PMPM.FirstName as 'ContactFirstName',
		PMPM.LastName as 'ContactLastName'
		
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
		left join pUserLicenseType ON pUserLicenseType.UserID = pUsers.UserID
		) AS UserLicenses
	PIVOT
	(
		COUNT(LicenseTypeID) -- This returns 0 is not assigned or 1 if assigned
		FOR UserLicenses.LicenseTypeID IN ([1],[2],[3]) -- License Types
	) AS PivotTable
	ORDER BY Upper(UserName); -- Default sorting.  Grid sorts case insensitive, to be consistent use Upper()
END


GO
GRANT EXECUTE ON  [dbo].[vpspUserLicenseAssignments] TO [VCSPortal]
GO
