SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[vpspPromoteUserToPortalAdmin]
/************************************************************
* CREATED:		2011/12/26 Joe A
*
* USAGE:
*	Performs all actions necessary when a User becomes a PortalAdmin
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
(
	@UserID int
)

AS
BEGIN
                SET NOCOUNT OFF;

DELETE FROM pUserSites where UserID = @UserID
END
GO
GRANT EXECUTE ON  [dbo].[vpspPromoteUserToPortalAdmin] TO [VCSPortal]
GO
