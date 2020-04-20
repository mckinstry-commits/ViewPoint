SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE   PROCEDURE dbo.vpspForumInsert
(
	@PageSiteControlID int,
	@UserID int,
	@ParentID int,
	@ThreadOrder int,
	@UserWebPage varchar(255),
	@UserLocation varchar(255),
	@Subject varchar(255),
	@Body varchar(4095),
	@PostedDate datetime,
	@SiteID int
)
AS
	
SET NOCOUNT OFF;

IF @ParentID = -1 SET @ParentID = NULL

INSERT INTO pForum(PageSiteControlID, UserID, ParentID, ThreadOrder, UserWebPage, UserLocation, 
Subject, Body, PostedDate, SiteID) 
VALUES (@PageSiteControlID, @UserID, @ParentID, @ThreadOrder, @UserWebPage, @UserLocation, 
@Subject, @Body, @PostedDate, @SiteID);

SELECT ForumID, PageSiteControlID, UserID, ISNULL(ParentID, -1), ThreadOrder, UserWebPage, UserLocation, 
Subject, Body, PostedDate, SiteID 
FROM pForum with (nolock) 
WHERE (ForumID = SCOPE_IDENTITY()) 
AND (PageSiteControlID = @PageSiteControlID) 
AND (UserID = @UserID)



GO
GRANT EXECUTE ON  [dbo].[vpspForumInsert] TO [VCSPortal]
GO
