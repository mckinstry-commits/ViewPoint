CREATE TABLE [dbo].[bJBAR]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[BillNumber] [int] NOT NULL,
[BatchTransType] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[Invoice] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Contract] [dbo].[bContract] NULL,
[CustGroup] [dbo].[bGroup] NOT NULL,
[Customer] [dbo].[bCustomer] NOT NULL,
[RecType] [tinyint] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[ARTrans] [dbo].[bTrans] NULL,
[TransDate] [dbo].[bDate] NOT NULL,
[PayTerms] [dbo].[bPayTerms] NULL,
[DueDate] [dbo].[bDate] NOT NULL,
[DiscDate] [dbo].[bDate] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[oldInvoice] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[oldContract] [dbo].[bContract] NULL,
[oldCustomer] [dbo].[bCustomer] NULL,
[oldRecType] [tinyint] NULL,
[oldDescription] [dbo].[bDesc] NULL,
[oldTransDate] [dbo].[bDate] NULL,
[oldDueDate] [dbo].[bDate] NULL,
[oldDiscDate] [dbo].[bDate] NULL,
[oldPayTerms] [dbo].[bPayTerms] NULL,
[BillMonth] [dbo].[bMonth] NOT NULL,
[RevRelRetgYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJBAR_RevRelRetgYN] DEFAULT ('N'),
[oldNotes] [varchar] (max) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   /****** Object:  Trigger dbo.btJBARd    Script Date: 8/28/99 9:37:01 AM ******/
   
   CREATE trigger [dbo].[btJBARd] ON [dbo].[bJBAR] for DELETE as
   

/*-----------------------------------------------------------------
   *	bJBAR (JB Batch Header)
   *
   *  Created:  bc 11/23/99
   *  Modified: TJL 11/21/02 - Issue #17278, Allow changes to bills in a closed month.
   *
   *----------------------------------------------------------------*/
   declare  @errno int, @numrows int, @errmsg varchar(255), @validcnt int
   
   select @numrows = @@rowcount
   
   if @numrows = 0 return
   set nocount on
   
   begin
   
   update bJBIN
   set InUseBatchId = null, InUseMth = null
   from deleted d
   join bJBIN n on n.JBCo = d.Co and n.BillMonth = d.BillMonth and n.BillNumber = d.BillNumber
   where n.JBCo = d.Co and n.BillMonth = d.BillMonth and n.BillNumber = d.BillNumber
   
   if @@rowcount <> @numrows
   	begin
   	select @errmsg = 'Unable to remove InUse Flag from Bill Number.'
   	goto error
   	end
   
   return
   
   error:
   	SELECT @errmsg = @errmsg + ' - cannot delete JBAR!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   end
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE trigger [dbo].[btJBARi] on [dbo].[bJBAR] for INSERT as
   

/*--------------------------------------------------------------
   *
   *  Update trigger for JBAR
   *  Created By: bc 11/23/99
   *  Modified:  TJL 11/21/02 - Issue #17278, Allow changes to bills in a closed month.
   *
   *--------------------------------------------------------------*/
   
   /***  basic declares for SQL Triggers ****/
   declare @numrows int, @errmsg varchar(255), @validcnt int, @validcnt2 int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   /* validate batch */
   select @validcnt = count(*)
   from bHQBC r
   JOIN inserted i ON i.Co=r.Co and i.Mth=r.Mth and i.BatchId=r.BatchId
   if @validcnt<>@numrows
   	begin
   	select @errmsg = 'Invalid Batch ID#'
   	goto error
   	end
   
   select @validcnt = count(*)
   from bHQBC r
   JOIN inserted i ON i.Co=r.Co and i.Mth=r.Mth and i.BatchId=r.BatchId and not r.BatchId is null
   
   if @validcnt<>@numrows
   	begin
   	select @errmsg = 'Batch (In Use) name must first be updated.'
   	goto error
   	end
   
   select @validcnt = count(*)
   from bHQBC r
   JOIN inserted i ON i.Co=r.Co and i.Mth=r.Mth and i.BatchId=r.BatchId and r.Status=0
   if @validcnt<>@numrows
   	begin
   	select @errmsg = 'Must be an open batch.'
   	goto error
   	end
   
   update bJBIN
   set InUseBatchId = i.BatchId, InUseMth = i.Mth
   from inserted i
   join bJBIN n on n.JBCo = i.Co and n.BillMonth = i.BillMonth and n.BillNumber = i.BillNumber
   where n.JBCo = i.Co and n.BillMonth = i.BillMonth and n.BillNumber = i.BillNumber
   
   select @validcnt = @@rowcount
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Unable to flag Bill Number as (In Use).'
   	goto error
   	end
   
   return
   
   error:
   
   select @errmsg = @errmsg + ' - cannot insert Header Batch'
   
   RAISERROR(@errmsg, 11, -1);
   rollback transaction
   
   
  
 



GO
ALTER TABLE [dbo].[bJBAR] WITH NOCHECK ADD CONSTRAINT [CK_bJBAR_RevRelRetgYN] CHECK (([RevRelRetgYN]='Y' OR [RevRelRetgYN]='N'))
GO
CREATE NONCLUSTERED INDEX [biJBARInvoice] ON [dbo].[bJBAR] ([Co], [Invoice]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biJBAR] ON [dbo].[bJBAR] ([Co], [Mth], [BatchId], [BatchSeq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
