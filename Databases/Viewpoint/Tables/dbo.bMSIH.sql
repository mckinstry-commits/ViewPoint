CREATE TABLE [dbo].[bMSIH]
(
[MSCo] [dbo].[bCompany] NOT NULL,
[MSInv] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[CustGroup] [dbo].[bGroup] NOT NULL,
[Customer] [dbo].[bCustomer] NOT NULL,
[CustJob] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[CustPO] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[Description] [dbo].[bDesc] NULL,
[ShipAddress] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[City] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[State] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[Zip] [varchar] (12) COLLATE Latin1_General_BIN NULL,
[ShipAddress2] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[PaymentType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[RecType] [tinyint] NOT NULL,
[PayTerms] [dbo].[bPayTerms] NULL,
[InvDate] [dbo].[bDate] NOT NULL,
[DiscDate] [dbo].[bDate] NULL,
[DueDate] [dbo].[bDate] NOT NULL,
[ApplyToInv] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[InterCoInv] [dbo].[bYN] NOT NULL,
[LocGroup] [dbo].[bGroup] NULL,
[Location] [dbo].[bLoc] NULL,
[PrintLvl] [tinyint] NOT NULL,
[SubtotalLvl] [tinyint] NOT NULL,
[SepHaul] [dbo].[bYN] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[InUseBatchId] [dbo].[bBatchID] NULL,
[Void] [dbo].[bYN] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[CheckNo] [dbo].[bCMRef] NULL,
[CMCo] [dbo].[bCompany] NULL,
[CMAcct] [dbo].[bCMAcct] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[Country] [char] (2) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biMSIH] ON [dbo].[bMSIH] ([MSCo], [MSInv]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bMSIH] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE  trigger [dbo].[btMSIHd] on [dbo].[bMSIH] for DELETE as
   

/*-----------------------------------------------------------------
    * Created: DAN SO 05/18/09 - Issue: #133441 - Handle Attachment deletion differently
    * Modified: 
    *
    */----------------------------------------------------------------
   declare  @numrows int, @errmsg varchar(255), @rcode int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
      

	-- ISSUE: #133441
	-- Delete attachments if they exist. Make sure UniqueAttchID is not null
	INSERT vDMAttachmentDeletionQueue (AttachmentID, UserName, DeletedFromRecord)
		SELECT AttachmentID, suser_name(), 'Y' 
          FROM bHQAT h join deleted d 
			ON h.UniqueAttchID = d.UniqueAttchID                  
         WHERE d.UniqueAttchID IS NOT NULL  

   
   return
   
   error:
       select @errmsg = @errmsg +  ' - cannot delete Hauler Time Sheet Header!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
  
 



GO

EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSIH].[InterCoInv]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSIH].[SepHaul]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSIH].[Void]'
GO
EXEC sp_bindrule N'[dbo].[brCMAcct]', N'[dbo].[bMSIH].[CMAcct]'
GO
