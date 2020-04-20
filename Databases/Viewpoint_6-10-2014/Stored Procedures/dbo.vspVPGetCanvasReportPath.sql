SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspVPGetCanvasReportPath]
/**************************************************
* Created: CC 09/04/2008
* Modified: AMR 06/22/11 - Issue TK-07089 , Fixing performance issue with if exists statement.
*           2012-06-12 Chris Crewdson - TK-14612 - Removed '\' from SELECT to 
*               support all reports.
*   
*   
*   Retrieves report path of a specified report ID
****************************************************/
    (
      @co bCompany ,
      @ReportID INT = -1
    )
AS 
    SET NOCOUNT ON

    DECLARE @access TINYINT ,
        @errmsg VARCHAR(512) ;

    EXEC vspRPReportSecurity @co, @ReportID, @access = @access OUTPUT,
        @errmsg = @errmsg OUTPUT

    IF @access = 2
        OR ISNULL(@errmsg, '') <> '' 
        SELECT  ''
    IF @access = 0 
        SELECT  l.Path + s.[FileName]
        --use inline table function for performance issue
        FROM    dbo.vfRPRTShared(@ReportID) s
                INNER JOIN RPRL l ON s.Location = l.Location
GO
GRANT EXECUTE ON  [dbo].[vspVPGetCanvasReportPath] TO [public]
GO
