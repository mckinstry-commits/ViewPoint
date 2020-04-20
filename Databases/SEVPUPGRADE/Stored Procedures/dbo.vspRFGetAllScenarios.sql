SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspRFGetAllScenarios]
/***************************************
* Created: CC 08/21/09 - Get all available scenarios
* Modified: 
* 
* 
* 
**************************************/
AS
BEGIN
	SELECT dbo.RFScenarios.ScenarioName,
		   dbo.RFScenarios.Customer,
		   dbo.RFScenarios.UserName,
		   dbo.RFScenarios.RecordingDateTime,
		   dbo.RFScenarios.Scene,
		   dbo.RFScenarios.IssueNumber,
		   dbo.RFScenarios.Module,
		   dbo.RFScenarios.ScenarioFileName
	FROM dbo.RFScenarios;
END

GO
GRANT EXECUTE ON  [dbo].[vspRFGetAllScenarios] TO [public]
GO
