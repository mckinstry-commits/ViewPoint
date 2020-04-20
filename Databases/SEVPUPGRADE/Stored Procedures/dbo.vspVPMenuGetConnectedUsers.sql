SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspVPMenuGetConnectedUsers]
/**************************************************
* Created: JRK 09/08/03
* Modified: JRK w/GG 06/27/06 Remove GROUP BY and MAX so users are counted multiple times.
            2012-01-06 - Chris Crewdson - Changing so different user logins from the same hostname are counted
*
* Used by VPMenu to count/itemize users for a license check or to list logged in users.
* Each user + workstation are counted as 1 license, so a user can be logged in from
* multiple workstations and each will be counted.
*
* Inputs:
*   @sysuseracct    Name of the Viewpoint system account in SQL (usually "viewpointcs").
*
* Output:
*   resultset of user info
*   @errmsg     Error message
*
*
* Return code:
*   @rcode  0 = success, 1 = failure
*
****************************************************/
(@sysuseracct bVPUserName,
 @errmsg      VARCHAR(512) output)
AS
  SET nocount ON

  DECLARE @rcode INT

  SELECT @rcode = 0

  IF @sysuseracct = NULL
    BEGIN
        SELECT @errmsg = 'Missing required input parameter: sysuseracct (eg, viewpointcs)',
               @rcode = 1

        GOTO VSPEXIT
    END

  RETURN_RESULTS:

  SELECT *
  FROM  (SELECT  m.loginame
                ,m.hostname
                ,( m.last_batch ) AS most_recent_batch
                ,( m.login_time ) AS most_recent_login
                ,u.FullName
                ,u.Phone
                ,u.EMail
                ,Row_number() OVER (PARTITION BY [hostname], [loginame] ORDER BY [hostname]) AS RowNum
         FROM   master.dbo.sysprocesses m
                LEFT OUTER JOIN DDUP u
                  ON m.loginame = u.VPUserName
         WHERE  program_name = 'ViewpointClient'
                AND loginame <> @sysuseracct -- exclude viewpoint system login
        ) AS tbl
  WHERE  RowNum = 1
  ORDER  BY most_recent_login ASC

  VSPEXIT:

  IF @rcode <> 0
    SELECT @errmsg = @errmsg + Char(13) + Char(10) + '[vspVPMenuGetConnectedUsers]'

  RETURN @rcode 

GO
GRANT EXECUTE ON  [dbo].[vspVPMenuGetConnectedUsers] TO [public]
GO
