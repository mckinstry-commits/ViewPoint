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
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
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

-- check for changes to Seq 
IF UPDATE(Seq)
  BEGIN 
	  RAISERROR('Cannot change Seq - cannot update PMCD', 11, -1)
	  ROLLBACK TRANSACTION
	  RETURN
  END 
      	
RETURN


   
  
 



GO
ALTER TABLE [dbo].[bPMCD] ADD CONSTRAINT [CK_bPMCD_CC] CHECK (([CC]='C' OR [CC]='B' OR [CC]='N'))
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMCD] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPMCD] ON [dbo].[bPMCD] ([PMCo], [Project], [PCOType], [PCO], [Seq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bPMCD] WITH NOCHECK ADD CONSTRAINT [FK_bPMCD_bPMDT] FOREIGN KEY ([PCOType]) REFERENCES [dbo].[bPMDT] ([DocType])
GO
ALTER TABLE [dbo].[bPMCD] WITH NOCHECK ADD CONSTRAINT [FK_bPMCD_bJCJM] FOREIGN KEY ([PMCo], [Project]) REFERENCES [dbo].[bJCJM] ([JCCo], [Job])
GO
ALTER TABLE [dbo].[bPMCD] WITH NOCHECK ADD CONSTRAINT [FK_bPMCD_bPMOP] FOREIGN KEY ([PMCo], [Project], [PCOType], [PCO]) REFERENCES [dbo].[bPMOP] ([PMCo], [Project], [PCOType], [PCO]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[bPMCD] WITH NOCHECK ADD CONSTRAINT [FK_bPMCD_bPMPM] FOREIGN KEY ([VendorGroup], [SentToFirm], [SentToContact]) REFERENCES [dbo].[bPMPM] ([VendorGroup], [FirmNumber], [ContactCode])
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPMCD].[Send]'
GO
