SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspRFGetScenarioFileName]
/***************************************
* Created: CC 08/21/09 - Get scenarios filename, by scenario name
* Modified: 
* 
* 
* 
**************************************/
	@ScenarioName VARCHAR(128)
AS	
BEGIN
	SELECT ScenarioFileName
	FROM dbo.RFScenarios
	WHERE dbo.RFScenarios.ScenarioName = @ScenarioName;
END
GO
GRANT EXECUTE ON  [dbo].[vspRFGetScenarioFileName] TO [public]
GO
