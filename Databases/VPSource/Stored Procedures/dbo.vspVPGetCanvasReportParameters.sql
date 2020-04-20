SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspVPGetCanvasReportParameters]
/**************************************************
* Created: CC 10/21/2008
* Modified: 
*			
*	
*	Retrieves all parameters for a specified report id
* 
*
*
****************************************************/
(@ReportID int = -1)

AS

SET NOCOUNT ON
	
	SELECT	ParameterName
			,[Description]
			,ParameterDefault 
			, p.ReportID
	FROM RPRPShared p
	WHERE ReportID = @ReportID
GO
GRANT EXECUTE ON  [dbo].[vspVPGetCanvasReportParameters] TO [public]
GO
