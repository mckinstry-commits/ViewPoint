SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspRPGetReportManagerURL]
/********************************
* Created:  2012-06-18 Chris Crewdson
* Modified: 
* 
* Returns the ReportManager URL to be used in V6. This ReportManager URL is 
* used to launch to the report subscription page
* 
* Output:
*  Report Manager URL
* 
*********************************/
AS
BEGIN
SET NOCOUNT ON

SELECT Path FROM dbo.RPRL WHERE Location='ReportManager'

END
GO
GRANT EXECUTE ON  [dbo].[vspRPGetReportManagerURL] TO [public]
GO
