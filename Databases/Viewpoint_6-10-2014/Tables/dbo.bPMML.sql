CREATE TABLE [dbo].[bPMML]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bJob] NOT NULL,
[MeetingType] [dbo].[bDocType] NOT NULL,
[Meeting] [int] NOT NULL,
[MinutesType] [tinyint] NOT NULL,
[Item] [int] NOT NULL,
[ItemLine] [tinyint] NOT NULL,
[Description] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[ResponsibleFirm] [dbo].[bFirm] NULL,
[ResponsiblePerson] [dbo].[bEmployee] NULL,
[InitDate] [dbo].[bDate] NULL,
[DueDate] [dbo].[bDate] NULL,
[FinDate] [dbo].[bDate] NULL,
[Status] [dbo].[bStatus] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/***********************************************************/
CREATE  trigger [dbo].[btPMMLd] on [dbo].[bPMML] for DELETE as
/*--------------------------------------------------------------
 * Delete trigger for PMML
 * Created By:	GF 01/11/2006
 * Modified By:	GF 01/15/2007 - 6.x HQMA auditing
 *				JayR 03/23/2012 - TK-00000 Remove unused variables
 *
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

---- HQMA inserts
insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bPMML','PMCo: ' + isnull(convert(char(3),d.PMCo), '') + ' Project: ' + isnull(d.Project,'') + ' MeetingType: '
		+ isnull(d.MeetingType,'') + ' Meeting: ' + isnull(convert(varchar(8),d.Meeting),'') + ' MinutesType: '
		+ isnull(convert(varchar(1),d.MinutesType),'') + ' Item: ' + isnull(convert(varchar(10),d.Item),'')
		+ ' Line: ' + isnull(convert(varchar(3),d.ItemLine),''), d.PMCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from deleted d JOIN bPMCO c ON d.PMCo=c.PMCo
where c.AuditPMMM = 'Y'


RETURN 





GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMMLi    Script Date: 8/28/99 9:37:54 AM ******/
CREATE trigger [dbo].[btPMMLi] on [dbo].[bPMML] for INSERT as
/*--------------------------------------------------------------
 * Insert trigger for PMML
 * Created By:	LM 1/21/98
 * Modified By:	GF 11/04/2004 - issue #25825 changed item to a integer
 *				GF 01/15/2007 - 6.x HQMA auditing
 *				JayR 03/23/2012 - TK-00000 Chnage to use FKs for validation
 *
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on


-- Audit inserts
insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bPMML','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'') + ' MeetingType: '
		+ isnull(i.MeetingType,'') + ' Meeting: ' + isnull(convert(varchar(8),i.Meeting),'') + ' MinutesType: '
		+ isnull(convert(varchar(1),i.MinutesType),'') + ' Item: ' + isnull(convert(varchar(10),i.Item),'')
		+ ' Line: ' + isnull(convert(varchar(3),i.ItemLine),''), i.PMCo, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from inserted i join bPMCO c on c.PMCo = i.PMCo
where i.PMCo = c.PMCo and c.AuditPMMM = 'Y'


RETURN 
   
  
 







GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMMLu    Script Date: 8/28/99 9:37:54 AM ******/
CREATE trigger [dbo].[btPMMLu] on [dbo].[bPMML] for UPDATE as
/*--------------------------------------------------------------
 * Update trigger for PMML
 * Created By:	LM 1/21/98
 * Modified By:	GF 11/04/2004 - issue #25825 changed item to a integer
 *				GF 01/15/2007 - 6.x HQMA auditing
 *
 *
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

---- check for changes to key values
if update(PMCo) or update(Project) or update(MeetingType) or update(Meeting) 
   		or update(MinutesType) or update(Item) or update(ItemLine)
   	begin
   		RAISERROR('Cannot change PMML key fields. - cannot update PMML', 11, -1)
   		ROLLBACK TRANSACTION
   		RETURN
   	end


---- HQMA inserts
if not exists(select top 1 1 from inserted i join bPMCO c with (nolock) on i.PMCo=c.PMCo and c.AuditPMMM='Y')
	begin
  	goto trigger_end
	end

if update(Description)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMML','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'') + ' MeetingType: '
			+ isnull(i.MeetingType,'') + ' Meeting: ' + isnull(convert(varchar(8),i.Meeting),'') + ' MinutesType: '
			+ isnull(convert(varchar(1),i.MinutesType),'') + ' Item: ' + isnull(convert(varchar(10),i.Item),'')
			+ ' Line: ' + isnull(convert(varchar(3),i.ItemLine),''), i.PMCo, 'C',
			'Description', d.Description, i.Description, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.MeetingType=i.MeetingType
	and d.Meeting=i.Meeting and d.MinutesType=i.MinutesType and d.Item=i.Item and d.ItemLine=i.ItemLine
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.Description,'') <> isnull(i.Description,'') and c.AuditPMMM='Y'
	end
if update(Status)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMML','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'') + ' MeetingType: '
			+ isnull(i.MeetingType,'') + ' Meeting: ' + isnull(convert(varchar(8),i.Meeting),'') + ' MinutesType: '
			+ isnull(convert(varchar(1),i.MinutesType),'') + ' Item: ' + isnull(convert(varchar(10),i.Item),'')
			+ ' Line: ' + isnull(convert(varchar(3),i.ItemLine),''), i.PMCo, 'C',
			'Status', d.Status, i.Status, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.MeetingType=i.MeetingType
	and d.Meeting=i.Meeting and d.MinutesType=i.MinutesType and d.Item=i.Item and d.ItemLine=i.ItemLine
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.Status,'') <> isnull(i.Status,'') and c.AuditPMMM='Y'
	end
if update(ResponsibleFirm)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMML','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'') + ' MeetingType: '
			+ isnull(i.MeetingType,'') + ' Meeting: ' + isnull(convert(varchar(8),i.Meeting),'') + ' MinutesType: '
			+ isnull(convert(varchar(1),i.MinutesType),'') + ' Item: ' + isnull(convert(varchar(10),i.Item),'')
			+ ' Line: ' + isnull(convert(varchar(3),i.ItemLine),''), i.PMCo, 'C',
			'ResponsibleFirm', convert(varchar(10),d.ResponsibleFirm), convert(varchar(10),i.ResponsibleFirm), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.MeetingType=i.MeetingType
	and d.Meeting=i.Meeting and d.MinutesType=i.MinutesType and d.Item=i.Item and d.ItemLine=i.ItemLine
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.ResponsibleFirm,'') <> isnull(i.ResponsibleFirm,'') and c.AuditPMMM='Y'
	end
if update(ResponsiblePerson)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMML','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'') + ' MeetingType: '
			+ isnull(i.MeetingType,'') + ' Meeting: ' + isnull(convert(varchar(8),i.Meeting),'') + ' MinutesType: '
			+ isnull(convert(varchar(1),i.MinutesType),'') + ' Item: ' + isnull(convert(varchar(10),i.Item),'')
			+ ' Line: ' + isnull(convert(varchar(3),i.ItemLine),''), i.PMCo, 'C',
			'ResponsiblePerson', convert(varchar(10),d.ResponsiblePerson), convert(varchar(10),i.ResponsiblePerson), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.MeetingType=i.MeetingType
	and d.Meeting=i.Meeting and d.MinutesType=i.MinutesType and d.Item=i.Item and d.ItemLine=i.ItemLine
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.ResponsiblePerson,'') <> isnull(i.ResponsiblePerson,'') and c.AuditPMMM='Y'
	end
if update(InitDate)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMML','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'') + ' MeetingType: '
			+ isnull(i.MeetingType,'') + ' Meeting: ' + isnull(convert(varchar(8),i.Meeting),'') + ' MinutesType: '
			+ isnull(convert(varchar(1),i.MinutesType),'') + ' Item: ' + isnull(convert(varchar(10),i.Item),'')
			+ ' Line: ' + isnull(convert(varchar(3),i.ItemLine),''), i.PMCo, 'C',
			'InitDate', convert(char(8),d.InitDate,1), convert(char(8),i.InitDate,1), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.MeetingType=i.MeetingType
	and d.Meeting=i.Meeting and d.MinutesType=i.MinutesType and d.Item=i.Item and d.ItemLine=i.ItemLine
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.InitDate,'') <> isnull(i.InitDate,'') and c.AuditPMMM='Y'
	end
if update(DueDate)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMML','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'') + ' MeetingType: '
			+ isnull(i.MeetingType,'') + ' Meeting: ' + isnull(convert(varchar(8),i.Meeting),'') + ' MinutesType: '
			+ isnull(convert(varchar(1),i.MinutesType),'') + ' Item: ' + isnull(convert(varchar(10),i.Item),'')
			+ ' Line: ' + isnull(convert(varchar(3),i.ItemLine),''), i.PMCo, 'C',
			'DueDate', convert(char(8),d.DueDate,1), convert(char(8),i.DueDate,1), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.MeetingType=i.MeetingType
	and d.Meeting=i.Meeting and d.MinutesType=i.MinutesType and d.Item=i.Item and d.ItemLine=i.ItemLine
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.DueDate,'') <> isnull(i.DueDate,'') and c.AuditPMMM='Y'
	end
if update(FinDate)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMML','PMCo: ' + isnull(convert(char(3),i.PMCo), '') + ' Project: ' + isnull(i.Project,'') + ' MeetingType: '
			+ isnull(i.MeetingType,'') + ' Meeting: ' + isnull(convert(varchar(8),i.Meeting),'') + ' MinutesType: '
			+ isnull(convert(varchar(1),i.MinutesType),'') + ' Item: ' + isnull(convert(varchar(10),i.Item),'')
			+ ' Line: ' + isnull(convert(varchar(3),i.ItemLine),''), i.PMCo, 'C',
			'FinDate', convert(char(8),d.FinDate,1), convert(char(8),i.FinDate,1), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.MeetingType=i.MeetingType
	and d.Meeting=i.Meeting and d.MinutesType=i.MinutesType and d.Item=i.Item and d.ItemLine=i.ItemLine
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.FinDate,'') <> isnull(i.FinDate,'') and c.AuditPMMM='Y'
	end


trigger_end:

RETURN 
   
  
 






GO
ALTER TABLE [dbo].[bPMML] WITH NOCHECK ADD CONSTRAINT [CK_bPMML_ResponsiblePerson] CHECK (([ResponsiblePerson] IS NULL OR [VendorGroup] IS NOT NULL AND [ResponsibleFirm] IS NOT NULL))
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMML] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPMML] ON [dbo].[bPMML] ([PMCo], [Project], [MeetingType], [Meeting], [MinutesType], [Item], [ItemLine]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bPMML] WITH NOCHECK ADD CONSTRAINT [FK_bPMML_bPMDT] FOREIGN KEY ([MeetingType]) REFERENCES [dbo].[bPMDT] ([DocType])
GO
ALTER TABLE [dbo].[bPMML] WITH NOCHECK ADD CONSTRAINT [FK_bPMML_bPMMI] FOREIGN KEY ([PMCo], [Project], [MeetingType], [Meeting], [MinutesType], [Item]) REFERENCES [dbo].[bPMMI] ([PMCo], [Project], [MeetingType], [Meeting], [MinutesType], [Item])
GO
ALTER TABLE [dbo].[bPMML] WITH NOCHECK ADD CONSTRAINT [FK_bPMML_bPMSC] FOREIGN KEY ([Status]) REFERENCES [dbo].[bPMSC] ([Status])
GO
ALTER TABLE [dbo].[bPMML] WITH NOCHECK ADD CONSTRAINT [FK_bPMML_bPMPM] FOREIGN KEY ([VendorGroup], [ResponsibleFirm], [ResponsiblePerson]) REFERENCES [dbo].[bPMPM] ([VendorGroup], [FirmNumber], [ContactCode])
GO
ALTER TABLE [dbo].[bPMML] NOCHECK CONSTRAINT [FK_bPMML_bPMDT]
GO
ALTER TABLE [dbo].[bPMML] NOCHECK CONSTRAINT [FK_bPMML_bPMMI]
GO
ALTER TABLE [dbo].[bPMML] NOCHECK CONSTRAINT [FK_bPMML_bPMSC]
GO
ALTER TABLE [dbo].[bPMML] NOCHECK CONSTRAINT [FK_bPMML_bPMPM]
GO
