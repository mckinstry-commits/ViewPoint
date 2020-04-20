use Viewpoint
go

/*

declare @JCCo bCompany
declare @Contract bContract
declare @Job bJob
declare @ProjectionMonth bMonth

select
	@JCCo = 1
,	@Contract = ' 14345-'
--,	@Contract = ' 10353-'
,	@Job= null --' 14345-001'
,	@ProjectionMonth = '12/31/2015'

if @ProjectionMonth is null
	select @ProjectionMonth = max(Month) from JCOR where JCCo=@JCCo and ( Contract=@Contract or @Contract is null ) group by JCCo, Contract

select * from mers.mfnContractHeader(@JCCo, @Contract, @ProjectionMonth) order by JCCo, Contract;
--select * from mers.mfnContractItem(@JCCo, @Contract) order by JCCo, Contract, ContractItem;
select * from mers.mfnContractItemProjectionSum(@JCCo, @Contract, @ProjectionMonth) order by JCCo, Contract, ContractItem, ThroughMonth;
--select * from mers.mfnContractItemProjections(@JCCo, @Contract, @ProjectionMonth) order by JCCo, Contract, ContractItem, ProjectionMonth;
select * from mers.mfnContractProjects(@JCCo, @Contract, @Job, @ProjectionMonth) order by JCCo, Contract, Job;

--select * from mers.mfnContractProjectPhases(@JCCo, @Contract, @Job) order by JCCo, Contract, Job, PhaseGroup, Phase;
--select * from mers.mfnContractProjectPhaseCostTypes(@JCCo, @Contract, @Job) order by JCCo, Contract, Job, PhaseGroup, Phase, CostTypeId;
--select * from mers.mfnContractProjectPhaseCostTypeProjections(@JCCo, @Contract, @Job, @ProjectionMonth) order by JCCo, Contract, Job, PhaseGroup, Phase, CostTypeId;
select * from mers.mfnContractProjectPhaseCostTypeProjectionSum(@JCCo, @Contract, @Job, @ProjectionMonth) order by JCCo, Contract, Job, PhaseGroup, Phase, CostTypeId;
select * from mers.mfnContractProjectPhaseCostTypeProjectionsDetail(@JCCo, @Contract, @Job, @ProjectionMonth) order by ThroughMonth, Mth, JCCo, Job, PhaseGroup, Phase, CostType;

*/


if exists ( select 1 from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mfnContractHeader' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION mers.mfnContractHeader'
	DROP FUNCTION mers.mfnContractHeader
end
go

print 'CREATE FUNCTION mers.mfnContractHeader'
go

create function mers.mfnContractHeader
(
	@JCCo		bCompany
,	@Contract	bContract
,	@ProjectionMonth		bMonth
)
/*

2016.04.12 - LWO -	Created as baseline for "Prophecy" ETC/LRF VSTO Solution
			Returns 'table' of Contract Header Information related to specified Contract

					declare @JCCo bCompany
					declare @Contract bContract
					declare @ProjectionMonth bMonth

					select @JCCo=1, @Contract=' 14345-', @ProjectionMonth='12/1/2015'

					select * from mers.mfnContractHeader(@JCCo, @Contract, @ProjectionMonth)

*/
returns table as return  -- TODO: Change to explicityly defined return table
select
--	'ContractHeader' as DataSetName,
	jccm.JCCo
,	jccm.Contract
,	jccm.Description
,	jccm.ContractStatus as ContractStatusId
,	ddci.DisplayValue as ContractStatus
,	jccm.Department as JCDepartment
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
,	case when @ProjectionMonth is null then jcor.Month else @ProjectionMonth end as ThroughMonth
,	jccm.OrigContractAmt
,	jccm.ContractAmt
,	jccm.BilledAmt
,	jccm.ReceivedAmt
,	jccm.CurrentRetainAmt
,	jccm.MaxRetgAmt
,	jccm.JBFlatBillingAmt
,	jccm.udGMAXAmt as GMAXAmt
,	jcor.RevCost as ContractAmount_Override
,	jcor.OtherAmount as ContractOtherAmount_Override
from
	JCCM jccm left outer join
	DDCI ddci on
		ddci.ComboType='JCContractStatus'
	and	cast(jccm.ContractStatus as varchar(10))=ddci.DatabaseValue  left outer join
	JCDM jcdm on
		jccm.JCCo=jcdm.JCCo
	and jccm.Department=jcdm.Department left outer join
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
	and jcmp.udEmployee=ddup.Employee left outer join
	JCOR jcor on
		jccm.JCCo=jcor.JCCo
	and jccm.Contract=jcor.Contract
	and ( jcor.Month = @ProjectionMonth or @ProjectionMonth is null)
where
	( jccm.JCCo = @JCCo	or @JCCo is null )
and ( jccm.Contract = @Contract	or @Contract is null )
and jccm.JCCo < 100
go

if exists ( select 1 from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mfnContractItem' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION mers.mfnContractItem'
	DROP FUNCTION mers.mfnContractItem
end
go

print 'CREATE FUNCTION mers.mfnContractItem'
go


create function mers.mfnContractItem
(
	@JCCo		bCompany
,	@Contract	bContract
)
/*

2016.04.12 - LWO -	Created as baseline for "Prophecy" ETC/LRF VSTO Solution
					Returns 'table' of Contract Items related to specified Contract

					declare @JCCo bCompany
					declare @Contract bContract

					select @JCCo=1, @Contract=' 14345-'

					select * from mers.mfnContractItem(@JCCo, @Contract)

*/
returns table as return  -- TODO: Change to explicityly defined return table
select
--	'ContractItem' as DataSetName,
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
,	jcci.OrigContractAmt
,	jcci.ContractAmt
,	jcci.BilledAmt
,	jcci.ReceivedAmt
,	jcci.CurrentRetainAmt
,	jcci.MarkUpRate
,	jcci.udCRMNumber as CRMOpportunity
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
		jcci.udProjDelivery=udpd.Code
where
	( jccm.JCCo = @JCCo	or @JCCo is null )
and ( jccm.Contract = @Contract	or @Contract is null )
and jccm.JCCo < 100
go


if exists ( select 1 from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mfnContractItemProjectionSum' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION mers.mfnContractItemProjectionSum'
	DROP FUNCTION mers.mfnContractItemProjectionSum
end
go

print 'CREATE FUNCTION mers.mfnContractItemProjectionSum'
go

create function mers.mfnContractItemProjectionSum
(
	@JCCo		bCompany
,	@Contract	bContract
,	@ProjectionMonth		bMonth
)
/*

2016.04.12 - LWO -	Created as baseline for "Prophecy" ETC/LRF VSTO Solution
					Returns 'table' of Contract Items Projection data by summed through the specified Month related to specified Contract

					declare @JCCo bCompany
					declare @Contract bContract
					declare @ProjectionMonth		bMonth

					select @JCCo=1, @Contract=' 14345-', @ProjectionMonth='12/1/2015'

					select * from mers.mfnContractItemProjectionSum(@JCCo, @Contract,@ProjectionMonth)

*/
returns table as return  -- TODO: Change to explicityly defined return table
select
--	'ContractItemProjectionsSum' as DataSetName,
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
,	jcci.OrigContractAmt
,	jcci.ContractAmt
,	jcci.BilledAmt
,	jcci.ReceivedAmt
,	jcci.CurrentRetainAmt
,	jcci.MarkUpRate
,	jcci.udCRMNumber as CRMOpportunity
,	@ProjectionMonth as ThroughMonth --jcip.Mth as ProjectionMonth
,	sum(jcip.OrigContractAmt) as OrigContractAmt_Proj
,	sum(jcip.OrigContractUnits) as OrigContractUnits_Proj
,	sum(jcip.OrigUnitPrice) as 	OrigUnitPrice_Proj
,	sum(jcip.ContractAmt) as 	ContractAmt_Proj
,	sum(jcip.ContractUnits) as 	ContractUnits_Proj
,	sum(jcip.CurrentUnitPrice) as 	CurrentUnitPrice_Proj
,	sum(jcip.BilledUnits) as 	BilledUnits_Proj
,	sum(jcip.BilledAmt) as 	BilledAmt_Proj
,	sum(jcip.ReceivedAmt) as 	ReceivedAmt_Proj
,	sum(jcip.CurrentRetainAmt) as 	CurrentRetainAmt_Proj
,	sum(jcip.BilledTax) as 	BilledTax_Proj
,	sum(jcip.ProjUnits) as 	ProjUnits_Proj
,	sum(jcip.ProjDollars) as 	ProjDollars_Proj
--,	jcip.ProjPlug	
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
group by
	jccm.JCCo
,	jccm.Contract
,	jccm.Description 
,	jcci.Item 
,	jcci.Description 
,	jccm.ContractStatus 
,	ddci_contractstatus.DisplayValue 
,	jcci.Department 
,	jcdm.Description 
,	glpi.Instance 
,	glpi.Description 
,	jccm.udPOC 
,	jcmp.Name 
,	jcmp.udPRCo 
,	jcmp.udEmployee 
,	preh.FullName 
,	preh.ActiveYN 
,	ddup.VPUserName 
,	jccm.StartDate 
,	jccm.ProjCloseDate 
,	jccm.ActualCloseDate 
,	jcci.udRevType 
,	ddci_revenuetype.DisplayValue 
,	jcci.udProjDelivery 
,	udpd.Description 
,	jcci.StartMonth
,	jcci.OrigContractAmt
,	jcci.ContractAmt
,	jcci.BilledAmt
,	jcci.ReceivedAmt
,	jcci.CurrentRetainAmt
,	jcci.MarkUpRate
,	jcci.udCRMNumber 
go


if exists ( select 1 from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mfnContractItemProjections' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION mers.mfnContractItemProjections'
	DROP FUNCTION mers.mfnContractItemProjections
end
go

print 'CREATE FUNCTION mers.mfnContractItemProjections'
go

create function mers.mfnContractItemProjections
(
	@JCCo		bCompany
,	@Contract	bContract
,	@ProjectionMonth		bMonth
)
/*

2016.04.12 - LWO -	Created as baseline for "Prophecy" ETC/LRF VSTO Solution
					Returns 'table' of Contract Items Projection data by Month through the specified Month related to specified Contract

					declare @JCCo bCompany
					declare @Contract bContract
					declare @ProjectionMonth		bMonth

					select @JCCo=1, @Contract=' 14345-', @ProjectionMonth='12/1/2015'

					select * from mers.mfnContractItemProjections(@JCCo, @Contract,@ProjectionMonth)

*/
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
go


if exists ( select 1 from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mfnContractProjects' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION mers.mfnContractProjects'
	DROP FUNCTION mers.mfnContractProjects
end
go

print 'CREATE FUNCTION mers.mfnContractProjects'
go

create function mers.mfnContractProjects
(
	@JCCo		bCompany
,	@Contract	bContract
,	@Job		bJob
,	@ProjectionMonth	bMonth
)
/*

2016.04.12 - LWO -	Created as baseline for "Prophecy" ETC/LRF VSTO Solution
					Returns 'table' of Projects/Jobs associated to specified Contract

					declare @JCCo bCompany
					declare @Contract bContract
					declare @Job	bJob 
					declare @ProjectionMonth	bMonth 

					select @JCCo=1, @Contract=' 14345-', @Job = null, @ProjectionMonth='12/1/2015'

					select * from mers.mfnContractProjects(@JCCo, @Contract, @Job)

*/
returns table as return  -- TODO: Change to explicityly defined return table
select distinct
--	'ContractProjects' as DataSetName,
	jcjm.JCCo
,	jcjm.Contract
,	jccm.Description as ContractDesc	
,	jccm.Department as ContractJCDepartment
,	jcdm_contract.Description as ContractJCDepartmentDescription
,	glpi_contract.Instance as ContractGLDepartment
,	glpi_contract.Description as ContractGLDepartmentDescription
,	jccm.udPOC as ContractPOC
,	jcmp_poc.Name as ContractPOCName
,	jcmp_poc.udPRCo as ContractPOCPRCo
,	jcmp_poc.udEmployee as ContractPOCEmployee
,	preh_poc.FullName as ContractPOCFullName
,	preh_poc.ActiveYN as ContractPOCEmployeeActiveYN
,	ddup_poc.VPUserName as ContractPOCUserName
,	jcjm.Job
,	jcjm.Description as JobDesc
,	jcjm.JobStatus as JobStatusId
,	ddci.DisplayValue as JobStatus
,	jcci.Department as JCDepartment
,	jcdm_job.Description as JCDepartmentDescription
,	glpi_job.Instance as GLDepartment
,	glpi_job.Description as GLDepartmentDescription
,	jcjm.ProjectMgr as ProjectMgr
,	jcmp_pm.Name as ProjectMgrName
,	jcmp_pm.udPRCo as ProjectMgrPRCo
,	jcmp_pm.udEmployee as ProjectMgrEmployee
,	preh_pm.FullName as ProjectMgrFullName
,	preh_pm.ActiveYN as ProjectMgrActiveYN
,	ddup_pm.VPUserName as ProjectMgrUserName
,	jcjm.JobPhone	
,	jcjm.JobFax	
,	jcjm.MailAddress	
,	jcjm.MailAddress2	
,	jcjm.MailCity	
,	jcjm.MailState	
,	jcjm.MailZip	
,	jcjm.MailCountry	
,	jcjm.udCRMNum	
,	jcjm.udProjWrkstrm	
,	jcjm.udDateChanged	
,	case when jcjm.udProjStart is null then ( select min(Month) from JCOP where JCOP.JCCo=jccm.JCCo and JCOP.Job=jcjm.Job  ) else jcjm.udProjStart end as ProjectStartDate
,	case when jcjm.udProjEnd is null then ( select max(Month) from JCOP where JCOP.JCCo=jccm.JCCo and JCOP.Job=jcjm.Job  ) else jcjm.udProjEnd end as ProjectEndDate
,	datediff(
		month
	,case when jcjm.udProjStart is null then ( select min(Month) from JCOP where JCOP.JCCo=jccm.JCCo and JCOP.Job=jcjm.Job  ) else jcjm.udProjStart end
	,case when jcjm.udProjEnd is null then ( select max(Month) from JCOP where JCOP.JCCo=jccm.JCCo and JCOP.Job=jcjm.Job  ) else jcjm.udProjEnd end
	) as ProjectDuration
from
	JCJM jcjm left outer join	 
	DDCIShared ddci on
		ddci.ComboType='JCJMJobStatus'
	and	cast(jcjm.JobStatus as varchar(10))=ddci.DatabaseValue left outer join
	JCJP jcjp on
		jcjm.JCCo=jcjp.JCCo
	and jcjm.Job=jcjp.Job left outer join
	JCOP jcop on
		jcjm.JCCo = jcop.JCCo
	and jcjm.Job = jcop.Job left outer join
	JCCI jcci on
		jcjp.JCCo=jcci.JCCo
	and jcjp.Contract=jcci.Contract
	and jcjp.Item=jcci.Item left outer join
	JCCM jccm on
		jcci.JCCo=jccm.JCCo
	and jcci.Contract=jccm.Contract left outer join
	JCDM jcdm_job on
		jcci.JCCo=jcdm_job.JCCo
	and jcci.Department=jcdm_job.Department left outer join
	GLAC glac_job on
		jcdm_job.GLCo=glac_job.GLCo
	and jcdm_job.OpenRevAcct=glac_job.GLAcct left outer join
	GLPI glpi_job on
		glac_job.GLCo=glpi_job.GLCo
	and glac_job.Part3=glpi_job.Instance
	and glpi_job.PartNo=3 left outer join
	JCDM jcdm_contract on
		jccm.JCCo=jcdm_contract.JCCo
	and jccm.Department=jcdm_contract.Department left outer join
	GLAC glac_contract on
		jcdm_contract.GLCo=glac_contract.GLCo
	and jcdm_contract.OpenRevAcct=glac_contract.GLAcct left outer join
	GLPI glpi_contract on
		glac_contract.GLCo=glpi_contract.GLCo
	and glac_contract.Part3=glpi_contract.Instance
	and glpi_job.PartNo=3 left outer join
	JCMP jcmp_poc on
		jccm.JCCo=jcmp_poc.JCCo
	and jccm.udPOC=jcmp_poc.ProjectMgr left join
	PREHFullName preh_poc on
		jcmp_poc.udPRCo=preh_poc.PRCo
	and jcmp_poc.udEmployee=preh_poc.Employee left join 
	DDUP ddup_poc on
		jcmp_poc.udPRCo=ddup_poc.PRCo
	and jcmp_poc.udEmployee=ddup_poc.Employee left outer join
	JCMP jcmp_pm on
		jccm.JCCo=jcmp_pm.JCCo
	and jccm.udPOC=jcmp_pm.ProjectMgr left join
	PREHFullName preh_pm on
		jcmp_pm.udPRCo=preh_pm.PRCo
	and jcmp_pm.udEmployee=preh_pm.Employee left join 
	DDUP ddup_pm on
		jcmp_pm.udPRCo=ddup_pm.PRCo
	and jcmp_pm.udEmployee=ddup_pm.Employee
	--TODO: Get JCOP value for the specified Month to include optional Cost Override
where
	jcjm.JCCo<100
and	( jcjm.JCCo = @JCCo	or @JCCo is null )
and ( jcjm.Contract=@Contract or @Contract is null )
and ( jcjm.Job=@Job or @Job is null )
go


if exists ( select 1 from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mfnContractProjectPhases' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION mers.mfnContractProjectPhases'
	DROP FUNCTION mers.mfnContractProjectPhases
end
go

print 'CREATE FUNCTION mers.mfnContractProjectPhases'
go

create function mers.mfnContractProjectPhases
(
	@JCCo		bCompany
,	@Contract	bContract
,	@Job		bJob
)
/*

2016.04.12 - LWO -	Created as baseline for "Prophecy" ETC/LRF VSTO Solution
					Returns 'table' of Project/Job Phases for Projects/Jobs  associated to specified Contract

					declare @JCCo bCompany
					declare @Contract bContract
					declare @Job	bJob 

					select @JCCo=1, @Contract=' 14345-', @Job = null

					select * from mers.mfnContractProjectPhases(@JCCo, @Contract, @Job)

*/
returns table as return  -- TODO: Change to explicityly defined return table
select 
--	'ContractProjectPhases' as DataSetName,
	jcjm.JCCo
,	jcjm.Contract
,	jccm.Description as ContractDesc	
,	jccm.Department as ContractJCDepartment
,	jcdm_contract.Description as ContractJCDepartmentDescription
,	glpi_contract.Instance as ContractGLDepartment
,	glpi_contract.Description as ContractGLDepartmentDescription
,	jccm.udPOC as ContractPOC
,	jcmp_poc.Name as ContractPOCName
,	jcmp_poc.udPRCo as ContractPOCPRCo
,	jcmp_poc.udEmployee as ContractPOCEmployee
,	preh_poc.FullName as ContractPOCFullName
,	preh_poc.ActiveYN as ContractPOCEmployeeActiveYN
,	ddup_poc.VPUserName as ContractPOCUserName
,	jcjm.Job
,	jcjm.Description as JobDesc
,	jcjm.JobStatus as JobStatusId
,	ddci.DisplayValue as JobStatus
,	jcci.Department as JCDepartment
,	jcdm_job.Description as JCDepartmentDescription
,	glpi_job.Instance as GLDepartment
,	glpi_job.Description as GLDepartmentDescription
,	jcjm.ProjectMgr as ProjectMgr
,	jcmp_pm.Name as ProjectMgrName
,	jcmp_pm.udPRCo as ProjectMgrPRCo
,	jcmp_pm.udEmployee as ProjectMgrEmployee
,	preh_pm.FullName as ProjectMgrFullName
,	preh_pm.ActiveYN as ProjectMgrActiveYN
,	ddup_pm.VPUserName as ProjectMgrUserName
,	jcjm.JobPhone	
,	jcjm.JobFax	
,	jcjm.MailAddress	
,	jcjm.MailAddress2	
,	jcjm.MailCity	
,	jcjm.MailState	
,	jcjm.MailZip	
,	jcjm.MailCountry	
,	jcjm.udCRMNum	
,	jcjm.udProjWrkstrm	
,	jcjm.udDateChanged	
,	case when jcjm.udProjStart is null then ( select min(Month) from JCOP where JCOP.JCCo=jccm.JCCo and JCOP.Job=jcjm.Job  ) else jcjm.udProjStart end as ProjectStartDate
,	case when jcjm.udProjEnd is null then ( select max(Month) from JCOP where JCOP.JCCo=jccm.JCCo and JCOP.Job=jcjm.Job  ) else jcjm.udProjEnd end as ProjectEndDate
,	datediff(
		month
	,case when jcjm.udProjStart is null then ( select min(Month) from JCOP where JCOP.JCCo=jccm.JCCo and JCOP.Job=jcjm.Job  ) else jcjm.udProjStart end
	,case when jcjm.udProjEnd is null then ( select max(Month) from JCOP where JCOP.JCCo=jccm.JCCo and JCOP.Job=jcjm.Job  ) else jcjm.udProjEnd end
	) as ProjectDuration
,	jcjp.Item as ContractItem
,	jcci.Description as ContractItemDesc
,	jcjp.PhaseGroup
,	jcjp.Phase
,	jcjp.Description as JobPhaseDesc
from
	JCJM jcjm left outer join	 
	DDCIShared ddci on
		ddci.ComboType='JCJMJobStatus'
	and	cast(jcjm.JobStatus as varchar(10))=ddci.DatabaseValue left outer join
	JCJP jcjp on
		jcjm.JCCo=jcjp.JCCo
	and jcjm.Job=jcjp.Job left outer join
	JCCI jcci on
		jcjp.JCCo=jcci.JCCo
	and jcjp.Contract=jcci.Contract
	and jcjp.Item=jcci.Item left outer join
	JCCM jccm on
		jcci.JCCo=jccm.JCCo
	and jcci.Contract=jccm.Contract left outer join
	JCDM jcdm_job on
		jcci.JCCo=jcdm_job.JCCo
	and jcci.Department=jcdm_job.Department left outer join
	GLAC glac_job on
		jcdm_job.GLCo=glac_job.GLCo
	and jcdm_job.OpenRevAcct=glac_job.GLAcct left outer join
	GLPI glpi_job on
		glac_job.GLCo=glpi_job.GLCo
	and glac_job.Part3=glpi_job.Instance
	and glpi_job.PartNo=3 left outer join
	JCDM jcdm_contract on
		jccm.JCCo=jcdm_contract.JCCo
	and jccm.Department=jcdm_contract.Department left outer join
	GLAC glac_contract on
		jcdm_contract.GLCo=glac_contract.GLCo
	and jcdm_contract.OpenRevAcct=glac_contract.GLAcct left outer join
	GLPI glpi_contract on
		glac_contract.GLCo=glpi_contract.GLCo
	and glac_contract.Part3=glpi_contract.Instance
	and glpi_job.PartNo=3 left outer join
	JCMP jcmp_poc on
		jccm.JCCo=jcmp_poc.JCCo
	and jccm.udPOC=jcmp_poc.ProjectMgr left join
	PREHFullName preh_poc on
		jcmp_poc.udPRCo=preh_poc.PRCo
	and jcmp_poc.udEmployee=preh_poc.Employee left join 
	DDUP ddup_poc on
		jcmp_poc.udPRCo=ddup_poc.PRCo
	and jcmp_poc.udEmployee=ddup_poc.Employee left outer join
	JCMP jcmp_pm on
		jccm.JCCo=jcmp_pm.JCCo
	and jccm.udPOC=jcmp_pm.ProjectMgr left join
	PREHFullName preh_pm on
		jcmp_pm.udPRCo=preh_pm.PRCo
	and jcmp_pm.udEmployee=preh_pm.Employee left join 
	DDUP ddup_pm on
		jcmp_pm.udPRCo=ddup_pm.PRCo
	and jcmp_pm.udEmployee=ddup_pm.Employee

where
	jcjm.JCCo<100
and	( jcjm.JCCo = @JCCo	or @JCCo is null )
and ( jcjm.Contract=@Contract or @Contract is null )
and ( jcjm.Job=@Job or @Job is null )
go



if exists ( select 1 from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mfnContractProjectPhaseCostTypes' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION mers.mfnContractProjectPhaseCostTypes'
	DROP FUNCTION mers.mfnContractProjectPhaseCostTypes
end
go

print 'CREATE FUNCTION mers.mfnContractProjectPhaseCostTypes'
go

create function mers.mfnContractProjectPhaseCostTypes
(
	@JCCo		bCompany
,	@Contract	bContract
,	@Job		bJob
)
/*

2016.04.12 - LWO -	Created as baseline for "Prophecy" ETC/LRF VSTO Solution
					Returns 'table' of Project/Job Phase CostTypes for Projects/Jobs Phases for Projects/Jobs  associated to specified Contract

					declare @JCCo bCompany
					declare @Contract bContract
					declare @Job	bJob 

					select @JCCo=1, @Contract=' 14345-', @Job = null

					select * from mers.mfnContractProjectPhaseCostTypes(@JCCo, @Contract, @Job)

*/
returns table as return  -- TODO: Change to explicityly defined return table
select 
--	'ContractProjectPhaseCostTypes' as DataSetName,
	jcjm.JCCo
,	jcjm.Contract
,	jccm.Description as ContractDesc	
,	jccm.Department as ContractJCDepartment
,	jcdm_contract.Description as ContractJCDepartmentDescription
,	glpi_contract.Instance as ContractGLDepartment
,	glpi_contract.Description as ContractGLDepartmentDescription
,	jccm.udPOC as ContractPOC
,	jcmp_poc.Name as ContractPOCName
,	jcmp_poc.udPRCo as ContractPOCPRCo
,	jcmp_poc.udEmployee as ContractPOCEmployee
,	preh_poc.FullName as ContractPOCFullName
,	preh_poc.ActiveYN as ContractPOCEmployeeActiveYN
,	ddup_poc.VPUserName as ContractPOCUserName
,	jcjm.Job
,	jcjm.Description as JobDesc
,	jcjm.JobStatus as JobStatusId
,	ddci.DisplayValue as JobStatus
,	jcci.Department as JCDepartment
,	jcdm_job.Description as JCDepartmentDescription
,	glpi_job.Instance as GLDepartment
,	glpi_job.Description as GLDepartmentDescription
,	jcjm.ProjectMgr as ProjectMgr
,	jcmp_pm.Name as ProjectMgrName
,	jcmp_pm.udPRCo as ProjectMgrPRCo
,	jcmp_pm.udEmployee as ProjectMgrEmployee
,	preh_pm.FullName as ProjectMgrFullName
,	preh_pm.ActiveYN as ProjectMgrActiveYN
,	ddup_pm.VPUserName as ProjectMgrUserName
,	jcjm.JobPhone	
,	jcjm.JobFax	
,	jcjm.MailAddress	
,	jcjm.MailAddress2	
,	jcjm.MailCity	
,	jcjm.MailState	
,	jcjm.MailZip	
,	jcjm.MailCountry	
,	jcjm.udCRMNum	
,	jcjm.udProjWrkstrm	
,	jcjm.udDateChanged	
,	case when jcjm.udProjStart is null then ( select min(Month) from JCOP where JCOP.JCCo=jccm.JCCo and JCOP.Job=jcjm.Job  ) else jcjm.udProjStart end as ProjectStartDate
,	case when jcjm.udProjEnd is null then ( select max(Month) from JCOP where JCOP.JCCo=jccm.JCCo and JCOP.Job=jcjm.Job  ) else jcjm.udProjEnd end as ProjectEndDate
,	datediff(
		month
	,case when jcjm.udProjStart is null then ( select min(Month) from JCOP where JCOP.JCCo=jccm.JCCo and JCOP.Job=jcjm.Job  ) else jcjm.udProjStart end
	,case when jcjm.udProjEnd is null then ( select max(Month) from JCOP where JCOP.JCCo=jccm.JCCo and JCOP.Job=jcjm.Job  ) else jcjm.udProjEnd end
	) as ProjectDuration
,	jcjp.Item as ContractItem
,	jcci.Description as ContractItemDesc
,	jcjp.PhaseGroup
,	jcjp.Phase
,	jcjp.Description as JobPhaseDesc
,	jcct.Abbreviation as CostTypeId
,	jcct.Description as CostType
,	jcch.OrigCost
,	jcch.OrigHours
,	jcch.OrigUnits
from
	JCJM jcjm left outer join	 
	DDCIShared ddci on
		ddci.ComboType='JCJMJobStatus'
	and	cast(jcjm.JobStatus as varchar(10))=ddci.DatabaseValue left outer join
	JCJP jcjp on
		jcjm.JCCo=jcjp.JCCo
	and jcjm.Job=jcjp.Job left outer join
	JCCH jcch on
		jcjp.JCCo=jcch.JCCo
	and jcjp.Job=jcch.Job
	and jcjp.PhaseGroup=jcch.PhaseGroup
	and jcjp.Phase=jcch.Phase left outer join
	JCCT jcct on
		jcch.PhaseGroup=jcct.PhaseGroup
	and jcch.CostType=jcct.CostType left outer join
	JCCI jcci on
		jcjp.JCCo=jcci.JCCo
	and jcjp.Contract=jcci.Contract
	and jcjp.Item=jcci.Item left outer join
	JCCM jccm on
		jcci.JCCo=jccm.JCCo
	and jcci.Contract=jccm.Contract left outer join
	JCDM jcdm_job on
		jcci.JCCo=jcdm_job.JCCo
	and jcci.Department=jcdm_job.Department left outer join
	GLAC glac_job on
		jcdm_job.GLCo=glac_job.GLCo
	and jcdm_job.OpenRevAcct=glac_job.GLAcct left outer join
	GLPI glpi_job on
		glac_job.GLCo=glpi_job.GLCo
	and glac_job.Part3=glpi_job.Instance
	and glpi_job.PartNo=3 left outer join
	JCDM jcdm_contract on
		jccm.JCCo=jcdm_contract.JCCo
	and jccm.Department=jcdm_contract.Department left outer join
	GLAC glac_contract on
		jcdm_contract.GLCo=glac_contract.GLCo
	and jcdm_contract.OpenRevAcct=glac_contract.GLAcct left outer join
	GLPI glpi_contract on
		glac_contract.GLCo=glpi_contract.GLCo
	and glac_contract.Part3=glpi_contract.Instance
	and glpi_job.PartNo=3 left outer join
	JCMP jcmp_poc on
		jccm.JCCo=jcmp_poc.JCCo
	and jccm.udPOC=jcmp_poc.ProjectMgr left join
	PREHFullName preh_poc on
		jcmp_poc.udPRCo=preh_poc.PRCo
	and jcmp_poc.udEmployee=preh_poc.Employee left join 
	DDUP ddup_poc on
		jcmp_poc.udPRCo=ddup_poc.PRCo
	and jcmp_poc.udEmployee=ddup_poc.Employee left outer join
	JCMP jcmp_pm on
		jccm.JCCo=jcmp_pm.JCCo
	and jccm.udPOC=jcmp_pm.ProjectMgr left join
	PREHFullName preh_pm on
		jcmp_pm.udPRCo=preh_pm.PRCo
	and jcmp_pm.udEmployee=preh_pm.Employee left join 
	DDUP ddup_pm on
		jcmp_pm.udPRCo=ddup_pm.PRCo
	and jcmp_pm.udEmployee=ddup_pm.Employee
where
	jcjm.JCCo<100
and	( jcjm.JCCo = @JCCo	or @JCCo is null )
and ( jcjm.Contract=@Contract or @Contract is null )
and ( jcjm.Job=@Job or @Job is null )
go



if exists ( select 1 from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mfnContractProjectPhaseCostTypeProjections' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION mers.mfnContractProjectPhaseCostTypeProjections'
	DROP FUNCTION mers.mfnContractProjectPhaseCostTypeProjections
end
go

print 'CREATE FUNCTION mers.mfnContractProjectPhaseCostTypeProjections'
go

create function mers.mfnContractProjectPhaseCostTypeProjections
(
	@JCCo				bCompany
,	@Contract			bContract
,	@Job				bJob
,	@ProjectionMonth	bMonth
)
/*

2016.04.12 - LWO -	Created as baseline for "Prophecy" ETC/LRF VSTO Solution
					Returns 'table' of Project/Job Phase CostTypes for Projects/Jobs Phases for Projects/Jobs  associated to specified Contract

					declare @JCCo bCompany
					declare @Contract bContract
					declare @Job	bJob 
					declare @ProjectionMonth	bMonth 

					select @JCCo=1, @Contract=' 14345-', @Job = null, @ProjectionMonth='12/1/2012'

					select * from mers.mfnContractProjectPhaseCostTypeProjections(@JCCo, @Contract, @Job, @ProjectionMonth)

*/
returns table as return  -- TODO: Change to explicityly defined return table
select 
--	'ContractProjectPhaseCostTypeProjections' as DataSetName,
	jcjm.JCCo
,	jcjm.Contract
,	jccm.Description as ContractDesc	
,	jccm.Department as ContractJCDepartment
,	jcdm_contract.Description as ContractJCDepartmentDescription
,	glpi_contract.Instance as ContractGLDepartment
,	glpi_contract.Description as ContractGLDepartmentDescription
,	jccm.udPOC as ContractPOC
,	jcmp_poc.Name as ContractPOCName
,	jcmp_poc.udPRCo as ContractPOCPRCo
,	jcmp_poc.udEmployee as ContractPOCEmployee
,	preh_poc.FullName as ContractPOCFullName
,	preh_poc.ActiveYN as ContractPOCEmployeeActiveYN
,	ddup_poc.VPUserName as ContractPOCUserName
,	jcjm.Job
,	jcjm.Description as JobDesc
,	jcjm.JobStatus as JobStatusId
,	ddci.DisplayValue as JobStatus
,	jcci.Department as JCDepartment
,	jcdm_job.Description as JCDepartmentDescription
,	glpi_job.Instance as GLDepartment
,	glpi_job.Description as GLDepartmentDescription
,	jcjm.ProjectMgr as ProjectMgr
,	jcmp_pm.Name as ProjectMgrName
,	jcmp_pm.udPRCo as ProjectMgrPRCo
,	jcmp_pm.udEmployee as ProjectMgrEmployee
,	preh_pm.FullName as ProjectMgrFullName
,	preh_pm.ActiveYN as ProjectMgrActiveYN
,	ddup_pm.VPUserName as ProjectMgrUserName
,	jcjm.JobPhone	
,	jcjm.JobFax	
,	jcjm.MailAddress	
,	jcjm.MailAddress2	
,	jcjm.MailCity	
,	jcjm.MailState	
,	jcjm.MailZip	
,	jcjm.MailCountry	
,	jcjm.udCRMNum	
,	jcjm.udProjWrkstrm	
,	jcjm.udDateChanged	
,	case when jcjm.udProjStart is null then ( select min(Month) from JCOP where JCOP.JCCo=jcjm.JCCo and JCOP.Job=jcjm.Job  ) else jcjm.udProjStart end as ProjectStartDate
,	case when jcjm.udProjEnd is null then ( select max(Month) from JCOP where JCOP.JCCo=jcjm.JCCo and JCOP.Job=jcjm.Job  ) else jcjm.udProjEnd end as ProjectEndDate
,	datediff(
		month
	,case when jcjm.udProjStart is null then ( select min(Month) from JCOP where JCOP.JCCo=jcjm.JCCo and JCOP.Job=jcjm.Job  ) else jcjm.udProjStart end
	,case when jcjm.udProjEnd is null then ( select max(Month) from JCOP where JCOP.JCCo=jcjm.JCCo and JCOP.Job=jcjm.Job  ) else jcjm.udProjEnd end
	) as ProjectDuration
,	jcjp.Item as ContractItem
,	jcci.Description as ContractItemDesc
,	jcjp.PhaseGroup
,	jcjp.Phase
,	jcjp.Description as JobPhaseDesc
,	jcct.Abbreviation as CostTypeId
,	jcct.Description as CostType
,	jcch.OrigCost
,	jcch.OrigHours
,	jcch.OrigUnits
,	jccp.Mth
,	jccp.ActualHours	
,	jccp.ActualUnits	
,	jccp.ActualCost	
,	jccp.OrigEstHours	
,	jccp.OrigEstUnits	
,	jccp.OrigEstCost	
,	jccp.CurrEstHours	
,	jccp.CurrEstUnits	
,	jccp.CurrEstCost	
,	jccp.ProjHours	
,	jccp.ProjUnits	
,	jccp.ProjCost	
,	jccp.ForecastHours	
,	jccp.ForecastUnits	
,	jccp.ForecastCost	
,	jccp.TotalCmtdUnits	
,	jccp.TotalCmtdCost	
,	jccp.RemainCmtdUnits	
,	jccp.RemainCmtdCost	
,	jccp.RecvdNotInvcdUnits	
,	jccp.RecvdNotInvcdCost	
,	jccp.ProjPlug	
from
	JCJM jcjm left outer join	 
	DDCIShared ddci on
		ddci.ComboType='JCJMJobStatus'
	and	cast(jcjm.JobStatus as varchar(10))=ddci.DatabaseValue left outer join
	JCJP jcjp on
		jcjm.JCCo=jcjp.JCCo
	and jcjm.Job=jcjp.Job left outer join
	JCCH jcch on
		jcjp.JCCo=jcch.JCCo
	and jcjp.Job=jcch.Job
	and jcjp.PhaseGroup=jcch.PhaseGroup
	and jcjp.Phase=jcch.Phase left outer join
	JCCT jcct on
		jcch.PhaseGroup=jcct.PhaseGroup
	and jcch.CostType=jcct.CostType left outer join
	JCCI jcci on
		jcjp.JCCo=jcci.JCCo
	and jcjp.Contract=jcci.Contract
	and jcjp.Item=jcci.Item left outer join
	JCCM jccm on
		jcci.JCCo=jccm.JCCo
	and jcci.Contract=jccm.Contract left outer join
	JCDM jcdm_job on
		jcci.JCCo=jcdm_job.JCCo
	and jcci.Department=jcdm_job.Department left outer join
	GLAC glac_job on
		jcdm_job.GLCo=glac_job.GLCo
	and jcdm_job.OpenRevAcct=glac_job.GLAcct left outer join
	GLPI glpi_job on
		glac_job.GLCo=glpi_job.GLCo
	and glac_job.Part3=glpi_job.Instance
	and glpi_job.PartNo=3 left outer join
	JCDM jcdm_contract on
		jccm.JCCo=jcdm_contract.JCCo
	and jccm.Department=jcdm_contract.Department left outer join
	GLAC glac_contract on
		jcdm_contract.GLCo=glac_contract.GLCo
	and jcdm_contract.OpenRevAcct=glac_contract.GLAcct left outer join
	GLPI glpi_contract on
		glac_contract.GLCo=glpi_contract.GLCo
	and glac_contract.Part3=glpi_contract.Instance
	and glpi_job.PartNo=3 left outer join
	JCMP jcmp_poc on
		jccm.JCCo=jcmp_poc.JCCo
	and jccm.udPOC=jcmp_poc.ProjectMgr left join
	PREHFullName preh_poc on
		jcmp_poc.udPRCo=preh_poc.PRCo
	and jcmp_poc.udEmployee=preh_poc.Employee left join 
	DDUP ddup_poc on
		jcmp_poc.udPRCo=ddup_poc.PRCo
	and jcmp_poc.udEmployee=ddup_poc.Employee left outer join
	JCMP jcmp_pm on
		jccm.JCCo=jcmp_pm.JCCo
	and jccm.udPOC=jcmp_pm.ProjectMgr left join
	PREHFullName preh_pm on
		jcmp_pm.udPRCo=preh_pm.PRCo
	and jcmp_pm.udEmployee=preh_pm.Employee left join 
	DDUP ddup_pm on
		jcmp_pm.udPRCo=ddup_pm.PRCo
	and jcmp_pm.udEmployee=ddup_pm.Employee left outer join
	JCCP jccp on
		jcch.JCCo=jccp.JCCo
	and jcch.Job=jccp.Job
	and jcch.PhaseGroup=jccp.PhaseGroup
	and jcch.Phase=jccp.Phase
	and jcch.CostType=jccp.CostType
	and jccp.Mth <= @ProjectionMonth
where
	jcjm.JCCo<100
and	( jcjm.JCCo = @JCCo	or @JCCo is null )
and ( jcjm.Contract=@Contract or @Contract is null )
and ( jcjm.Job=@Job or @Job is null )
go


--declare @JCCo bCompany
--declare @Contract bContract
--declare @Job bJob
--declare @ProjectionMonth bMonth

--select
--	@JCCo = null
--,	@Contract = ' 14345-'
--,	@Job= null --' 14345-001'
--,	@ProjectionMonth = '12/31/2015'

--if @ProjectionMonth is null
--	select @ProjectionMonth = max(Month) from JCOR where JCCo=@JCCo and ( Contract=@Contract or @Contract is null ) group by JCCo, Contract

if exists ( select 1 from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mfnContractProjectPhaseCostTypeProjectionSum' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION mers.mfnContractProjectPhaseCostTypeProjectionSum'
	DROP FUNCTION mers.mfnContractProjectPhaseCostTypeProjectionSum
end
go

print 'CREATE FUNCTION mers.mfnContractProjectPhaseCostTypeProjectionSum'
go

create function mers.mfnContractProjectPhaseCostTypeProjectionSum
(
	@JCCo				bCompany
,	@Contract			bContract
,	@Job				bJob
,	@ProjectionMonth	bMonth
)
/*

2016.04.12 - LWO -	Created as baseline for "Prophecy" ETC/LRF VSTO Solution
					Returns 'table' of Project/Job Phase CostTypes for Projects/Jobs Phases for Projects/Jobs  associated to specified Contract

					declare @JCCo bCompany
					declare @Contract bContract
					declare @Job	bJob 
					declare @ProjectionMonth	bMonth 

					select @JCCo=1, @Contract=' 14345-', @Job = null, @ProjectionMonth='12/1/2012'

					select * from mers.mfnContractProjectPhaseCostTypeProjectionSum(@JCCo, @Contract, @Job, @ProjectionMonth)

*/
returns table as return  -- TODO: Change to explicityly defined return table
select 
--	'ContractProjectPhaseCostTypeProjectionsSum' as DataSetName,
	jcjm.JCCo
,	jcjm.Contract
,	jccm.Description as ContractDesc	
,	jccm.Department as ContractJCDepartment
,	jcdm_contract.Description as ContractJCDepartmentDescription
,	glpi_contract.Instance as ContractGLDepartment
,	glpi_contract.Description as ContractGLDepartmentDescription
,	jccm.udPOC as ContractPOC
,	jcmp_poc.Name as ContractPOCName
,	jcmp_poc.udPRCo as ContractPOCPRCo
,	jcmp_poc.udEmployee as ContractPOCEmployee
,	preh_poc.FullName as ContractPOCFullName
,	preh_poc.ActiveYN as ContractPOCEmployeeActiveYN
,	ddup_poc.VPUserName as ContractPOCUserName
,	jcjm.Job
,	jcjm.Description as JobDesc
,	jcjm.JobStatus as JobStatusId
,	ddci.DisplayValue as JobStatus
,	jcci.Department as JCDepartment
,	jcdm_job.Description as JCDepartmentDescription
,	glpi_job.Instance as GLDepartment
,	glpi_job.Description as GLDepartmentDescription
,	jcjm.ProjectMgr as ProjectMgr
,	jcmp_pm.Name as ProjectMgrName
,	jcmp_pm.udPRCo as ProjectMgrPRCo
,	jcmp_pm.udEmployee as ProjectMgrEmployee
,	preh_pm.FullName as ProjectMgrFullName
,	preh_pm.ActiveYN as ProjectMgrActiveYN
,	ddup_pm.VPUserName as ProjectMgrUserName
,	jcjm.JobPhone	
,	jcjm.JobFax	
,	jcjm.MailAddress	
,	jcjm.MailAddress2	
,	jcjm.MailCity	
,	jcjm.MailState	
,	jcjm.MailZip	
,	jcjm.MailCountry	
,	jcjm.udCRMNum	
,	jcjm.udProjWrkstrm	
,	jcjm.udDateChanged	
,	case when jcjm.udProjStart is null then ( select min(Month) from JCOP where JCOP.JCCo=jcjm.JCCo and JCOP.Job=jcjm.Job  ) else jcjm.udProjStart end as ProjectStartDate
,	case when jcjm.udProjEnd is null then ( select max(Month) from JCOP where JCOP.JCCo=jcjm.JCCo and JCOP.Job=jcjm.Job  ) else jcjm.udProjEnd end as ProjectEndDate
,	datediff(
		month
	,case when jcjm.udProjStart is null then ( select min(Month) from JCOP where JCOP.JCCo=jcjm.JCCo and JCOP.Job=jcjm.Job  ) else jcjm.udProjStart end
	,case when jcjm.udProjEnd is null then ( select max(Month) from JCOP where JCOP.JCCo=jcjm.JCCo and JCOP.Job=jcjm.Job  ) else jcjm.udProjEnd end
	) as ProjectDuration
,	jcjp.Item as ContractItem
,	jcci.Description as ContractItemDesc
,	jcjp.PhaseGroup
,	jcjp.Phase
,	jcjp.Description as JobPhaseDesc
,	jcct.Abbreviation as CostTypeId
,	jcct.Description as CostType
,	jcch.OrigCost
,	jcch.OrigHours
,	jcch.OrigUnits
,	@ProjectionMonth as ThroughMonth --  jccp.Mth
,	sum(jccp.ActualHours) as 	ActualHours
,	sum(jccp.ActualUnits) as ActualUnits	
,	sum(jccp.ActualCost) as 	ActualCost
,	sum(jccp.OrigEstHours) as 	OrigEstHours
,	sum(jccp.OrigEstUnits) as 	OrigEstUnits
,	sum(jccp.OrigEstCost) as 	OrigEstCost
,	sum(jccp.CurrEstHours) as 	CurrEstHours
,	sum(jccp.CurrEstUnits) as 	CurrEstUnits
,	sum(jccp.CurrEstCost) as 	CurrEstCost
,	sum(jccp.ProjHours) as 	ProjHours
,	sum(jccp.ProjUnits) as 	ProjUnits
,	sum(jccp.ProjCost) as 	ProjCost
,	sum(jccp.ForecastHours) as 	ForecastHours
,	sum(jccp.ForecastUnits) as 	ForecastUnits
,	sum(jccp.ForecastCost) as 	ForecastCost
,	sum(jccp.TotalCmtdUnits) as 	TotalCmtdUnits
,	sum(jccp.TotalCmtdCost) as 	TotalCmtdCost
,	sum(jccp.RemainCmtdUnits) as 	RemainCmtdUnits
,	sum(jccp.RemainCmtdCost) as 	RemainCmtdCost
,	sum(jccp.RecvdNotInvcdUnits) as 	RecvdNotInvcdUnits
,	sum(jccp.RecvdNotInvcdCost) as 	RecvdNotInvcdCost
--,	jccp.ProjPlug	
from
	JCJM jcjm left outer join	 
	DDCIShared ddci on
		ddci.ComboType='JCJMJobStatus'
	and	cast(jcjm.JobStatus as varchar(10))=ddci.DatabaseValue left outer join
	JCJP jcjp on
		jcjm.JCCo=jcjp.JCCo
	and jcjm.Job=jcjp.Job left outer join
	JCCH jcch on
		jcjp.JCCo=jcch.JCCo
	and jcjp.Job=jcch.Job
	and jcjp.PhaseGroup=jcch.PhaseGroup
	and jcjp.Phase=jcch.Phase left outer join
	JCCT jcct on
		jcch.PhaseGroup=jcct.PhaseGroup
	and jcch.CostType=jcct.CostType left outer join
	JCCI jcci on
		jcjp.JCCo=jcci.JCCo
	and jcjp.Contract=jcci.Contract
	and jcjp.Item=jcci.Item left outer join
	JCCM jccm on
		jcci.JCCo=jccm.JCCo
	and jcci.Contract=jccm.Contract left outer join
	JCDM jcdm_job on
		jcci.JCCo=jcdm_job.JCCo
	and jcci.Department=jcdm_job.Department left outer join
	GLAC glac_job on
		jcdm_job.GLCo=glac_job.GLCo
	and jcdm_job.OpenRevAcct=glac_job.GLAcct left outer join
	GLPI glpi_job on
		glac_job.GLCo=glpi_job.GLCo
	and glac_job.Part3=glpi_job.Instance
	and glpi_job.PartNo=3 left outer join
	JCDM jcdm_contract on
		jccm.JCCo=jcdm_contract.JCCo
	and jccm.Department=jcdm_contract.Department left outer join
	GLAC glac_contract on
		jcdm_contract.GLCo=glac_contract.GLCo
	and jcdm_contract.OpenRevAcct=glac_contract.GLAcct left outer join
	GLPI glpi_contract on
		glac_contract.GLCo=glpi_contract.GLCo
	and glac_contract.Part3=glpi_contract.Instance
	and glpi_job.PartNo=3 left outer join
	JCMP jcmp_poc on
		jccm.JCCo=jcmp_poc.JCCo
	and jccm.udPOC=jcmp_poc.ProjectMgr left join
	PREHFullName preh_poc on
		jcmp_poc.udPRCo=preh_poc.PRCo
	and jcmp_poc.udEmployee=preh_poc.Employee left join 
	DDUP ddup_poc on
		jcmp_poc.udPRCo=ddup_poc.PRCo
	and jcmp_poc.udEmployee=ddup_poc.Employee left outer join
	JCMP jcmp_pm on
		jccm.JCCo=jcmp_pm.JCCo
	and jccm.udPOC=jcmp_pm.ProjectMgr left join
	PREHFullName preh_pm on
		jcmp_pm.udPRCo=preh_pm.PRCo
	and jcmp_pm.udEmployee=preh_pm.Employee left join 
	DDUP ddup_pm on
		jcmp_pm.udPRCo=ddup_pm.PRCo
	and jcmp_pm.udEmployee=ddup_pm.Employee left outer join
	JCCP jccp on
		jcch.JCCo=jccp.JCCo
	and jcch.Job=jccp.Job
	and jcch.PhaseGroup=jccp.PhaseGroup
	and jcch.Phase=jccp.Phase
	and jcch.CostType=jccp.CostType
	and jccp.Mth <= @ProjectionMonth
where
	jcjm.JCCo<100
and	( jcjm.JCCo = @JCCo	or @JCCo is null )
and ( jcjm.Contract=@Contract or @Contract is null )
and ( jcjm.Job=@Job or @Job is null )
group by
	jcjm.JCCo
,	jcjm.Contract
,	jccm.Description --as ContractDesc	
,	jcjm.Description --as JobDesc
,	jccm.Department --as ContractJCDepartment
,	jcdm_contract.Description --as ContractJCDepartmentDescription
,	glpi_contract.Instance --as ContractGLDepartment
,	glpi_contract.Description --as ContractGLDepartmentDescription
,	jccm.udPOC --as ContractPOC
,	jcmp_poc.Name --as ContractPOCName
,	jcmp_poc.udPRCo --as ContractPOCPRCo
,	jcmp_poc.udEmployee --as ContractPOCEmployee
,	preh_poc.FullName --as ContractPOCFullName
,	preh_poc.ActiveYN --as ContractPOCEmployeeActiveYN
,	ddup_poc.VPUserName --as ContractPOCUserName
,	jcjm.Job
,	jcjm.Description --as JobDesc
,	jcjm.JobStatus --as JobStatusId
,	ddci.DisplayValue --as JobStatus
,	jcci.Department --as JCDepartment
,	jcdm_job.Description --as JCDepartmentDescription
,	glpi_job.Instance --as GLDepartment
,	glpi_job.Description --as GLDepartmentDescription
,	jcjm.ProjectMgr --as ProjectMgr
,	jcmp_pm.Name --as ProjectMgrName
,	jcmp_pm.udPRCo --as ProjectMgrPRCo
,	jcmp_pm.udEmployee --as ProjectMgrEmployee
,	preh_pm.FullName --as ProjectMgrFullName
,	preh_pm.ActiveYN --as ProjectMgrActiveYN
,	ddup_pm.VPUserName --as ProjectMgrUserName
,	jcjm.JobPhone	
,	jcjm.JobFax	
,	jcjm.MailAddress	
,	jcjm.MailAddress2	
,	jcjm.MailCity	
,	jcjm.MailState	
,	jcjm.MailZip	
,	jcjm.MailCountry	
,	jcjm.udCRMNum	
,	jcjm.udProjWrkstrm	
,	jcjm.udDateChanged	
,	jcjm.udProjStart
,	jcjm.udProjEnd
,	jcjp.Item --as ContractItem
,	jcci.Description --as ContractItemDesc
,	jcjp.PhaseGroup
,	jcjp.Phase
,	jcjp.Description --as JobPhaseDesc
,	jcct.Abbreviation --as CostTypeId
,	jcct.Description --as CostType
,	jcch.OrigCost
,	jcch.OrigHours
,	jcch.OrigUnits
go



--declare @JCCo bCompany
--declare @Contract bContract
--declare @Job bJob
--declare @ProjectionMonth bMonth

--select
--	@JCCo = null
--,	@Contract = ' 14345-'
--,	@Job= null --' 14345-001'
--,	@ProjectionMonth = '12/31/2015'

--if @ProjectionMonth is null
--	select @ProjectionMonth = max(Month) from JCOR where JCCo=@JCCo and ( Contract=@Contract or @Contract is null ) group by JCCo, Contract

if exists ( select 1 from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mfnContractProjectPhaseCostTypeProjectionsDetail' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION mers.mfnContractProjectPhaseCostTypeProjectionsDetail'
	DROP FUNCTION mers.mfnContractProjectPhaseCostTypeProjectionsDetail
end
go

print 'CREATE FUNCTION mers.mfnContractProjectPhaseCostTypeProjectionsDetail'
go

create function mers.mfnContractProjectPhaseCostTypeProjectionsDetail
(
	@JCCo				bCompany
,	@Contract			bContract
,	@Job				bJob
,	@ProjectionMonth	bMonth
)
/*

2016.04.12 - LWO -	Created as baseline for "Prophecy" ETC/LRF VSTO Solution
					Returns 'table' of Project/Job Phase CostTypes for Projects/Jobs Phases for Projects/Jobs  associated to specified Contract

					declare @JCCo bCompany
					declare @Contract bContract
					declare @Job	bJob 
					declare @ProjectionMonth	bMonth 

					select @JCCo=1, @Contract=' 14345-', @Job = null, @ProjectionMonth='12/1/2012'

					select * from mers.mfnContractProjectPhaseCostTypeProjectionsDetail(@JCCo, @Contract, @Job, @ProjectionMonth)

*/
returns table as return  -- TODO: Change to explicityly defined return table
select 
--	'ContractProjectPhaseCostTypeProjectionsDetail' as DataSetName,
	@ProjectionMonth as ThroughMonth
,	* 
from 
	JCPR jcpr 
where 	
	jcpr.JCCo<100
and	( jcpr.JCCo = @JCCo	or @JCCo is null )
and ( jcpr.Job in (select distinct Job from JCJM where JCJM.JCCo =jcpr.JCCo and JCJM.Contract=@Contract ) )
and jcpr.Mth <= @ProjectionMonth
go



