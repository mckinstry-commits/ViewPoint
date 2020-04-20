SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspCalendarEventsTodayGet
AS
	SET NOCOUNT ON;
SELECT PageSiteControlID, CalendarID FROM pCalendarEventsToday with (nolock)


GO
GRANT EXECUTE ON  [dbo].[vpspCalendarEventsTodayGet] TO [VCSPortal]
GO
