SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspReportParametersGet]
(@ReportID int = null)
AS

SET NOCOUNT ON;

SELECT s.ReportID, s.ParameterName, s.DisplaySeq, s.Description,
ISNULL(s.PortalParameterDefault, -1) As 'PortalParameterDefault', 
ISNULL(v.Description, 'Not Set') as 'PortalParameterDefaultDisplay',
ISNULL(s.PortalAccess, -1) AS 'PortalAccess',
ISNULL(a.AccessDescription, 'Not Set') as 'PortalAccessDisplay'
FROM RPRPShared s
LEFT JOIN pvPortalParameters v ON s.PortalParameterDefault = v.KeyField
LEFT JOIN pvPortalParameterAccess a ON s.PortalAccess = a.KeyField
WHERE s.ReportID = ISNULL(@ReportID, s.ReportID)
ORDER BY s.DisplaySeq
GO
GRANT EXECUTE ON  [dbo].[vpspReportParametersGet] TO [VCSPortal]
GO
