SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspGetMonthOldScenarios]
/***************************************
* Created: AL 4/1/10 - Get all scenarios that are over 30 days old
* Modified: 
* 
* 
* 
**************************************/
AS
BEGIN
	SELECT dbo.RFScenarios.ScenarioID,
		   dbo.RFScenarios.RecordingDateTime,
		   dbo.RFScenarios.ScenarioFileName
	FROM dbo.RFScenarios
	WHERE
				DATEDIFF(day, RecordingDateTime, GETDATE()) > 30
				ORDER BY RecordingDateTime desc
END

GO
GRANT EXECUTE ON  [dbo].[vspGetMonthOldScenarios] TO [public]
GO
