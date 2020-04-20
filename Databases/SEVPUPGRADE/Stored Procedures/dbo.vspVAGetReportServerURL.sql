SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspVAGetReportServerURL]
/********************************
* Created: Narendra 2012-04-09
* Modified: 
* 
* Returns Report Server URL used in V6 
* This Report Server URL is used to get Report Server path and 
* to find the domain where Report Server is located
* 
* Output:
*  Report Server URL
* 
*********************************/
AS
BEGIN
SET NOCOUNT ON

SELECT Path FROM dbo.RPRL WHERE Location='ReportServer'

END
GO
GRANT EXECUTE ON  [dbo].[vspVAGetReportServerURL] TO [public]
GO
