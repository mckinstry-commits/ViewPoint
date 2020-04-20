SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE   PROCEDURE dbo.vpspContactTypesDelete
/************************************************************
* CREATED:     2/13/06  SDE
* MODIFIED:    
*
* USAGE:
*	Deletes a Contact Type
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
	@Original_ContactTypeID int,
	@Original_Name varchar(50),
	@Original_Description varchar(255),
	@Original_Static bit
)
AS
	SET NOCOUNT OFF;
DELETE FROM pContactTypes WHERE (ContactTypeID = @Original_ContactTypeID) AND (Name = @Original_Name) AND (Description = @Original_Description) AND (Static = @Original_Static)




GO
GRANT EXECUTE ON  [dbo].[vpspContactTypesDelete] TO [VCSPortal]
GO
