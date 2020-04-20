use Viewpoint
go

if exists ( select 1 from INFORMATION_SCHEMA.SCHEMATA where SCHEMA_NAME='mers')
BEGIN
	print 'SCHEMA ''mers'' already exists  -- McKinstry Enterprise Reporting Schema'
END
ELSE
BEGIN
	print 'CREATE SCHEMA ''mers'' -- McKinstry Enterprise Reporting Schema'
	EXEC sp_executesql N'CREATE SCHEMA mers AUTHORIZATION dbo'
END
go

if exists ( select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='PROCEDURE' and ROUTINE_NAME='mspContractDetail')
begin
	print 'DROP PROCEDURE mers.mspContractDetail'
	DROP PROCEDURE mers.mspContractDetail
end
go

print 'CREATE PROCEDURE mers.mspContractDetail'
go

CREATE PROCEDURE mers.mspContractDetail
(
	@Company bCompany = NULL
,	@GLDepartment	VARCHAR(4) = NULL
,	@Contract	bContract = NULL
,	@Job		bJob	= null
)
AS

IF @Company=0
	SELECT @Company=NULL

IF @GLDepartment=0
	SELECT @GLDepartment=NULL


SELECT
	jccm.JCCo
,	jccm.Contract
,	jccm.Description AS ContractDescription
,	jccm.ContractStatus
,	CASE jccm.ContractStatus
		WHEN 0 THEN '0-Pending'
		WHEN 1 THEN '1-Open'
		WHEN 2 THEN '2-Soft Close'
		WHEN 3 THEN '3-Hard Close'
		ELSE CAST(jccm.ContractStatus AS VARCHAR(5)) + '-Unknown'
	END AS ContractStatusDescription
,	jccm.Department AS ContractDepartment
,	jcdm.Description AS ContractDepartmentDescription
,	glpi.Instance AS ContractGLDepartment
,	glpi.Description AS ContractGLDepartmentDescription
,	jccm.udPOC AS ContractPOC
,	jcmp.Name AS ContractPOCName
,	jcmp.udPRCo AS ContractPOCPRCo
,	jcmp.udEmployee AS ContractPOCEmployee
,	jcci.Item AS ContractItem
,	jcci.Description AS ContractItemDescription
,	jcci.udLockYN AS ContractItemLockedYN
,	jcci.udRevType AS ContractItemRevType
,	CASE jcci.udRevType
		WHEN 'C' THEN 'C-Cost to Cost'
		WHEN 'M' THEN 'M-Cost + Markup'
		WHEN 'N' THEN 'N-Non-Revenue'
		WHEN 'A' THEN 'A-Straight Line'
		ELSE CAST(jcci.udRevType AS VARCHAR(5)) + '-Unknown'
	END AS ContractItemRevTypeDescription
,	jcci.udProjDelivery AS ContractItemProjectDelivery
,	prdel.Description  AS ContractItemProjectDeliveryDescription
,	jcci.Department AS ContractItemDepartment
,	jcdm_i.Description AS ContractItemDepartmentDescription
,	glpi_i.Instance AS ContractItemGLDepartment
,	glpi_i.Description AS ContractItemGLDepartmentDescription
,	jcjm.Job
,	jcjm.Description AS JobDescription
,	jcjm.ProjectMgr AS JobPOC
,	jcmp_j.Name AS JobPOCName
,	jcmp_j.udPRCo AS JobPOCPRCo
,	jcmp_j.udEmployee AS JobPOCEmployee
,	jcjm.JobStatus
,	CASE jcjm.JobStatus
		WHEN 0 THEN '0-Pending'
		WHEN 1 THEN '1-Open'
		WHEN 2 THEN '2-Soft Close'
		WHEN 3 THEN '3-Hard Close'
		ELSE CAST(jcjm.JobStatus AS VARCHAR(5)) + '-Unknown'
	END AS JobStatusDescription
,	jcjm.udProjWrkstrm AS JobWorkstream
,	CASE jcjm.udProjWrkstrm
		WHEN 'S' THEN 'S-Sales'
		WHEN 'E1' THEN 'E1-Delivery'
		WHEN 'E2' THEN 'E2-Warranty'
		WHEN 'I' THEN 'S-Internal'
		ELSE CAST(jcjm.udProjWrkstrm AS VARCHAR(5)) + '-Unknown'
	END AS JobWorkstreamDescription
,	jcjp.Phase AS JobPhase
,	jcjp.Description AS JobPhaseDescription
,	jcjp.ActiveYN AS JobPhaseActiveYN
,	jcch.CostType AS JobPhaseCostType
,	jcct.Description AS JobPhaseCostTypeDescription
FROM 
	HQCO hqco (NOLOCK)
JOIN JCCM jccm (NOLOCK) ON
	hqco.HQCo=jccm.JCCo
AND hqco.udTESTCo <> 'Y'
LEFT OUTER JOIN JCCI jcci (NOLOCK) ON
	jccm.JCCo=jcci.JCCo
AND jccm.Contract=jcci.Contract
LEFT OUTER JOIN JCDM jcdm (NOLOCK) ON 
	jccm.JCCo=jcdm.JCCo
AND jccm.Department=jcdm.Department
LEFT OUTER JOIN GLPI glpi (NOLOCK) ON
	jcdm.GLCo=glpi.GLCo
AND glpi.PartNo=3
AND glpi.Instance=SUBSTRING(jcdm.OpenRevAcct,10,4)
LEFT OUTER JOIN JCDM jcdm_i (NOLOCK) ON 
	jcci.JCCo=jcdm_i.JCCo
AND jcci.Department=jcdm_i.Department
LEFT OUTER JOIN GLPI glpi_i (NOLOCK) ON
	jcdm_i.GLCo=glpi_i.GLCo
AND glpi_i.PartNo=3
AND glpi_i.Instance=SUBSTRING(jcdm_i.OpenRevAcct,10,4)
LEFT OUTER JOIN JCJP jcjp (NOLOCK) ON
	jcci.JCCo=jcjp.JCCo
AND jcci.Contract=jcjp.Contract
AND jcci.Item=jcjp.Item
LEFT OUTER JOIN JCJM jcjm (NOLOCK) ON
	jcjp.JCCo=jcjm.JCCo
AND jcjp.Job=jcjm.Job
LEFT OUTER JOIN JCCH jcch (NOLOCK) ON
	jcjp.JCCo=jcch.JCCo
AND jcjp.Job=jcch.Job
AND jcjp.PhaseGroup=jcch.PhaseGroup
AND jcjp.Phase=jcch.Phase 
LEFT OUTER JOIN JCCT jcct (NOLOCK) ON
	jcch.PhaseGroup=jcct.PhaseGroup
AND	jcch.CostType=jcct.CostType
LEFT OUTER JOIN JCMP jcmp (NOLOCK) ON
	jccm.JCCo=jcmp.JCCo
AND jccm.udPOC=jcmp.ProjectMgr
LEFT OUTER JOIN JCMP jcmp_j (NOLOCK) ON
	jcjm.JCCo=jcmp_j.JCCo
AND jcjm.ProjectMgr=jcmp_j.ProjectMgr
LEFT OUTER JOIN udProjDelivery prdel (NOLOCK) ON 
	jcci.udProjDelivery=prdel.Code
WHERE
	( hqco.HQCo=@Company OR @Company IS NULL )
AND ( glpi_i.Instance = @GLDepartment OR glpi.Instance=@GLDepartment OR @GLDepartment IS NULL )
AND ( jccm.Contract = @Contract OR @Contract IS NULL )
AND ( jcjm.Job = @Job OR @Job IS NULL )
go


GRANT EXEC ON mers.mspContractDetail TO PUBLIC
go


EXEC mers.mspContractDetail 0,'0001', null
