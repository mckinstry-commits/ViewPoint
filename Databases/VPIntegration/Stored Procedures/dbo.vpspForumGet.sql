SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  PROCEDURE dbo.vpspForumGet
AS
	SET NOCOUNT ON;
SELECT ForumID, PageSiteControlID, UserID, ISNULL(ParentID, -1) AS ParentID, ThreadOrder, UserWebPage, UserLocation, Subject, Body, PostedDate, SiteID 
FROM pForum with (nolock)



GO
GRANT EXECUTE ON  [dbo].[vpspForumGet] TO [VCSPortal]
GO
