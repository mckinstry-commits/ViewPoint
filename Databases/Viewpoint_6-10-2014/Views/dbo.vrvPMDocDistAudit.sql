SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE view [dbo].[vrvPMDocDistAudit] as
--PM RFI
select 1 as Sort,p.ProjectMgr,p.JobStatus,d.SourceTableName,d.SourceKeyId,
	s.PMCo,s.Project,d.KeyId,s.UniqueAttchID,'PMDocDistAudit' as FormName
	,f.FirmNumber as SentToFirm,f.FirmName as SentToFirmName,f.VendorGroup,
	c.ContactCode as SentToContact,isnull(c.FirstName,'') + ' ' + isnull(c.LastName,'') as SentToContactName,c.EMail,d.Fax,d.FaxAddress,
	d.Subject,d.CCAddresses,d.bCCAddresses,d.CreatedDateTime,d.CreatedBy,d.Printed,d.Emailed,d.Faxed
	,case when exists(select 1 from PMHF where PMHIKeyId = d.KeyId) then 'Y' else 'N' end Attachments
	,t.DocCategory,t.DocType,'RFI' as DocTypeDesc,dbo.vfToString(s.RFI) as Document,null as Revision
from PMRI s 
	join PMHI d on s.KeyID = d.SourceKeyId and d.SourceTableName in ('PMRI')
	join JCJMPM p on s.PMCo = p.PMCo and s.Project = p.Project
	left join PMFM f on d.VendorGroup = f.VendorGroup and d.SentToFirm = f.FirmNumber
	left join PMPM c on d.VendorGroup = c.VendorGroup and d.SentToFirm = c.FirmNumber and d.SentToContact = c.ContactCode
	left join PMDT t on t.DocType = s.RFIType
union all
--PM Transmittals
select 2 as Sort,p.ProjectMgr,p.JobStatus,d.SourceTableName,d.SourceKeyId,
	s.PMCo,s.Project,d.KeyId,s.UniqueAttchID,'PMDocDistAudit' as FormName
	,f.FirmNumber as SentToFirm,f.FirmName as SentToFirmName,f.VendorGroup,
	c.ContactCode as SentToContact,isnull(c.FirstName,'') + ' ' + isnull(c.LastName,'') as SentToContactName,c.EMail,d.Fax,d.FaxAddress,
	d.Subject,d.CCAddresses,d.bCCAddresses,d.CreatedDateTime,d.CreatedBy,d.Printed,d.Emailed,d.Faxed
	,case when exists(select 1 from PMHF where PMHIKeyId = d.KeyId) then 'Y' else 'N' end Attachments
	,t.DocCategory,t.DocType,'Transmittal' as DocTypeDesc,dbo.vfToString(s.Transmittal) as Document,null as Revision
from PMTM s 
	join PMHI d on s.KeyID = d.SourceKeyId and d.SourceTableName in ('PMTM')
	join JCJMPM p on s.PMCo = p.PMCo and s.Project = p.Project
	left join PMFM f on d.VendorGroup = f.VendorGroup and d.SentToFirm = f.FirmNumber
	left join PMPM c on d.VendorGroup = c.VendorGroup and d.SentToFirm = c.FirmNumber and d.SentToContact = c.ContactCode
	left join PMDT t on t.DocType = s.DocType
union all
-- PM Submittal old
select 3 as Sort,p.ProjectMgr,p.JobStatus,d.SourceTableName,d.SourceKeyId,
	s.PMCo,s.Project,d.KeyId,s.UniqueAttchID,'PMDocDistAudit' as FormName
	,f.FirmNumber as SentToFirm,f.FirmName as SentToFirmName,f.VendorGroup,
	c.ContactCode as SentToContact,isnull(c.FirstName,'') + ' ' + isnull(c.LastName,'') as SentToContactName,c.EMail,d.Fax,d.FaxAddress,
	d.Subject,d.CCAddresses,d.bCCAddresses,d.CreatedDateTime,d.CreatedBy,d.Printed,d.Emailed,d.Faxed
	,case when exists(select 1 from PMHF where PMHIKeyId = d.KeyId) then 'Y' else 'N' end Attachments
	,t.DocCategory,t.DocType,'Submittal' as DocTypeDesc,dbo.vfToString(s.Submittal) as Document,dbo.vfToString(s.Rev) as Revision
from PMSM s 
	join PMHI d on s.KeyID = d.SourceKeyId and d.SourceTableName in ('PMSM')
	join JCJMPM p on s.PMCo = p.PMCo and s.Project = p.Project
	left join PMFM f on d.VendorGroup = f.VendorGroup and d.SentToFirm = f.FirmNumber
	left join PMPM c on d.VendorGroup = c.VendorGroup and d.SentToFirm = c.FirmNumber and d.SentToContact = c.ContactCode
	left join PMDT t on t.DocType = s.SubmittalType
union all
--PM Other Docs
select 4 as Sort,p.ProjectMgr,p.JobStatus,d.SourceTableName,d.SourceKeyId,
	s.PMCo,s.Project,d.KeyId,s.UniqueAttchID,'PMDocDistAudit' as FormName
	,f.FirmNumber as SentToFirm,f.FirmName as SentToFirmName,f.VendorGroup,
	c.ContactCode as SentToContact,isnull(c.FirstName,'') + ' ' + isnull(c.LastName,'') as SentToContactName,c.EMail,d.Fax,d.FaxAddress,
	d.Subject,d.CCAddresses,d.bCCAddresses,d.CreatedDateTime,d.CreatedBy,d.Printed,d.Emailed,d.Faxed
	,case when exists(select 1 from PMHF where PMHIKeyId = d.KeyId) then 'Y' else 'N' end Attachments
	,t.DocCategory,t.DocType,'Other Documents' as DocTypeDesc,s.Document as Document,null as Revision
from PMOD s 
	join PMHI d on s.KeyID = d.SourceKeyId and d.SourceTableName in ('PMOD')
	join JCJMPM p on s.PMCo = p.PMCo and s.Project = p.Project
	left join PMFM f on d.VendorGroup = f.VendorGroup and d.SentToFirm = f.FirmNumber
	left join PMPM c on d.VendorGroup = c.VendorGroup and d.SentToFirm = c.FirmNumber and d.SentToContact = c.ContactCode
	left join PMDT t on t.DocType = s.DocType
union all
--RFQs old
select 5 as Sort,p.ProjectMgr,p.JobStatus,d.SourceTableName,d.SourceKeyId,
	s.PMCo,s.Project,d.KeyId,s.UniqueAttchID,'PMDocDistAudit' as FormName
	,f.FirmNumber as SentToFirm,f.FirmName as SentToFirmName,f.VendorGroup,
	c.ContactCode as SentToContact,isnull(c.FirstName,'') + ' ' + isnull(c.LastName,'') as SentToContactName,c.EMail,d.Fax,d.FaxAddress,
	d.Subject,d.CCAddresses,d.bCCAddresses,d.CreatedDateTime,d.CreatedBy,d.Printed,d.Emailed,d.Faxed
	,case when exists(select 1 from PMHF where PMHIKeyId = d.KeyId) then 'Y' else 'N' end Attachments
	,t.DocCategory,t.DocType,'Request For Quotes' as DocTypeDesc,dbo.vfToString(s.RFQ) as Document,null as Revision
from PMRQ s 
	join PMHI d on s.KeyID = d.SourceKeyId and d.SourceTableName in ('PMRQ')
	join JCJMPM p on s.PMCo = p.PMCo and s.Project = p.Project
	left join PMFM f on d.VendorGroup = f.VendorGroup and d.SentToFirm = f.FirmNumber
	left join PMPM c on d.VendorGroup = c.VendorGroup and d.SentToFirm = c.FirmNumber and d.SentToContact = c.ContactCode
	left join PMDT t on t.DocType = s.PCOType
union all
--Subcontract Emails
select 6 as Sort,p.ProjectMgr,p.JobStatus,d.SourceTableName,d.SourceKeyId,
	s.PMCo,s.Project,d.KeyId,s.UniqueAttchID,'PMDocDistAudit' as FormName
	,f.FirmNumber as SentToFirm,f.FirmName as SentToFirmName,f.VendorGroup,
	c.ContactCode as SentToContact,isnull(c.FirstName,'') + ' ' + isnull(c.LastName,'') as SentToContactName,c.EMail,d.Fax,d.FaxAddress,
	d.Subject,d.CCAddresses,d.bCCAddresses,d.CreatedDateTime,d.CreatedBy,d.Printed,d.Emailed,d.Faxed
	,case when exists(select 1 from PMHF where PMHIKeyId = d.KeyId) then 'Y' else 'N' end Attachments
	,t.DocCategory,t.DocType,'Subcontracts' as DocTypeDesc,s.SL as Document,null as Revision
from SLHDPM s 
	join PMHI d on s.KeyID = d.SourceKeyId and d.SourceTableName in ('SLHDPM','SLHD')
	join JCJMPM p on s.PMCo = p.PMCo and s.Project = p.Project
	left join PMFM f on d.VendorGroup = f.VendorGroup and d.SentToFirm = f.FirmNumber
	left join PMPM c on d.VendorGroup = c.VendorGroup and d.SentToFirm = c.FirmNumber and d.SentToContact = c.ContactCode
	left join PMDT t on t.DocType = s.DocType
union all
--PM PCOs
select  7 as Sort,p.ProjectMgr,p.JobStatus,d.SourceTableName,d.SourceKeyId,
	s.PMCo,s.Project,d.KeyId,s.UniqueAttchID,'PMDocDistAudit' as FormName
	,f.FirmNumber as SentToFirm,f.FirmName as SentToFirmName,f.VendorGroup,
	c.ContactCode as SentToContact,isnull(c.FirstName,'') + ' ' + isnull(c.LastName,'') as SentToContactName,c.EMail,d.Fax,d.FaxAddress,
	d.Subject,d.CCAddresses,d.bCCAddresses,d.CreatedDateTime,d.CreatedBy,d.Printed,d.Emailed,d.Faxed
	,case when exists(select 1 from PMHF where PMHIKeyId = d.KeyId) then 'Y' else 'N' end Attachments
	,t.DocCategory,t.DocType,'Pending Change Orders' as DocTypeDesc,s.PCO as Document,null as Revision
from PMOP s 
	join PMHI d on s.KeyID = d.SourceKeyId and d.SourceTableName in ('PMOP')
	join JCJMPM p on s.PMCo = p.PMCo and s.Project = p.Project
	left join PMFM f on d.VendorGroup = f.VendorGroup and d.SentToFirm = f.FirmNumber
	left join PMPM c on d.VendorGroup = c.VendorGroup and d.SentToFirm = c.FirmNumber and d.SentToContact = c.ContactCode
	left join PMDT t on t.DocType = s.PCOType
union all
--PO Emails
select 8 as Sort,p.ProjectMgr,p.JobStatus,d.SourceTableName,d.SourceKeyId,
	s.PMCo,s.Project,d.KeyId,s.UniqueAttchID,'PMDocDistAudit' as FormName
	,f.FirmNumber as SentToFirm,f.FirmName as SentToFirmName,f.VendorGroup,
	c.ContactCode as SentToContact,isnull(c.FirstName,'') + ' ' + isnull(c.LastName,'') as SentToContactName,c.EMail,d.Fax,d.FaxAddress,
	d.Subject,d.CCAddresses,d.bCCAddresses,d.CreatedDateTime,d.CreatedBy,d.Printed,d.Emailed,d.Faxed
	,case when exists(select 1 from PMHF where PMHIKeyId = d.KeyId) then 'Y' else 'N' end Attachments
	,t.DocCategory,t.DocType,'Purchase Orders' as DocTypeDesc,s.PO as Document,null as Revision
from POHDPM s 
	join PMHI d on s.KeyID = d.SourceKeyId and d.SourceTableName in ('POHDPM','POHD')
	join JCJMPM p on s.PMCo = p.PMCo and s.Project = p.Project
	left join PMFM f on d.VendorGroup = f.VendorGroup and d.SentToFirm = f.FirmNumber
	left join PMPM c on d.VendorGroup = c.VendorGroup and d.SentToFirm = c.FirmNumber and d.SentToContact = c.ContactCode
	left join PMDT t on t.DocType = s.DocType
union all
--Submittal Register
select 9 as Sort,p.ProjectMgr,p.JobStatus,d.SourceTableName,d.SourceKeyId,
	s.PMCo,s.Project,d.KeyId,s.UniqueAttchID,'PMDocDistAudit' as FormName
	,f.FirmNumber as SentToFirm,f.FirmName as SentToFirmName,f.VendorGroup,
	c.ContactCode as SentToContact,isnull(c.FirstName,'') + ' ' + isnull(c.LastName,'') as SentToContactName,c.EMail,d.Fax,d.FaxAddress,
	d.Subject,d.CCAddresses,d.bCCAddresses,d.CreatedDateTime,d.CreatedBy,d.Printed,d.Emailed,d.Faxed
	,case when exists(select 1 from PMHF where PMHIKeyId = d.KeyId) then 'Y' else 'N' end Attachments
	,t.DocCategory,t.DocType,'Submittal' as DocTypeDesc,dbo.vfToString(s.SubmittalNumber) as Document,dbo.vfToString(s.SubmittalRev) as Revision
from PMSubmittal s 
	join PMHI d on s.KeyID = d.SourceKeyId and d.SourceTableName in ('PMSubmittal')
	join JCJMPM p on s.PMCo = p.PMCo and s.Project = p.Project
	left join PMFM f on d.VendorGroup = f.VendorGroup and d.SentToFirm = f.FirmNumber
	left join PMPM c on d.VendorGroup = c.VendorGroup and d.SentToFirm = c.FirmNumber and d.SentToContact = c.ContactCode
	left join PMDT t on t.DocType = s.DocumentType
union all
--Punch lists
select 10 as Sort,p.ProjectMgr,p.JobStatus,d.SourceTableName,d.SourceKeyId,
	s.PMCo,s.Project,d.KeyId,s.UniqueAttchID,'PMDocDistAudit' as FormName
	,f.FirmNumber as SentToFirm,f.FirmName as SentToFirmName,f.VendorGroup,
	c.ContactCode as SentToContact,isnull(c.FirstName,'') + ' ' + isnull(c.LastName,'') as SentToContactName,c.EMail,d.Fax,d.FaxAddress,
	d.Subject,d.CCAddresses,d.bCCAddresses,d.CreatedDateTime,d.CreatedBy,d.Printed,d.Emailed,d.Faxed
	,case when exists(select 1 from PMHF where PMHIKeyId = d.KeyId) then 'Y' else 'N' end Attachments
	,t.DocCategory,t.DocType,'Punch List' as DocTypeDesc,dbo.vfToString(s.PunchList) as Document,null as Revision
from PMPU s 
	join PMHI d on s.KeyID = d.SourceKeyId and d.SourceTableName in ('PMPU')
	join JCJMPM p on s.PMCo = p.PMCo and s.Project = p.Project
	left join PMFM f on d.VendorGroup = f.VendorGroup and d.SentToFirm = f.FirmNumber
	left join PMPM c on d.VendorGroup = c.VendorGroup and d.SentToFirm = c.FirmNumber and d.SentToContact = c.ContactCode
	left join PMDT t on t.DocType = s.DocType
union all
--PM Issues
select 11 as Sort,p.ProjectMgr,p.JobStatus,d.SourceTableName,d.SourceKeyId,
	s.PMCo,s.Project,d.KeyId,s.UniqueAttchID,'PMDocDistAudit' as FormName
	,f.FirmNumber as SentToFirm,f.FirmName as SentToFirmName,f.VendorGroup,
	c.ContactCode as SentToContact,isnull(c.FirstName,'') + ' ' + isnull(c.LastName,'') as SentToContactName,c.EMail,d.Fax,d.FaxAddress,
	d.Subject,d.CCAddresses,d.bCCAddresses,d.CreatedDateTime,d.CreatedBy,d.Printed,d.Emailed,d.Faxed
	,case when exists(select 1 from PMHF where PMHIKeyId = d.KeyId) then 'Y' else 'N' end Attachments
	,t.DocCategory,t.DocType,'Issue' as DocTypeDesc,dbo.vfToString(s.Issue) as Document,null as Revision
from PMIM s 
	join PMHI d on s.KeyID = d.SourceKeyId and d.SourceTableName in ('PMIM')
	join JCJMPM p on s.PMCo = p.PMCo and s.Project = p.Project
	left join PMFM f on d.VendorGroup = f.VendorGroup and d.SentToFirm = f.FirmNumber
	left join PMPM c on d.VendorGroup = c.VendorGroup and d.SentToFirm = c.FirmNumber and d.SentToContact = c.ContactCode
	left join PMDT t on t.DocType = s.Type
union all
-- Sub COs
select 12 as Sort,p.ProjectMgr,p.JobStatus,d.SourceTableName,d.SourceKeyId,
	s.PMCo,s.Project,d.KeyId,s.UniqueAttchID,'PMDocDistAudit' as FormName
	,f.FirmNumber as SentToFirm,f.FirmName as SentToFirmName,f.VendorGroup,
	c.ContactCode as SentToContact,isnull(c.FirstName,'') + ' ' + isnull(c.LastName,'') as SentToContactName,c.EMail,d.Fax,d.FaxAddress,
	d.Subject,d.CCAddresses,d.bCCAddresses,d.CreatedDateTime,d.CreatedBy,d.Printed,d.Emailed,d.Faxed
	,case when exists(select 1 from PMHF where PMHIKeyId = d.KeyId) then 'Y' else 'N' end Attachments
	,t.DocCategory,t.DocType,'SL Change Order' as DocTypeDesc,s.SL as Document,dbo.vfToString(s.SubCO) as Revision
from PMSubcontractCO s 
	join PMHI d on s.KeyID = d.SourceKeyId and d.SourceTableName in ('PMSubcontractCO')
	join JCJMPM p on s.PMCo = p.PMCo and s.Project = p.Project
	left join PMFM f on d.VendorGroup = f.VendorGroup and d.SentToFirm = f.FirmNumber
	left join PMPM c on d.VendorGroup = c.VendorGroup and d.SentToFirm = c.FirmNumber and d.SentToContact = c.ContactCode
	left join PMDT t on t.DocType = s.DocType
union all
--CCOs
select distinct 13 as Sort,p.ProjectMgr,p.JobStatus,d.SourceTableName,d.SourceKeyId,
	s.PMCo,p.Project,d.KeyId,s.UniqueAttchID,'PMDocDistAudit' as FormName
	,f.FirmNumber as SentToFirm,f.FirmName as SentToFirmName,f.VendorGroup,
	c.ContactCode as SentToContact,isnull(c.FirstName,'') + ' ' + isnull(c.LastName,'') as SentToContactName,c.EMail,d.Fax,d.FaxAddress,
	d.Subject,d.CCAddresses,d.bCCAddresses,d.CreatedDateTime,d.CreatedBy,d.Printed,d.Emailed,d.Faxed
	,case when exists(select 1 from PMHF where PMHIKeyId = d.KeyId) then 'Y' else 'N' end Attachments
	,t.DocCategory,t.DocType,'CCO' as DocTypeDesc,s.Contract as Document,dbo.vfToString(s.ID) as Revision
from PMContractChangeOrder s
	join JCJMPM p on s.PMCo=p.PMCo and s.Contract = p.Contract 
	join PMHI d on s.KeyID = d.SourceKeyId and d.SourceTableName in ('PMContractChangeOrder')
	left join PMFM f on d.VendorGroup = f.VendorGroup and d.SentToFirm = f.FirmNumber
	left join PMPM c on d.VendorGroup = c.VendorGroup and d.SentToFirm = c.FirmNumber and d.SentToContact = c.ContactCode
	left join PMDT t on t.DocType = s.DocType
union all

-- RFQs new
select 14 as Sort,p.ProjectMgr,p.JobStatus,d.SourceTableName,d.SourceKeyId,
	s.PMCo,s.Project,d.KeyId,s.UniqueAttchID,'PMDocDistAudit' as FormName
	,f.FirmNumber as SentToFirm,f.FirmName as SentToFirmName,f.VendorGroup,
	c.ContactCode as SentToContact,isnull(c.FirstName,'') + ' ' + isnull(c.LastName,'') as SentToContactName,c.EMail,d.Fax,d.FaxAddress,
	d.Subject,d.CCAddresses,d.bCCAddresses,d.CreatedDateTime,d.CreatedBy,d.Printed,d.Emailed,d.Faxed
	,case when exists(select 1 from PMHF where PMHIKeyId = d.KeyId) then 'Y' else 'N' end Attachments
	,t.DocCategory,t.DocType,'RFQ' as DocTypeDesc,dbo.vfToString(s.RFQ) as Document,null as Revision
from PMRequestForQuote s 
	join PMHI d on s.KeyID = d.SourceKeyId and d.SourceTableName in ('PMRequestForQuote')
	join JCJMPM p on s.PMCo = p.PMCo and s.Project = p.Project
	left join PMFM f on d.VendorGroup = f.VendorGroup and d.SentToFirm = f.FirmNumber
	left join PMPM c on d.VendorGroup = c.VendorGroup and d.SentToFirm = c.FirmNumber and d.SentToContact = c.ContactCode
	left join PMDT t on t.DocType = s.DocType
union all
--PM Submittal Package
select 15 as Sort,p.ProjectMgr,p.JobStatus,d.SourceTableName,d.SourceKeyId,
	s.PMCo,s.Project,d.KeyId,s.UniqueAttchID,'PMDocDistAudit' as FormName
	,f.FirmNumber as SentToFirm,f.FirmName as SentToFirmName,f.VendorGroup,
	c.ContactCode as SentToContact,isnull(c.FirstName,'') + ' ' + isnull(c.LastName,'') as SentToContactName,c.EMail,d.Fax,d.FaxAddress,
	d.Subject,d.CCAddresses,d.bCCAddresses,d.CreatedDateTime,d.CreatedBy,d.Printed,d.Emailed,d.Faxed
	,case when exists(select 1 from PMHF where PMHIKeyId = d.KeyId) then 'Y' else 'N' end Attachments
	,t.DocCategory,t.DocType,'Submittal Package' as DocTypeDesc,dbo.vfToString(s.Package) as Document,dbo.vfToString(s.PackageRev) as Revision
from PMSubmittalPackage s 
	join PMHI d on s.KeyID = d.SourceKeyId and d.SourceTableName in ('PMSubmittalPackage')
	join JCJMPM p on s.PMCo = p.PMCo and s.Project = p.Project
	left join PMFM f on d.VendorGroup = f.VendorGroup and d.SentToFirm = f.FirmNumber
	left join PMPM c on d.VendorGroup = c.VendorGroup and d.SentToFirm = c.FirmNumber and d.SentToContact = c.ContactCode
	left join PMDT t on t.DocType = s.DocType
union all
--PM Inspections
select 16 as Sort,p.ProjectMgr,p.JobStatus,d.SourceTableName,d.SourceKeyId,
	s.PMCo,s.Project,d.KeyId,s.UniqueAttchID,'PMDocDistAudit' as FormName
	,f.FirmNumber as SentToFirm,f.FirmName as SentToFirmName,f.VendorGroup,
	c.ContactCode as SentToContact,isnull(c.FirstName,'') + ' ' + isnull(c.LastName,'') as SentToContactName,c.EMail,d.Fax,d.FaxAddress,
	d.Subject,d.CCAddresses,d.bCCAddresses,d.CreatedDateTime,d.CreatedBy,d.Printed,d.Emailed,d.Faxed
	,case when exists(select 1 from PMHF where PMHIKeyId = d.KeyId) then 'Y' else 'N' end Attachments
	,t.DocCategory,t.DocType,'Inspection' as DocTypeDesc,dbo.vfToString(s.InspectionCode) as Document,null as Revision
from PMIL s 
	join PMHI d on s.KeyID = d.SourceKeyId and d.SourceTableName in ('PMIL')
	join JCJMPM p on s.PMCo = p.PMCo and s.Project = p.Project
	left join PMFM f on d.VendorGroup = f.VendorGroup and d.SentToFirm = f.FirmNumber
	left join PMPM c on d.VendorGroup = c.VendorGroup and d.SentToFirm = c.FirmNumber and d.SentToContact = c.ContactCode
	left join PMDT t on t.DocType = s.InspectionType
union all
--PM Daily Log
select 17 as Sort,p.ProjectMgr,p.JobStatus,d.SourceTableName,d.SourceKeyId,
	s.PMCo,s.Project,d.KeyId,s.UniqueAttchID,'PMDocDistAudit' as FormName
	,f.FirmNumber as SentToFirm,f.FirmName as SentToFirmName,f.VendorGroup,
	c.ContactCode as SentToContact,isnull(c.FirstName,'') + ' ' + isnull(c.LastName,'') as SentToContactName,c.EMail,d.Fax,d.FaxAddress,
	d.Subject,d.CCAddresses,d.bCCAddresses,d.CreatedDateTime,d.CreatedBy,d.Printed,d.Emailed,d.Faxed
	,case when exists(select 1 from PMHF where PMHIKeyId = d.KeyId) then 'Y' else 'N' end Attachments
	,t.DocCategory,t.DocType,'Daily Log' as DocTypeDesc,dbo.vfDateOnlyAsStringUsingStyle(s.LogDate,s.PMCo,null) as Document,dbo.vfToString(s.DailyLog) as Revision
from PMDL s 
	join PMHI d on s.KeyID = d.SourceKeyId and d.SourceTableName in ('PMDL')
	join JCJMPM p on s.PMCo = p.PMCo and s.Project = p.Project
	left join PMFM f on d.VendorGroup = f.VendorGroup and d.SentToFirm = f.FirmNumber
	left join PMPM c on d.VendorGroup = c.VendorGroup and d.SentToFirm = c.FirmNumber and d.SentToContact = c.ContactCode
	left join PMDT t on t.DocType = s.DocType
union all
--PM COR
select distinct 18 as Sort,p.ProjectMgr,p.JobStatus,d.SourceTableName,d.SourceKeyId,
	s.PMCo,p.Project,d.KeyId,s.UniqueAttchID,'PMDocDistAudit' as FormName
	,f.FirmNumber as SentToFirm,f.FirmName as SentToFirmName,f.VendorGroup,
	c.ContactCode as SentToContact,isnull(c.FirstName,'') + ' ' + isnull(c.LastName,'') as SentToContactName,c.EMail,d.Fax,d.FaxAddress,
	d.Subject,d.CCAddresses,d.bCCAddresses,d.CreatedDateTime,d.CreatedBy,d.Printed,d.Emailed,d.Faxed
	,case when exists(select 1 from PMHF where PMHIKeyId = d.KeyId) then 'Y' else 'N' end Attachments
	,t.DocCategory,t.DocType,'COR' as DocTypeDesc,s.Contract as Document,dbo.vfToString(s.COR) as Revision
from PMChangeOrderRequest s
	join JCJMPM p on s.PMCo=p.PMCo and s.Contract = p.Contract 
	join PMHI d on s.KeyID = d.SourceKeyId and d.SourceTableName in ('PMChangeOrderRequest')
	left join PMFM f on d.VendorGroup = f.VendorGroup and d.SentToFirm = f.FirmNumber
	left join PMPM c on d.VendorGroup = c.VendorGroup and d.SentToFirm = c.FirmNumber and d.SentToContact = c.ContactCode
	left join PMDT t on t.DocType = s.DocType
union all
--PM ACO
select 19 as Sort,p.ProjectMgr,p.JobStatus,d.SourceTableName,d.SourceKeyId,
	s.PMCo,s.Project,d.KeyId,s.UniqueAttchID,'PMDocDistAudit' as FormName
	,f.FirmNumber as SentToFirm,f.FirmName as SentToFirmName,f.VendorGroup,
	c.ContactCode as SentToContact,isnull(c.FirstName,'') + ' ' + isnull(c.LastName,'') as SentToContactName,c.EMail,d.Fax,d.FaxAddress,
	d.Subject,d.CCAddresses,d.bCCAddresses,d.CreatedDateTime,d.CreatedBy,d.Printed,d.Emailed,d.Faxed
	,case when exists(select 1 from PMHF where PMHIKeyId = d.KeyId) then 'Y' else 'N' end Attachments
	,t.DocCategory,t.DocType,'Approved Change Orders' as DocTypeDesc,s.ACO as Document,null as Revision
from PMOH s 
	join PMHI d on s.KeyID = d.SourceKeyId and d.SourceTableName in ('PMOH')
	join JCJMPM p on s.PMCo = p.PMCo and s.Project = p.Project
	left join PMFM f on d.VendorGroup = f.VendorGroup and d.SentToFirm = f.FirmNumber
	left join PMPM c on d.VendorGroup = c.VendorGroup and d.SentToFirm = c.FirmNumber and d.SentToContact = c.ContactCode
	left join PMDT t on t.DocType = s.DocType
union all
--PM POCO
select 20 as Sort,p.ProjectMgr,p.JobStatus,d.SourceTableName,d.SourceKeyId,
	s.PMCo,s.Project,d.KeyId,s.UniqueAttchID,'PMDocDistAudit' as FormName
	,f.FirmNumber as SentToFirm,f.FirmName as SentToFirmName,f.VendorGroup,
	c.ContactCode as SentToContact,isnull(c.FirstName,'') + ' ' + isnull(c.LastName,'') as SentToContactName,c.EMail,d.Fax,d.FaxAddress,
	d.Subject,d.CCAddresses,d.bCCAddresses,d.CreatedDateTime,d.CreatedBy,d.Printed,d.Emailed,d.Faxed
	,case when exists(select 1 from PMHF where PMHIKeyId = d.KeyId) then 'Y' else 'N' end Attachments
	,t.DocCategory,t.DocType,'PO Change Order' as DocTypeDesc,s.PO as Document,dbo.vfToString(s.POCONum) as Revision
from PMPOCO s 
	join PMHI d on s.KeyID = d.SourceKeyId and d.SourceTableName in ('PMPOCO')
	join JCJMPM p on s.PMCo = p.PMCo and s.Project = p.Project
	left join PMFM f on d.VendorGroup = f.VendorGroup and d.SentToFirm = f.FirmNumber
	left join PMPM c on d.VendorGroup = c.VendorGroup and d.SentToFirm = c.FirmNumber and d.SentToContact = c.ContactCode
	left join PMDT t on t.DocType = s.DocType
union all
--PM Drawing Log
select 21 as Sort,p.ProjectMgr,p.JobStatus,d.SourceTableName,d.SourceKeyId,
	s.PMCo,s.Project,d.KeyId,s.UniqueAttchID,'PMDocDistAudit' as FormName
	,f.FirmNumber as SentToFirm,f.FirmName as SentToFirmName,f.VendorGroup,
	c.ContactCode as SentToContact,isnull(c.FirstName,'') + ' ' + isnull(c.LastName,'') as SentToContactName,c.EMail,d.Fax,d.FaxAddress,
	d.Subject,d.CCAddresses,d.bCCAddresses,d.CreatedDateTime,d.CreatedBy,d.Printed,d.Emailed,d.Faxed
	,case when exists(select 1 from PMHF where PMHIKeyId = d.KeyId) then 'Y' else 'N' end Attachments
	,t.DocCategory,t.DocType,'Drawing' as DocTypeDesc,dbo.vfToString(s.Drawing) as Document,null as Revision
from PMDG s 
	join PMHI d on s.KeyID = d.SourceKeyId and d.SourceTableName in ('PMDG')
	join JCJMPM p on s.PMCo = p.PMCo and s.Project = p.Project
	left join PMFM f on d.VendorGroup = f.VendorGroup and d.SentToFirm = f.FirmNumber
	left join PMPM c on d.VendorGroup = c.VendorGroup and d.SentToFirm = c.FirmNumber and d.SentToContact = c.ContactCode
	left join PMDT t on t.DocType = s.DrawingType
union all
--PM Test Logs
select 22 as Sort,p.ProjectMgr,p.JobStatus,d.SourceTableName,d.SourceKeyId,
	s.PMCo,s.Project,d.KeyId,s.UniqueAttchID,'PMDocDistAudit' as FormName
	,f.FirmNumber as SentToFirm,f.FirmName as SentToFirmName,f.VendorGroup,
	c.ContactCode as SentToContact,isnull(c.FirstName,'') + ' ' + isnull(c.LastName,'') as SentToContactName,c.EMail,d.Fax,d.FaxAddress,
	d.Subject,d.CCAddresses,d.bCCAddresses,d.CreatedDateTime,d.CreatedBy,d.Printed,d.Emailed,d.Faxed
	,case when exists(select 1 from PMHF where PMHIKeyId = d.KeyId) then 'Y' else 'N' end Attachments
	,t.DocCategory,t.DocType,'Test' as DocTypeDesc,s.TestCode as Document,null as Revision
from PMTL s 
	join PMHI d on s.KeyID = d.SourceKeyId and d.SourceTableName in ('PMTL')
	join JCJMPM p on s.PMCo = p.PMCo and s.Project = p.Project
	left join PMFM f on d.VendorGroup = f.VendorGroup and d.SentToFirm = f.FirmNumber
	left join PMPM c on d.VendorGroup = c.VendorGroup and d.SentToFirm = c.FirmNumber and d.SentToContact = c.ContactCode
	left join PMDT t on t.DocType = s.TestType

GO
GRANT SELECT ON  [dbo].[vrvPMDocDistAudit] TO [public]
GRANT INSERT ON  [dbo].[vrvPMDocDistAudit] TO [public]
GRANT DELETE ON  [dbo].[vrvPMDocDistAudit] TO [public]
GRANT UPDATE ON  [dbo].[vrvPMDocDistAudit] TO [public]
GO
