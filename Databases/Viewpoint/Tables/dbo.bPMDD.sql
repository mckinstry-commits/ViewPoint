CREATE TABLE [dbo].[bPMDD]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bJob] NOT NULL,
[LogDate] [dbo].[bDate] NOT NULL,
[DailyLog] [smallint] NOT NULL,
[LogType] [tinyint] NOT NULL,
[Seq] [smallint] NOT NULL,
[PRCo] [dbo].[bCompany] NULL,
[Crew] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[FirmNumber] [dbo].[bFirm] NULL,
[ContactCode] [dbo].[bEmployee] NULL,
[Equipment] [dbo].[bEquip] NULL,
[Visitor] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Description] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[ArriveTime] [smalldatetime] NULL,
[DepartTime] [smalldatetime] NULL,
[CatStatus] [char] (1) COLLATE Latin1_General_BIN NULL,
[Supervisor] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[Foreman] [tinyint] NULL,
[Journeymen] [tinyint] NULL,
[Apprentices] [tinyint] NULL,
[PhaseGroup] [dbo].[bGroup] NULL,
[Phase] [dbo].[bPhase] NULL,
[PO] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[Material] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[Quantity] [int] NULL,
[Location] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Issue] [dbo].[bIssue] NULL,
[DelTicket] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[CreatedChangedBy] [dbo].[bVPUserName] NULL,
[MatlGroup] [dbo].[bGroup] NULL,
[UM] [dbo].[bUM] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[EMCo] [dbo].[bCompany] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biPMDD] ON [dbo].[bPMDD] ([PMCo], [Project], [LogDate], [DailyLog], [LogType], [Seq]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMDD] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

ALTER TABLE [dbo].[bPMDD] WITH NOCHECK ADD
CONSTRAINT [FK_bPMDD_bPMPL] FOREIGN KEY ([PMCo], [Project], [Location]) REFERENCES [dbo].[bPMPL] ([PMCo], [Project], [Location])
ALTER TABLE [dbo].[bPMDD] WITH NOCHECK ADD
CONSTRAINT [FK_bPMDD_bPMDL] FOREIGN KEY ([PMCo], [Project], [LogDate], [DailyLog]) REFERENCES [dbo].[bPMDL] ([PMCo], [Project], [LogDate], [DailyLog])
ALTER TABLE [dbo].[bPMDD] WITH NOCHECK ADD
CONSTRAINT [FK_bPMDD_bPMFM] FOREIGN KEY ([VendorGroup], [FirmNumber]) REFERENCES [dbo].[bPMFM] ([VendorGroup], [FirmNumber])
ALTER TABLE [dbo].[bPMDD] WITH NOCHECK ADD
CONSTRAINT [FK_bPMDD_bPMPM] FOREIGN KEY ([VendorGroup], [FirmNumber], [ContactCode]) REFERENCES [dbo].[bPMPM] ([VendorGroup], [FirmNumber], [ContactCode])
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMDLd    Script Date: 8/28/99 9:37:50 AM ******/
CREATE TRIGGER [dbo].[btPMDDd] ON [dbo].[bPMDD]
    FOR DELETE
AS
    /*--------------------------------------------------------------
 * Delete trigger for PMDD
 * Created By: GF 01/17/2002
 * Modified By:	GF 02/01/2007 - issue #123699
 *				GF 01/26/2011 - tfs #398
 *				JayR 03/20/2012 TK-00000 Cleanup unused variables.  
 *
 *--------------------------------------------------------------*/

    IF @@rowcount = 0 
        RETURN
    SET nocount ON


---- Audit PM Daily Log deletions
    INSERT  INTO bHQMA
            ( TableName ,
              KeyString ,
              Co ,
              RecType ,
              FieldName ,
              OldValue ,
              NewValue ,
              DateTime ,
              UserName
            )
            SELECT  'bPMDD' ,
                    'PMCo ' + ISNULL(CONVERT(CHAR(3), d.PMCo), '')
                    + ' Project: ' + ISNULL(d.Project, '') + ' Log Date: '
                    + ISNULL(CONVERT(VARCHAR(8), d.LogDate, 1), '')
                    + ' Daily Log: ' + ISNULL(CONVERT(VARCHAR(10), d.DailyLog),
                                              '') + ' Log Type: '
                    + ISNULL(CONVERT(VARCHAR(1), d.LogType), '') ,
                    d.PMCo ,
                    'D' ,
                    NULL ,
                    NULL ,
                    NULL ,
                    GETDATE() ,
                    SUSER_SNAME()
            FROM    deleted d
                    JOIN bPMCO c WITH ( NOLOCK ) ON d.PMCo = c.PMCo
            WHERE   c.AuditDailyLogs = 'Y'

    RETURN
   
  
 






GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMDDi    Script Date: 8/28/99 9:37:50 AM ******/
CREATE trigger [dbo].[btPMDDi] on [dbo].[bPMDD] for INSERT as
/*--------------------------------------------------------------
 *  Insert trigger for PMDD
 *  Created By:  SE 1/14/98
 *  Modified By: RM 03/15/01 - Updates issue history on when adding an issue to Activities tab,
 *                     Conversations tab, Accidents tab and visitors tab
 *				GF 01/17/2002 - Added auditing
 *				GG 09/20/02 - #18522 ANSI nulls
 *				GF 07/02/2003 - trigger will not work as is for bulk insert. Need cursor.
 *				GF 02/01/2007 - issue #123699 issue history
 *				GF 10/08/2010 - issue #141648
 *				GF 01/26/2011 - tfs #398
 *				JayR 03/20/2012 TK-00000 Cleanup unused variables
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

---- update CreatedChangedBy to User_Name
update bPMDD set CreatedChangedBy=user_name()
from bPMDD d join inserted i on i.PMCo=d.PMCo and i.Project=d.Project
and i.LogDate=d.LogDate and i.DailyLog=d.DailyLog and i.Seq=d.Seq

---- Audit inserts
insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bPMDD', 'PMCo: ' + isnull(convert(char(3), i.PMCo),'') + 'Project: ' + isnull(i.Project,'') + ' Log Date: ' + isnull(convert(varchar(8),i.LogDate,1),'') + ' Daily Log: ' + isnull(convert(varchar(10), i.DailyLog),'') + ' Log Type: ' + isnull(convert(varchar(1),i.LogType),''),
		i.PMCo, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from inserted i join bPMCO c on c.PMCo = i.PMCo
where i.PMCo = c.PMCo and c.AuditDailyLogs = 'Y'


RETURN
   
  
 













GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
/****** Object:  Trigger dbo.btPMDLu    Script Date: 8/28/99 9:37:50 AM ******/
CREATE TRIGGER [dbo].[btPMDDu] ON [dbo].[bPMDD] FOR UPDATE AS
/*--------------------------------------------------------------
 *
 * Update trigger for PMDD
 * Created By:	GF 01/17/2002
 * Modified By: GF 07/01/2003 - issue #20652 - added audit for EMCo
 *				GF 05/23/2007 - issue #124659 - added issue history update when changed for log type
 *				GF 10/08/2010 - issue #141648
 *				JayR 03/20/2012 Cleanup unused variables and goto statements
 *--------------------------------------------------------------*/

IF @@rowcount = 0 RETURN
SET nocount ON

---- check for changes to PMCo
IF UPDATE(PMCo) 
    BEGIN
        RAISERROR('Cannot change PM Company - cannot update PMDD', 11, -1)
        ROLLBACK TRANSACTION
        RETURN 
    END

---- check for changes to Project
IF UPDATE(Project) 
    BEGIN
        RAISERROR('Cannot change Project - cannot update PMDD', 11, -1)
        ROLLBACK TRANSACTION
        RETURN 
    END

---- check for changes to LogDate
IF UPDATE(LogDate) 
    BEGIN
        RAISERROR('Cannot change Log Date - cannot update PMDD', 11, -1)
        ROLLBACK TRANSACTION
        RETURN 
    END

---- check for changes to DailyLog
IF UPDATE(DailyLog) 
    BEGIN
        RAISERROR('Cannot change Daily Log  - cannot update PMDD', 11, -1)
        ROLLBACK TRANSACTION
        RETURN 
    END

---- Insert records into HQMA for changes made to audited fields
IF UPDATE(PRCo)
   	INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bPMDD', 'PM Co#: ' + ISNULL(CONVERT(CHAR(3), i.PMCo),'') + 'Project: ' + ISNULL(i.Project,'') + ' Log Date: ' + ISNULL(CONVERT(VARCHAR(8),i.LogDate,1),'') + ' Daily Log: ' + ISNULL(CONVERT(VARCHAR(4), i.DailyLog),'') + ' Log Type: ' + ISNULL(CONVERT(VARCHAR(1),i.LogType),''),
   	i.PMCo, 'C','PR CO#', CONVERT(VARCHAR(3),ISNULL(d.PRCo,0)), CONVERT(VARCHAR(3),ISNULL(i.PRCo,0)), GETDATE(), SUSER_SNAME()
   	FROM inserted i JOIN deleted d ON d.PMCo=i.PMCo AND d.DailyLog=i.DailyLog
   	JOIN bPMCO WITH (NOLOCK) ON i.PMCo=bPMCO.PMCo AND bPMCO.AuditDailyLogs='Y'
   	WHERE ISNULL(d.PRCo,0)<>ISNULL(i.PRCo,0)
   
   IF UPDATE(Crew)
   	INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bPMDD', 'PM Co#: ' + ISNULL(CONVERT(CHAR(3), i.PMCo),'') + 'Project: ' + ISNULL(i.Project,'') + ' Log Date: ' + ISNULL(CONVERT(VARCHAR(8),i.LogDate,1),'') + ' Daily Log: ' + ISNULL(CONVERT(VARCHAR(4), i.DailyLog),'') + ' Log Type: ' + ISNULL(CONVERT(VARCHAR(1),i.LogType),''),
   	i.PMCo, 'C','Crew', d.Crew, i.Crew, GETDATE(), SUSER_SNAME()
   	FROM inserted i JOIN deleted d ON d.PMCo=i.PMCo AND d.DailyLog=i.DailyLog
   	JOIN bPMCO WITH (NOLOCK) ON i.PMCo=bPMCO.PMCo AND bPMCO.AuditDailyLogs='Y'
   	WHERE ISNULL(d.Crew,'')<>ISNULL(i.Crew,'')
   
   IF UPDATE(VendorGroup)
   	INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bPMDD', 'PM Co#: ' + ISNULL(CONVERT(CHAR(3), i.PMCo),'') + 'Project: ' + ISNULL(i.Project,'') + ' Log Date: ' + ISNULL(CONVERT(VARCHAR(8),i.LogDate,1),'') + ' Daily Log: ' + ISNULL(CONVERT(VARCHAR(4), i.DailyLog),'') + ' Log Type: ' + ISNULL(CONVERT(VARCHAR(1),i.LogType),''),
   	i.PMCo, 'C','VendorGroup', CONVERT(VARCHAR(3),d.VendorGroup), CONVERT(VARCHAR(3),i.VendorGroup), GETDATE(), SUSER_SNAME()
   	FROM inserted i JOIN deleted d ON d.PMCo=i.PMCo AND d.DailyLog=i.DailyLog
   	JOIN bPMCO WITH (NOLOCK) ON i.PMCo=bPMCO.PMCo AND bPMCO.AuditDailyLogs='Y'
   	WHERE ISNULL(d.VendorGroup,0)<>ISNULL(i.VendorGroup,0)
   
   IF UPDATE(FirmNumber)
   	INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bPMDD', 'PM Co#: ' + ISNULL(CONVERT(CHAR(3), i.PMCo),'') + 'Project: ' + ISNULL(i.Project,'') + ' Log Date: ' + ISNULL(CONVERT(VARCHAR(8),i.LogDate,1),'') + ' Daily Log: ' + ISNULL(CONVERT(VARCHAR(4), i.DailyLog),'') + ' Log Type: ' + ISNULL(CONVERT(VARCHAR(1),i.LogType),''),
   	i.PMCo, 'C','FirmNumber', CONVERT(VARCHAR(8),d.FirmNumber), CONVERT(VARCHAR(8),i.FirmNumber), GETDATE(), SUSER_SNAME()
   	FROM inserted i JOIN deleted d ON d.PMCo=i.PMCo AND d.DailyLog=i.DailyLog
   	JOIN bPMCO WITH (NOLOCK) ON i.PMCo=bPMCO.PMCo AND bPMCO.AuditDailyLogs='Y'
   	WHERE ISNULL(d.FirmNumber,0)<>ISNULL(i.FirmNumber,0)
   
   IF UPDATE(ContactCode)
   	INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bPMDD', 'PM Co#: ' + ISNULL(CONVERT(CHAR(3), i.PMCo),'') + 'Project: ' + ISNULL(i.Project,'') + ' Log Date: ' + ISNULL(CONVERT(VARCHAR(8),i.LogDate,1),'') + ' Daily Log: ' + ISNULL(CONVERT(VARCHAR(4), i.DailyLog),'') + ' Log Type: ' + ISNULL(CONVERT(VARCHAR(1),i.LogType),''),
   	i.PMCo, 'C','ContactCode', CONVERT(VARCHAR(8),d.ContactCode), CONVERT(VARCHAR(8),i.ContactCode), GETDATE(), SUSER_SNAME()
   	FROM inserted i JOIN deleted d ON d.PMCo=i.PMCo AND d.DailyLog=i.DailyLog
   	JOIN bPMCO WITH (NOLOCK) ON i.PMCo=bPMCO.PMCo AND bPMCO.AuditDailyLogs='Y'
   	WHERE ISNULL(d.ContactCode,0)<>ISNULL(i.ContactCode,0)
   
   IF UPDATE(EMCo)
   	INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bPMDD', 'PM Co#: ' + ISNULL(CONVERT(CHAR(3), i.PMCo),'') + 'Project: ' + ISNULL(i.Project,'') + ' Log Date: ' + ISNULL(CONVERT(VARCHAR(8),i.LogDate,1),'') + ' Daily Log: ' + ISNULL(CONVERT(VARCHAR(4), i.DailyLog),'') + ' Log Type: ' + ISNULL(CONVERT(VARCHAR(1),i.LogType),''),
   	i.PMCo, 'C','EM CO#', CONVERT(VARCHAR(3),ISNULL(d.EMCo,0)), CONVERT(VARCHAR(3),ISNULL(i.EMCo,0)), GETDATE(), SUSER_SNAME()
   	FROM inserted i JOIN deleted d ON d.PMCo=i.PMCo AND d.DailyLog=i.DailyLog
   	JOIN bPMCO WITH (NOLOCK) ON i.PMCo=bPMCO.PMCo AND bPMCO.AuditDailyLogs='Y'
   	WHERE ISNULL(d.EMCo,0)<>ISNULL(i.EMCo,0)
   
   IF UPDATE(Equipment)
   	INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bPMDD', 'PM Co#: ' + ISNULL(CONVERT(CHAR(3), i.PMCo),'') + 'Project: ' + ISNULL(i.Project,'') + ' Log Date: ' + ISNULL(CONVERT(VARCHAR(8),i.LogDate,1),'') + ' Daily Log: ' + ISNULL(CONVERT(VARCHAR(4), i.DailyLog),'') + ' Log Type: ' + ISNULL(CONVERT(VARCHAR(1),i.LogType),''),
   	i.PMCo, 'C','Equipment', d.Equipment, i.Equipment, GETDATE(), SUSER_SNAME()
   	FROM inserted i JOIN deleted d ON d.PMCo=i.PMCo AND d.DailyLog=i.DailyLog
   	JOIN bPMCO WITH (NOLOCK) ON i.PMCo=bPMCO.PMCo AND bPMCO.AuditDailyLogs='Y'
   	WHERE ISNULL(d.Equipment,'')<>ISNULL(i.Equipment,'')
   
   IF UPDATE(Visitor)
   	INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bPMDD',
   	'PM Co#: ' + ISNULL(CONVERT(CHAR(3), i.PMCo),'') + 'Project: ' + ISNULL(i.Project,'') + ' Log Date: ' + ISNULL(CONVERT(VARCHAR(8),i.LogDate,1),'') + ' Daily Log: ' + ISNULL(CONVERT(VARCHAR(4), i.DailyLog),'') + ' Log Type: ' + ISNULL(CONVERT(VARCHAR(1),i.LogType),''),
   	i.PMCo, 'C','Visitor', d.Visitor, i.Visitor, GETDATE(), SUSER_SNAME()
   	FROM inserted i JOIN deleted d ON d.PMCo=i.PMCo AND d.DailyLog=i.DailyLog
   	JOIN bPMCO WITH (NOLOCK) ON i.PMCo=bPMCO.PMCo AND bPMCO.AuditDailyLogs='Y'
   	WHERE ISNULL(d.Visitor,'')<>ISNULL(i.Visitor,'')
   
   IF UPDATE(ArriveTime)
   	INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bPMDD', 'PM Co#: ' + ISNULL(CONVERT(CHAR(3), i.PMCo),'') + 'Project: ' + ISNULL(i.Project,'') + ' Log Date: ' + ISNULL(CONVERT(VARCHAR(8),i.LogDate,1),'') + ' Daily Log: ' + ISNULL(CONVERT(VARCHAR(4), i.DailyLog),'') + ' Log Type: ' + ISNULL(CONVERT(VARCHAR(1),i.LogType),''),
   	i.PMCo, 'C','Arrive Time', CONVERT(VARCHAR(20),d.ArriveTime), CONVERT(VARCHAR(20),i.ArriveTime), GETDATE(), SUSER_SNAME()
   	FROM inserted i JOIN deleted d ON d.PMCo=i.PMCo AND d.DailyLog=i.DailyLog
   	JOIN bPMCO WITH (NOLOCK) ON i.PMCo=bPMCO.PMCo AND bPMCO.AuditDailyLogs='Y'
   	WHERE ISNULL(d.ArriveTime,0)<>ISNULL(i.ArriveTime,0)
   
   IF UPDATE(DepartTime)
   	INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bPMDD', 'PM Co#: ' + ISNULL(CONVERT(CHAR(3), i.PMCo),'') + 'Project: ' + ISNULL(i.Project,'') + ' Log Date: ' + ISNULL(CONVERT(VARCHAR(8),i.LogDate,1),'') + ' Daily Log: ' + ISNULL(CONVERT(VARCHAR(4), i.DailyLog),'') + ' Log Type: ' + ISNULL(CONVERT(VARCHAR(1),i.LogType),''),
   	i.PMCo, 'C','Depart Time', CONVERT(VARCHAR(20),d.DepartTime), CONVERT(VARCHAR(20),i.DepartTime), GETDATE(), SUSER_SNAME()
   	FROM inserted i JOIN deleted d ON d.PMCo=i.PMCo AND d.DailyLog=i.DailyLog
   	JOIN bPMCO WITH (NOLOCK) ON i.PMCo=bPMCO.PMCo AND bPMCO.AuditDailyLogs='Y'
   	WHERE ISNULL(d.DepartTime,0)<>ISNULL(i.DepartTime,0)
   
   IF UPDATE(CatStatus)
   	INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bPMDD', 'PM Co#: ' + ISNULL(CONVERT(CHAR(3), i.PMCo),'') + 'Project: ' + ISNULL(i.Project,'') + ' Log Date: ' + ISNULL(CONVERT(VARCHAR(8),i.LogDate,1),'') + ' Daily Log: ' + ISNULL(CONVERT(VARCHAR(4), i.DailyLog),'') + ' Log Type: ' + ISNULL(CONVERT(VARCHAR(1),i.LogType),''),
   	i.PMCo, 'C','Category Status', d.CatStatus, i.CatStatus, GETDATE(), SUSER_SNAME()
   	FROM inserted i JOIN deleted d ON d.PMCo=i.PMCo AND d.DailyLog=i.DailyLog
   	JOIN bPMCO WITH (NOLOCK) ON i.PMCo=bPMCO.PMCo AND bPMCO.AuditDailyLogs='Y'
   	WHERE ISNULL(d.CatStatus,'')<>ISNULL(i.CatStatus,'')
   
   IF UPDATE(Supervisor)
   	INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bPMDD', 'PM Co#: ' + ISNULL(CONVERT(CHAR(3), i.PMCo),'') + 'Project: ' + ISNULL(i.Project,'') + ' Log Date: ' + ISNULL(CONVERT(VARCHAR(8),i.LogDate,1),'') + ' Daily Log: ' + ISNULL(CONVERT(VARCHAR(4), i.DailyLog),'') + ' Log Type: ' + ISNULL(CONVERT(VARCHAR(1),i.LogType),''),
   	i.PMCo, 'C','Supervisor', d.Supervisor, i.Supervisor, GETDATE(), SUSER_SNAME()
   	FROM inserted i JOIN deleted d ON d.PMCo=i.PMCo AND d.DailyLog=i.DailyLog
   	JOIN bPMCO WITH (NOLOCK) ON i.PMCo=bPMCO.PMCo AND bPMCO.AuditDailyLogs='Y'
   	WHERE ISNULL(d.Supervisor,'')<>ISNULL(i.Supervisor,'')
   
   IF UPDATE(Foreman)
   	INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bPMDD', 'PM Co#: ' + ISNULL(CONVERT(CHAR(3), i.PMCo),'') + 'Project: ' + ISNULL(i.Project,'') + ' Log Date: ' + ISNULL(CONVERT(VARCHAR(8),i.LogDate,1),'') + ' Daily Log: ' + ISNULL(CONVERT(VARCHAR(4), i.DailyLog),'') + ' Log Type: ' + ISNULL(CONVERT(VARCHAR(1),i.LogType),''),
   	i.PMCo, 'C','Foreman', CONVERT(VARCHAR(4),d.Foreman), CONVERT(VARCHAR(4),i.Foreman), GETDATE(), SUSER_SNAME()
   	FROM inserted i JOIN deleted d ON d.PMCo=i.PMCo AND d.DailyLog=i.DailyLog
   	JOIN bPMCO WITH (NOLOCK) ON i.PMCo=bPMCO.PMCo AND bPMCO.AuditDailyLogs='Y'
   	WHERE ISNULL(d.Foreman,0)<>ISNULL(i.Foreman,0)
   
   IF UPDATE(Journeymen)
   	INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bPMDD', 'PM Co#: ' + ISNULL(CONVERT(CHAR(3), i.PMCo),'') + 'Project: ' + ISNULL(i.Project,'') + ' Log Date: ' + ISNULL(CONVERT(VARCHAR(8),i.LogDate,1),'') + ' Daily Log: ' + ISNULL(CONVERT(VARCHAR(4), i.DailyLog),'') + ' Log Type: ' + ISNULL(CONVERT(VARCHAR(1),i.LogType),''),
   	i.PMCo, 'C','Journeymen', CONVERT(VARCHAR(4),d.Journeymen), CONVERT(VARCHAR(4),i.Journeymen), GETDATE(), SUSER_SNAME()
   	FROM inserted i JOIN deleted d ON d.PMCo=i.PMCo AND d.DailyLog=i.DailyLog
   	JOIN bPMCO WITH (NOLOCK) ON i.PMCo=bPMCO.PMCo AND bPMCO.AuditDailyLogs='Y'
   	WHERE ISNULL(d.Journeymen,0)<>ISNULL(i.Journeymen,0)
   
   IF UPDATE(Apprentices)
   	INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bPMDD', 'PM Co#: ' + ISNULL(CONVERT(CHAR(3), i.PMCo),'') + 'Project: ' + ISNULL(i.Project,'') + ' Log Date: ' + ISNULL(CONVERT(VARCHAR(8),i.LogDate,1),'') + ' Daily Log: ' + ISNULL(CONVERT(VARCHAR(4), i.DailyLog),'') + ' Log Type: ' + ISNULL(CONVERT(VARCHAR(1),i.LogType),''),
   	i.PMCo, 'C','Apprentices', CONVERT(VARCHAR(4),d.Apprentices), CONVERT(VARCHAR(4),i.Apprentices), GETDATE(), SUSER_SNAME()
   	FROM inserted i JOIN deleted d ON d.PMCo=i.PMCo AND d.DailyLog=i.DailyLog
   	JOIN bPMCO WITH (NOLOCK) ON i.PMCo=bPMCO.PMCo AND bPMCO.AuditDailyLogs='Y'
   	WHERE ISNULL(d.Apprentices,0)<>ISNULL(i.Apprentices,0)
   
   IF UPDATE(PhaseGroup)
   	INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bPMDD', 'PM Co#: ' + ISNULL(CONVERT(CHAR(3), i.PMCo),'') + 'Project: ' + ISNULL(i.Project,'') + ' Log Date: ' + ISNULL(CONVERT(VARCHAR(8),i.LogDate,1),'') + ' Daily Log: ' + ISNULL(CONVERT(VARCHAR(4), i.DailyLog),'') + ' Log Type: ' + ISNULL(CONVERT(VARCHAR(1),i.LogType),''),
   	i.PMCo, 'C','PhaseGroup', CONVERT(VARCHAR(3),d.PhaseGroup), CONVERT(VARCHAR(3),i.PhaseGroup), GETDATE(), SUSER_SNAME()
   	FROM inserted i JOIN deleted d ON d.PMCo=i.PMCo AND d.DailyLog=i.DailyLog
   	JOIN bPMCO WITH (NOLOCK) ON i.PMCo=bPMCO.PMCo AND bPMCO.AuditDailyLogs='Y'
   	WHERE ISNULL(d.PhaseGroup,0)<>ISNULL(i.PhaseGroup,0)
   
   IF UPDATE(Phase)
   	INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bPMDD', 'PM Co#: ' + ISNULL(CONVERT(CHAR(3), i.PMCo),'') + 'Project: ' + ISNULL(i.Project,'') + ' Log Date: ' + ISNULL(CONVERT(VARCHAR(8),i.LogDate,1),'') + ' Daily Log: ' + ISNULL(CONVERT(VARCHAR(4), i.DailyLog),'') + ' Log Type: ' + ISNULL(CONVERT(VARCHAR(1),i.LogType),''),
   	i.PMCo, 'C','Phase', d.Phase, i.Phase, GETDATE(), SUSER_SNAME()
   	FROM inserted i JOIN deleted d ON d.PMCo=i.PMCo AND d.DailyLog=i.DailyLog
   	JOIN bPMCO WITH (NOLOCK) ON i.PMCo=bPMCO.PMCo AND bPMCO.AuditDailyLogs='Y'
   	WHERE ISNULL(d.Phase,'')<>ISNULL(i.Phase,'')
   
   IF UPDATE(PO)
   	INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bPMDD', 'PM Co#: ' + ISNULL(CONVERT(CHAR(3), i.PMCo),'') + 'Project: ' + ISNULL(i.Project,'') + ' Log Date: ' + ISNULL(CONVERT(VARCHAR(8),i.LogDate,1),'') + ' Daily Log: ' + ISNULL(CONVERT(VARCHAR(4), i.DailyLog),'') + ' Log Type: ' + ISNULL(CONVERT(VARCHAR(1),i.LogType),''),
   	i.PMCo, 'C','PO', d.PO, i.PO, GETDATE(), SUSER_SNAME()
   	FROM inserted i JOIN deleted d ON d.PMCo=i.PMCo AND d.DailyLog=i.DailyLog
   	JOIN bPMCO WITH (NOLOCK) ON i.PMCo=bPMCO.PMCo AND bPMCO.AuditDailyLogs='Y'
   	WHERE ISNULL(d.PO,'')<>ISNULL(i.PO,'')
   
   IF UPDATE(Material)
   	INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bPMDD', 'PM Co#: ' + ISNULL(CONVERT(CHAR(3), i.PMCo),'') + 'Project: ' + ISNULL(i.Project,'') + ' Log Date: ' + ISNULL(CONVERT(VARCHAR(8),i.LogDate,1),'') + ' Daily Log: ' + ISNULL(CONVERT(VARCHAR(4), i.DailyLog),'') + ' Log Type: ' + ISNULL(CONVERT(VARCHAR(1),i.LogType),''),
   	i.PMCo, 'C','Material', d.Material, i.Material, GETDATE(), SUSER_SNAME()
   	FROM inserted i JOIN deleted d ON d.PMCo=i.PMCo AND d.DailyLog=i.DailyLog
   	JOIN bPMCO WITH (NOLOCK) ON i.PMCo=bPMCO.PMCo AND bPMCO.AuditDailyLogs='Y'
   	WHERE ISNULL(d.Material,'')<>ISNULL(i.Material,'')
   
   IF UPDATE(Quantity)
   	INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bPMDD', 'PM Co#: ' + ISNULL(CONVERT(CHAR(3), i.PMCo),'') + 'Project: ' + ISNULL(i.Project,'') + ' Log Date: ' + ISNULL(CONVERT(VARCHAR(8),i.LogDate,1),'') + ' Daily Log: ' + ISNULL(CONVERT(VARCHAR(4), i.DailyLog),'') + ' Log Type: ' + ISNULL(CONVERT(VARCHAR(1),i.LogType),''),
   	i.PMCo, 'C','Quantity', CONVERT(VARCHAR(12),d.Quantity), CONVERT(VARCHAR(12),i.Quantity), GETDATE(), SUSER_SNAME()
   	FROM inserted i JOIN deleted d ON d.PMCo=i.PMCo AND d.DailyLog=i.DailyLog
   	JOIN bPMCO WITH (NOLOCK) ON i.PMCo=bPMCO.PMCo AND bPMCO.AuditDailyLogs='Y'
   	WHERE ISNULL(d.Quantity,0)<>ISNULL(i.Quantity,0)
   
   IF UPDATE(Location)
   	INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bPMDD', 'PM Co#: ' + ISNULL(CONVERT(CHAR(3), i.PMCo),'') + 'Project: ' + ISNULL(i.Project,'') + ' Log Date: ' + ISNULL(CONVERT(VARCHAR(8),i.LogDate,1),'') + ' Daily Log: ' + ISNULL(CONVERT(VARCHAR(4), i.DailyLog),'') + ' Log Type: ' + ISNULL(CONVERT(VARCHAR(1),i.LogType),''),
   	i.PMCo, 'C','Location', d.Location, i.Location, GETDATE(), SUSER_SNAME()
   	FROM inserted i JOIN deleted d ON d.PMCo=i.PMCo AND d.DailyLog=i.DailyLog
   	JOIN bPMCO WITH (NOLOCK) ON i.PMCo=bPMCO.PMCo AND bPMCO.AuditDailyLogs='Y'
   	WHERE ISNULL(d.Location,'')<>ISNULL(i.Location,'')
   
   IF UPDATE(Issue)
   	INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bPMDD', 'PM Co#: ' + ISNULL(CONVERT(CHAR(3), i.PMCo),'') + 'Project: ' + ISNULL(i.Project,'') + ' Log Date: ' + ISNULL(CONVERT(VARCHAR(8),i.LogDate,1),'') + ' Daily Log: ' + ISNULL(CONVERT(VARCHAR(4), i.DailyLog),'') + ' Log Type: ' + ISNULL(CONVERT(VARCHAR(1),i.LogType),''),
   	i.PMCo, 'C','Issue', CONVERT(VARCHAR(8),d.Issue), CONVERT(VARCHAR(8),i.Issue), GETDATE(), SUSER_SNAME()
   	FROM inserted i JOIN deleted d ON d.PMCo=i.PMCo AND d.DailyLog=i.DailyLog
   	JOIN bPMCO WITH (NOLOCK) ON i.PMCo=bPMCO.PMCo AND bPMCO.AuditDailyLogs='Y'
   	WHERE ISNULL(d.Issue,0)<>ISNULL(i.Issue,0)
   
   IF UPDATE(DelTicket)
   	INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bPMDD', 'PM Co#: ' + ISNULL(CONVERT(CHAR(3), i.PMCo),'') + 'Project: ' + ISNULL(i.Project,'') + ' Log Date: ' + ISNULL(CONVERT(VARCHAR(8),i.LogDate,1),'') + ' Daily Log: ' + ISNULL(CONVERT(VARCHAR(4), i.DailyLog),'') + ' Log Type: ' + ISNULL(CONVERT(VARCHAR(1),i.LogType),''),
   	i.PMCo, 'C','Del Ticket', d.DelTicket, i.DelTicket, GETDATE(), SUSER_SNAME()
   	FROM inserted i JOIN deleted d ON d.PMCo=i.PMCo AND d.DailyLog=i.DailyLog
   	JOIN bPMCO WITH (NOLOCK) ON i.PMCo=bPMCO.PMCo AND bPMCO.AuditDailyLogs='Y'
   	WHERE ISNULL(d.DelTicket,'')<>ISNULL(i.DelTicket,'')
   
   IF UPDATE(CreatedChangedBy)
   	INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bPMDD', 'PM Co#: ' + ISNULL(CONVERT(CHAR(3), i.PMCo),'') + 'Project: ' + ISNULL(i.Project,'') + ' Log Date: ' + ISNULL(CONVERT(VARCHAR(8),i.LogDate,1),'') + ' Daily Log: ' + ISNULL(CONVERT(VARCHAR(4), i.DailyLog),'') + ' Log Type: ' + ISNULL(CONVERT(VARCHAR(1),i.LogType),''),
   	i.PMCo, 'C','Created-Changed By', d.CreatedChangedBy, i.CreatedChangedBy, GETDATE(), SUSER_SNAME()
   	FROM inserted i JOIN deleted d ON d.PMCo=i.PMCo AND d.DailyLog=i.DailyLog
   	JOIN bPMCO WITH (NOLOCK) ON i.PMCo=bPMCO.PMCo AND bPMCO.AuditDailyLogs='Y'
   	WHERE ISNULL(d.CreatedChangedBy,'')<>ISNULL(i.CreatedChangedBy,'')
   
   IF UPDATE(MatlGroup)
   	INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bPMDD', 'PM Co#: ' + ISNULL(CONVERT(CHAR(3), i.PMCo),'') + 'Project: ' + ISNULL(i.Project,'') + ' Log Date: ' + ISNULL(CONVERT(VARCHAR(8),i.LogDate,1),'') + ' Daily Log: ' + ISNULL(CONVERT(VARCHAR(4), i.DailyLog),'') + ' Log Type: ' + ISNULL(CONVERT(VARCHAR(1),i.LogType),''),
   	i.PMCo, 'C','Material Group', CONVERT(VARCHAR(3),d.MatlGroup), CONVERT(VARCHAR(3),i.MatlGroup), GETDATE(), SUSER_SNAME()
   	FROM inserted i JOIN deleted d ON d.PMCo=i.PMCo AND d.DailyLog=i.DailyLog
   	JOIN bPMCO WITH (NOLOCK) ON i.PMCo=bPMCO.PMCo AND bPMCO.AuditDailyLogs='Y'
   	WHERE ISNULL(d.MatlGroup,0)<>ISNULL(i.MatlGroup,0)
   
   IF UPDATE(UM)
   	INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bPMDD', 'PM Co#: ' + ISNULL(CONVERT(CHAR(3), i.PMCo),'') + 'Project: ' + ISNULL(i.Project,'') + ' Log Date: ' + ISNULL(CONVERT(VARCHAR(8),i.LogDate,1),'') + ' Daily Log: ' + ISNULL(CONVERT(VARCHAR(4), i.DailyLog),'') + ' Log Type: ' + ISNULL(CONVERT(VARCHAR(1),i.LogType),''),
   	i.PMCo, 'C','UM', d.UM, i.UM, GETDATE(), SUSER_SNAME()
   	FROM inserted i JOIN deleted d ON d.PMCo=i.PMCo AND d.DailyLog=i.DailyLog
   	JOIN bPMCO WITH (NOLOCK) ON i.PMCo=bPMCO.PMCo AND bPMCO.AuditDailyLogs='Y'
   	WHERE ISNULL(d.UM,'')<>ISNULL(i.UM,'')



RETURN

   
  
 



GO
