SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- Create Procedure
CREATE PROCEDURE [dbo].[vpspGetUserInformation]
/************************************************************
* CREATED:     SDE 3/22/2005
* MODIFIED:    TEJ 1/29/2010
*
* USAGE:
*   Returns: All the data from the following tables in the following order:
*	Users from vpspGetUsers,	
*	Roles from vpspGetRoles, 
*	UserContactInfo from vpspGetUserContactInfo, 
*	UserSites from vpspGetUserSites
*   UserLicenseTypes from vpspUserLicenseTypeGet
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* RETURN VALUE
*   
************************************************************/
as
set nocount on
--Get Users
exec dbo.vpspUsersGet
--Get Roles
exec dbo.vpspRolesGet
--Get UserContactInfo
exec dbo.vpspUserContactInfoGet
--Get UserSites
exec dbo.vpspUserSitesGet
-- Get User to LicenseType Links
exec dbo.vpspUserLicenseTypeGet

GO
GRANT EXECUTE ON  [dbo].[vpspGetUserInformation] TO [VCSPortal]
GO
