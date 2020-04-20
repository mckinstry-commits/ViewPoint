use Viewpoint
go

if exists ( select 1 from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mfnProjectHeaderDtl' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION mers.mfnProjectHeaderDtl'
	DROP FUNCTION mers.mfnProjectHeaderDtl
end
go

print 'CREATE FUNCTION mers.mfnProjectHeaderDtl'
go

/****** Object:  UserDefinedFunction [mers].[mfnProjectHeaderDtl]    Script Date: 6/10/2016 9:29:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE function [mers].[mfnProjectHeaderDtl]
(
	@JCCo				bCompany
,	@Contract			bContract
,	@Job				bJob
)
-- ========================================================================
-- mers.mfnProjectHeaderDtl
-- Author:		Ziebell, Jonathan
-- Create date: 06/21/2016
-- Description:	Select Project Header Detail
-- Update Hist: USER--------DATE-------DESC-----------
--				J.Ziebell   6/10/2016  Limit to Header Information
-- ========================================================================

returns table as return  -- TODO: Change to explicityly defined return table
select 
	jcjm.JCCo
,	jcjm.Contract
,	jccm.Description as ContractDesc
,	jcci.Item as ContractItem
,	jcci.Description as ContractItemDesc	
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
,	case when jcjm.udProjStart is null then ( select min(Month) from JCOP where JCOP.JCCo=jcjm.JCCo and JCOP.Job=jcjm.Job  ) else jcjm.udProjStart end as ProjectStartDate
,	case when jcjm.udProjEnd is null then ( select max(Month) from JCOP where JCOP.JCCo=jcjm.JCCo and JCOP.Job=jcjm.Job  ) else jcjm.udProjEnd end as ProjectEndDate
,	datediff(
		month
	,case when jcjm.udProjStart is null then ( select min(Month) from JCOP where JCOP.JCCo=jcjm.JCCo and JCOP.Job=jcjm.Job  ) else jcjm.udProjStart end
	,case when jcjm.udProjEnd is null then ( select max(Month) from JCOP where JCOP.JCCo=jcjm.JCCo and JCOP.Job=jcjm.Job  ) else jcjm.udProjEnd end
	) as ProjectDuration
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
FROM JCJM jcjm 
	LEFT OUTER JOIN	DDCIShared ddci 
		ON ddci.ComboType='JCJMJobStatus'
		AND	cast(jcjm.JobStatus as varchar(10))=ddci.DatabaseValue 
	LEFT OUTER JOIN	JCCM jccm on
		jcjm.JCCo=jccm.JCCo
		AND jcjm.Contract=jccm.Contract 
	LEFT OUTER JOIN JCCI jcci 
		ON jcjm.JCCo=jcci.JCCo
		AND jcjm.Contract=jcci.Contract
		AND EXISTS(Select 'x' from JCJP jcjp
					where jcjm.Job = jcjp.Job
					AND jcjm.JCCo = jcjp.JCCo
					AND jcjp.Item = jcci.Item)
	LEFT OUTER JOIN	JCDM jcdm_job 
		ON jcjm.JCCo=jcdm_job.JCCo
		AND jcci.Department=jcdm_job.Department 
	LEFT OUTER JOIN	GLAC glac_job 
		ON jcdm_job.GLCo=glac_job.GLCo
		AND jcdm_job.OpenRevAcct=glac_job.GLAcct 
	LEFT OUTER JOIN	GLPI glpi_job 
		ON glac_job.GLCo=glpi_job.GLCo
		and glac_job.Part3=glpi_job.Instance
		and glpi_job.PartNo=3 
	LEFT OUTER JOIN	JCDM jcdm_contract 
		ON jccm.JCCo=jcdm_contract.JCCo
		AND jccm.Department=jcdm_contract.Department 
	LEFT OUTER JOIN	GLAC glac_contract 
		ON jcdm_contract.GLCo=glac_contract.GLCo
		AND jcdm_contract.OpenRevAcct=glac_contract.GLAcct 
	LEFT OUTER JOIN	GLPI glpi_contract 
		ON glac_contract.GLCo=glpi_contract.GLCo
		AND glac_contract.Part3=glpi_contract.Instance
		AND glpi_job.PartNo=3 
	LEFT OUTER JOIN	JCMP jcmp_poc 
		ON jccm.JCCo=jcmp_poc.JCCo
		AND jccm.udPOC=jcmp_poc.ProjectMgr 
	LEFT JOIN PREHFullName preh_poc 
		ON jcmp_poc.udPRCo=preh_poc.PRCo
		AND jcmp_poc.udEmployee=preh_poc.Employee 
	LEFT JOIN DDUP ddup_poc 
		ON jcmp_poc.udPRCo=ddup_poc.PRCo
		AND jcmp_poc.udEmployee=ddup_poc.Employee 
	LEFT OUTER JOIN	JCMP jcmp_pm 
		ON jccm.JCCo=jcmp_pm.JCCo
		AND jccm.udPOC=jcmp_pm.ProjectMgr 
	LEFT JOIN PREHFullName preh_pm 
		ON jcmp_pm.udPRCo=preh_pm.PRCo
		AND jcmp_pm.udEmployee=preh_pm.Employee 
	LEFT JOIN DDUP ddup_pm 
		ON jcmp_pm.udPRCo=ddup_pm.PRCo
		AND jcmp_pm.udEmployee=ddup_pm.Employee 
WHERE jcjm.JCCo<100
	AND	( jcjm.JCCo = @JCCo	or @JCCo is null )
	AND ( jcjm.Contract=@Contract or @Contract is null )
	AND ( jcjm.Job=@Job or @Job is null )
