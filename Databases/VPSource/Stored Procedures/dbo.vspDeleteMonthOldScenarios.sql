SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspDeleteMonthOldScenarios]
/***************************************
* Created: AL 4/1/10 - Delete all scenarios that are over 30 days old
* Modified: 
* 
* 
* 
**************************************/
(@ScenarioIDs VARCHAR(MAX))

AS
BEGIN
 DELETE
	FROM dbo.RFScenarios
	WHERE
				ScenarioID in (SELECT CAST(IntCol as INT) FROM vfIntTableFromArray(@ScenarioIDs))
END
GO
GRANT EXECUTE ON  [dbo].[vspDeleteMonthOldScenarios] TO [public]
GO
