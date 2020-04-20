SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  PROCEDURE [dbo].[vpspGetAllAvailableSSRSReportTitles]
/************************************************************
* CREATED:     Joe A 6/22/2012
* MODIFIED:    
*
* USAGE:
*   Returns the report IDs and titles for all SSRS Reports available to connects
*	*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    None       
*
* OUTPUT PARAMETERS
*   
* RETURN VALUE
	ReportID, Title
*   
************************************************************/
AS
	SET NOCOUNT ON;

SELECT rprt.ReportID, rprt.Title
FROM RPRTShared rprt, RPRL rprl, vRPRSServer rsserver
WHERE rprt.Location = rprl.Location AND rprl.ServerName = rsserver.ServerName
AND rprt.AppType = 'SQL Reporting Services' and rprt.AvailableToPortal = 'Y' and rprl.LocType = 'URL'
AND rsserver.CustomSecurity = 'Y'







GO
GRANT EXECUTE ON  [dbo].[vpspGetAllAvailableSSRSReportTitles] TO [VCSPortal]
GO
