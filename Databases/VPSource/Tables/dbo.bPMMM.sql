CREATE TABLE [dbo].[bPMMM]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bJob] NOT NULL,
[MeetingType] [dbo].[bDocType] NOT NULL,
[MeetingDate] [dbo].[bDate] NOT NULL,
[Meeting] [int] NOT NULL,
[MinutesType] [tinyint] NOT NULL,
[MeetingTime] [smalldatetime] NULL,
[Location] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[Subject] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[FirmNumber] [dbo].[bFirm] NULL,
[Preparer] [dbo].[bEmployee] NULL,
[NextDate] [dbo].[bDate] NULL,
[NextTime] [smalldatetime] NULL,
[NextLocation] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
ALTER TABLE [dbo].[bPMMM] ADD
CONSTRAINT [FK_bPMMM_bJCJM] FOREIGN KEY ([PMCo], [Project]) REFERENCES [dbo].[bJCJM] ([JCCo], [Job])
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/***********************************************************/
CREATE  trigger [dbo].[btPMMMd] on [dbo].[bPMMM] for DELETE as
/*--------------------------------------------------------------
 * Delete trigger for PMMM
 * Created By:	LM 1/21/98
 * Modified By: GF 06/17/2002
 *				GF 01/15/2007 - 6.x HQMA auditing
 *				GF 12/21/2010 - issue #141957 record association
 *				GF 01/26/2011 - TFS #398
 *				JayR 03/23/2012  Change to use FKs for validation
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
DELETE dbo.vPMIssueHistory FROM deleted d WHERE RelatedTableName = 'bPMMM' AND RelatedKeyID = d.KeyID
---- insert
INSERT dbo.vPMIssueHistory (IssueKeyID,RelatedTableName,RelatedKeyID,Co,Project,Issue,ActionType,RelatedDeleteAction)
SELECT x.KeyID, 'bPMMM', d.KeyID, d.PMCo, d.Project, x.Issue, 'D',
		'Meeting Type: ' + ISNULL(d.MeetingType,'') + ' Meeting Date: ' + dbo.vfDateOnlyAsStringUsingStyle(d.MeetingDate, d.PMCo, 111) + ' Meeting: ' + ISNULL(CONVERT(VARCHAR(20),d.Meeting),'') + ' Minutes Type: ' + ISNULL(CONVERT(VARCHAR(3),d.MinutesType),'') + ' : ' + ISNULL(d.Subject,'')	
from deleted d
JOIN dbo.vPMRelateRecord r ON r.RecTableName = 'bPMMM' AND r.RECID = d.KeyID AND r.LinkTableName = 'bPMIM'
JOIN dbo.bPMIM x ON x.KeyID = r.LINKID
WHERE d.KeyID=r.RECID
---- link side
INSERT dbo.vPMIssueHistory (IssueKeyID,RelatedTableName,RelatedKeyID,Co,Project,Issue,ActionType,RelatedDeleteAction)
SELECT x.KeyID, 'bPMMM', d.KeyID, d.PMCo, d.Project, x.Issue, 'D',
		'Meeting Type: ' + ISNULL(d.MeetingType,'') + ' Meeting Date: ' + dbo.vfDateOnlyAsStringUsingStyle(d.MeetingDate, d.PMCo, 111) + ' Meeting: ' + ISNULL(CONVERT(VARCHAR(20),d.Meeting),'') + ' Minutes Type: ' + ISNULL(CONVERT(VARCHAR(3),d.MinutesType),'') + ' : ' + ISNULL(d.Subject,'')	
from deleted d
JOIN dbo.vPMRelateRecord r ON r.LinkTableName = 'bPMMM' AND r.LINKID = d.KeyID AND r.RecTableName = 'bPMIM'
JOIN dbo.bPMIM x ON x.KeyID = r.RECID
WHERE d.KeyID=r.LINKID

---- delete associations if any from both sides - #141957
---- record side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='bPMMM' AND a.RECID=d.KeyID
WHERE d.KeyID IS NOT NULL
---- link side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMRelateRecord a ON a.LinkTableName='bPMMM' AND a.LINKID=d.KeyID
WHERE d.KeyID IS NOT NULL


---- HQMA inserts
insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bPMMM','PMCo: ' + isnull(convert(char(3),d.PMCo), '') + ' Project: ' + isnull(d.Project,'') + ' MeetingType: '
		+ isnull(d.MeetingType,'') + ' Meeting: ' + isnull(convert(varchar(8),d.Meeting),'') + ' MinutesType: ' + isnull(convert(varchar(1),d.MinutesType),''),
		d.PMCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from deleted d JOIN bPMCO c ON d.PMCo=c.PMCo
where c.AuditPMMM = 'Y'


RETURN 





GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMMMi    Script Date: 8/28/99 9:37:54 AM ******/
CREATE trigger [dbo].[btPMMMi] on [dbo].[bPMMM] for INSERT as
/*--------------------------------------------------------------
 * Insert trigger for PMMM
 * Created By:	LM 1/21/98
 * Modified By:	GF 01/13/2007 - 6.x HQMA auditing
 *				JayR 03/23/2012 Change to use FK and constraints for validation
 *
 *
 *--------------------------------------------------------------*/
declare @numrows int,  @validcnt int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on


---- Validate MeetingType
select @validcnt = count(*) from bPMDT r JOIN inserted i ON i.MeetingType = r.DocType and r.DocCategory = 'MTG'
if @validcnt <> @numrows
	begin
	RAISERROR('Meeting Type is Invalid - cannot insert into PMMM', 11, -1)
	ROLLBACK TRANSACTION 
	RETURN
	end

---- Validate Preparer
--select @validcnt = count(*) from bPMPM r JOIN inserted i ON i.VendorGroup = r.VendorGroup
--   		and i.FirmNumber = r.FirmNumber and i.Preparer = r.ContactCode
--select @validcnt2 = count(*) from inserted i where i.Preparer is null
--if @validcnt + @validcnt2 <> @numrows
--	begin
--	select @errmsg = 'Preparer is Invalid '
--	goto error
--	end


-- Audit inserts
insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bPMMM','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'') + ' MeetingType: '
		+ isnull(i.MeetingType,'') + ' Meeting: ' + isnull(convert(varchar(8),i.Meeting),'') + ' MinutesType: ' + isnull(convert(varchar(1),i.MinutesType),''),
		i.PMCo, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from inserted i join bPMCO c on c.PMCo = i.PMCo
where i.PMCo = c.PMCo and c.AuditPMMF = 'Y'


RETURN 








GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMMMu    Script Date: 8/28/99 9:37:55 AM ******/
CREATE trigger [dbo].[btPMMMu] on [dbo].[bPMMM] for UPDATE as
/*--------------------------------------------------------------
 * Update trigger for PMMM
 * Created By:	LM 1/21/98
 * Modified By:	GF 10/11/2002 - #18910 Allow changes to meeting minute date
 *				GF 01/15/2007 - 6.x HQMA auditing
 *				JayR 03/23/2012 - TK-00000 Change to use FKs for validation
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

---- check for changes to PMCo
if update(PMCo)
       begin
       RAISERROR('Cannot change PMCo - cannot update PMMM', 11, -1)
       ROLLBACK TRANSACTION
       RETURN 
       end

---- check for changes to Project
if update(Project)
       begin
       RAISERROR('Cannot change Project - cannot update PMMM', 11, -1)
       ROLLBACK TRANSACTION
       RETURN
       end

---- check for changes to MeetingType
if update(MeetingType)
       begin
       RAISERROR('Cannot change MeetingType - cannot update PMMM', 11, -1)
       ROLLBACK TRANSACTION
       RETURN
       end

---- check for changes to Meeting
if update(Meeting)
       begin
       RAISERROR('Cannot change Meeting - cannot update PMMM', 11, -1)
       ROLLBACK TRANSACTION
       RETURN
       end

---- check for changes to MinutesType
if update(MinutesType)
       begin
       RAISERROR('Cannot change MinutesType - cannot update PMMM', 11, -1)
       ROLLBACK TRANSACTION
       RETURN
       end


---- HQMA inserts
if not exists(select top 1 1 from inserted i join bPMCO c with (nolock) on i.PMCo=c.PMCo and c.AuditPMMM='Y')
	begin
  	goto trigger_end
	end

if update(Subject)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMMM','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'') + ' MeetingType: '
			+ isnull(i.MeetingType,'') + ' Meeting: ' + isnull(convert(varchar(8),i.Meeting),'') + ' MinutesType: ' + isnull(convert(varchar(1),i.MinutesType),''),
			i.PMCo, 'C', 'Subject', d.Subject, i.Subject, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.MeetingType=i.MeetingType and d.Meeting=i.Meeting and d.MinutesType=i.MinutesType
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.Subject,'') <> isnull(i.Subject,'') and c.AuditPMMM='Y'
	end
if update(MeetingDate)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMMM','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'') + ' MeetingType: '
			+ isnull(i.MeetingType,'') + ' Meeting: ' + isnull(convert(varchar(8),i.Meeting),'') + ' MinutesType: ' + isnull(convert(varchar(1),i.MinutesType),''),
			i.PMCo, 'C', 'MeetingDate', convert(char(8),d.MeetingDate,1), convert(char(8),i.MeetingDate,1), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.MeetingType=i.MeetingType and d.Meeting=i.Meeting and d.MinutesType=i.MinutesType
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.MeetingDate,'') <> isnull(i.MeetingDate,'') and c.AuditPMMM='Y'
	end
if update(MeetingTime)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMMM','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'') + ' MeetingType: '
			+ isnull(i.MeetingType,'') + ' Meeting: ' + isnull(convert(varchar(8),i.Meeting),'') + ' MinutesType: ' + isnull(convert(varchar(1),i.MinutesType),''),
			i.PMCo, 'C', 'MeetingTime', isnull(convert(varchar(5),d.MeetingTime,8),''), isnull(convert(varchar(5),i.MeetingTime,8),''), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.MeetingType=i.MeetingType and d.Meeting=i.Meeting and d.MinutesType=i.MinutesType
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.MeetingTime,'') <> isnull(i.MeetingTime,'') and c.AuditPMMM='Y'
	end
if update(Location)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMMM','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'') + ' MeetingType: '
			+ isnull(i.MeetingType,'') + ' Meeting: ' + isnull(convert(varchar(8),i.Meeting),'') + ' MinutesType: ' + isnull(convert(varchar(1),i.MinutesType),''),
			i.PMCo, 'C', 'Location', d.Location, i.Location, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.MeetingType=i.MeetingType and d.Meeting=i.Meeting and d.MinutesType=i.MinutesType
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.Location,'') <> isnull(i.Location,'') and c.AuditPMMM='Y'
	end
if update(FirmNumber)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMMM','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'') + ' MeetingType: '
			+ isnull(i.MeetingType,'') + ' Meeting: ' + isnull(convert(varchar(8),i.Meeting),'') + ' MinutesType: ' + isnull(convert(varchar(1),i.MinutesType),''),
			i.PMCo, 'C', 'FirmNumber', convert(varchar(10),d.FirmNumber), convert(varchar(10),i.FirmNumber), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.MeetingType=i.MeetingType and d.Meeting=i.Meeting and d.MinutesType=i.MinutesType
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.FirmNumber,0) <> isnull(i.FirmNumber,0) and c.AuditPMMM='Y'
	end
if update(Preparer)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMMM','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'') + ' MeetingType: '
			+ isnull(i.MeetingType,'') + ' Meeting: ' + isnull(convert(varchar(8),i.Meeting),'') + ' MinutesType: ' + isnull(convert(varchar(1),i.MinutesType),''),
			i.PMCo, 'C', 'Preparer', convert(varchar(10),d.Preparer), convert(varchar(10),i.Preparer), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.MeetingType=i.MeetingType and d.Meeting=i.Meeting and d.MinutesType=i.MinutesType
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.Preparer,0) <> isnull(i.Preparer,0) and c.AuditPMMM='Y'
	end
if update(NextDate)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMMM','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'') + ' MeetingType: '
			+ isnull(i.MeetingType,'') + ' Meeting: ' + isnull(convert(varchar(8),i.Meeting),'') + ' MinutesType: ' + isnull(convert(varchar(1),i.MinutesType),''),
			i.PMCo, 'C', 'NextDate', convert(char(8),d.NextDate,1), convert(char(8),i.NextDate,1), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.MeetingType=i.MeetingType and d.Meeting=i.Meeting and d.MinutesType=i.MinutesType
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.NextDate,'') <> isnull(i.NextDate,'') and c.AuditPMMM='Y'
	end
if update(NextTime)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMMM','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'') + ' MeetingType: '
			+ isnull(i.MeetingType,'') + ' Meeting: ' + isnull(convert(varchar(8),i.Meeting),'') + ' MinutesType: ' + isnull(convert(varchar(1),i.MinutesType),''),
			i.PMCo, 'C', 'NextTime', d.NextTime, i.NextTime, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.MeetingType=i.MeetingType and d.Meeting=i.Meeting and d.MinutesType=i.MinutesType
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.NextTime,'') <> isnull(i.NextTime,'') and c.AuditPMMM='Y'
	end
if update(NextLocation)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMMM','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'') + ' MeetingType: '
			+ isnull(i.MeetingType,'') + ' Meeting: ' + isnull(convert(varchar(8),i.Meeting),'') + ' MinutesType: ' + isnull(convert(varchar(1),i.MinutesType),''),
			i.PMCo, 'C', 'Location', d.NextLocation, i.NextLocation, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.MeetingType=i.MeetingType and d.Meeting=i.Meeting and d.MinutesType=i.MinutesType
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.NextLocation,'') <> isnull(i.NextLocation,'') and c.AuditPMMM='Y'
	end




trigger_end:

RETURN 
   
  
 











GO
ALTER TABLE [dbo].[bPMMM] WITH NOCHECK ADD CONSTRAINT [CK_bPMMM_MinutesType] CHECK (([MinutesType]=(1) OR [MinutesType]=(0)))
GO
ALTER TABLE [dbo].[bPMMM] WITH NOCHECK ADD CONSTRAINT [CK_bPMMM_Preparer] CHECK (([Preparer] IS NULL OR [VendorGroup] IS NOT NULL AND [FirmNumber] IS NOT NULL))
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMMM] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPMMM] ON [dbo].[bPMMM] ([PMCo], [Project], [MeetingType], [Meeting], [MinutesType]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bPMMM] WITH NOCHECK ADD CONSTRAINT [FK_bPMMM_bPMDT] FOREIGN KEY ([MeetingType]) REFERENCES [dbo].[bPMDT] ([DocType])
GO

ALTER TABLE [dbo].[bPMMM] WITH NOCHECK ADD CONSTRAINT [FK_bPMMM_bPMPM] FOREIGN KEY ([VendorGroup], [FirmNumber], [Preparer]) REFERENCES [dbo].[bPMPM] ([VendorGroup], [FirmNumber], [ContactCode])
GO
