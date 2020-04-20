SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  PROCEDURE dbo.vpspForumReader
/******************************
* created by CHS, 11/7/05
*
*******************************/
(
@pagesitecontrolid int
)
AS
	SET NOCOUNT ON;
	
SELECT 
pForum.ForumID, 
pForum.PageSiteControlID, 
pForum.UserID,
ISNULL(pForum.ParentID, -1) AS ParentID, 
pForum.ThreadOrder,
pForum.UserWebPage, 
pForum.UserLocation, 
pForum.Subject, 
pForum.Body, 
pForum.PostedDate,
pForum.SiteID

FROM pForum  with (nolock)

WHERE (PageSiteControlID = @pagesitecontrolid)



GO
GRANT EXECUTE ON  [dbo].[vpspForumReader] TO [VCSPortal]
GO
