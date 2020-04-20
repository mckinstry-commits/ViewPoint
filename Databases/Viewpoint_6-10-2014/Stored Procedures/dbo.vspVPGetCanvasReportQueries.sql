SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[vspVPGetCanvasReportQueries]
/**************************************************
* Created: CC 09/04/2008
* Modified: 
*			
*	
*	Retrieves all queries for a specified report id
* 
*
*
****************************************************/
(@ReportID int = -1)

AS

SET NOCOUNT ON
	
SELECT DataSetName, QueryText FROM RPRQShared WHERE ReportID = @ReportID


GO
GRANT EXECUTE ON  [dbo].[vspVPGetCanvasReportQueries] TO [public]
GO
