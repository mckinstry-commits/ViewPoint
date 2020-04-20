SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspPortalReportsControlsGet]
(@ReportID int = null,
@PortalControlID int = null)
AS
	
SET NOCOUNT ON;
  
SELECT r.ReportID, r.Title, c.PortalControlID, p.Name, c.Access, r.UserNotes, r.ReportDesc, 
	r.FileName, l.Path, r.AvailableToPortal FROM pvReportControlsShared c
	INNER JOIN RPRTShared r ON r.ReportID = c.ReportID
	INNER JOIN RPRL l ON r.Location = l.Location
	INNER JOIN pPortalControls p ON p.PortalControlID = c.PortalControlID
WHERE c.PortalControlID = ISNULL(@PortalControlID, c.PortalControlID)
  AND c.ReportID = ISNULL(@ReportID, c.ReportID)
GO
GRANT EXECUTE ON  [dbo].[vpspPortalReportsControlsGet] TO [VCSPortal]
GO
