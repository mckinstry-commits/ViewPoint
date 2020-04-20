use Viewpoint
go

if exists ( select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mfnContractProjects' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='PROCEDURE' )
begin
	print 'DROP PROCEDURE mers.mfnContractProjects'
	DROP PROCEDURE mers.mfnContractProjects
end
go

print 'CREATE PROCEDURE mers.mfnContractProjects'
go

CREATE FUNCTION [mers].[mfnContractProjects]
(
	@JCCo		bCompany
,	@Contract	bContract
,	@Job		bJob
,	@ProjectionMonth	bMonth
)
-- ========================================================================
-- mers.mspGetRevenueProjectionBatchPivot
-- Author:	Ziebell, Jonathan
-- Create date: 06/21/2016
-- Description:	2016.05.06 - 2016.05.06 - LWO - Created
	/*2016.04.12 - LWO -	Created as baseline for "Prophecy" ETC/LRF VSTO Solution
					Returns 'table' of Projects/Jobs associated to specified Contract

					declare @JCCo bCompany
					declare @Contract bContract
					declare @Job	bJob 
					declare @ProjectionMonth	bMonth 

					select @JCCo=1, @Contract=' 14345-', @Job = null, @ProjectionMonth='12/1/2015'

					select * from mers.mfnContractProjects(@JCCo, @Contract, @Job)
*/
-- Update Hist: USER--------DATE-------DESC-----------
-- ========================================================================

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

GO


