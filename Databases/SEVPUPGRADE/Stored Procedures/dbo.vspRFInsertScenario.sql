SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspRFInsertScenario]
/***************************************
* Created: CC 08/21/09 - Insert scenario information
* Modified: 
* 
* 
* 
**************************************/
(
	  @theScenarioName			VARCHAR(128)
	, @theCustomer				VARCHAR(128)
	, @theUserName				VARCHAR(128)
	, @theRecordingDate			DateTime 
	, @theIssueNumber			VARCHAR(20)
	, @theScene					VARCHAR(128)
	, @theScenarioFileName		VARCHAR(128)
	, @theModule				VARCHAR(4)
)
AS
BEGIN
	INSERT INTO dbo.RFScenarios (ScenarioName, Customer, UserName, RecordingDateTime, Scene, IssueNumber, ScenarioFileName, Module ) 
	VALUES (@theScenarioName, @theCustomer, @theUserName, @theRecordingDate, @theScene, @theIssueNumber, @theScenarioFileName, @theModule);
END
GO
GRANT EXECUTE ON  [dbo].[vspRFInsertScenario] TO [public]
GO
