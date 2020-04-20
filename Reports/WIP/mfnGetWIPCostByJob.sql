--DROP FUNCTION mfnGetWIPCostByJob
IF EXISTS ( SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE='FUNCTION' AND ROUTINE_SCHEMA='dbo' AND ROUTINE_NAME='mfnGetWIPCostByJob')
BEGIN
	PRINT 'DROP FUNCTION mfnGetWIPCostByJob'
	DROP FUNCTION dbo.mfnGetWIPCostByJob
END
go

-- =================================================================================================================================
-- Change History
-- Date       Author            Description
-- ---------- ----------------- ----------------------------------------------------------------------------------------------------
-- 09/15/2014 Bill Orebaugh		Authored
-- 09/29/2014 Amit Mody			Added ProcessedOn to return table schema and updated join
-- 02/10/2015 Amit Mody			Updated for supporting multiple ExcludeRevenueType (so that non-rev contracts can be processed on locked months)
-- ==================================================================================================================================

PRINT 'CREATE FUNCTION mfnGetWIPCostByJob'
go
create FUNCTION dbo.mfnGetWIPCostByJob
(
	@inCompany				tinyint
,	@inMonth				smalldatetime
,	@inContract				VARCHAR(10) --bContract
,	@inIsLocked				CHAR(1) --bYN
,	@inExcludeWorkStream	varchar(255)
,	@inExcludeRevenueType	varchar(255)
)
RETURNS @retTable TABLE
(
	ThroughMonth			SMALLDATETIME	null
,	JCCo					TINYINT			null
,	Contract				VARCHAR(10)		NULL
,	ContractDesc			VARCHAR(60)  	NULL
,	Job						VARCHAR(10)		NULL
,	IsLocked				CHAR(1)			NULL	--bYN		
,	RevenueType				varchar(10)		null
,	RevenueTypeName			VARCHAR(60)		null
,	ContractStatus			varchar(10)		null
,	ContractStatusDesc		VARCHAR(60)		null
,	GLDepartment			VARCHAR(4)		null
,	GLDepartmentName		VARCHAR(60)		null
,	POC						INT				NULL	--bEmployee		
,	POCName					VARCHAR(60)		null
,	OriginalCost			decimal(18,2)	null
,	CurrentCost				decimal(18,2)	null
,	CurrentEstCost			decimal(18,2)	null
,	ProjectedCost			decimal(18,2)	null
,	CommittedCost			decimal(18,2)	null
,	ProcessedOn				DateTime		null
)
AS
BEGIN

DECLARE @firstOfMonth smalldatetime
SELECT @firstOfMonth = dbo.mfnFirstOfMonth(@inMonth)

INSERT @retTable
SELECT 
	@firstOfMonth AS ThroughMonth
,	jcci.JCCo
,	ltrim(rtrim(jcci.Contract)) as Contract
,	jccm.Description AS ContractDescription
,	jcjp.Job
,	jcci.udLockYN as IsLocked
,	COALESCE(jcci.udRevType,'C') as RevenueType
,	vddcic.DisplayValue AS RevenueTypeName
,	jccm.ContractStatus 
,	CASE jccm.ContractStatus 
		WHEN 0 THEN CAST(jccm.ContractStatus AS VARCHAR(4)) + '-Pending'
		ELSE vddci.DisplayValue 
	END AS ContractStatusDesc	
,	glpi.Instance as GLDepartment
,	glpi.Description as GLDepartmentName
,	jccm.udPOC as POC
,	jcmp.Name as POCName
,	COALESCE(sum(jccp.OrigEstCost),0) as OriginalCost
,	COALESCE(sum(jccp.CurrEstCost),0) as CurrentEstCost
,	COALESCE(sum(jccp.ActualCost),0) as CurrentCost
,	COALESCE(sum(jccp.ProjCost),0) as ProjectedCost
,	COALESCE(sum(jccp.RemainCmtdCost),0) as CommittedCost
,	GETDATE() as ProcessedOn
FROM
	dbo.JCCI jcci JOIN	
	dbo.JCCM jccm ON
		jcci.JCCo=jccm.JCCo
	AND jcci.Contract=jccm.Contract
	AND (jcci.JCCo=@inCompany OR @inCompany IS NULL)
	AND ( ltrim(rtrim(jcci.Contract))=@inContract or @inContract is null ) LEFT OUTER JOIN
	dbo.JCDM jcdm ON
		jcci.JCCo=jcdm.JCCo
	AND jcci.Department=jcdm.Department JOIN
	dbo.GLPI glpi ON
		jcdm.GLCo=glpi.GLCo
	AND glpi.PartNo=3
	AND glpi.Instance=SUBSTRING(jcdm.OpenRevAcct,10,4) LEFT JOIN
	dbo.JCMP jcmp ON
		jccm.JCCo=jcmp.JCCo
	AND jccm.udPOC=jcmp.ProjectMgr left outer JOIN
	dbo.vDDCIc vddcic ON
		vddcic.ComboType='RevenueType'
	AND vddcic.DatabaseValue=COALESCE(jcci.udRevType,'C') LEFT OUTER JOIN
	dbo.vDDCI vddci ON
		vddci.ComboType='JCContractStatus'
	AND vddci.DatabaseValue=jccm.ContractStatus	JOIN
	dbo.JCJP jcjp on
		jcci.JCCo=jcjp.JCCo
	and jcci.Contract=jcjp.Contract
	and jcci.Item=jcjp.Item JOIN
	dbo.JCJM jcjm ON
		jcjp.JCCo=jcjm.JCCo
	AND jcjp.Job=jcjm.Job 
	AND (jcjm.udProjWrkstrm NOT IN (@inExcludeWorkStream) OR @inExcludeWorkStream IS null) LEFT OUTER JOIN
	dbo.JCCP jccp ON
		jcjp.JCCo=jccp.JCCo
	and jcjp.Job=jccp.Job
	and jcjp.Phase=jccp.Phase
	and jcjp.PhaseGroup=jccp.PhaseGroup		
	and jccp.Mth <= @firstOfMonth
WHERE
	COALESCE(jcci.udRevType,'C') NOT IN (SELECT * from dbo.mfnSplitCsvParam(@inExcludeRevenueType))
group by
	jcci.JCCo
,	jcci.Contract
,	jccm.Description
,	jcjp.Job
,	jcci.udLockYN 
,	jcci.udRevType 
,	vddcic.DisplayValue
,	jccm.ContractStatus 
,	glpi.Instance
,	glpi.Description 
,	jccm.udPOC
,	jcmp.Name 
,	vddci.DisplayValue
,	vddci.DatabaseValue

RETURN

END
GO

-- Test Script
-- SELECT distinct RevenueType from dbo.mfnGetWIPCostByJob(1,'12/1/2014',null,null,null,'M,A,C')