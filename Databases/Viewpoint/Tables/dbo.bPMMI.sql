CREATE TABLE [dbo].[bPMMI]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bJob] NOT NULL,
[MeetingType] [dbo].[bDocType] NOT NULL,
[Meeting] [int] NOT NULL,
[MinutesType] [tinyint] NOT NULL,
[Item] [int] NOT NULL,
[OriginalItem] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Minutes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[InitFirm] [dbo].[bFirm] NULL,
[Initiator] [dbo].[bEmployee] NULL,
[ResponsibleFirm] [dbo].[bFirm] NULL,
[ResponsiblePerson] [dbo].[bEmployee] NULL,
[InitDate] [dbo].[bDate] NULL,
[DueDate] [dbo].[bDate] NULL,
[FinDate] [dbo].[bDate] NULL,
[Status] [dbo].[bStatus] NULL,
[Issue] [dbo].[bIssue] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[Description] [dbo].[bItemDesc] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biPMMI] ON [dbo].[bPMMI] ([PMCo], [Project], [MeetingType], [Meeting], [MinutesType], [Item]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMMI] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

ALTER TABLE [dbo].[bPMMI] WITH NOCHECK ADD
CONSTRAINT [FK_bPMMI_bJCJM] FOREIGN KEY ([PMCo], [Project]) REFERENCES [dbo].[bJCJM] ([JCCo], [Job])
ALTER TABLE [dbo].[bPMMI] WITH NOCHECK ADD
CONSTRAINT [FK_bPMMI_bPMMM] FOREIGN KEY ([PMCo], [Project], [MeetingType], [Meeting], [MinutesType]) REFERENCES [dbo].[bPMMM] ([PMCo], [Project], [MeetingType], [Meeting], [MinutesType])
ALTER TABLE [dbo].[bPMMI] WITH NOCHECK ADD
CONSTRAINT [FK_bPMMI_bPMDT] FOREIGN KEY ([MeetingType]) REFERENCES [dbo].[bPMDT] ([DocType])
ALTER TABLE [dbo].[bPMMI] WITH NOCHECK ADD
CONSTRAINT [FK_bPMMI_bPMPM_Initiator] FOREIGN KEY ([VendorGroup], [InitFirm], [Initiator]) REFERENCES [dbo].[bPMPM] ([VendorGroup], [FirmNumber], [ContactCode])
ALTER TABLE [dbo].[bPMMI] WITH NOCHECK ADD
CONSTRAINT [FK_bPMMI_bPMPM_ResponsiblePerson] FOREIGN KEY ([VendorGroup], [ResponsibleFirm], [ResponsiblePerson]) REFERENCES [dbo].[bPMPM] ([VendorGroup], [FirmNumber], [ContactCode])
ALTER TABLE [dbo].[bPMMI] WITH NOCHECK ADD
CONSTRAINT [FK_bPMMI_bPMSC] FOREIGN KEY ([Status]) REFERENCES [dbo].[bPMSC] ([Status])
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMMId    Script Date: 8/28/99 9:37:54 AM ******/
CREATE  trigger [dbo].[btPMMId] on [dbo].[bPMMI] for DELETE as
/*--------------------------------------------------------------
 * Delete trigger for PMMI
 * Created By:	LM 1/21/98
 * Modified By:	GF 11/04/2004 - issue #25825 changed item to a integer
 *				GF 01/15/2007 - 6.x HQMA auditing
 *				GF 02/07/2007 - issue #123699 issue history
 *				GF 01/26/2011 - TFS #398
 *				JayR 03/22/2012 - TK-00000 Change to use FK for validation
 *
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on


---- HQMA inserts
insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bPMMI','PMCo: ' + isnull(convert(char(3),d.PMCo), '') + ' Project: ' + isnull(d.Project,'') + ' MeetingType: '
		+ isnull(d.MeetingType,'') + ' Meeting: ' + isnull(convert(varchar(10),d.Meeting),'') + ' MinutesType: '
		+ isnull(convert(varchar(1),d.MinutesType),'') + ' Item: ' + isnull(convert(varchar(10),d.Item),''),
		d.PMCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from deleted d JOIN bPMCO c ON d.PMCo=c.PMCo
where c.AuditPMMM = 'Y'


RETURN 
  
 















GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMMIi    Script Date: 8/28/99 9:37:54 AM ******/
CREATE trigger [dbo].[btPMMIi] on [dbo].[bPMMI] for INSERT as
/*--------------------------------------------------------------
 * Insert trigger for PMMI
 * Created By:	LM 1/21/98
 * Modified By:	GF 10/09/2002 - Changed DBL quotes to single quotes
 *				GF 11/04/2004 - issue #25825 changed item to a integer
 *				GF 01/15/2007 - 6.x HQMA auditing
 *				GF 02/07/2007 - issue #123699 issue history
 *				GF 10/08/2010 - issue #141648
 *				GF 01/26/2011 - TFS #398
 *
 *
 *
 *--------------------------------------------------------------*/
declare @numrows int, @validcnt int
select @numrows = @@rowcount
if @numrows = 0 return
set nocount on


---- Validate MeetingType
select @validcnt = count(*) from bPMDT r JOIN inserted i ON i.MeetingType = r.DocType and r.DocCategory = 'MTG'
if @validcnt <> @numrows
   	begin
   	RAISERROR('Meeting Type is Invalid  - cannot insert into PMMI', 11, -1)
   	ROLLBACK TRANSACTION
   	RETURN
   	end


---- Audit inserts
insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bPMMI','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'') + ' MeetingType: '
		+ isnull(i.MeetingType,'') + ' Meeting: ' + isnull(convert(varchar(8),i.Meeting),'') + ' MinutesType: '
		+ isnull(convert(varchar(1),i.MinutesType),'') + ' Item: ' + isnull(convert(varchar(10),i.Item),''),
		i.PMCo, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from inserted i join bPMCO c on c.PMCo = i.PMCo
where i.PMCo = c.PMCo and c.AuditPMMM = 'Y'


RETURN 
   











GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMMIu    Script Date: 8/28/99 9:37:54 AM ******/
CREATE trigger [dbo].[btPMMIu] on [dbo].[bPMMI] for UPDATE as
/*--------------------------------------------------------------
 * Update trigger for PMMI
 * Created By:	LM 1/21/98
 * Modified By:	GF 10/09/2002 - Changed DBL quotes to single quotes
 *				GF 05/04/2004 - #24518 - when issue is removed need to insert PMIM record for old issue.
 *								Issue cannot be null in PMIM
 *				GF 11/04/2004 - issue #25825 changed item to a integer
 *				GF 01/15/2007 - 6.x HQMA auditing
 *				GF 02/07/2007 - issue #123699 issue history
 *				GF 10/08/2010 - issue #141648
 *				JayR 03/23/2012 - TK-00000 Change to use FK for validation.  Remove some gotos
 *
 *--------------------------------------------------------------*/
declare @numrows int

/************************************************************************************************************************
************************
************************
************************  !!!!!!!!!!!!!!!!  START HERE !!!!!!!!!!!!!!!!!!!!
************************
************************
************************
*************************************************************************************************************************/


if @@rowcount = 0 return
set nocount on

---- check for changes to PMCo
if update(PMCo)
   	begin
   	RAISERROR('Cannot change PMCo - cannot update PMMI', 11, -1)
   	ROLLBACK TRANSACTION
   	RETURN 
   	end

---- check for changes to Project
if update(Project)
   	begin
   	RAISERROR('Cannot change Project - cannot update PMMI', 11, -1)
   	ROLLBACK TRANSACTION
   	RETURN
   	end

---- check for changes to MeetingType
if update(MeetingType)
   	begin
   	RAISERROR('Cannot change MeetingType - cannot update PMMI', 11, -1)
   	ROLLBACK TRANSACTION
   	RETURN
   	end

---- check for changes to Meeting
if update(Meeting)
   	begin
   	RAISERROR('Cannot change Meeting - cannot update PMMI', 11, -1)
   	ROLLBACK TRANSACTION
   	RETURN
   	end

---- check for changes to MinutesType
if update(MinutesType)
   	begin
   	RAISERROR('Cannot change MinutesType - cannot update PMMI', 11, -1)
   	ROLLBACK TRANSACTION
   	RETURN
   	end

---- check for changes to Item
if update(Item)
   	begin
   	RAISERROR('Cannot change Item - cannot update PMMI', 11, -1)
   	ROLLBACK TRANSACTION
   	RETURN
   	end


---- HQMA inserts
if not exists(select top 1 1 from inserted i join bPMCO c with (nolock) on i.PMCo=c.PMCo and c.AuditPMMM='Y')
	begin
  	goto trigger_end
	end

if update(OriginalItem)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMMI','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'') + ' MeetingType: '
			+ isnull(i.MeetingType,'') + ' Meeting: ' + isnull(convert(varchar(8),i.Meeting),'') + ' MinutesType: '
			+ isnull(convert(varchar(1),i.MinutesType),'') + ' Item: ' + isnull(convert(varchar(10),i.Item),'') ,
			i.PMCo, 'C', 'OriginalItem', d.OriginalItem, i.OriginalItem, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.MeetingType=i.MeetingType
	and d.Meeting=i.Meeting and d.MinutesType=i.MinutesType and d.Item=i.Item
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.OriginalItem,'') <> isnull(i.OriginalItem,'') and c.AuditPMMM='Y'
	end
if update(InitFirm)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMMI','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'') + ' MeetingType: '
			+ isnull(i.MeetingType,'') + ' Meeting: ' + isnull(convert(varchar(8),i.Meeting),'') + ' MinutesType: '
			+ isnull(convert(varchar(1),i.MinutesType),'') + ' Item: ' + isnull(convert(varchar(10),i.Item),'') ,
			i.PMCo, 'C', 'InitFirm', convert(varchar(10),d.InitFirm), convert(varchar(10),i.InitFirm), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.MeetingType=i.MeetingType
	and d.Meeting=i.Meeting and d.MinutesType=i.MinutesType and d.Item=i.Item
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.InitFirm,'') <> isnull(i.InitFirm,'') and c.AuditPMMM='Y'
	end
if update(Initiator)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMMI','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'') + ' MeetingType: '
			+ isnull(i.MeetingType,'') + ' Meeting: ' + isnull(convert(varchar(8),i.Meeting),'') + ' MinutesType: '
			+ isnull(convert(varchar(1),i.MinutesType),'') + ' Item: ' + isnull(convert(varchar(10),i.Item),'') ,
			i.PMCo, 'C', 'Initiator', convert(varchar(10),d.Initiator), convert(varchar(10),i.Initiator), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.MeetingType=i.MeetingType
	and d.Meeting=i.Meeting and d.MinutesType=i.MinutesType and d.Item=i.Item
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.Initiator,'') <> isnull(i.Initiator,'') and c.AuditPMMM='Y'
	end
if update(ResponsibleFirm)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMMI','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'') + ' MeetingType: '
			+ isnull(i.MeetingType,'') + ' Meeting: ' + isnull(convert(varchar(8),i.Meeting),'') + ' MinutesType: '
			+ isnull(convert(varchar(1),i.MinutesType),'') + ' Item: ' + isnull(convert(varchar(10),i.Item),'') ,
			i.PMCo, 'C', 'ResponsibleFirm', convert(varchar(10),d.ResponsibleFirm), convert(varchar(10),i.ResponsibleFirm), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.MeetingType=i.MeetingType
	and d.Meeting=i.Meeting and d.MinutesType=i.MinutesType and d.Item=i.Item
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.ResponsibleFirm,'') <> isnull(i.ResponsibleFirm,'') and c.AuditPMMM='Y'
	end
if update(ResponsiblePerson)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMMI','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'') + ' MeetingType: '
			+ isnull(i.MeetingType,'') + ' Meeting: ' + isnull(convert(varchar(8),i.Meeting),'') + ' MinutesType: '
			+ isnull(convert(varchar(1),i.MinutesType),'') + ' Item: ' + isnull(convert(varchar(10),i.Item),'') ,
			i.PMCo, 'C', 'ResponsiblePerson', convert(varchar(10),d.ResponsiblePerson), convert(varchar(10),i.ResponsiblePerson), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.MeetingType=i.MeetingType
	and d.Meeting=i.Meeting and d.MinutesType=i.MinutesType and d.Item=i.Item
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.ResponsiblePerson,'') <> isnull(i.ResponsiblePerson,'') and c.AuditPMMM='Y'
	end
if update(Status)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMMI','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'') + ' MeetingType: '
			+ isnull(i.MeetingType,'') + ' Meeting: ' + isnull(convert(varchar(8),i.Meeting),'') + ' MinutesType: '
			+ isnull(convert(varchar(1),i.MinutesType),'') + ' Item: ' + isnull(convert(varchar(10),i.Item),'') ,
			i.PMCo, 'C', 'Status', d.Status, i.Status, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.MeetingType=i.MeetingType
	and d.Meeting=i.Meeting and d.MinutesType=i.MinutesType and d.Item=i.Item
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.Status,'') <> isnull(i.Status,'') and c.AuditPMMM='Y'
	end
if update(Description)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMMI','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'') + ' MeetingType: '
			+ isnull(i.MeetingType,'') + ' Meeting: ' + isnull(convert(varchar(8),i.Meeting),'') + ' MinutesType: '
			+ isnull(convert(varchar(1),i.MinutesType),'') + ' Item: ' + isnull(convert(varchar(10),i.Item),'') ,
			i.PMCo, 'C', 'Description', d.Description, i.Description, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.MeetingType=i.MeetingType
	and d.Meeting=i.Meeting and d.MinutesType=i.MinutesType and d.Item=i.Item
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.Description,'') <> isnull(i.Description,'') and c.AuditPMMM='Y'
	end
if update(Issue)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMMI','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'') + ' MeetingType: '
			+ isnull(i.MeetingType,'') + ' Meeting: ' + isnull(convert(varchar(8),i.Meeting),'') + ' MinutesType: '
			+ isnull(convert(varchar(1),i.MinutesType),'') + ' Item: ' + isnull(convert(varchar(10),i.Item),'') ,
			i.PMCo, 'C', 'Issue', convert(varchar(10),d.Issue), convert(varchar(10),i.Issue), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.MeetingType=i.MeetingType
	and d.Meeting=i.Meeting and d.MinutesType=i.MinutesType and d.Item=i.Item
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.Issue,'') <> isnull(i.Issue,'') and c.AuditPMMM='Y'
	end
if update(InitDate)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMMI','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'') + ' MeetingType: '
			+ isnull(i.MeetingType,'') + ' Meeting: ' + isnull(convert(varchar(8),i.Meeting),'') + ' MinutesType: '
			+ isnull(convert(varchar(1),i.MinutesType),'') + ' Item: ' + isnull(convert(varchar(10),i.Item),'') ,
			i.PMCo, 'C', 'InitDate', convert(char(8),d.InitDate,1), convert(char(8),i.InitDate,1), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.MeetingType=i.MeetingType
	and d.Meeting=i.Meeting and d.MinutesType=i.MinutesType and d.Item=i.Item
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.InitDate,'') <> isnull(i.InitDate,'') and c.AuditPMMM='Y'
	end
if update(DueDate)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMMI','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'') + ' MeetingType: '
			+ isnull(i.MeetingType,'') + ' Meeting: ' + isnull(convert(varchar(8),i.Meeting),'') + ' MinutesType: '
			+ isnull(convert(varchar(1),i.MinutesType),'') + ' Item: ' + isnull(convert(varchar(10),i.Item),'') ,
			i.PMCo, 'C', 'DueDate', convert(char(8),d.DueDate,1), convert(char(8),i.DueDate,1), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.MeetingType=i.MeetingType
	and d.Meeting=i.Meeting and d.MinutesType=i.MinutesType and d.Item=i.Item
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.DueDate,'') <> isnull(i.DueDate,'') and c.AuditPMMM='Y'
	end
if update(FinDate)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMMI','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'') + ' MeetingType: '
			+ isnull(i.MeetingType,'') + ' Meeting: ' + isnull(convert(varchar(8),i.Meeting),'') + ' MinutesType: '
			+ isnull(convert(varchar(1),i.MinutesType),'') + ' Item: ' + isnull(convert(varchar(10),i.Item),'') ,
			i.PMCo, 'C', 'FinDate', convert(char(8),d.FinDate,1), convert(char(8),i.FinDate,1), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.MeetingType=i.MeetingType
	and d.Meeting=i.Meeting and d.MinutesType=i.MinutesType and d.Item=i.Item
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.FinDate,'') <> isnull(i.FinDate,'') and c.AuditPMMM='Y'
	end

trigger_end:

RETURN 
   
   
  
 
















GO
ALTER TABLE [dbo].[bPMMI] WITH NOCHECK ADD CONSTRAINT [CK_bPMMI_Initiator] CHECK (([Initiator] IS NULL OR [VendorGroup] IS NOT NULL AND [InitFirm] IS NOT NULL))
GO
ALTER TABLE [dbo].[bPMMI] WITH NOCHECK ADD CONSTRAINT [CK_bPMMI_ResponsiblePerson] CHECK (([ResponsiblePerson] IS NULL OR [VendorGroup] IS NOT NULL AND [ResponsibleFirm] IS NOT NULL))
GO
