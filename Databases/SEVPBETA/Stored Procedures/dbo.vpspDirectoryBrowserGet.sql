SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE     PROCEDURE dbo.vpspDirectoryBrowserGet
/************************************************************
* CREATED:     
* MODIFIED:    
*
* USAGE:
*	
*	
*
* CALLED FROM:
*	
*
* INPUT PARAMETERS
*
*
* OUTPUT PARAMETERS
*   
* RETURN VALUE
*   
************************************************************/
(@PageSiteControlID int = Null)
AS

SET NOCOUNT ON;
 

SELECT PageSiteControlID, 
	IsNull(Directory, '') as 'Directory'
	FROM pDirectoryBrowser pDisplayControl with (nolock)
		WHERE PageSiteControlID = IsNull(@PageSiteControlID, PageSiteControlID)





GO
GRANT EXECUTE ON  [dbo].[vpspDirectoryBrowserGet] TO [VCSPortal]
GO
