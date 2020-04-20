SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE view [dbo].[vrvPMDocDistAudit] as

--RFI
select PMRI.PMCo, PMRI.Project, JCJMPM.ProjectMgr, PMRI.RFI as Document, PMRI.RFIType as DocType, p.KeyId, 
p.SourceTableName, p.SourceKeyId, 
Sort = 1, 'RFI' as DocTypeDesc,  p.CreatedDateTime, p.CreatedBy, p.VendorGroup,
p.SentToFirm, p.SentToContact, p.EMail, p.Fax, p.FaxAddress, p.Subject, p.CCAddresses, p.bCCAddresses,
p.Printed, p.Emailed, p.Faxed


from PMHI p with (nolock)

inner join PMRI with (nolock) on  p.SourceKeyId=PMRI.KeyID
left join JCJMPM with (nolock) on  PMRI.PMCo=JCJMPM.PMCo and PMRI.Project=JCJMPM.Project
where p.SourceTableName = 'PMRI'

union all

select PMTM.PMCo, PMTM.Project, JCJMPM.ProjectMgr, PMTM.Transmittal, 'TRANSMITTAL' as DocType, p.KeyId, 
p.SourceTableName, p.SourceKeyId, 
Sort = 2, 'Transmittal', p.CreatedDateTime, p.CreatedBy, p.VendorGroup,
p.SentToFirm, p.SentToContact, p.EMail, p.Fax, p.FaxAddress, p.Subject, p.CCAddresses, p.bCCAddresses,
p.Printed, p.Emailed, p.Faxed


from PMHI p with (nolock)

inner join PMTM with (nolock) on  p.SourceKeyId=PMTM.KeyID
left join JCJMPM with (nolock) on  PMTM.PMCo=JCJMPM.PMCo and PMTM.Project=JCJMPM.Project
where p.SourceTableName = 'PMTM'

union all

select PMSM.PMCo, PMSM.Project, JCJMPM.ProjectMgr, PMSM.Submittal, PMSM.SubmittalType as DocType, p.KeyId, 
p.SourceTableName, p.SourceKeyId, 
Sort = 3, 'Submittal', p.CreatedDateTime, p.CreatedBy, p.VendorGroup,
p.SentToFirm, p.SentToContact, p.EMail, p.Fax, p.FaxAddress, p.Subject, p.CCAddresses, p.bCCAddresses,
p.Printed, p.Emailed, p.Faxed

from PMHI p with (nolock)

inner join PMSM with (nolock) on  p.SourceKeyId=PMSM.KeyID
left join JCJMPM with (nolock) on  PMSM.PMCo=JCJMPM.PMCo and PMSM.Project=JCJMPM.Project
where p.SourceTableName = 'PMSM'

union all

select PMOD.PMCo, PMOD.Project, JCJMPM.ProjectMgr, PMOD.Document, PMOD.DocType as DocType, p.KeyId, 
p.SourceTableName, p.SourceKeyId, 
Sort = 4, 'Other Documents', p.CreatedDateTime, p.CreatedBy, p.VendorGroup,
p.SentToFirm, p.SentToContact, p.EMail, p.Fax, p.FaxAddress, p.Subject, p.CCAddresses, p.bCCAddresses,
p.Printed, p.Emailed, p.Faxed


from PMHI p with (nolock)

inner join PMOD with (nolock) on  p.SourceKeyId=PMOD.KeyID
left join JCJMPM with (nolock) on  PMOD.PMCo=JCJMPM.PMCo and PMOD.Project=JCJMPM.Project
where p.SourceTableName = 'PMOD'

union all

select PMRQ.PMCo, PMRQ.Project, JCJMPM.ProjectMgr, PMRQ.RFQ,  PMRQ.PCOType, p.KeyId, 
p.SourceTableName, p.SourceKeyId, 
Sort = 5, 'Request For Quotes', p.CreatedDateTime, p.CreatedBy, p.VendorGroup,
p.SentToFirm, p.SentToContact, p.EMail, p.Fax, p.FaxAddress, p.Subject, p.CCAddresses, p.bCCAddresses,
p.Printed, p.Emailed, p.Faxed


from PMHI p with (nolock)

inner join PMRQ with (nolock) on  p.SourceKeyId=PMRQ.KeyID
left join JCJMPM with (nolock) on  PMRQ.PMCo=JCJMPM.PMCo and PMRQ.Project=JCJMPM.Project
where p.SourceTableName = 'PMRQ'

union all

select SLHD.SLCo, SLHD.Job, JCJMPM.ProjectMgr, SLHD.SL,  'SL', p.KeyId, 
p.SourceTableName, p.SourceKeyId, 
Sort = 6, 'Subcontracts', p.CreatedDateTime, p.CreatedBy, p.VendorGroup,
p.SentToFirm, p.SentToContact, p.EMail, p.Fax, p.FaxAddress, p.Subject, p.CCAddresses, p.bCCAddresses,
p.Printed, p.Emailed, p.Faxed

from PMHI p with (nolock)

inner join SLHD with (nolock) on  p.SourceKeyId=SLHD.KeyID
left join JCJMPM with (nolock) on  SLHD.SLCo=JCJMPM.PMCo and SLHD.Job=JCJMPM.Project
where p.SourceTableName = 'SLHD'

union all

select PMOP.PMCo, PMOP.Project, JCJMPM.ProjectMgr, PMOP.PCO, PMOP.PCOType, p.KeyId, 
p.SourceTableName, p.SourceKeyId, 
Sort = 7, 'Pending Change Orders', p.CreatedDateTime, p.CreatedBy, p.VendorGroup,
p.SentToFirm, p.SentToContact, p.EMail, p.Fax, p.FaxAddress, p.Subject, p.CCAddresses, p.bCCAddresses,
p.Printed, p.Emailed, p.Faxed


from PMHI p with (nolock)

inner join PMOP with (nolock) on  p.SourceKeyId=PMOP.KeyID
left join JCJMPM with (nolock) on  PMOP.PMCo=JCJMPM.PMCo and PMOP.Project=JCJMPM.Project
where p.SourceTableName = 'PMOP'











GO
GRANT SELECT ON  [dbo].[vrvPMDocDistAudit] TO [public]
GRANT INSERT ON  [dbo].[vrvPMDocDistAudit] TO [public]
GRANT DELETE ON  [dbo].[vrvPMDocDistAudit] TO [public]
GRANT UPDATE ON  [dbo].[vrvPMDocDistAudit] TO [public]
GO
