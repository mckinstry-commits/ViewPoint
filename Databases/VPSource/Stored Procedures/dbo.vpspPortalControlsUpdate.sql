SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspPortalControlsUpdate]
/************************************************************
* CREATED:     6/4/07  SDE
* MODIFIED:    
*
* USAGE:
*	Updates a PortalControl
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
	@Name varchar(50),
	@Description varchar(255),
	@ChildControl bit,
	@Path varchar(255),
	@Notes varchar(3000),
	@PortalControlID int,
	@Help varchar(50),
	@PrimaryTable varchar(50)    
)
AS

SET NOCOUNT OFF;

UPDATE pPortalControls SET Name = @Name, Description = @Description, 
ChildControl = @ChildControl, Path = @Path, Notes = @Notes, 
Help = @Help, PrimaryTable = @PrimaryTable WHERE (PortalControlID = @PortalControlID); 
	
SELECT PortalControlID, Name, Description, ChildControl, Path, 
	Notes, Help, PrimaryTable 
	FROM pPortalControls WHERE (PortalControlID = @PortalControlID)

GO
GRANT EXECUTE ON  [dbo].[vpspPortalControlsUpdate] TO [VCSPortal]
GO
