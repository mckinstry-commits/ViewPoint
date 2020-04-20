SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE   PROCEDURE dbo.vpspContactTypesGet
/************************************************************
* CREATED:     2/13/06  SDE
* MODIFIED:    
*
* USAGE:
*	Gets all Contact Types
*	
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*	ContactTypeID
*
* OUTPUT PARAMETERS
*   
* RETURN VALUE
*   
************************************************************/
(@ContactTypeID int = Null)
AS
	SET NOCOUNT ON;

SELECT ContactTypeID, Name, Description, Static FROM pContactTypes with (nolock)
	where ContactTypeID = IsNull(@ContactTypeID, ContactTypeID)




GO
GRANT EXECUTE ON  [dbo].[vpspContactTypesGet] TO [VCSPortal]
GO
