SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[mfnGetWIPCost]
(
	@inCompany				tinyint
,	@inMonth				smalldatetime
,	@inContract				bContract
,	@inIsLocked				bYN
,	@inExcludeWorkStream	varchar(255)
,	@inExcludeRevenueType   varchar(255)
)
RETURNS @retTable TABLE
(
	JCCo					bCompany		null
,	Contract				bContract		NULL
,	ContractDesc			VARCHAR(60)		null
,	IsLocked				bYN				null
,	RevenueType				varchar(10)		null
,	RevenueTypeName			VARCHAR(60)			null
,	ContractStatus			varchar(10)		null
,	ContractStatusDesc		VARCHAR(60)			null
,	GLDepartment			VARCHAR(4)		null
,	GLDepartmentName		VARCHAR(60)			null
,	POC						bEmployee		null
,	POCName					VARCHAR(60)			null
,	OriginalCost			decimal(18,2)	null
,	CurrentCost				decimal(18,2)	null	
,	ProjectedCost			decimal(18,2)	null	
,	CostIsOverride			bYN				null
,	CostOverridePercent		decimal(12,8)	NULL
,	CostOverrideAmount		decimal(18,2)	null
,	OROriginalCost			decimal(18,2)	null		
,	ORCurrentCost			decimal(18,2)	null		
,	ORProjectedCost			decimal(18,2)	null		
,	ExcludeWorkstreams		VARCHAR(255)	NULL
,	ThroughMonth			SMALLDATETIME	null
,	Note					VARCHAR(2000)	null	
,	mckEstCostAtCompletion	decimal(18,2)	NULL
,	mckActualCost			decimal(18,2)	NULL
,	mckEstCostToComplete	decimal(18,2)	NULL
,	mckRevenuePercentComplete	DECIMAL(8,3)	null
)

AS

BEGIN

INSERT @retTable
select 
	jcci.JCCo
,	ltrim(rtrim(jcci.Contract)) as CONTRACT
,	jccm.Description AS ContractDescription
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
,	sum(jccp.OrigEstCost) as OriginalCost
,	sum(jccp.CurrEstCost) as CurrentCost
,	sum(jccp.ProjCost) as ProjectedCost
,	case coalesce(SUM(jcop.ProjCost),0)
		when 0 then 'N'
		else 'Y' 
	end as CostIsOverride
	
	
	/* TODO : 
		Calc Percent on ProjectedCost
		Adjust to take : (Cost Override - Sum(ProjCost)) * Cost Override Percentage + Contract Item ProjCost to get prorated Override Amount.	
	*/
	
,	dbo.mfnGetCostOverridePercent(jcci.JCCo,@inMonth,jcci.Contract, sum(jccp.ProjCost), @inExcludeWorkStream,@inExcludeRevenueType ) as CostOverridePercent
,	dbo.mfnGetCostOverrideAmount(jcci.JCCo,@inMonth,jcci.Contract, COALESCE(sum(jcop.ProjCost),0), sum(jccp.ProjCost), @inExcludeWorkStream,@inExcludeRevenueType ) as CostOverrideAmount
,	sum(jccp.OrigEstCost) as OROriginalCost
,	sum(jccp.CurrEstCost) as ORCurrentCost	
,	case coalesce(SUM(jcop.ProjCost),0)
		when 0 then sum(jccp.ProjCost)
		else ( sum(jcop.ProjCost) * dbo.mfnGetCostOverridePercent(jcci.JCCo,@inMonth,jcci.Contract, sum(jccp.ProjCost), @inExcludeWorkStream,@inExcludeRevenueType ) )
	end as ORProjectedCost
,	@inExcludeWorkStream AS ExcludeWorkstreams
,	dbo.mfnFirstOfMonth(@inMonth)
,	'Data through ' + CONVERT(VARCHAR(10),dbo.mfnFirstOfMonth(@inMonth),101) AS Note
,	case coalesce(SUM(jcop.ProjCost),0)
		when 0 then sum(jccp.ProjCost)
		else dbo.mfnGetCostOverrideAmount(jcci.JCCo,@inMonth,jcci.Contract, COALESCE(sum(jcop.ProjCost),0), sum(jccp.ProjCost), @inExcludeWorkStream,@inExcludeRevenueType )
	end as mckEstCostAtCompletion
,	sum(jccp.CurrEstCost) AS mckActualCost
,	(case coalesce(SUM(jcop.ProjCost),0)
		when 0 then sum(jccp.ProjCost)
		else dbo.mfnGetCostOverrideAmount(jcci.JCCo,@inMonth,jcci.Contract, COALESCE(sum(jcop.ProjCost),0), sum(jccp.ProjCost), @inExcludeWorkStream,@inExcludeRevenueType )
	END - sum(jccp.CurrEstCost)) AS mckEstCostToComplete
--,	dbo.mfnGetPercentComplete
--	(
--		jcci.JCCo				--tinyint
--	,	@inMonth				--smalldatetime
--	,	jcci.Contract			--	bContract	
--	,	@inIsLocked				--bYN
--	,	@inExcludeWorkStream	--varchar(255)
--	,	@inExcludeRevenueType   --varchar(255)
--	,	sum(jccp.CurrEstCost)		--decimal(18,2)	
--	,	coalesce(SUM(jccp.ProjCost),0)			--decimal(18,2)	
--	,	coalesce(SUM(jcop.ProjCost),0)			--decimal(18,2)	
--	) as mckRevenuePercentComplete
,	CASE 
		WHEN coalesce(SUM(jcop.ProjCost),0)=0 AND coalesce(SUM(jccp.ProjCost),0)=0 THEN 0.00
		WHEN coalesce(SUM(jcop.ProjCost),0)=0 AND coalesce(SUM(jccp.ProjCost),0)<>0 THEN CAST(sum(jccp.CurrEstCost) / ( sum(jccp.ProjCost) ) AS decimal(8,3))
		ELSE CAST(sum(jccp.CurrEstCost) / ( dbo.mfnGetCostOverrideAmount(jcci.JCCo,@inMonth,jcci.Contract, COALESCE(sum(jcop.ProjCost),0), sum(jccp.ProjCost), @inExcludeWorkStream,@inExcludeRevenueType ) ) AS decimal(8,3))
	END as mckRevenuePercentComplete
FROM
	JCCI jcci JOIN	
	JCCM jccm ON
		jcci.JCCo=jccm.JCCo
	AND jcci.Contract=jccm.Contract
	AND jcci.JCCo=@inCompany		
	AND ( ltrim(rtrim(jcci.Contract))=@inContract or @inContract is null ) LEFT OUTER JOIN
	JCDM jcdm ON
		jcci.JCCo=jcdm.JCCo
	AND jcci.Department=jcdm.Department JOIN
	GLPI glpi ON
		jcdm.GLCo=glpi.GLCo
	AND glpi.PartNo=3
	AND glpi.Instance=SUBSTRING(jcdm.OpenRevAcct,10,4) LEFT JOIN
	JCMP jcmp ON
		jccm.JCCo=jcmp.JCCo
	AND jccm.udPOC=jcmp.ProjectMgr left outer JOIN
	vDDCIc vddcic ON
		vddcic.ComboType='RevenueType'
	AND vddcic.DatabaseValue=COALESCE(jcci.udRevType,'C') LEFT OUTER JOIN
	vDDCI vddci ON
		vddci.ComboType='JCContractStatus'
	AND vddci.DatabaseValue=jccm.ContractStatus	JOIN
	JCJP jcjp on
		jcci.JCCo=jcjp.JCCo
	and jcci.Contract=jcjp.Contract
	and jcci.Item=jcjp.Item JOIN
	JCJM jcjm ON
		jcjp.JCCo=jcjm.JCCo
	AND jcjp.Job=jcjm.Job 
	AND (jcjm.udProjWrkstrm NOT IN (@inExcludeWorkStream) OR @inExcludeWorkStream IS null) JOIN
	JCCP jccp ON
		jcjp.JCCo=jccp.JCCo
	and jcjp.Job=jccp.Job
	and jcjp.Phase=jccp.Phase
	and jcjp.PhaseGroup=jccp.PhaseGroup		
	and jccp.Mth <= dbo.mfnFirstOfMonth(@inMonth) JOIN
	JCDC jcdc ON
		jccp.CostType=jcdc.CostType
	AND jccp.JCCo=jcdc.JCCo
	and jccp.PhaseGroup=jcdc.PhaseGroup	
	and jcci.Department=jcdc.Department LEFT OUTER JOIN
	JCOP jcop ON
		jcop.JCCo=jcjm.JCCo
	AND jcop.Job=jcjm.Job
	AND jcop.Month=dbo.mfnFirstOfMonth(@inMonth)
WHERE
	( COALESCE(jcci.udRevType,'C') <> (@inExcludeRevenueType) OR @inExcludeRevenueType is null  ) 
group by
	jcci.JCCo
,	jcci.Contract
,	jccm.Description
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
order by
	jcci.JCCo
,	ltrim(rtrim(jcci.Contract))
,	glpi.Instance

RETURN 
	
END
GO
