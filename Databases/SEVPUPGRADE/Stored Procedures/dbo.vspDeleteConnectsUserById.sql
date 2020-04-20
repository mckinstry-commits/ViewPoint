SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create       PROCEDURE [dbo].[vspDeleteConnectsUserById]
/************************************************************
* CREATED:     KSE 6/28/2012
* MODIFIED:    
*
* USAGE:
*   Deletes a User and associated Records by the UserID
*
* CALLED FROM:
*	ViewpointCS Portal through stored procedure vpspDeleteUser
*	V6
*
* INPUT PARAMETERS
*     UserID       
*
* RETURN VALUE
*   
************************************************************/
(@UserID int)
AS
SET NOCOUNT OFF;
--Delete UserContactInfo for this user
DELETE pUserContactInfo WHERE UserID = @UserID
--Delete UserSites for this user
DELETE pUserSites WHERE UserID = @UserID
-- Delete License Assignments
delete pUserLicenseType where UserID = @UserID 
--Delete this user
DELETE pUsers WHERE UserID = @UserID
GO
GRANT EXECUTE ON  [dbo].[vspDeleteConnectsUserById] TO [public]
GO
