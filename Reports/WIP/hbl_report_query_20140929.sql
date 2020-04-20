USE Viewpoint
go

IF EXISTS ( SELECT * FROM sysobjects WHERE name='mvwHardBacklogReport' AND type ='V')
BEGIN
PRINT 'DROP VIEW mvwHardBacklogReport'
DROP VIEW mvwHardBacklogReport
END
go

CREATE view mvwHardBacklogReport
as
SELECT 
	jccp.Mth 
,	jcjm.JCCo
,	jcjm.Job
,	jcjm.Description AS JobDescription
,	jcjp.PhaseGroup
,	jcjp.Phase
,	jcjp.Description AS PhaseDescription
,	jcch.CostType
,	jcct.Abbreviation AS CostTypeAbbreviation
,	jcct.Description AS CostTypeDescription
,	jcjm.ProjectMgr AS ProjectManagerId
,	jcmp.Name AS ProjectManager
,	jccm.Contract
,	jccm.Description AS ContractDescription
,	glpi.Instance AS GLDepartment
,	glpi.Description AS GLDepartmentName
,	jcpr.DetMth
,	SUM(jcpr.Amount) AS ProjCost
,	SUM(jcpr.Hours) AS ProjHours
,	hqco.udTESTCo AS IsTestCompany
FROM 
	HQCO hqco JOIN
	JCJM jcjm ON 
		jcjm.JCCo=jcjm.JCCo
	AND jcjm.Contract=jcjm.Contract JOIN 
	JCJP jcjp ON
		jcjm.JCCo=jcjp.JCCo 
	AND jcjm.Job=jcjp.Job JOIN	
	JCCH jcch ON
		jcch.JCCo=jcjp.JCCo
	AND jcch.Job=jcjp.Job
	AND jcch.PhaseGroup=jcjp.PhaseGroup
	AND jcch.Phase=jcjp.Phase JOIN
	JCCP jccp ON
		jcch.JCCo=jccp.JCCo 
	AND jcch.Job=jccp.Job 
	AND jcch.PhaseGroup=jccp.PhaseGroup 
	AND jcch.Phase=jccp.Phase 
	AND jcch.CostType=jccp.CostType JOIN
	JCPR jcpr ON
		jcch.JCCo=jcpr.JCCo
	AND jcch.Job=jcpr.Job
	AND jcch.PhaseGroup=jcpr.PhaseGroup
	AND jcch.Phase=jcpr.Phase
	AND jcch.CostType=jcpr.CostType 
	AND jccp.Mth=jcpr.Mth JOIN
	JCCM jccm ON 
		jcjm.JCCo=jccm.JCCo
	AND jcjm.Contract=jccm.Contract JOIN
	JCMP jcmp ON
		jcjm.JCCo=jcmp.JCCo
	AND jcjm.ProjectMgr=jcmp.ProjectMgr JOIN
	JCDM jcdm ON
		jccm.JCCo=jcdm.JCCo
	AND	jccm.Department=jcdm.Department JOIN
	GLPI glpi ON
		jcdm.GLCo=glpi.GLCo
	AND glpi.PartNo=3
	AND glpi.Instance=SUBSTRING(jcdm.OpenRevAcct,10,4) JOIN
	JCCT jcct ON
		jcch.PhaseGroup=jcct.PhaseGroup 
	AND jcch.CostType=jcct.CostType
WHERE
	jccp.Mth=CAST(MONTH(GETDATE()) AS VARCHAR(2)) + '/1/' + CAST(YEAR(GETDATE()) AS VARCHAR(10))
GROUP BY
	jccp.Mth 
,	jcjm.JCCo
,	jcjm.Job
,	jcjm.Description
,	jcjp.PhaseGroup
,	jcjp.Phase
,	jcjp.Description
,	jcch.CostType
,	jcct.Abbreviation
,	jcct.Description
,	jcjm.ProjectMgr 
,	jcmp.Name 
,	jccm.Contract
,	jccm.Description 
,	glpi.Instance 
,	glpi.Description 
,	jcpr.DetMth
,	hqco.udTESTCo
GO