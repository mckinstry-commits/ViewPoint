use Viewpoint
go

--Contract Selector List
if exists ( select 1 from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mfnContractSelectorList' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION mers.mfnContractSelectorList'
	DROP FUNCTION mers.mfnContractSelectorList
end
go

print 'CREATE FUNCTION mers.mfnContractSelectorList'
go

create function mers.mfnContractSelectorList
(
	@JCCo			bCompany	= null
,	@SearchString	varchar(30) = null
)
-- ========================================================================
-- mers.mfnContractSelectorList
-- Author:	Ziebell, Jonathan
-- Create date: 06/21/2016
-- Description:	
-- Update Hist: USER--------DATE-------DESC-----------
-- ========================================================================
returns table as return
select
	jccm.JCCo
,	jccm.Contract
,	jccm.Description
,	jcmp.Name as ContractPOC
,	jccm.ContractStatus as ContractStatusId
,	ddci.DisplayValue as ContractStatus
,	glpi.Instance as GLDepartmentId
,	glpi.Description as GLDepartment
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
	and jccm.udPOC=jcmp.ProjectMgr
where
	( jccm.JCCo=@JCCo or @JCCo is null )
and ( 
		jccm.Contract like '%' + @SearchString + '%' 
	or	jccm.Description like '%' + @SearchString + '%' 
	or	jcmp.Name like '%' + @SearchString + '%' 
	or	glpi.Instance like '%' + @SearchString + '%' 
	or	glpi.Description like '%' + @SearchString + '%' 
	or	@SearchString is null 
	)

go
