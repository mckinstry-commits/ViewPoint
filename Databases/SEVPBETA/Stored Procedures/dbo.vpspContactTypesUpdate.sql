SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE   PROCEDURE dbo.vpspContactTypesUpdate
/************************************************************
* CREATED:     2/13/06  SDE
* MODIFIED:    
*
* USAGE:
*	Updates a Contact Type
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
	@Static bit,
	@Original_ContactTypeID int,
	@Original_Name varchar(50),
	@Original_Description varchar(255),
	@Original_Static bit,
	@ContactTypeID int
)
AS
	SET NOCOUNT OFF;
UPDATE pContactTypes SET Name = @Name, Description = @Description, Static = @Static WHERE (ContactTypeID = @Original_ContactTypeID) AND (Name = @Original_Name) AND (Description = @Original_Description) AND (Static = @Original_Static);
	
execute vpspContactTypesGet @ContactTypeID




GO
GRANT EXECUTE ON  [dbo].[vpspContactTypesUpdate] TO [VCSPortal]
GO
