CREATE TABLE [dbo].[bMSWH]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[HaulVendor] [dbo].[bVendor] NOT NULL,
[APRef] [dbo].[bAPReference] NOT NULL,
[InvDate] [dbo].[bDate] NOT NULL,
[InvDescription] [dbo].[bDesc] NULL,
[PayTerms] [dbo].[bPayTerms] NULL,
[DueDate] [dbo].[bDate] NOT NULL,
[HoldCode] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[PayControl] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[CMCo] [dbo].[bCompany] NULL,
[CMAcct] [dbo].[bCMAcct] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[APTrans] [dbo].[bTrans] NULL,
[APCo] [dbo].[bCompany] NOT NULL,
[SalesTypeRstrct] [varchar] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bMSWH_SalesTypeRstrct] DEFAULT ('N'),
[CustGroup] [dbo].[bGroup] NULL,
[Customer] [dbo].[bCustomer] NULL,
[CustJob] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[JCCo] [dbo].[bCompany] NULL,
[Job] [dbo].[bJob] NULL,
[INCo] [dbo].[bCompany] NULL,
[ToLoc] [dbo].[bLoc] NULL,
[PayCategory] [int] NULL,
[PayType] [tinyint] NULL,
[DiscDate] [dbo].[bDate] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE   trigger [dbo].[btMSWHd] on [dbo].[bMSWH] for DELETE as
   

/*-----------------------------------------------------------------
    * Created By:  GG 01/10/01
    * Modified By:
    *
    *	Check for MS Hauler Worksheet Detail
    *
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   -- check for Worksheet Detail
   if exists(select 1 from bMSWD w with (Nolock) join deleted d on w.Co = d.Co and w.Mth = d.Mth
       and w.BatchId = d.BatchId and w.BatchSeq = d.BatchSeq)
       begin
       select @errmsg = 'Worksheet Detail exists'
       goto error
       end
   
   return
   
   
   error:
   	select @errmsg = @errmsg + ' - cannot delete MS Hauler Worksheet Header!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE    trigger [dbo].[btMSWHi] on [dbo].[bMSWH] for INSERT as
   

/*--------------------------------------------------------------
    * Created By: GG 01/10/01
    * Modified By: GF 07/29/2003 - issue #21933 speed improvements
    *
    * Insert trigger bMSWH - Hauler Worksheet Header
    *
    * Performs validation on critical columns.
    *
    *--------------------------------------------------------------*/
   declare @numrows int, @errmsg varchar(255), @validcnt int, @nullcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   -- validate batch
   select @validcnt = count(*) from bHQBC r with (Nolock) 
   JOIN inserted i ON i.Co = r.Co and i.Mth = r.Mth and i.BatchId = r.BatchId
   if @validcnt<>@numrows
   	begin
   	select @errmsg = 'Invalid Batch ID#'
   	goto error
   	end
   
   select @validcnt = count(*) from bHQBC r with (Nolock) 
   JOIN inserted i ON i.Co = r.Co and i.Mth = r.Mth and i.BatchId = r.BatchId and r.Status = 0
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Must be an open batch'
   	goto error
   	end
   
   --validate Haul Vendor
   select @validcnt = count(*) from bAPVM v with (Nolock) 
   join inserted i on v.VendorGroup = i.VendorGroup and v.Vendor = i.HaulVendor
   where v. ActiveYN = 'Y'
   if @validcnt <> @numrows
       begin
       select @errmsg = 'Invalid or inactive Haul Vendor'
       goto error
       end
   
   --validate Payment Terms, may be null
   select @nullcnt = count(*) from inserted where PayTerms is null
   select @validcnt = count(*) from bHQPT p with (Nolock) join inserted i on p.PayTerms = i.PayTerms
   if @nullcnt + @validcnt <> @numrows
       begin
       select @errmsg = 'Invalid Payment Terms'
       goto error
       end
   
   --validate Hold Code, may be null
   select @nullcnt = count(*) from inserted where HoldCode is null
   select @validcnt = count(*) from bHQHC h with (Nolock) join inserted i on h.HoldCode = i.HoldCode
   if @nullcnt + @validcnt <> @numrows
       begin
       select @errmsg = 'Invalid Hold Code'
       goto error
       end
   
   return
   
   
   
   error:
      select @errmsg = @errmsg + ' - cannot insert MS Hauler Worksheet Header'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE  trigger [dbo].[btMSWHu] on [dbo].[bMSWH] for UPDATE as
   

/*-----------------------------------------------------------------
    * Created:  GG 01/10/01
    * Modified:
    *
    * Update trigger for bMSWH (Hauler Worksheet Header)
    *
    * Cannot change Company, Mth, BatchId, or Seq
    *
    *----------------------------------------------------------------*/
   declare @numrows int, @validcount int, @errmsg varchar(255)
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   
   -- check for key changes
   select @validcount = count(*)
   from deleted d join inserted i on d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId
       and d.BatchSeq = i.BatchSeq
   if @numrows <> @validcount
   	begin
   	select @errmsg = 'Cannot change Company, Month, Batch ID #, or Sequence #'
   	goto error
   	end
   
   -- limit changes if Worksheet Detail exists
   if update(VendorGroup) or update(HaulVendor)
       begin
       if exists(select 1 from bMSWD d with (Nolock) join inserted i on d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId)
           begin
           select @errmsg = 'Cannot change Haul Vendor when Worksheet Detail exists'
           goto error
           end
       end
   
   
   
   return
   
   
   
   error:
   	select @errmsg = @errmsg + ' - cannot update MS Hauler Worksheet Header!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biMSWH] ON [dbo].[bMSWH] ([Co], [Mth], [BatchId], [BatchSeq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bMSWH] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brCMAcct]', N'[dbo].[bMSWH].[CMAcct]'
GO
