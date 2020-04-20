SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE     PROCEDURE [dbo].[vpspPortalControlsDelete]
/************************************************************
* CREATED:     6/4/07  SDE
* MODIFIED:    
*
* USAGE:
*	Deletes a PortalControl
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
(
	@Original_PortalControlID int,
	@Original_ChildControl bit,
	@Original_Description varchar(255),
	@Original_Name varchar(50),
	@Original_Notes varchar(3000),
	@Original_Path varchar(255),
	@Original_PrimaryTable varchar(50)
)
AS
	SET NOCOUNT OFF;

DELETE FROM pPortalControls WHERE 
	(PortalControlID = @Original_PortalControlID) AND 
	(ChildControl = @Original_ChildControl) AND 
	(Description = @Original_Description) AND 
	(Name = @Original_Name) AND 
	(Notes = @Original_Notes OR @Original_Notes IS NULL AND Notes IS NULL) AND 
	(Path = @Original_Path) AND 
	PrimaryTable = @Original_PrimaryTable

GO
GRANT EXECUTE ON  [dbo].[vpspPortalControlsDelete] TO [VCSPortal]
GO
