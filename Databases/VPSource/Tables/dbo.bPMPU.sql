CREATE TABLE [dbo].[bPMPU]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bJob] NOT NULL,
[PunchList] [dbo].[bDocument] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[PunchListDate] [dbo].[bDate] NULL,
[PrintOption] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[DocType] [dbo].[bDocType] NOT NULL CONSTRAINT [DF_bPMPU_DocType] DEFAULT ('PUNCH')
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
ALTER TABLE [dbo].[bPMPU] ADD
CONSTRAINT [FK_bPMPU_bPMDT] FOREIGN KEY ([DocType]) REFERENCES [dbo].[bPMDT] ([DocType])
ALTER TABLE [dbo].[bPMPU] ADD
CONSTRAINT [FK_bPMPU_bJCJM] FOREIGN KEY ([PMCo], [Project]) REFERENCES [dbo].[bJCJM] ([JCCo], [Job])
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMPUd    Script Date: 8/28/99 9:38:00 AM ******/
CREATE trigger [dbo].[btPMPUd] on [dbo].[bPMPU] for DELETE as
/*--------------------------------------------------------------
 * Delete trigger for PMPU
 * Created By:		LM 1/9/98
 * Modified Date:	GF 11/11/2006 6.x 
 *					GF 12/21/2010 - issue #141957 record association
 *					GF 01/26/2011 - TFS #398
 *					JayR 03/26/2012 - TK-00000 Switch to FKs for validation
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

---- when the record is related to a project issue PMIM
---- we need to add a delete action recorded in history for the issue
---- noting that the type and code with a description ws deleted.
---- record side. TFS #398
---- delete
DELETE dbo.vPMIssueHistory FROM deleted d WHERE RelatedTableName = 'bPMPU' AND RelatedKeyID = d.KeyID
---- insert
INSERT dbo.vPMIssueHistory (IssueKeyID,RelatedTableName,RelatedKeyID,Co,Project,Issue,ActionType,RelatedDeleteAction)
SELECT x.KeyID, 'bPMPU', d.KeyID, d.PMCo, d.Project, x.Issue, 'D',
		'Punch List: ' + ISNULL(d.PunchList,'') + ' : ' + ISNULL(d.Description,'')	
from deleted d
JOIN dbo.vPMRelateRecord r ON r.RecTableName = 'PMPU' AND r.RECID = d.KeyID AND r.LinkTableName = 'PMIM'
JOIN dbo.bPMIM x ON x.KeyID = r.LINKID
WHERE d.KeyID=r.RECID
---- link side
INSERT dbo.vPMIssueHistory (IssueKeyID,RelatedTableName,RelatedKeyID,Co,Project,Issue,ActionType,RelatedDeleteAction)
SELECT x.KeyID, 'bPMPU', d.KeyID, d.PMCo, d.Project, x.Issue, 'D',
		'Punch List: ' + ISNULL(d.PunchList,'') + ' : ' + ISNULL(d.Description,'')	
from deleted d
JOIN dbo.vPMRelateRecord r ON r.LinkTableName = 'PMPU' AND r.LINKID = d.KeyID AND r.RecTableName = 'PMIM'
JOIN dbo.bPMIM x ON x.KeyID = r.RECID
WHERE d.KeyID=r.LINKID


---- delete associations if any from both sides - #141957
---- record side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='PMPU' AND a.RECID=d.KeyID
WHERE d.KeyID IS NOT NULL
---- link side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMRelateRecord a ON a.LinkTableName='PMPU' AND a.LINKID=d.KeyID
WHERE d.KeyID IS NOT NULL


---- document history (bPMDH)
insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
select i.PMCo, i.Project, isnull(max(h.Seq),0)+1 + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
		'PUNCH', null, i.PunchList, null, getdate(), 'D', 'PunchList', i.PunchList, null,
		SUSER_SNAME(), 'Punch List: ' + isnull(i.PunchList,'') + ' has been deleted.', null
from deleted i
left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PUNCH'
join bPMCO c with (nolock) on i.PMCo=c.PMCo
left join bJCJM j with (nolock) on j.JCCo=i.PMCo and j.Job=i.Project
where j.ClosePurgeFlag <> 'Y' and c.DocHistPunchList = 'Y'
group by i.PMCo, i.Project, i.PunchList



RETURN 
   
  
 





GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMPUi    Script Date: 8/28/99 9:38:00 AM ******/
CREATE trigger [dbo].[btPMPUi] on [dbo].[bPMPU] for INSERT as
/*--------------------------------------------------------------
 * Insert trigger for PMPU
 * Created By:		LM 1/9/97
 * Modified Date:	GF 11/11/2006 6.x
 *					JayR 03/26/2012 TK-00000 Change to use FKs for validation
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on



---- document history (bPMDH)
insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, Action)
select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
		'PUNCH', null, i.PunchList, null, getdate(), 'A', 'PunchList', null, i.PunchList, SUSER_SNAME(),
		'Punch List: ' + isnull(i.PunchList,'') + ' has been added.'
from inserted i 
left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PUNCH'
join bPMCO c with (nolock) on i.PMCo=c.PMCo
where c.DocHistPunchList = 'Y'
group by i.PMCo, i.Project, i.PunchList


RETURN 
   
  
 





GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMPUu    Script Date: 8/28/99 9:38:00 AM ******/
CREATE trigger [dbo].[btPMPUu] on [dbo].[bPMPU] for UPDATE as
/*--------------------------------------------------------------
 *
 * Update trigger for PMPU
 * Created By:		LM 1/9/98
 * Modified Date:	GF 10/12/2006 - changes for 6.x PMDH document history.
 *
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

---- check for changes to PMCo
if update(PMCo)
      begin
      RAISERROR('Cannot change PM Company - cannot update PMPU', 11, -1)
      ROLLBACK TRANSACTION
      RETURN 
      end

---- check for changes to Project
if update(Project)
      begin
      RAISERROR('Cannot change Project - cannot update PMPU', 11, -1)
      ROLLBACK TRANSACTION
      RETURN 
      end

---- check for changes to Punch List
if update(PunchList)
      begin
      RAISERROR('Cannot change Punch List - cannot update PMPU', 11, -1)
      ROLLBACK TRANSACTION
      RETURN 
      end


if update(Description)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			'PUNCH', null, i.PunchList, null, getdate(), 'C', 'Description', d.Description, i.Description,
			SUSER_SNAME(), 'Description has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.PunchList=i.PunchList
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PUNCH'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Description,'') <> isnull(i.Description,'')
	and c.DocHistPunchList = 'Y'
	group by i.PMCo, i.Project, i.PunchList, i.Description, d.Description
	end
if update(PunchListDate)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			'PUNCH', null, i.PunchList, null, getdate(), 'C', 'PunchListDate', convert(char(8),d.PunchListDate,1),
			convert(char(8),i.PunchListDate,1), SUSER_SNAME(), 'Punch List Date has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.PunchList=i.PunchList
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PUNCH'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.PunchListDate,'') <> isnull(i.PunchListDate,'')
	and c.DocHistPunchList = 'Y'
	group by i.PMCo, i.Project, i.PunchList, i.PunchListDate, d.PunchListDate
	end
if update(PrintOption)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, AssignToDoc)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			'PUNCH', null, i.PunchList, null, getdate(), 'C', 'PrintOption', d.PrintOption, i.PrintOption,
			SUSER_SNAME(), 'Print Option has been changed', null
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.PunchList=i.PunchList
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PUNCH'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.PrintOption,'') <> isnull(i.PrintOption,'')
	and c.DocHistPunchList = 'Y'
	group by i.PMCo, i.Project, i.PunchList, i.PrintOption, d.PrintOption
	end


RETURN 
   
   
  
 






GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMPU] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPMPL] ON [dbo].[bPMPU] ([PMCo], [Project], [PunchList]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
