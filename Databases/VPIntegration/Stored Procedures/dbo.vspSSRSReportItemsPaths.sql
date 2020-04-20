SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROC [dbo].[vspSSRSReportItemsPaths]
(
    @ServerName AS VARCHAR(50),
    @rcode AS INT OUTPUT
)

/********************************
* Created: HH 6/25/12 - TK-15776, get all SSRS report items that are registered in Viewpoint, i.e. RPRTShared
* Modified:	
*
* Retrieves the reports' paths based on a SSRS server 
*
* Input:
*	the report server name registered in RPRSServer.ServerName
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

	SELECT ReportPath = 
		CASE 
			WHEN l.[Path] like '/%' THEN l.[Path] + t.[FileName]
			ELSE '/' + l.[Path] + t.[FileName]
		END
	FROM 
	RPRTShared t
	INNER JOIN RPRL l ON t.Location =l.Location
	INNER JOIN RPRSServer s ON l.ServerName = s.ServerName
	WHERE AppType = 'SQL Reporting Services' 
		AND s.[ServerName] = @ServerName

    
    RETURN @rcode
     
END TRY
BEGIN CATCH
    SELECT @rcode = 1
    RETURN @rcode
END CATCH

GO
GRANT EXECUTE ON  [dbo].[vspSSRSReportItemsPaths] TO [public]
GO
