SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[mfnWIPCost]
(
	@Company					bCompany
,	@Month						bMonth
,	@Contract					bContract
,	@ExcludeWorkstreams			VARCHAR(255) = '''Sales'',''Internal'''
)
RETURNS TABLE
AS 

RETURN (
select 
	jccp.JCCo
,	LTRIM(RTRIM(jcjp.Contract)) AS Contract
,	jccm.Description AS ContractDescription
,	jccm.udPOC AS ContractPOC
,	jcmp.Name AS ContractPOCName
,	substring(jcdm.OpenRevAcct,10,4) as GLDept
,	glpi.Description as GLDeptName
--,	jcci.udRevType AS RevenueType
,	vddcic.DisplayValue AS RevenueType
,	jcci.udLockYN AS IsLocked
--,	jcjm.udProjWrkstrm AS WorkStream
,	dbo.mfnFirstOfMonth(@Month) AS ThroughMonth
,	sum(jccp.OrigEstCost) as OriginalCost
,	sum(jccp.CurrEstCost) as CurrentCost
,	case sum(jccp.ProjCost) when 0 then sum(jccp.CurrEstCost) else sum(jccp.ProjCost) end as ProjectedCost
,	@ExcludeWorkstreams AS ExcludeWorkstreams
from
	JCCI jcci JOIN
	JCJP jcjp on
		jcci.JCCo=jcjp.JCCo
	and jcci.Contract=jcjp.Contract
	and jcci.Item=jcjp.Item 
	AND (LTRIM(RTRIM(jcjp.Contract))=@Contract OR @Contract is NULL) JOIN
	JCJM jcjm ON
		jcjp.JCCo=jcjm.JCCo
	AND jcjp.Job=jcjm.Job 
	AND (jcjm.udProjWrkstrm NOT IN (@ExcludeWorkstreams) OR @ExcludeWorkstreams IS null) JOIN
	JCCP jccp ON
		jcjp.JCCo=jccp.JCCo
	and jcjp.Job=jccp.Job
	and jcjp.Phase=jccp.Phase
	and jcjp.PhaseGroup=jccp.PhaseGroup		
	and jccp.Mth <= dbo.mfnFirstOfMonth(@Month)
	and jccp.JCCo=@Company JOIN
	JCDC jcdc ON
		jccp.CostType=jcdc.CostType
	AND jccp.JCCo=jcdc.JCCo
	and jccp.PhaseGroup=jcdc.PhaseGroup	
	and jcci.Department=jcdc.Department JOIN
	JCCM jccm on
		jcci.JCCo=jccm.JCCo
	and jcci.Contract=jccm.Contract 
	and jcci.JCCo=@Company join
	JCDM jcdm on
		jcdc.JCCo=jcdm.JCCo
	and jcdc.GLCo=jcdm.GLCo
	and jcdc.Department=jcdm.Department JOIN
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
	jccp.JCCo
,	jcjp.Contract
,	jccm.Description
,	jccm.udPOC
,	jcmp.Name
,	substring(jcdm.OpenRevAcct,10,4) 
,	glpi.Description
,	vddcic.DisplayValue
,	jcci.udLockYN
)
GO
