SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspCalendarEventsTodayDelete
(
	@Original_PageSiteControlID int,
	@Original_CalendarID int
)
AS
	SET NOCOUNT OFF;
DELETE FROM pCalendarEventsToday
WHERE (PageSiteControlID = @Original_PageSiteControlID) 
AND (CalendarID = @Original_CalendarID)


GO
GRANT EXECUTE ON  [dbo].[vpspCalendarEventsTodayDelete] TO [VCSPortal]
GO
