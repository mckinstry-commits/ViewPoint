SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  PROCEDURE [dbo].[vpspGetSSRSReportURLParts]
/************************************************************
* CREATED:     SDE 6/6/2006
* MODIFIED:    
*
* USAGE:
*   Returns SSRS Server, ReportServer Directory, Path, and File Name for 
*	Connects to display a SSRS report
*	
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    ReportID        
*
* OUTPUT PARAMETERS
*   
* RETURN VALUE
*   
************************************************************/
(@ReportID int)
AS
	SET NOCOUNT ON;

SELECT rprt.ReportID, rsserver.Server, rsserver.ReportServerInstance, rprl.Path, rprt.FileName
FROM RPRTShared rprt, RPRL rprl, vRPRSServer rsserver
WHERE rprt.Location = rprl.Location AND rprl.ServerName = rsserver.ServerName
AND rprt.AppType = 'SQL Reporting Services' and rprt.AvailableToPortal = 'Y' and rprl.LocType = 'URL'
AND rsserver.CustomSecurity = 'Y' AND rprt.ReportID = @ReportID







GO
GRANT EXECUTE ON  [dbo].[vpspGetSSRSReportURLParts] TO [VCSPortal]
GO
