SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspCustomControlInsert
(
	@PageSiteControlID int,
	@SiteID int,
	@FileName varchar(255)
)
AS
	SET NOCOUNT OFF;
INSERT INTO pCustomControl(PageSiteControlID, SiteID, FileName) VALUES (@PageSiteControlID, @SiteID, @FileName);
	SELECT PageSiteControlID, SiteID, FileName 
	
	FROM pCustomControl with (nolock) 
	
	WHERE (PageSiteControlID = @PageSiteControlID)


GO
GRANT EXECUTE ON  [dbo].[vpspCustomControlInsert] TO [VCSPortal]
GO
