SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspVAGetReportsAppAndLocType]
/********************************
* Created: Narendra 2012-04-09
* Modified: 
*   2012-06-15 Chris Crewdson - Added LocType to return
*
* Returns App Type (Crystal/SQL Reporting Services) and LocType (URL, UNC) for 
* the given ReportID 
* 
* Input:
* @reportid - ReportID for which we are returning AppType.
*
*Output:
* Reports App Type (Crystal/SQL Reporting Services)
* Location LocType (URL, UNC)
*
*********************************/
(@reportid int = null)
AS
BEGIN
SET NOCOUNT ON

SELECT rs.AppType, rl.LocType
FROM dbo.RPRTShared rs
JOIN dbo.RPRL rl ON rs.Location = rl.Location
WHERE ReportID = @reportid

END
GO
GRANT EXECUTE ON  [dbo].[vspVAGetReportsAppAndLocType] TO [public]
GO
