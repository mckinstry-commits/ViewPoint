USE Viewpoint
go


--SELECT JCCo, Contract, COUNT(*) from JCJM where JCCo<100 GROUP BY JCCo, Contract HAVING COUNT(*) >1

DECLARE @Co bCompany
DECLARE @Contract bContract
DECLARE @Month bMonth

SELECT
	@Month='10/1/2014' 
,	@Co=1
--,	@Contract=' 87939-'
--,	@Contract=' 87938-'
--,	@Contract='100101-'

SELECT
	@Month AS FinanicalMonth
,	jccm.JCCo
,	jccm.Contract
,	jccm.Description AS ContractItemDescription
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
,	wipcost.Job
,	wipcost.POC AS JobPOC
,	wipcost.POCName AS JobPOCName
,	wipcost.OriginalCost
,	wipcost.ProjectedCost
,	wipcost.CurrentCost
,	wipcost.CommittedCost
,	wiprev.OrigContractAmt
,	wiprev.ProjContractAmt
,	wiprev.CurrContractAmt
,	wiprev.CurrentBilledAmount
FROM
	HQCO hqco LEFT OUTER JOIN 
	JCCI jcci ON 
		hqco.HQCo=jcci.JCCo
	AND hqco.udTESTCo <> 'Y' LEFT OUTER JOIN
	JCCM jccm ON
		jcci.JCCo=jccm.JCCo
	AND jcci.Contract=jccm.Contract LEFT OUTER JOIN
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
	mckWipCostByJobData wipcost ON
		jcci.JCCo=wipcost.JCCo
	AND LTRIM(RTRIM(jcci.Contract))=wipcost.Contract
    AND glpi_ci.Instance=wipcost.GLDepartment
	AND wipcost.ThroughMonth=@Month  LEFT OUTER JOIN
	mckWipRevenueData wiprev ON
		jcci.JCCo=wiprev.JCCo
	AND LTRIM(RTRIM(jcci.Contract))=wiprev.Contract
	AND glpi_ci.Instance=wiprev.GLDepartment
	AND wiprev.ThroughMonth=@Month
	--JCJP jcjp ON -- Change to use WIPCostByJob
	--	jcci.JCCo=jcjp.JCCo
	--AND jcci.Item=jcjp.Item
	--AND jcci.Contract=jcjp.Contract LEFT OUTER JOIN
	--JCJM jcjm ON
	--	jcjp.JCCo=jcjm.JCCo
	--AND jcjp.Job=jcjm.Job LEFT OUTER JOIN
	--JCMP jcmp_jobpoc ON
	--	jcjm.JCCo=jcmp_jobpoc.JCCo
	--AND jcjm.ProjectMgr=jcmp_jobpoc.ProjectMgr 
WHERE
	( jccm.JCCo=@Co OR @Co IS NULL)
and	( jccm.Contract=@Contract OR @Contract IS NULL)
ORDER BY
	jccm.JCCo
,	glpi.Instance
,	jccm.Contract
,	glpi_ci.Instance
,	jcci.Item


--SELECT * FROM dbo.mckWipCostByJobData
--sp_helptext 	mvwWIPJoin


--sp_helptext mckspAddUserAccount

