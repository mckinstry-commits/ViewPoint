use Viewpoint
go

if exists (select 1 from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mfnSLComplianceAudit' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='FUNCTION')
begin
	print 'DROP FUNCTION [dbo].[mfnSLComplianceAudit]'
	drop function [dbo].[mfnSLComplianceAudit] 
end
go

print 'CREATE FUNCTION  [dbo].[mfnSLComplianceAudit]'
go

create function [dbo].[mfnSLComplianceAudit]
(
	@ExpirationDate smalldatetime = null
,	@JobNumber	varchar(50) = null	
,	@SubcontractNumber varchar(50) = null
,	@Contract	varchar(50) = null
,	@Vendor varchar(50) = null
,	@GLDepartment varchar(50) = null
,	@POC_PM		varchar(50) = null
)
returns table

as

return
--set @SL = null --'100136-001001' --'10166-001005'

select 
	* 
,	(
	select 
		count(*) 
	from 
		SLCT slct join
		HQCP hqcp on
			slct.CompCode=hqcp.CompCode
	where
		slct.SLCo=slcounion.SLCo
	and slct.SL=slcounion.Subcontract
) as SLComplianceRecordCount
--,	(
--	select 
--		count(*)
--	from
--		HQAT hqat join
--		HQAI hqai on
--			hqat.AttachmentID=hqai.AttachmentID
--	where
--		hqat.UniqueAttchID=slcounion.SLUniqueAttchID
--	--or  (hqai.SLCo=@SLCo and hqai.SLSubcontract=@SL)
--) as SLAttachmentCount
--,	(
--	select 
--		count(*)
--	from
--		HQAT hqat join
--		HQAI hqai on
--			hqat.AttachmentID=hqai.AttachmentID
--	where
--		hqat.UniqueAttchID=slcounion.SLComplianceUniqueAttchID
--	--or  (hqai.SLCo=@SLCo and hqai.SLSubcontract=@SL)
--) as SLComlianceAttachmentCount
--,	(
--	select 
--		count(*)
--	from
--		HQAT hqat join
--		HQAI hqai on
--			hqat.AttachmentID=hqai.AttachmentID
--	where
--		hqat.UniqueAttchID=slcounion.SLChangeOrderUniqueAttchID
--	--or  (hqai.SLCo=@SLCo and hqai.SLSubcontract=@SL)
--) as SLChangeOrderAttachmentCount
from
(
select 
	'Subcontract' as Type
,	slhd.SLCo
,	slhd.SL as Subcontract
,	(select case count(*) when 0 then 'N' else 'Y' end from PMSubcontractCO where SLCo=slhd.SLCo and SL=slhd.SL) as ChangeOrdersAssociated
--,	null as SubcontractChangeOrder
,	slhd.KeyID as UniqueRecordNumber
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
,	slhd.VendorGroup
,	slhd.Vendor
,	apvm.Name as VendorName
,	jcjm.JCCo
,	jccm.Contract
,	jccm.Description as ContractName
,	case jccm.ContractStatus
		when 1 then '1 - Open'
		when 2 then '2 - Soft Close'
		when 3 then '3 - Hard Close'
		else '0 - Pending'
	end as ContractStatus
,	poc.Name as POC
,	jcjm.Job
,	jcjm.Description as JobName
--,	jcjm.JobStatus
,	case jcjm.JobStatus
		when 1 then '1 - Open'
		when 2 then '2 - Soft Close'
		when 3 then '3 - Hard Close'
		else '0 - Pending'
	end as JobStatus
,	jcmp.Name as ProjectManager
,	glpi.Instance as GLDepartment
,	glpi.Description as GLDepartmentName
,	slhd.Approved as ApprovedOrAcctReady
,	slhd.ApprovedBy 
,	null as DateApproved
/*
	udDocStatusValues
		Pending
		Sent to Subcontractor
		In Negotiations
		Awaiting McKinstry Signature
		Full Executed
*/
--,	slhd.udDocStatus as DocumentStatus
,	dslu.DisplayValue as EchoSignStatus
,	slhd.udLastStatusChgBy as EchoSignStatusLastUpdatedBy
,	slhd.udLastStatusChgDate as EchoSignStatusLastUpdated
,	slct.CompCode
,	slct.Description as CompDescription
,	hqcp.CompType -- D=Date, F=Yes/No 
,	slct.Complied
,	slct.ExpDate
,	slct.ReceiveDate
,	slct.Verify
,	slit.InterfaceDate
,	slhd.udPerfBondYN as PerfBondYN
,	slhd.UniqueAttchID as SLUniqueAttchID
,	slct.UniqueAttchID as SLComplianceUniqueAttchID
,	cast(null as uniqueidentifier) as SLChangeOrderUniqueAttchID
,	@@SERVERNAME as Source
,	db_name() as DBName
,	getdate() as ProcessDate
from 
	HQCO hqco join
	SLHD slhd on
		hqco.HQCo=slhd.SLCo
	and hqco.udTESTCo <> 'Y' 
	and slhd.Status not in (2) left join
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
	and glpi.Instance=substring(jcdm.OpenRevAcct,10,4) left join
	SLCT slct on
		slhd.SLCo=slct.SLCo
	and slhd.SL=slct.SL left join
	HQCP hqcp on
		slct.CompCode=hqcp.CompCode left join
	DDCIShared dslu on
		slhd.udDocStatus = dslu.DatabaseValue
	and dslu.ComboType='mckSLDocStatus'
	where
		( (slct.ExpDate <= @ExpirationDate) or slct.ExpDate is null or @ExpirationDate is null)

--	and (slhd.Job like '%' + @JobNumber + '%' or @JobNumber is null)
--	and (jccm.Contract like '%' + @Contract + '%' or @Contract is null)
--	and	(slhd.SL=@SubcontractNumber or @SubcontractNumber is null)
--	and (slhd.Vendor=@Vendor or @Vendor is null)
--	and (glpi.Instance like '%' + @GLDepartment + '%' or @GLDepartment is null)

	and ( upper(slhd.Job) like ('%' + coalesce(upper(@JobNumber),'') + '%') or upper(jcjm.Description) like ('%' + coalesce(upper(@JobNumber),'') + '%') or @JobNumber is null ) 		
	and ( upper(jccm.Contract) like ('%' + coalesce(upper(@Contract),'') + '%') or upper(jccm.Description) like ('%' + coalesce(upper(@Contract),'') + '%') or @Contract is null ) 	
	and ( upper(slhd.SL) like ('%' + coalesce(upper(@SubcontractNumber),'') + '%') or upper(slhd.Description) like ('%' + coalesce(upper(@SubcontractNumber),'') + '%') or @SubcontractNumber is null ) 	
	and ( upper(cast(slhd.Vendor as varchar(50))) like ('%' + coalesce(upper(@Vendor),'') + '%') or upper(apvm.Name) like ('%' + coalesce(upper(@Vendor),'') + '%') or @Vendor is null ) 
	and ( upper(glpi.Instance) like ('%' + coalesce(upper(@GLDepartment),'') + '%') or upper(glpi.Description) like ('%' + coalesce(upper(@GLDepartment),'') + '%') or @GLDepartment is null ) 
	and ( upper(poc.Name) like ('%' + coalesce(upper(@POC_PM),'') + '%') or upper(jcmp.Name) like ('%' + coalesce(upper(@POC_PM),'') + '%') or @POC_PM is null ) 

-- Eliminating Change Orders from Report since compliance is really on at the Subcontract level
/*
union
--Change Orders
select
	'Subcontract CO' as Type 
,	slco.SLCo
,	slco.SL as Subcontract
,	slco.SubCO as SubcontractChangeOrder
,	slco.KeyID as UniqueRecordNumber
,	slco.Description
,	slco.Details
,	slco.Status
,	case slhd.Status
		when 0 then '0 - Open' 
		when 1 then '1 - Complete'
		when 2 then '2 - Closed'
		when 3 then '3 - Pending'
		else '? - Unknown'
	end +  ' (' + slco.Status + ')' as SLStatus
,	slhd.HoldCode
,	slhd.Vendor
,	apvm.Name as VendorName
,	jcjm.JCCo
,	jccm.Contract
,	jccm.Description as ContractName
,	case jccm.ContractStatus
		when 1 then '1-Open'
		when 2 then '2-Soft Close'
		when 3 then '3-Hard Close'
		else '0-Pending'
	end as ContractStatus
,	poc.Name as POC
,	jcjm.Job
,	jcjm.Description as JobName
,	case jcjm.JobStatus
		when 1 then '1-Open'
		when 2 then '2-Soft Close'
		when 3 then '3-Hard Close'
		else '0-Pending'
	end as JobStatus
,	jcmp.Name as ProjectManager
,	glpi.Instance as GLDepartment
,	glpi.Description as GLDepartmentName
,	slco.ReadyForAcctg as ApprovedOrAcctReady
,	slhd.ApprovedBy
,	slco.DateApproved
/*
	udDocStatusValues
		Pending
		Sent to Subcontractor
		In Negotiations
		Awaiting McKinstry Signature
		Full Executed
*/
--,	slco.udDocStatus as EchoSignStatus
,	dslu.DisplayValue as EchoSignStatus
,	slco.udLastStatusChgBy as EchoSignStatusLastUpdatedBy
,	slco.udLastStatusChgDate as EchoSignStatusLastUpdated
,	null as CompCode --slct.CompCode
,	null as CompDescription --slct.Description as CompDescription
,	null as CompType
,	null as Complied
,	null as ExpDaet --slct.ExpDate
,	slco.DateReceived as ReceiveDate
,	null as Verify 
,	slit.InterfaceDate
,	slhd.udPerfBondYN as PerfBondYN
,	slhd.UniqueAttchID as SLUniqueAttchID
,	null as SLComplianceUniqueAttchID
,	slco.UniqueAttchID as SLChangeOrderUniqueAttchID
,	@@SERVERNAME as Source
,	db_name() as DBName
,	getdate() as ProcessDate
from 
	HQCO hqco join
	PMSubcontractCO slco on
		hqco.HQCo=slco.SLCo
	and hqco.udTESTCo <> 'Y' left join
	SLHD slhd on
		slco.SLCo=slhd.SLCo
	and slco.SL=slhd.SL 
	and slhd.Status not in (2)  left join
	SLITPM slit on
		slhd.SLCo=slit.SLCo
	and slhd.SL=slit.SL
	and slco.SubCO=slit.SubCO left join
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
	and glpi.Instance=substring(jcdm.OpenRevAcct,10,4) left join
		DDCIShared dslu on
		slco.udDocStatus = dslu.DatabaseValue
	and dslu.ComboType='mckSLDocStatus'

	where
		/*( (slct.ExpDate <= @ExpirationDate) or @ExpirationDate is null)
	and */ 
		(slhd.Job like '%' + @JobNumber + '%' or @JobNumber is null)
	and (jccm.Contract like '%' + @Contract + '%' or @Contract is null)
	and	(slhd.SL=@SubcontractNumber or @SubcontractNumber is null)
	and (slhd.Vendor=@Vendor or @Vendor is null)
	and (glpi.Instance like '%' + @GLDepartment + '%' or @GLDepartment is null)
	and (
		(upper(poc.Name) like ('%' + coalesce(upper(@POC_PM),'') + '%') or @POC_PM is null)
	or	(upper(jcmp.Name) like ('%' + coalesce(upper(@POC_PM),'') + '%') or @POC_PM is null)

		)
*/
--	SLCT slct on
--		slhd.SLCo=slct.SLCo
--	and slhd.SL=slct.SL
)  slcounion
--where
--	(SL=@SL or @SL is null)
go


print 'GRANT SELECT ON [dbo].[mfnSLComplianceAudit] TO [public, Viewpoint]'
print ''
go

grant select on [dbo].[mfnSLComplianceAudit] to public
go

grant select on [dbo].[mfnSLComplianceAudit] to Viewpoint
go

select * from [dbo].[mfnSLComplianceAudit](null,null,null,null,null,null,null)


if exists (select 1 from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mfnSLComplianceAuditReport' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='FUNCTION')
begin
	print 'DROP FUNCTION [dbo].[mfnSLComplianceAuditReport]'
	drop function [dbo].[mfnSLComplianceAuditReport] 
end
go

print 'CREATE FUNCTION  [dbo].[mfnSLComplianceAuditReport]'
go

create function [dbo].[mfnSLComplianceAuditReport]
(
	@ExpirationDate smalldatetime = null
,	@JobNumber	varchar(50) = null	
,	@SubcontractNumber varchar(50) = null
,	@Contract	varchar(50) = null
,	@Vendor varchar(50) = null
,	@GLDepartment varchar(50) = null
,	@POC_PM		varchar(50) = null
)
returns table

as

return

select 
	[Type]
,	(
	   ( case when CompType='D' and SLComplianceRecordCount > 0  and ExpDate <= cast(getdate() as smalldatetime) then '[Expired] ' else '' end ) 
	+  ( case when CompType='D' and SLComplianceRecordCount > 0  and ExpDate <= @ExpirationDate and ExpDate > cast(getdate() as smalldatetime) then '[Expires By Date Selected] ' else '' end ) 
	+  ( case when CompType='D' and SLComplianceRecordCount > 0 and ExpDate is null then '[Expiration Date Missing] ' else '' end ) 
	+  ( case when CompType='D' and SLComplianceRecordCount > 0 and ExpDate > cast(getdate() as smalldatetime) and (EchoSignStatus <> '5-Fully Executed' or EchoSignStatus is null) then '[Missing Executed Doc Status] ' else '' end ) 
	+  ( case when CompType = 'F' and SLComplianceRecordCount > 0 and Complied<>'Y' then '[Missing Compliance Documents]' else '' end )
	+  ( case when CompType = 'F' and SLComplianceRecordCount > 0 and Complied='Y' and (EchoSignStatus <> '5-Fully Executed' or EchoSignStatus is null) then '[Missing Executed Doc Status]' else '' end )
	-- 2015.08.21 - LWO - Excluding Change Orders from "Compliance Evaluation"
--	+  ( case when (CompType = null or CompType = '' or SubcontractChangeOrder is not null) and ApprovedOrAcctReady='Y' and ( DocumentStatus <> '5-Fully Executed' ) then '[CO Missing Executed Doc Status] ' else '' end )	
	+  ( case when ( /* SubcontractChangeOrder is null and */ SLComplianceRecordCount = 0 ) then '[Missing Compliance Codes]' else '' end ) 
	+  ( case when	( /* SubcontractChangeOrder is null and */ PerfBondYN='Y' and (select count(*) from SLCT slct where slct.SLCo=SLCo and slct.SL=Subcontract and ( upper(slct.CompCode) like ('%BOND%') )) = 0 ) then '[Missing Bond Compliance] ' else '' end ) 
	)
	as ReasonNotes
,	SLCo
,	GLDepartment
,	GLDepartmentName
,	Job
,	JobName
,	JobStatus
,	POC
,	ProjectManager
,	Subcontract
,	ChangeOrdersAssociated
,	UniqueRecordNumber
,	'n/a' as RequestDocDate
,	SLStatus
/*
	udDocStatusValues
		Pending
		Sent to Subcontractor
		In Negotiations
		Awaiting McKinstry Signature
		Full Executed
*/
,	EchoSignStatus
,	EchoSignStatusLastUpdatedBy
,	EchoSignStatusLastUpdated
,	InterfaceDate
,	VendorGroup
,	Vendor
,	VendorName
,	HoldCode
,	CompCode
,	CompType
,	CompDescription
,	ReceiveDate
,	Complied
,	ExpDate
,	PerfBondYN
,	SLComplianceRecordCount
--,	SLAttachmentCount
--,	SLComlianceAttachmentCount
--,	SLChangeOrderAttachmentCount
,	ApprovedOrAcctReady
,	ApprovedBy
from 
	dbo.mfnSLComplianceAudit(@ExpirationDate,@JobNumber,@SubcontractNumber,@Contract,@Vendor,@GLDepartment,@POC_PM)
--where
--	( CompType = 'D' and SLComplianceRecordCount > 0 and (ExpDate <= @ExpirationDate or ExpDate <= getdate() or @ExpirationDate is null))
--or  ( CompType = 'F' and SLComplianceRecordCount > 0 and (ReceiveDate is null or Complied<>'Y') )
----  Need test for CO's to verify compliance
--or  ( SLComplianceRecordCount = 0 )
--or  ( PerfBondYN='Y' and 
--		(
--			select 
--				count(*) 
--			from 
--				SLCT slct join
--				HQCP hqcp on
--					slct.CompCode=hqcp.CompCode
--			where
--				slct.SLCo=SLCo
--			and slct.SL=Subcontract
--			and slct.CompCode in ('BOND-RET','Bond-Pay','Bond-Perf')
--		) <> 3
--	)
go

print 'GRANT SELECT ON [dbo].[mfnSLComplianceReport] TO [public, Viewpoint]'
print ''
go

grant select on [dbo].[mfnSLComplianceAuditReport] to public
go

grant select on [dbo].[mfnSLComplianceAuditReport] to Viewpoint
go


declare	@ExpirationDate smalldatetime 
declare	@JobNumber	varchar(50) 
declare	@SubcontractNumber varchar(50) 
declare	@Contract	varchar(50) 
declare	@Vendor varchar(50) 
declare	@GLDepartment varchar(50) 
declare	@POC_PM		varchar(50) 

set	@ExpirationDate		= null
set @JobNumber			= null
set @SubcontractNumber	= null
set	@Contract			= null
set	@Vendor				= null
set	@GLDepartment		= null
set	@POC_PM				= null

select Type,case when ltrim(rtrim(ReasonNotes)) = '' then '[Compliant]' else ReasonNotes end as ReasonNotes,SLCo,GLDepartment,GLDepartmentName,Job,JobName,JobStatus,POC,ProjectManager,Subcontract,ChangeOrdersAssociated,RequestDocDate,SLStatus,EchoSignStatus,EchoSignStatusLastUpdatedBy,EchoSignStatusLastUpdated,InterfaceDate,Vendor,VendorName,HoldCode,CompCode,CompDescription,ReceiveDate,Complied,ExpDate,PerfBondYN,SLComplianceRecordCount,ApprovedOrAcctReady,ApprovedBy,UniqueRecordNumber from dbo.mfnSLComplianceAuditReport(
	@ExpirationDate 
,	@JobNumber	
,	@SubcontractNumber 
,	@Contract	
,	@Vendor 
,	@GLDepartment
,	@POC_PM		
)

-- Date Driven Compliance requires a valid Expritaion Date
-- Non-Date Driven "F" require "Complied" = "Y" or ReceivedDate <= today

/*

declare	@ExpirationDate smalldatetime 
declare	@JobNumber	varchar(50) 
declare	@SubcontractNumber varchar(50) 
declare	@Contract	varchar(50) 
declare	@Vendor varchar(50) 
declare	@GLDepartment varchar(50) 
declare	@POC_PM		varchar(50) 

set	@ExpirationDate		= dateadd(d,30, getdate())
set @JobNumber			= null
set @SubcontractNumber	= null
set	@Contract			= null
set	@Vendor				= null
set	@GLDepartment		= '020[0-9]'
set	@POC_PM				= null

select * from dbo.mfnSLComplianceAuditReport(@ExpirationDate,@JobNumber,@SubcontractNumber,@Contract,@Vendor,@GLDepartment,@POC_PM) where ExpDate > getdate()

*/


--select * from dbo.mfnSLComplianceAuditReport('09/11/2015',null,null,null,null,null,'')



--select * from DDCIShared where ComboType like 'mckSLDocStatus'
--select * from DDCIc where ComboType like 'mckSLDocStatus'

--update DDCIc set DisplayValue = DatabaseValue + '-' + DisplayValue where ComboType like 'mckSLDocStatus'




--declare	@ExpirationDate smalldatetime 
--declare	@JobNumber	varchar(10) 
--declare	@SubcontractNumber varchar(50) 
--declare	@Contract	bContract 
--declare	@Vendor varchar(50) 
--declare	@GLDepartment varchar(10) 
--declare	@POC_PM		varchar(50) 

--set	@ExpirationDate		= dateadd(d,30, getdate())
--set @JobNumber			= null
--set @SubcontractNumber	= null
--set	@Contract			= null
--set	@Vendor				= null
--set	@GLDepartment		= '020[0-9]'
--set	@POC_PM				= null

--select * from dbo.mfnSLComplianceAuditReport(@ExpirationDate,@JobNumber,@SubcontractNumber,@Contract,@Vendor,@GLDepartment,@POC_PM) 


