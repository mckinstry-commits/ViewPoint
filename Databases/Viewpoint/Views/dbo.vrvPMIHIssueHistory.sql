SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE view [dbo].[vrvPMIHIssueHistory] as  --PMIH PMIssueHistory

WITH PMIHIssueHistory ( PMCo
	,Project
	,Issue
	,Seq
	,DocType
	,DocCategory
	,Document
	,Rev
	,IssueDateTime
	,Action
	,Login
	,ActionDate
	,UniqueAttchID
	,KeyID
	,FromView) 

AS 

(
/*PMIH*/
SELECT PMCo
	,Project
	,Issue
	,Seq
	,DocType
	,''
	,Document
	,Rev
	,IssueDateTime
	,Action
	,Login
	,ActionDate
	,UniqueAttchID
	,KeyID
	,'PMIH'
FROM PMIH

UNION ALL 

/* PMIssueHistory */
SELECT Co		AS PMCo
	,Project	AS Project
	,Issue		AS Issue
	,Null		AS Seq
	,(SELECT DocType 
	  FROM vf_rptPMDocInfoForHistory(PMIssueHistory.RelatedTableName, PMIssueHistory.RelatedKeyID)) 
				AS DocType
	,(SELECT DocCategory 
	  FROM vf_rptPMDocInfoForHistory(PMIssueHistory.RelatedTableName, PMIssueHistory.RelatedKeyID)) 
				AS DocCategory
	,(SELECT Document 
	  FROM vf_rptPMDocInfoForHistory(PMIssueHistory.RelatedTableName, PMIssueHistory.RelatedKeyID)) 
				AS Document
	,NULL		AS Rev
	,(SELECT DocDate 
	  FROM vf_rptPMDocInfoForHistory(PMIssueHistory.RelatedTableName, PMIssueHistory.RelatedKeyID)) 
				AS IssueDateTime
	,ActionType	AS Action
	,Login		AS Login
	,ActionDate	AS ActionDate
	,NULL		AS UniqueAttchID
	,KeyID		AS KeyID
	,'PMIssueHistory' AS FromView
FROM PMIssueHistory
)


SELECT 
	PMCo
	,Project
	,Issue
	,Seq
	,DocType
	,DocCategory
	,Document
	,Rev
	,IssueDateTime
	,Action
	,Login
	,ActionDate
	,UniqueAttchID
	,KeyID
	,FromView
FROM PMIHIssueHistory



GO
GRANT SELECT ON  [dbo].[vrvPMIHIssueHistory] TO [public]
GRANT INSERT ON  [dbo].[vrvPMIHIssueHistory] TO [public]
GRANT DELETE ON  [dbo].[vrvPMIHIssueHistory] TO [public]
GRANT UPDATE ON  [dbo].[vrvPMIHIssueHistory] TO [public]
GO
