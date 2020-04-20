CREATE TABLE [dbo].[bMSHB]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[BatchTransType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[HaulTrans] [dbo].[bTrans] NULL,
[FreightBill] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[SaleDate] [dbo].[bDate] NOT NULL,
[HaulerType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[HaulVendor] [dbo].[bVendor] NULL,
[Truck] [dbo].[bTruck] NULL,
[Driver] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[EMCo] [dbo].[bCompany] NULL,
[Equipment] [dbo].[bEquip] NULL,
[EMGroup] [dbo].[bGroup] NULL,
[PRCo] [dbo].[bCompany] NULL,
[Employee] [dbo].[bEmployee] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[OldFreightBill] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[OldSaleDate] [dbo].[bDate] NULL,
[OldHaulerType] [char] (1) COLLATE Latin1_General_BIN NULL,
[OldVendorGroup] [dbo].[bGroup] NULL,
[OldHaulVendor] [dbo].[bVendor] NULL,
[OldTruck] [dbo].[bTruck] NULL,
[OldDriver] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[OldEMCo] [dbo].[bCompany] NULL,
[OldEquipment] [dbo].[bEquip] NULL,
[OldPRCo] [dbo].[bCompany] NULL,
[OldEmployee] [dbo].[bEmployee] NULL,
[OldNotes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE trigger [dbo].[btMSHBd] on [dbo].[bMSHB] for DELETE as
   

/*-----------------------------------------------------------------
    * Created By:  GG 11/07/00
    * Modified By: DAN SO 05/18/09 - Issue: #133441 - Delete Attachments
    *
    *	Unlock any associated Haul Transactions - set InUseBatchId to null.
    *
    */----------------------------------------------------------------
   
   declare @errmsg varchar(255), @numrows int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   -- 'unlock' existing Haul Transaction
   update bMSHH set InUseBatchId = null
   from bMSHH h join deleted d on d.Co = h.MSCo and d.Mth = h.Mth and d.HaulTrans = h.HaulTrans
   

	-- ISSUE: #133441
	-- Delete attachments if they exist. Make sure UniqueAttchID is not null.
	INSERT vDMAttachmentDeletionQueue (AttachmentID, UserName, DeletedFromRecord)
		SELECT AttachmentID, SUSER_NAME(), 'Y' 
          FROM bHQAT h JOIN deleted d 
			ON h.UniqueAttchID = d.UniqueAttchID
         WHERE h.UniqueAttchID NOT IN(SELECT t.UniqueAttchID 
										FROM bMSHH t JOIN deleted d1 
										  ON t.UniqueAttchID = d1.UniqueAttchID)
           AND d.UniqueAttchID IS NOT NULL     

------------------------------------
-- OLD ATTACHMENT DELETION METHOD --
------------------------------------
----   --delete HQAT entries if not exists in MSHH
----   delete bHQAT 
----   from bHQAT h join deleted d on h.UniqueAttchID = d.UniqueAttchID
----   where d.UniqueAttchID is not null 
----   and h.UniqueAttchID not in(select t.UniqueAttchID from bMSHH t join deleted d1 on t.UniqueAttchID = d1.UniqueAttchID)
   
   
   return
   
   
   
   error:
   	select @errmsg = @errmsg + ' - cannot delete Hauler Time Sheet Batch Header!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE   trigger [dbo].[btMSHBi] on [dbo].[bMSHB] for INSERT as
   

/*--------------------------------------------------------------
    * Created By: GG 11/07/00
    * Modified By: GF 10/09/2002 - changed dbl quotes to single quotes
    *				GF 12/03/2003 - issue #23147 changes for ansi nulls
    *
    *
    * Insert trigger bMSHB - Hauler Time Sheet Header
    *
    * Performs validation on critical columns.
    *
    * Locks bMSHH entries pulled into batch
    *
    * Adds bHQCC entries as needed
    *
    *--------------------------------------------------------------*/
   declare @numrows int, @errmsg varchar(255), @validcnt int, @opencursor tinyint,
           @msglco bCompany, @co bCompany, @mth bMonth, @batchid bBatchID,
           @emco bCompany, @glco bCompany
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   set @opencursor = 0
   
   -- validate batch
   select @validcnt = count(*) from bHQBC r
          JOIN inserted i ON i.Co = r.Co and i.Mth = r.Mth and i.BatchId = r.BatchId
   if @validcnt<>@numrows
   	begin
   	select @errmsg = 'Invalid Batch ID#'
   	goto error
   	end
   
   select @validcnt = count(*) from bHQBC r
          JOIN inserted i ON i.Co = r.Co and i.Mth = r.Mth and
               i.BatchId = r.BatchId and r.Status = 0
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Must be an open batch.'
   	goto error
   	end
   
   -- validate BatchTransType
   if exists(select * from inserted where BatchTransType not in ('A','C','D'))
       begin
       select @errmsg = 'Invalid Batch Trans Type, must be (A, C, or D)!'
       goto error
       end
   
   -- validate Haul Trans#
   if exists(select * from inserted where BatchTransType = 'A' and HaulTrans is not null)
   	begin
   	select @errmsg = 'Haul Trans # must be null for all type (A) entries!'
   	goto error
   	end
   if exists(select * from inserted where BatchTransType <> 'A' and HaulTrans is null)
   	begin
   	select @errmsg = 'All type (C) and (D) entries must have an Haul Trans #!'
   	goto error
   	end
   
   -- attempt to update InUseBatchId in MSHH
   select @validcnt = count(*) from inserted where BatchTransType <> 'A'
   
   update bMSHH set InUseBatchId = i.BatchId
   from bMSHH h join inserted i on i.Co = h.MSCo and i.Mth = h.Mth and i.HaulTrans = h.HaulTrans
   where h.InUseBatchId is null	-- must be unlocked
   if @validcnt <> @@rowcount
   	begin
   	select @errmsg = 'Unable to lock existing Haul Transaction!'
   	goto error
   	end
   
   -- Add entries to HQ Close Control if needed.
   if @numrows = 1
       select @co = i.Co, @mth = i.Mth, @batchid = i.BatchId, @emco = EMCo, @msglco = c.GLCo
       from inserted i join bMSCO c on i.Co = c.MSCo
   else
   	begin
   	-- use a cursor to process each inserted row
   	declare bMSHB_insert cursor LOCAL FAST_FORWARD
   	for select distinct i.Co, i.Mth, i.BatchId, i.EMCo, c.GLCo
   	from inserted i join bMSCO c on i.Co = c.GLCo
   
   	open bMSHB_insert
   	set @opencursor = 1
   
   	fetch next from bMSHB_insert into @co, @mth, @batchid,  @emco, @msglco
   	if @@fetch_status <> 0
   		begin
   		select @errmsg = 'Cursor error'
   		goto error
   		end
   	end
   
   
   insert_HQCC_check:
   -- add entry to HQ Close Control for MS Company GLCo
   if not exists(select TOP 1 1 from bHQCC where Co = @co and Mth = @mth and BatchId = @batchid and GLCo = @msglco)
   	begin
   	insert bHQCC (Co, Mth, BatchId, GLCo)
   	values (@co, @mth, @batchid, @msglco)
   	end
   
   -- get GL Company for Equipment use
   if @emco is not null
   	begin
       select @glco = GLCo from bEMCO where EMCo = @emco
       if @@rowcount <> 0
   		begin
   		-- add entry to HQ Close Control for Equipment use
   		if not exists(select TOP 1 1 from bHQCC where Co = @co and Mth = @mth and BatchId = @batchid and GLCo = @glco)
   			begin
   			insert bHQCC (Co, Mth, BatchId, GLCo)
   			values (@co, @mth, @batchid, @glco)
   			end
   		end
   	end
   
   
   if @numrows > 1
       begin
       fetch next from bMSHB_insert into @co, @mth, @batchid,  @emco, @msglco
       if @@fetch_status = 0 goto insert_HQCC_check
   
   	close bMSHB_insert
   	deallocate bMSHB_insert
   	set @opencursor = 0
   	end
   
   
   
   return
   
   
   
   error:
   	select @errmsg = @errmsg + ' - cannot insert Haul Transaction Batch entry'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE  trigger [dbo].[btMSHBu] on [dbo].[bMSHB] for UPDATE as
   

/*-----------------------------------------------------------------
    * Created:  GG 11/07/00
    * Modified: GG 06/18/01 - added BatchTransType validation and allow HaulTrans update on new entries
    *			 GF 10/09/2002 - changed dbl quotes to single quotes
    *			 GF 12/03/2003 - issue #23147 changes for ansi nulls
    *
    * Update trigger for bMSHB (Hauler Time Sheet Batch)
    *
    * Cannot change Company, Mth, BatchId, Seq
    *
    * Add HQCC (Close Control) as needed.
    *
    *----------------------------------------------------------------*/
   
   declare @numrows int, @validcount int, @co bCompany, @mth bMonth, @batchid bBatchID,
   		@seq int, @errmsg varchar(255), @opencursor tinyint, @emco bCompany, @msglco bCompany,
   		@glco bCompany
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   set @opencursor = 0
   
   -- check for key changes
   select @validcount = count(*)
   from deleted d join inserted i on d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId and d.BatchSeq = i.BatchSeq
   if @numrows <> @validcount
   	begin
   	select @errmsg = 'Cannot change Company, Month, Batch ID #, or Sequence #'
   	goto error
   	end
   
   -- check Batch Transaction Type
   select @validcount = count(*) from inserted i where i.BatchTransType in ('A','C','D')
   if @validcount <> @numrows
    	begin
    	select @errmsg = 'Batch Transaction Type must be (A, C, or D)'
    	goto error
    	end
   
   -- check for change
   select @validcount = count(*) from deleted d, inserted i
   where d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId and d.BatchSeq = i.BatchSeq
       and (d.BatchTransType = 'A' and i.BatchTransType in ('C','D'))
   if @validcount > 0
       begin
       select @errmsg = 'Cannot change Batch Transaction Type from (A to C or D)'
       goto error
       end
   
   select @validcount = count(*) from deleted d, inserted i
   where d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId and d.BatchSeq = i.BatchSeq
       and (i.BatchTransType = 'A' and d.BatchTransType in ('C','D'))
   if @validcount > 0
    	begin
    	select @errmsg = 'Cannot change Batch Transaction Type from (C or D to A)'
    	goto error
    	end
   
   -- check Haul Transaction
   select @validcount = count(*) from deleted d, inserted i
   where d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId and d.BatchSeq = i.BatchSeq
       and i.BatchTransType in ('C','D') and ((i.HaulTrans <> d.HaulTrans) or i.HaulTrans is null or d.HaulTrans is null)
   if @validcount > 0
       begin
       select @errmsg = 'Cannot change Haul Transaction # on (C or D) entries'
       goto error
       end
   
   -- update entries to HQ Close Control
   if @numrows = 1
       select @co = i.Co, @mth = i.Mth, @batchid = i.BatchId, @emco = EMCo, @msglco = c.GLCo
       from inserted i join bMSCO c on i.Co = c.MSCo
   else
       begin
   	-- use a cursor to process each updated row
   	declare bMSHB_update cursor LOCAL FAST_FORWARD
   	for select distinct i.Co, i.Mth, i.BatchId, i.EMCo, c.GLCo
   	from inserted i join bMSCO c on i.Co = c.MSCo
   
   	open bMSHB_update
       set @opencursor = 1
   
   	fetch next from bMSHB_update into @co, @mth, @batchid, @emco, @msglco
   	if @@fetch_status <> 0
           begin
   		select @errmsg = 'Cursor error'
   		goto error
   		end
   	end
   
   
   insert_HQCC_check:
   -- add entry to HQ Close Control for MS Company GLCo
   if not exists(select top 1 1 from bHQCC where Co = @co and Mth = @mth and BatchId = @batchid and GLCo = @msglco)
   	begin
   	insert bHQCC (Co, Mth, BatchId, GLCo)
   	values (@co, @mth, @batchid, @msglco)
   	end
   
   -- get GL Compamy for Equipment use
   if @emco is not null
   	begin
   	select @glco = GLCo from bEMCO where EMCo = @emco
   	if @@rowcount <> 0
   		begin
   		-- add entry to HQ Close Control for Equipment use
   		if not exists(select * from bHQCC where Co = @co and Mth = @mth and BatchId = @batchid and GLCo = @glco)
   			begin
   			insert bHQCC (Co, Mth, BatchId, GLCo)
   			values (@co, @mth, @batchid, @glco)
   			end
   		end
   	end
   
   
   if @numrows > 1
       begin
       fetch next from bMSHB_update into @co, @mth, @batchid, @emco, @msglco
       if @@fetch_status = 0 goto insert_HQCC_check
   
   	close bMSHB_update
   	deallocate bMSHB_update
   	set @opencursor = 0
   	end
   
   
   
   return
   
   
   
   error:
   	select @errmsg = @errmsg + ' - cannot update Hauler Time Sheet Batch Header!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biMSHB] ON [dbo].[bMSHB] ([Co], [Mth], [BatchId], [BatchSeq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bMSHB] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
