SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE    PROCEDURE dbo.vpspDirectoryBrowserDelete
(
	@Original_PageSiteControlID int
)
AS
	SET NOCOUNT OFF;


DELETE 
FROM pDirectoryBrowser WHERE (PageSiteControlID = @Original_PageSiteControlID)






GO
GRANT EXECUTE ON  [dbo].[vpspDirectoryBrowserDelete] TO [VCSPortal]
GO
