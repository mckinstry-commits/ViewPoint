SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[mfnGetWIPRevenue]
(
	@inCompany				tinyint
,	@inMonth				smalldatetime
,	@inContract				bContract
,	@inIsLocked				bYN
,	@inExcludeWorkStream	varchar(255)
,	@inExcludeRevenueType	varchar(255)
)
RETURNS @retTable TABLE
(
	JCCo					bCompany		null
,	Contract				bContract		NULL
,	ContractDesc			VARCHAR(60)  	null
,	IsLocked				bYN				null
,	RevenueType				varchar(10)		null
,	RevenueTypeName			VARCHAR(60)		null
,	ContractStatus			varchar(10)		null
,	ContractStatusDesc		VARCHAR(60)		null
,	GLDepartment			VARCHAR(4)		null
,	GLDepartmentName		VARCHAR(60)		null
,	POC						bEmployee		null
,	POCName					VARCHAR(60)		null
,	OrigContractAmt			decimal(18,2)	null
,	CurrContractAmt			decimal(18,2)	null	
,	ProjContractAmt			decimal(18,2)	null	
,	RevenueIsOverride		bYN				null
,	RevenueOverridePercent	decimal(12,8)	NULL
,	RevenueOverrideAmount	decimal(18,2)	null
,	OROrigContractAmt		decimal(18,2)	null		
,	ORCurrContractAmt		decimal(18,2)	null		
,	ORProjContractAmt		decimal(18,2)	null		
,	BilledAmt				decimal(18,2)	null	
,	ThroughMonth			SMALLDATETIME	null
,	Note					VARCHAR(2000)	null	
,	mckETCContractValue		decimal(18,2)	null	
,	mckBilledToDate			decimal(18,2)	null
)

AS

BEGIN

INSERT @retTable
select 
	jcci.JCCo
,	ltrim(rtrim(jcci.Contract)) as Contract
,	jccm.Description AS ContractDesc
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
,	sum(jcip.OrigContractAmt) as OrigContractAmt
,	sum(jcip.ContractAmt) as CurrContractAmt
--,	CASE sum(jcip.ProjDollars) WHEN 0 THEN sum(jcip.ContractAmt) ELSE sum(jcip.ProjDollars) END as ProjContractAmt
,	sum(jcip.ProjDollars) as ProjContractAmt
,	case coalesce(jcor.RevCost,0)
		when 0 then 'N'
		else 'Y' 
	end as RevenueIsOverride
	
	/* TODO : 
		Calc Percent on ProjectedRevenue 
		Adjust to take : (Contract Override - Sum(Contract ProjDollars)) * Contract Item Override Percentage + Contract Item ProjDollars to get prorated Override Amount.	
	*/
	/* TODO : 
		Loss Calculation based on Projected Revenue 
			if (Sum Projected Revenue) - (Sum Projected Cost ) for all Contract Items < 0 then Percent Complete = 100%
		Only on Cost To Cost Rev Type
		
		Cost + Markup does not allow <0 % Complete
	
	*/
,	dbo.mfnGetRevenueOverridePercent(jcci.JCCo,@inMonth,jcci.Contract, sum(jcip.ProjDollars) ) as RevenueOverridePercent
,	CASE
		WHEN dbo.mfnGetRevenueOverrideAmount(jcci.JCCo,@inMonth,jcci.Contract, jcor.RevCost, sum(jcip.ProjDollars) ) = 0 THEN sum(jcip.ContractAmt)
		WHEN dbo.mfnGetRevenueOverrideAmount(jcci.JCCo,@inMonth,jcci.Contract, jcor.RevCost, sum(jcip.ProjDollars) ) is null THEN sum(jcip.ContractAmt)
		ELSE dbo.mfnGetRevenueOverrideAmount(jcci.JCCo,@inMonth,jcci.Contract, jcor.RevCost, sum(jcip.ProjDollars) )
	END as RevenueOverrideAmount
--,	case coalesce(jcor.RevCost,0)
--		when 0 then 1.00
--		else CAST(( sum(jcip.ContractAmt) / jcor.RevCost ) AS DECIMAL(8,3))
--	end as RevenueOverridePercent
,	sum(jcip.OrigContractAmt) as OROrigContractAmt
,	sum(jcip.ContractAmt) as ORCurrContractAmt	
,	CASE
		WHEN dbo.mfnGetRevenueOverrideAmount(jcci.JCCo,@inMonth,jcci.Contract, jcor.RevCost, sum(jcip.ProjDollars) ) =0 THEN sum(jcip.ContractAmt)
		WHEN dbo.mfnGetRevenueOverrideAmount(jcci.JCCo,@inMonth,jcci.Contract, jcor.RevCost, sum(jcip.ProjDollars) ) is NULL  THEN sum(jcip.ContractAmt)
		ELSE dbo.mfnGetRevenueOverrideAmount(jcci.JCCo,@inMonth,jcci.Contract, jcor.RevCost, sum(jcip.ProjDollars) )
	END AS ORProjContractAmt
,	sum(jcip.BilledAmt) as BilledAmt
,	dbo.mfnFirstOfMonth(@inMonth)
,	'Data through ' + CONVERT(VARCHAR(10),dbo.mfnFirstOfMonth(@inMonth),101) 
+	COALESCE('  Override: $' + CAST(jcor.RevCost AS VARCHAR(20)),'')	AS Note
,	case coalesce(jcor.RevCost,0)
		when 0 then sum(jcip.ProjDollars)
		else  
				CASE 
					WHEN dbo.mfnGetRevenueOverrideAmount(jcci.JCCo,@inMonth,jcci.Contract, jcor.RevCost, sum(jcip.ProjDollars) )  = 0 THEN sum(jcip.ContractAmt)
					WHEN dbo.mfnGetRevenueOverrideAmount(jcci.JCCo,@inMonth,jcci.Contract, jcor.RevCost, sum(jcip.ProjDollars) )  is null THEN sum(jcip.ContractAmt)
					ELSE dbo.mfnGetRevenueOverrideAmount(jcci.JCCo,@inMonth,jcci.Contract, jcor.RevCost, sum(jcip.ProjDollars) ) 
				END
			
	end as mckETCContractValue
,	sum(jcip.BilledAmt) AS mckBilledToDate
from
	JCCI jcci JOIN	
	JCIP jcip ON			
		jcci.JCCo=jcip.JCCo
	AND jcci.Contract=jcip.Contract
	AND jcci.Item=jcip.Item 
	AND jcci.JCCo=@inCompany
	AND ( ltrim(rtrim(jcci.Contract))=@inContract or @inContract is null )
	AND jcip.Mth <= dbo.mfnFirstOfMonth(@inMonth) JOIN
	JCCM jccm ON
		jcci.JCCo=jccm.JCCo
	AND jcci.Contract=jccm.Contract LEFT OUTER JOIN
	JCOR jcor ON
		jccm.JCCo=jcor.JCCo
	AND jccm.Contract=jcor.Contract 
	AND jcor.Month=dbo.mfnFirstOfMonth(@inMonth) JOIN
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
	AND vddci.DatabaseValue=jccm.ContractStatus	
WHERE
	( vddcic.DatabaseValue <> (@inExcludeRevenueType) OR @inExcludeRevenueType IS NULL  )
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
,	jcor.RevCost
,	vddci.DisplayValue
,	vddci.DatabaseValue
order by
	jcci.JCCo
,	ltrim(rtrim(jcci.Contract))
,	glpi.Instance

RETURN 

END



GO
