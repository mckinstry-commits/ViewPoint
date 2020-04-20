CREATE TABLE [dbo].[bMSWD]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[TransMth] [dbo].[bMonth] NOT NULL,
[MSTrans] [dbo].[bTrans] NOT NULL,
[PayCode] [dbo].[bPayCode] NULL,
[PayBasis] [dbo].[bUnits] NOT NULL,
[PayRate] [dbo].[bUnitCost] NOT NULL,
[PayTotal] [dbo].[bDollar] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[Ticket] [dbo].[bTic] NULL,
[SaleDate] [dbo].[bDate] NULL,
[Truck] [dbo].[bTruck] NULL,
[TruckType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[FromLoc] [dbo].[bLoc] NULL,
[MatlGroup] [dbo].[bGroup] NULL,
[Material] [dbo].[bMatl] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[HaulPayTaxType] [tinyint] NULL,
[HaulPayTaxCode] [dbo].[bTaxCode] NULL,
[HaulPayTaxRate] [dbo].[bUnitCost] NULL,
[HaulPayTaxAmt] [dbo].[bDollar] NULL
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biMSWD] ON [dbo].[bMSWD] ([Co], [Mth], [BatchId], [BatchSeq], [TransMth], [MSTrans]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bMSWD] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE   trigger [dbo].[btMSWDd] on [dbo].[bMSWD] for DELETE as
    

/*-----------------------------------------------------------------
     *  Created By:  GG 01/10/01
     *  Modified By: GF 07/20/01 - Set AuditYN to 'N'
     *				  GF 03/25/2003 - issue #20785 validate and lock MSTD record using trans month.
     *
     *	Unlock any associated MS Detail - set InUseBatchId to null.
     *
     */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int
    
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
    
   -- 'unlock' existing MS Detail
   update bMSTD set InUseBatchId = null
   from bMSTD t
   join deleted d on d.Co = t.MSCo and d.TransMth = t.Mth and d.MSTrans = t.MSTrans
   if @@rowcount <> @numrows
        begin
        select @errmsg = 'Unable to unlock MS Transaction Detail'
        goto error
        end
    
   return
    
   
   
   error:
    	select @errmsg = @errmsg + ' - cannot delete MS Hauler Worksheet Detail!'
        RAISERROR(@errmsg, 11, -1);
        rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE  trigger [dbo].[btMSWDi] on [dbo].[bMSWD] for INSERT as
    

/*--------------------------------------------------------------
     * Created: GG 01/10/01
     * Modified: GF 03/25/2003 - issue #20785 validate and lock MSTD record using trans month.
     *			  GF 07/29/2003 - isseu #21933 speed improvements
     *						
     *
     * Performs validation on critical columns.
     *
     * Locks bMSTD entries pulled into batch
     *
     * Adds bHQCC entries as needed
     *
     *--------------------------------------------------------------*/
    declare @numrows int, @errmsg varchar(255), @validcnt int, @opencursor tinyint,
            @msglco bCompany, @co bCompany, @mth bMonth, @batchid bBatchID,
            @apco bCompany,  @glco bCompany
    
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   set @opencursor = 0
    
   -- validate batch
   select @validcnt = count(*)
   from bHQBC r with (Nolock) 
   join inserted i ON i.Co = r.Co and i.Mth = r.Mth and i.BatchId = r.BatchId
   where r.Status = 0  -- must be Open
   if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Invalid or missing Batch, must be Open!'
    	goto error
    	end
   
   -- validate with Worksheet Batch Header
   select @validcnt = count(*)
   from bMSWH h with (Nolock) 
   join inserted i ON i.Co = h.Co and i.Mth = h.Mth and i.BatchId = h.BatchId and i.BatchSeq = h.BatchSeq
   if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Worksheet detail references an invalid or missing Worksheet Header!'
    	goto error
    	end
   
   -- lock & validate MS Trans#, Haul Vendor in bMSTD must match Vendor in bMSWH
   update bMSTD set InUseBatchId = i.BatchId
   from bMSTD t
   join inserted i on i.Co = t.MSCo and i.TransMth = t.Mth and i.MSTrans = t.MSTrans
   join bMSWH h with (Nolock) on i.Co = h.Co and i.Mth = h.Mth and i.BatchId = h.BatchId and i.BatchSeq = h.BatchSeq
        and h.VendorGroup = t.VendorGroup and h.HaulVendor = t.HaulVendor
   where t.InUseBatchId is null and t.APRef is null and t.Void = 'N'
   if @@rowcount <> @numrows
    	begin
    	select @errmsg = 'Invalid or ineligible MS Transaction!'
    	goto error
    	end
    
   -- Add entries to HQ Close Control if needed.
   if @numrows = 1
   	select @co = i.Co, @mth = i.Mth, @batchid = i.BatchId, @apco = c.APCo, @msglco = c.GLCo
   	from inserted i join bMSCO c on i.Co = c.MSCo
   else
    	begin
    	-- use a cursor to process each inserted row
    	declare bMSWD_insert cursor LOCAL FAST_FORWARD
   	for select distinct i.Co, i.Mth, i.BatchId, c.APCo, c.GLCo
    	from inserted i join bMSCO c with (Nolock) on i.Co = c.GLCo
    
    	open bMSWD_insert
    	set @opencursor = 1
    
    	fetch next from bMSWD_insert into @co, @mth, @batchid, @apco, @msglco
    	if @@fetch_status <> 0
    		begin
    		select @errmsg = 'Cursor error'
    		goto error
    		end
    	end
    
   insert_HQCC_check:
   -- add entry to HQ Close Control for MS Company GLCo
   if not exists(select top 1 1 from bHQCC with (Nolock) where Co = @co and Mth = @mth and BatchId = @batchid and GLCo = @msglco)
    	begin
    	insert bHQCC (Co, Mth, BatchId, GLCo)
    	values (@co, @mth, @batchid, @msglco)
    	end
   
   -- get AP GL Company
   select @glco = GLCo from bAPCO with (Nolock) where APCo = @apco
   if @@rowcount <> 0
   	begin
   	-- add entry to HQ Close Control for AP Co#
   	if not exists(select top 1 1 from bHQCC with (Nolock) where Co = @co and Mth = @mth and BatchId = @batchid and GLCo = @glco)
   		begin
   		insert bHQCC (Co, Mth, BatchId, GLCo)
   		values (@co, @mth, @batchid, @glco)
   		end
   	end
    
   if @numrows > 1
   	begin
   	fetch next from bMSWD_insert into @co, @mth, @batchid,  @apco, @msglco
   	if @@fetch_status = 0 goto insert_HQCC_check
   
   	close bMSWD_insert
   	deallocate bMSWD_insert
   	set @opencursor = 0
    	end
    
   
   
   return
    
   
   
   error:
       select @errmsg = @errmsg + ' - cannot insert MS Hauler Worksheet Detail'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE trigger [dbo].[btMSWDu] on [dbo].[bMSWD] for UPDATE as
    

/*-----------------------------------------------------------------
     * Created:  GG 01/10/01
     * Modified: GF 03/25/2003 - issue #20785 validate and lock MSTD record using trans month.
     *
     * Cannot change Company, Mth, BatchId, Seq, or MS Trans
     *
     *----------------------------------------------------------------*/
   declare @numrows int, @validcount int, @errmsg varchar(255)
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
    
   -- check for key changes
   select @validcount = count(*)
   from deleted d join inserted i on d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId
        and d.BatchSeq = i.BatchSeq and d.TransMth = i.TransMth and d.MSTrans = i.MSTrans
   if @numrows <> @validcount
    	begin
    	select @errmsg = 'Cannot change Company, Month, Batch ID #, Sequence #, Trans Month, or MS Trans #'
    	goto error
    	end
    
   return
    
   
   
   error:
    	select @errmsg = @errmsg + ' - cannot update MS Hauler Worksheet Detail!'
    	RAISERROR(@errmsg, 11, -1);
    	rollback transaction
   
  
 



GO
