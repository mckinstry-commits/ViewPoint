SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE    PROCEDURE [dbo].[vpspLinkControlGet]
/************************************************************
* CREATED:     4/24/06  SDE
* MODIFIED:    
*
* USAGE:
*	Gets all Links for a page site control
*	
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    LinkID, PageSiteControlID
*
* OUTPUT PARAMETERS
*   
* RETURN VALUE
*   
************************************************************/
(
@LinkControlID int = Null,
@PageSiteControlID int
)
AS
	SET NOCOUNT ON;

SELECT LinkControlID, 
	PageSiteControlID, 
	LinkOrder, 
	LinkText, 
	URL,
	IsNull(PopUpHeight, -1) as 'PopUpHeight', 
	IsNull(PopUpWidth, -1) as 'PopUpWidth',  
	IsNull(SiteID, -1) as 'SiteID', 
	IsNull(LinkTypeID, -1) as 'LinkTypeID' 
	FROM pLinkControl with (nolock)
	WHERE LinkControlID = IsNull(@LinkControlID, LinkControlID) and PageSiteControlID = @PageSiteControlID
	ORDER BY LinkOrder






GO
GRANT EXECUTE ON  [dbo].[vpspLinkControlGet] TO [VCSPortal]
GO
