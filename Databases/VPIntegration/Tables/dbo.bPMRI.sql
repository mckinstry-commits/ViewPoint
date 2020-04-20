CREATE TABLE [dbo].[bPMRI]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bJob] NOT NULL,
[RFIType] [dbo].[bDocType] NOT NULL,
[RFI] [dbo].[bDocument] NOT NULL,
[Subject] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[RFIDate] [dbo].[bDate] NOT NULL,
[Issue] [dbo].[bIssue] NULL,
[Status] [dbo].[bStatus] NULL,
[Submittal] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Drawing] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Addendum] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[SpecSec] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[ScheduleNo] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[ResponsibleFirm] [dbo].[bFirm] NULL,
[ResponsiblePerson] [dbo].[bEmployee] NULL,
[ReqFirm] [dbo].[bFirm] NULL,
[ReqContact] [dbo].[bEmployee] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[Response] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[DateDue] [dbo].[bDate] NULL,
[ImpactDesc] [dbo].[bItemDesc] NULL,
[ImpactDays] [smallint] NULL,
[ImpactCosts] [dbo].[bDollar] NULL,
[ImpactPrice] [dbo].[bDollar] NULL,
[RespondFirm] [dbo].[bFirm] NULL,
[RespondContact] [dbo].[bEmployee] NULL,
[DateSent] [dbo].[bDate] NULL,
[DateRecd] [dbo].[bDate] NULL,
[PrefMethod] [varchar] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMRI_PrefMethod] DEFAULT ('M'),
[InfoRequested] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[ImpactDaysYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMRI_ImpactDaysYN] DEFAULT ('N'),
[ImpactCostsYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMRI_ImpactCostsYN] DEFAULT ('N'),
[ImpactPriceYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMRI_ImpactPriceYN] DEFAULT ('N'),
[Suggestion] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[Reference] [varchar] (10) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Trigger dbo.btPMRId    Script Date: 8/28/99 9:38:00 AM ******/
CREATE trigger [dbo].[btPMRId] on [dbo].[bPMRI] for DELETE as
/*--------------------------------------------------------------
 * Created By:	LM 1/16/98
 * Modified By:	GF 10/12/2006 - changes for 6.x PMDH document history
 *				GF 02/04/2007 - issue #123699 issue history
 *				GF 06/11/2007 - issue #124481 null out RFIType and RFI in PMOI for deleted rows
 *				GF 04/24/2008 - issue #125958 delete PM distribution audit
 *				GF 12/21/2010 - issue #141957 record association
 *				GF 01/26/2011 - TFS #398
 *				JayR 03/26/2012 TK-00000 Change to FK for cascase deletion.  Remove gotos
 *
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

---- update PMOI remove set PMOI.RFIType, PMOI.RFI to null for matches
update bPMOI set RFIType=null, RFI=null
from bPMOI i join deleted d on i.PMCo=d.PMCo and i.Project=d.Project
and i.RFIType=d.RFIType and i.RFI=d.RFI

---- delete PM distribution audit tables if any
delete bPMHA from bPMHA a join bPMHI i on i.KeyId=a.PMHIKeyId
join deleted d on i.SourceTableName='PMRI' and i.SourceKeyId=d.KeyID

delete bPMHF from bPMHF a join bPMHI i on i.KeyId=a.PMHIKeyId
join deleted d on i.SourceTableName='PMRI' and i.SourceKeyId=d.KeyID

delete bPMHI from bPMHI i
join deleted d on i.SourceTableName='PMRI' and i.SourceKeyId=d.KeyID


---- when the record is related to a project issue PMIM
---- we need to add a delete action recorded in history for the issue
---- noting that the type and code with a description ws deleted.
---- record side. TFS #398
---- delete
DELETE dbo.vPMIssueHistory FROM deleted d WHERE RelatedTableName = 'bPMRI' AND RelatedKeyID = d.KeyID
---- insert
INSERT dbo.vPMIssueHistory (IssueKeyID,RelatedTableName,RelatedKeyID,Co,Project,Issue,ActionType,RelatedDeleteAction)
SELECT x.KeyID, 'bPMRI', d.KeyID, d.PMCo, d.Project, x.Issue, 'D',
		'RFI Type: ' + ISNULL(d.RFIType,'') + ' RFI: ' + ISNULL(d.RFI,'') + ' : ' + ISNULL(d.Subject,'')	
from deleted d
JOIN dbo.vPMRelateRecord r ON r.RecTableName = 'PMRI' AND r.RECID = d.KeyID AND r.LinkTableName = 'PMIM'
JOIN dbo.bPMIM x ON x.KeyID = r.LINKID
WHERE d.KeyID=r.RECID
---- link side
INSERT dbo.vPMIssueHistory (IssueKeyID,RelatedTableName,RelatedKeyID,Co,Project,Issue,ActionType,RelatedDeleteAction)
SELECT x.KeyID, 'bPMRI', d.KeyID, d.PMCo, d.Project, x.Issue, 'D',
		'RFI Type: ' + ISNULL(d.RFIType,'') + ' RFI: ' + ISNULL(d.RFI,'') + ' : ' + ISNULL(d.Subject,'')	
from deleted d
JOIN dbo.vPMRelateRecord r ON r.LinkTableName = 'PMRI' AND r.LINKID = d.KeyID AND r.RecTableName = 'PMIM'
JOIN dbo.bPMIM x ON x.KeyID = r.RECID
WHERE d.KeyID=r.LINKID

---- delete associations if any from both sides - #141957
---- record side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='PMRI' AND a.RECID=d.KeyID
WHERE d.KeyID IS NOT NULL
---- link side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMRelateRecord a ON a.LinkTableName='PMRI' AND a.LINKID=d.KeyID
WHERE d.KeyID IS NOT NULL


---- document history (bPMDH)
insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.RFIType ASC),
		'RFI', i.RFIType, i.RFI, null, getdate(), 'D', 'RFI', i.RFI, null,
		SUSER_SNAME(), 'RFI: ' + isnull(i.RFI,'') + ' has been deleted.', null
from deleted i
left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='RFI'
join bPMCO c with (nolock) on i.PMCo=c.PMCo
left join bJCJM j with (nolock) on j.JCCo=i.PMCo and j.Job=i.Project
where j.ClosePurgeFlag <> 'Y' and  isnull(c.DocHistRFI,'N') = 'Y'
group by i.PMCo, i.Project, i.RFIType, i.RFI


RETURN 
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Trigger dbo.btPMRIi Script Date: 11/07/2006 ******/
CREATE trigger [dbo].[btPMRIi] on [dbo].[bPMRI] for INSERT as
/*--------------------------------------------------------------
 * Insert trigger for PMRI
 * Created By:	LM 1/15/98
 * Modified By: GF 10/09/2002 - changed dbl quotes to single quotes
 *				GF 06/26/2003 - #21613 action does not allow nulls. Added isnulls
 *				GF 10/12/2006 - changes for 6.x PMDH document history, 
								validation for Responding Firm/Contact, insert PMRD record
 *				GF 11/26/2006 - 6.x
 *				GF 02/04/2007 - issue #123699 issue history
 *				GF 10/24/2007 - issue #125953 update PMRD with responding firm/contact if not exists.
 *				GF 01/30/2008 - issue #126439 added DateRecd to PMRD update.
 *				GF 03/17/2008 - issue #127470 added DateReqd to PMRD update.
 *				DC 10/5/2010 - Created RFI Copy process.  Removed Issue validation from triggers.
 *				GF 10/08/2010 - issue #141648
 *				GF 01/26/2011 - tfs #398
 *				GP 08/12/2011 - TK-06380 Added vfDateOnly to PMRD insert if i.DateSent is null
 *				JayR 03/26/2012 TK-00000 Change to use FKs for validation.
 *
 *--------------------------------------------------------------*/
declare @numrows int, @validcnt int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

---- Validate RFI Type
select @validcnt = count(*) from bPMDT r JOIN inserted i ON i.RFIType = r.DocType and r.DocCategory = 'RFI'
if @validcnt <> @numrows
      begin
		  RAISERROR('RFI Type is Invalid - cannot insert into PMRI', 11, -1)
		  rollback TRANSACTION
		  RETURN
      end


---- insert PMRD record for responding firm/contact
insert into bPMRD (PMCo, Project, RFIType, RFI, RFISeq, VendorGroup, SentToFirm, SentToContact,
			DateSent, DateReqd, Send, CC, DateRecd, PrefMethod)
select i.PMCo, i.Project, i.RFIType, i.RFI, isnull(max(h.RFISeq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.RFIType ASC, i.RFI ASC),
		i.VendorGroup, i.RespondFirm, i.RespondContact, isnull(i.DateSent, dbo.vfDateOnly()), i.DateDue, 'Y', 'N', i.DateRecd,
		case when c.PrefMethod = 'E' and isnull(c.EMail,'') <> '' then c.PrefMethod
			 when c.PrefMethod = 'F' and isnull(c.Fax,'') <> '' then c.PrefMethod
			 else 'M' end
from inserted i
left join bPMRD h on h.PMCo=i.PMCo and h.Project=i.Project and h.RFIType=i.RFIType and h.RFI=i.RFI
left join bPMPM c on c.VendorGroup=i.VendorGroup and c.FirmNumber=i.RespondFirm and c.ContactCode=i.RespondContact
where i.RespondFirm is not null and i.RespondContact is not null
group by i.PMCo, i.Project, i.RFIType, i.RFI, i.VendorGroup, i.RespondFirm, i.RespondContact,
i.DateSent, i.DateDue, i.DateRecd, c.PrefMethod, c.EMail, c.Fax
if @@rowcount <> 0
	begin
	---- if we add distributions then add to project firms (bPMPF)
	insert into bPMPF (PMCo, Project, Seq, VendorGroup, FirmNumber, ContactCode, PortalSiteAccess)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			i.VendorGroup, i.RespondFirm, i.RespondContact, 'N'
	from inserted i
	left join bPMPF h on h.PMCo=i.PMCo and h.Project=i.Project
	where i.RespondFirm is not null and i.RespondContact is not null
	and not exists(select PMCo from bPMPF f where f.PMCo=i.PMCo and f.Project=i.Project and f.VendorGroup=i.VendorGroup
				and f.FirmNumber=i.RespondFirm and f.ContactCode=i.RespondContact)
	group by i.PMCo, i.Project, i.VendorGroup, i.RespondFirm, i.RespondContact
	end



---- document history (PMDH)
insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, Action)
select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.RFIType ASC),
		'RFI', i.RFIType, i.RFI, null, getdate(), 'A', 'RFI', null, i.RFI, SUSER_SNAME(),
		'RFI: ' + isnull(i.RFI,'') + ' has been added.'
from inserted i
left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='RFI'
join bPMCO c with (nolock) on i.PMCo=c.PMCo
where isnull(c.DocHistRFI,'N') = 'Y'
group by i.PMCo, i.Project, i.RFIType, i.RFI


RETURN


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Trigger dbo.btPMRIu    Script Date: 8/28/99 9:38:01 AM ******/
CREATE  trigger [dbo].[btPMRIu] on [dbo].[bPMRI] for UPDATE as
/*--------------------------------------------------------------
 * Update trigger for PMRI
 * Created By:	LM 1/15/98
 * Modified By: GF 10/09/2002 - changed dbl quotes to single quotes
 *				GF 06/26/2003 - #21613 action does not allow nulls. Added isnulls
 *				gf 11/30/2006 - 6.x document history changes.
 *				gf 02/07/2007 - issue #123699 issue history
 *				GF 10/24/2007 - issue #125953 update PMRD with responding firm/contact if not exists.
 *				GF 01/30/2008 - issue #126439 added DateRecd to PMRD update.
 *				GF 03/17/2008 - issue #127470 added DateReqd to PMRD update.
 *				DC 10/5/2010 - Created RFI Copy process.  Removed Issue validation from triggers.
 *				GP 08/12/2011 - TK-06380 Added vfDateOnly to PMRD insert if i.DateSent is null
 *				JayR 03/26/2012 Tk-00000 Change to using Fks for validation.
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

---- check for key changes
if update(PMCo) or update(Project) or update(RFIType) or update(RFI)
      begin
      RAISERROR('Cannot change key values  - cannot update PMRI', 11, -1)
      ROLLBACK TRANSACTION
      RETURN
      end

---- insert PMRD record for responding firm/contact
insert into bPMRD (PMCo, Project, RFIType, RFI, RFISeq, VendorGroup, SentToFirm, SentToContact,
			DateSent, DateReqd, Send, CC, DateRecd, PrefMethod)
select i.PMCo, i.Project, i.RFIType, i.RFI, isnull(max(h.RFISeq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.RFIType ASC, i.RFI ASC),
		i.VendorGroup, i.RespondFirm, i.RespondContact, isnull(i.DateSent, dbo.vfDateOnly()), i.DateDue, 'Y', 'N', i.DateRecd,
		case when c.PrefMethod = 'E' and isnull(c.EMail,'') <> '' then c.PrefMethod
			 when c.PrefMethod = 'F' and isnull(c.Fax,'') <> '' then c.PrefMethod
			 else 'M' end
from inserted i
left join bPMRD h on h.PMCo=i.PMCo and h.Project=i.Project and h.RFIType=i.RFIType and h.RFI=i.RFI
left join bPMPM c on c.VendorGroup=i.VendorGroup and c.FirmNumber=i.RespondFirm and c.ContactCode=i.RespondContact
where i.RespondFirm is not null and i.RespondContact is not null
and not exists(select PMCo from bPMRD r where r.PMCo=i.PMCo and r.Project=i.Project and r.RFIType=i.RFIType
				and r.RFI=i.RFI and r.VendorGroup=i.VendorGroup and r.SentToFirm=i.RespondFirm and r.SentToContact=i.RespondContact)
group by i.PMCo, i.Project, i.RFIType, i.RFI, i.VendorGroup, i.RespondFirm, i.RespondContact,
i.DateSent, i.DateDue, i.DateRecd, c.PrefMethod, c.EMail, c.Fax
if @@rowcount <> 0
	begin
	---- if we add distributions then add to project firms (bPMPF)
	insert into bPMPF (PMCo, Project, Seq, VendorGroup, FirmNumber, ContactCode, PortalSiteAccess)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			i.VendorGroup, i.RespondFirm, i.RespondContact, 'N'
	from inserted i
	left join bPMPF h on h.PMCo=i.PMCo and h.Project=i.Project
	where i.RespondFirm is not null and i.RespondContact is not null
	and not exists(select PMCo from bPMPF f where f.PMCo=i.PMCo and f.Project=i.Project and f.VendorGroup=i.VendorGroup
				and f.FirmNumber=i.RespondFirm and f.ContactCode=i.RespondContact)
	group by i.PMCo, i.Project, i.VendorGroup, i.RespondFirm, i.RespondContact
	end

---- update PMRD record with Date Received if needed
if update(DateRecd)
	begin
	update bPMRD set DateRecd = i.DateRecd
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.RFIType=i.RFIType and d.RFI=i.RFI
	join bPMRD r on r.PMCo=i.PMCo and r.Project=i.Project and r.RFIType=i.RFIType and r.RFI=i.RFI and r.VendorGroup=i.VendorGroup
	and r.SentToFirm=i.RespondFirm and r.SentToContact=i.RespondContact
	where i.RespondFirm is not null and i.RespondContact is not null
	and isnull(i.DateRecd,'') <> isnull(d.DateRecd,'')
	end


---- document history updates (bPMDH)
if update(Subject)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.RFIType),
			'RFI', i.RFIType, i.RFI, null, getdate(), 'C', 'Subject',
			d.Subject, i.Subject, SUSER_SNAME(), 'Subject has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.RFIType=i.RFIType and d.RFI=i.RFI
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='RFI'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Subject,'') <> isnull(i.Subject,'') and isnull(c.DocHistRFI,'N') = 'Y'
	group by i.PMCo, i.Project, i.RFIType, i.RFI, i.Subject, d.Subject
	end
if update(RFIDate)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.RFIType),
			'RFI', i.RFIType, i.RFI, null, getdate(), 'C', 'RFIDate',
			convert(char(8),d.RFIDate,1), convert(char(8),i.RFIDate,1), SUSER_SNAME(), 'RFI Date has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.RFIType=i.RFIType and d.RFI=i.RFI
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='RFI'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.RFIDate,'') <> isnull(i.RFIDate,'') and isnull(c.DocHistRFI,'N') = 'Y'
	group by i.PMCo, i.Project, i.RFIType, i.RFI, i.RFIDate, d.RFIDate
	end
if update(DateDue)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.RFIType),
			'RFI', i.RFIType, i.RFI, null, getdate(), 'C', 'DateDue',
			convert(char(8),d.DateDue,1), convert(char(8),i.DateDue,1), SUSER_SNAME(), 'Date Due has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.RFIType=i.RFIType and d.RFI=i.RFI
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='RFI'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.DateDue,'') <> isnull(i.DateDue,'') and isnull(c.DocHistRFI,'N') = 'Y'
	group by i.PMCo, i.Project, i.RFIType, i.RFI, i.DateDue, d.DateDue
	end
if update(Issue)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.RFIType),
			'RFI', i.RFIType, i.RFI, null, getdate(), 'C', 'Issue',
			convert(varchar(10),d.Issue), convert(varchar(10),i.Issue),  SUSER_SNAME(), 'Issue has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.RFIType=i.RFIType and d.RFI=i.RFI
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='RFI'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Issue,0) <> isnull(i.Issue,0) and isnull(c.DocHistRFI,'N') = 'Y'
	group by i.PMCo, i.Project, i.RFIType, i.RFI, i.Issue, d.Issue
	end
if update(Status)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.RFIType),
			'RFI', i.RFIType, i.RFI, null, getdate(), 'C', 'Status',
			d.Status, i.Status, SUSER_SNAME(), 'Status has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.RFIType=i.RFIType and d.RFI=i.RFI
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='RFI'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Status,'') <> isnull(i.Status,'') and isnull(c.DocHistRFI,'N') = 'Y'
	group by i.PMCo, i.Project, i.RFIType, i.RFI, i.Status, d.Status
	end
if update(Submittal)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.RFIType),
			'RFI', i.RFIType, i.RFI, null, getdate(), 'C', 'Submittal',
			d.Submittal, i.Submittal, SUSER_SNAME(), 'Submittal has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.RFIType=i.RFIType and d.RFI=i.RFI
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='RFI'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Submittal,'') <> isnull(i.Submittal,'') and isnull(c.DocHistRFI,'N') = 'Y'
	group by i.PMCo, i.Project, i.RFIType, i.RFI, i.Submittal, d.Submittal
	end
if update(Drawing)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.RFIType),
			'RFI', i.RFIType, i.RFI, null, getdate(), 'C', 'Drawing',
			d.Drawing, i.Drawing, SUSER_SNAME(), 'Drawing has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.RFIType=i.RFIType and d.RFI=i.RFI
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='RFI'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Drawing,'') <> isnull(i.Drawing,'') and isnull(c.DocHistRFI,'N') = 'Y'
	group by i.PMCo, i.Project, i.RFIType, i.RFI, i.Drawing, d.Drawing
	end
if update(SpecSec)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.RFIType),
			'RFI', i.RFIType, i.RFI, null, getdate(), 'C', 'Spec Section',
			d.SpecSec, i.SpecSec, SUSER_SNAME(), 'SpecSec has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.RFIType=i.RFIType and d.RFI=i.RFI
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='RFI'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.SpecSec,'') <> isnull(i.SpecSec,'') and isnull(c.DocHistRFI,'N') = 'Y'
	group by i.PMCo, i.Project, i.RFIType, i.RFI, i.SpecSec, d.SpecSec
	end
if update(ScheduleNo)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.RFIType),
			'RFI', i.RFIType, i.RFI, null, getdate(), 'C', 'ScheduleNo',
			d.ScheduleNo, i.ScheduleNo, SUSER_SNAME(), 'Schedule No has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.RFIType=i.RFIType and d.RFI=i.RFI
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='RFI'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.ScheduleNo,'') <> isnull(i.ScheduleNo,'') and isnull(c.DocHistRFI,'N') = 'Y'
	group by i.PMCo, i.Project, i.RFIType, i.RFI, i.ScheduleNo, d.ScheduleNo
	end
if update(Addendum)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.RFIType),
			'RFI', i.RFIType, i.RFI, null, getdate(), 'C', 'Addendum',
			d.Addendum, i.Addendum, SUSER_SNAME(), 'Addendum has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.RFIType=i.RFIType and d.RFI=i.RFI
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='RFI'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Addendum,'') <> isnull(i.Addendum,'') and isnull(c.DocHistRFI,'N') = 'Y'
	group by i.PMCo, i.Project, i.RFIType, i.RFI, i.Addendum, d.Addendum
	end
if update(ResponsiblePerson)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.RFIType),
			'RFI', i.RFIType, i.RFI, null, getdate(), 'C', 'ResponsiblePerson',
			convert(varchar(10),d.ResponsiblePerson), convert(varchar(10),i.ResponsiblePerson), SUSER_SNAME(), 'Responsible Person has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.RFIType=i.RFIType and d.RFI=i.RFI
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='RFI'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.ResponsiblePerson,0) <> isnull(i.ResponsiblePerson,0) and isnull(c.DocHistRFI,'N') = 'Y'
	group by i.PMCo, i.Project, i.RFIType, i.RFI, i.ResponsiblePerson, d.ResponsiblePerson
	end
if update(ReqFirm)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.RFIType),
			'RFI', i.RFIType, i.RFI, null, getdate(), 'C', 'ReqFirm',
			convert(varchar(10),d.ReqFirm), convert(varchar(10),i.ReqFirm), SUSER_SNAME(), 'Requesting Firm has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.RFIType=i.RFIType and d.RFI=i.RFI
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='RFI'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.ReqFirm,0) <> isnull(i.ReqFirm,0) and isnull(c.DocHistRFI,'N') = 'Y'
	group by i.PMCo, i.Project, i.RFIType, i.RFI, i.ReqFirm, d.ReqFirm
	end
if update(ReqContact)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.RFIType),
			'RFI', i.RFIType, i.RFI, null, getdate(), 'C', 'ReqContact',
			convert(varchar(10),d.ReqContact), convert(varchar(10),i.ReqContact), SUSER_SNAME(), 'Requesting Contact has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.RFIType=i.RFIType and d.RFI=i.RFI
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='RFI'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.ReqContact,0) <> isnull(i.ReqContact,0) and isnull(c.DocHistRFI,'N') = 'Y'
	group by i.PMCo, i.Project, i.RFIType, i.RFI, i.ReqContact, d.ReqContact
	end
if update(RespondFirm)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.RFIType),
			'RFI', i.RFIType, i.RFI, null, getdate(), 'C', 'RespondFirm',
			convert(varchar(10),d.RespondFirm), convert(varchar(10),i.RespondFirm), SUSER_SNAME(), 'Responding Firm has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.RFIType=i.RFIType and d.RFI=i.RFI
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='RFI'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.RespondFirm,0) <> isnull(i.RespondFirm,0) and isnull(c.DocHistRFI,'N') = 'Y'
	group by i.PMCo, i.Project, i.RFIType, i.RFI, i.RespondFirm, d.RespondFirm
	end
if update(RespondContact)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.RFIType),
			'RFI', i.RFIType, i.RFI, null, getdate(), 'C', 'RespondContact',
			convert(varchar(10),d.RespondContact), convert(varchar(10),i.RespondContact), SUSER_SNAME(), 'Responding Contact has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.RFIType=i.RFIType and d.RFI=i.RFI
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='RFI'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.RespondContact,0) <> isnull(i.RespondContact,0) and isnull(c.DocHistRFI,'N') = 'Y'
	group by i.PMCo, i.Project, i.RFIType, i.RFI, i.RespondContact, d.RespondContact
	end
if update(ImpactDesc)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.RFIType),
			'RFI', i.RFIType, i.RFI, null, getdate(), 'C', 'ImpactDesc',
			d.ImpactDesc, i.ImpactDesc, SUSER_SNAME(), 'Impact Description has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.RFIType=i.RFIType and d.RFI=i.RFI
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='RFI'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.ImpactDesc,'') <> isnull(i.ImpactDesc,'') and isnull(c.DocHistRFI,'N') = 'Y'
	group by i.PMCo, i.Project, i.RFIType, i.RFI, i.ImpactDesc, d.ImpactDesc
	end
if update(ImpactDays)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.RFIType),
			'RFI', i.RFIType, i.RFI, null, getdate(), 'C', 'ImpactDays',
			convert(varchar(6),d.ImpactDays), convert(varchar(6),i.ImpactDays), SUSER_SNAME(), 'Impact Days has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.RFIType=i.RFIType and d.RFI=i.RFI
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='RFI'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.ImpactDays,0) <> isnull(i.ImpactDays,0) and isnull(c.DocHistRFI,'N') = 'Y'
	group by i.PMCo, i.Project, i.RFIType, i.RFI, i.ImpactDays, d.ImpactDays
	end
if update(ImpactCosts)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.RFIType),
			'RFI', i.RFIType, i.RFI, null, getdate(), 'C', 'ImpactCosts',
			convert(varchar(14),d.ImpactCosts), convert(varchar(14),i.ImpactCosts), SUSER_SNAME(), 'Impact Costs has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.RFIType=i.RFIType and d.RFI=i.RFI
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='RFI'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.ImpactCosts,0) <> isnull(i.ImpactCosts,0) and isnull(c.DocHistRFI,'N') = 'Y'
	group by i.PMCo, i.Project, i.RFIType, i.RFI, i.ImpactCosts, d.ImpactCosts
	end
if update(ImpactPrice)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.RFIType),
			'RFI', i.RFIType, i.RFI, null, getdate(), 'C', 'ImpactPrice',
			convert(varchar(14),d.ImpactPrice), convert(varchar(14),i.ImpactPrice), SUSER_SNAME(), 'Impact Price has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.RFIType=i.RFIType and d.RFI=i.RFI
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='RFI'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.ImpactPrice,0) <> isnull(i.ImpactPrice,0) and isnull(c.DocHistRFI,'N') = 'Y'
	group by i.PMCo, i.Project, i.RFIType, i.RFI, i.ImpactPrice, d.ImpactPrice
	end
if update(DateSent)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.RFIType),
			'RFI', i.RFIType, i.RFI, null, getdate(), 'C', 'DateSent',
			convert(char(8),d.DateSent,1), convert(char(8),i.DateSent,1), SUSER_SNAME(), 'Date Sent has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.RFIType=i.RFIType and d.RFI=i.RFI
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='RFI'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.DateSent,'') <> isnull(i.DateSent,'') and isnull(c.DocHistRFI,'N') = 'Y'
	group by i.PMCo, i.Project, i.RFIType, i.RFI, i.DateSent, d.DateSent
	end
if update(DateRecd)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.RFIType),
			'RFI', i.RFIType, i.RFI, null, getdate(), 'C', 'DateRecd',
			convert(char(8),d.DateRecd,1), convert(char(8),i.DateRecd,1), SUSER_SNAME(), 'Date Received has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.RFIType=i.RFIType and d.RFI=i.RFI
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='RFI'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.DateRecd,'') <> isnull(i.DateRecd,'') and isnull(c.DocHistRFI,'N') = 'Y'
	group by i.PMCo, i.Project, i.RFIType, i.RFI, i.DateRecd, d.DateRecd
	end
if update(PrefMethod)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.RFIType),
			'RFI', i.RFIType, i.RFI, null, getdate(), 'C', 'PrefMethod',
			d.PrefMethod, i.PrefMethod, SUSER_SNAME(), 'Preferred Method has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.RFIType=i.RFIType and d.RFI=i.RFI
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='RFI'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.PrefMethod,'') <> isnull(i.PrefMethod,'') and isnull(c.DocHistRFI,'N') = 'Y'
	group by i.PMCo, i.Project, i.RFIType, i.RFI, i.PrefMethod, d.PrefMethod
	end


RETURN 

GO
ALTER TABLE [dbo].[bPMRI] WITH NOCHECK ADD CONSTRAINT [CK_bPMRI_ReqContact] CHECK (([ReqContact] IS NULL OR [ReqFirm] IS NOT NULL))
GO
ALTER TABLE [dbo].[bPMRI] WITH NOCHECK ADD CONSTRAINT [CK_bPMRI_RespondContact] CHECK (([RespondContact] IS NULL OR [RespondFirm] IS NOT NULL))
GO
ALTER TABLE [dbo].[bPMRI] ADD CONSTRAINT [PK_bPMRI] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_bPMRI_RFI] ON [dbo].[bPMRI] ([PMCo], [Project], [RFIType], [RFI]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bPMRI] WITH NOCHECK ADD CONSTRAINT [FK_bPMRI_bJCJM] FOREIGN KEY ([PMCo], [Project]) REFERENCES [dbo].[bJCJM] ([JCCo], [Job])
GO
ALTER TABLE [dbo].[bPMRI] WITH NOCHECK ADD CONSTRAINT [FK_bPMRI_bPMDT] FOREIGN KEY ([RFIType]) REFERENCES [dbo].[bPMDT] ([DocType])
GO
ALTER TABLE [dbo].[bPMRI] WITH NOCHECK ADD CONSTRAINT [FK_bPMRI_bPMSC] FOREIGN KEY ([Status]) REFERENCES [dbo].[bPMSC] ([Status])
GO
ALTER TABLE [dbo].[bPMRI] WITH NOCHECK ADD CONSTRAINT [FK_bPMRI_bPMFM_ReqFirm] FOREIGN KEY ([VendorGroup], [ReqFirm]) REFERENCES [dbo].[bPMFM] ([VendorGroup], [FirmNumber])
GO
ALTER TABLE [dbo].[bPMRI] WITH NOCHECK ADD CONSTRAINT [FK_bPMRI_bPMPM_ReqContact] FOREIGN KEY ([VendorGroup], [ReqFirm], [ReqContact]) REFERENCES [dbo].[bPMPM] ([VendorGroup], [FirmNumber], [ContactCode])
GO
ALTER TABLE [dbo].[bPMRI] WITH NOCHECK ADD CONSTRAINT [FK_bPMRI_bPMFM_RespondFirm] FOREIGN KEY ([VendorGroup], [RespondFirm]) REFERENCES [dbo].[bPMFM] ([VendorGroup], [FirmNumber])
GO
ALTER TABLE [dbo].[bPMRI] WITH NOCHECK ADD CONSTRAINT [FK_bPMRI_bPMPM_RespondContact] FOREIGN KEY ([VendorGroup], [RespondFirm], [RespondContact]) REFERENCES [dbo].[bPMPM] ([VendorGroup], [FirmNumber], [ContactCode])
GO
ALTER TABLE [dbo].[bPMRI] WITH NOCHECK ADD CONSTRAINT [FK_bPMRI_bPMPM_ResponsiblePerson] FOREIGN KEY ([VendorGroup], [ResponsibleFirm], [ResponsiblePerson]) REFERENCES [dbo].[bPMPM] ([VendorGroup], [FirmNumber], [ContactCode])
GO
