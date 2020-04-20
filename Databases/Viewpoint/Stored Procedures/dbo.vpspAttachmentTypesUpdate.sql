SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE   PROCEDURE dbo.vpspAttachmentTypesUpdate
/************************************************************
* CREATED:     2/13/06  SDE
* MODIFIED:    
*
* USAGE:
*	Updates an Attachment Type
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
	@Original_AttachmentTypeID int,
	@Original_Static bit,
	@Original_Description varchar(255),
	@Original_Name varchar(50),
	@AttachmentTypeID int
)
AS
	SET NOCOUNT OFF;
UPDATE pAttachmentTypes SET Name = @Name, Description = @Description, Static = @Static WHERE (AttachmentTypeID = @Original_AttachmentTypeID) AND (Description = @Original_Description) AND (Name = @Original_Name) AND (Static = @Original_Static);
	
execute vpspAttachmentTypesGet @AttachmentTypeID




GO
GRANT EXECUTE ON  [dbo].[vpspAttachmentTypesUpdate] TO [VCSPortal]
GO
