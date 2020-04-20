SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspVAGetReportsItemPath]
/********************************
* Created: Joe AmRhein 2012-06-12
* 
* Returns File Name and Path for the given ReportID. 
* 
* Input:
* @reportid - ReportID for which we are returning information
* 
* Output:
* Reports FileName and Path
* 
*********************************/
 (@reportid int = null)
AS
BEGIN

	EXEC vspVAGetReportsItemPath @reportid;

END
GO
GRANT EXECUTE ON  [dbo].[vpspVAGetReportsItemPath] TO [VCSPortal]
GO
