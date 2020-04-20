SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[mfnWIPRevenue]
(
	@Company	bCompany
,	@Month		bMonth
,	@Contract	bContract
)
RETURNS TABLE
AS 
RETURN (
select
	jcci.JCCo
,	LTRIM(RTRIM(jcci.Contract)) AS Contract
,	jccm.Description AS ContractDescription
,	jccm.udPOC AS ContractPOC
,	jcmp.Name AS ContractPOCName
,	substring(jcdm.OpenRevAcct,10,4) as GLDept
,	glpi.Description as GLDeptName
--,	COALESCE(jcci.udRevType,'C') AS RevenueType
,	vddcic.DisplayValue AS RevenueType
,	jcci.udLockYN AS IsLocked
,	dbo.mfnFirstOfMonth(@Month) AS ThroughMonth
,	sum(jcip.OrigContractAmt) as OriginalContractAmount
,	sum(jcip.ContractAmt) as CurrentContractAmount
,	case sum(jcip.ProjDollars) when 0 then sum(jcip.ContractAmt) else sum(jcip.ProjDollars) end as ProjectedContractAmount
,	SUM(jcci.BilledAmt) AS CurrentBilledAmount
from
	JCCI jcci join
	JCCM jccm on
		jcci.JCCo=jccm.JCCo
	and jcci.Contract=jccm.Contract 
	and jcci.JCCo=@Company join
	JCIP jcip on
		jcci.JCCo=jcip.JCCo
	and jcci.Contract=jcip.Contract
	and jcci.Item=jcip.Item 
	and (ltrim(rtrim(jcci.Contract))=@Contract OR @Contract IS NULL)
	and jcip.Mth <= dbo.mfnFirstOfMonth(@Month) JOIN
	JCDM jcdm on
		jcci.JCCo=jcdm.JCCo
	and jcci.Department=jcdm.Department JOIN
	GLPI glpi on
		glpi.PartNo=3
	AND glpi.GLCo=jcdm.GLCo
	and glpi.Instance=substring(jcdm.OpenRevAcct,10,4) join
	JCMP jcmp on
		jccm.JCCo=jcmp.JCCo
	and jccm.udPOC=jcmp.ProjectMgr left outer JOIN
	vDDCIc vddcic ON
		vddcic.ComboType='RevenueType'
	AND vddcic.DatabaseValue=COALESCE(jcci.udRevType,'C')
group by
	jcci.JCCo
,	jcci.Contract
,	jccm.Description
,	jccm.udPOC
,	jcmp.Name
,	substring(jcdm.OpenRevAcct,10,4) 
,	glpi.Description
,	vddcic.DisplayValue
,	jcci.udLockYN 
)
GO
