SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspRPSaveReportViewerSettings]
/***********************************************************
 * CREATED BY: TEJ 04/19/2011 (Split out vspRPSavePrintOptions - which should now be obsolete)
 * MODIFIED BY: AMR 06/22/11 - Issue TK-07089 , Fixing performance issue with if exists statement.
 *
 *USAGE:
 * Save the ReportViewer settings for the given report/username combination. 
 * Provides a snapshot of size and zoom that the given user had on the given
 * Report the last time it was opened.
 * 
 * INPUT PARAMETERS
 *    @username         VPUserName
 *    @reportid			ReportID
 *    @zoom             int
 *    @viewerwidth      int
 *    @viewerheight     int
 *    @lastaccessdate   small date time
 *
 * OUTPUT PARAMETERS
 *    @msg           error message from
 *
 * RETURN VALUE
 *    none
 *****************************************************/
    (
      @username VARCHAR(128) = NULL ,
      @reportid INT = NULL ,
      @zoom INT = NULL ,
      @viewerwidth INT = NULL ,
      @viewerheight INT = NULL ,
      @lastaccessdate SMALLDATETIME = NULL ,
      @msg VARCHAR(255) OUTPUT
	
    )
AS 
    SET NOCOUNT OFF
    DECLARE @rcode INT
    SELECT  @rcode = 0

    IF @username IS NULL 
        BEGIN
            SELECT  @msg = 'Missing VP User Name' + CHAR(13) + CHAR(10)
							+ '[vspRPSaveReportViewerSettings]'	,
                   @rcode = 1
            RETURN @rcode
        END

    IF @reportid IS NULL
        OR @reportid = 0 
        BEGIN
            SELECT  @msg = 'Missing ReportID' + CHAR(13) + CHAR(10)
							+ '[vspRPSaveReportViewerSettings]'	,
                   @rcode = 1
            RETURN @rcode
        END

    IF @reportid > 0 
        BEGIN
        --use inline table function for performance issue
            IF NOT EXISTS (SELECT 1 FROM dbo.vfRPRTShared(@reportid))  
                BEGIN
                    SELECT  @msg = 'VP User:  ' + @username + 'Report ID: '
                            + CONVERT(VARCHAR, ISNULL(@reportid, 0))
                            + 'does not exist!' + CHAR(13) + CHAR(10)
							+ '[vspRPSaveReportViewerSettings]'	,
                           @rcode = 1
                    RETURN @rcode
                END
        END

    IF ( SELECT COUNT(*)
         FROM   dbo.vRPUP
         WHERE  VPUserName = @username
                AND ReportID = @reportid
       ) = 0 
        BEGIN
            INSERT  INTO vRPUP
                    ( VPUserName ,
                      ReportID ,
                      Zoom ,
                      ViewerWidth ,
                      ViewerHeight ,
                      LastAccessed
                    )
            VALUES  ( @username ,
                      @reportid ,
                      @zoom ,
                      @viewerwidth ,
                      @viewerheight ,
                      @lastaccessdate
                    )
            IF @@ROWCOUNT = 0 
                BEGIN
                    SELECT  @msg = 'VP User:  ' + @username + 'Report ID: '
                            + CONVERT(VARCHAR, ISNULL(@reportid, 0))
                            + ' did not insert!' + CHAR(13) + CHAR(10)
							+ '[vspRPSaveReportViewerSettings]'	,
							@rcode = 1
					RETURN	@rcode
                END
        END
    ELSE 
        BEGIN
            UPDATE  dbo.vRPUP
            SET     Zoom = ISNULL(@zoom, Zoom) ,
                    ViewerWidth = ISNULL(@viewerwidth, ViewerWidth) ,
                    ViewerHeight = ISNULL(@viewerheight, ViewerHeight) ,
                    LastAccessed = ISNULL(@lastaccessdate, LastAccessed)
            FROM    dbo.vRPUP
            WHERE   VPUserName = @username
                    AND ReportID = @reportid

            IF @@ROWCOUNT = 0 
                BEGIN
                    SELECT  @msg = 'VP User:  ' + @username + 'Report ID: '
                            + CONVERT(VARCHAR, ISNULL(@reportid, 0))
                            + ' did not update!' + CHAR(13) + CHAR(10)
							+ '[vspRPSaveReportViewerSettings]'	,
							@rcode = 1
					RETURN @rcode
                END
        END

RETURN @rcode
GO
GRANT EXECUTE ON  [dbo].[vspRPSaveReportViewerSettings] TO [public]
GO
