SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspCalendarEventsTodayInsert
(
	@PageSiteControlID int,
	@CalendarID int
)
AS
	SET NOCOUNT OFF;
INSERT INTO pCalendarEventsToday(PageSiteControlID, CalendarID) VALUES (@PageSiteControlID, @CalendarID);
	SELECT PageSiteControlID, CalendarID FROM pCalendarEventsToday with (nolock) 
	WHERE (PageSiteControlID = @PageSiteControlID)


GO
GRANT EXECUTE ON  [dbo].[vpspCalendarEventsTodayInsert] TO [VCSPortal]
GO
