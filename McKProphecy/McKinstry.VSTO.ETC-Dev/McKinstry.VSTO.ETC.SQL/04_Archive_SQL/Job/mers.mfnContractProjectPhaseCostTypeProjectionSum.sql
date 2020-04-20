use Viewpoint
go

if exists ( select 1 from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mfnContractProjectPhaseCostTypeProjectionSum' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION mers.mfnContractProjectPhaseCostTypeProjectionSum'
	DROP FUNCTION mers.mfnContractProjectPhaseCostTypeProjectionSum
end
go

print 'CREATE FUNCTION mers.mfnContractJobs'
go
CREATE function [mers].[mfnContractProjectPhaseCostTypeProjectionSum]
(
	@JCCo				bCompany
,	@Contract			bContract
,	@Job				bJob
,	@ProjectionMonth	bMonth
)
-- ========================================================================
-- mers.mfnContractProjectPhaseCostTypeProjectionSum
-- Author:	Ziebell, Jonathan
-- Create date: 06/21/2016
-- Description:	
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
-- Update Hist: USER--------DATE-------DESC-----------
-- ========================================================================
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
