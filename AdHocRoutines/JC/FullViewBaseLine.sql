USE Viewpoint
go


--SELECT JCCo, Contract, Item, COUNT(*) from JCCI GROUP BY JCCo, Contract, Item HAVING COUNT(*) >1

IF EXISTS ( SELECT 1 FROM sysobjects WHERE type='P' and name='mspLWOFullJCSummary')
BEGIN
	PRINT 'DROP PROCEDURE mspLWOFullJCSummary'
	DROP PROCEDURE mspLWOFullJCSummary
END
go


create PROCEDURE mspLWOFullJCSummary
(
	@Co bCompany = null
,	@Contract bContract = null
,	@GLDept VARCHAR(100) = null
,	@Month bMonth = null
)
as

SELECT
	@Month AS ThroughMonth
,	jccm.JCCo
,	jccm.Contract
,	jccm.Description AS ContractDescription
--,	jccm.Department AS ContractJCDepartment
,	jccm.udPOC AS POC
,	jcmp_poc.Name AS POCName
,	jccm.udSalesPerson AS SalesPerson
,	jcmp_sp.Name AS SalesPersonName
,	glpi.Instance AS ContractGLDepartment
,	glpi.Description AS ContractGLDepartmentName
,	jcci.Item AS ContractItem
,	jcci.Description AS ContractItemDescription
,	jcci.udRevType AS Revenuetype
,	glpi_ci.Instance AS ContractItemGLDepartment
,	glpi_ci.Description AS ContractItemGLDepartmentName
,	jcjm.Job
,	jcjm.Description AS JobDescription
,	jcjm.ProjectMgr AS JobPOC
,	jcmp_jobpoc.Name AS JobPOCName
,	jcjm.JobStatus
--,	jcjp.PhaseGroup
--,	jcjp.Phase
--,	jcjp.ActiveYN AS IsPhaseActive
--,	jcch.CostType
--,	jcct.Abbreviation AS CostTypeCode
--,	jcct.Description AS CostTypeDescription
--,	jccp.Mth
,	SUM(jccp.OrigEstCost) AS OriginalEstCost
,	SUM(jccp.CurrEstCost) AS CurrentEstCost
,	SUM(jccp.ProjCost) AS ProjectedCost
,	SUM(jccp.ActualCost) AS ActualCost
,	(
	SELECT
		sum(jcip.OrigContractAmt) 

	from 
		JCIP jcip
	WHERE 
		jcip.JCCo=jccm.JCCo
	AND jcip.Contract=jccm.Contract
	AND jcip.Item=jcci.Item
	AND jcip.Mth <= @Month
	) AS OriginalContractAmount
,	(
	SELECT

		sum(jcip.ContractAmt)
	from 
		JCIP jcip
	WHERE 
		jcip.JCCo=jccm.JCCo
	AND jcip.Contract=jccm.Contract
	AND jcip.Item=jcci.Item
	AND jcip.Mth <= @Month
	) AS ContractAmount
,	(
	SELECT
		sum(jcip.ProjDollars) AS ProjectedRevenue
	from 
		JCIP jcip
	WHERE 
		jcip.JCCo=jccm.JCCo
	AND jcip.Contract=jccm.Contract
	AND jcip.Item=jcci.Item
	AND jcip.Mth <= @Month
	) AS ProjectedRevenue
,	(
	SELECT
		sum(jcip.BilledAmt) 
	from 
		JCIP jcip
	WHERE 
		jcip.JCCo=jccm.JCCo
	AND jcip.Contract=jccm.Contract
	AND jcip.Item=jcci.Item
	AND jcip.Mth <= @Month
	) AS BilledAmount
--,	AVG(jcip.OrigContractAmt) AS OriginalContractAmount -- Change to subselect (prorated) to include Revenue Values from JCIP
--,	AVG(jcip.ContractAmt) AS ContractAmount
--,	AVG(jcip.ProjDollars) AS ProjectedRevenue
--,	AVG(jcip.BilledAmt) AS BilledAmount
FROM
	HQCO hqco JOIN 
	JCCM jccm ON
		hqco.HQCo=jccm.JCCo
	-- Uncomment below section for Production deployment.
	 AND hqco.udTESTCo <> 'Y' LEFT OUTER JOIN
	JCCI jcci ON 
		jccm.JCCo=jcci.JCCo
	AND jccm.Contract=jcci.Contract LEFT OUTER JOIN
	JCDM jcdm ON
		jccm.JCCo=jcdm.JCCo
	AND jccm.Department=jcdm.Department LEFT OUTER JOIN
	GLPI glpi ON
		jcdm.GLCo=glpi.GLCo
	AND glpi.PartNo=3
	AND SUBSTRING(jcdm.OpenRevAcct,10,4)=glpi.Instance LEFT OUTER JOIN
	JCDM jcdm_ci ON
		jcci.JCCo=jcdm_ci.JCCo
	AND jcci.Department=jcdm_ci.Department LEFT OUTER JOIN
	GLPI glpi_ci ON
		jcdm_ci.GLCo=glpi_ci.GLCo
	AND glpi_ci.PartNo=3
	AND SUBSTRING(jcdm_ci.OpenRevAcct,10,4)=glpi_ci.Instance LEFT OUTER JOIN
	JCMP jcmp_poc ON
		jccm.JCCo=jcmp_poc.JCCo
	AND jccm.udPOC=jcmp_poc.ProjectMgr LEFT OUTER JOIN
	JCMP jcmp_sp ON
		jccm.JCCo=jcmp_sp.JCCo
	AND jccm.udSalesPerson=jcmp_sp.ProjectMgr LEFT OUTER JOIN
	JCJP jcjp ON
		jcci.JCCo=jcjp.JCCo
	AND jcci.Item=jcjp.Item
	AND jcci.Contract=jcjp.Contract LEFT OUTER JOIN
	JCCH jcch ON
		jcjp.JCCo=jcch.JCCo
	AND jcjp.Job=jcch.Job
	AND jcjp.PhaseGroup=jcch.PhaseGroup
	AND jcjp.Phase=jcch.Phase LEFT OUTER JOIN
	JCCT jcct ON
		jcch.CostType=jcct.CostType
	AND jcch.PhaseGroup=jcct.PhaseGroup LEFT OUTER JOIN 
	JCJM jcjm ON
		jcjp.JCCo=jcjm.JCCo
	AND jcjp.Job=jcjm.Job 
	AND jcjm.Contract=jcci.Contract LEFT OUTER JOIN
	JCMP jcmp_jobpoc ON
		jcjm.JCCo=jcmp_jobpoc.JCCo
	AND jcjm.ProjectMgr=jcmp_jobpoc.ProjectMgr LEFT OUTER JOIN
	JCCP jccp ON
		jccp.JCCo=jcch.JCCo
	AND jccp.Job=jcch.Job
	AND jccp.PhaseGroup=jcch.PhaseGroup
	AND jccp.Phase=jcch.Phase
	AND jccp.CostType=jcch.CostType /* LEFT OUTER JOIN
	JCIP jcip ON
		jcci.JCCo=jcip.JCCo
	AND jcci.Contract=jcip.Contract
	AND jcci.Item=jcip.Item
	AND jcip.Mth=jccp.Mth */
WHERE
	(jccm.JCCo=@Co OR @Co IS NULL)
and	(jccm.Contract=@Contract OR @Contract IS NULL)
AND (glpi.Instance=@GLDept OR @GLDept IS NULL)
AND jccp.Mth <= @Month
--AND jcip.Mth <= @Month
GROUP BY
	jccm.JCCo
,	jccm.Contract
,	jccm.Description --AS ContractItemDescription
--,	jccm.Department --AS ContractJCDepartment
,	jccm.udPOC --AS POC
,	jcmp_poc.Name --AS POCName
,	jccm.udSalesPerson --AS SalesPerson
,	jcmp_sp.Name --AS SalesPersonName
,	glpi.Instance --AS ContractGLDepartment
,	glpi.Description --AS ContractGLDepartmentName
,	jcci.Item --AS ContractItem
,	jcci.Description --AS ContractItemDescription
,	jcci.udRevType --AS Revenuetype
,	glpi_ci.Instance --AS ContractItemGLDepartment
,	glpi_ci.Description --AS ContractItemGLDepartmentName
,	jcjm.Job
,	jcjm.Description --AS JobDescription
,	jcjm.ProjectMgr --AS JobPOC
,	jcmp_jobpoc.Name --AS JobPOCName
,	jcjm.JobStatus
--,	jcjp.PhaseGroup
--,	jcjp.Phase
--,	jcjp.ActiveYN --AS IsPhaseActive
--,	jcch.CostType
--,	jcct.Abbreviation --AS CostTypeCode
--,	jcct.Description --AS CostTypeDescription
--,	jccp.Mth
--,	jcip.OrigContractAmt --AS OriginalContractAmount -- PRORATE BASED ON PERCENT OF COST
--,	jcip.ContractAmt --AS ContractAmount
--,	jcip.ProjDollars --AS ProjectedRevenue
--,	jcip.BilledAmt --AS BilledAmount

GO


EXEC mspLWOFullJCSummary
	@Co = null
,	@Contract = null
--,	@Contract = ' 10088-'
,	@GLDept = null
,	@Month = '11/1/2014'


--JCCI Subselect
--SELECT
--	sum(jcip.OrigContractAmt) AS OriginalContractAmount -- Change to subselect (prorated) to include Revenue Values from JCIP
--,	sum(jcip.ContractAmt) AS ContractAmount
--,	sum(jcip.ProjDollars) AS ProjectedRevenue
--,	sum(jcip.BilledAmt) AS BilledAmount
--from 
--	JCIP jcip
--WHERE 
--	jcip.JCCo=1
--AND jcip.Contract=' 10088-'
--AND jcip.Item=1