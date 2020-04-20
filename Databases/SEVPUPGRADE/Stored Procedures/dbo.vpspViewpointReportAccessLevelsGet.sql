SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspViewpointReportAccessLevelsGet]
AS
SET NOCOUNT ON;

SELECT KeyField, AccessDescription FROM pvPortalParameterAccess
GO
GRANT EXECUTE ON  [dbo].[vpspViewpointReportAccessLevelsGet] TO [VCSPortal]
GO
