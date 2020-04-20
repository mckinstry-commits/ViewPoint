CREATE TABLE [dbo].[bPMPF]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bJob] NOT NULL,
[Seq] [int] NOT NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[FirmNumber] [dbo].[bFirm] NOT NULL,
[ContactCode] [dbo].[bEmployee] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[PortalSiteAccess] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMPF_PortalSiteAccess] DEFAULT ('N'),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[EmailOption] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMPF_EmailOption] DEFAULT ('N')
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMPFd    Script Date: 8/28/99 9:37:58 AM ******/
CREATE  trigger [dbo].[btPMPFd] on [dbo].[bPMPF] for DELETE as
/*--------------------------------------------------------------
 * Delete trigger for PMPF
 * Created By:	LM 12/18/97
 * Modified By:	GF 10/24/2001
 *				GF 01/21/2005 - issue #26894 allow project firm to be deleted even when used in document distributions.
 *				GF 12/13/2006 - 6.x HQMA
 *				JayR 03/26/2012 Remove unused variables
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

---- HQMA inserts
insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bPMPF','PMCo: ' + isnull(convert(varchar(3),d.PMCo), '') + ' Project: ' + isnull(d.Project,'') +
			' Firm: ' + isnull(convert(varchar(8),d.FirmNumber),'') + ' Contact: ' + isnull(convert(varchar(8),d.ContactCode),''),
		d.PMCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from deleted d JOIN bPMCO c ON d.PMCo=c.PMCo
where c.AuditPMPF = 'Y'


RETURN



   
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMPFi    Script Date: 8/28/99 9:37:58 AM ******/
CREATE  trigger [dbo].[btPMPFi] on [dbo].[bPMPF] for INSERT as
/*--------------------------------------------------------------
 * Insert trigger for PMPF
 * Created By:	LM 12/18/97
 * Modified By:	GF 10/24/2001
 *				GF 12/13/2006 - 6.x HQMA
 *				JayR 03/26/2012
 *
 *--------------------------------------------------------------*/
if @@rowcount = 0 return
set nocount on



---- Audit inserts
insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bPMPF', 'PMCo: ' + isnull(convert(varchar(3),i.PMCo),'') + ' Project: ' + isnull(i.Project,'') +
			' Firm: ' + isnull(convert(varchar(8),i.FirmNumber),'') + ' Contact: ' + isnull(convert(varchar(8),i.ContactCode),''),
	i.PMCo, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from inserted i join bPMCO c on c.PMCo = i.PMCo
where i.PMCo = c.PMCo and c.AuditPMPF = 'Y'


RETURN 
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMPFu    Script Date: 8/28/99 9:37:58 AM ******/
CREATE trigger [dbo].[btPMPFu] on [dbo].[bPMPF] for UPDATE as
/*--------------------------------------------------------------
 * Update trigger for PMPF
 * Created By:  LM 12/18/97
 * Modified By:	GF 10/24/2001
 *				GF 12/13/2006 - 6.x HQMA
 *				JayR 3/26/2012 TK-00000 Change to use FKs for validation.
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

---- check for changes to PMCo
if update(PMCo)
      begin
      RAISERROR('Cannot change PMCo - cannot update PMPF', 11, -1)
      ROLLBACK TRANSACTION
      RETURN 
      end

---- check for changes to Project
if update(Project)
      begin
      RAISERROR('Cannot change Project - cannot update PMPF', 11, -1)
      ROLLBACK TRANSACTION
      RETURN 
      end

---- check for changes to VendorGroup
if update(VendorGroup)
      begin
      RAISERROR('Cannot change VendorGroup - cannot update PMPF', 11, -1)
      ROLLBACK TRANSACTION
      RETURN 
      end

---- check seq for changes
if update(Seq)
	begin
	RAISERROR('Cannot change Seq - cannot update PMPF', 11, -1)
	ROLLBACK TRANSACTION
    RETURN 
	end


---- HQMA inserts
if update(Description)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMPF', 'PMCo: ' + convert(varchar(3), i.PMCo) + ' Project: ' + isnull(i.Project,'') +
			' Firm: ' + isnull(convert(varchar(8),i.FirmNumber),'') + ' Contact: ' + isnull(convert(varchar(8),i.ContactCode),''),
		i.PMCo, 'C', 'Description', d.Description, i.Description, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.PMCo=i.PMCo AND d.Project=i.Project and d.Seq=i.Seq
	join bPMCO c ON i.PMCo=c.PMCo
	where isnull(d.Description,'') <> isnull(i.Description,'') and c.AuditPMPF = 'Y'


return

   
   
   
  
 




GO
ALTER TABLE [dbo].[bPMPF] WITH NOCHECK ADD CONSTRAINT [CK_bPMPF_EmailOption] CHECK (([EmailOption]='C' OR [EmailOption]='B' OR [EmailOption]='N'))
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMPF] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biPMPFSeq] ON [dbo].[bPMPF] ([PMCo], [Project], [Seq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPMPF] ON [dbo].[bPMPF] ([PMCo], [Project], [VendorGroup], [FirmNumber], [ContactCode]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bPMPF] WITH NOCHECK ADD CONSTRAINT [FK_bPMPF_bJCJM] FOREIGN KEY ([PMCo], [Project]) REFERENCES [dbo].[bJCJM] ([JCCo], [Job]) ON DELETE CASCADE ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[bPMPF] WITH NOCHECK ADD CONSTRAINT [FK_bPMPF_bPMFM] FOREIGN KEY ([VendorGroup], [FirmNumber]) REFERENCES [dbo].[bPMFM] ([VendorGroup], [FirmNumber])
GO
ALTER TABLE [dbo].[bPMPF] WITH NOCHECK ADD CONSTRAINT [FK_bPMPF_bPMPM] FOREIGN KEY ([VendorGroup], [FirmNumber], [ContactCode]) REFERENCES [dbo].[bPMPM] ([VendorGroup], [FirmNumber], [ContactCode])
GO
