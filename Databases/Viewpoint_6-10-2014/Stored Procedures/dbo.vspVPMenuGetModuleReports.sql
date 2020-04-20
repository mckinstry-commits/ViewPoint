SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[vspVPMenuGetModuleReports]
/**************************************************
* Created: GG 07/14/03
* Modified: JRK 12/19/03 - RPRTShared no longer has an IconKey field so select null instead.
*			GG 06/03/04 - return AppType with Report info
*			JRK 1/26/05 - return IconKey.
*			JRK 10/25/07 - To get back RptOwner need to check is Status is "Custom", not "Override".
*			CC 07/15/09 - Issue #133695 - Hide forms that are not applicable to the current country
*			AMR 06/22/11 - Issue TK-07089, Fixing performance issue with if exists statement.
*           DW 02/19/13 - User Story #9679 (Version1 #B-07510) Make procedure return all reports if @mod=NULL
* 
* Used by VPMenu to list all Reports assigned to a 
* Viewpoint Module.  Resultset includes 'Accessible' flag to
* indicate whether the user is allowed to run the report in the 
* given Company. 
*
* Inputs:
*	@co			Company
*	@mod		Module
*
* Output:
*	resultset	Reports with access info
*	@errmsg		Error message

*
* Return code:
*	@rcode	0 = success, 1 = failure
*
****************************************************/
    (
      @co bCompany = NULL ,
      @mod CHAR(2) = NULL ,
      @country CHAR(2) = NULL ,
      @errmsg VARCHAR(512) OUTPUT
    )
AS 
    SET nocount ON 

    DECLARE @rcode INT ,
        @opencursor TINYINT ,
        @user bVPUserName ,
        @reportid INT ,
        @access TINYINT
	
    IF @co IS NULL
        BEGIN
            SELECT  @errmsg = 'Missing required input parameter(s): Company!' ,
                    @rcode = 1
            GOTO vspexit
        END

    SELECT  @rcode = 0 ,
            @user = SUSER_SNAME()

-- use a local table to hold all Reports for the Module
    DECLARE @allreports TABLE
        (
          ReportID INT ,
          Title VARCHAR(60) ,
          ReportType VARCHAR(10) ,
          RptOwner VARCHAR(128) ,
          LastAccessed DATETIME ,
          Accessible CHAR(1) ,
          Status CHAR(8) ,
          AppType VARCHAR(30) ,
          IconKey VARCHAR(20)
        )

    INSERT  @allreports
            ( ReportID ,
              Title ,
              ReportType ,
              RptOwner ,
              LastAccessed ,
              Accessible ,
              Status ,
              AppType ,
              IconKey
            )
            SELECT  m.ReportID ,
                    t.Title ,
                    t.ReportType , 
/*
 RptOwner:
 - RPRTShared now has a "Custom" field that indicates there is a custom report was
   set up, so there is a record in vRPRTc for it.
   If Custom = 1, then we return either "VP" or "User".  All custom reports
   with "viewpointcs" in the ReportOwner field of RPRTShared were modified
   by Viewpoint, so we'll display "VP".  Otherwise a user at the customer
   site created/modified the report and we'll display the text "User".
 */
                    CASE t.[Status]
                      WHEN 'Custom' THEN  --Status is "Standard" or 'Custom".
                           CASE t.ReportOwner
                             WHEN 'viewpointcs' THEN 'VP'
                             ELSE 'User'
                           END
                      ELSE NULL
                    END ,
 -- ISNULL(si.MenuSeq, m.MenuSeq) MenuSeq,
                    u.LastAccessed ,
                    'Y' ,
                    t.[Status] ,
                    t.AppType ,
                    t.IconKey
            FROM    RPRMShared m
					CROSS APPLY (SELECT * FROM dbo.vfRPRTShared(m.ReportID)) t
                    LEFT OUTER JOIN vRPUP u ON u.ReportID = m.ReportID
                                               AND u.VPUserName = @user
--left outer join vDDSI si on si.MenuItem = t.ReportID and si.Co = @co and si.VPUserName = @user and si.Mod = @mod and si.SubFolder = -1
            WHERE   m.[Mod] = ISNULL(@mod, m.[Mod])
                    AND m.Active = 'Y'
                    AND t.ShowOnMenu = 'Y'
                    AND ( t.Country = @country
                          OR t.Country IS NULL
                        )

    IF @user = 'viewpointcs' 
        GOTO return_results	-- Viewpoint system user has access to all reports 

-- create a cursor to process each Report
    DECLARE vcReports CURSOR
    FOR
        SELECT  ReportID
        FROM    @allreports

    OPEN vcReports
    SET @opencursor = 1

    report_loop:	-- check Security for each Report
    FETCH NEXT FROM vcReports INTO @reportid
    IF @@fetch_status <> 0 
        GOTO end_report_loop

    EXEC @rcode = vspRPReportSecurity @co, @reportid, @access = @access OUTPUT,
        @errmsg = @errmsg OUTPUT
    IF @rcode <> 0 
        BEGIN
           DELETE FROM @allreports WHERE ReportID=@reportid
        END
	
    UPDATE  @allreports
    SET     Accessible = CASE WHEN @access = 0 THEN 'Y'
                              ELSE 'N'
                         END
    WHERE   ReportID = @reportid

    GOTO report_loop

    end_report_loop:	--  all Reports checked
    CLOSE vcReports
    DEALLOCATE vcReports
    SELECT  @opencursor = 0

    return_results:	-- return resultset
    SELECT  ReportID ,
            Title ,
            ReportType ,
            RptOwner ,
            LastAccessed ,
            Accessible ,
            Status ,
            AppType ,
            IconKey
    FROM    @allreports
    ORDER BY Title
   
    vspexit:
    IF @opencursor = 1 
        BEGIN
            CLOSE vcReports
            DEALLOCATE vcReports
        END

    IF @rcode <> 0 
        SELECT  @errmsg = @errmsg + CHAR(13) + CHAR(10)
                + '[vspVPMenuGetModuleReports]'
    RETURN @rcode



GO
GRANT EXECUTE ON  [dbo].[vspVPMenuGetModuleReports] TO [public]
GO
