CREATE TABLE [dbo].[bPMOH]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bJob] NOT NULL,
[ACO] [dbo].[bACO] NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[ACOSequence] [int] NULL,
[Issue] [dbo].[bIssue] NULL,
[Contract] [dbo].[bContract] NOT NULL,
[ChangeDays] [smallint] NULL,
[NewCmplDate] [dbo].[bDate] NULL,
[IntExt] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[DateSent] [dbo].[bDate] NULL,
[DateReqd] [dbo].[bDate] NULL,
[DateRecd] [dbo].[bDate] NULL,
[ApprovalDate] [dbo].[bDate] NOT NULL,
[ApprovedBy] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[BillGroup] [dbo].[bBillingGroup] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[ReadyForAcctg] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMOH_ReadyForAcctg] DEFAULT ('Y'),
[udSource] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTableID] [decimal] (12, 0) NULL,
[DocType] [dbo].[bDocType] NOT NULL CONSTRAINT [DF_bPMOH_DocType] DEFAULT ('ACO')
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
ALTER TABLE [dbo].[bPMOH] ADD
CONSTRAINT [FK_bPMOH_bPMDT] FOREIGN KEY ([DocType]) REFERENCES [dbo].[bPMDT] ([DocType])
ALTER TABLE [dbo].[bPMOH] ADD
CONSTRAINT [FK_bPMOH_bJCCM] FOREIGN KEY ([PMCo], [Contract]) REFERENCES [dbo].[bJCCM] ([JCCo], [Contract])
ALTER TABLE [dbo].[bPMOH] ADD
CONSTRAINT [FK_bPMOH_bJCJM] FOREIGN KEY ([PMCo], [Project]) REFERENCES [dbo].[bJCJM] ([JCCo], [Job])
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMOHd    Script Date: 8/28/99 9:37:55 AM ******/
CREATE trigger [dbo].[btPMOHd] on [dbo].[bPMOH] for DELETE as
/*--------------------------------------------------------------
 * Delete trigger for PMOH
 * Created By:	LM 1/15/98
 * Modified By:	GF 12/10/2006 - 6.x document history
 *				GF 02/01/2007 - issue #123699 issue history
 *				GF 12/21/2010 - issue #141957 record association
 *				GF 01/26/2011 - TFS #398
 *				JayR 03/23/2012 - TK-00000 Change to use FKs for validation.
 *
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on


---- when the record is related to a project issue PMIM
---- we need to add a delete action recorded in history for the issue
---- noting that the type and code with a description ws deleted.
---- record side. TFS #398
---- delete
DELETE dbo.vPMIssueHistory FROM deleted d WHERE RelatedTableName = 'bPMOH' AND RelatedKeyID = d.KeyID
---- insert
INSERT dbo.vPMIssueHistory (IssueKeyID,RelatedTableName,RelatedKeyID,Co,Project,Issue,ActionType,RelatedDeleteAction)
SELECT x.KeyID, 'bPMOH', d.KeyID, d.PMCo, d.Project, x.Issue, 'D',
		'ACO: ' + ISNULL(d.ACO,'') + ' : ' + ISNULL(d.Description,'')	
from deleted d
JOIN dbo.vPMRelateRecord r ON r.RecTableName = 'PMOH' AND r.RECID = d.KeyID AND r.LinkTableName = 'PMIM'
JOIN dbo.bPMIM x ON x.KeyID = r.LINKID
WHERE d.KeyID=r.RECID
---- link side
INSERT dbo.vPMIssueHistory (IssueKeyID,RelatedTableName,RelatedKeyID,Co,Project,Issue,ActionType,RelatedDeleteAction)
SELECT x.KeyID, 'bPMOH', d.KeyID, d.PMCo, d.Project, x.Issue, 'D',
		'ACO: ' + ISNULL(d.ACO,'')  + ' : ' + ISNULL(d.Description,'')
from deleted d
JOIN dbo.vPMRelateRecord r ON r.LinkTableName = 'PMOH' AND r.LINKID = d.KeyID AND r.RecTableName = 'PMIM'
JOIN dbo.bPMIM x ON x.KeyID = r.RECID
WHERE d.KeyID=r.LINKID

---- delete associations if any from both sides - #141957
---- record side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='PMOH' AND a.RECID=d.KeyID
WHERE d.KeyID IS NOT NULL
---- link side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMRelateRecord a ON a.LinkTableName='PMOH' AND a.LINKID=d.KeyID
WHERE d.KeyID IS NOT NULL


---- document history (bPMDH)
insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
		'ACO', null, i.ACO, null, getdate(), 'D', 'ACO', i.ACO, null,
		SUSER_SNAME(), 'ACO: ' + isnull(i.ACO,'') + ' has been deleted.', null
from deleted i
left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='ACO'
join bPMCO c with (nolock) on i.PMCo=c.PMCo
left join bJCJM j with (nolock) on j.JCCo=i.PMCo and j.Job=i.Project
where j.ClosePurgeFlag <> 'Y' and c.DocHistACO = 'Y'
group by i.PMCo, i.Project, i.ACO


RETURN 
   
  
 









GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMOHi    Script Date: 8/28/99 9:37:55 AM ******/
CREATE trigger [dbo].[btPMOHi] on [dbo].[bPMOH] for INSERT as
/*--------------------------------------------------------------
 * Insert trigger for PMOH
 * Created By:	LM 1/15/98
 * Modified By:	JRE 7/24/98 changed from COSEQ as ACO
 *				 GF 07/24/98 reject if ACO Sequence is null
 *				 GF 10/09/2002 - changed dbl quotes to single quotes
 *				GF 11/09/2004 - issue #22768 cleanup changed from pseudo to local cursor
 *				GF 02/01/2007 - issue #123699 updated for PMDH and PMIH for 6.x
 *				GF 10/08/2010 - issue #141648
 *				GF 01/26/2011 - tfs #398
 *				JayR 03/23/2012 - TK-00000 Change to use FKs for validation
 *
 *
 *--------------------------------------------------------------*/


if @@rowcount = 0 return
set nocount on

---- document history (bPMDH)
insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, Action)
select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
		'ACO', null, i.ACO, null, getdate(), 'A', 'ACO', null, i.ACO, SUSER_SNAME(),
		'ACO: ' + isnull(i.ACO,'') + ' has been added.'
from inserted i 
left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='ACO'
join bPMCO c with (nolock) on i.PMCo=c.PMCo
where c.DocHistACO = 'Y'
group by i.PMCo, i.Project, i.ACO


RETURN 



   
   
  
 








GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/****** Object:  Trigger dbo.btPMOHu    Script Date: 8/28/99 9:37:56 AM ******/
CREATE  trigger [dbo].[btPMOHu] on [dbo].[bPMOH] for UPDATE as
/*--------------------------------------------------------------
 * Update trigger for PMOH
 * Created By:	LM 1/15/98
 * Modified By: GF 07/28/98 Reject insert if ACOSequence is null
 *				GF 10/09/2002 - changed dbl quotes to single quotes
 *				GF 11/09/2004 - issue #22768 cleanup changed from pseudo to local cursor
 *				GF 12/08/2006 - 6.x document history enhancement
 *				GF 02/07/2007 - issue #123699 issue history
 *				GF 10/08/2010 - issue #141648
 *				GF 05/24/2011 - TK-05347 ready for accounting flag
 *				TRL 11/14/2011 - TK-09940 added to PMOH to update statement for ReadyForAcctg
 *				GF 01/22/2012 - TK-08852 remmed out ready for accounting update. Confusion around for customers
 *				JayR 03/23/2012 TK-00000 Change from to using FKs for validation.
 *
 *
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

---- check for changes to PMCo
if update(PMCo)
       begin
       RAISERROR('Cannot change PM Company - cannot update PMOH', 11, -1)
       ROLLBACK TRANSACTION
       RETURN 
       end

---- check for changes to Project
if update(Project)
       begin
       RAISERROR('Cannot change Project - cannot update PMOH', 11, -1)
       ROLLBACK TRANSACTION
       RETURN 
       end

---- check for changes to ACO
if update(ACO)
       begin
       RAISERROR('Cannot change Approved Change Order # - cannot update PMOH', 11, -1)
       ROLLBACK TRANSACTION
       RETURN 
       end

---- document history updates (bPMDH)
if update(Description)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			'ACO', null, i.ACO, null, getdate(), 'C', 'Description',
			d.Description, i.Description, SUSER_SNAME(), 'Description has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.ACO=i.ACO
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='ACO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Description,'') <> isnull(i.Description,'') and isnull(c.DocHistACO,'N') = 'Y'
	group by i.PMCo, i.Project, i.ACO, i.Description, d.Description
	end
if update(Issue)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			'ACO', null, i.ACO, null, getdate(), 'C', 'Issue',
			convert(varchar(8),d.Issue), convert(varchar(8),i.Issue),  SUSER_SNAME(), 'Issue has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.ACO=i.ACO
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='ACO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Issue,0) <> isnull(i.Issue,0) and isnull(c.DocHistACO,'N') = 'Y'
	group by i.PMCo, i.Project, i.ACO, i.Issue, d.Issue
	end
if update(DateSent)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			'ACO', null, i.ACO, null, getdate(), 'C', 'DateSent',
			convert(char(8),d.DateSent,1), convert(char(8),i.DateSent,1), SUSER_SNAME(), 'Date Sent has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.ACO=i.ACO
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='ACO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.DateSent,'') <> isnull(i.DateSent,'') and isnull(c.DocHistACO,'N') = 'Y'
	group by i.PMCo, i.Project, i.ACO, i.DateSent, d.DateSent
	end
if update(DateReqd)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			'ACO', null, i.ACO, null, getdate(), 'C', 'DateReqd',
			convert(char(8),d.DateReqd,1), convert(char(8),i.DateReqd,1), SUSER_SNAME(), 'Date Reqd has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.ACO=i.ACO
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='ACO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.DateReqd,'') <> isnull(i.DateReqd,'') and isnull(c.DocHistACO,'N') = 'Y'
	group by i.PMCo, i.Project, i.ACO, i.DateReqd, d.DateReqd
	end
if update(DateRecd)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			'ACO', null, i.ACO, null, getdate(), 'C', 'DateRecd',
			convert(char(8),d.DateRecd,1), convert(char(8),i.DateRecd,1), SUSER_SNAME(), 'Date Recd has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.ACO=i.ACO
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='ACO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.DateRecd,'') <> isnull(i.DateRecd,'') and isnull(c.DocHistACO,'N') = 'Y'
	group by i.PMCo, i.Project, i.ACO, i.DateRecd, d.DateRecd
	end
if update(IntExt)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			'ACO', null, i.ACO, null, getdate(), 'C', 'IntExt',
			d.IntExt, i.IntExt, SUSER_SNAME(), 'IntExt Flag has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.ACO=i.ACO
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='ACO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.IntExt,'') <> isnull(i.IntExt,'') and isnull(c.DocHistACO,'N') = 'Y'
	group by i.PMCo, i.Project, i.ACO, i.IntExt, d.IntExt
	end
if update(ACOSequence)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			'ACO', null, i.ACO, null, getdate(), 'C', 'ACOSequence',
			convert(varchar(8),d.ACOSequence), convert(varchar(8),i.ACOSequence),  SUSER_SNAME(), 'ACO Seq has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.ACO=i.ACO
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='ACO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.ACOSequence,0) <> isnull(i.ACOSequence,0) and isnull(c.DocHistACO,'N') = 'Y'
	group by i.PMCo, i.Project, i.ACO, i.ACOSequence, d.ACOSequence
	end
if update(BillGroup)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			'ACO', null, i.ACO, null, getdate(), 'C', 'BillGroup',
			d.BillGroup, i.BillGroup, SUSER_SNAME(), 'Bill Group has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.ACO=i.ACO
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='ACO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.BillGroup,'') <> isnull(i.BillGroup,'') and isnull(c.DocHistACO,'N') = 'Y'
	group by i.PMCo, i.Project, i.ACO, i.BillGroup, d.BillGroup
	end
if update(NewCmplDate)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			'ACO', null, i.ACO, null, getdate(), 'C', 'NewCmplDate',
			convert(char(8),d.NewCmplDate,1), convert(char(8),i.NewCmplDate,1), SUSER_SNAME(), 'New Cmpl Date has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.ACO=i.ACO
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='ACO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.NewCmplDate,'') <> isnull(i.NewCmplDate,'') and isnull(c.DocHistACO,'N') = 'Y'
	group by i.PMCo, i.Project, i.ACO, i.NewCmplDate, d.NewCmplDate
	end
if update(ApprovalDate)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			'ACO', null, i.ACO, null, getdate(), 'C', 'ApprovalDate',
			convert(char(8),d.ApprovalDate,1), convert(char(8),i.ApprovalDate,1), SUSER_SNAME(), 'Approval Date has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.ACO=i.ACO
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='ACO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.ApprovalDate,'') <> isnull(i.ApprovalDate,'') and isnull(c.DocHistACO,'N') = 'Y'
	group by i.PMCo, i.Project, i.ACO, i.ApprovalDate, d.ApprovalDate
	end
if update(ApprovedBy)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			'ACO', null, i.ACO, null, getdate(), 'C', 'ApprovedBy',
			d.ApprovedBy, i.ApprovedBy, SUSER_SNAME(), 'Approved By has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.ACO=i.ACO
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='ACO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.ApprovedBy,'') <> isnull(i.ApprovedBy,'') and isnull(c.DocHistACO,'N') = 'Y'
	group by i.PMCo, i.Project, i.ACO, i.ApprovedBy, d.ApprovedBy
	end




RETURN 



GO
ALTER TABLE [dbo].[bPMOH] ADD CONSTRAINT [CK_bPMOH_IntExt] CHECK (([IntExt] = 'E' OR [IntExt] = 'I'))
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMOH] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPMOH] ON [dbo].[bPMOH] ([PMCo], [Project], [ACO]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
