SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspImportProjectFirmContactsToUserSites]
/************************************************************
* CREATED:     SDE 12/12/2006
* MODIFIED:    JB 10/29/09		- Recreated this SP because it was missing
*								In the current version. No functionality change.
*			   CJG 3/4/10       - Issue 143290 - Handle case where Firm Contact not yet imported as a pUser
*
* USAGE:
*   Imports PM Project Firm Contacts (PMPF) into pUserSites
*     if they are allowed PortalSiteAccess in PM Project Firms
*     and they exist in pUsers
*
* CALLED FROM:
*     ViewpointCS Portal  
*
* INPUT PARAMETERS
*     @SiteID
*
* OUTPUT PARAMETERS
*   
* RETURN VALUE
*   
************************************************************/
(@SiteID INT)
AS
    SET NOCOUNT OFF;

	INSERT INTO pUserSites 
		(
		UserID, 
		SiteID, 
		RoleID
		) 
	SELECT 
		pUsers.UserID, 
		pSites.SiteID, 
		ISNULL(PMPM.PortalDefaultRole, 3) AS RoleID
    FROM PMPF WITH (NOLOCK) 
        INNER JOIN PMPM WITH (NOLOCK) ON PMPF.FirmNumber = PMPM.FirmNumber AND PMPF.ContactCode = PMPM.ContactCode AND PMPF.VendorGroup = PMPM.VendorGroup
        INNER JOIN pSites WITH (NOLOCK) ON PMPF.PMCo = pSites.JCCo AND PMPF.Project = pSites.Job 
        LEFT JOIN pUsers WITH (NOLOCK) ON pUsers.UserName = ISNULL(PMPM.PortalUserName, PMPM.SortName)
    WHERE 
		PMPF.PortalSiteAccess = 'Y' 
		AND pUsers.UserID IS NOT NULL
		AND NOT EXISTS(SELECT TOP 1 1 FROM pUserSites WHERE SiteID = pSites.SiteID AND UserID = pUsers.UserID)
        AND pSites.SiteID = @SiteID

GO
GRANT EXECUTE ON  [dbo].[vpspImportProjectFirmContactsToUserSites] TO [VCSPortal]
GO
