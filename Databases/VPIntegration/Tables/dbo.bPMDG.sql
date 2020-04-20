CREATE TABLE [dbo].[bPMDG]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bJob] NOT NULL,
[DrawingType] [dbo].[bDocType] NOT NULL,
[Drawing] [dbo].[bDocument] NOT NULL,
[DateIssued] [dbo].[bDate] NULL,
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
CREATE trigger [dbo].[btPMDGd] on [dbo].[bPMDG] for DELETE as
/*--------------------------------------------------------------
 * Delete trigger for PMDG
 * Created By:	GF 04/05/2002
 * Modified By:	GF 10/22/2009 - issue #135479 issue history
 *				GF 12/21/2010 - issue #141957 record association
 *				JayR 03/20/2012 - TK-00000 Change to using FK with Cascading delete.
 *
 * Removes drawing revisions from PMDR also. Cascade delete.
 *
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

---- delete PM distribution audit tables if any
delete bPMHA from bPMHA a join bPMHI i on i.KeyId=a.PMHIKeyId
join deleted d on i.SourceTableName='PMDG' and i.SourceKeyId=d.KeyID

delete bPMHF from bPMHF a join bPMHI i on i.KeyId=a.PMHIKeyId
join deleted d on i.SourceTableName='PMDG' and i.SourceKeyId=d.KeyID

delete bPMHI from bPMHI i
join deleted d on i.SourceTableName='PMDG' and i.SourceKeyId=d.KeyID


---- when the record is related to a project issue PMIM
---- we need to add a delete action recorded in history for the issue
---- noting that the type and code with a description ws deleted.
---- record side. TFS #398
---- delete
DELETE dbo.vPMIssueHistory FROM deleted d WHERE RelatedTableName = 'bPMDG' AND RelatedKeyID = d.KeyID
---- insert
INSERT dbo.vPMIssueHistory (IssueKeyID,RelatedTableName,RelatedKeyID,Co,Project,Issue,ActionType,RelatedDeleteAction)
SELECT x.KeyID, 'bPMDG', d.KeyID, d.PMCo, d.Project, x.Issue, 'D',
		'Drawing Type: ' + ISNULL(d.DrawingType,'') + ' Drawing: ' + ISNULL(d.Drawing,'') + ' : ' + ISNULL(d.Description,'')	
from deleted d
JOIN dbo.vPMRelateRecord r ON r.RecTableName = 'PMDG' AND r.RECID = d.KeyID AND r.LinkTableName = 'PMIM'
JOIN dbo.bPMIM x ON x.KeyID = r.LINKID
WHERE d.KeyID=r.RECID
---- link side
INSERT dbo.vPMIssueHistory (IssueKeyID,RelatedTableName,RelatedKeyID,Co,Project,Issue,ActionType,RelatedDeleteAction)
SELECT x.KeyID, 'bPMDG', d.KeyID, d.PMCo, d.Project, x.Issue, 'D',
		'Drawing Type: ' + ISNULL(d.DrawingType,'') + ' Drawing: ' + ISNULL(d.Drawing,'') + ' : ' + ISNULL(d.Description,'')
from deleted d
JOIN dbo.vPMRelateRecord r ON r.LinkTableName = 'PMDG' AND r.LINKID = d.KeyID AND r.RecTableName = 'PMIM'
JOIN dbo.bPMIM x ON x.KeyID = r.RECID
WHERE d.KeyID=r.LINKID

---- delete associations if any from both sides - #141957
---- record side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='PMDG' AND a.RECID=d.KeyID
WHERE d.KeyID IS NOT NULL
---- link side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMRelateRecord a ON a.LinkTableName='PMDG' AND a.LINKID=d.KeyID
WHERE d.KeyID IS NOT NULL



---- document history (bPMDH)
insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.DrawingType ASC),
		'DRAWING', i.DrawingType, i.Drawing, null, getdate(), 'D', 'Drawing', i.Drawing, null,
		SUSER_SNAME(), 'Drawing Type: ' + isnull(i.DrawingType,'') + ' Drawing: ' + isnull(i.Drawing,'') + ' has been deleted.', null
from deleted i
left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='DRAWING'
join bPMCO c with (nolock) on i.PMCo=c.PMCo
left join bJCJM j with (nolock) on j.JCCo=i.PMCo and j.Job=i.Project
where j.ClosePurgeFlag <> 'Y' and isnull(c.DocHistDrawing,'N') = 'Y'
group by i.PMCo, i.Project, i.DrawingType, i.Drawing



RETURN





GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/***************************************************/
CREATE trigger [dbo].[btPMDGi] on [dbo].[bPMDG] for INSERT as
/*--------------------------------------------------------------
 *  Insert trigger for PMDG
 *  Created By:		GF 04/05/2002
 *  Modified By:	GF 10/22/2009 - issue #135479 issue history
 *				GF 10/08/2010 - issue #141648
 *				JayR 03/20/2012 TK-00000 Change to using FKs
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

---- document history (bPMDH)
insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.DrawingType ASC),
		'DRAWING', i.DrawingType, i.Drawing, null, getdate(), 'A', 'Drawing', null, i.Drawing,
		SUSER_SNAME(), 'Drawing Type: ' + isnull(i.DrawingType,'') + ' Drawing: ' + isnull(i.Drawing,'') + ' has been added.', null
from inserted i
left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='DRAWING'
join bPMCO c with (nolock) on i.PMCo=c.PMCo
where isnull(c.DocHistDrawing,'N') = 'Y'
group by i.PMCo, i.Project, i.DrawingType, i.Drawing

RETURN
   
  
 







GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/***************************************************/
CREATE trigger [dbo].[btPMDGu] on [dbo].[bPMDG] for UPDATE as
/*--------------------------------------------------------------
 *	Update trigger for PMDG
 *  Created By:		GF 04/05/2002
 *  Modified By:	GF 10/22/2009 - issue #135479 issue history
 *				GF 10/08/2010 - issue #141648
 *				JayR 03/21/2012 Remove gotos and unused variables
 *				TRL 08/02/2012 TK-16812 remove code for Status column update
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

---- check for changes to PMCo
if update(PMCo)
      begin
      RAISERROR('Cannot change PMCo - cannot update PMDG', 11, -1)
      ROLLBACK TRANSACTION
      RETURN
      end

---- check for changes to Project
if update(Project)
      begin
      RAISERROR('Cannot change Project - cannot update PMDG', 11, -1)
      ROLLBACK TRANSACTION
      RETURN
      end

---- check for changes to DrawingType
if update(DrawingType)
      begin
      RAISERROR('Cannot change DrawingType - cannot update PMDG', 11, -1)
      ROLLBACK TRANSACTION
      RETURN
      end

----- check for changes to Drawing
if update(Drawing)
      begin
      RAISERROR('Cannot change Drawing - cannot update PMDG', 11, -1)
      ROLLBACK TRANSACTION
      RETURN
      end


---- Validate Issue #135479
--if update(Issue)
--      begin
--      select @validcnt = count(*) from bPMIM r JOIN inserted i ON i.PMCo=r.PMCo and i.Project=r.Project and i.Issue=r.Issue
--      select @validcnt2 = count(*) from inserted i where i.Issue is null
--      if @validcnt + @validcnt2 <> @numrows
--         begin
--         select @errmsg = 'Issue is Invalid '
--         goto error
--         end
--      end


if update(Issue)
	begin
	update bPMDR set Issue=i.Issue
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.DrawingType=i.DrawingType and d.Drawing=i.Drawing
	join bPMDR s on s.PMCo=i.PMCo and s.Project=i.Project and s.DrawingType=i.DrawingType and s.Drawing=i.Drawing
	where isnull(i.Status,'') = isnull(s.Status,'') ----AND isnull(d.Issue,'') = isnull(s.Issue,'')
	and (s.Issue is null or isnull(s.Issue,'') = isnull(d.Issue,''))
	end
	


---- Insert records into Issue History
--if update(Issue)
--	begin
--	-- old and new issue exists
--	insert into bPMIH (PMCo, Project, Issue, Seq, DocType, Document, Rev, IssueDateTime, Action)
--	select i.PMCo, i.Project, i.Issue, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.Issue ASC),
--			i.DrawingType, i.Drawing, null, getdate(),
--			'Issue has changed from ' + isnull(convert(varchar(10),d.Issue),'') + ' to ' + convert(varchar(10),isnull(i.Issue,'')) +
--			' for Drawing Type: ' + i.DrawingType + ' Drawing: ' + i.Drawing + ' - ' + isnull(i.Description,'')
--	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project
--	and d.DrawingType=i.DrawingType and d.Drawing=i.Drawing
--	left join bPMIH h on h.PMCo=i.PMCo and h.Project=i.Project and h.Issue=i.Issue
--	where isnull(i.Issue,'') <> isnull(d.Issue,'') and isnull(i.Issue,'') <> ''
--	group by i.PMCo, i.Project, i.DrawingType, i.Drawing, i.Issue, d.Issue, h.Issue, i.Description
--	end
--if update(Status)
--	begin
--	insert into bPMIH (PMCo, Project, Issue, Seq, DocType, Document, Rev, IssueDateTime, Action)
--	select i.PMCo, i.Project, i.Issue, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.Issue ASC),
--			i.DrawingType, i.Drawing, null, getdate(),
--			'Status has changed from ' + isnull(d.Status,'') + ' to ' + isnull(i.Status,'') + 
--			' for Drawing Type: ' + i.DrawingType + ' Drawing: ' + i.Drawing + ' - ' + isnull(i.Description,'')
--	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project
--	and d.DrawingType=i.DrawingType and d.Drawing=i.Drawing
--	left join bPMIH h on h.PMCo=i.PMCo and h.Project=i.Project and h.Issue=i.Issue
--	where isnull(i.Status,'') <> isnull(d.Status,'') and isnull(i.Issue,'') <> ''
--	group by i.PMCo, i.Project, i.DrawingType, i.Drawing, i.Status, d.Status, i.Issue, d.Issue, h.Issue, i.Description
--	end


---- document history updates (bPMDH)
if update(Description)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.DrawingType),
			'DRAWING', i.DrawingType, i.Drawing, null, getdate(), 'C', 'Description',
			d.Description, i.Description, SUSER_SNAME(), 'Description has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.DrawingType=i.DrawingType and d.Drawing=i.Drawing
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='DRAWING'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Description,'') <> isnull(i.Description,'') and isnull(c.DocHistDrawing,'N') = 'Y'
	group by i.PMCo, i.Project, i.DrawingType, i.Drawing, i.Description, d.Description
	end
if update(DateIssued)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.DrawingType),
			'DRAWING', i.DrawingType, i.Drawing, null, getdate(), 'C', 'DateIssued',
			convert(char(8),d.DateIssued,1), convert(char(8),i.DateIssued,1), SUSER_SNAME(), 'Date Issued has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.DrawingType=i.DrawingType and d.Drawing=i.Drawing
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='DRAWING'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.DateIssued,'') <> isnull(i.DateIssued,'') and isnull(c.DocHistDrawing,'N') = 'Y'
	group by i.PMCo, i.Project, i.DrawingType, i.Drawing, i.DateIssued, d.DateIssued
	end
if update(Status)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.DrawingType),
			'DRAWING', i.DrawingType, i.Drawing, null, getdate(), 'C', 'Status',
			d.Status, i.Status, SUSER_SNAME(), 'Status has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.DrawingType=i.DrawingType and d.Drawing=i.Drawing
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='DRAWING'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Status,'') <> isnull(i.Status,'') and isnull(c.DocHistDrawing,'N') = 'Y'
	group by i.PMCo, i.Project, i.DrawingType, i.Drawing, i.Status, d.Status
	END
---- #135479
if update(Issue)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.DrawingType),
			'DRAWING', i.DrawingType, i.Drawing, null, getdate(), 'C', 'Issue',
			convert(varchar(8),d.Issue), convert(varchar(8),i.Issue),  SUSER_SNAME(), 'Issue has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.DrawingType=i.DrawingType and d.Drawing=i.Drawing
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='DRAWING'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Issue,0) <> isnull(i.Issue,0) and isnull(c.DocHistDrawing,'N') = 'Y'
	group by i.PMCo, i.Project, i.DrawingType, i.Drawing, i.Issue, d.Issue
	end


RETURN 
   
   
  
 





GO
ALTER TABLE [dbo].[bPMDG] ADD CONSTRAINT [PK_bPMDG] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMDG] ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPMDG] ON [dbo].[bPMDG] ([PMCo], [Project], [DrawingType], [Drawing]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bPMDG] WITH NOCHECK ADD CONSTRAINT [FK_bPMDG_bPMDT] FOREIGN KEY ([DrawingType]) REFERENCES [dbo].[bPMDT] ([DocType])
GO
ALTER TABLE [dbo].[bPMDG] WITH NOCHECK ADD CONSTRAINT [FK_bPMDG_bJCJM] FOREIGN KEY ([PMCo], [Project]) REFERENCES [dbo].[bJCJM] ([JCCo], [Job])
GO
ALTER TABLE [dbo].[bPMDG] WITH NOCHECK ADD CONSTRAINT [FK_bPMDG_bPMSC] FOREIGN KEY ([Status]) REFERENCES [dbo].[bPMSC] ([Status])
GO
