use Viewpoint
go

--Contract Item
if exists ( select 1 from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mfnContractItems' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION mers.mfnContractItems'
	DROP FUNCTION mers.mfnContractItems
end
go

print 'CREATE FUNCTION mers.mfnContractItems'
go

create function mers.mfnContractItems
(
	@JCCo			bCompany
,	@Contract		bContract
)
-- ========================================================================
-- mers.mfnContractItems
-- Author:	Ziebell, Jonathan
-- Create date: 06/21/2016
-- Description:	
-- Update Hist: USER--------DATE-------DESC-----------
-- ========================================================================
returns table as return
select
	contract_header.JCCo
,	contract_header.Contract
,	jcci.Item as ContractItem
,	jcci.Description as ContractItemDescription
,	jcci.Department as JCDepartment
,	jcdm.Description as JCDepartmentDescription
,	glpi.Instance as GLDepartment
,	glpi.Description as GLDepartmentDescription
,	jcci.udPOC as ContractItemPOC
,	jcmp.Name as ContractItemPOCName
,	jcmp.udPRCo as ContractPOCPRCo
,	jcmp.udEmployee as ContractPOCEmployee
,	preh.FullName as ContractPOCFullName
,	preh.ActiveYN as ContractPOCEmployeeActiveYN
,	ddup.VPUserName as ContractPOCUserName
,	jcci.udRevType as RevenueType
,	ddci.DisplayValue as RevnueTypeLabel
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
	mers.mfnContractHeader(@JCCo, @Contract) contract_header join
	JCCI jcci on 
		contract_header.JCCo=jcci.JCCo
	and	contract_header.Contract = jcci.Contract left outer join
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
		jcci.JCCo=jcmp.JCCo
	and jcci.udPOC=jcmp.ProjectMgr left join
	PREHFullName preh on
		jcmp.udPRCo=preh.PRCo
	and jcmp.udEmployee=preh.Employee left join 
	DDUP ddup on
		jcmp.udPRCo=ddup.PRCo
	and jcmp.udEmployee=ddup.Employee left outer join
	DDCIShared ddci on
		ddci.ComboType='RevenueType'
	and	jcci.udRevType=ddci.DatabaseValue left outer join
	udProjDelivery udpd on
		jcci.udProjDelivery=udpd.Code		
go