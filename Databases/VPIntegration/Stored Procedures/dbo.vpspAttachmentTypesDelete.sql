SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE    PROCEDURE dbo.vpspAttachmentTypesDelete
/************************************************************
* CREATED:     2/13/06  SDE
* MODIFIED:    
*
* USAGE:
*	Deletes an Attachment Type
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
	@Original_AttachmentTypeID int,
	@Original_Description varchar(255),
	@Original_Name varchar(50),
	@Original_Static bit
)
AS
	SET NOCOUNT OFF;
DELETE FROM pAttachmentTypes WHERE (AttachmentTypeID = @Original_AttachmentTypeID) AND (Description = @Original_Description) AND (Name = @Original_Name) AND (Static = @Original_Static)





GO
GRANT EXECUTE ON  [dbo].[vpspAttachmentTypesDelete] TO [VCSPortal]
GO
