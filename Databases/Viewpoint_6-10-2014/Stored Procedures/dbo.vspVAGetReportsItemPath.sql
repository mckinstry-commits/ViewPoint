SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspVAGetReportsItemPath]
/********************************
* Created: Narendra 2012-04-09
* Modified: 
*  Chris Crewdson 2012-06-06 - Added Path to selection
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
SET NOCOUNT ON

SELECT (rl.Path + rt.FileName) AS ItemPath
FROM dbo.RPRTShared rt
JOIN dbo.RPRL rl ON rt.Location = rl.Location
WHERE ReportID = @reportid

END
GO
GRANT EXECUTE ON  [dbo].[vspVAGetReportsItemPath] TO [public]
GO
