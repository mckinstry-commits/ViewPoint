USE Viewpoint
GO


--SELECT * FROM dbo.DDFHShared
----WHERE WhereClause IS NOT NULL
--WHERE Form LIKE 'udVASecApprov%'
--SELECT * FROM dbo.DDFIc
--WHERE Form LIKE  'udVASecApprovals%'
--SELECT * FROM dbo.DDFHShared
--WHERE Form LIKE 'udVAApprover%'

--UPDATE VA Approver
UPDATE dbo.vDDFHc
SET ViewName = 'udVASPckAuthorizors'
WHERE Form = 'udVAApprover'

UPDATE dbo.DDFIc
SET ViewName = 'udVASPckAuthorizors'
WHERE Form = 'udVAApprover'

--SELECT * FROM dbo.DDFIc
--WHERE Form LIKE  'udVASecApprovals%'

--UPDATE VASecApprovalsA
UPDATE dbo.vDDFHc
SET ShowOnMenu = 'N'
	, WhereClause = 'Processed = ''Y'' AND ApprovedYN = ''Y'''
	, ViewName = 'udVASecApprovals'
WHERE Form = 'udVASecApprovalsA'

UPDATE dbo.DDFIc
SET ViewName = 'udVASecApprovals'
WHERE Form =  'udVASecApprovalsA'

--UPDATE VASecApprovalsR
UPDATE dbo.vDDFHc
SET ShowOnMenu = 'N'
	, WhereClause = 'Processed = ''Y''AND RejectedYN = ''Y'''
	, ViewName = 'udVASecApprovals'
WHERE Form = 'udVASecApprovalsR'

UPDATE dbo.DDFIc
SET ViewName = 'udVASecApprovals'
WHERE Form =  'udVASecApprovalsR'


--SELECT * FROM udVASecApprovals
--WHERE Processed = 'Y'
--	AND RejectedYN = 'Y'
--	AND ApprovedYN = 'Y'

--SELECT * FROM dbo.udVASPckAuthMembers