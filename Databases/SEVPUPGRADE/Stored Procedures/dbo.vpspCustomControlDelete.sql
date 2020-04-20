SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspCustomControlDelete
(
	@Original_PageSiteControlID int,
	@Original_FileName varchar(255),
	@Original_SiteID int
)
AS
	SET NOCOUNT OFF;
DELETE FROM pCustomControl 

WHERE (PageSiteControlID = @Original_PageSiteControlID) 
AND (FileName = @Original_FileName OR @Original_FileName IS NULL AND FileName IS NULL) 
AND (SiteID = @Original_SiteID)


GO
GRANT EXECUTE ON  [dbo].[vpspCustomControlDelete] TO [VCSPortal]
GO
