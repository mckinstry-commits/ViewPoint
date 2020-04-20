SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspVAGetUserNotDeniedInEveryCompany]
/********************************
* Created:  2012-07-27 Chris Crewdson
* Modified: 
* 
*  Returns the count of companies that do not have denied records for this 
* user to this report, including "All Companies" (-1)
* 
* Input:
* username varchar(512)
* reportid int
* 
* Output:
* 
* 
*********************************/
(
@username varchar(512) = null,
@reportid int = null
) AS
BEGIN

SET NOCOUNT ON;

WITH allRecords AS 
(
    SELECT 1 AS a 
    FROM HQCO co 
    WHERE co.HQCo NOT IN (
        SELECT rs.Co FROM RPRS rs 
        WHERE   Access = 2 
            AND VPUserName = @username 
            AND ReportID = @reportid) 
 UNION 
    SELECT 1 AS a 
    FROM RPRS 
    WHERE   Co = -1 
        AND Access = 2 
        AND VPUserName = @username 
        AND ReportID = @reportid
)

SELECT COUNT(1) 
FROM allRecords

END
GO
GRANT EXECUTE ON  [dbo].[vspVAGetUserNotDeniedInEveryCompany] TO [public]
GO
