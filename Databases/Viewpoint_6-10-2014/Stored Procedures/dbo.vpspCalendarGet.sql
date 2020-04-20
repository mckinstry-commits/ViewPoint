SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspCalendarGet]
AS
	SET NOCOUNT ON;

SELECT DateID, SiteID, PageSiteControlID, DisplayOrder, CalendarDate, DateSubject, DateComment, DateColor 
FROM pCalendar with (nolock)


GO
GRANT EXECUTE ON  [dbo].[vpspCalendarGet] TO [VCSPortal]
GO
