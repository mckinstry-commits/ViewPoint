SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[vpspPortalControlsGet]
/************************************************************
* CREATED:     6/4/07  SDE
* MODIFIED:    
*
* USAGE:
*	Gets all PortalControls
*	
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*   
*
* OUTPUT PARAMETERS
*   
* RETURN VALUE
*   
************************************************************/
AS
	
SET NOCOUNT ON;

SELECT PortalControlID, Name, Description, pPortalControls.ChildControl AS 'pPortalControls.ChildControl',
	ChildControl, Path, Notes, Help, PrimaryTable
	FROM pPortalControls
GO
GRANT EXECUTE ON  [dbo].[vpspPortalControlsGet] TO [VCSPortal]
GO
