CREATE TABLE [dbo].[bPMQD]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bJob] NOT NULL,
[PCOType] [dbo].[bDocType] NOT NULL,
[PCO] [dbo].[bPCO] NOT NULL,
[RFQ] [dbo].[bDocument] NOT NULL,
[RFQSeq] [tinyint] NOT NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[SentToFirm] [dbo].[bFirm] NOT NULL,
[SentToContact] [dbo].[bEmployee] NOT NULL,
[DateSent] [dbo].[bDate] NULL,
[DateReqd] [dbo].[bDate] NULL,
[Response] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[DateRecd] [dbo].[bDate] NULL,
[Send] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMQD_Send] DEFAULT ('N'),
[PrefMethod] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMQD_PrefMethod] DEFAULT ('N'),
[CC] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMQD_CC] DEFAULT ('N'),
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
ALTER TABLE [dbo].[bPMQD] ADD 
CONSTRAINT [PK_bPMQD] PRIMARY KEY CLUSTERED  ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
CREATE NONCLUSTERED INDEX [IX_bPMQD_Contact] ON [dbo].[bPMQD] ([PMCo], [Project], [PCOType], [PCO], [RFQ], [VendorGroup], [SentToFirm], [SentToContact]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/****** Object:  Trigger dbo.btPMQDi    Script Date: 8/28/99 9:37:55 AM ******/
CREATE trigger [dbo].[btPMQDi] on [dbo].[bPMQD] for INSERT as
/*--------------------------------------------------------------
* Insert trigger for PMQD
* Created By:	ScottP 04/30/2013
* Modified By:	
*
*--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on
	
---- validate uniqueness of vendor + firm + contact
IF (SELECT COUNT(*) FROM dbo.bPMQD v JOIN INSERTED i ON
		i.PMCo = v.PMCo AND i.Project = v.Project
		AND i.PCOType = v.PCOType AND i.PCO = v.PCO AND i.RFQ = v.RFQ
		AND i.VendorGroup = v.VendorGroup 
		AND i.SentToFirm = v.SentToFirm AND i.SentToContact = v.SentToContact
		WHERE i.KeyID <> v.KeyID) > 0
	begin
	RAISERROR('Sent To Firm and Contact already exists - cannot insert PMQD', 11, -1)
	ROLLBACK TRANSACTION 
	RETURN
	end
	
RETURN 
   
GO

ALTER TABLE [dbo].[bPMQD] WITH NOCHECK ADD
CONSTRAINT [FK_bPMQD_bPMOP] FOREIGN KEY ([PMCo], [Project], [PCOType], [PCO]) REFERENCES [dbo].[bPMOP] ([PMCo], [Project], [PCOType], [PCO]) ON DELETE CASCADE
ALTER TABLE [dbo].[bPMQD] WITH NOCHECK ADD
CONSTRAINT [FK_bPMQD_bPMRQ] FOREIGN KEY ([PMCo], [Project], [PCOType], [PCO], [RFQ]) REFERENCES [dbo].[bPMRQ] ([PMCo], [Project], [PCOType], [PCO], [RFQ]) ON DELETE CASCADE
ALTER TABLE [dbo].[bPMQD] WITH NOCHECK ADD
CONSTRAINT [FK_bPMQD_bPMDT] FOREIGN KEY ([PCOType]) REFERENCES [dbo].[bPMDT] ([DocType])
ALTER TABLE [dbo].[bPMQD] ADD
CONSTRAINT [CK_bPMQD_Send] CHECK (([Send]='Y' OR [Send]='N'))
ALTER TABLE [dbo].[bPMQD] ADD
CONSTRAINT [FK_bPMQD_bJCJM] FOREIGN KEY ([PMCo], [Project]) REFERENCES [dbo].[bJCJM] ([JCCo], [Job])
GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/****** Object:  Trigger dbo.btPMQDu    Script Date: 8/28/99 9:38:00 AM ******/
CREATE trigger [dbo].[btPMQDu] on [dbo].[bPMQD] for UPDATE as
/*--------------------------------------------------------------
* Update trigger for PMQD
* Created By:	LM 1/15/98
* Modified By: JayR 03/26/2012 Switched to using FKs for validation, removed gotos		
*				ScottP 04/30/2013 TFS-42264
*						Add check for duplicate insert based on new index
*
*--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

---- check for changes to PMCo
if update(PMCo)
      begin
      RAISERROR('Cannot change PMCo - cannot update PMQD', 11, -1)
      ROLLBACK TRANSACTION
      RETURN
      end

---- check for changes to Project
   if update(Project)
      begin
      RAISERROR('Cannot change Project - cannot update PMQD', 11, -1)
      ROLLBACK TRANSACTION
      RETURN
      end

---- check for changes to PCOType
   if update(PCOType)
      begin
      RAISERROR('Cannot change PCOType - cannot update PMQD', 11, -1)
      ROLLBACK TRANSACTION
      RETURN
      end

---- check for changes to PCO
   if update(PCO)
      begin
      RAISERROR('Cannot change PCO - cannot update PMQD', 11, -1)
      ROLLBACK TRANSACTION
      RETURN
      end

---- check for changes to RFQ
   if update(RFQ)
      begin
      RAISERROR('Cannot change RFQ - cannot update PMQD', 11, -1)
      ROLLBACK TRANSACTION
      RETURN
      end

---- validate uniqueness of vendor + firm + contact
IF (SELECT COUNT(*) FROM dbo.bPMQD v JOIN INSERTED i ON
		i.PMCo = v.PMCo AND i.Project = v.Project
		AND i.PCOType = v.PCOType AND i.PCO = v.PCO AND i.RFQ = v.RFQ
		AND i.VendorGroup = v.VendorGroup 
		AND i.SentToFirm = v.SentToFirm AND i.SentToContact = v.SentToContact
		WHERE i.KeyID <> v.KeyID) > 0
	begin
	RAISERROR('Sent To Firm and Contact already exists - cannot update PMQD', 11, -1)
	ROLLBACK TRANSACTION 
	RETURN
	end
	

RETURN 
   
   
  
 




GO

ALTER TABLE [dbo].[bPMQD] ADD CONSTRAINT [CK_bPMQD_CC] CHECK (([CC]='C' OR [CC]='B' OR [CC]='N'))
GO

ALTER TABLE [dbo].[bPMQD] WITH NOCHECK ADD CONSTRAINT [FK_bPMQD_bPMFM] FOREIGN KEY ([VendorGroup], [SentToFirm]) REFERENCES [dbo].[bPMFM] ([VendorGroup], [FirmNumber])
GO
ALTER TABLE [dbo].[bPMQD] WITH NOCHECK ADD CONSTRAINT [FK_bPMQD_bPMPM] FOREIGN KEY ([VendorGroup], [SentToFirm], [SentToContact]) REFERENCES [dbo].[bPMPM] ([VendorGroup], [FirmNumber], [ContactCode])
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPMQD].[Send]'
GO
