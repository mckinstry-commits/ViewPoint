use Viewpoint
go

if exists (select 1 from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mfnSLSubcontractorList' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='FUNCTION')
begin
	print 'DROP FUNCTION [dbo].[mfnSLSubcontractorList]'
	drop function [dbo].[mfnSLSubcontractorList] 
end
go

print 'CREATE FUNCTION  [dbo].[mfnSLSubcontractorList]'
go

create function [dbo].[mfnSLSubcontractorList]
(
	@SL varchar(30) = null
,	@Contract bContract = null
)
returns table

as

return
--set @SL = null --'100136-001001' --'10166-001005'

select 
	'Subcontract' as Type
,	slhd.SLCo
,	slhd.SL
,	slhd.Description
,	slhd.Notes as Details
,	cast(slhd.Status as varchar(10)) as Status
,	case slhd.Status
		when 0 then '0 - Open'
		when 1 then '1 - Complete'
		when 2 then '2 - Closed'
		when 3 then '3 - Pending'
		else '? - Unknown'
	end as SLStatus
,	slhd.HoldCode
,	slhd.Vendor
,	apvm.Name as VendorName
,	apvm.Address
,	apvm.Address2
,	apvm.City
,	apvm.State
,	apvm.Zip
,	apvm.Contact
,	apvm.Phone
,	apvm.EMail
,	apvm.URL
,	apvm.MasterVendor
,	jcjm.JCCo
,	jccm.Contract
,	jccm.Description as ContractName
,	poc.Name as POC
,	jcjm.Job
,	jcjm.Description as JobName
,	jcmp.Name as ProjectManager
,	glpi.Instance as GLDepartment
,	glpi.Description as GLDepartmentName
,	slhd.Approved as ApprovedOrAcctReady
,	slhd.ApprovedBy
,	slhd.udDocStatus
,	slhd.udPerfBondYN
,	slit.InterfaceDate
,	slhd.UniqueAttchID
,	@@SERVERNAME as Source
,	db_name() as DBName
,	getdate() as ProcessDate
from 
	HQCO hqco join
	SLHD slhd on
		hqco.HQCo=slhd.SLCo
	and hqco.udTESTCo <> 'Y' 
	and slhd.Status not in (1,2) left join
	SLITPM slit on
		slhd.SLCo=slit.SLCo
	and slhd.SL=slit.SL
	and slit.SubCO is null left join
	JCJM jcjm on
		slhd.JCCo=jcjm.JCCo
	and slhd.Job=jcjm.Job left join
	JCCM jccm on
		jcjm.JCCo=jccm.JCCo
	and jcjm.Contract=jccm.Contract left join
	JCMP poc on
		jccm.JCCo=poc.JCCo
	and jccm.udPOC=poc.ProjectMgr left join
	JCMP jcmp on
		jcjm.JCCo=jcmp.JCCo
	and jcjm.ProjectMgr=jcmp.ProjectMgr left join
	APVM apvm on
		slhd.VendorGroup=apvm.VendorGroup
	and slhd.Vendor=apvm.Vendor left join
	JCDM jcdm on
		jccm.JCCo=jcdm.JCCo
	and jccm.Department=jcdm.Department left join
	GLPI glpi on
		jcdm.GLCo=glpi.GLCo
	and glpi.PartNo=3
	and glpi.Instance=substring(jcdm.OpenRevAcct,10,4) 
where
	(slhd.SL=@SL or @SL is null)
and (jccm.Contract= @Contract or @Contract is null)
go


print 'GRANT SELECT ON [dbo].[mfnSLSubcontractorList] TO [public, Viewpoint]'
print ''
go

grant select on [dbo].[mfnSLSubcontractorList] to public
go

grant select on [dbo].[mfnSLSubcontractorList] to Viewpoint
go


select
	*
from
	[dbo].[mfnSLSubcontractorList](null,null)

