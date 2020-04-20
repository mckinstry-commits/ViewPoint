SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE            PROCEDURE dbo.vpspCopySiteAttachment
/************************************************************
* CREATED:     SDE 6/24/2005
* MODIFIED:    
*
* USAGE:
*   Copies an attachment from one site to another
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
* 	@AttachmentID, @SiteID 
*
* OUTPUT PARAMETERS
*   
* RETURN VALUE
*   
************************************************************/
(@SiteAttachmentID int, @DestinationSiteID int)
AS
	SET NOCOUNT ON;
--Insert Attachment Details
insert into pSiteAttachments(SiteID, Name, FileName, AttachmentTypeID, Date, Size, Description) 
	select @DestinationSiteID, Name, FileName, AttachmentTypeID, Date, Size, Description from pSiteAttachments where SiteAttachmentID = @SiteAttachmentID
--Insert the Binary
insert into pSiteAttachmentBinaries(SiteAttachmentID, Type, Data)
	select SCOPE_IDENTITY(), Type, Data from pSiteAttachmentBinaries where SiteAttachmentID = @SiteAttachmentID




GO
GRANT EXECUTE ON  [dbo].[vpspCopySiteAttachment] TO [VCSPortal]
GO
