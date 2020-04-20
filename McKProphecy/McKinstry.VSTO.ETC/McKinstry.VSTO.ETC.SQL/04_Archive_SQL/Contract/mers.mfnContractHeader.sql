USE [ViewpointProphecy]
GO
/****** Object:  UserDefinedFunction [mers].[mfnContractHeader]    Script Date: 8/11/2016 10:33:58 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER function [mers].[mfnContractHeader]
(
	@JCCo			bCompany
,	@Contract		bContract
)
-- ========================================================================
-- mers.mfnContractHeader
-- Author:	Ziebell, Jonathan
-- Create date: 06/21/2016
-- Description:	
-- Update Hist: USER--------DATE-------DESC-----------
-- ========================================================================
returns table as return
select
	jccm.JCCo
,	jccm.Contract
,	jccm.Description as ContractDescription
,	jccm.ContractStatus as ContractStatusId
,	ddci.DisplayValue as ContractStatus
,	jcdm.Department as JCDepartmentId
,	jcdm.Description as JCDepartment
,	glpi.Instance as GLDepartmentId
,	glpi.Description as GLDepartment
,	jccm.udPOC as ContractPOC
,	jcmp.Name as ContractPOCName
,	jcmp.udPRCo as ContractPOCPRCo
,	jcmp.udEmployee as ContractPOCEmployee
,	preh.FullName as ContractPOCFullName
,	preh.ActiveYN as ContractPOCEmployeeActiveYN
,	ddup.VPUserName as ContractPOCUserName
,	jccm.StartDate as ContractStartDate
,	jccm.ProjCloseDate as ContractProjectedCloseDate
,	jccm.ActualCloseDate as ContractActualCloseDate
from
	JCCM jccm join
	HQCO hqco on
		jccm.JCCo=hqco.HQCo
	and ( hqco.udTESTCo<>'Y' or hqco.udTESTCo is null ) join
	DDCIShared ddci on
		jccm.ContractStatus=ddci.DatabaseValue
	and ddci.ComboType='JCContractStatus' join
	JCDM jcdm on
		jccm.JCCo=jcdm.JCCo
	and jccm.Department=jcdm.Department join
	GLAC glac on
		jcdm.GLCo=glac.GLCo
	and jcdm.OpenRevAcct=glac.GLAcct join
	GLPI glpi on
		glac.GLCo=glpi.GLCo
	and glac.Part3=glpi.Instance
	and glpi.PartNo=3 join
	JCMP jcmp on
		jccm.JCCo=jcmp.JCCo
	and jccm.udPOC=jcmp.ProjectMgr left join
	PREHFullName preh on
		jcmp.udPRCo=preh.PRCo
	and jcmp.udEmployee=preh.Employee left join
	DDUP ddup on
		jcmp.udPRCo=ddup.PRCo
	and jcmp.udEmployee=ddup.Employee
where
	jccm.JCCo=@JCCo
and jccm.Contract=@Contract
