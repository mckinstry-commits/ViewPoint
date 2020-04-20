SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspForumViewsDelete
(
	@Original_ForumID int,
	@Original_TotalViews int
)
AS
	SET NOCOUNT OFF;
DELETE FROM pForumViews 
WHERE (ForumID = @Original_ForumID) 
AND (TotalViews = @Original_TotalViews OR @Original_TotalViews IS NULL AND TotalViews IS NULL)


GO
GRANT EXECUTE ON  [dbo].[vpspForumViewsDelete] TO [VCSPortal]
GO
