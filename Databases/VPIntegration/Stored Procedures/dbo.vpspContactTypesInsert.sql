SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE    PROCEDURE [dbo].[vpspContactTypesInsert]
/************************************************************
* CREATED:     2/13/06  SDE
* MODIFIED:    
*
* USAGE:
*	Inserts a new Contact Type
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
	@Static bit
)
AS
	SET NOCOUNT OFF;
INSERT INTO pContactTypes(Name, Description, Static) VALUES (@Name, @Description, @Static);

DECLARE @ContactTypeID int 
SET @ContactTypeID = SCOPE_IDENTITY() 
execute vpspContactTypesGet @ContactTypeID 






GO
GRANT EXECUTE ON  [dbo].[vpspContactTypesInsert] TO [VCSPortal]
GO
