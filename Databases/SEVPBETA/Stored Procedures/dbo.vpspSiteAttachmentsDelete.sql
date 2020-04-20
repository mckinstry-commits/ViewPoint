SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE   PROCEDURE [dbo].[vpspSiteAttachmentsDelete]
/************************************************************
* CREATED:     SDE 7/5/2005
* MODIFIED:    
*
* USAGE:
*   	Deletes the Binary data for an attachment, then the Attachment
*	details.
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
* 	@Original_SiteAttachmentID, @Original_AttachmentTypeID, @Original_Date,
*	@Original_Description, @Original_FileName, @Original_Name, 
*	@Original_SiteID, @Original_Size int 
*
* OUTPUT PARAMETERS
*   
* RETURN VALUE
*   
************************************************************/
(
	@Original_SiteAttachmentID int,
	@Original_AttachmentTypeID int,
	@Original_Date datetime,
	@Original_Description varchar(255),
	@Original_FileName varchar(50),
	@Original_Name varchar(50),
	@Original_SiteID int,
	@Original_Size int
)
AS
	SET NOCOUNT OFF;

-- Make sure this attachment is not in use in pSites
IF EXISTS(SELECT * FROM pSites WHERE SiteAttachmentID = @Original_SiteAttachmentID)
	goto InUseMessage

-- Make sure this attachment is not in use in pDisplayControl
IF EXISTS(SELECT * FROM pDisplayControl WHERE AttachmentID = @Original_SiteAttachmentID)
	goto InUseMessage
	
--Delete Binary Data
DELETE FROM pSiteAttachmentBinaries WHERE SiteAttachmentID = @Original_SiteAttachmentID

--Delete Details
DELETE FROM pSiteAttachments WHERE (SiteAttachmentID = @Original_SiteAttachmentID) AND (AttachmentTypeID = @Original_AttachmentTypeID) AND (Date = @Original_Date OR @Original_Date IS NULL AND Date IS NULL) AND (Description = @Original_Description OR @Original_Description IS NULL AND Description IS NULL) AND (FileName = @Original_FileName) AND (Name = @Original_Name) AND (SiteID = @Original_SiteID) AND (Size = @Original_Size)

RETURN

InUseMessage:
	RAISERROR('This attachment is currently in use and cannot be deleted.', 11, -1)
GO
GRANT EXECUTE ON  [dbo].[vpspSiteAttachmentsDelete] TO [VCSPortal]
GO
