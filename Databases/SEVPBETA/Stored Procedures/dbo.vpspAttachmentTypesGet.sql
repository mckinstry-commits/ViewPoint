SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  PROCEDURE dbo.vpspAttachmentTypesGet
/************************************************************
* CREATED:     2/13/06  SDE
* MODIFIED:    
*
* USAGE:
*	Gets all Attachment Types
*	
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    AttachmentTypeID
*
* OUTPUT PARAMETERS
*   
* RETURN VALUE
*   
************************************************************/
(@AttachmentTypeID int = Null)
AS
	SET NOCOUNT ON;
SELECT AttachmentTypeID, Name, Description, Static FROM pAttachmentTypes with (nolock)
	where AttachmentTypeID = IsNull(@AttachmentTypeID, AttachmentTypeID)




GO
GRANT EXECUTE ON  [dbo].[vpspAttachmentTypesGet] TO [VCSPortal]
GO
