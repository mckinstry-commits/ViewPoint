SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE   PROCEDURE dbo.vpspDirectoryBrowserInsert
(
	@PageSiteControlID int,
	@Directory varchar(255)
)
AS
	SET NOCOUNT OFF;

INSERT INTO pDirectoryBrowser(PageSiteControlID, Directory)
VALUES (@PageSiteControlID, @Directory);

execute vpspDirectoryBrowserGet @PageSiteControlID = @PageSiteControlID




GO
GRANT EXECUTE ON  [dbo].[vpspDirectoryBrowserInsert] TO [VCSPortal]
GO
