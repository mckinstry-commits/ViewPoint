CREATE TABLE [dbo].[bPMTC]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bJob] NOT NULL,
[Transmittal] [dbo].[bDocument] NOT NULL,
[Seq] [int] NOT NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[SentToFirm] [dbo].[bFirm] NOT NULL,
[SentToContact] [dbo].[bEmployee] NOT NULL,
[Send] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMTC_Send] DEFAULT ('N'),
[PrefMethod] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMTC_PrefMethod] DEFAULT ('N'),
[CC] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMTC_CC] DEFAULT ('N'),
[DateSent] [dbo].[bDate] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMTCu    Script Date: 8/28/99 9:38:02 AM ******/
CREATE trigger [dbo].[btPMTCu] on [dbo].[bPMTC] for UPDATE as
/*--------------------------------------------------------------
 *
 *  Update trigger for PMTC
 *  Created By: LM 1/16/98
 *  Modified By:    GF 10/23/2001
 *					JayR 03/28/2012 TK-00000 Remove unused variables, switch to FKs for validation
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

---- check for changes to PMCo
   if update(PMCo)
      begin
      RAISERROR('Cannot change PMCo - cannot update PMTC', 11, -1)
      ROLLBACK TRANSACTION
      RETURN
      end

---- check for changes to Project
   if update(Project)
      begin
      RAISERROR('Cannot change Project - cannot update PMTC', 11, -1)
      ROLLBACK TRANSACTION
      RETURN
      end

---- check for changes to Transmittal
   if update(Transmittal)
      begin
      RAISERROR('Cannot change Transmittal - cannot update PMTC', 11, -1)
      ROLLBACK TRANSACTION
      RETURN
      end

---- check for changes to Seq
   if update(Seq)
      begin
      RAISERROR('Cannot change Seq - cannot update PMTC', 11, -1)
      ROLLBACK TRANSACTION
      RETURN
      end

RETURN 
  
 



GO
ALTER TABLE [dbo].[bPMTC] ADD CONSTRAINT [CK_bPMTC_CC] CHECK (([CC]='C' OR [CC]='B' OR [CC]='N'))
GO
ALTER TABLE [dbo].[bPMTC] ADD CONSTRAINT [PK_bPMTC] PRIMARY KEY CLUSTERED  ([PMCo], [Project], [Transmittal], [Seq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMTC] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bPMTC] WITH NOCHECK ADD CONSTRAINT [FK_bPMTC_bJCJM] FOREIGN KEY ([PMCo], [Project]) REFERENCES [dbo].[bJCJM] ([JCCo], [Job])
GO
ALTER TABLE [dbo].[bPMTC] WITH NOCHECK ADD CONSTRAINT [FK_bPMTC_bPMTM] FOREIGN KEY ([PMCo], [Project], [Transmittal]) REFERENCES [dbo].[bPMTM] ([PMCo], [Project], [Transmittal]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[bPMTC] WITH NOCHECK ADD CONSTRAINT [FK_bPMTC_bPMFM] FOREIGN KEY ([VendorGroup], [SentToFirm]) REFERENCES [dbo].[bPMFM] ([VendorGroup], [FirmNumber])
GO
ALTER TABLE [dbo].[bPMTC] WITH NOCHECK ADD CONSTRAINT [FK_bPMTC_bPMPM] FOREIGN KEY ([VendorGroup], [SentToFirm], [SentToContact]) REFERENCES [dbo].[bPMPM] ([VendorGroup], [FirmNumber], [ContactCode])
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPMTC].[Send]'
GO
