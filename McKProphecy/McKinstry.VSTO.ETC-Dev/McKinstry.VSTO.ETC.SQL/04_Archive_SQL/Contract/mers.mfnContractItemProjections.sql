USE Viewpoint
GO

/****** Object:  UserDefinedFunction [mers].[mfnContractItemProjections]    Script Date: 6/22/2016 4:36:43 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


create function [mers].[mfnContractItemProjections]
(
	@JCCo		bCompany
,	@Contract	bContract
,	@ProjectionMonth		bMonth
)
-- ========================================================================
-- mers.mfnContractItemProjections
-- Author:	Ziebell, Jonathan
-- Create date: 06/21/2016
-- Description:
/*
2016.04.12 - LWO -	Created as baseline for "Prophecy" ETC/LRF VSTO Solution
					Returns 'table' of Contract Items Projection data by Month through the specified Month related to specified Contract

					declare @JCCo bCompany
					declare @Contract bContract
					declare @ProjectionMonth		bMonth

					select @JCCo=1, @Contract=' 14345-', @ProjectionMonth='12/1/2015'

					select * from mers.mfnContractItemProjections(@JCCo, @Contract,@ProjectionMonth)
*/	
-- Update Hist: USER--------DATE-------DESC-----------
-- ========================================================================

returns table as return  -- TODO: Change to explicityly defined return table
select
--	'ContractItemProjections' as DataSetName,
	jccm.JCCo
,	jccm.Contract
,	jccm.Description as ContractDesc
,	jcci.Item as ContractItem
,	jcci.Description as ContractItemDesc
,	jccm.ContractStatus as ContractStatusId
,	ddci_contractstatus.DisplayValue as ContractStatus
,	jcci.Department as JCDepartment
,	jcdm.Description as JCDepartmentDescription
,	glpi.Instance as GLDepartment
,	glpi.Description as GLDepartmentDescription
,	jccm.udPOC as ContractPOC
,	jcmp.Name as ContractPOCName
,	jcmp.udPRCo as ContractPOCPRCo
,	jcmp.udEmployee as ContractPOCEmployee
,	preh.FullName as ContractPOCFullName
,	preh.ActiveYN as ContractPOCEmployeeActiveYN
,	ddup.VPUserName as ContractPOCUserName
,	case when jccm.StartDate is null then ( select min(Month) from JCOR where JCOR.JCCo=jccm.JCCo and JCOR.Contract=jccm.Contract  ) else jccm.StartDate end as ContractStartDate
,	case when jccm.ProjCloseDate is null then ( select max(Month) from JCOR where JCOR.JCCo=jccm.JCCo and JCOR.Contract=jccm.Contract  ) else jccm.ProjCloseDate end as ContractProjectedCloseDate
,	datediff(
		month
	,case when jccm.StartDate is null then ( select min(Month) from JCOR where JCOR.JCCo=jccm.JCCo and JCOR.Contract=jccm.Contract  ) else jccm.StartDate end 
	,case when jccm.ProjCloseDate is null then ( select max(Month) from JCOR where JCOR.JCCo=jccm.JCCo and JCOR.Contract=jccm.Contract  ) else jccm.ProjCloseDate end
	) as ContractDuration
,	jccm.ActualCloseDate as ContractActualCloseDate
,	jcci.udRevType as RevenueType
,	ddci_revenuetype.DisplayValue as RevnueTypeLabel
,	jcci.udProjDelivery as ProjectDelivery
,	udpd.Description as ProjectDeliveryLabel
,	jcci.StartMonth
--,	jcci.OrigContractAmt
--,	jcci.ContractAmt
--,	jcci.BilledAmt
--,	jcci.ReceivedAmt
--,	jcci.CurrentRetainAmt
,	jcci.MarkUpRate
,	jcci.udCRMNumber as CRMOpportunity
,	jcip.Mth as ProjectionMonth
,	jcip.OrigContractAmt as 	OrigContractAmt_Proj
,	jcip.OrigContractUnits	 as OrigContractUnits_Proj
,	jcip.OrigUnitPrice	 as OrigUnitPrice_Proj
,	jcip.ContractAmt	 as ContractAmt_Proj
,	jcip.ContractUnits	 as ContractUnits_Proj
,	jcip.CurrentUnitPrice	 as CurrentUnitPrice_Proj
,	jcip.BilledUnits	 as BilledUnits_Proj
,	jcip.BilledAmt	 as BilledAmt_Proj
,	jcip.ReceivedAmt	 as ReceivedAmt_Proj
,	jcip.CurrentRetainAmt	 as CurrentRetainAmt_Proj
,	jcip.BilledTax	 as BilledTax_Proj
,	jcip.ProjUnits	 as ProjUnits_Proj_Proj
,	jcip.ProjDollars	 as ProjDollars
,	jcip.ProjPlug	 as ProjPlug_Proj
from
	JCCM jccm left outer join
	JCCI jcci on
		jccm.JCCo=jcci.JCCo
	and jccm.Contract=jcci.Contract left outer join
	DDCI ddci_contractstatus on
		ddci_contractstatus.ComboType='JCContractStatus'
	and	cast(jccm.ContractStatus as varchar(10))=ddci_contractstatus.DatabaseValue  left outer join
	JCDM jcdm on
		jcci.JCCo=jcdm.JCCo
	and jcci.Department=jcdm.Department left outer join
	GLAC glac on
		jcdm.GLCo=glac.GLCo
	and jcdm.OpenRevAcct=glac.GLAcct left outer join
	GLPI glpi on
		glac.GLCo=glpi.GLCo
	and glac.Part3=glpi.Instance
	and glpi.PartNo=3 left outer join
	JCMP jcmp on
		jccm.JCCo=jcmp.JCCo
	and jccm.udPOC=jcmp.ProjectMgr left outer join
	PREHFullName preh on
		jcmp.udPRCo=preh.PRCo
	and jcmp.udEmployee=preh.Employee  left outer join 
	DDUP ddup on
		jcmp.udPRCo=ddup.PRCo
	and jcmp.udEmployee=ddup.Employee  left outer join
	DDCIShared ddci_revenuetype on
		ddci_revenuetype.ComboType='RevenueType'
	and	jcci.udRevType=ddci_revenuetype.DatabaseValue left outer join
	udProjDelivery udpd on
		jcci.udProjDelivery=udpd.Code left outer join
	JCIP jcip on
		jcci.JCCo=jcip.JCCo
	and jcci.Contract=jcip.Contract
	and jcci.Item=jcip.Item
where
	( jccm.JCCo = @JCCo	or @JCCo is null )
and ( jccm.Contract = @Contract	or @Contract is null )
and ( jcip.Mth <= @ProjectionMonth or @ProjectionMonth is null )
and jccm.JCCo < 100

GO


