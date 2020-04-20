SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROC [dbo].[vspReportServerInfoByName]
(
    @servername AS VARCHAR(255),
    @rcode AS INT OUTPUT
)
/********************************
* Created:  2012-06-27 Chris Crewdson
* Modified:	
*
* Retrieves the RPRSServer information based on server name
*
* Input:
*	the report server name
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

    SELECT   s.[Server]
            ,s.ReportServerInstance
            ,s.ReportManagerInstance
            ,s.CustomSecurity
    FROM    RPRSServer s
    WHERE   s.ServerName = @servername
    
    RETURN @rcode
     
END TRY
BEGIN CATCH
    SELECT @rcode = 1
    RETURN @rcode
END CATCH

GO
GRANT EXECUTE ON  [dbo].[vspReportServerInfoByName] TO [public]
GO
