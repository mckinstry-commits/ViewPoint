SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  PROCEDURE [dbo].[vpspLicenseTypeDelete]
/************************************************************
* CREATED:     Tom J - 2/17/2010
* MODIFIED:    
*
* USAGE:
*   Deletes a LicenseType Resource Contact, Cleans up the pPortalControlLicenseType and pUserLicenseType link tables
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*   Original_ID: Id of the LicenseType To Delete
************************************************************/
(
	@Original_ID int
)
AS

DELETE FROM pUserLicenseType WHERE LicenseTypeID = @Original_ID;
DELETE FROM pPortalControlLicenseType WHERE LicenseTypeID = @Original_ID;
DELETE FROM pLicenseType WHERE LicenseTypeID = @Original_ID;


GO
GRANT EXECUTE ON  [dbo].[vpspLicenseTypeDelete] TO [VCSPortal]
GO
