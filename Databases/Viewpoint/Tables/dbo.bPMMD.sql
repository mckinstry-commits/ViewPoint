CREATE TABLE [dbo].[bPMMD]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bJob] NOT NULL,
[MeetingType] [dbo].[bDocType] NOT NULL,
[Meeting] [int] NOT NULL,
[MinutesType] [tinyint] NOT NULL,
[Seq] [int] NOT NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[FirmNumber] [dbo].[bFirm] NOT NULL,
[ContactCode] [dbo].[bEmployee] NOT NULL,
[PresentYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMMD_PresentYN] DEFAULT ('Y'),
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[CC] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMMD_CC] DEFAULT ('N')
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biPMMD] ON [dbo].[bPMMD] ([PMCo], [Project], [MeetingType], [Meeting], [MinutesType], [VendorGroup], [FirmNumber], [ContactCode]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMMD] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biPMMDSeq] ON [dbo].[bPMMD] ([PMCo], [Project], [MeetingType], [Meeting], [MinutesType], [Seq]) WITH (FILLFACTOR=90) ON [PRIMARY]

ALTER TABLE [dbo].[bPMMD] WITH NOCHECK ADD
CONSTRAINT [FK_bPMMD_bPMMM] FOREIGN KEY ([PMCo], [Project], [MeetingType], [Meeting], [MinutesType]) REFERENCES [dbo].[bPMMM] ([PMCo], [Project], [MeetingType], [Meeting], [MinutesType]) ON DELETE CASCADE
ALTER TABLE [dbo].[bPMMD] WITH NOCHECK ADD
CONSTRAINT [FK_bPMMD_bPMDT] FOREIGN KEY ([MeetingType]) REFERENCES [dbo].[bPMDT] ([DocType])
ALTER TABLE [dbo].[bPMMD] WITH NOCHECK ADD
CONSTRAINT [FK_bPMMD_bPMPM] FOREIGN KEY ([VendorGroup], [FirmNumber], [ContactCode]) REFERENCES [dbo].[bPMPM] ([VendorGroup], [FirmNumber], [ContactCode])
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*************************************/
CREATE trigger [dbo].[btPMMDu] on [dbo].[bPMMD] for UPDATE as
/***  basic declares for SQL Triggers ****/
    /*--------------------------------------------------------------
     *
     *  Update trigger for PMMD
     *  Created By: LM 1/21/98
     *  Modified By:   GF 10/26/2001 - Added Sequence to table
     *					GF 06/26/2009 - issue #134540 remmed out vendor group check
     *
     *
     *--------------------------------------------------------------*/
   if @@rowcount = 0 return
   set nocount on
   
   -- check for changes to PMCo
   if update(PMCo)
       begin
       RAISERROR('Cannot change PMCo - cannot update PMMD', 11, -1)
       ROLLBACK TRANSACTION
       RETURN 
       end
   
   -- check for changes to Project
   if update(Project)
       begin
       RAISERROR('Cannot change Project - cannot update PMMD', 11, -1)
       ROLLBACK TRANSACTION
       RETURN
       end
   
   -- check for changes to MeetingType
   if update(MeetingType)
       begin
       RAISERROR('Cannot change MeetingType - cannot update PMMD', 11, -1)
       ROLLBACK TRANSACTION
       RETURN
       end
   
   -- check for changes to Meeting
   if update(Meeting)
       begin
       RAISERROR('Cannot change Meeting - cannot update PMMD', 11, -1)
       ROLLBACK TRANSACTION
       RETURN
       end
   
   -- check for changes to MinutesType
   if update(MinutesType)
       begin
       RAISERROR('Cannot change MinutesType - cannot update PMMD', 11, -1)
       ROLLBACK TRANSACTION
       RETURN
       end
   
   -- check for changes to sequence
   if update(Seq)
       begin
       RAISERROR('Cannot change sequence - cannot update PMMD', 11, -1)
       ROLLBACK TRANSACTION
       RETURN
       end
   
   RETURN 
   
   
   
   
  
 




GO
ALTER TABLE [dbo].[bPMMD] ADD CONSTRAINT [CK_bPMMD_CC] CHECK (([CC]='C' OR [CC]='B' OR [CC]='N'))
GO

EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPMMD].[PresentYN]'
GO
