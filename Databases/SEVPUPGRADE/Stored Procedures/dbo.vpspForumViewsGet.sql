SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


AS
	SET NOCOUNT ON;
SELECT ForumID, TotalViews FROM pForumViews with (nolock)


GO
GRANT EXECUTE ON  [dbo].[vpspForumViewsGet] TO [VCSPortal]
GO