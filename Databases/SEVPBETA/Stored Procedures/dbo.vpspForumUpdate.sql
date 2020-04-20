SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  PROCEDURE dbo.vpspForumUpdate
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
	@SiteID int,
	@Original_ForumID int,
	@Original_PageSiteControlID int,
	@Original_UserID int,
	@Original_Body varchar(4095),
	@Original_ParentID int,
	@Original_PostedDate datetime,
	@Original_SiteID int,
	@Original_Subject varchar(255),
	@Original_ThreadOrder int,
	@Original_UserLocation varchar(255),
	@Original_UserWebPage varchar(255),
	@ForumID int
)
AS
	SET NOCOUNT OFF;

IF @ParentID = -1
	BEGIN
	SET @ParentID = NULL
	END

IF @Original_ParentID = -1
	BEGIN
	SET @Original_ParentID = NULL
	END

UPDATE pForum 
SET PageSiteControlID = @PageSiteControlID, UserID = @UserID, ParentID = @ParentID, ThreadOrder = @ThreadOrder, UserWebPage = @UserWebPage, UserLocation = @UserLocation, Subject = @Subject, Body = @Body, PostedDate = @PostedDate, SiteID = @SiteID 
WHERE (ForumID = @Original_ForumID) 
AND (PageSiteControlID = @Original_PageSiteControlID) 
AND (UserID = @Original_UserID) 
AND (Body = @Original_Body OR @Original_Body IS NULL AND Body IS NULL) 
AND (ParentID = @Original_ParentID OR (@Original_ParentID IS NULL AND ParentID IS NULL)) 
AND (PostedDate = @Original_PostedDate OR @Original_PostedDate IS NULL AND PostedDate IS NULL) 
AND (SiteID = @Original_SiteID OR @Original_SiteID IS NULL AND SiteID IS NULL) 
AND (Subject = @Original_Subject OR @Original_Subject IS NULL AND Subject IS NULL) 
AND (ThreadOrder = @Original_ThreadOrder) 
AND (UserLocation = @Original_UserLocation OR @Original_UserLocation IS NULL AND UserLocation IS NULL) 
AND (UserWebPage = @Original_UserWebPage OR @Original_UserWebPage IS NULL AND UserWebPage IS NULL);

	SELECT ForumID, PageSiteControlID, UserID, ParentID, ThreadOrder, UserWebPage, UserLocation, Subject, Body, PostedDate, SiteID 
	FROM pForum with (nolock)
	WHERE (ForumID = @ForumID) 
	AND (PageSiteControlID = @PageSiteControlID) 
	AND (UserID = @UserID)



GO
GRANT EXECUTE ON  [dbo].[vpspForumUpdate] TO [VCSPortal]
GO
