SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  PROCEDURE dbo.vpspForumDelete
(
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
	@Original_UserWebPage varchar(255)
)
AS

IF @Original_ParentID = -1
	BEGIN
	SET @Original_ParentID = NULL
	END

SET NOCOUNT OFF;

DELETE FROM pForumViews WHERE ForumID = @Original_ForumID

DELETE FROM pForum 
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
AND (UserWebPage = @Original_UserWebPage OR @Original_UserWebPage IS NULL AND UserWebPage IS NULL)



GO
GRANT EXECUTE ON  [dbo].[vpspForumDelete] TO [VCSPortal]
GO
