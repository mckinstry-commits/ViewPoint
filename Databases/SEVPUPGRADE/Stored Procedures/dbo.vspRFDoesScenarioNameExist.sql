SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspRFDoesScenarioNameExist]
/***************************************
* Created: CC 08/27/09 - Check if scenario name already exists in current database
* Modified: 
*
* Checks if scenario name already exists in database
*
**************************************/
@ScenarioName VARCHAR(128)
AS
BEGIN
	IF EXISTS(SELECT TOP 1 1 FROM dbo.vRFScenarios WHERE ScenarioName = @ScenarioName)
		SELECT CAST(1 AS BIT);
	ELSE
		SELECT CAST(0 AS BIT);	
END
GO
GRANT EXECUTE ON  [dbo].[vspRFDoesScenarioNameExist] TO [public]
GO
