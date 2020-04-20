CREATE TABLE [dbo].[bPMOC]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bJob] NOT NULL,
[DocType] [dbo].[bDocType] NOT NULL,
[Document] [dbo].[bDocument] NOT NULL,
[Seq] [int] NOT NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[SentToFirm] [dbo].[bFirm] NOT NULL,
[SentToContact] [dbo].[bEmployee] NOT NULL,
[Send] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMOC_Send] DEFAULT ('N'),
[PrefMethod] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMOC_PrefMethod] DEFAULT ('N'),
[CC] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMOC_CC] DEFAULT ('N'),
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


/****** Object:  Trigger dbo.btPMOCi    Script Date: 8/28/99 9:37:55 AM ******/
CREATE trigger [dbo].[btPMOCi] on [dbo].[bPMOC] for INSERT as
/*--------------------------------------------------------------
* Insert trigger for PMOC
* Created By:	ScottP 04/30/2013
* Modified By:	
*
*--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on
	
---- validate uniqueness of vendor + firm + contact
IF (SELECT COUNT(*) FROM dbo.bPMOC v JOIN INSERTED i ON
		i.PMCo = v.PMCo AND i.Project = v.Project
		AND i.DocType = v.DocType AND i.Document = v.Document 
		AND i.VendorGroup = v.VendorGroup 
		AND i.SentToFirm = v.SentToFirm AND i.SentToContact = v.SentToContact
		WHERE i.KeyID <> v.KeyID) > 0
	begin
	RAISERROR('Sent To Firm and Contact already exists - cannot insert PMOC', 11, -1)
	ROLLBACK TRANSACTION 
	RETURN
	end
	
RETURN 
   
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/****** Object:  Trigger dbo.btPMOCu    Script Date: 8/28/99 9:37:55 AM ******/
CREATE trigger [dbo].[btPMOCu] on [dbo].[bPMOC] for UPDATE as
/*--------------------------------------------------------------
* Update trigger for PMOC
* Created By:	GF 10/23/2001
* Modified By:	GF 02/20/2008
*				JayR 03/23/2012 Change to use FKs for validation.
*				ScottP 04/30/2013 TFS-42264
*						Add check for duplicate insert based on new index
*
*--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

-- check for changes to PMCo
if update(PMCo)
  begin
  RAISERROR('Cannot change PMCo - cannot update PMOC', 11, -1)
  ROLLBACK TRANSACTION 
  RETURN
  end

-- check for changes to Project
if update(Project)
  begin
  RAISERROR('Cannot change Project - cannot update PMOC', 11, -1)
  ROLLBACK TRANSACTION 
  RETURN
  end

-- check for changes to DocType
if update(DocType)
  begin
  RAISERROR('Cannot change DocType - cannot update PMOC', 11, -1)
  ROLLBACK TRANSACTION 
  RETURN
  end

-- check for changes to Document
if update(Document)
  begin
  RAISERROR('Cannot change Document - cannot update PMOC', 11, -1)
  ROLLBACK TRANSACTION 
  RETURN
  end

---- validate uniqueness of vendor + firm + contact
IF (SELECT COUNT(*) FROM dbo.bPMOC v JOIN INSERTED i ON
		i.PMCo = v.PMCo AND i.Project = v.Project
		AND i.DocType = v.DocType AND i.Document = v.Document 
		AND i.VendorGroup = v.VendorGroup 
		AND i.SentToFirm = v.SentToFirm AND i.SentToContact = v.SentToContact
		WHERE i.KeyID <> v.KeyID) > 0
	begin
	RAISERROR('Sent To Firm and Contact already exists - cannot update PMOC', 11, -1)
	ROLLBACK TRANSACTION 
	RETURN
	end
	
RETURN 
   
GO
ALTER TABLE [dbo].[bPMOC] WITH NOCHECK ADD CONSTRAINT [CK_bPMOC_CC] CHECK (([CC]='C' OR [CC]='B' OR [CC]='N'))
GO
ALTER TABLE [dbo].[bPMOC] WITH NOCHECK ADD CONSTRAINT [CK_bPMOC_Send] CHECK (([Send]='Y' OR [Send]='N'))
GO
ALTER TABLE [dbo].[bPMOC] ADD CONSTRAINT [PK_bPMOC] PRIMARY KEY CLUSTERED  ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_bPMOC_Contact] ON [dbo].[bPMOC] ([PMCo], [Project], [DocType], [Document], [VendorGroup], [SentToFirm], [SentToContact]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bPMOC] WITH NOCHECK ADD CONSTRAINT [FK_bPMOC_bPMDT] FOREIGN KEY ([DocType]) REFERENCES [dbo].[bPMDT] ([DocType])
GO
ALTER TABLE [dbo].[bPMOC] WITH NOCHECK ADD CONSTRAINT [FK_bPMOC_bJCJM] FOREIGN KEY ([PMCo], [Project]) REFERENCES [dbo].[bJCJM] ([JCCo], [Job])
GO
ALTER TABLE [dbo].[bPMOC] WITH NOCHECK ADD CONSTRAINT [FK_bPMOC_bPMOD] FOREIGN KEY ([PMCo], [Project], [DocType], [Document]) REFERENCES [dbo].[bPMOD] ([PMCo], [Project], [DocType], [Document]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[bPMOC] WITH NOCHECK ADD CONSTRAINT [FK_bPMOC_bPMPM] FOREIGN KEY ([VendorGroup], [SentToFirm], [SentToContact]) REFERENCES [dbo].[bPMPM] ([VendorGroup], [FirmNumber], [ContactCode])
GO
ALTER TABLE [dbo].[bPMOC] NOCHECK CONSTRAINT [FK_bPMOC_bPMDT]
GO
ALTER TABLE [dbo].[bPMOC] NOCHECK CONSTRAINT [FK_bPMOC_bJCJM]
GO
ALTER TABLE [dbo].[bPMOC] NOCHECK CONSTRAINT [FK_bPMOC_bPMOD]
GO
ALTER TABLE [dbo].[bPMOC] NOCHECK CONSTRAINT [FK_bPMOC_bPMPM]
GO
