SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROC [dbo].[vspReportServerInfo]
(
    @ReportID AS INT,
    @rcode AS INT OUTPUT
)

/********************************
* Created: HH 6/25/12 - TK-15495, get SSRS server information in RPRSServer
* Modified:	
*
* Retrieves the RPRSServer information based on a ReportID
*
* Input:
*	the report id to be launched.
*
* Output:
*
* Return code:
*	0 = success, 1 = failure
*
*********************************/
AS 
    SET nocount ON

BEGIN TRY

    SELECT  @rcode = 0

    SELECT   l.[Path]
            ,t.[FileName]
            ,l.LocType
            ,s.ServerName
            ,s.[Server]
            ,s.ReportServerInstance
            ,s.ReportManagerInstance
            ,s.CustomSecurity
            --using a inline table function to reduce index scans
    FROM    dbo.vfRPRTShared(@ReportID) t
            JOIN RPRL l ON l.Location = t.Location
            LEFT OUTER JOIN RPRSServer s ON s.ServerName = l.ServerName
    
    RETURN @rcode
     
END TRY
BEGIN CATCH
    SELECT @rcode = 1
    RETURN @rcode
END CATCH

GO
GRANT EXECUTE ON  [dbo].[vspReportServerInfo] TO [public]
GO
