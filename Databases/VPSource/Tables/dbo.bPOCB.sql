CREATE TABLE [dbo].[bPOCB]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[BatchTransType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[POTrans] [int] NULL,
[PO] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[POItem] [dbo].[bItem] NOT NULL,
[ChangeOrder] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[ActDate] [dbo].[bDate] NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[UM] [dbo].[bUM] NOT NULL,
[ChangeCurUnits] [dbo].[bUnits] NOT NULL,
[CurUnitCost] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bPOCB_CurUnitCost] DEFAULT ((0)),
[ECM] [dbo].[bECM] NULL,
[ChangeCurCost] [dbo].[bDollar] NOT NULL,
[ChangeBOUnits] [dbo].[bUnits] NOT NULL,
[ChangeBOCost] [dbo].[bDollar] NOT NULL,
[OldPO] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[OldPOItem] [dbo].[bItem] NULL,
[OldChangeOrder] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[OldActDate] [dbo].[bDate] NULL,
[OldDescription] [dbo].[bItemDesc] NULL,
[OldUM] [dbo].[bUM] NULL,
[OldCurUnits] [dbo].[bUnits] NULL,
[OldUnitCost] [dbo].[bUnitCost] NULL,
[OldECM] [dbo].[bECM] NULL,
[OldCurCost] [dbo].[bDollar] NULL,
[OldBOUnits] [dbo].[bUnits] NULL,
[OldBOCost] [dbo].[bDollar] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[ChgTotCost] [dbo].[bDollar] NULL CONSTRAINT [DF_bPOCB_ChgTotCost] DEFAULT ((0)),
[OldChgTotCost] [dbo].[bDollar] NULL CONSTRAINT [DF_bPOCB_OldChgTotCost] DEFAULT ((0)),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[ChgToTax] [dbo].[bDollar] NULL,
[POCONum] [smallint] NULL CONSTRAINT [DF_bPOCB_POCONum] DEFAULT ((0))
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
ALTER TABLE [dbo].[bPOCB] ADD
CONSTRAINT [CK_bPOCB_ECM] CHECK (([ECM]='E' OR [ECM]='C' OR [ECM]='M' OR [ECM] IS NULL))
ALTER TABLE [dbo].[bPOCB] ADD
CONSTRAINT [CK_bPOCB_OldECM] CHECK (([OldECM]='E' OR [OldECM]='C' OR [OldECM]='M' OR [OldECM] IS NULL))
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

 
   
   CREATE     trigger [dbo].[btPOCBd] on [dbo].[bPOCB] for DELETE as 
	/********************************************** 
    * Created: kb 4/24/98
    * Modified: kb 12/4/98
    * 			LM 01/23/00 - When coming from PM we don't want to reset the inusebatchid
    *          The Great TV 03/21/02 Delete HQAT records
    *			GG 04/18/02 - #17051 cleanup
    *			DC 05/15/09 - #133438 - Ensure stored procedures/triggers are using the correct attachment delete proc
    *
    *	Delete trigger on PO Change Order Batch entries.
    *
    ***********************************************/
   declare @numrows int, @errmsg varchar(255), @validcnt int
   
   select @numrows = @@rowcount 
   if @numrows = 0 return
   
   set nocount on
   
   -- unlock PO Change Order Detail
   update dbo.bPOCD
   set InUseBatchId = null
   from bPOCD r
   join deleted d on d.Co = r.POCo and d.Mth = r.Mth and d.POTrans = r.POTrans
   where r.InUseBatchId = d.BatchId
   
   -- unlock PO Item if all entries for the Item have been removed
   update dbo.bPOIT
   set InUseMth = null, InUseBatchId = null
   from bPOIT i
   join deleted d on i.POCo = d.Co and i.PO = d.PO and i.POItem = d.POItem
   where d.POItem not in (select b.POItem from bPOCB b where b.Co = d.Co and b.Mth = d.Mth 
   						and b.BatchId = d.BatchId and b.PO = d.PO and b.POItem = d.POItem)
    
   -- unlock PO Header if all entries have been removed
   update dbo.bPOHD
   set InUseBatchId = null, InUseMth = null
   from deleted d
   join bPOHD t on d.Co = t.POCo and d.PO = t.PO
   where d.PO not in (select r.PO from bPOCB r where r.Co = d.Co and r.Mth = d.Mth
   					and r.BatchId = d.BatchId and r.PO = d.PO)
   
   --DC #133440
   --delete HQAT entries if not exists in POCD
   --if exists(select 1 from deleted where UniqueAttchID is not null)
   --	begin
   --	delete bHQAT 
   --	from bHQAT h join deleted d on h.UniqueAttchID = d.UniqueAttchID
   --	where h.UniqueAttchID not in(select t.UniqueAttchID from bPOCD t join deleted d1 on t.UniqueAttchID = d1.UniqueAttchID)
   --	end
      
   --DC #133440
   insert vDMAttachmentDeletionQueue (AttachmentID, UserName, DeletedFromRecord)
    select AttachmentID, suser_name(), 'Y' 
        	from bHQAT h join deleted d on h.UniqueAttchID = d.UniqueAttchID
   			where h.UniqueAttchID not in(select t.UniqueAttchID from bPOCD t join deleted d1 on t.UniqueAttchID = d1.UniqueAttchID)
   			and d.UniqueAttchID is not null     
   
   
   return
   
   error:
   
      select @errmsg = @errmsg + ' - cannot delete PO Change Order Batch entry (bPOCB)'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
   
   
   
   
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

 
  
   
   
   
   
   
   
   /****** Object:  Trigger dbo.btPOCBi    Script Date: 8/28/99 9:38:06 AM ******/
   CREATE     trigger [dbo].[btPOCBi] on [dbo].[bPOCB] for INSERT as
   

/*********************************************
    * Created: kb 4/24/98
    * Modified: kb 1/4/99
    *			GG 04/18/02 - #17051 cleanup, removed cursor 
    *
    * Insert trigger for PO Change Order Batch entries
    *
    *********************************************/
   
   declare @numrows int, @errmsg varchar(255), @validcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   -- validate batch
   select @validcnt = count(*)
   from bHQBC r
   JOIN inserted i ON i.Co = r.Co and i.Mth = r.Mth and i.BatchId = r.BatchId
   where r.Status = 0
   if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Invalid Batch or incorrect status, must be ''open'''
    	goto error
    	end
   -- validate Batch Trans Type
   if exists(select 1 from inserted where BatchTransType not in ('A','C','D'))
   	begin
    	select @errmsg = 'Invalid Batch Transaction Type, must be ''A'',''C'', or ''D'''
    	goto error
    	end
   
   -- add HQ Close Control for AP/PO GL Co#
   insert bHQCC (Co, Mth, BatchId, GLCo)
   select i.Co, i.Mth, i.BatchId, c.GLCo
   from inserted i
   join bAPCO c on i.Co = c.APCo
   where c.GLCo not in (select h.GLCo from bHQCC h join inserted i on h.Co = i.Co and h.Mth = i.Mth 
   						and h.BatchId = i.BatchId)
   
   -- add HQ Close Control for GL Co#s referenced by PO Item
   insert bHQCC (Co, Mth, BatchId, GLCo)
   select i.Co, i.Mth, i.BatchId, p.GLCo
   from inserted i
   join bPOIT p on i.Co = p.POCo and i.PO = p.PO and i.POItem = p.POItem
   where p.GLCo not in (select h.GLCo from bHQCC h join inserted i on h.Co = i.Co and h.Mth = i.Mth 
   						and h.BatchId = i.BatchId)
   
   --lock existing bPOCD Change Order entries pulled into batch
   select @validcnt = count(*) from inserted where BatchTransType in ('C','D')
   if @validcnt <> 0
   	begin
   	update bPOCD
   	set InUseBatchId = i.BatchId
   	from bPOCD d
   	join inserted i on i.Co = d.POCo and i.Mth = d.Mth and i.POTrans = d.POTrans
   	if @@rowcount <> @validcnt
    		begin
    		select @errmsg = 'Unable to lock PO Change Order Detail'
    		goto error
    		end
    	end	
    
   --lock existing PO Headers, unless the batch is from a PM Interface 
   -- PM may create both an Entry and Change Order batch in the same interface, so don't lock the Header
   update dbo.bPOHD
   set InUseMth = i.Mth, InUseBatchId = i.BatchId 
   from bPOHD h
   join inserted i on i.Co = h.POCo and i.PO = h.PO
   join bHQBC b on i.Co = b.Co and i.Mth = b.Mth and i.BatchId = b.BatchId
   where h.InUseMth is null and h.InUseBatchId is null
   	and b.Source <> 'PM Intface' 
   
   
   -- lock existing PO Items, same rules apply for PM batches
   update dbo.bPOIT
   set InUseMth = i.Mth, InUseBatchId = i.BatchId 
   from bPOIT t
   join inserted i on i.Co = t.POCo and i.PO = t.PO and i.POItem = t.POItem
   join bHQBC b on i.Co = b.Co and i.Mth = b.Mth and i.BatchId = b.BatchId
   where t.InUseMth is null and t.InUseBatchId is null
   	and b.Source <> 'PM Intface' 
   
   return
   
   error:
       select @errmsg = @errmsg + ' - cannot insert PO Change Order Batch entry (bPOCB)'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btPOCBu    Script Date: 8/28/99 9:38:06 AM ******/
   CREATE   trigger [dbo].[btPOCBu] on [dbo].[bPOCB] for UPDATE as
   

/*--------------------------------------------------------------
    *  Created By: kf 04/25/97
    *  Modified: kb 12/2/98
    *              GG 06/14/01 - allow PO Transaction update with Add entries
    *				GG 04/30/02 - #17051 - cleanup
    *
    *  Update trigger for PO Change Order Batch table
    *--------------------------------------------------------------*/
   declare @numrows int, @errmsg varchar(255), @validcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   /* check for key changes */
   select @validcnt = count(*) from deleted d
   join inserted i on d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId and d.BatchSeq = i.BatchSeq
   if @numrows <> @validcnt
       begin
    	select @errmsg = 'Cannot change Company, Month, Batch ID #, or Batch Sequence #'
    	goto error
    	end
   
   -- check Batch Transaction Type
   if update(BatchTransType)
   	begin
   	select @validcnt = count(*) from inserted i where i.BatchTransType in ('A','C','D')
   	if @validcnt <> @numrows
   	 	begin
   	 	select @errmsg = 'Batch Transaction Type must be ''A'',''C'', or ''D'''
   	 	goto error
   	 	end
   	-- check for change
   	select @validcnt = count(*)
   	from deleted d
   	join inserted i on d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId and d.BatchSeq = i.BatchSeq
   	where (d.BatchTransType = 'A' and i.BatchTransType in ('C','D'))
   	if @validcnt > 0
   	    begin
   	    select @errmsg = 'Cannot change Batch Transaction Type from ''A'' to ''C'' or ''D'''
   	    goto error
   	    end
   	select @validcnt = count(*)
   	from deleted d
   	join inserted i on d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId and d.BatchSeq = i.BatchSeq
   	where (i.BatchTransType = 'A' and d.BatchTransType in ('C','D'))
   	if @validcnt > 0
   	 	begin
   	 	select @errmsg = 'Cannot change Batch Transaction Type from ''C'' or ''D'' to ''A'''
   	 	goto error
   	 	end
   	end
   
   -- check PO Transaction, change allowed on 'add' needed for user memo updates
   if update(POTrans)
   	begin
   	select @validcnt = count(*)
   	from deleted d
   	join inserted i on d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId and d.BatchSeq = i.BatchSeq
   	where i.BatchTransType in ('C','D') and ((i.POTrans <> d.POTrans) or i.POTrans is null or d.POTrans is null)
   	if @validcnt > 0
   	    begin
   	    select @errmsg = 'Cannot change PO Transaction # on ''C'' or ''D'' entries'
   	    goto error
   	    end
   	end
   
   /* if change or delete, cannot change PO or POItem */
   if update(PO) or update(POItem)
   	begin
   	select @validcnt = count(*)
   	from deleted d
   	join inserted i on d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId and d.BatchSeq = i.BatchSeq
   	where i.BatchTransType in ('C','D') and (d.PO <> i.PO or d.POItem <> i.POItem)
   	 if @validcnt > 0
   	 	begin
   	 	select @errmsg = 'Cannot change Purchase Order or Item on ''C'' or ''D'' entries'
   	 	goto error
   	 	end
   	end
   
   -- if PO Header updated, validate, unlock old, and lock new
   if update(PO)
    	begin
    	select @validcnt = count(*)
       from bPOHD r
       JOIN inserted i ON i.Co = r.POCo and i.PO = r.PO
    	if @validcnt <> @numrows
    		begin
    	 	select @errmsg = 'Invalid Purchase Order # '
    	 	goto error
    	 	end
       -- unlock old PO Header if no longer in the batch
    	update bPOHD
    	set InUseBatchId = null, InUseMth = null
       from deleted d
   	join bPOHD t on d.Co = t.POCo and d.PO = t.PO
   	where d.PO not in (select PO from bPOCB r
   						where r.Co=d.Co and r.PO=d.PO and r.Mth=d.Mth and r.BatchId=d.BatchId)
       -- lock new PO Header
    	update bPOHD
    	set InUseBatchId = i.BatchId, InUseMth = i.Mth
       from inserted i
   	join bPOHD t on i.Co = t.POCo and i.PO = t.PO
   	where t.InUseBatchId is null and t.InUseMth is null
    	end
   
   -- if PO Item updated, validate, unlock old, and lock new
  
   if update(POItem)
    	begin
    	select @validcnt = count(*)
       from bPOIT r
       JOIN inserted i ON i.Co = r.POCo and i.PO = r.PO and i.POItem = r.POItem
    	if @validcnt <> @numrows
    	    begin
    	    select @errmsg = 'PO Item is Invalid '
    	    goto error
           end
       -- unlock old PO Item if no longer in the batch
    	update bPOIT
    	set InUseBatchId = null, InUseMth = null
       from deleted d
   	join bPOIT t on d.Co = t.POCo and d.PO = t.PO and d.POItem = t.POItem
       where d.POItem not in (select POItem from bPOCB r where r.Co=d.Co
               and r.PO = d.PO and r.POItem = d.POItem and r.Mth = d.Mth and r.BatchId = d.BatchId)
       -- lock new PO Item
    	update bPOIT
    	set InUseBatchId = i.BatchId, InUseMth = i.Mth
       from inserted i
   	join bPOIT t on i.Co = t.POCo and i.PO = t.PO and i.POItem = t.POItem
   	where t.InUseBatchId is null and t.InUseMth is null
    	end
   
   return
   
   error:
       select @errmsg = @errmsg + ' - cannot update PO Change Order Batch entry (bPOCB)'
       RAISERROR(@errmsg, 11, -1);
   
       rollback transaction
   
   
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biPOCB] ON [dbo].[bPOCB] ([Co], [Mth], [BatchId], [BatchSeq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPOCB] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPOCB].[CurUnitCost]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bPOCB].[ECM]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bPOCB].[OldECM]'
GO
