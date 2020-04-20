SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspCalendarEventsTodayUpdate
(
	@PageSiteControlID int,
	@CalendarID int,
	@Original_PageSiteControlID int,
	@Original_CalendarID int
)
AS
	SET NOCOUNT OFF;
UPDATE pCalendarEventsToday SET PageSiteControlID = @PageSiteControlID, CalendarID = @CalendarID 
WHERE (PageSiteControlID = @Original_PageSiteControlID) AND (CalendarID = @Original_CalendarID);

	SELECT PageSiteControlID, CalendarID 
	FROM pCalendarEventsToday with (nolock) 
	WHERE (PageSiteControlID = @PageSiteControlID)


GO
GRANT EXECUTE ON  [dbo].[vpspCalendarEventsTodayUpdate] TO [VCSPortal]
GO
