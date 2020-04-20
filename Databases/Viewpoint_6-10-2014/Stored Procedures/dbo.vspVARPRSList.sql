SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  PROC [dbo].[vspVARPRSList]
/*******************************************************************
* Created: GG 07/17/07
* Modified: AL 07/31/07 Added Report Type to the query
*			GG 08/03/07 - added @group and @user parameters as query filters
*			AMR 06/22/11 - Issue TK-07089 , Fixing performance issue with if exists statement.
*			HH 07/10/12 - Issue TK-15776 , added RPRT.AppType
*			AL 09/27/12 - Changed Security Group to INT
* Usage:
* Returns a resultset of Report Security info.  Includes all combinations of 
* report security groups and/or users with reports filtered by module and company.
* Used by VA Report Security to display information in the grid.
*
* Inputs:
*	@mod			Module used to filtered reports, null for all
*	@co				Company # or -1 for all company access
*	@type			Return entries for Security Groups ('G') or Users ('U')
*	@group			Security Group or null for all, only used when @type = 'G'
*	@user			User or null for all, only used when @type = 'U'
*
* Outputs:
*	resultset of report security info 
*	@msg				Error message
*
* Return code:
*	0 = success, 1 = error w/messsge
*
*
*********************************************************************/
    (
      @mod CHAR(2) = NULL ,
      @co SMALLINT = NULL ,
      @type CHAR(1) = NULL ,
      @group INT = NULL ,
      @user bVPUserName = NULL ,
      @msg VARCHAR(255) OUTPUT
    )
AS 
    SET nocount ON
    DECLARE @rcode INT
    SET @rcode = 0

    IF @co IS NULL 
        BEGIN
            SELECT  @msg = 'Missing Company#!' ,
                    @rcode = 1
            RETURN @rcode
        END
    IF @type IS NULL
        OR @type NOT IN ( 'G', 'U' ) 
        BEGIN
            SELECT  @msg = 'Invalid security option, must select by ''G'' = Security Group or ''U'' = User!' ,
                    @rcode = 1
            RETURN @rcode
        END


    IF @type = 'G'	-- Report Security by Module, Co#, and Security Group 
        BEGIN
            SELECT DISTINCT
                    r.ReportID ,
                    r.Title ,
                    r.[ReportType] ,
                    r.AppType ,
                    ISNULL(s.SecurityGroup, g.SecurityGroup) AS [SecGroup] ,
                    g.Name AS [SecGroupDesc] ,
                    NULL AS [UserName] ,
                    NULL AS [FullName] ,
                    CASE WHEN s.Access IS NULL THEN 1
                         ELSE s.Access
                    END AS [Access]	-- return '1' for no access
            FROM    dbo.RPRMShared m ( NOLOCK )
					CROSS APPLY (SELECT Title, 
										ReportID,
										[ReportType],
										AppType
								 FROM dbo.vfRPRTShared (m.ReportID)) r
					JOIN dbo.vDDSG g ( NOLOCK ) ON g.SecurityGroup = ISNULL(@group,g.SecurityGroup)
                                                   AND GroupType = 2	-- Report Security Groups only
                    LEFT JOIN dbo.vRPRS s ( NOLOCK ) ON s.ReportID = r.ReportID
                                                        AND s.SecurityGroup = g.SecurityGroup
                                                        AND s.Co = @co
            WHERE   m.[Mod] = ISNULL(@mod, m.[Mod])
            ORDER BY r.Title
        END

    IF @type = 'U'	-- Report Security by Module, Co#, and User Name
        BEGIN
            SELECT DISTINCT
                    r.ReportID ,
                    r.Title ,
                    r.[ReportType] ,
                    r.AppType ,
                    NULL AS [SecGroup] ,
                    NULL AS [SecGroupDesc] ,
                    ISNULL(s.VPUserName, p.VPUserName) AS [UserName] ,
                    p.FullName ,
                    CASE WHEN s.Access IS NULL THEN 1
                         ELSE s.Access
                    END AS [Access]
            FROM    dbo.RPRMShared m
                    CROSS APPLY (SELECT Title, 
										ReportID,
										[ReportType],
										AppType
								 FROM dbo.vfRPRTShared (m.ReportID)) r
					JOIN dbo.vDDUP p ( NOLOCK ) ON p.VPUserName = ISNULL(@user,p.VPUserName)
													AND p.VPUserName NOT IN ('vcspublic', 'viewpointcs' )	-- exclude these
                    LEFT JOIN dbo.vRPRS s ( NOLOCK ) ON s.ReportID = r.ReportID
                                                        AND s.VPUserName = p.VPUserName
                                                        AND s.Co = @co
            WHERE   m.[Mod] = ISNULL(@mod, m.[Mod])
            ORDER BY r.Title
        END
 
    RETURN @rcode
GO
GRANT EXECUTE ON  [dbo].[vspVARPRSList] TO [public]
GO
