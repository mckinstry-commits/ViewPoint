CREATE TABLE [dbo].[bPMCD]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bJob] NOT NULL,
[PCOType] [dbo].[bDocType] NULL,
[PCO] [dbo].[bPCO] NULL,
[Seq] [tinyint] NOT NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[SentToFirm] [dbo].[bFirm] NOT NULL,
[SentToContact] [dbo].[bEmployee] NOT NULL,
[DateSent] [dbo].[bDate] NULL,
[DateReqd] [dbo].[bDate] NULL,
[DateRecd] [dbo].[bDate] NULL,
[Send] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMCD_Send] DEFAULT ('Y'),
[PrefMethod] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMCD_PrefMethod] DEFAULT ('M'),
[CC] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMCD_CC] DEFAULT ('N'),
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
ALTER TABLE [dbo].[bPMCD] ADD 
CONSTRAINT [PK_bPMCD] PRIMARY KEY CLUSTERED  ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
CREATE NONCLUSTERED INDEX [IX_bPMCD_Contact] ON [dbo].[bPMCD] ([PMCo], [Project], [PCOType], [PCO], [VendorGroup], [SentToFirm], [SentToContact]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/****** Object:  Trigger dbo.btPMCDi    Script Date: 8/28/99 9:37:55 AM ******/
CREATE trigger [dbo].[btPMCDi] on [dbo].[bPMCD] for INSERT as
/*--------------------------------------------------------------
* Insert trigger for PMCD
* Created By:	ScottP 04/30/2013
* Modified By:	
*
*--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on
	
---- validate uniqueness of vendor + firm + contact
IF (SELECT COUNT(*) FROM dbo.bPMCD v JOIN INSERTED i ON
		i.PMCo = v.PMCo AND i.Project = v.Project
		AND i.PCOType = v.PCOType AND i.PCO = v.PCO 
		AND i.VendorGroup = v.VendorGroup 
		AND i.SentToFirm = v.SentToFirm AND i.SentToContact = v.SentToContact
		WHERE i.KeyID <> v.KeyID) > 0
	begin
	RAISERROR('Sent To Firm and Contact already exists - cannot insert PMCD', 11, -1)
	ROLLBACK TRANSACTION 
	RETURN
	end
	
RETURN 
   
GO

ALTER TABLE [dbo].[bPMCD] WITH NOCHECK ADD
CONSTRAINT [FK_bPMCD_bPMOP] FOREIGN KEY ([PMCo], [Project], [PCOType], [PCO]) REFERENCES [dbo].[bPMOP] ([PMCo], [Project], [PCOType], [PCO]) ON DELETE CASCADE
ALTER TABLE [dbo].[bPMCD] WITH NOCHECK ADD
CONSTRAINT [FK_bPMCD_bPMDT] FOREIGN KEY ([PCOType]) REFERENCES [dbo].[bPMDT] ([DocType])
ALTER TABLE [dbo].[bPMCD] ADD
CONSTRAINT [CK_bPMCD_Send] CHECK (([Send]='Y' OR [Send]='N'))
ALTER TABLE [dbo].[bPMCD] ADD
CONSTRAINT [FK_bPMCD_bJCJM] FOREIGN KEY ([PMCo], [Project]) REFERENCES [dbo].[bJCJM] ([JCCo], [Job])
GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*********************************/
CREATE trigger [dbo].[btPMCDu] on [dbo].[bPMCD] for UPDATE as
/*--------------------------------------------------------------
* Update trigger for PMCD
* Created By:	LM	01/16/1998
* Modified By:	GF issue #143773 TK-04310
*               JayR 03/20/2012 TJ-00000  Change to use FK for validation
*				ScottP 04/30/2013 TFS-42264
*						Add check for duplicate insert based on new index
*
*--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

-- check for changes to PMCo 
IF UPDATE(PMCo)
  BEGIN 
	  RAISERROR('Cannot change PMCo - cannot update PMCD', 11, -1)
	  ROLLBACK TRANSACTION
	  RETURN 
  end

-- check for changes to Project
IF UPDATE(Project)
  BEGIN
	  RAISERROR('Cannot change Project - cannot update PMCD', 11, -1)
	  ROLLBACK TRANSACTION
	  RETURN
  END

-- check for changes to PCOType 
IF UPDATE(PCOType)
  BEGIN 
	  RAISERROR('Cannot change PCOType - cannot update PMCD', 11, -1)
	  ROLLBACK TRANSACTION
	  RETURN
  END 

-- check for changes to PCO 
IF UPDATE(PCO)
  BEGIN 
	  RAISERROR('Cannot change PCO - cannot update PMCD', 11, -1)
	  ROLLBACK TRANSACTION
	  RETURN
  END 
  
---- validate uniqueness of vendor + firm + contact
IF (SELECT COUNT(*) FROM dbo.bPMCD v JOIN INSERTED i ON
		i.PMCo = v.PMCo AND i.Project = v.Project
		AND i.PCOType = v.PCOType AND i.PCO = v.PCO 
		AND i.VendorGroup = v.VendorGroup 
		AND i.SentToFirm = v.SentToFirm AND i.SentToContact = v.SentToContact
		WHERE i.KeyID <> v.KeyID) > 0
	begin
	RAISERROR('Sent To Firm and Contact already exists - cannot update PMCD', 11, -1)
	ROLLBACK TRANSACTION 
	RETURN
	end
	
RETURN

GO

ALTER TABLE [dbo].[bPMCD] ADD CONSTRAINT [CK_bPMCD_CC] CHECK (([CC]='C' OR [CC]='B' OR [CC]='N'))
GO

ALTER TABLE [dbo].[bPMCD] WITH NOCHECK ADD CONSTRAINT [FK_bPMCD_bPMPM] FOREIGN KEY ([VendorGroup], [SentToFirm], [SentToContact]) REFERENCES [dbo].[bPMPM] ([VendorGroup], [FirmNumber], [ContactCode])
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPMCD].[Send]'
GO
