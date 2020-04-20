SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspCalendarDelete
(
	@Original_DateID int,
	@Original_CalendarDate datetime,
	@Original_DateColor varchar(50),
	@Original_DateComment varchar(255),
	@Original_DateSubject varchar(50),
	@Original_DisplayOrder int,
	@Original_PageSiteControlID int,
	@Original_SiteID int
)
AS
	SET NOCOUNT OFF;
DELETE FROM pCalendar
WHERE (DateID = @Original_DateID) 
AND (CalendarDate = @Original_CalendarDate) 
AND (DateColor = @Original_DateColor) 
AND (DateComment = @Original_DateComment OR @Original_DateComment IS NULL AND DateComment IS NULL) 
AND (DateSubject = @Original_DateSubject) 
AND (DisplayOrder = @Original_DisplayOrder) 
AND (PageSiteControlID = @Original_PageSiteControlID) 
AND (SiteID = @Original_SiteID OR @Original_SiteID IS NULL AND SiteID IS NULL)


GO
GRANT EXECUTE ON  [dbo].[vpspCalendarDelete] TO [VCSPortal]
GO
