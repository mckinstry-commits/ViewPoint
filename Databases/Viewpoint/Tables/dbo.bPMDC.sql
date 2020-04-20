CREATE TABLE [dbo].[bPMDC]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bJob] NOT NULL,
[LogDate] [dbo].[bDate] NOT NULL,
[DailyLog] [smallint] NOT NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[SentToFirm] [dbo].[bFirm] NOT NULL,
[SentToContact] [dbo].[bEmployee] NOT NULL,
[DateSent] [dbo].[bDate] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[CC] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMDC_CC] DEFAULT ('N')
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biPMDC] ON [dbo].[bPMDC] ([PMCo], [Project], [LogDate], [DailyLog], [VendorGroup], [SentToFirm], [SentToContact], [DateSent]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMDC] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

ALTER TABLE [dbo].[bPMDC] WITH NOCHECK ADD
CONSTRAINT [CK_bPMDC_CC] CHECK (([CC]='C' OR [CC]='B' OR [CC]='N'))
ALTER TABLE [dbo].[bPMDC] WITH NOCHECK ADD
CONSTRAINT [FK_bPMDC_bJCJM] FOREIGN KEY ([PMCo], [Project]) REFERENCES [dbo].[bJCJM] ([JCCo], [Job])
ALTER TABLE [dbo].[bPMDC] WITH NOCHECK ADD
CONSTRAINT [FK_bPMDC_bPMDL] FOREIGN KEY ([PMCo], [Project], [LogDate], [DailyLog]) REFERENCES [dbo].[bPMDL] ([PMCo], [Project], [LogDate], [DailyLog])
ALTER TABLE [dbo].[bPMDC] WITH NOCHECK ADD
CONSTRAINT [FK_bPMDC_bPMFM] FOREIGN KEY ([VendorGroup], [SentToFirm]) REFERENCES [dbo].[bPMFM] ([VendorGroup], [FirmNumber])
ALTER TABLE [dbo].[bPMDC] WITH NOCHECK ADD
CONSTRAINT [FK_bPMDC_bPMPM] FOREIGN KEY ([VendorGroup], [SentToFirm], [SentToContact]) REFERENCES [dbo].[bPMPM] ([VendorGroup], [FirmNumber], [ContactCode])
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
   /****** Object:  Trigger dbo.btPMDCu    Script Date: 8/28/99 9:37:50 AM ******/
CREATE  TRIGGER [dbo].[btPMDCu] ON [dbo].[bPMDC]
    FOR UPDATE
AS
   /*--------------------------------------------------------------
    *
    * Update trigger for PMDC
    * Created By:	LM 1/16/98
    * Modified By:	GF 06/26/2009 - issue #134540 remmed out vendor group check
    *				JayR 03/20/2012 - TK-00000 Remove unused variables, cleanup.
    *
    *
    *--------------------------------------------------------------*/
    IF @@rowcount = 0 RETURN
    SET nocount ON
   
   -- check for changes to PMCo
    IF UPDATE(PMCo) 
        BEGIN
            RAISERROR('Cannot change PMCo - cannot update PMDC', 11, -1)
            ROLLBACK TRANSACTION
            RETURN
        END
   
   -- check for changes to Project
    IF UPDATE(Project) 
        BEGIN
            RAISERROR('Cannot change Project - cannot update PMDC', 11, -1)
            ROLLBACK TRANSACTION
            RETURN
        END
   
   -- check for changes to LogDate
    IF UPDATE(LogDate) 
        BEGIN
            RAISERROR('Cannot change Log Date - cannot update PMDC', 11, -1)
            ROLLBACK TRANSACTION
            RETURN
        END
   
   -- check for changes to DailyLog
    IF UPDATE(DailyLog) 
        BEGIN
            RAISERROR('Cannot change Daily Log - cannot update PMDC', 11, -1)
            ROLLBACK TRANSACTION
            RETURN
        END
   
   ---- check for changes to VendorGroup
   --if update(VendorGroup)
   --   begin
   --   select @errmsg = 'Cannot change Vendor Group'
   --   goto error
   --   end
   
   -- check for changes to SentToFirm
    IF UPDATE(SentToFirm) 
        BEGIN
            RAISERROR('Cannot change Sent To Firm - cannot update PMDC', 11, -1)
            ROLLBACK TRANSACTION
            RETURN
        END
   
   -- check for changes to  SentToContact
    IF UPDATE(SentToContact) 
        BEGIN
            RAISERROR('Cannot change Sent To Contact - cannot update PMDC', 11, -1)
            ROLLBACK TRANSACTION
            RETURN
        END
   
   
    RETURN
   
   
  
 



GO
