CREATE TABLE [dbo].[bPMDC]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bJob] NOT NULL,
[LogDate] [dbo].[bDate] NOT NULL,
[DailyLog] [smallint] NOT NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[SentToFirm] [dbo].[bFirm] NOT NULL,
[SentToContact] [dbo].[bEmployee] NOT NULL,
[DateSent] [dbo].[bDate] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[CC] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMDC_CC] DEFAULT ('N'),
[Seq] [bigint] NOT NULL,
[Send] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMDC_Send] DEFAULT ('N'),
[PrefMethod] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMDC_PrefMethod] DEFAULT ('M'),
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/****** Object:  Trigger dbo.btPMDCi    Script Date: 8/28/99 9:37:55 AM ******/
CREATE trigger [dbo].[btPMDCi] on [dbo].[bPMDC] for INSERT as
/*--------------------------------------------------------------
* Insert trigger for PMDC
* Created By:	ScottP 05/01/2013
* Modified By:	
*
*--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on
	
 ---- validate uniqueness of vendor + firm + contact
	IF (SELECT COUNT(*) FROM dbo.bPMDC v JOIN INSERTED i ON
		i.PMCo = v.PMCo AND i.Project = v.Project
		AND i.LogDate = v.LogDate AND i.DailyLog = v.DailyLog
		AND i.VendorGroup = v.VendorGroup 
		AND i.SentToFirm = v.SentToFirm AND i.SentToContact = v.SentToContact
		WHERE i.KeyID <> v.KeyID) > 0
	begin
	RAISERROR('Sent To Firm and Contact already exists - cannot insert into PMDC', 11, -1)
	ROLLBACK TRANSACTION 
	RETURN
	end
	
RETURN 
   
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
    *				ScottP 04/30/2013 TFS-42264
	*						Add check for duplicate insert based on new index
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
      
   ---- validate uniqueness of vendor + firm + contact
	IF (SELECT COUNT(*) FROM dbo.bPMDC v JOIN INSERTED i ON
		i.PMCo = v.PMCo AND i.Project = v.Project
		AND i.LogDate = v.LogDate AND i.DailyLog = v.DailyLog
		AND i.VendorGroup = v.VendorGroup 
		AND i.SentToFirm = v.SentToFirm AND i.SentToContact = v.SentToContact
		WHERE i.KeyID <> v.KeyID) > 0
	begin
	RAISERROR('Sent To Firm and Contact already exists - cannot update PMDC', 11, -1)
	ROLLBACK TRANSACTION 
	RETURN
	end
	
    RETURN
    
       
GO
ALTER TABLE [dbo].[bPMDC] WITH NOCHECK ADD CONSTRAINT [CK_bPMDC_CC] CHECK (([CC]='C' OR [CC]='B' OR [CC]='N'))
GO
ALTER TABLE [dbo].[bPMDC] WITH NOCHECK ADD CONSTRAINT [CK_bPMDC_PrefMethod] CHECK (([PrefMethod]='M' OR [PrefMethod]='E' OR [PrefMethod]='F'))
GO
ALTER TABLE [dbo].[bPMDC] WITH NOCHECK ADD CONSTRAINT [CK_bPMDC_Send] CHECK (([Send]='Y' OR [Send]='N'))
GO
ALTER TABLE [dbo].[bPMDC] ADD CONSTRAINT [PK_bPMDC] PRIMARY KEY CLUSTERED  ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_bPMDC_Contact] ON [dbo].[bPMDC] ([PMCo], [Project], [LogDate], [DailyLog], [VendorGroup], [SentToFirm], [SentToContact]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bPMDC] WITH NOCHECK ADD CONSTRAINT [FK_bPMDC_bJCJM] FOREIGN KEY ([PMCo], [Project]) REFERENCES [dbo].[bJCJM] ([JCCo], [Job])
GO
ALTER TABLE [dbo].[bPMDC] WITH NOCHECK ADD CONSTRAINT [FK_bPMDC_bPMDL] FOREIGN KEY ([PMCo], [Project], [LogDate], [DailyLog]) REFERENCES [dbo].[bPMDL] ([PMCo], [Project], [LogDate], [DailyLog])
GO
ALTER TABLE [dbo].[bPMDC] WITH NOCHECK ADD CONSTRAINT [FK_bPMDC_bPMFM] FOREIGN KEY ([VendorGroup], [SentToFirm]) REFERENCES [dbo].[bPMFM] ([VendorGroup], [FirmNumber])
GO
ALTER TABLE [dbo].[bPMDC] WITH NOCHECK ADD CONSTRAINT [FK_bPMDC_bPMPM] FOREIGN KEY ([VendorGroup], [SentToFirm], [SentToContact]) REFERENCES [dbo].[bPMPM] ([VendorGroup], [FirmNumber], [ContactCode])
GO
ALTER TABLE [dbo].[bPMDC] NOCHECK CONSTRAINT [FK_bPMDC_bJCJM]
GO
ALTER TABLE [dbo].[bPMDC] NOCHECK CONSTRAINT [FK_bPMDC_bPMDL]
GO
ALTER TABLE [dbo].[bPMDC] NOCHECK CONSTRAINT [FK_bPMDC_bPMFM]
GO
ALTER TABLE [dbo].[bPMDC] NOCHECK CONSTRAINT [FK_bPMDC_bPMPM]
GO
