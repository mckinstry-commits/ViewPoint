SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  PROCEDURE dbo.vpspCalendarInsert
(
	@SiteID int,
	@PageSiteControlID int,
	@DisplayOrder int,
	@CalendarDate datetime,
	@DateSubject varchar(50),
	@DateComment varchar(255),
	@DateColor varchar(50)
)
AS
	SET NOCOUNT OFF;
INSERT INTO pCalendar(SiteID, PageSiteControlID, DisplayOrder, CalendarDate, DateSubject, DateComment, DateColor) VALUES (@SiteID, @PageSiteControlID, @DisplayOrder, @CalendarDate, @DateSubject, @DateComment, @DateColor);
	SELECT DateID, SiteID, PageSiteControlID, DisplayOrder, CalendarDate, DateSubject, DateComment, DateColor 
	FROM pCalendar  with (nolock)
	WHERE (DateID = SCOPE_IDENTITY())



GO
GRANT EXECUTE ON  [dbo].[vpspCalendarInsert] TO [VCSPortal]
GO
