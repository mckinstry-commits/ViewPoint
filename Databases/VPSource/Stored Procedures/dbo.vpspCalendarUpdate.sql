SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspCalendarUpdate
(
	@SiteID int,
	@PageSiteControlID int,
	@DisplayOrder int,
	@CalendarDate datetime,
	@DateSubject varchar(50),
	@DateComment varchar(255),
	@DateColor varchar(50),
	@Original_DateID int,
	@Original_CalendarDate datetime,
	@Original_DateColor varchar(50),
	@Original_DateComment varchar(255),
	@Original_DateSubject varchar(50),
	@Original_DisplayOrder int,
	@Original_PageSiteControlID int,
	@Original_SiteID int,
	@DateID int
)
AS
	SET NOCOUNT OFF;
UPDATE pCalendar SET SiteID = @SiteID, PageSiteControlID = @PageSiteControlID, DisplayOrder = @DisplayOrder, CalendarDate = @CalendarDate, DateSubject = @DateSubject, DateComment = @DateComment, DateColor = @DateColor WHERE (DateID = @Original_DateID) AND (CalendarDate = @Original_CalendarDate) AND (DateColor = @Original_DateColor) AND (DateComment = @Original_DateComment OR @Original_DateComment IS NULL AND DateComment IS NULL) AND (DateSubject = @Original_DateSubject) AND (DisplayOrder = @Original_DisplayOrder) AND (PageSiteControlID = @Original_PageSiteControlID) AND (SiteID = @Original_SiteID OR @Original_SiteID IS NULL AND SiteID IS NULL);
	SELECT DateID, SiteID, PageSiteControlID, DisplayOrder, CalendarDate, DateSubject, DateComment, DateColor 
	FROM pCalendar with (nolock)
	WHERE (DateID = @DateID)


GO
GRANT EXECUTE ON  [dbo].[vpspCalendarUpdate] TO [VCSPortal]
GO
