SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspReportControlsGet]
(@ReportID int,
@UserID int,
@PortalControlID int = null)
AS
	
SET NOCOUNT ON;


--DECLARE @ReportID int, @UserID int, @PortalControlID int 
--SET @ReportID = 1
--SET @UserID = 1
--SET @PortalControlID = null


--SELECT DISTINCT @ReportID as ReportID, c.PortalControlID, c.Name,
--CASE ISNULL(r.Access, -1) WHEN -1 THEN 0 ELSE r.Access END as Access,
--CASE ISNULL(r.Access, -1) 
--	WHEN -1 THEN 'Not Available'
--	WHEN 0 THEN 'Not Available'
--	WHEN 1 THEN 'Available'
--	ELSE 'Not Avaialable'
--	END
--	as 'AccessDisplay',
--@UserID as 'UserID'
--FROM pPortalControls c
--LEFT OUTER JOIN pvReportControlsShared r 
--ON c.PortalControlID = r.PortalControlID AND (r.ReportID = @ReportID OR r.ReportID IS NULL)
--WHERE c.PortalControlID = ISNULL(@PortalControlID, c.PortalControlID)


SELECT DISTINCT @ReportID as ReportID, c.PortalControlID, c.Name,
ISNULL(r.Access, 0) AS Access,
CASE WHEN r.Access = 1 THEN 'Available' ELSE 'Not Available' END AS AccessDisplay,
@UserID AS UserID
FROM pPortalControls c
LEFT OUTER JOIN pvReportControlsShared r 
ON c.PortalControlID = r.PortalControlID AND (r.ReportID = @ReportID OR r.ReportID IS NULL)
WHERE c.PortalControlID = ISNULL(@PortalControlID, c.PortalControlID)

--SELECT * FROM pReportControlsCustom
GO
GRANT EXECUTE ON  [dbo].[vpspReportControlsGet] TO [VCSPortal]
GO
