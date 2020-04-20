SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspForumViewsUpdate
(
	@ForumID int,
	@TotalViews int,
	@Original_ForumID int,
	@Original_TotalViews int
)
AS
	SET NOCOUNT OFF;
UPDATE pForumViews SET ForumID = @ForumID, TotalViews = @TotalViews 

WHERE (ForumID = @Original_ForumID) 
AND (TotalViews = @Original_TotalViews OR @Original_TotalViews IS NULL AND TotalViews IS NULL);

	SELECT ForumID, TotalViews 
	FROM pForumViews with (nolock)
	WHERE (ForumID = @ForumID)


GO
GRANT EXECUTE ON  [dbo].[vpspForumViewsUpdate] TO [VCSPortal]
GO
