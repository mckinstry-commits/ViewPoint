

/*-- ADD REVIEWERS TO JC Job Reviewers 
 --Run this before RLB scripts
*/
--INSERT INTO dbo.JCJR
--        ( JCCo ,
--          Job ,
--          Seq ,
--          Reviewer ,
--          ReviewerType
--        )
--SELECT JCJM.JCCo,JCJM.Job, 1, SUBSTRING(JCJM.Job,5,2),1 
--FROM dbo.JCJM
--	LEFT JOIN dbo.JCJR ON dbo.JCJR.JCCo = dbo.JCJM.JCCo AND dbo.JCJR.Job = dbo.JCJM.Job 
--WHERE JCJM.Job > '100099' AND RIGHT(JCJM.Job,3)='002'
--	AND JCJM.Job NOT LIKE '%[A-Za-z]%' AND JCJM.Job < '100171'
--	AND JCJM.JCCo = 222 AND (JCJR.Reviewer <> SUBSTRING(JCJM.Job,5,2) OR JCJR.Reviewer IS NULL)


--IF NECESSARY, SYNC THE ATTACHMENTS FROM DEV TO PROD
/*
INSERT INTO dbo.HQAT
        ( HQCo ,
          FormName ,
          KeyField ,
          Description ,
          AddedBy ,
          AddDate ,
          DocName ,
          AttachmentID ,
          TableName ,
          UniqueAttchID ,
          OrigFileName ,
          DocAttchYN ,
          CurrentState ,
          AttachmentTypeID ,
          IsEmail
        )
SELECT  dev.HQCo ,
        dev.FormName ,
        dev.KeyField ,
        dev.Description ,
        dev.AddedBy ,
        dev.AddDate ,
        dev.DocName ,
        dev.AttachmentID ,
        dev.TableName ,
        dev.UniqueAttchID ,
        dev.OrigFileName ,
        dev.DocAttchYN ,
        dev.CurrentState ,
        dev.AttachmentTypeID ,
        dev.IsEmail
FROM [MCKTESTSQL04\VIEWPOINT].Viewpoint.dbo.HQAT dev
	LEFT JOIN dbo.HQAT prod ON dev.AttachmentID = prod.AttachmentID
WHERE prod.AttachmentID IS NULL AND dev.FormName = 'PMSLHeader'
*/


/*--ADD DOCUMENT ROUTES FOR THE TRAINING USERS.
	--Run this after RLB scripts.
*/
INSERT INTO dbo.HQDR
        ( UserName ,
          AttachmentID ,
          DateAdded ,
          AddedBy ,
          Status ,
          StatusDate ,
          Instructions 
        )
SELECT 
	'MCKINSTRY\VPPMTRAIN'+SUBSTRING(JCJob,5,2) AS UserName
	,a.AttachmentID
	,GETDATE() AS DateAdded
	,a.AddedBy
	, s.Status
	,GETDATE() AS StatusDate
	,'Instructions' AS Instructions
	--, i.JCCo
	, i.JCJob
	, i.SLSubcontract
	--, a.FormName
FROM dbo.HQAT a
	LEFT JOIN dbo.HQDR rte ON a.AttachmentID = rte.AttachmentID
	LEFT JOIN dbo.HQAI i ON i.AttachmentID = a.AttachmentID
	CROSS JOIN (SELECT TOP 1 YNBeginStatus, Status
		FROM dbo.HQDS
		WHERE YNBeginStatus='Y'
		ORDER BY Seq) s 
WHERE a.FormName = 'PMSLHeader'
	AND JCJob BETWEEN '100101-002' AND '100170-002' AND RIGHT(JCJob,3) ='002'
	AND RIGHT(RTRIM(SLSubcontract),4) ='2001'