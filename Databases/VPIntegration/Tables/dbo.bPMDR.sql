CREATE TABLE [dbo].[bPMDR]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bJob] NOT NULL,
[DrawingType] [dbo].[bDocType] NOT NULL,
[Drawing] [dbo].[bDocument] NOT NULL,
[Rev] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[RevisionDate] [dbo].[bDate] NULL,
[Status] [dbo].[bStatus] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[Description] [dbo].[bItemDesc] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[Issue] [dbo].[bIssue] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/******************************************/
CREATE trigger [dbo].[btPMDRd] on [dbo].[bPMDR] for DELETE as
/*--------------------------------------------------------------
 * Delete trigger for PMDR
 * Created By:	GF 11/11/2006
 * Modified By:	GF 10/22/2009 - #135749 issue history
 *				GF 12/21/2010 - issue #141957 record association
 *				GF 01/26/2011 - TFS #398
 *				JayR 03/21/2012 Remove gotos and unused variables
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on


---- when the record is related to a project issue PMIM
---- we need to add a delete action recorded in history for the issue
---- noting that the type and code with a description ws deleted.
---- record side. TFS #398
---- delete
DELETE dbo.vPMIssueHistory FROM deleted d WHERE RelatedTableName = 'bPMDR' AND RelatedKeyID = d.KeyID
---- insert
INSERT dbo.vPMIssueHistory (IssueKeyID,RelatedTableName,RelatedKeyID,Co,Project,Issue,ActionType,RelatedDeleteAction)
SELECT x.KeyID, 'bPMDR', d.KeyID, d.PMCo, d.Project, x.Issue, 'D',
		'Drawing Type: ' + ISNULL(d.DrawingType,'') + ' Drawing: ' + ISNULL(d.Drawing,'') + ' Revision: ' + ISNULL(CONVERT(VARCHAR(20),d.Rev),'') + ' : ' + ISNULL(d.Description,'')	
from deleted d
JOIN dbo.vPMRelateRecord r ON r.RecTableName = 'PMDR' AND r.RECID = d.KeyID AND r.LinkTableName = 'PMIM'
JOIN dbo.bPMIM x ON x.KeyID = r.LINKID
WHERE d.KeyID=r.RECID
---- link side
INSERT dbo.vPMIssueHistory (IssueKeyID,RelatedTableName,RelatedKeyID,Co,Project,Issue,ActionType,RelatedDeleteAction)
SELECT x.KeyID, 'bPMDR', d.KeyID, d.PMCo, d.Project, x.Issue, 'D',
		'Drawing Type: ' + ISNULL(d.DrawingType,'') + ' Drawing: ' + ISNULL(d.Drawing,'') + ' Revision: ' + ISNULL(CONVERT(VARCHAR(20),d.Rev),'') + ' : ' + ISNULL(d.Description,'')
from deleted d
JOIN dbo.vPMRelateRecord r ON r.LinkTableName = 'PMDR' AND r.LINKID = d.KeyID AND r.RecTableName = 'PMIM'
JOIN dbo.bPMIM x ON x.KeyID = r.RECID
WHERE d.KeyID=r.LINKID

---- delete associations if any from both sides - #141957
---- record side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='PMDR' AND a.RECID=d.KeyID
WHERE d.KeyID IS NOT NULL
---- link side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMRelateRecord a ON a.LinkTableName='PMDR' AND a.LINKID=d.KeyID
WHERE d.KeyID IS NOT NULL



---- document history (bPMDH)
insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, DrawingRev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
select d.PMCo, d.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY d.PMCo ASC, d.Project ASC, d.DrawingType ASC),
		'DRAWING', d.DrawingType, d.Drawing, d.Rev, getdate(), 'D', 'Rev', d.Rev, null,
		SUSER_SNAME(), 'Drawing Type: ' + d.DrawingType + ' Drawing: ' + isnull(d.Drawing,'') + ' Rev: ' + d.Rev + ' has been deleted.', null
from deleted d
left join bPMDH h on h.PMCo=d.PMCo and h.Project=d.Project and h.DocCategory='DRAWING'
join bPMCO c with (nolock) on d.PMCo=c.PMCo
left join bJCJM j with (nolock) on j.JCCo=d.PMCo and j.Job=d.Project
where j.ClosePurgeFlag <> 'Y' and isnull(c.DocHistDrawing,'N') = 'Y'
group by d.PMCo, d.Project, d.DrawingType, d.Drawing, d.Rev


RETURN 

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*******************************************************/
CREATE  trigger [dbo].[btPMDRi] on [dbo].[bPMDR] for INSERT as
/*--------------------------------------------------------------------------
 *  Insert trigger for PMDR
 *  Created By:		GF 04/09/2002
 *  Modified By:	GF 10/22/2009 - issue #135479 issue history
 *					GF 10/08/2010 - issue #141648
 *					JayR 03/21/2012 Change to using FK for validation
 *
 *-------------------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on


---- document history (bPMDH)
insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, DrawingRev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.DrawingType ASC),
		'DRAWING', i.DrawingType, i.Drawing, i.Rev, getdate(), 'A', 'Rev', null, i.Rev,
		SUSER_SNAME(), 'Drawing Type: ' + i.DrawingType + ' Drawing: ' + isnull(i.Drawing,'') + ' Rev: ' + i.Rev + ' has been added.', null
from inserted i
left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='DRAWING'
join bPMCO c with (nolock) on i.PMCo=c.PMCo
where isnull(c.DocHistDrawing,'N') = 'Y'
group by i.PMCo, i.Project, i.DrawingType, i.Drawing, i.Rev

RETURN 

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************************/
CREATE  trigger [dbo].[btPMDRu] on [dbo].[bPMDR] for UPDATE as
/*--------------------------------------------------------------
 *	Update trigger for PMDR
 *  Created By:		GF 04/09/2002
 *  Modified By:	GF 10/23/2009 - issue #135479 issue history
  *				GF 10/08/2010 - issue #141648
 *
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

---- check for changes to PMCo
if update(PMCo)
      begin
      RAISERROR('Cannot change PMCo - cannot update PMDR', 11, -1)
      ROLLBACK TRANSACTION
      RETURN 
      end

---- check for changes to Project
if update(Project)
      begin
      RAISERROR('Cannot change Project - cannot update PMDR', 11, -1)
      ROLLBACK TRANSACTION
      RETURN
      end

---- check for changes to DrawingType
if update(DrawingType)
      begin
      RAISERROR('Cannot change DrawingType - cannot update PMDR', 11, -1)
      ROLLBACK TRANSACTION
      RETURN
      end

---- check for changes to Drawing
if update(Drawing)
      begin
      RAISERROR('Cannot change Drawing - cannot update PMDR', 11, -1)
      ROLLBACK TRANSACTION
      RETURN
      end

---- check for changes to Revision
if update(Rev)
      begin
      RAISERROR('Cannot change Drawing Revision - cannot update PMDR', 11, -1)
      ROLLBACK TRANSACTION
      RETURN
      end



---- document history updates (bPMDH)
if update(Description)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, DrawingRev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.DrawingType),
			'DRAWING', i.DrawingType, i.Drawing, i.Rev, getdate(), 'C', 'Description',
			d.Description, i.Description, SUSER_SNAME(), 'Description has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.DrawingType=i.DrawingType and d.Drawing=i.Drawing and d.Rev=i.Rev
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='DRAWING'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Description,'') <> isnull(i.Description,'') and isnull(c.DocHistDrawing,'N') = 'Y'
	group by i.PMCo, i.Project, i.DrawingType, i.Drawing, i.Rev, i.Description, d.Description
	end
if update(RevisionDate)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, DrawingRev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.DrawingType),
			'DRAWING', i.DrawingType, i.Drawing, i.Rev, getdate(), 'C', 'RevisionDate',
			convert(char(8),d.RevisionDate,1), convert(char(8),i.RevisionDate,1), SUSER_SNAME(), 'Revision Date has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.DrawingType=i.DrawingType and d.Drawing=i.Drawing and d.Rev=i.Rev
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='DRAWING'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.RevisionDate,'') <> isnull(i.RevisionDate,'') and isnull(c.DocHistDrawing,'N') = 'Y'
	group by i.PMCo, i.Project, i.DrawingType, i.Drawing, i.Rev, i.RevisionDate, d.RevisionDate
	end
if update(Status)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, DrawingRev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.DrawingType),
			'DRAWING', i.DrawingType, i.Drawing, i.Rev, getdate(), 'C', 'Status',
			d.Status, i.Status, SUSER_SNAME(), 'Status has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.DrawingType=i.DrawingType and d.Drawing=i.Drawing and d.Rev=i.Rev
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='DRAWING'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Status,'') <> isnull(i.Status,'') and isnull(c.DocHistDrawing,'N') = 'Y'
	group by i.PMCo, i.Project, i.DrawingType, i.Drawing, i.Rev, i.Status, d.Status
	end
---- #135479
if update(Issue)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, DrawingRev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.DrawingType),
			'DRAWING', i.DrawingType, i.Drawing, i.Rev, getdate(), 'C', 'Issue',
			d.Issue, i.Issue, SUSER_SNAME(), 'Issue has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.DrawingType=i.DrawingType and d.Drawing=i.Drawing and d.Rev=i.Rev
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='DRAWING'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Issue,'') <> isnull(i.Issue,'') and isnull(c.DocHistDrawing,'N') = 'Y'
	group by i.PMCo, i.Project, i.DrawingType, i.Drawing, i.Rev, i.Issue, d.Issue
	end


RETURN 


GO
ALTER TABLE [dbo].[bPMDR] ADD CONSTRAINT [PK_bPMDR] PRIMARY KEY CLUSTERED  ([PMCo], [Project], [DrawingType], [Drawing], [Rev]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMDR] ([KeyID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bPMDR] WITH NOCHECK ADD CONSTRAINT [FK_bPMDR_bPMDG] FOREIGN KEY ([PMCo], [Project], [DrawingType], [Drawing]) REFERENCES [dbo].[bPMDG] ([PMCo], [Project], [DrawingType], [Drawing]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[bPMDR] WITH NOCHECK ADD CONSTRAINT [FK_bPMDR_bPMSC] FOREIGN KEY ([Status]) REFERENCES [dbo].[bPMSC] ([Status])
GO
