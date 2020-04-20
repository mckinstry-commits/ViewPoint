CREATE TABLE [dbo].[bPMRD]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bJob] NOT NULL,
[RFIType] [dbo].[bDocType] NOT NULL,
[RFI] [dbo].[bDocument] NOT NULL,
[RFISeq] [int] NOT NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[SentToFirm] [dbo].[bFirm] NOT NULL,
[SentToContact] [dbo].[bEmployee] NOT NULL,
[DateSent] [dbo].[bDate] NOT NULL,
[InformationReq] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[DateReqd] [dbo].[bDate] NULL,
[Response] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[DateRecd] [dbo].[bDate] NULL,
[Send] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMRD_Send] DEFAULT ('N'),
[PrefMethod] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMRD_PrefMethod] DEFAULT ('N'),
[CC] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMRD_CC] DEFAULT ('N'),
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
ALTER TABLE [dbo].[bPMRD] ADD 
CONSTRAINT [PK_bPMRD] PRIMARY KEY CLUSTERED  ([PMCo], [Project], [RFIType], [RFI], [RFISeq]) WITH (FILLFACTOR=90) ON [PRIMARY]
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMRD] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

ALTER TABLE [dbo].[bPMRD] WITH NOCHECK ADD
CONSTRAINT [FK_bPMRD_bJCJM] FOREIGN KEY ([PMCo], [Project]) REFERENCES [dbo].[bJCJM] ([JCCo], [Job])
ALTER TABLE [dbo].[bPMRD] WITH NOCHECK ADD
CONSTRAINT [FK_bPMRD_bPMDT] FOREIGN KEY ([RFIType]) REFERENCES [dbo].[bPMDT] ([DocType])
ALTER TABLE [dbo].[bPMRD] WITH NOCHECK ADD
CONSTRAINT [FK_bPMRD_bPMFM] FOREIGN KEY ([VendorGroup], [SentToFirm]) REFERENCES [dbo].[bPMFM] ([VendorGroup], [FirmNumber])
ALTER TABLE [dbo].[bPMRD] WITH NOCHECK ADD
CONSTRAINT [FK_bPMRD_bPMPM] FOREIGN KEY ([VendorGroup], [SentToFirm], [SentToContact]) REFERENCES [dbo].[bPMPM] ([VendorGroup], [FirmNumber], [ContactCode])
ALTER TABLE [dbo].[bPMRD] WITH NOCHECK ADD
CONSTRAINT [FK_bPMRD_bPMRI] FOREIGN KEY ([PMCo], [Project], [RFIType], [RFI]) REFERENCES [dbo].[bPMRI] ([PMCo], [Project], [RFIType], [RFI]) ON DELETE CASCADE
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   /****** Object:  Trigger dbo.btPMRDi    Script Date: 8/28/99 9:38:00 AM ******/
   CREATE   trigger [dbo].[btPMRDi] on [dbo].[bPMRD] for INSERT as
   

/*--------------------------------------------------------------
    * Insert trigger for PMRD
    * Created By:	LM 1/16/98
    * Modified By: GR 8/4/99  - changed the validation for firmnumber and contactcode
    *                            to validate from PMFM and PMPM tables instead of PMPF
    *				JayR 03/26/2012 TK-00000 Change to use FKs for validation.
    *--------------------------------------------------------------*/
   declare @numrows int, @validcnt int
   select @numrows = @@rowcount
   if @@rowcount = 0 return
   set nocount on
   
   
   -- -- -- Validate RFI Type
   select @validcnt = count(*) from bPMDT r JOIN inserted i ON i.RFIType = r.DocType and r.DocCategory = 'RFI'
   if @validcnt <> @numrows
      begin
      RAISERROR('RFI Type is Invalid  - cannot insert into PMRD', 11, -1)
      ROLLBACK TRANSACTION
      RETURN
      end
  
   RETURN 
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
  
   /****** Object:  Trigger dbo.btPMRDu    Script Date: 8/28/99 9:38:00 AM ******/
   CREATE trigger [dbo].[btPMRDu] on [dbo].[bPMRD] for UPDATE as
   

/*--------------------------------------------------------------
    * Update trigger for PMRD
    * Created By:	LM 1/16/98
    * Modified By: GR 8/4/99 -changed the validation for firmnumber and contactcode
    *                          to validate from PMFM and PMPM tables instead of PMPF
    *				JayR 03/26/2012 TK-00000 Change to use FKs for validation.  Remove gotos
    *
    *--------------------------------------------------------------*/

   if @@rowcount = 0 return
   set nocount on
   /* check for changes to PMCo */
   if update(PMCo)
      begin
      RAISERROR('Cannot change PMCo - cannot update PMRD', 11, -1)
      ROLLBACK TRANSACTION
      RETURN 
      end
   /* check for changes to Project */
   if update(Project)
      begin
      RAISERROR('Cannot change Project - cannot update PMRD', 11, -1)
      ROLLBACK TRANSACTION
      RETURN 
      end
   /* check for changes to RFIType */
   if update(RFIType)
      begin
      RAISERROR('Cannot change RFIType - cannot update PMRD', 11, -1)
      ROLLBACK TRANSACTION
      RETURN 
      end
   /* check for changes to RFI */
   if update(RFI)
      begin
      RAISERROR('Cannot change RFI - cannot update PMRD', 11, -1)
      ROLLBACK TRANSACTION
      RETURN 
      end
   /* check for changes to RFISeq */
   if update(RFISeq)
      begin
      RAISERROR('Cannot change RFISeq - cannot update PMRD', 11, -1)
      ROLLBACK TRANSACTION
      RETURN 
      end
   
   RETURN 
   
  
 



GO
ALTER TABLE [dbo].[bPMRD] ADD CONSTRAINT [CK_bPMRD_CC] CHECK (([CC]='C' OR [CC]='B' OR [CC]='N'))
GO

EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPMRD].[Send]'
GO
