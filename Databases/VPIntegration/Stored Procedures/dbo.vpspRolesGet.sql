SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE     PROCEDURE dbo.vpspRolesGet
/************************************************************
* CREATED:     2/9/06  SDE
* MODIFIED:    
*
* USAGE:
*	Gets all Roles
*	
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    RoleID
*
* OUTPUT PARAMETERS
*   
* RETURN VALUE
*   
************************************************************/
(@RoleID int = Null)
AS
	SET NOCOUNT ON;

SELECT RoleID, Name, Description, Active, Static FROM pRoles with (nolock) 
	where RoleID = IsNull(@RoleID, RoleID)






GO
GRANT EXECUTE ON  [dbo].[vpspRolesGet] TO [VCSPortal]
GO
