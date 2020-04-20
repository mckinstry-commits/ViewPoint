SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspCalendarDatesGet]
(
	@PageSiteControlID int
)
AS
	
SET NOCOUNT ON;

SELECT CalendarDateID, PageSiteControlID, c.DateID, d.Name, DateOrder, DateColor 
	FROM pCalendarDates c with (nolock)
	INNER JOIN pDates d ON c.DateID = d.DateID
	WHERE PageSiteControlID = @PageSiteControlID
	ORDER BY DateOrder ASC 



GO
GRANT EXECUTE ON  [dbo].[vpspCalendarDatesGet] TO [VCSPortal]
GO
