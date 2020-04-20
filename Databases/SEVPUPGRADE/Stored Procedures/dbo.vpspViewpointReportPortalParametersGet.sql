SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspViewpointReportPortalParametersGet]
AS
SET NOCOUNT ON;

SELECT KeyField, Description FROM pvPortalParameters
GO
GRANT EXECUTE ON  [dbo].[vpspViewpointReportPortalParametersGet] TO [VCSPortal]
GO
