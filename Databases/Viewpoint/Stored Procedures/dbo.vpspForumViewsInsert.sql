SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


(
	@ForumID int,
	@TotalViews int
)
AS
	SET NOCOUNT OFF;
INSERT INTO pForumViews(ForumID, TotalViews) 
VALUES (@ForumID, @TotalViews);

	SELECT ForumID, TotalViews 
	
	FROM pForumViews with (nolock)
	
	WHERE (ForumID = @ForumID)


GO
GRANT EXECUTE ON  [dbo].[vpspForumViewsInsert] TO [VCSPortal]
GO