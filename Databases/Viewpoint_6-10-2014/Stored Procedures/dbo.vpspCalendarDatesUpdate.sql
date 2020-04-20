SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspCalendarDatesUpdate]
(
	@CalendarDateID int,
	@PageSiteControlID int,
	@DateID int,
	@DateOrder int,
	@DateColor varchar(50) 
)
AS
	
SET NOCOUNT OFF;

UPDATE pCalendarDates SET DateOrder = @DateOrder, DateColor = @DateColor
	WHERE CalendarDateID = @CalendarDateID;


SELECT CalendarDateID, PageSiteControlID, c.DateID, d.Name, DateOrder, DateColor 
	FROM pCalendarDates c with (nolock)
	INNER JOIN pDates d ON c.DateID = d.DateID 
	WHERE CalendarDateID = @CalendarDateID;



GO
GRANT EXECUTE ON  [dbo].[vpspCalendarDatesUpdate] TO [VCSPortal]
GO
