SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspPMIssueHistoryDelete]
/************************************************************
* CREATED:     3/15/06  CHS
*
* USAGE:
*   Deletes PM Issue History
*
* CALLED FROM:
*	ViewpointCS Portal  
*
************************************************************/
(
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
	
DELETE 
FROM PMIH

WHERE (Issue = @Original_Issue) 
AND (PMCo = @Original_PMCo) 
AND (Project = @Original_Project)
AND (Seq = @Original_Seq)
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
	


GO
GRANT EXECUTE ON  [dbo].[vpspPMIssueHistoryDelete] TO [VCSPortal]
GO
