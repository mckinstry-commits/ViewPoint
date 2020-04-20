SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- Create Procedure
CREATE        PROCEDURE [dbo].[vpspDeleteUser]
/************************************************************
* CREATED:     SDE 8/31/2005
* MODIFIED:    TEJ 01/29/2010 - Added License Type Deletion
*				KSE 06/29/2012 - Moved the code to a vsp function
*				vspDeleteConnectsUserById so that it can be used
*				from V6 as well
* USAGE:
*   Deletes a User and associated Records by the UserID
*
* CALLED FROM:
*	ViewpointCS Portal  
*	ViewpointCS V6
*
* INPUT PARAMETERS
*     UserID       
*
* RETURN VALUE
*   
************************************************************/
(@UserID int)
AS
exec [dbo].[vspDeleteConnectsUserById] @UserID


GO
GRANT EXECUTE ON  [dbo].[vpspDeleteUser] TO [VCSPortal]
GO
