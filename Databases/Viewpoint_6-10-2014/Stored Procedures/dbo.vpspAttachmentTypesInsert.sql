SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE    PROCEDURE [dbo].[vpspAttachmentTypesInsert]
/************************************************************
* CREATED:     2/13/06  SDE
* MODIFIED:    
*
* USAGE:
*	Inserts a new Attachment Type
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
INSERT INTO pAttachmentTypes(Name, Description, Static) VALUES (@Name, @Description, @Static);

DECLARE @AttachmentTypeID int 
SET @AttachmentTypeID = SCOPE_IDENTITY() 
execute vpspAttachmentTypesGet @AttachmentTypeID 





GO
GRANT EXECUTE ON  [dbo].[vpspAttachmentTypesInsert] TO [VCSPortal]
GO
