SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE    PROCEDURE dbo.vpspDirectoryBrowserUpdate
(
	@PageSiteControlID int,
	@Directory varchar(255),
	@Original_PageSiteControlID int,
	@Original_Directory varchar(255)
)
AS

SET NOCOUNT OFF;

UPDATE pDirectoryBrowser 
SET PageSiteControlID = @PageSiteControlID, 
Directory = @Directory
WHERE (PageSiteControlID = @Original_PageSiteControlID) 
AND (Directory = @Original_Directory OR @Original_Directory IS NULL AND Directory IS NULL);

execute vpspDirectoryBrowserGet @PageSiteControlID = @PageSiteControlID





GO
GRANT EXECUTE ON  [dbo].[vpspDirectoryBrowserUpdate] TO [VCSPortal]
GO
