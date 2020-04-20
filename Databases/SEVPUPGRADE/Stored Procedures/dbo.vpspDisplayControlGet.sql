SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE      PROCEDURE dbo.vpspDisplayControlGet
/************************************************************
* CREATED:     2/20/06  SDE
* MODIFIED:    
*
* USAGE:
*	Gets the Display Controls
*	
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*	PageSiteControlID
*
* OUTPUT PARAMETERS
*   
* RETURN VALUE
*   
************************************************************/
(@PageSiteControlID int = Null)
AS
	SET NOCOUNT ON;


SELECT pDisplayControl.PageSiteControlID, 
	IsNull(pDisplayControl.AttachmentID, -1) as 'AttachmentID', 
	pDisplayControl.DisplayText, 
	IsNull(pDisplayControl.SiteID, -1) as 'SiteID', 
	IsNull(pSiteAttachments.Name, 'Not Set') as 'AttachmentName'
	FROM pDisplayControl pDisplayControl with (nolock)
	left join pSiteAttachments pSiteAttachments on pDisplayControl.AttachmentID = pSiteAttachments.SiteAttachmentID
	WHERE PageSiteControlID = IsNull(@PageSiteControlID, PageSiteControlID)










GO
GRANT EXECUTE ON  [dbo].[vpspDisplayControlGet] TO [VCSPortal]
GO
