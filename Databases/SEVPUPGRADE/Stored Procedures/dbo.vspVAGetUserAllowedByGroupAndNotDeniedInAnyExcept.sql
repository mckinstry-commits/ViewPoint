SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspVAGetUserAllowedByGroupAndNotDeniedInAnyExcept]
/********************************
* Created:  2012-07-27 Chris Crewdson
* Modified: 
* 
*  Gets the count of records that allow a user access to a report through a 
* group not including records that are denied by a user-specific record with 
* the optional companyid to be excluded
* 
* Input:
*   username varchar(512)
*   reportid int
*   companyid int
* 
* Output:
* 
* 
*********************************/
(
@username varchar(512) = null,
@reportid int = null,
@companyid int = null
) AS
BEGIN

SET NOCOUNT ON

SELECT COUNT(1) 
FROM RPRS rs 
JOIN DDSU su ON rs.SecurityGroup = su.SecurityGroup
WHERE   Access = 0 
    AND su.VPUserName = @username 
    AND ReportID = @reportid
    AND (@companyid IS NULL OR Co <> @companyid)
    AND NOT EXISTS (
        SELECT 1 FROM RPRS rsInside
        WHERE   rsInside.Access = 2 
            AND rsInside.VPUserName = @username 
            AND rsInside.ReportID = @reportid
            AND rsInside.Co = rs.Co)

END
GO
GRANT EXECUTE ON  [dbo].[vspVAGetUserAllowedByGroupAndNotDeniedInAnyExcept] TO [public]
GO
