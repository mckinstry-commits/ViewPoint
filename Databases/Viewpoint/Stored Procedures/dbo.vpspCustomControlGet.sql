SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


AS
	SET NOCOUNT ON;
SELECT PageSiteControlID, SiteID, FileName 

FROM pCustomControl with (nolock)


GO
GRANT EXECUTE ON  [dbo].[vpspCustomControlGet] TO [VCSPortal]
GO