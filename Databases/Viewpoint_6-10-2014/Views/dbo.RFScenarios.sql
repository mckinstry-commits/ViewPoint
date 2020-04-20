SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
	
CREATE VIEW [dbo].[RFScenarios] AS 

SELECT dbo.vRFScenarios.ScenarioID,
	   dbo.vRFScenarios.ScenarioName,
	   dbo.vRFScenarios.Customer,
	   dbo.vRFScenarios.UserName,
	   dbo.vRFScenarios.RecordingDateTime,
	   dbo.vRFScenarios.Scene,
	   dbo.vRFScenarios.IssueNumber,
	   dbo.vRFScenarios.ScenarioFileName,
	   dbo.vRFScenarios.Module
	   
FROM dbo.vRFScenarios;


GO
GRANT SELECT ON  [dbo].[RFScenarios] TO [public]
GRANT INSERT ON  [dbo].[RFScenarios] TO [public]
GRANT DELETE ON  [dbo].[RFScenarios] TO [public]
GRANT UPDATE ON  [dbo].[RFScenarios] TO [public]
GRANT SELECT ON  [dbo].[RFScenarios] TO [Viewpoint]
GRANT INSERT ON  [dbo].[RFScenarios] TO [Viewpoint]
GRANT DELETE ON  [dbo].[RFScenarios] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[RFScenarios] TO [Viewpoint]
GO
