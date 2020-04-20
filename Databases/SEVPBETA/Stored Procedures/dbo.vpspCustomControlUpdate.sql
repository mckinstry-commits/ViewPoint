SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspCustomControlUpdate
(
	@PageSiteControlID int,
	@SiteID int,
	@FileName varchar(255),
	@Original_PageSiteControlID int,
	@Original_FileName varchar(255),
	@Original_SiteID int
)
AS
	SET NOCOUNT OFF;
UPDATE pCustomControl SET PageSiteControlID = @PageSiteControlID, SiteID = @SiteID, FileName = @FileName 
WHERE (PageSiteControlID = @Original_PageSiteControlID) 
AND (FileName = @Original_FileName OR @Original_FileName IS NULL AND FileName IS NULL) 
AND (SiteID = @Original_SiteID);

	SELECT PageSiteControlID, SiteID, FileName 
	FROM pCustomControl with (nolock)
	
	WHERE (PageSiteControlID = @PageSiteControlID)


GO
GRANT EXECUTE ON  [dbo].[vpspCustomControlUpdate] TO [VCSPortal]
GO
