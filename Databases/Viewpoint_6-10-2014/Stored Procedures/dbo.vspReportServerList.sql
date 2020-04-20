SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROC [dbo].[vspReportServerList]
(
    @rcode AS INT OUTPUT
)

/********************************
* Created:  2012-06-29 Chris Crewdson
* Modified: 
*
* Retrieves all RPRSServer information
*
* Input:
* 
*
* Output:
*
* Return code:
*   0 = success, 1 = failure
*
*********************************/
AS 
    SET nocount ON

BEGIN TRY

    SELECT  @rcode = 0

    SELECT   s.ServerName
            ,s.[Server]
            ,s.ReportServerInstance
            ,s.ReportManagerInstance
            ,s.CustomSecurity
    FROM    RPRSServer s
    
    RETURN @rcode
     
END TRY
BEGIN CATCH
    SELECT @rcode = 1
    RETURN @rcode
END CATCH

GO
GRANT EXECUTE ON  [dbo].[vspReportServerList] TO [public]
GO
