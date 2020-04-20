SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspCalendarDatesDelete]
(
	@CalendarDateID int
)
AS
	
SET NOCOUNT OFF;

DELETE FROM pCalendarDates
	WHERE CalendarDateID = @CalendarDateID


GO
GRANT EXECUTE ON  [dbo].[vpspCalendarDatesDelete] TO [VCSPortal]
GO
