CREATE TABLE [dbo].[bPMPN]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bProject] NOT NULL,
[NoteSeq] [int] NOT NULL,
[Issue] [dbo].[bIssue] NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[Firm] [dbo].[bFirm] NULL,
[FirmContact] [dbo].[bEmployee] NULL,
[PMStatus] [dbo].[bStatus] NULL,
[AddedBy] [dbo].[bVPUserName] NOT NULL,
[AddedDate] [dbo].[bDate] NOT NULL,
[ChangedBy] [dbo].[bVPUserName] NULL,
[ChangedDate] [dbo].[bDate] NULL,
[Summary] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*****************************************************/
CREATE  trigger [dbo].[btPMPNd] on [dbo].[bPMPN] for DELETE as
/****************************************************************
 * Created By:	02/03/04 RBT - #16547 
 * Modified By:	GF 12/13/2006 - 6.x HQMA
 *				GF 02/05/2007 - issue #123699 issue history
 *				GF 12/21/2010 - issue #141957 record association
 *				GF 01/26/2011 - TFS #398
 *				JayR 03/26/2012 TK-00000 Change to using FKs to do cascade deletion.
 *
 * Delete trigger for PM Project Notes table.
 *
 ****************************************************************/

if @@rowcount = 0 return
set nocount on


---- when the record is related to a project issue PMIM
---- we need to add a delete action recorded in history for the issue
---- noting that the type and code with a description ws deleted.
---- record side. TFS #398
---- delete
DELETE dbo.vPMIssueHistory FROM deleted d WHERE RelatedTableName = 'bPMPN' AND RelatedKeyID = d.KeyID
---- insert
INSERT dbo.vPMIssueHistory (IssueKeyID,RelatedTableName,RelatedKeyID,Co,Project,Issue,ActionType,RelatedDeleteAction)
SELECT x.KeyID, 'bPMPN', d.KeyID, d.PMCo, d.Project, x.Issue, 'D',
		'Note Sequence:: ' + ISNULL(CONVERT(VARCHAR(20),d.NoteSeq),'') + ' : ' + ISNULL(d.Summary,'')	
from deleted d
JOIN dbo.vPMRelateRecord r ON r.RecTableName = 'PMPN' AND r.RECID = d.KeyID AND r.LinkTableName = 'PMIM'
JOIN dbo.bPMIM x ON x.KeyID = r.LINKID
WHERE d.KeyID=r.RECID
---- link side
INSERT dbo.vPMIssueHistory (IssueKeyID,RelatedTableName,RelatedKeyID,Co,Project,Issue,ActionType,RelatedDeleteAction)
SELECT x.KeyID, 'bPMPN', d.KeyID, d.PMCo, d.Project, x.Issue, 'D',
		'Note Sequence:: ' + ISNULL(CONVERT(VARCHAR(20),d.NoteSeq),'') + ' : ' + ISNULL(d.Summary,'')	
from deleted d
JOIN dbo.vPMRelateRecord r ON r.LinkTableName = 'PMPN' AND r.LINKID = d.KeyID AND r.RecTableName = 'PMIM'
JOIN dbo.bPMIM x ON x.KeyID = r.RECID
WHERE d.KeyID=r.LINKID

---- delete associations if any from both sides - #141957
---- record side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='PMPN' AND a.RECID=d.KeyID
WHERE d.KeyID IS NOT NULL
---- link side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMRelateRecord a ON a.LinkTableName='PMPN' AND a.LINKID=d.KeyID
WHERE d.KeyID IS NOT NULL



---- HQMA inserts
insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bPMPN','PMCo: ' + isnull(convert(char(3),d.PMCo), '') + ' Project: ' + isnull(d.Project,'') + ' NoteSeq: ' + isnull(convert(varchar(8),d.NoteSeq),''),
		d.PMCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from deleted d JOIN bPMCO c ON d.PMCo=c.PMCo
left join bJCJM j with (nolock) on j.JCCo=d.PMCo and j.Job=d.Project
where c.AuditPMPN = 'Y' and j.ClosePurgeFlag <> 'Y'


RETURN 







GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*********************************************************/
CREATE  trigger [dbo].[btPMPNi] on [dbo].[bPMPN] for INSERT as 
/*--------------------------------------------------------------
 * Insert trigger for PMPN
 * Created By: RT 02/05/04 - Issue #16547 (cloned from btPMIMi)
 * Modified By:	GF 12/13/2006 - 6.x HQMA
 *				GF 02/05/2007 - issue #123699 issue history
 *				GF 10/08/2010 - issue #141648
 *				GF 01/26/2011 - tfs #398
 *				JayR 03/26/2012 TK-00000 Switch to using FKs for validation 
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on 

-- Audit inserts
insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bPMPN', 'PMCo: ' + convert(char(3), i.PMCo) + ' Project: ' + isnull(i.Project,'') + ' NoteSeq: ' + isnull(convert(varchar(8),i.NoteSeq),''),
       i.PMCo, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from inserted i join bPMCO c on c.PMCo = i.PMCo
where i.PMCo = c.PMCo and c.AuditPMPN = 'Y'


RETURN 







GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/***********************************************************/
CREATE  trigger [dbo].[btPMPNu] on [dbo].[bPMPN] for UPDATE as
/****************************************************************
 * Created By:  01/19/04 RBT - #16547 
 * Modified By: GF 04/12/2005 - issue #28400 update issue history when issue changes.
 *				GF 12/13/2006 - 6.x HQMA
 *				GF 02/07/2007 - issue #123699 issue history
 *				GF 10/08/2010 - issue #141648
 *				GF 12/09/2010 - issue #141031
 *				JayR 03/26/2012 TK-00000 Remove unused variables and gotos
 *
 * Update trigger for PM Project Notes table.
 *
 ****************************************************************/
declare @numrows int, @validcount int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

---- do not allow changes to key fields
select @validcount = count(*) from inserted i join deleted d
on i.PMCo = d.PMCo and i.Project = d.Project and i.NoteSeq = d.NoteSeq
if @validcount <> @numrows 
	begin	
   		RAISERROR('Cannot change key fields! - cannot update PMPN', 11, -1)
		ROLLBACK TRANSACTION
		RETURN
	end

---- automatically set Changed Date and Changed By field -- 141031
update bPMPN set ChangedDate = dbo.vfDateOnly(), ChangedBy = SUSER_SNAME()
from bPMPN a 
join inserted i on a.PMCo = i.PMCo and a.Project = i.Project and a.NoteSeq = i.NoteSeq
join deleted d on i.PMCo = d.PMCo and i.Project = d.Project and i.NoteSeq = d.NoteSeq




---- HQMA inserts
if update(Summary)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMPN', 'PMCo: ' + convert(varchar(3), i.PMCo) + ' Project: ' + isnull(i.Project,'') + ' NoteSeq: ' + isnull(convert(varchar(8),i.NoteSeq),''),
		i.PMCo, 'C', 'Summary', d.Summary, i.Summary, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.NoteSeq=i.NoteSeq
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.Summary,'') <> isnull(i.Summary,'') and c.AuditPMPN='Y'
if update(PMStatus)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMPN', 'PMCo: ' + convert(varchar(3), i.PMCo) + ' Project: ' + isnull(i.Project,'') + ' NoteSeq: ' + isnull(convert(varchar(8),i.NoteSeq),''),
		i.PMCo, 'C', 'PMStatus', d.PMStatus, i.PMStatus, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.NoteSeq=i.NoteSeq
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.PMStatus,'') <> isnull(i.PMStatus,'') and c.AuditPMPN='Y'
if update(Firm)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMPN', 'PMCo: ' + convert(varchar(3), i.PMCo) + ' Project: ' + isnull(i.Project,'') + ' NoteSeq: ' + isnull(convert(varchar(8),i.NoteSeq),''),
		i.PMCo, 'C', 'Firm', isnull(convert(varchar(8),d.Firm),''), isnull(convert(varchar(8),i.Firm),''), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.NoteSeq=i.NoteSeq
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.Firm,'') <> isnull(i.Firm,'') and c.AuditPMPN='Y'
if update(FirmContact)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMPN', 'PMCo: ' + convert(varchar(3), i.PMCo) + ' Project: ' + isnull(i.Project,'') + ' NoteSeq: ' + isnull(convert(varchar(8),i.NoteSeq),''),
		i.PMCo, 'C', 'FirmContact', isnull(convert(varchar(8),d.FirmContact),''), isnull(convert(varchar(8),i.FirmContact),''), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.NoteSeq=i.NoteSeq
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.FirmContact,'') <> isnull(i.FirmContact,'') and c.AuditPMPN='Y'
if update(Issue)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMPN', 'PMCo: ' + convert(varchar(3), i.PMCo) + ' Project: ' + isnull(i.Project,'') + ' NoteSeq: ' + isnull(convert(varchar(8),i.NoteSeq),''),
		i.PMCo, 'C', 'Issue', isnull(convert(varchar(10),d.Issue),''), isnull(convert(varchar(10),i.Issue),''), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.NoteSeq=i.NoteSeq
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.Issue,'') <> isnull(i.Issue,'') and c.AuditPMPN='Y'


RETURN  






GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMPN] ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPMPN] ON [dbo].[bPMPN] ([PMCo], [Project], [NoteSeq]) ON [PRIMARY]
GO
