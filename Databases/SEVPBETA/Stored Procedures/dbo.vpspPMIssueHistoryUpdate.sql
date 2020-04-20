SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspPMIssueHistoryUpdate]
/************************************************************
* CREATED:     3/15/06  CHS
*
* USAGE:
*   Updates PM Issue History
*
* CALLED FROM:
*	ViewpointCS Portal  
*
************************************************************/
(
	@PMCo nvarchar(50),
	@Project nvarchar(50),
	@Issue nvarchar(50),
	@Seq smallint,
	@DocType nvarchar(50),
	@Document nvarchar(50),
	@Rev tinyint,
	@PCOType nvarchar(50),
	@PCO nvarchar(50),
	@PCOItem nvarchar(50),
	@ACO nvarchar(50),
	@ACOItem nvarchar(50),
	@IssueDateTime datetime,
	@Action nvarchar(50),
	@Login nvarchar(50),
	@ActionDate bDate,
	@UniqueAttchID uniqueidentifier,
	
	@Original_PMCo nvarchar(50),
	@Original_Project nvarchar(50),
	@Original_Issue nvarchar(50),
	@Original_Seq smallint,
	@Original_DocType nvarchar(50),
	@Original_Document nvarchar(50),
	@Original_Rev tinyint,
	@Original_PCOType nvarchar(50),
	@Original_PCO nvarchar(50),
	@Original_PCOItem nvarchar(50),
	@Original_ACO nvarchar(50),
	@Original_ACOItem nvarchar(50),
	@Original_IssueDateTime datetime,
	@Original_Action nvarchar(50),
	@Original_Login nvarchar(50),
	@Original_ActionDate bDate,
	@Original_UniqueAttchID uniqueidentifier
	
)
AS
	SET NOCOUNT ON
	
UPDATE PMIH

SET 
--PMCo = @PMCo, 
--Project = @Project, 
--Issue = @Issue,
--Seq = @Seq,
DocType = @DocType,
Document = @Document,
Rev = @Rev,
PCOType = @PCOType,
PCO = @PCO,
PCOItem = @PCOItem,
ACO = @ACO,
ACOItem = @ACOItem,
IssueDateTime = @IssueDateTime,
Action = @Action,
Login = @Login,
ActionDate = @ActionDate,
UniqueAttchID = @UniqueAttchID

WHERE (Issue = @Original_Issue) 
AND (PMCo = @Original_PMCo) 
AND (Project = @Original_Project)
AND (Seq = @Original_Seq OR @Original_Seq IS NULL AND Seq IS NULL)
AND (DocType = @Original_DocType OR @Original_DocType IS NULL AND DocType IS NULL)
AND (Document = @Original_Document OR @Original_Document IS NULL AND Document IS NULL)
AND (Rev = @Original_Rev OR @Original_Rev IS NULL AND Rev IS NULL)
AND (PCOType = @Original_PCOType OR @Original_PCOType IS NULL AND PCOType IS NULL)
AND (PCO = @Original_PCO OR @Original_PCO IS NULL AND PCO IS NULL)
AND (PCOItem = @Original_PCOItem OR @Original_PCOItem IS NULL AND PCOItem IS NULL)
AND (ACO = @Original_ACO OR @Original_ACO IS NULL AND ACO IS NULL)
AND (ACOItem = @Original_ACOItem OR @Original_ACOItem IS NULL AND ACOItem IS NULL)
AND (IssueDateTime = @Original_IssueDateTime OR @Original_IssueDateTime IS NULL AND IssueDateTime IS NULL)
--AND (Action = @Original_Action OR @Original_Action IS NULL AND Action IS NULL)
AND (Login = @Original_Login OR @Original_Login IS NULL AND Login IS NULL)
AND (ActionDate = @Original_ActionDate OR @Original_ActionDate IS NULL AND ActionDate IS NULL)
AND (UniqueAttchID = @Original_UniqueAttchID OR @Original_UniqueAttchID IS NULL AND UniqueAttchID IS NULL)

	RETURN 


GO
GRANT EXECUTE ON  [dbo].[vpspPMIssueHistoryUpdate] TO [VCSPortal]
GO
