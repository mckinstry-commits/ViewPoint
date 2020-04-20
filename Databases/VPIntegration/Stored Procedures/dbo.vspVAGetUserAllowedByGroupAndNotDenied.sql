SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspVAGetUserAllowedByGroupAndNotDenied]
/********************************
* Created:  2012-07-27 Chris Crewdson
* Modified: 
* 
*  Returns the count of records that allow a user access to a report via a 
* group other than the optional group
* 
* Input:
* 
* 
* Output:
* 
* 
*********************************/
(
@username varchar(512) = null,
@reportid int = null,
@securitygroup int = null
) AS
BEGIN

SET NOCOUNT ON

SELECT COUNT(1) 
FROM RPRS rs 
JOIN DDSU su ON rs.SecurityGroup = su.SecurityGroup 
WHERE   Access = 0 
    AND su.VPUserName = @username 
    AND ReportID = @reportid 
    AND NOT EXISTS(
        SELECT 1 FROM RPRS rsInside
        WHERE   rsInside.Access = 2 
            AND rsInside.VPUserName = @username 
            AND rsInside.ReportID = @reportid
            AND rsInside.Co = rs.Co)
    AND (@securitygroup IS NULL OR rs.SecurityGroup <> @securitygroup)

END
GO
GRANT EXECUTE ON  [dbo].[vspVAGetUserAllowedByGroupAndNotDenied] TO [public]
GO
