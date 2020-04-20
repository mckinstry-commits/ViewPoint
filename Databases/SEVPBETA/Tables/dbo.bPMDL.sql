CREATE TABLE [dbo].[bPMDL]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bJob] NOT NULL,
[LogDate] [dbo].[bDate] NOT NULL,
[DailyLog] [smallint] NOT NULL,
[Description] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Weather] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Wind] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[TempHigh] [smallint] NULL,
[TempLow] [smallint] NULL,
[EmployeeYN] [dbo].[bYN] NOT NULL,
[CrewYN] [dbo].[bYN] NOT NULL,
[SubcontractYN] [dbo].[bYN] NOT NULL,
[EquipmentYN] [dbo].[bYN] NOT NULL,
[ActivityYN] [dbo].[bYN] NOT NULL,
[ConversationsYN] [dbo].[bYN] NOT NULL,
[DeliveriesYN] [dbo].[bYN] NOT NULL,
[AccidentsYN] [dbo].[bYN] NOT NULL,
[VisitorsYN] [dbo].[bYN] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[udRespPerson] [int] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMDLd    Script Date: 8/28/99 9:37:50 AM ******/
CREATE  trigger [dbo].[btPMDLd] on [dbo].[bPMDL] for DELETE as
/*--------------------------------------------------------------
*
*  Delete trigger for PMDL
*  Created By: LM 1/21/98
*              9/25/01 - CHECK OF PMDC was looking at PMDD table
*				GF 01/17/2002 - Added auditing
*				GF 12/21/2010 - issue #141957 record association
*				GF 01/26/2011 - TFS #398
*				JayR 03/21/2012 Change to using FK for validation.
*
*--------------------------------------------------------------*/
	
if @@rowcount = 0 return
set nocount on

---- Check bPMDD for detail
--if exists(select * from deleted d JOIN bPMDD o ON d.PMCo = o.PMCo and d.Project = o.Project
--				and d.LogDate = o.LogDate and d.DailyLog = o.DailyLog)
--	begin
--	select @errmsg = 'Entries exist in bPMDD'
--	goto error
--	end

-- Check bPMDC for detail
--if exists(select * from deleted d JOIN bPMDC o ON d.PMCo = o.PMCo and d.Project = o.Project
--				and d.LogDate = o.LogDate and d.DailyLog = o.DailyLog)
--	begin
--	select @errmsg = 'Entries exist in bPMDC'
--	goto error
--	end


---- when the record is related to a project issue PMIM
---- we need to add a delete action recorded in history for the issue
---- noting that the type and code with a description ws deleted.
---- record side. TFS #398
---- delete
DELETE dbo.vPMIssueHistory FROM deleted d WHERE RelatedTableName = 'bPMDL' AND RelatedKeyID = d.KeyID
---- insert
INSERT dbo.vPMIssueHistory (IssueKeyID,RelatedTableName,RelatedKeyID,Co,Project,Issue,ActionType,RelatedDeleteAction)
SELECT x.KeyID, 'bPMDL', d.KeyID, d.PMCo, d.Project, x.Issue, 'D',
		'Daily Log Date: ' + dbo.vfDateOnlyAsStringUsingStyle(d.LogDate, d.PMCo, 111) + ' Daily Log: ' + ISNULL(CONVERT(VARCHAR(20),d.DailyLog),'')  + ' : ' + ISNULL(d.Description,'')	
from deleted d
JOIN dbo.vPMRelateRecord r ON r.RecTableName = 'PMDL' AND r.RECID = d.KeyID AND r.LinkTableName = 'PMIM'
JOIN dbo.bPMIM x ON x.KeyID = r.LINKID
WHERE d.KeyID=r.RECID
---- link side
INSERT dbo.vPMIssueHistory (IssueKeyID,RelatedTableName,RelatedKeyID,Co,Project,Issue,ActionType,RelatedDeleteAction)
SELECT x.KeyID, 'bPMDL', d.KeyID, d.PMCo, d.Project, x.Issue, 'D',
		'Daily Log Date: ' + dbo.vfDateOnlyAsStringUsingStyle(d.LogDate, d.PMCo, 111) + ' Daily Log: ' + ISNULL(CONVERT(VARCHAR(20),d.DailyLog),'')  + ' : ' + ISNULL(d.Description,'')	
from deleted d
JOIN dbo.vPMRelateRecord r ON r.LinkTableName = 'PMDL' AND r.LINKID = d.KeyID AND r.RecTableName = 'PMIM'
JOIN dbo.bPMIM x ON x.KeyID = r.RECID
WHERE d.KeyID=r.LINKID

---- delete associations if any from both sides - #141957
---- record side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='PMDL' AND a.RECID=d.KeyID
WHERE d.KeyID IS NOT NULL
---- link side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMRelateRecord a ON a.LinkTableName='PMDL' AND a.LINKID=d.KeyID
WHERE d.KeyID IS NOT NULL

   
-- Audit PM Daily Log deletions
INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
SELECT 'bPMDL', 'PM Co#: ' + isnull(convert(char(3), d.PMCo), '') + 'Project: ' + isnull(d.Project,'') + ' Log Date: ' + isnull(convert(varchar(8),d.LogDate,1),'') + ' Daily Log: ' + isnull(convert(varchar(4), d.DailyLog),''),
		d.PMCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
FROM deleted d JOIN bPMCO c ON d.PMCo=c.PMCo
where c.AuditDailyLogs = 'Y'


RETURN
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
   /****** Object:  Trigger dbo.btPMDLi    Script Date: 8/28/99 9:37:50 AM ******/
    CREATE   trigger [dbo].[btPMDLi] on [dbo].[bPMDL] for INSERT as
     

   /*--------------------------------------------------------------
    *
    * Insert trigger for PMDL
    * Created By:  LM 1/21/98
    *	Modified By:	GF 01/16/2002 - Added auditing
    *
    *--------------------------------------------------------------*/
   if @@rowcount = 0 return
   set nocount on
   
  
   
   -- Audit inserts
   INSERT INTO bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bPMDL',
   	'PM Co#: ' + isnull(convert(char(3), i.PMCo),'') + 'Project: ' + isnull(i.Project,'') + ' Log Date: ' + isnull(convert(varchar(8),i.LogDate,1),'') + ' Daily Log: ' + isnull(convert(varchar(4), i.DailyLog),''),
       i.PMCo, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
       FROM inserted i join bPMCO c on c.PMCo = i.PMCo
   	where i.PMCo = c.PMCo and c.AuditDailyLogs = 'Y'
   
 RETURN 
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
 
   
   /****** Object:  Trigger dbo.btPMDLu    Script Date: 8/28/99 9:37:50 AM ******/
   CREATE       trigger [dbo].[btPMDLu] on [dbo].[bPMDL] for UPDATE as
   

   /*--------------------------------------------------------------
    *
    * Update trigger for PMDL
    * Created By: LM 1/21/98
    *	Modified By:	GF 01/17/2002 - Added auditing
    *					JayR 03/21/2012 Remove gotos
    *--------------------------------------------------------------*/
   if @@rowcount = 0 return
   set nocount on
   
   -- check for changes to PMCo
   if update(PMCo)
       begin
       RAISERROR('Cannot change PM Company - cannot update PMDL', 11, -1)
       rollback TRANSACTION
       RETURN 
       end
   
   -- check for changes to Project
   if update(Project)
       begin
       RAISERROR('Cannot change Project - cannot update PMDL', 11, -1)
       rollback TRANSACTION
       RETURN 
       end
   
   -- check for changes to LogDate
   if update(LogDate)
       begin
       RAISERROR('Cannot change Log Date - cannot update PMDL', 11, -1)
       rollback TRANSACTION
       RETURN 
       end
   
   -- check for changes to DailyLog
   if update(DailyLog)
       begin
       RAISERROR('Cannot change Daily Log  - cannot update PMDL', 11, -1)
       rollback TRANSACTION
       RETURN 
       end
   
   
   -- Insert records into HQMA for changes made to audited fields
   IF UPDATE(Description)
   	insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPMDL',
   	'PM Co#: ' + isnull(convert(char(3), i.PMCo),'') + 'Project: ' + isnull(i.Project,'') + ' Log Date: ' + isnull(convert(varchar(8),i.LogDate,1),'') + ' Daily Log: ' + isnull(convert(varchar(4), i.DailyLog),''),
   	i.PMCo, 'C','Description', d.Description, i.Description, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on d.PMCo=i.PMCo and d.DailyLog=i.DailyLog
   	join bPMCO on i.PMCo=bPMCO.PMCo and bPMCO.AuditDailyLogs='Y'
   	where isnull(d.Description,'')<>isnull(i.Description,'')
   
   IF UPDATE(Weather)
   	insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPMDL',
   	'PM Co#: ' + isnull(convert(char(3), i.PMCo),'') + 'Project: ' + isnull(i.Project,'') + ' Log Date: ' + isnull(convert(varchar(8),i.LogDate,1),'') + ' Daily Log: ' + isnull(convert(varchar(4), i.DailyLog),''),
   	i.PMCo, 'C','Weather', d.Weather, i.Weather, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on d.PMCo=i.PMCo and d.DailyLog=i.DailyLog
   	join bPMCO on i.PMCo=bPMCO.PMCo and bPMCO.AuditDailyLogs='Y'
   	where isnull(d.Weather,'')<>isnull(i.Weather,'')
   
   IF UPDATE(Wind)
   	insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPMDL',
   	'PM Co#: ' + isnull(convert(char(3), i.PMCo),'') + 'Project: ' + isnull(i.Project,'') + ' Log Date: ' + isnull(convert(varchar(8),i.LogDate,1),'') + ' Daily Log: ' + isnull(convert(varchar(4), i.DailyLog),''),
   	i.PMCo, 'C','Wind', d.Wind, i.Wind, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on d.PMCo=i.PMCo and d.DailyLog=i.DailyLog
   	join bPMCO on i.PMCo=bPMCO.PMCo and bPMCO.AuditDailyLogs='Y'
   	where isnull(d.Wind,'')<>isnull(i.Wind,'')
   
   IF UPDATE(TempHigh)
   	insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPMDL',
   	'PM Co#: ' + isnull(convert(char(3), i.PMCo),'') + 'Project: ' + isnull(i.Project,'') + ' Log Date: ' + isnull(convert(varchar(8),i.LogDate,1),'') + ' Daily Log: ' + isnull(convert(varchar(4), i.DailyLog),''),
   	i.PMCo, 'C','High Temp', convert(varchar(5),d.TempHigh), convert(varchar(5),i.TempHigh), getdate(), SUSER_SNAME()
   	from inserted i join deleted d on d.PMCo=i.PMCo and d.DailyLog=i.DailyLog
   	join bPMCO on i.PMCo=bPMCO.PMCo and bPMCO.AuditDailyLogs='Y'
   	where isnull(d.TempHigh,0)<>isnull(i.TempHigh,0)
   
   IF UPDATE(TempLow)
   	insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPMDL',
   	'PM Co#: ' + isnull(convert(char(3), i.PMCo),'') + 'Project: ' + isnull(i.Project,'') + ' Log Date: ' + isnull(convert(varchar(8),i.LogDate,1),'') + ' Daily Log: ' + isnull(convert(varchar(4), i.DailyLog),''),
   	i.PMCo, 'C','Low Temp', convert(varchar(5),d.TempLow), convert(varchar(5),i.TempLow), getdate(), SUSER_SNAME()
   	from inserted i join deleted d on d.PMCo=i.PMCo and d.DailyLog=i.DailyLog
   	join bPMCO on i.PMCo=bPMCO.PMCo and bPMCO.AuditDailyLogs='Y'
   	where isnull(d.TempLow,0)<>isnull(i.TempLow,0)
   
   IF UPDATE(EmployeeYN)
   	insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPMDL',
   	'PM Co#: ' + isnull(convert(char(3), i.PMCo),'') + 'Project: ' + isnull(i.Project,'') + ' Log Date: ' + isnull(convert(varchar(8),i.LogDate,1),'') + ' Daily Log: ' + isnull(convert(varchar(4), i.DailyLog),''),
   	i.PMCo, 'C','Employee YN', d.EmployeeYN, i.EmployeeYN, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on d.PMCo=i.PMCo and d.DailyLog=i.DailyLog
   	join bPMCO on i.PMCo=bPMCO.PMCo and bPMCO.AuditDailyLogs='Y'
   	where d.EmployeeYN<>i.EmployeeYN
   
   IF UPDATE(CrewYN)
   	insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPMDL',
   	'PM Co#: ' + isnull(convert(char(3), i.PMCo),'') + 'Project: ' + isnull(i.Project,'') + ' Log Date: ' + isnull(convert(varchar(8),i.LogDate,1),'') + ' Daily Log: ' + isnull(convert(varchar(4), i.DailyLog),''),
   	i.PMCo, 'C','Crew Y/N', d.CrewYN, i.CrewYN, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on d.PMCo=i.PMCo and d.DailyLog=i.DailyLog
   	join bPMCO on i.PMCo=bPMCO.PMCo and bPMCO.AuditDailyLogs='Y'
   	where d.CrewYN<>i.CrewYN
   
   IF UPDATE(SubcontractYN)
   	insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPMDL',
   	'PM Co#: ' + isnull(convert(char(3), i.PMCo),'') + 'Project: ' + isnull(i.Project,'') + ' Log Date: ' + isnull(convert(varchar(8),i.LogDate,1),'') + ' Daily Log: ' + isnull(convert(varchar(4), i.DailyLog),''),
   	i.PMCo, 'C','Subcontract Y/N', d.SubcontractYN, i.SubcontractYN, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on d.PMCo=i.PMCo and d.DailyLog=i.DailyLog
   	join bPMCO on i.PMCo=bPMCO.PMCo and bPMCO.AuditDailyLogs='Y'
   	where d.SubcontractYN<>i.SubcontractYN
   
   IF UPDATE(EquipmentYN)
   	insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPMDL',
   	'PM Co#: ' + isnull(convert(char(3), i.PMCo),'') + 'Project: ' + isnull(i.Project,'') + ' Log Date: ' + isnull(convert(varchar(8),i.LogDate,1),'') + ' Daily Log: ' + isnull(convert(varchar(4), i.DailyLog),''),
   	i.PMCo, 'C','Equipment Y/N', d.EquipmentYN, i.EquipmentYN, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on d.PMCo=i.PMCo and d.DailyLog=i.DailyLog
   	join bPMCO on i.PMCo=bPMCO.PMCo and bPMCO.AuditDailyLogs='Y'
   	where d.EquipmentYN<>i.EquipmentYN
   
   IF UPDATE(ActivityYN)
   	insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPMDL',
   	'PM Co#: ' + isnull(convert(char(3), i.PMCo),'') + 'Project: ' + isnull(i.Project,'') + ' Log Date: ' + isnull(convert(varchar(8),i.LogDate,1),'') + ' Daily Log: ' + isnull(convert(varchar(4), i.DailyLog),''),
   	i.PMCo, 'C','Activity YN', d.ActivityYN, i.ActivityYN, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on d.PMCo=i.PMCo and d.DailyLog=i.DailyLog
   	join bPMCO on i.PMCo=bPMCO.PMCo and bPMCO.AuditDailyLogs='Y'
   	where d.ActivityYN<>i.ActivityYN
   
   IF UPDATE(ConversationsYN)
   	insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPMDL',
   	'PM Co#: ' + isnull(convert(char(3), i.PMCo),'') + 'Project: ' + isnull(i.Project,'') + ' Log Date: ' + isnull(convert(varchar(8),i.LogDate,1),'') + ' Daily Log: ' + isnull(convert(varchar(4), i.DailyLog),''),
   	i.PMCo, 'C','Conversations Y/N', d.ConversationsYN, i.ConversationsYN, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on d.PMCo=i.PMCo and d.DailyLog=i.DailyLog
   	join bPMCO on i.PMCo=bPMCO.PMCo and bPMCO.AuditDailyLogs='Y'
   	where d.ConversationsYN<>i.ConversationsYN
   
   IF UPDATE(DeliveriesYN)
   	insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPMDL',
   	'PM Co#: ' + isnull(convert(char(3), i.PMCo),'') + 'Project: ' + isnull(i.Project,'') + ' Log Date: ' + isnull(convert(varchar(8),i.LogDate,1),'') + ' Daily Log: ' + isnull(convert(varchar(4), i.DailyLog),''),
   	i.PMCo, 'C','Deliveries Y/N', d.DeliveriesYN, i.DeliveriesYN, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on d.PMCo=i.PMCo and d.DailyLog=i.DailyLog
   	join bPMCO on i.PMCo=bPMCO.PMCo and bPMCO.AuditDailyLogs='Y'
   	where d.DeliveriesYN<>i.DeliveriesYN
   
   IF UPDATE(AccidentsYN)
   	insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPMDL',
   	'PM Co#: ' + isnull(convert(char(3), i.PMCo),'') + 'Project: ' + isnull(i.Project,'') + ' Log Date: ' + isnull(convert(varchar(8),i.LogDate,1),'') + ' Daily Log: ' + isnull(convert(varchar(4), i.DailyLog),''),
   	i.PMCo, 'C','Accidents Y/N', d.AccidentsYN, i.AccidentsYN, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on d.PMCo=i.PMCo and d.DailyLog=i.DailyLog
   	join bPMCO on i.PMCo=bPMCO.PMCo and bPMCO.AuditDailyLogs='Y'
   	where d.AccidentsYN<>i.AccidentsYN
   
   IF UPDATE(VisitorsYN)
   	insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPMDL',
   	'PM Co#: ' + isnull(convert(char(3), i.PMCo),'') + 'Project: ' + isnull(i.Project,'') + ' Log Date: ' + isnull(convert(varchar(8),i.LogDate,1),'') + ' Daily Log: ' + isnull(convert(varchar(4), i.DailyLog),''),
   	i.PMCo, 'C','Visitors Y/N', d.VisitorsYN, i.VisitorsYN, getdate(), SUSER_SNAME()
   	from inserted i join deleted d on d.PMCo=i.PMCo and d.DailyLog=i.DailyLog
   	join bPMCO on i.PMCo=bPMCO.PMCo and bPMCO.AuditDailyLogs='Y'
   	where d.VisitorsYN<>i.VisitorsYN
   
   
   RETURN 
   
   
   
   
   
  
 



GO
ALTER TABLE [dbo].[bPMDL] ADD CONSTRAINT [PK_bPMDL] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMDL] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPMDL] ON [dbo].[bPMDL] ([PMCo], [Project], [LogDate], [DailyLog]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bPMDL] WITH NOCHECK ADD CONSTRAINT [FK_bPMDL_bJCJM] FOREIGN KEY ([PMCo], [Project]) REFERENCES [dbo].[bJCJM] ([JCCo], [Job])
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPMDL].[EmployeeYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPMDL].[CrewYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPMDL].[SubcontractYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPMDL].[EquipmentYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPMDL].[ActivityYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPMDL].[ConversationsYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPMDL].[DeliveriesYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPMDL].[AccidentsYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPMDL].[VisitorsYN]'
GO
