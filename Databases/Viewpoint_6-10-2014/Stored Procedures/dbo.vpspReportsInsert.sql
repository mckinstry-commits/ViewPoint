SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspReportsInsert]
AS
SET NOCOUNT ON;

SELECT r.PortalReportID, r.ReportID, v.Title, v.FileName, v.Location, v.ReportType, 
v.ShowOnMenu, v.ReportMemo, v.ReportDesc, v.AppType, v.Version, v.IconKey 
FROM pReports r INNER JOIN RPRT v ON r.ReportID = v.ReportID



GO
GRANT EXECUTE ON  [dbo].[vpspReportsInsert] TO [VCSPortal]
GO
