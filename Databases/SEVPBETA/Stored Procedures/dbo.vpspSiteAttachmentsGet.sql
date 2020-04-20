SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE   PROCEDURE dbo.vpspSiteAttachmentsGet
/************************************************************
* CREATED:     3/9/06  SDE
* MODIFIED:    
*
* USAGE:
*	Gets Site Attachments
*	
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    SiteAttachmentID
*
* OUTPUT PARAMETERS
*   
* RETURN VALUE
*   
************************************************************/
(@SiteAttachmentID int = Null)
AS
	SET NOCOUNT ON;

select pSiteAttachments.SiteAttachmentID, 
	pSiteAttachments.SiteID, 
	pSiteAttachments.Name, 
	pSiteAttachments.FileName, 
	pSiteAttachments.AttachmentTypeID, 
	pAttachmentTypes.Name as 'AttachmentTypeName',
	pSiteAttachments.Date, 
	pSiteAttachments.Size, 
	pSiteAttachments.Description 
	FROM pSiteAttachments with (nolock) 
	left join pAttachmentTypes on pSiteAttachments.AttachmentTypeID = pAttachmentTypes.AttachmentTypeID
	where pSiteAttachments.SiteAttachmentID = IsNull(@SiteAttachmentID, pSiteAttachments.SiteAttachmentID)



GO
GRANT EXECUTE ON  [dbo].[vpspSiteAttachmentsGet] TO [VCSPortal]
GO
