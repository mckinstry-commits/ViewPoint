SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[vspDDRefreshFormReports]
/********************************
* Created: GG 09/19/06  
* Modified:	GG 11/06/07 - #126080 - return all report params if any has a form level override
*			AMR 06/22/11 - Issue TK-07089, Fixing performance issue with if exists statement.
*			CJG 07/16/13 - TFS 55896 - Added UsedForPublish which should have been added earlier
*
* Called from Form Overrides to retrieve accessible Reports 
* linked to a specific Form and their Parameter defaults
*
* Input:
*	@co					current Company - needed for report security
*	@form				Form name
*
* Output:
*	@errmsg				error message
*	1st resultset		linked reports
*	2nd resultset		report parameters w/defaults
*	
* Return code:
*	0 = success, 1 = failure
*
*********************************/
    (
      @co bCompany = NULL ,
      @form VARCHAR(30) = NULL ,
      @errmsg VARCHAR(255) OUTPUT
    )
AS 
    SET nocount ON
	
    DECLARE @rcode INT ,
        @openreportcursor TINYINT ,
        @reportid INT ,
        @errmsg2 VARCHAR(255) ,
        @access TINYINT

    SET @rcode = 0

    IF @co IS NULL
        OR @form IS NULL 
        BEGIN
            SELECT  @errmsg = 'Missing input paramters!' ,
                    @rcode = 1
            GOTO vspexit
        END

-- hold Form Reports info in local table variable until Security can be determined
    DECLARE @formreports TABLE
        (
          ReportID INT ,
          Title VARCHAR(60) ,
          Access TINYINT
        )

    INSERT  @formreports
            ( ReportID ,
              Title ,
              Access
            )
            SELECT  f.ReportID ,
                    r.Title ,
                    0	 -- assume full access
            FROM    dbo.RPFRShared f ( NOLOCK )
					--use inline table function for performance issue
					CROSS APPLY (SELECT Title FROM dbo.vfRPRTShared(f.ReportID)) r
            WHERE   f.Form = @form
                    AND f.Active = 'Y'	-- active reports only
			ORDER BY r.Title

-- use a cursor to get access level for each Report
    DECLARE vcReportSecurity CURSOR
    FOR
        SELECT  ReportID
        FROM    @formreports

    OPEN vcReportSecurity
    SET @openreportcursor = 1

-- loop through all Reports on the Form
    report_loop:
    FETCH NEXT FROM vcReportSecurity INTO @reportid

    IF @@fetch_status <> 0 
        GOTO report_loop_end

    EXEC @rcode = vspRPReportSecurity @co, @reportid, @access OUTPUT,
        @errmsg2 OUTPUT
    IF @rcode <> 0 
        BEGIN
            SELECT  @errmsg = 'Error returned from vspRPReportSecurity:'
                    + @errmsg2
            GOTO vspexit
        END
    UPDATE  @formreports
    SET     Access = @access	-- save Report Access level
    WHERE   ReportID = @reportid

    GOTO report_loop

    report_loop_end:	-- processed all Reports on the Form
    CLOSE vcReportSecurity
    DEALLOCATE vcReportSecurity
    SET @openreportcursor = 0

-- return accessible Form Reports only
    SELECT  ReportID ,
            Title
    FROM    @formreports
    WHERE   Access = 0	

-- return Form Report Defaults for the accessible reports
--select r.Title, d.ReportID, d.ParameterName, d.ParameterDefault
--from dbo.RPFDShared d (nolock)
--join @formreports r on r.ReportID = d.ReportID
--where d.Form = @form
--order by d.ReportID, d.ParameterName

--if Report has any Form Parameter Defaults return all Report Params
    SELECT  r.Title ,
            p.ReportID ,
            p.ParameterName ,
            ISNULL(f.ParameterDefault, p.ParameterDefault) AS ParameterDefault,
			ISNULL(f.UsedForPublish, 0) AS UsedForPublish
    FROM    dbo.RPRPShared p ( NOLOCK )
            JOIN @formreports fr ON fr.ReportID = p.ReportID
            JOIN dbo.RPRTShared r ( NOLOCK ) ON r.ReportID = p.ReportID
            LEFT JOIN dbo.RPFDShared f ON f.ReportID = p.ReportID
                                          AND f.ParameterName = p.ParameterName
                                          AND f.Form = @form
    WHERE   r.ReportID IN ( SELECT  ReportID
                            FROM    RPFDShared
                            WHERE   Form = @form ) AND
            --Only return parameters for reports in the above collection (accessible Form Reports)
            r.ReportID IN ( SELECT  ReportID
							FROM    @formreports
							WHERE   Access = 0 )
    
    ORDER BY p.ReportID ,
            p.ParameterName

	
    vspexit:
    IF @openreportcursor = 1 
        BEGIN
            CLOSE vcReportSecurity
            DEALLOCATE vcReportSecurity
        END

    RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDRefreshFormReports] TO [public]
GO
