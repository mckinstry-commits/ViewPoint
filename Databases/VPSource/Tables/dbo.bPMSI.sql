CREATE TABLE [dbo].[bPMSI]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bJob] NOT NULL,
[Submittal] [dbo].[bDocument] NOT NULL,
[SubmittalType] [dbo].[bDocType] NOT NULL,
[Rev] [tinyint] NOT NULL,
[Item] [smallint] NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[Status] [dbo].[bStatus] NULL,
[Send] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMSI_Send] DEFAULT ('Y'),
[DateReqd] [dbo].[bDate] NULL,
[DateRecd] [dbo].[bDate] NULL,
[ToArchEng] [dbo].[bDate] NULL,
[DueBackArch] [dbo].[bDate] NULL,
[RecdBackArch] [dbo].[bDate] NULL,
[DateRetd] [dbo].[bDate] NULL,
[ActivityDate] [dbo].[bDate] NULL,
[CopiesRecd] [tinyint] NULL,
[CopiesSent] [tinyint] NULL,
[CopiesReqd] [tinyint] NULL,
[CopiesRecdArch] [tinyint] NULL,
[CopiesSentArch] [tinyint] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[ChangedFromPMSM] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMSI_ChangedFromPMSM] DEFAULT ('N'),
[PhaseGroup] [dbo].[bGroup] NULL,
[Phase] [dbo].[bPhase] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[Issue] [dbo].[bIssue] NULL,
[SpecNumber] [varchar] (20) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
ALTER TABLE [dbo].[bPMSI] ADD
CONSTRAINT [CK_bPMSI_Send] CHECK (([Send]='Y' OR [Send]='N'))
ALTER TABLE [dbo].[bPMSI] ADD
CONSTRAINT [FK_bPMSI_bJCJM] FOREIGN KEY ([PMCo], [Project]) REFERENCES [dbo].[bJCJM] ([JCCo], [Job])
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger [dbo].[btPMSId]    Script Date: 12/14/2006 12:57:48 ******/
CREATE   trigger [dbo].[btPMSId] on [dbo].[bPMSI] for DELETE as
/*--------------------------------------------------------------
 * Created By:	GF 12/14/2006
 * Modified By:	GF 12/14/2006 - changes for 6.x PMDH document history.
 *				GF 09/02/2008 - issue #129637
 *				GF 10/22/2009 - issue #134090 - issue history
 *				GF 12/21/2010 - issue #141957 record association
 *				GF 01/26/2011 - TFS #398
 *				JayR 03/26/2012 TK-00000 Remove unused variables	
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

---- when the record is related to a project issue PMIM
---- we need to add a delete action recorded in history for the issue
---- noting that the type and code with a description ws deleted.
---- record side. TFS #398
---- delete
DELETE dbo.vPMIssueHistory FROM deleted d WHERE RelatedTableName = 'bPMSI' AND RelatedKeyID = d.KeyID
---- insert
INSERT dbo.vPMIssueHistory (IssueKeyID,RelatedTableName,RelatedKeyID,Co,Project,Issue,ActionType,RelatedDeleteAction)
SELECT x.KeyID, 'bPMSI', d.KeyID, d.PMCo, d.Project, x.Issue, 'D',
		'Submittal Type: ' + ISNULL(d.SubmittalType,'') + ' Submittal: ' + ISNULL(d.Submittal,'') + ' Revision: ' + ISNULL(CONVERT(VARCHAR(3),d.Rev),'') + ' Item: ' + ISNULL(CONVERT(VARCHAR(10),d.Item),'') + ' : ' + ISNULL(d.Description,'')	
from deleted d
JOIN dbo.vPMRelateRecord r ON r.RecTableName = 'PMSI' AND r.RECID = d.KeyID AND r.LinkTableName = 'PMIM'
JOIN dbo.bPMIM x ON x.KeyID = r.LINKID
WHERE d.KeyID=r.RECID
---- link side
INSERT dbo.vPMIssueHistory (IssueKeyID,RelatedTableName,RelatedKeyID,Co,Project,Issue,ActionType,RelatedDeleteAction)
SELECT x.KeyID, 'bPMSI', d.KeyID, d.PMCo, d.Project, x.Issue, 'D',
		'Submittal Type: ' + ISNULL(d.SubmittalType,'') + ' Submittal: ' + ISNULL(d.Submittal,'') + ' Revision: ' + ISNULL(CONVERT(VARCHAR(3),d.Rev),'') + ' Item: ' + ISNULL(CONVERT(VARCHAR(10),d.Item),'') + ' : ' + ISNULL(d.Description,'')
from deleted d
JOIN dbo.vPMRelateRecord r ON r.LinkTableName = 'PMSI' AND r.LINKID = d.KeyID AND r.RecTableName = 'PMIM'
JOIN dbo.bPMIM x ON x.KeyID = r.RECID
WHERE d.KeyID=r.LINKID

---- delete associations if any from both sides - #141957
---- record side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='PMSI' AND a.RECID=d.KeyID
WHERE d.KeyID IS NOT NULL
---- link side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMRelateRecord a ON a.LinkTableName='PMSI' AND a.LINKID=d.KeyID
WHERE d.KeyID IS NOT NULL


---- document history (bPMDH)
insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, Action, Item)
select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.SubmittalType ASC),
		'SUBMIT', i.SubmittalType, i.Submittal, i.Rev, getdate(), 'D', 'Item', i.Item, null,
		SUSER_SNAME(), 'Submittal Item: ' + isnull(convert(varchar(8),i.Item),'') + ' has been deleted.', i.Item
from deleted i
left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='SUBMIT'
join bPMCO c with (nolock) on i.PMCo=c.PMCo
left join bJCJM j with (nolock) on j.JCCo=i.PMCo and j.Job=i.Project
where j.ClosePurgeFlag <> 'Y' and c.DocHistSubmittal = 'Y'
group by i.PMCo, i.Project, i.SubmittalType, i.Submittal, i.Rev, i.Item


RETURN 
   
   
  
 






GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
/*********************************************/
CREATE trigger [dbo].[btPMSIi] on [dbo].[bPMSI] for INSERT as
/*--------------------------------------------------------------
* Insert trigger for PMSI
* Created By:	GF 03/15/2002
* Modified By:	GF 12/14/2006 - 6.x document history
*				GF 09/02/2008 - issue #129637
*				GF 10/22/2009 - added issue validation and history
*				GF 10/08/2010 - issue #141648
*				GF 01/26/2011 - tfs #398
*				JayR 03/26/2012 TK-00000 Switch to using FKs for validation
*
*--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on


---- document history (bPMDH)
insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
		FieldType, FieldName, OldValue, NewValue, UserName, Action, Item)
select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.SubmittalType ASC),
		'SUBMIT', i.SubmittalType, i.Submittal, i.Rev, getdate(), 'A', 'Item', null, i.Item, SUSER_SNAME(),
		'Submittal Item: ' + isnull(convert(varchar(8),i.Item),'') + ' has been added.', i.Item
from inserted i
left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='SUBMIT'
join bPMCO c with (nolock) on i.PMCo=c.PMCo
where c.DocHistSubmittal = 'Y'
group by i.PMCo, i.Project, i.SubmittalType, i.Submittal, i.Rev, i.Item


RETURN 
   
  
 






GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/************************************************/
CREATE  trigger [dbo].[btPMSIu] on [dbo].[bPMSI] for UPDATE as
/*--------------------------------------------------------------
 * Created By:	GF 03/16/2002
 * Modified By:	GF 12/14/2006 - 6.x document history
 *				GF 09/02/2008 - issue #129637
 *				GF 10/22/2009 - issue #134090 issue and spec number
 *				GF 10/08/2010 - issue #141648
 *				JayR 03/26/2012 TK-00000 Switch to using FKs for validation.
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

---- check for changes to PMCo
if update(PMCo)
      begin
		  RAISERROR('Cannot change PMCo - cannot update PMSI', 11, -1)
		  ROLLBACK TRANSACTION
		  RETURN
      end

---- check for changes to Project
if update(Project)
      begin
		  RAISERROR('Cannot change Project - cannot update PMSI', 11, -1)
		  ROLLBACK TRANSACTION
		  RETURN
      end

---- check for changes to SubmittalType
if update(SubmittalType)
      begin
		  RAISERROR('Cannot change SubmittalType - cannot update PMSI', 11, -1)
		  ROLLBACK TRANSACTION
		  RETURN
      end

---- check for changes to Submittal
if update(Submittal)
      begin
		  RAISERROR('Cannot change Submittal - cannot update PMSI', 11, -1)
		  ROLLBACK TRANSACTION
		  RETURN
      end

---- check for changes to Rev
if update(Rev)
      begin
		  RAISERROR('Cannot change Rev - cannot update PMSI', 11, -1)
		  ROLLBACK TRANSACTION
		  RETURN
      end

---- submittal item
if update(Item)
   	begin
   		RAISERROR('Cannot change submittal item - cannot update PMSI', 11, -1)
   		ROLLBACK TRANSACTION
		RETURN
   	end


---- document history updates (bPMDH)
if update(Description)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, Item)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.SubmittalType),
			'SUBMIT', i.SubmittalType, i.Submittal, i.Rev, getdate(), 'C', 'Description',
			d.Description, i.Description, SUSER_SNAME(), 'Description has been changed', i.Item
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.SubmittalType=i.SubmittalType
	and d.Submittal=i.Submittal and d.Rev=i.Rev and d.Item=i.Item
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='SUBMIT'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Description,'') <> isnull(i.Description,'')
	and c.DocHistSubmittal = 'Y' and i.ChangedFromPMSM = 'N'
	group by i.PMCo, i.Project, i.SubmittalType, i.Submittal, i.Rev, i.Item, i.Description, d.Description
	end
if update(Status)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, Item)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.SubmittalType),
			'SUBMIT', i.SubmittalType, i.Submittal, i.Rev, getdate(), 'C', 'Status',
			d.Status, i.Status, SUSER_SNAME(), 'Status has been changed', i.Item
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.SubmittalType=i.SubmittalType
	and d.Submittal=i.Submittal and d.Rev=i.Rev and d.Item=i.Item
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='SUBMIT'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Status,'') <> isnull(i.Status,'')
	and c.DocHistSubmittal = 'Y' and i.ChangedFromPMSM = 'N'
	group by i.PMCo, i.Project, i.SubmittalType, i.Submittal, i.Rev, i.Item, i.Status, d.Status
	end
if update(Send)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, Item)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.SubmittalType),
			'SUBMIT', i.SubmittalType, i.Submittal, i.Rev, getdate(), 'C', 'Send',
			d.Send, i.Send, SUSER_SNAME(), 'Send has been changed', i.Item
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.SubmittalType=i.SubmittalType
	and d.Submittal=i.Submittal and d.Rev=i.Rev and d.Item=i.Item
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='SUBMIT'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Send,'') <> isnull(i.Send,'')
	and c.DocHistSubmittal = 'Y' and i.ChangedFromPMSM = 'N'
	group by i.PMCo, i.Project, i.SubmittalType, i.Submittal, i.Rev, i.Item, i.Send, d.Send
	end
if update(Phase)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, Item)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.SubmittalType),
			'SUBMIT', i.SubmittalType, i.Submittal, i.Rev, getdate(), 'C', 'Phase',
			d.Phase, i.Phase, SUSER_SNAME(), 'Phase has been changed', i.Item
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.SubmittalType=i.SubmittalType
	and d.Submittal=i.Submittal and d.Rev=i.Rev and d.Item=i.Item
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='SUBMIT'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Phase,'') <> isnull(i.Phase,'')
	and c.DocHistSubmittal = 'Y' and i.ChangedFromPMSM = 'N'
	group by i.PMCo, i.Project, i.SubmittalType, i.Submittal, i.Rev, i.Item, i.Phase, d.Phase
	end
if update(CopiesRecd)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, Item)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.SubmittalType),
			'SUBMIT', i.SubmittalType, i.Submittal, i.Rev, getdate(), 'C', 'CopiesRecd',
			isnull(convert(varchar(3),d.CopiesRecd),''), isnull(convert(varchar(3),i.CopiesRecd),''),
			SUSER_SNAME(), 'Copies Recd has been changed', i.Item
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.SubmittalType=i.SubmittalType
	and d.Submittal=i.Submittal and d.Rev=i.Rev and d.Item=i.Item
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='SUBMIT'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.CopiesRecd,'') <> isnull(i.CopiesRecd,'')
	and c.DocHistSubmittal = 'Y' and i.ChangedFromPMSM = 'N'
	group by i.PMCo, i.Project, i.SubmittalType, i.Submittal, i.Rev, i.Item, i.CopiesRecd, d.CopiesRecd
	end
if update(CopiesSent)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, Item)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.SubmittalType),
			'SUBMIT', i.SubmittalType, i.Submittal, i.Rev, getdate(), 'C', 'CopiesSent',
			isnull(convert(varchar(3),d.CopiesSent),''), isnull(convert(varchar(3),i.CopiesSent),''),
			SUSER_SNAME(), 'Copies Sent has been changed', i.Item
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.SubmittalType=i.SubmittalType
	and d.Submittal=i.Submittal and d.Rev=i.Rev and d.Item=i.Item
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='SUBMIT'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.CopiesSent,'') <> isnull(i.CopiesSent,'')
	and c.DocHistSubmittal = 'Y' and i.ChangedFromPMSM = 'N'
	group by i.PMCo, i.Project, i.SubmittalType, i.Submittal, i.Rev, i.Item, i.CopiesSent, d.CopiesSent
	end
if update(CopiesReqd)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, Item)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.SubmittalType),
			'SUBMIT', i.SubmittalType, i.Submittal, i.Rev, getdate(), 'C', 'CopiesReqd',
			isnull(convert(varchar(3),d.CopiesReqd),''), isnull(convert(varchar(3),i.CopiesReqd),''),
			SUSER_SNAME(), 'Copies Reqd has been changed', i.Item
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.SubmittalType=i.SubmittalType
	and d.Submittal=i.Submittal and d.Rev=i.Rev and d.Item=i.Item
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='SUBMIT'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.CopiesReqd,'') <> isnull(i.CopiesReqd,'')
	and c.DocHistSubmittal = 'Y' and i.ChangedFromPMSM = 'N'
	group by i.PMCo, i.Project, i.SubmittalType, i.Submittal, i.Rev, i.Item, i.CopiesReqd, d.CopiesReqd
	end
if update(CopiesRecdArch)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, Item)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.SubmittalType),
			'SUBMIT', i.SubmittalType, i.Submittal, i.Rev, getdate(), 'C', 'CopiesRecdArch',
			isnull(convert(varchar(3),d.CopiesRecdArch),''), isnull(convert(varchar(3),i.CopiesRecdArch),''),
			SUSER_SNAME(), 'Copies Recd Arch has been changed', i.Item
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.SubmittalType=i.SubmittalType
	and d.Submittal=i.Submittal and d.Rev=i.Rev and d.Item=i.Item
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='SUBMIT'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.CopiesRecdArch,'') <> isnull(i.CopiesRecdArch,'')
	and c.DocHistSubmittal = 'Y' and i.ChangedFromPMSM = 'N'
	group by i.PMCo, i.Project, i.SubmittalType, i.Submittal, i.Rev, i.Item, i.CopiesRecdArch, d.CopiesRecdArch
	end
if update(CopiesSentArch)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, Item)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.SubmittalType),
			'SUBMIT', i.SubmittalType, i.Submittal, i.Rev, getdate(), 'C', 'CopiesSentArch',
			isnull(convert(varchar(3),d.CopiesSentArch),''), isnull(convert(varchar(3),i.CopiesSentArch),''),
			SUSER_SNAME(), 'Copies Sent Arch has been changed', i.Item
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.SubmittalType=i.SubmittalType
	and d.Submittal=i.Submittal and d.Rev=i.Rev and d.Item=i.Item
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='SUBMIT'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.CopiesSentArch,'') <> isnull(i.CopiesSentArch,'')
	and c.DocHistSubmittal = 'Y' and i.ChangedFromPMSM = 'N'
	group by i.PMCo, i.Project, i.SubmittalType, i.Submittal, i.Rev, i.Item, i.CopiesSentArch, d.CopiesSentArch
	end
if update(DateReqd)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, Item)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.SubmittalType),
			'SUBMIT', i.SubmittalType, i.Submittal, i.Rev, getdate(), 'C', 'DateReqd',
			isnull(convert(char(8),d.DateReqd,1),''), isnull(convert(char(8),i.DateReqd,1),''),
			SUSER_SNAME(), 'Date Reqd Arch has been changed', i.Item
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.SubmittalType=i.SubmittalType
	and d.Submittal=i.Submittal and d.Rev=i.Rev and d.Item=i.Item
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='SUBMIT'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.DateReqd,'') <> isnull(i.DateReqd,'')
	and c.DocHistSubmittal = 'Y' and i.ChangedFromPMSM = 'N'
	group by i.PMCo, i.Project, i.SubmittalType, i.Submittal, i.Rev, i.Item, i.DateReqd, d.DateReqd
	end
if update(DateRecd)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, Item)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.SubmittalType),
			'SUBMIT', i.SubmittalType, i.Submittal, i.Rev, getdate(), 'C', 'DateRecd',
			isnull(convert(char(8),d.DateRecd,1),''), isnull(convert(char(8),i.DateRecd,1),''),
			SUSER_SNAME(), 'Date Recd has been changed', i.Item
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.SubmittalType=i.SubmittalType
	and d.Submittal=i.Submittal and d.Rev=i.Rev and d.Item=i.Item
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='SUBMIT'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.DateRecd,'') <> isnull(i.DateRecd,'')
	and c.DocHistSubmittal = 'Y' and i.ChangedFromPMSM = 'N'
	group by i.PMCo, i.Project, i.SubmittalType, i.Submittal, i.Rev, i.Item, i.DateRecd, d.DateRecd
	end
if update(ToArchEng)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, Item)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.SubmittalType),
			'SUBMIT', i.SubmittalType, i.Submittal, i.Rev, getdate(), 'C', 'ToArchEng',
			isnull(convert(char(8),d.ToArchEng,1),''), isnull(convert(char(8),i.ToArchEng,1),''),
			SUSER_SNAME(), 'ToArchEng Date has been changed', i.Item
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.SubmittalType=i.SubmittalType
	and d.Submittal=i.Submittal and d.Rev=i.Rev and d.Item=i.Item
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='SUBMIT'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.ToArchEng,'') <> isnull(i.ToArchEng,'')
	and c.DocHistSubmittal = 'Y' and i.ChangedFromPMSM = 'N'
	group by i.PMCo, i.Project, i.SubmittalType, i.Submittal, i.Rev, i.Item, i.ToArchEng, d.ToArchEng
	end
if update(DueBackArch)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, Item)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.SubmittalType),
			'SUBMIT', i.SubmittalType, i.Submittal, i.Rev, getdate(), 'C', 'DueBackArch',
			isnull(convert(char(8),d.DueBackArch,1),''), isnull(convert(char(8),i.DueBackArch,1),''),
			SUSER_SNAME(), 'DueBackArch Date has been changed', i.Item
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.SubmittalType=i.SubmittalType
	and d.Submittal=i.Submittal and d.Rev=i.Rev and d.Item=i.Item
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='SUBMIT'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.DueBackArch,'') <> isnull(i.DueBackArch,'')
	and c.DocHistSubmittal = 'Y' and i.ChangedFromPMSM = 'N'
	group by i.PMCo, i.Project, i.SubmittalType, i.Submittal, i.Rev, i.Item, i.DueBackArch, d.DueBackArch
	end
if update(RecdBackArch)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, Item)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.SubmittalType),
			'SUBMIT', i.SubmittalType, i.Submittal, i.Rev, getdate(), 'C', 'RecdBackArch',
			isnull(convert(char(8),d.RecdBackArch,1),''), isnull(convert(char(8),i.RecdBackArch,1),''),
			SUSER_SNAME(), 'RecdBackArch Date has been changed', i.Item
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.SubmittalType=i.SubmittalType
	and d.Submittal=i.Submittal and d.Rev=i.Rev and d.Item=i.Item
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='SUBMIT'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.RecdBackArch,'') <> isnull(i.RecdBackArch,'')
	and c.DocHistSubmittal = 'Y' and i.ChangedFromPMSM = 'N'
	group by i.PMCo, i.Project, i.SubmittalType, i.Submittal, i.Rev, i.Item, i.RecdBackArch, d.RecdBackArch
	end
if update(DateRetd)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, Item)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.SubmittalType),
			'SUBMIT', i.SubmittalType, i.Submittal, i.Rev, getdate(), 'C', 'DateRetd',
			isnull(convert(char(8),d.DateRetd,1),''), isnull(convert(char(8),i.DateRetd,1),''),
			SUSER_SNAME(), 'Date Retd has been changed', i.Item
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.SubmittalType=i.SubmittalType
	and d.Submittal=i.Submittal and d.Rev=i.Rev and d.Item=i.Item
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='SUBMIT'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.DateRetd,'') <> isnull(i.DateRetd,'')
	and c.DocHistSubmittal = 'Y' and i.ChangedFromPMSM = 'N'
	group by i.PMCo, i.Project, i.SubmittalType, i.Submittal, i.Rev, i.Item, i.DateRetd, d.DateRetd
	end
if update(ActivityDate)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, Item)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.SubmittalType),
			'SUBMIT', i.SubmittalType, i.Submittal, i.Rev, getdate(), 'C', 'ActivityDate',
			isnull(convert(char(8),d.ActivityDate,1),''), isnull(convert(char(8),i.ActivityDate,1),''),
			SUSER_SNAME(), 'Activity Date has been changed', i.Item
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.SubmittalType=i.SubmittalType
	and d.Submittal=i.Submittal and d.Rev=i.Rev and d.Item=i.Item
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='SUBMIT'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.ActivityDate,'') <> isnull(i.ActivityDate,'')
	and c.DocHistSubmittal = 'Y' and i.ChangedFromPMSM = 'N'
	group by i.PMCo, i.Project, i.SubmittalType, i.Submittal, i.Rev, i.Item, i.ActivityDate, d.ActivityDate
	END
---- #134090
if update(SpecNumber)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, Item)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.SubmittalType),
			'SUBMIT', i.SubmittalType, i.Submittal, i.Rev, getdate(), 'C', 'SpecNumber',
			d.SpecNumber, i.SpecNumber, SUSER_SNAME(), 'Spec Number has been changed', i.Item
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.SubmittalType=i.SubmittalType
	and d.Submittal=i.Submittal and d.Rev=i.Rev AND d.Item=i.Item
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='SUBMIT'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.SpecNumber,'') <> isnull(i.SpecNumber,'')
	and c.DocHistSubmittal = 'Y' AND i.ChangedFromPMSM = 'N'
	group by i.PMCo, i.Project, i.SubmittalType, i.Submittal, i.Rev, i.Item, i.SpecNumber, d.SpecNumber
	end
if update(Issue)
	begin
	insert into bPMDH(PMCo, Project, Seq,
			DocCategory, DocType, Document, Rev, ActionDateTime, FieldType, FieldName,
			OldValue, NewValue, UserName, Action, Item)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.SubmittalType),
			'SUBMIT', i.SubmittalType, i.Submittal, i.Rev, getdate(), 'C', 'Issue',
			convert(varchar(8),d.Issue), convert(varchar(8),i.Issue),  SUSER_SNAME(), 'Issue has been changed', i.Item
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.SubmittalType=i.SubmittalType
	and d.Submittal=i.Submittal and d.Rev=i.Rev AND d.Item=i.Item
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='SUBMIT'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Issue,0) <> isnull(i.Issue,0)
	and c.DocHistSubmittal = 'Y' AND i.ChangedFromPMSM = 'N'
	group by i.PMCo, i.Project, i.SubmittalType, i.Submittal, i.Rev, i.Item, i.Issue, d.Issue
	end

RETURN 
   
  
 








GO
ALTER TABLE [dbo].[bPMSI] ADD CONSTRAINT [PK_bPMSI] PRIMARY KEY CLUSTERED  ([PMCo], [Project], [SubmittalType], [Submittal], [Rev], [Item]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMSI] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO

ALTER TABLE [dbo].[bPMSI] WITH NOCHECK ADD CONSTRAINT [FK_bPMSI_bPMSM] FOREIGN KEY ([PMCo], [Project], [Submittal], [SubmittalType], [Rev]) REFERENCES [dbo].[bPMSM] ([PMCo], [Project], [Submittal], [SubmittalType], [Rev]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[bPMSI] WITH NOCHECK ADD CONSTRAINT [FK_bPMSI_bPMSC] FOREIGN KEY ([Status]) REFERENCES [dbo].[bPMSC] ([Status])
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPMSI].[Send]'
GO
