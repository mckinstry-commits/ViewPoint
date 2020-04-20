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
[DateSent] [dbo].[bDate] NOT NULL,
[DateReqd] [dbo].[bDate] NULL,
[Response] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[DateRecd] [dbo].[bDate] NULL,
[Send] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMQD_Send] DEFAULT ('N'),
[PrefMethod] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMQD_PrefMethod] DEFAULT ('N'),
[CC] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMQD_CC] DEFAULT ('N'),
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
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

---- check for changes to RFQSeq
   if update(RFQSeq)
      begin
      RAISERROR('Cannot change RFQSeq - cannot update PMQD', 11, -1)
      ROLLBACK TRANSACTION
      RETURN
      end


RETURN 
   
   
  
 



GO
ALTER TABLE [dbo].[bPMQD] ADD CONSTRAINT [CK_bPMQD_CC] CHECK (([CC]='C' OR [CC]='B' OR [CC]='N'))
GO
ALTER TABLE [dbo].[bPMQD] ADD CONSTRAINT [PK_bPMQD] PRIMARY KEY CLUSTERED  ([PMCo], [Project], [PCOType], [PCO], [RFQ], [RFQSeq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMQD] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bPMQD] WITH NOCHECK ADD CONSTRAINT [FK_bPMQD_bPMDT] FOREIGN KEY ([PCOType]) REFERENCES [dbo].[bPMDT] ([DocType])
GO
ALTER TABLE [dbo].[bPMQD] WITH NOCHECK ADD CONSTRAINT [FK_bPMQD_bJCJM] FOREIGN KEY ([PMCo], [Project]) REFERENCES [dbo].[bJCJM] ([JCCo], [Job])
GO
ALTER TABLE [dbo].[bPMQD] WITH NOCHECK ADD CONSTRAINT [FK_bPMQD_bPMOP] FOREIGN KEY ([PMCo], [Project], [PCOType], [PCO]) REFERENCES [dbo].[bPMOP] ([PMCo], [Project], [PCOType], [PCO]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[bPMQD] WITH NOCHECK ADD CONSTRAINT [FK_bPMQD_bPMRQ] FOREIGN KEY ([PMCo], [Project], [PCOType], [PCO], [RFQ]) REFERENCES [dbo].[bPMRQ] ([PMCo], [Project], [PCOType], [PCO], [RFQ]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[bPMQD] WITH NOCHECK ADD CONSTRAINT [FK_bPMQD_bPMFM] FOREIGN KEY ([VendorGroup], [SentToFirm]) REFERENCES [dbo].[bPMFM] ([VendorGroup], [FirmNumber])
GO
ALTER TABLE [dbo].[bPMQD] WITH NOCHECK ADD CONSTRAINT [FK_bPMQD_bPMPM] FOREIGN KEY ([VendorGroup], [SentToFirm], [SentToContact]) REFERENCES [dbo].[bPMPM] ([VendorGroup], [FirmNumber], [ContactCode])
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPMQD].[Send]'
GO
