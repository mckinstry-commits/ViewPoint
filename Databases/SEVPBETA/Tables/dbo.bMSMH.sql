CREATE TABLE [dbo].[bMSMH]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[MatlVendor] [dbo].[bVendor] NOT NULL,
[APRef] [dbo].[bAPReference] NOT NULL,
[InvDate] [dbo].[bDate] NOT NULL,
[InvDescription] [dbo].[bDesc] NULL,
[PayTerms] [dbo].[bPayTerms] NULL,
[DueDate] [dbo].[bDate] NOT NULL,
[HoldCode] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[PayControl] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[CMCo] [dbo].[bCompany] NULL,
[CMAcct] [dbo].[bCMAcct] NULL,
[APTrans] [dbo].[bTrans] NULL,
[APCo] [dbo].[bCompany] NOT NULL,
[SalesTypeRstrct] [varchar] (1) COLLATE Latin1_General_BIN NOT NULL,
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
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   /***********************************************************/
   CREATE trigger [dbo].[btMSMHd] on [dbo].[bMSMH] for DELETE as
   

/*-----------------------------------------------------------------
    * Created By:	GF 02/17/2005
    * Modified By:
    *
    *	Check for MS Material Vendor Worksheet Detail
    *
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   -- check for Worksheet Detail
   if exists(select 1 from bMSMT w with (Nolock) join deleted d on w.Co = d.Co and w.Mth = d.Mth
       and w.BatchId = d.BatchId and w.BatchSeq = d.BatchSeq)
       begin
       select @errmsg = 'Worksheet Detail exists'
       goto error
       end
   
   return
   
   
   error:
   	select @errmsg = @errmsg + ' - cannot delete MS Material Vendor Worksheet Header!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   /************************************************************/
   CREATE trigger [dbo].[btMSMHi] on [dbo].[bMSMH] for INSERT as
   

/*--------------------------------------------------------------
    * Created By:	GF 02/17/2004
    * Modified By:
    *
    * Insert trigger bMSMH - Material Vendor Worksheet Header
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
   join inserted i on v.VendorGroup = i.VendorGroup and v.Vendor = i.MatlVendor
   where v. ActiveYN = 'Y'
   if @validcnt <> @numrows
       begin
       select @errmsg = 'Invalid or inactive Material Vendor'
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
      select @errmsg = @errmsg + ' - cannot insert MS Material Vendor Worksheet Header'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /**************************************************************/
   CREATE  trigger [dbo].[btMSMHu] on [dbo].[bMSMH] for UPDATE as
   

/*-----------------------------------------------------------------
    * Created By:	GF 02/17/2005
    * Modified By:	GF 08/04/2005 - issue #29494 missing batch seq from check of MSMT for detail.
    *
    *
    *
    * Update trigger for bMSMH (Material Vendor Worksheet Header)
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
   if update(VendorGroup) or update(MatlVendor)
       begin
       if exists(select 1 from bMSMT d with (Nolock) join inserted i on d.Co = i.Co and d.Mth = i.Mth
   					and d.BatchId = i.BatchId and d.BatchSeq = i.BatchSeq)
           begin
           select @errmsg = 'Cannot change Material Vendor when Worksheet Detail exists'
           goto error
           end
       end
   
   
   
   return
   
   
   
   error:
   	select @errmsg = @errmsg + ' - cannot update MS Material Vendor Worksheet Header!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biMSMH] ON [dbo].[bMSMH] ([Co], [Mth], [BatchId], [BatchSeq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bMSMH] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brCMAcct]', N'[dbo].[bMSMH].[CMAcct]'
GO
