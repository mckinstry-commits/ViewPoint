--	sp_helptext mvwLegalDocHistoryLatestDates
--SELECT* FROM mvwLegalDocHistoryLatestDates
-- EXEC dbo.mckDDJoinClauseByView @View = N'udContractAdminLeg', -- nvarchar(128)
--    @Form = N'udContractAdminLeg', -- nvarchar(128)
--    @IncludeWHERE = NULL, -- bit
--    @IncludeORDERBY = NULL, -- bit
--    @Execute = 0, -- int
--    @MaxRows = 0, -- bigint
--    @ReturnMessage = '' -- varchar(max)
USE Viewpoint
go

IF EXISTS ( SELECT 1 FROM sysobjects WHERE name='' AND type='V')
BEGIN
PRINT 'DROP VIEW mvwJCCMContractAdminLegal'
DROP VIEW mvwJCCMContractAdminLegal
END
go

PRINT 'CREATE VIEW mvwJCCMContractAdminLegal'
go


CREATE VIEW mvwJCCMContractAdminLegal
as
SELECT 
	jccm.JCCo
,	jccm.Contract
,	jccm.Description AS ContractDesc
,	jcmp.Name AS ContractPOC
,	udca.Project
,	jcjm.Description AS JobDesc
,	jcmp2.Name AS JobPOC
,	udca.[DocType] 
,	udca.[McKSigner]
,	CASE
		WHEN udca.[McKSigner] IS NOT NULL AND udas.Description IS NULL THEN 'Invalid Signer'
		WHEN udca.[McKSigner] IS NULL AND udas.Description IS NULL THEN null
		ELSE udas.Description 
	END AS McKSignerDesc
--,	udca.[McKSignerDesc]
,	udca.[RefNum]
,	udca.[Seq] 
,	udca.[Status]
--,	CAST(udca.[StatusDate] AS DATETIME) AS StatusDate -- [dbo].[bDesc] NULL,
,	(SELECT MAX(Date) from udLegalDocHistory WHERE Co=udca.Co AND Contract=udca.Contract AND Project=udca.Project AND Seq=udca.Seq AND IsStatusUpdate='Y') AS StatusDate
,	CASE
		WHEN udca.[Status] IS NOT NULL AND udls.Description IS NULL THEN 'Invalid Status'
		WHEN udca.[Status] IS NULL AND udls.Description IS NULL THEN null
		ELSE udls.Description 
	END AS StatusDesc
--,	udca.[StatusDesc]
,	udls.DocType AS StatusDocType
,	udls.Sequence AS StatusSeq
,	udca.[Value] 
,	udca.[Notes]
--,	udca.[ProjectName]
,	udca.[AssignedTo]
,	preh.FirstName AS AssingedToFirstName
,	preh.LastName AS AssingedToLastName
--,	udca.[AssignedToName]
,	udca.[Comments] 
--,	udca.[PRCo] 
,	udca.[DocFeedback]
,	udca.[LegalFeedback] 
--,	udir.DocType	AS IssueDocType
--,	udir.Issue	 AS Issue
--,	udir.LastCommentDate AS IssueLastCommectDate	
--,	udir.UniqueAttchID	AS IssueUniqueAttchID
,	udca.[UniqueAttchID] 
,	udca.[KeyID] 
--,	udir.KeyID	AS IssueKeyID
--,	udir.IssueGuide AS IssueGuide
FROM
	JCCM jccm JOIN
	dbo.udContractAdminLeg udca ON
		jccm.JCCo=udca.Co
	AND jccm.Contract=udca.Contract LEFT OUTER JOIN
	JCMP jcmp ON
		jccm.JCCo=jcmp.JCCo
	AND jccm.udPOC=jcmp.ProjectMgr LEFT OUTER JOIN
	JCJM jcjm ON
		udca.Co=jcjm.JCCo
	AND udca.Project=jcjm.Job LEFT OUTER JOIN
	JCMP jcmp2 ON
		jcjm.JCCo=jcmp2.JCCo
	AND jcjm.ProjectMgr=jcmp2.ProjectMgr LEFT OUTER JOIN
	PREHFullName preh ON
		udca.PRCo=preh.PRCo
	AND	udca.AssignedTo=preh.Employee LEFT OUTER JOIN
	dbo.udLegalStatus udls ON
		udca.Status=udls.Status LEFT OUTER JOIN
	dbo.udAuthSigners udas ON
		udca.McKSigner=udas.Code /* LEFT OUTER JOIN
	udIssueReview udir ON
		udca.Co=udir.Co
	AND udca.Contract=udir.Contract
	AND udca.Project=udir.Project
	AND udca.Seq=udir.Seq */
go

-- SQL to get Associated Document Issue Records
--SELECT distinct
--	t2.* 
--FROM 	
--	mvwJCCMContractAdminLegal t1 JOIN
--	udIssueReview t2 ON
--		t1.JCCo=t2.Co
--	AND t1.Contract=t2.Contract
--	AND t1.Project=t2.Project
--	AND t1.Seq=t2.Seq

-- SQL to get Associated Document History Records
--SELECT distinct
--	t2.* 
--FROM 	
--	mvwJCCMContractAdminLegal t1 JOIN
--	udLegalDocHistory t2 ON
--		t1.JCCo=t2.Co
--	AND t1.Contract=t2.Contract
--	AND t1.Project=t2.Project
--	AND t1.Seq=t2.Seq




--SELECT * FROM udContractAdminLeg
--SELECT * FROM dbo.udIssueReview

--SELECT * FROM dbo.udLegalDocHistory

