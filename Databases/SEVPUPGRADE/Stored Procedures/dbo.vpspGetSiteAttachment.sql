SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE            PROCEDURE dbo.vpspGetSiteAttachment
/************************************************************
* CREATED:     SDE 6/24/2005
* MODIFIED:    
*
* USAGE:
*   Gets an attachment
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
* 	@SiteAttachmentID
*
* OUTPUT PARAMETERS
*   
* RETURN VALUE
*   
************************************************************/
(@SiteAttachmentID int)
AS
	SET NOCOUNT ON;
SELECT b.SiteAttachmentID, s.FileName, b.Type, b.Data FROM pSiteAttachmentBinaries b inner join 
	pSiteAttachments s on b.SiteAttachmentID = s.SiteAttachmentID
	where b.SiteAttachmentID = @SiteAttachmentID


GO
GRANT EXECUTE ON  [dbo].[vpspGetSiteAttachment] TO [VCSPortal]
GO
