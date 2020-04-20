CREATE TABLE [dbo].[bPMOD]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bJob] NOT NULL,
[DocType] [dbo].[bDocType] NOT NULL,
[Document] [dbo].[bDocument] NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[Location] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[RelatedFirm] [dbo].[bFirm] NULL,
[Issue] [dbo].[bIssue] NULL,
[Status] [dbo].[bStatus] NULL,
[ResponsibleFirm] [dbo].[bFirm] NULL,
[ResponsiblePerson] [dbo].[bEmployee] NULL,
[DateDue] [dbo].[bDate] NULL,
[DateRecd] [dbo].[bDate] NULL,
[DateSent] [dbo].[bDate] NULL,
[DateDueBack] [dbo].[bDate] NULL,
[DateRecdBack] [dbo].[bDate] NULL,
[DateRetd] [dbo].[bDate] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
ALTER TABLE [dbo].[bPMOD] ADD
CONSTRAINT [FK_bPMOD_bJCJM] FOREIGN KEY ([PMCo], [Project]) REFERENCES [dbo].[bJCJM] ([JCCo], [Job])
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMODd    Script Date: 8/28/99 9:37:55 AM ******/
CREATE trigger [dbo].[btPMODd] on [dbo].[bPMOD] for DELETE as
/*--------------------------------------------------------------
 * Delete trigger for PMOD
 * Created By: LM 1/16/98
 * Modified By:	GF 11/26/2006 6.x
 *				GF 02/01/2007 - issue #123699 issue history
 *				GF 04/24/2008 - issue #125958 delete PMHI distribution audit
 *				GF 01/26/2011 - TFS #398
 *				JayR 03/23/2012 - TK-00000 Change to use FKs for validation
 *
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on


---- delete PMOC - Distributions
--delete bPMOC from bPMOC a 
--join deleted d on a.PMCo=d.PMCo and a.Project=d.Project and a.DocType=d.DocType and a.Document=d.Document
------ check PMOC
--if exists(select * from deleted d JOIN bPMOC o ON d.PMCo=o.PMCo and d.Project=o.Project
--				and d.DocType=o.DocType and d.Document=o.Document)
--	begin
--	select @errmsg = 'Distributions exist in PMOC, cannot delete document.'
--	goto error
--	end


---- delete PM distribution audit tables if any
delete bPMHA from bPMHA a join bPMHI i on i.KeyId=a.PMHIKeyId
join deleted d on i.SourceTableName='PMOD' and i.SourceKeyId=d.KeyID

delete bPMHF from bPMHF a join bPMHI i on i.KeyId=a.PMHIKeyId
join deleted d on i.SourceTableName='PMOD' and i.SourceKeyId=d.KeyID

delete bPMHI from bPMHI i
join deleted d on i.SourceTableName='PMOD' and i.SourceKeyId=d.KeyID


---- when the record is related to a project issue PMIM
---- we need to add a delete action recorded in history for the issue
---- noting that the type and code with a description ws deleted.
---- record side. TFS #398
---- delete
DELETE dbo.vPMIssueHistory FROM deleted d WHERE RelatedTableName = 'bPMOD' AND RelatedKeyID = d.KeyID
---- insert
INSERT dbo.vPMIssueHistory (IssueKeyID,RelatedTableName,RelatedKeyID,Co,Project,Issue,ActionType,RelatedDeleteAction)
SELECT x.KeyID, 'bPMOD', d.KeyID, d.PMCo, d.Project, x.Issue, 'D',
		'Other Doc Type: ' + ISNULL(d.DocType,'') + ' Other Doc: ' + ISNULL(d.Document,'') + ' : ' + ISNULL(d.Description,'')	
from deleted d
JOIN dbo.vPMRelateRecord r ON r.RecTableName = 'PMOD' AND r.RECID = d.KeyID AND r.LinkTableName = 'PMIM'
JOIN dbo.bPMIM x ON x.KeyID = r.LINKID
WHERE d.KeyID=r.RECID
---- link side
INSERT dbo.vPMIssueHistory (IssueKeyID,RelatedTableName,RelatedKeyID,Co,Project,Issue,ActionType,RelatedDeleteAction)
SELECT x.KeyID, 'bPMOD', d.KeyID, d.PMCo, d.Project, x.Issue, 'D',
		'Other Doc Type: ' + ISNULL(d.DocType,'') + ' Other Doc: ' + ISNULL(d.Document,'') + ' : ' + ISNULL(d.Description,'')
from deleted d
JOIN dbo.vPMRelateRecord r ON r.LinkTableName = 'PMOD' AND r.LINKID = d.KeyID AND r.RecTableName = 'PMIM'
JOIN dbo.bPMIM x ON x.KeyID = r.RECID
WHERE d.KeyID=r.LINKID

---- delete associations if any from both sides - #141957
---- record side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='PMOD' AND a.RECID=d.KeyID
WHERE d.KeyID IS NOT NULL
---- link side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMRelateRecord a ON a.LinkTableName='PMOD' AND a.LINKID=d.KeyID
WHERE d.KeyID IS NOT NULL



---- document history (bPMDH)
insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.DocType ASC),
		'OTHER', i.DocType, i.Document, null, getdate(), 'D', 'OTHER', i.Document, null,
		SUSER_SNAME(), 'Other Document: ' + isnull(i.Document,'') + ' has been deleted.', null
from deleted i
left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='OTHER'
join bPMCO c with (nolock) on i.PMCo=c.PMCo
left join bJCJM j with (nolock) on j.JCCo=i.PMCo and j.Job=i.Project
where j.ClosePurgeFlag <> 'Y' and isnull(c.DocHistOtherDoc,'N') = 'Y'
group by i.PMCo, i.Project, i.DocType, i.Document


RETURN 
   
  
 









GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMODi    Script Date: 8/28/99 9:37:55 AM ******/
CREATE trigger [dbo].[btPMODi] on [dbo].[bPMOD] for INSERT as
/*--------------------------------------------------------------
 * Insert trigger for PMOD
 * Created By:	LM 1/16/98
 * Modified By: GF 10/09/2002 - changed dbl quotes to single quotes
 *				GF 11/09/2004 - issue #22768 cleanup changed from pseudo to local cursor
 *				GF 11/26/2006 - 6.x document history and issue history
 *				GF 02/01/2007 - issue #123699 issue history
 *				GF 10/08/2010 - issue #141648
 *				GF 01/26/2011 - TFS #398
 *				JayR 03/23/2012 Change to use FKs for validation.
 *
 *
 *--------------------------------------------------------------*/
 DECLARE @numrows INT, @validcnt int
 
SET  @numrows = @@rowcount
if @@rowcount = 0 return
set nocount on



---- Validate Doc Type --
select @validcnt = count(*) from bPMDT r JOIN inserted i ON i.DocType = r.DocType and r.DocCategory = 'OTHER'
if @validcnt <> @numrows
	begin
	RAISERROR('Document Type is Invalid - cannot insert into bPMOD', 11, -1)
	ROLLBACK TRANSACTION
	RETURN
	end

---- document history (bPMDH)
insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, Action)
select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.DocType ASC),
		'OTHER', i.DocType, i.Document, null, getdate(), 'A', 'OTHER', null, i.Document, SUSER_SNAME(),
		'Other Document: ' + isnull(i.Document,'') + ' has been added.'
from inserted i
left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='OTHER'
join bPMCO c with (nolock) on i.PMCo=c.PMCo
where isnull(c.DocHistOtherDoc,'N') = 'Y'
group by i.PMCo, i.Project, i.DocType, i.Document


RETURN 





GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMODu    Script Date: 8/28/99 9:37:55 AM ******/
CREATE   trigger [dbo].[btPMODu] on [dbo].[bPMOD] for UPDATE as
/*--------------------------------------------------------------
 * Update trigger for PMOD
 * Created By:	LM 1/16/98
 * Modified By: GF 10/09/2002 - change dbl quotes to single quotes
 *				GF 11/09/2004 - issue #22768 cleanup changed from pseudo to local cursor
 *				GF 11/26/2006 - 6.x
 *				GF 02/07/2007 - issue #123699 issue history
 *				GF 10/08/2010 - issue #141648
 *				JayR 03/23/2012 - TK-00000 Change to use FKs for validation
 *
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

---- check for changes to PMCo
if update(PMCo)
   	begin
   	RAISERROR('Cannot change PMCo - cannot update PMOD', 11, -1)
   	ROLLBACK TRANSACTION
   	RETURN 
   	end

---- check for changes to Project
if update(Project)
   	begin
   	RAISERROR('Cannot change Project - cannot update PMOD', 11, -1)
   	ROLLBACK TRANSACTION
   	RETURN 
   	end

---- check for changes to DocType
if update(DocType)
   	begin
   	RAISERROR('Cannot change DocType - cannot update PMOD', 11, -1)
   	ROLLBACK TRANSACTION
   	RETURN 
   	end

---- check for changes to Document
if update(Document)
   	begin
   	RAISERROR('Cannot change Document - cannot update PMOD', 11, -1)
   	ROLLBACK TRANSACTION
   	RETURN 
   	end


---- document history updates (bPMDH)
if update(Description)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.DocType),
			'OTHER', i.DocType, i.Document, null, getdate(), 'C', 'Description',
			d.Description, i.Description, SUSER_SNAME(), 'Description has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.DocType=i.DocType and d.Document=i.Document
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='OTHER'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Description,'') <> isnull(i.Description,'') and isnull(c.DocHistOtherDoc,'N') = 'Y'
	group by i.PMCo, i.Project, i.DocType, i.Document, i.Description, d.Description
	end
if update(Issue)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.DocType),
			'OTHER', i.DocType, i.Document, null, getdate(), 'C', 'Issue',
			convert(varchar(8),d.Issue), convert(varchar(8),i.Issue),  SUSER_SNAME(), 'Issue has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.DocType=i.DocType and d.Document=i.Document
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='OTHER'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Issue,0) <> isnull(i.Issue,0) and isnull(c.DocHistOtherDoc,'N') = 'Y'
	group by i.PMCo, i.Project, i.DocType, i.Document, i.Issue, d.Issue
	end
if update(Status)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.DocType),
			'OTHER', i.DocType, i.Document, null, getdate(), 'C', 'Status',
			d.Status, i.Status, SUSER_SNAME(), 'Status has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.DocType=i.DocType and d.Document=i.Document
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='OTHER'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Status,'') <> isnull(i.Status,'') and isnull(c.DocHistOtherDoc,'N') = 'Y'
	group by i.PMCo, i.Project, i.DocType, i.Document, i.Status, d.Status
	end
if update(DateDue)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.DocType),
			'OTHER', i.DocType, i.Document, null, getdate(), 'C', 'DateDue',
			convert(char(8),d.DateDue,1), convert(char(8),i.DateDue,1), SUSER_SNAME(), 'Date Due has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.DocType=i.DocType and d.Document=i.Document
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='OTHER'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.DateDue,'') <> isnull(i.DateDue,'') and isnull(c.DocHistOtherDoc,'N') = 'Y'
	group by i.PMCo, i.Project, i.DocType, i.Document, i.DateDue, d.DateDue
	end
if update(DateRecd)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.DocType),
			'OTHER', i.DocType, i.Document, null, getdate(), 'C', 'DateRecd',
			convert(char(8),d.DateRecd,1), convert(char(8),i.DateRecd,1), SUSER_SNAME(), 'Date Recd has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.DocType=i.DocType and d.Document=i.Document
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='OTHER'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.DateRecd,'') <> isnull(i.DateRecd,'') and isnull(c.DocHistOtherDoc,'N') = 'Y'
	group by i.PMCo, i.Project, i.DocType, i.Document, i.DateRecd, d.DateRecd
	end
if update(DateSent)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.DocType),
			'OTHER', i.DocType, i.Document, null, getdate(), 'C', 'DateSent',
			convert(char(8),d.DateSent,1), convert(char(8),i.DateSent,1), SUSER_SNAME(), 'Date Sent has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.DocType=i.DocType and d.Document=i.Document
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='OTHER'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.DateSent,'') <> isnull(i.DateSent,'') and isnull(c.DocHistOtherDoc,'N') = 'Y'
	group by i.PMCo, i.Project, i.DocType, i.Document, i.DateSent, d.DateSent
	end
if update(DateDueBack)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.DocType),
			'OTHER', i.DocType, i.Document, null, getdate(), 'C', 'DateDueBack',
			convert(char(8),d.DateDueBack,1), convert(char(8),i.DateDueBack,1), SUSER_SNAME(), 'Date Due Back has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.DocType=i.DocType and d.Document=i.Document
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='OTHER'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.DateDueBack,'') <> isnull(i.DateDueBack,'') and isnull(c.DocHistOtherDoc,'N') = 'Y'
	group by i.PMCo, i.Project, i.DocType, i.Document, i.DateDueBack, d.DateDueBack
	end
if update(DateRecdBack)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.DocType),
			'OTHER', i.DocType, i.Document, null, getdate(), 'C', 'DateRecdBack',
			convert(char(8),d.DateRecdBack,1), convert(char(8),i.DateRecdBack,1), SUSER_SNAME(), 'Date Recd Back has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.DocType=i.DocType and d.Document=i.Document
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='OTHER'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.DateRecdBack,'') <> isnull(i.DateRecdBack,'') and isnull(c.DocHistOtherDoc,'N') = 'Y'
	group by i.PMCo, i.Project, i.DocType, i.Document, i.DateRecdBack, d.DateRecdBack
	end
if update(DateRetd)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.DocType),
			'OTHER', i.DocType, i.Document, null, getdate(), 'C', 'DateRetd',
			convert(char(8),d.DateRetd,1), convert(char(8),i.DateRetd,1), SUSER_SNAME(), 'Date Retd Back has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.DocType=i.DocType and d.Document=i.Document
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='OTHER'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.DateRetd,'') <> isnull(i.DateRetd,'') and isnull(c.DocHistOtherDoc,'N') = 'Y'
	group by i.PMCo, i.Project, i.DocType, i.Document, i.DateRetd, d.DateRetd
	end
if update(Location)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.DocType),
			'OTHER', i.DocType, i.Document, null, getdate(), 'C', 'Location',
			d.Location, i.Location, SUSER_SNAME(), 'Location has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.DocType=i.DocType and d.Document=i.Document
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='OTHER'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Location,'') <> isnull(i.Location,'') and isnull(c.DocHistOtherDoc,'N') = 'Y'
	group by i.PMCo, i.Project, i.DocType, i.Document, i.Location, d.Location
	end
if update(ResponsiblePerson)
	begin
	insert into bPMDH(PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.DocType),
			'OTHER', i.DocType, i.Document, null, getdate(), 'C', 'ResponsiblePerson',
			convert(varchar(8),d.ResponsiblePerson), convert(varchar(8),i.ResponsiblePerson), SUSER_SNAME(), 'Responsible Person has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.DocType=i.DocType and d.Document=i.Document
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='OTHER'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.ResponsiblePerson,0) <> isnull(i.ResponsiblePerson,0) and isnull(c.DocHistOtherDoc,'N') = 'Y'
	group by i.PMCo, i.Project, i.DocType, i.Document, i.ResponsiblePerson, d.ResponsiblePerson
	end
if update(RelatedFirm)
	begin
	insert into bPMDH(PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.DocType),
			'OTHER', i.DocType, i.Document, null, getdate(), 'C', 'RelatedFirm',
			convert(varchar(10),d.RelatedFirm), convert(varchar(10),i.RelatedFirm), SUSER_SNAME(), 'Related Firm has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.DocType=i.DocType and d.Document=i.Document
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='OTHER'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.RelatedFirm,0) <> isnull(i.RelatedFirm,0) and isnull(c.DocHistOtherDoc,'N') = 'Y'
	group by i.PMCo, i.Project, i.DocType, i.Document, i.RelatedFirm, d.RelatedFirm
	end



RETURN 








GO
ALTER TABLE [dbo].[bPMOD] ADD CONSTRAINT [PK_bPMOD] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMOD] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPMOD] ON [dbo].[bPMOD] ([PMCo], [Project], [DocType], [Document]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bPMOD] WITH NOCHECK ADD CONSTRAINT [FK_bPMOD_bPMDT] FOREIGN KEY ([DocType]) REFERENCES [dbo].[bPMDT] ([DocType])
GO

ALTER TABLE [dbo].[bPMOD] WITH NOCHECK ADD CONSTRAINT [FK_bPMOD_bPMSC] FOREIGN KEY ([Status]) REFERENCES [dbo].[bPMSC] ([Status])
GO
ALTER TABLE [dbo].[bPMOD] WITH NOCHECK ADD CONSTRAINT [FK_bPMOD_bPMFM] FOREIGN KEY ([VendorGroup], [RelatedFirm]) REFERENCES [dbo].[bPMFM] ([VendorGroup], [FirmNumber])
GO
ALTER TABLE [dbo].[bPMOD] WITH NOCHECK ADD CONSTRAINT [FK_bPMOD_bPMPM] FOREIGN KEY ([VendorGroup], [ResponsibleFirm], [ResponsiblePerson]) REFERENCES [dbo].[bPMPM] ([VendorGroup], [FirmNumber], [ContactCode])
GO
