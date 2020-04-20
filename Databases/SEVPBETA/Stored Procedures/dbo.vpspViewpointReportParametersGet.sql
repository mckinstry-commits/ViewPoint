SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspViewpointReportParametersGet]
(@ReportID int, @UserID int, @ParameterName varchar(30) = NULL)
AS
SET NOCOUNT ON;

SELECT ReportID, ParameterName, DisplaySeq, s.Description, PortalParameterDefault, 
CAST(ISNULL(p.Description, PortalParameterDefault) as VARCHAR(50)) as 'PortalParameterDefaultDisplay',
PortalAccess,
ISNULL(a.AccessDescription, 'Not Set') as 'PortalAccessDisplay',
@UserID AS 'UserID' 
FROM RPRPShared s
LEFT JOIN pvPortalParameters p ON s.PortalParameterDefault = p.KeyField
LEFT JOIN pvPortalParameterAccess a ON s.PortalAccess = a.KeyField
WHERE ReportID = @ReportID AND ParameterName = ISNULL(@ParameterName, ParameterName)
ORDER BY DisplaySeq
GO
GRANT EXECUTE ON  [dbo].[vpspViewpointReportParametersGet] TO [VCSPortal]
GO
