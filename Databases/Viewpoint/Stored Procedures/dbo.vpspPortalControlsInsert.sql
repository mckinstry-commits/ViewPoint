SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE      PROCEDURE [dbo].[vpspPortalControlsInsert]
/************************************************************
* CREATED:     6/4/07  SDE
* MODIFIED:    
*
* USAGE:
*	Inserts a new PortalControl
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
	@Help varchar(50),
	@PrimaryTable varchar(50)
)
AS

SET NOCOUNT OFF;

INSERT INTO pPortalControls(Name, Description, ChildControl, Path, Notes, 
	Help, PrimaryTable) VALUES (@Name, @Description, 
	@ChildControl, @Path, @Notes, @Help, @PrimaryTable);
	
SELECT SCOPE_IDENTITY() AS PortalControlID
GO
GRANT EXECUTE ON  [dbo].[vpspPortalControlsInsert] TO [VCSPortal]
GO
