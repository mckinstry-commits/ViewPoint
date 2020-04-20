SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspCalendarDatesInsert]
(
	@PageSiteControlID int,
	@DateID int,
	@DateOrder int,
	@DateColor varchar(50)
)
AS
	
SET NOCOUNT OFF;

INSERT INTO pCalendarDates(PageSiteControlID, DateID, DateOrder, DateColor)
	VALUES (@PageSiteControlID, @DateID, @DateOrder, @DateColor);


SELECT CalendarDateID, PageSiteControlID, c.DateID, d.Name, DateOrder, DateColor 
	FROM pCalendarDates c with (nolock)
	INNER JOIN pDates d ON c.DateID = d.DateID 
	WHERE CalendarDateID = SCOPE_IDENTITY();
GO
GRANT EXECUTE ON  [dbo].[vpspCalendarDatesInsert] TO [VCSPortal]
GO
