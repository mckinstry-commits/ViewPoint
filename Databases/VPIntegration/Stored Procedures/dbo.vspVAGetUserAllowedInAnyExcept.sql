SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspVAGetUserAllowedInAnyExcept]
/********************************
* Created:  2012-07-27 Chris Crewdson
* Modified: 
* 
*  Returns the count of records that allow a user access to a report other 
* than records for the optional companyid
* 
* Input:
* username varchar(512)
* @reportid int
* @companyid int
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
FROM RPRS 
WHERE   Access = 0 
    AND VPUserName = @username 
    AND ReportID = @reportid
    AND (@companyid IS NULL OR Co <> @companyid)

END
GO
GRANT EXECUTE ON  [dbo].[vspVAGetUserAllowedInAnyExcept] TO [public]
GO
