SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    PROCEDURE [dbo].[vspRPReportSavedPrinterSettings]
/********************************
*  Created: TEJ 1/31/2011
* Modified: 
*
* Retrieves the saved printer settings for the passed in report id and the 
* user currently logged in to the database
*
* Input:
*	@reportid	Report ID#
*
* Output:
*		PrinterName, PaperSource, PaperSize, Duplex, Orientation
*
*********************************/
  (@reportid INT = null)
AS
BEGIN

select u.PrinterName, u.PaperSource, u.PaperSize, u.Duplex, u.Orientation, VPUserName
  from RPUP u
 where u.ReportID =  @reportid 
   and u.VPUserName = suser_sname()
END

GRANT EXECUTE ON vspDDGetTrustedConnectionLogin TO PUBLIC


GO
GRANT EXECUTE ON  [dbo].[vspRPReportSavedPrinterSettings] TO [public]
GO
