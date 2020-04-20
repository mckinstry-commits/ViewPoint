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
ALTER TABLE [dbo].[bPMOC] ADD 
CONSTRAINT [PK_bPMOC] PRIMARY KEY CLUSTERED  ([PMCo], [Project], [DocType], [Document], [Seq]) WITH (FILLFACTOR=90) ON [PRIMARY]
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMOC] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

ALTER TABLE [dbo].[bPMOC] WITH NOCHECK ADD
CONSTRAINT [FK_bPMOC_bJCJM] FOREIGN KEY ([PMCo], [Project]) REFERENCES [dbo].[bJCJM] ([JCCo], [Job])
ALTER TABLE [dbo].[bPMOC] WITH NOCHECK ADD
CONSTRAINT [FK_bPMOC_bPMOD] FOREIGN KEY ([PMCo], [Project], [DocType], [Document]) REFERENCES [dbo].[bPMOD] ([PMCo], [Project], [DocType], [Document]) ON DELETE CASCADE
ALTER TABLE [dbo].[bPMOC] WITH NOCHECK ADD
CONSTRAINT [FK_bPMOC_bPMDT] FOREIGN KEY ([DocType]) REFERENCES [dbo].[bPMDT] ([DocType])
ALTER TABLE [dbo].[bPMOC] WITH NOCHECK ADD
CONSTRAINT [FK_bPMOC_bPMPM] FOREIGN KEY ([VendorGroup], [SentToFirm], [SentToContact]) REFERENCES [dbo].[bPMPM] ([VendorGroup], [FirmNumber], [ContactCode])
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

-- check for changes to Seq
if update(Seq)
  begin
  RAISERROR('Cannot change Seq - cannot update PMOC', 11, -1)
  ROLLBACK TRANSACTION 
  RETURN
  end

RETURN 
   
  
 



GO
ALTER TABLE [dbo].[bPMOC] ADD CONSTRAINT [CK_bPMOC_CC] CHECK (([CC]='C' OR [CC]='B' OR [CC]='N'))
GO

EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPMOC].[Send]'
GO
