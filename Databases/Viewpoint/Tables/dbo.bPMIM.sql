CREATE TABLE [dbo].[bPMIM]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bJob] NOT NULL,
[Issue] [dbo].[bIssue] NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[DateInitiated] [dbo].[bDate] NOT NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[FirmNumber] [dbo].[bFirm] NULL,
[Initiator] [dbo].[bEmployee] NULL,
[MasterIssue] [dbo].[bIssue] NULL,
[DateResolved] [dbo].[bDate] NULL,
[Status] [tinyint] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[Type] [dbo].[bDocType] NULL,
[IssueInfo] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[Reference] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[CostImpactYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMIM_CostImpactYN] DEFAULT ('N'),
[CostImpact] [dbo].[bDollar] NULL,
[DaysImpactYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMIM_DaysImpactYN] DEFAULT ('N'),
[DaysImpact] [smallint] NULL,
[RelatedFirm] [dbo].[bFirm] NULL,
[RelatedFirmContact] [dbo].[bEmployee] NULL,
[ROMImpact] [dbo].[bDollar] NULL,
[ROMImpactYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMIM_ROMImpactYN] DEFAULT ('N'),
[DescImpact] [dbo].[bItemDesc] NULL,
[udDueDate] [smalldatetime] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biPMIM] ON [dbo].[bPMIM] ([PMCo], [Project], [Issue]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMIM] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

ALTER TABLE [dbo].[bPMIM] WITH NOCHECK ADD
CONSTRAINT [FK_bPMIM_bJCJM] FOREIGN KEY ([PMCo], [Project]) REFERENCES [dbo].[bJCJM] ([JCCo], [Job])
ALTER TABLE [dbo].[bPMIM] WITH NOCHECK ADD
CONSTRAINT [FK_bPMIM_bPMPM] FOREIGN KEY ([VendorGroup], [FirmNumber], [Initiator]) REFERENCES [dbo].[bPMPM] ([VendorGroup], [FirmNumber], [ContactCode])
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Trigger dbo.btPMIMd    Script Date: 8/28/99 9:37:53 AM ******/
CREATE trigger [dbo].[btPMIMd] on [dbo].[bPMIM] for DELETE as
/*--------------------------------------------------------------
 * Delete trigger for PMIM
 * Created By:	LM 12/19/97
 * Modified By:	GF 12/14/2006 - 6.x HQMA auditing
 *				GF 12/21/2010 - issue #141957 record association
 *				gf 01/26/2011 - tfs #398 with issue in related records allow delete without checks for other tables
 *
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on


---- delete PM distribution audit tables if any
delete bPMHA from bPMHA a join bPMHI i on i.KeyId=a.PMHIKeyId
join deleted d on i.SourceTableName='PMIM' and i.SourceKeyId=d.KeyID

delete bPMHF from bPMHF a join bPMHI i on i.KeyId=a.PMHIKeyId
join deleted d on i.SourceTableName='PMIM' and i.SourceKeyId=d.KeyID

delete bPMHI from bPMHI i
join deleted d on i.SourceTableName='PMIM' and i.SourceKeyId=d.KeyID

---- #134090
delete dbo.vPMDistribution
from dbo.vPMDistribution v JOIN deleted d ON d.KeyID=v.IssueID

---- delete associations if any from both sides - #141957
---- record side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='PMIM' AND a.RECID=d.KeyID
WHERE d.KeyID IS NOT NULL
---- link side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMRelateRecord a ON a.LinkTableName='PMIM' AND a.LINKID=d.KeyID
WHERE d.KeyID IS NOT NULL


---- HQMA inserts
insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bPMIM','PMCo: ' + isnull(convert(char(3),d.PMCo), '') + ' Project: ' + isnull(d.Project,'') + ' Issue: ' + isnull(convert(varchar(10),d.Issue),''),
		d.PMCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from deleted d JOIN bPMCO c ON d.PMCo=c.PMCo
where c.AuditPMIM = 'Y'


RETURN 

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Trigger dbo.btPMIMi    Script Date: 8/28/99 9:37:53 AM ******/
CREATE trigger [dbo].[btPMIMi] on [dbo].[bPMIM] for INSERT as
/*--------------------------------------------------------------
 * Insert trigger for PMIM
 * Created By:	LM 12/18/97
 *              GF 04/21/2001 - Issue 13180 - cannot insert null into PMIH
 *				RT 02/05/2004 - Issue #16547 - changed to say "has been added TO issue master".
 *				GF 01/15/2007 - 6.x added HQMA auditing
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on 

---- Audit inserts
insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bPMIM', 'PMCo: ' + convert(char(3), i.PMCo) + ' Project: ' + isnull(i.Project,'') + ' Issue: ' + isnull(convert(varchar(10),i.Issue),''),
       i.PMCo, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from inserted i join bPMCO c on c.PMCo = i.PMCo
where c.AuditPMIM = 'Y'

RETURN 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Trigger dbo.btPMIMu    Script Date: 8/28/99 9:37:54 AM ******/
CREATE  trigger [dbo].[btPMIMu] on [dbo].[bPMIM] for UPDATE as
/*--------------------------------------------------------------
 * Update trigger for PMIM
 * Created By:  LM	12/18/97
 *Modified By:	GF 02/20/2002 - Issue #16337 allow null master issues
 *				GF 11/6/2006 - 6.x record issue history if status changed.
 *				GF 11/30/2006 - issue #123230 allow for null initiator.
 *				GF 01/15/2007 - 6.x added HQMA auditing
 *				GF 05/13/2011 - TK-00000 date and login into PMIH
 *				JayR 03/22/2012 - TK-00000 Change to use FKs for validation
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

---- check for changes to PMCo
if update(PMCo)
	begin
	RAISERROR('Cannot change PMCo - cannot update PMIM', 11, -1)
	ROLLBACK TRANSACTION
	RETURN 
	end

---- check for changes to Project
if update(Project)
	begin
	RAISERROR('Cannot change Project - cannot update PMIM', 11, -1)
	ROLLBACK TRANSACTION
	RETURN 
	end

---- check for changes to Issue
if update(Issue)
	begin
	RAISERROR('Cannot change Issue - cannot update PMIM', 11, -1)
	ROLLBACK TRANSACTION
	RETURN 
	end

IF EXISTS 
        ( 
        SELECT  1
        FROM    INSERTED i
		  JOIN DELETED d
		  ON i.KeyID = d.KeyID
        WHERE  ISNULL(i.MasterIssue,-1) <> ISNULL(d.MasterIssue,-1)
		AND NOT EXISTS 
            ( 
            SELECT 1
            FROM   bPMIM r
            WHERE  i.PMCo = r.PMCo
            AND i.Project = r.Project
            AND i.MasterIssue = r.Issue 
            ) 
        ) 
        BEGIN 
			RAISERROR('Master Issue is Invalid - cannot update PMIM', 11, -1)
            ROLLBACK TRANSACTION
            RETURN 
END

---- insert issue history
if update (Status)
	begin
	---- closed TK-00000
	insert into bPMIH (PMCo, Project, Issue, Seq, IssueDateTime, Action, Login, ActionDate)
	select i.PMCo, i.Project, i.Issue,
			isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.Issue ASC),
			GETDATE(), 'Closed', SUSER_SNAME(), GETDATE()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.Issue=i.Issue
	left join bPMIH h on h.PMCo=i.PMCo and h.Project=i.Project and h.Issue=i.Issue
	where isnull(i.Status,'') <> isnull(d.Status,'') and isnull(i.Status,1) = 1
	group by i.PMCo, i.Project, i.Issue, i.Status, d.Status
	---- re-opened TK-00000
	insert into bPMIH (PMCo, Project, Issue, Seq, IssueDateTime, Action, Login, ActionDate)
	select i.PMCo, i.Project, i.Issue,
			isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.Issue ASC),
			GETDATE(), 'Re-Opened', SUSER_SNAME(), GETDATE()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.Issue=i.Issue
	left join bPMIH h on h.PMCo=i.PMCo and h.Project=i.Project and h.Issue=i.Issue
	where isnull(i.Status,'') <> isnull(d.Status,'') and isnull(i.Status,1) <> 1
	group by i.PMCo, i.Project, i.Issue, i.Status, d.Status
	end



---- HQMA inserts
if not exists(select top 1 1 from inserted i join bPMCO c with (nolock) on i.PMCo=c.PMCo and c.AuditPMIM = 'Y')
	begin
  	goto trigger_end
	end

if update(Description)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMIM', 'PMCo: ' + convert(varchar(3), i.PMCo) + ' Project: ' + isnull(i.Project,'') + ' Issue: ' + isnull(convert(varchar(10),i.Issue),''),
		i.PMCo, 'C', 'Description', d.Description, i.Description, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.Issue=i.Issue
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.Description,'') <> isnull(i.Description,'') and c.AuditPMIM='Y'
	end
if update(DateInitiated)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMIM', 'PMCo: ' + convert(varchar(3), i.PMCo) + ' Project: ' + isnull(i.Project,'') + ' Issue: ' + isnull(convert(varchar(10),i.Issue),''),
		i.PMCo, 'C', 'DateInitiated', isnull(convert(char(8),d.DateInitiated,1),''), isnull(convert(char(8),i.DateInitiated,1),''), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.Issue=i.Issue
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.DateInitiated,'') <> isnull(i.DateInitiated,'') and c.AuditPMIM='Y'
	end
if update(Initiator)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMIM', 'PMCo: ' + convert(varchar(3), i.PMCo) + ' Project: ' + isnull(i.Project,'') + ' Issue: ' + isnull(convert(varchar(10),i.Issue),''),
		i.PMCo, 'C', 'Initiator', isnull(convert(varchar(10),d.Initiator),''), isnull(convert(varchar(10),i.Initiator),''), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.Issue=i.Issue
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.Initiator,'') <> isnull(i.Initiator,'') and c.AuditPMIM='Y'
	end
if update(MasterIssue)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMIM', 'PMCo: ' + convert(varchar(3), i.PMCo) + ' Project: ' + isnull(i.Project,'') + ' Issue: ' + isnull(convert(varchar(10),i.Issue),''),
		i.PMCo, 'C', 'MasterIssue', isnull(convert(varchar(10),d.MasterIssue),''), isnull(convert(varchar(10),i.MasterIssue),''), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.Issue=i.Issue
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.MasterIssue,'') <> isnull(i.MasterIssue,'') and c.AuditPMIM='Y'
	end
if update(DateResolved)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMIM', 'PMCo: ' + convert(varchar(3), i.PMCo) + ' Project: ' + isnull(i.Project,'') + ' Issue: ' + isnull(convert(varchar(10),i.Issue),''),
		i.PMCo, 'C', 'DateResolved', isnull(convert(char(8),d.DateResolved,1),''), isnull(convert(char(8),i.DateResolved,1),''), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.Issue=i.Issue
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.DateResolved,'') <> isnull(i.DateResolved,'') and c.AuditPMIM='Y'
	end


trigger_end:

RETURN 


GO
ALTER TABLE [dbo].[bPMIM] WITH NOCHECK ADD CONSTRAINT [CK_bPMIM_Initiator] CHECK (([Initiator] IS NULL OR [VendorGroup] IS NOT NULL AND [FirmNumber] IS NOT NULL))
GO
ALTER TABLE [dbo].[bPMIM] WITH NOCHECK ADD CONSTRAINT [CK_bPMIM_Issue] CHECK (([Issue]<>(-1)))
GO
ALTER TABLE [dbo].[bPMIM] ADD CONSTRAINT [PK_bPMIM] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
