CREATE TABLE [dbo].[bPMTM]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bJob] NOT NULL,
[Transmittal] [dbo].[bDocument] NOT NULL,
[Subject] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[TransDate] [dbo].[bDate] NOT NULL,
[DateSent] [dbo].[bDate] NULL,
[DateDue] [dbo].[bDate] NULL,
[Issue] [dbo].[bIssue] NULL,
[CreatedBy] [dbo].[bVPUserName] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[ResponsibleFirm] [dbo].[bFirm] NULL,
[ResponsiblePerson] [dbo].[bEmployee] NULL,
[DateResponded] [dbo].[bDate] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMTMd    Script Date: 8/28/99 9:38:02 AM ******/
CREATE trigger [dbo].[btPMTMd] on [dbo].[bPMTM] for DELETE as
/*--------------------------------------------------------------
 *  Delete trigger for PMTM
 *  Created By:     LM 01/01/1998
 *  Modified By:    GF 09/07/2000
 *					GF 10/12/2006 - changes for 6.x PMDH document history.
 *					GF 02/01/2007 - issue #123699 issue history
 *					GF 04/24/2008 - issue #125958 delete PM distribution audit
 *					GF 12/21/2010 - issue #141957 record association
 *					GF 01/26/2011 - TFS #398
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on


---- delete PM distribution audit tables if any
delete bPMHA from bPMHA a join bPMHI i on i.KeyId=a.PMHIKeyId
join deleted d on i.SourceTableName='PMTM' and i.SourceKeyId=d.KeyID

delete bPMHF from bPMHF a join bPMHI i on i.KeyId=a.PMHIKeyId
join deleted d on i.SourceTableName='PMTM' and i.SourceKeyId=d.KeyID

delete bPMHI from bPMHI i
join deleted d on i.SourceTableName='PMTM' and i.SourceKeyId=d.KeyID


---- when the record is related to a project issue PMIM
---- we need to add a delete action recorded in history for the issue
---- noting that the type and code with a description ws deleted.
---- record side. TFS #398
---- delete
DELETE dbo.vPMIssueHistory FROM deleted d WHERE RelatedTableName = 'bPMTM' AND RelatedKeyID = d.KeyID
---- insert
INSERT dbo.vPMIssueHistory (IssueKeyID,RelatedTableName,RelatedKeyID,Co,Project,Issue,ActionType,RelatedDeleteAction)
SELECT x.KeyID, 'bPMTM', d.KeyID, d.PMCo, d.Project, x.Issue, 'D',
		'Transmittal: ' + ISNULL(d.Transmittal,'') + ' : ' + ISNULL(d.Subject,'')	
from deleted d
JOIN dbo.vPMRelateRecord r ON r.RecTableName = 'PMTM' AND r.RECID = d.KeyID AND r.LinkTableName = 'PMIM'
JOIN dbo.bPMIM x ON x.KeyID = r.LINKID
WHERE d.KeyID=r.RECID
---- link side
INSERT dbo.vPMIssueHistory (IssueKeyID,RelatedTableName,RelatedKeyID,Co,Project,Issue,ActionType,RelatedDeleteAction)
SELECT x.KeyID, 'bPMTM', d.KeyID, d.PMCo, d.Project, x.Issue, 'D',
		'Transmittal: ' + ISNULL(d.Transmittal,'') + ' : ' + ISNULL(d.Subject,'')	
from deleted d
JOIN dbo.vPMRelateRecord r ON r.LinkTableName = 'PMTM' AND r.LINKID = d.KeyID AND r.RecTableName = 'PMIM'
JOIN dbo.bPMIM x ON x.KeyID = r.RECID
WHERE d.KeyID=r.LINKID

---- delete associations if any from both sides - #141957
---- record side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='PMTM' AND a.RECID=d.KeyID
WHERE d.KeyID IS NOT NULL
---- link side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMRelateRecord a ON a.LinkTableName='PMTM' AND a.LINKID=d.KeyID
WHERE d.KeyID IS NOT NULL



---- document history (bPMDH)
insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
		'TRANSMIT', null, i.Transmittal, null, getdate(), 'D', 'Transmittal', i.Transmittal, null,
		SUSER_SNAME(), 'Transmittal: ' + isnull(i.Transmittal,'') + ' has been deleted.', null
from deleted i
left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='TRANSMIT'
join bPMCO c with (nolock) on i.PMCo=c.PMCo
left join bJCJM j with (nolock) on j.JCCo=i.PMCo and j.Job=i.Project
where j.ClosePurgeFlag <> 'Y' and c.DocHistTransmittal = 'Y'
group by i.PMCo, i.Project, i.Transmittal



RETURN 






















GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMTMi    Script Date: 8/28/99 9:38:02 AM ******/
CREATE trigger [dbo].[btPMTMi] on [dbo].[bPMTM] for INSERT as
/*--------------------------------------------------------------
 *  Insert trigger for PMTM
 *  Created By:		LM 1/16/98
 *	Modified By:	GF 01/15/2002
 *					GF 10/12/2006 - changes for 6.x PMDH document history.
 *					GF 02/01/2007 - issue #123699 issue history
 *					GF 10/08/2010 - issue #141648
 *					GF 01/26/2011 - tfs #398
 *					JayR 03/28/2012 TK-00000 Switch to using FKs for validation
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on


---- document history (bPMDH)
insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, Action)
select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
		'TRANSMIT', null, i.Transmittal, null, getdate(), 'A', 'Transmittal', null, i.Transmittal, SUSER_SNAME(),
		'Transmittal: ' + isnull(i.Transmittal,'') + ' has been added.'
from inserted i 
left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='TRANSMIT'
join bPMCO c with (nolock) on i.PMCo=c.PMCo
where c.DocHistTransmittal = 'Y'
group by i.PMCo, i.Project, i.Transmittal


RETURN 
   
   
  
 


























GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMTMu    Script Date: 8/28/99 9:38:02 AM ******/
CREATE trigger [dbo].[btPMTMu] on [dbo].[bPMTM] for UPDATE as
/*--------------------------------------------------------------
 *  Update trigger for PMTM
 *  Created By:		LM 1/16/98
 *	Modified By:	GF 01/15/2002
 *					GF 10/12/2006 - changes for 6.x PMDH document history.
 *					GF 02/06/2007 - issue #123699 issue history
  *				GF 10/08/2010 - issue #141648
 *
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

---- check for changes to PMCo
if update(PMCo)
      begin
      RAISERROR('Cannot change PMCo', 11, -1)
      ROLLBACK TRANSACTION
      RETURN
      end

---- check for changes to Project
if update(Project)
      begin
      RAISERROR('Cannot change Project', 11, -1)
      ROLLBACK TRANSACTION
      RETURN
      end

---- check for changes to Transmittal
if update(Transmittal)
      begin
      RAISERROR('Cannot change Transmittal', 11, -1)
      ROLLBACK TRANSACTION
      RETURN
      end


---- document history updates (bPMDH)
if update(ResponsiblePerson)
	begin
	insert into bPMDH(PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			'TRANSMIT', null, i.Transmittal, null, getdate(), 'C', 'ResponsiblePerson', convert(varchar(10),d.ResponsiblePerson),
			convert(varchar(10),i.ResponsiblePerson), SUSER_SNAME(), 'Responsible Person has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.Transmittal=i.Transmittal
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='TRANSMIT'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.ResponsiblePerson,0) <> isnull(i.ResponsiblePerson,0)
	and c.DocHistTransmittal = 'Y'
	group by i.PMCo, i.Project, i.Transmittal, i.ResponsiblePerson, d.ResponsiblePerson
	end
if update(DateSent)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			'TRANSMIT', null, i.Transmittal, null, getdate(), 'C', 'DateSent', convert(char(8),d.DateSent,1),
			convert(char(8),i.DateSent,1), SUSER_SNAME(), 'Date Sent has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.Transmittal=i.Transmittal
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='TRANSMIT'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.DateSent,'') <> isnull(i.DateSent,'')
	and c.DocHistTransmittal = 'Y'
	group by i.PMCo, i.Project, i.Transmittal, i.DateSent, d.DateSent
	end
if update(DateDue)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			'TRANSMIT', null, i.Transmittal, null, getdate(), 'C', 'DateDue', convert(char(8),d.DateDue,1),
			convert(char(8),i.DateDue,1), SUSER_SNAME(), 'Date Due has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.Transmittal=i.Transmittal
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='TRANSMIT'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.DateDue,'') <> isnull(i.DateDue,'')
	and c.DocHistTransmittal = 'Y'
	group by i.PMCo, i.Project, i.Transmittal, i.DateDue, d.DateDue
	end
if update(TransDate)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			'TRANSMIT' , null, i.Transmittal, null, getdate(), 'C', 'TransDate', convert(char(8),d.TransDate,1),
			convert(char(8),i.TransDate,1), SUSER_SNAME(), 'Transmittal Date has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.Transmittal=i.Transmittal
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='TRANSMIT'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.TransDate,'') <> isnull(i.TransDate,'')
	and c.DocHistTransmittal = 'Y'
	group by i.PMCo, i.Project, i.Transmittal, i.TransDate, d.TransDate
	end
if update(DateResponded)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			'TRANSMIT', null, i.Transmittal, null, getdate(), 'C', 'DateResponded', convert(char(8),d.DateResponded,1),
			convert(char(8),i.DateResponded,1), SUSER_SNAME(), 'Responded Date has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.Transmittal=i.Transmittal
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='TRANSMIT'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.DateResponded,'') <> isnull(i.DateResponded,'')
	and c.DocHistTransmittal = 'Y'
	group by i.PMCo, i.Project, i.Transmittal, i.DateResponded, d.DateResponded
	end
if update(Issue)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			'TRANSMIT', null, i.Transmittal, null, getdate(), 'C', 'Issue', convert(varchar(10),d.Issue),
			convert(char(10),i.Issue), SUSER_SNAME(), 'Issue has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.Transmittal=i.Transmittal
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='TRANSMIT'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Issue,0) <> isnull(i.Issue,0)
	and c.DocHistTransmittal = 'Y'
	group by i.PMCo, i.Project, i.Transmittal, i.Issue, d.Issue
	end
if update(Subject)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			'TRANSMIT', null, i.Transmittal, null, getdate(), 'C', 'Subject', d.Subject, i.Subject,
			SUSER_SNAME(), 'Subject has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.Transmittal=i.Transmittal
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='TRANSMIT'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Subject,'') <> isnull(i.Subject,'')
	and c.DocHistTransmittal = 'Y'
	group by i.PMCo, i.Project, i.Transmittal, i.Subject, d.Subject
	end



RETURN 

























GO
ALTER TABLE [dbo].[bPMTM] ADD CONSTRAINT [PK_bPMTM] PRIMARY KEY CLUSTERED  ([PMCo], [Project], [Transmittal]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMTM] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bPMTM] WITH NOCHECK ADD CONSTRAINT [FK_bPMTM_bJCJM] FOREIGN KEY ([PMCo], [Project]) REFERENCES [dbo].[bJCJM] ([JCCo], [Job])
GO
ALTER TABLE [dbo].[bPMTM] WITH NOCHECK ADD CONSTRAINT [FK_bPMTM_bPMPM] FOREIGN KEY ([VendorGroup], [ResponsibleFirm], [ResponsiblePerson]) REFERENCES [dbo].[bPMPM] ([VendorGroup], [FirmNumber], [ContactCode])
GO
