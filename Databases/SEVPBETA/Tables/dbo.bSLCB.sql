CREATE TABLE [dbo].[bSLCB]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[BatchTransType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[SLTrans] [dbo].[bTrans] NULL,
[SL] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[SLItem] [dbo].[bItem] NOT NULL,
[SLChangeOrder] [smallint] NOT NULL,
[AppChangeOrder] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[ActDate] [dbo].[bDate] NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[UM] [dbo].[bUM] NOT NULL,
[ChangeCurUnits] [dbo].[bUnits] NOT NULL,
[CurUnitCost] [dbo].[bUnitCost] NOT NULL,
[ChangeCurCost] [dbo].[bDollar] NOT NULL,
[OldSL] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[OldSLItem] [dbo].[bItem] NULL,
[OldSLChangeOrder] [smallint] NULL,
[OldAppChangeOrder] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[OldActDate] [dbo].[bDate] NULL,
[OldDescription] [dbo].[bItemDesc] NULL,
[OldUM] [dbo].[bUM] NULL,
[OldCurUnits] [dbo].[bUnits] NULL,
[OldUnitCost] [dbo].[bUnitCost] NULL,
[OldCurCost] [dbo].[bDollar] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[PMSLSeq] [int] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[ChgToTax] [dbo].[bDollar] NULL,
[ChgToJCCmtdTax] [dbo].[bDollar] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  trigger [dbo].[btSLCBd] on [dbo].[bSLCB] for DELETE as  
/********************************************** 
    * Created: kb 4/24/98
    * Modified: LM 01/23/00 - When coming from PM we don't want to reset the inusebatchid
    *          MV 07/09/01 - Issue 13952 Update InUseBatchId only if it's TransType C
    *          TV 07/11/01 - The SLCD delete was not working properly issue 13965
    *          I'm Back TV 03/21/02 delete HQAT Records
    *			GG 04/18/02 - #17050 cleanup
    *			DC 0515/09 - #133440 - Ensure stored procedures/triggers are using the correct attachment delete proc
    *
    *********************************************/   
   declare @numrows int, @errmsg varchar(255), @validcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   -- unlock SL Change Order Detail
   update bSLCD
   set InUseBatchId = null
   from bSLCD r
   join deleted d on d.Co = r.SLCo and d.Mth = r.Mth and d.SLTrans = r.SLTrans
   where r.InUseBatchId = d.BatchId
   
   -- unlock SL Item if all entries for the Item have been removed
   update bSLIT
   set InUseMth = null, InUseBatchId = null
   from bSLIT i
   join deleted d on i.SLCo = d.Co and i.SL = d.SL and i.SLItem = d.SLItem
   where d.SLItem not in (select b.SLItem from bSLCB b where b.Co = d.Co and b.Mth = d.Mth 
   						and b.BatchId = d.BatchId and b.SL = d.SL and b.SLItem = d.SLItem)
   
   -- unlock SL Header if all entries have been removed
   update bSLHD
   set InUseBatchId = null, InUseMth = null
   from deleted d
   join bSLHD t on d.Co = t.SLCo and d.SL = t.SL
   where d.SL not in (select r.SL from bSLCB r where r.Co = d.Co and r.Mth = d.Mth
   					and r.BatchId = d.BatchId and r.SL = d.SL)
   
   --DC #133440
   --delete HQAT entries if not exists in SLCD
   --if exists(select 1 from deleted where UniqueAttchID is not null)
   --	begin
   --	delete bHQAT 
   --	from bHQAT h join deleted d on h.UniqueAttchID = d.UniqueAttchID
   --	where h.UniqueAttchID not in(select t.UniqueAttchID from bSLCD t join deleted d1 on t.UniqueAttchID = d1.UniqueAttchID)
   --	end
      
   --DC #133440
   insert vDMAttachmentDeletionQueue (AttachmentID, UserName, DeletedFromRecord)
    select AttachmentID, suser_name(), 'Y' 
        	from bHQAT h join deleted d on h.UniqueAttchID = d.UniqueAttchID
   			where h.UniqueAttchID not in(select t.UniqueAttchID from bSLCD t join deleted d1 on t.UniqueAttchID = d1.UniqueAttchID)
   			and d.UniqueAttchID is not null     
   
   return
   
   error:
       select @errmsg = @errmsg + ' - cannot delete SL Change Order Batch entry (bSLCB)'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE     trigger [dbo].[btSLCBi] on [dbo].[bSLCB] for INSERT as
   

/*********************************************
    * Created: kb 4/24/98
    * Modified: kb 1/4/99
    *			GG 04/18/02 - #17050 cleanup
    *
    * Insert trigger for SL Change Order Batch entries
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
    	select @errmsg = 'Invalid Batch or incorrect status, must be [Open].'
    	goto error
    	end
   -- validate Batch Trans Type
   if exists(select 1 from inserted where BatchTransType not in ('A','C','D'))
   	begin
    	select @errmsg = 'Invalid Batch Transaction Type, must be ''A'',''C'', or ''D'''
    	goto error
    	end
   
   -- add HQ Close Control for AP/SL GL Co#
   insert bHQCC (Co, Mth, BatchId, GLCo)
   select i.Co, i.Mth, i.BatchId, c.GLCo
   from inserted i
   join bAPCO c on i.Co = c.APCo
   where c.GLCo not in (select h.GLCo from bHQCC h join inserted i on h.Co = i.Co and h.Mth = i.Mth 
   						and h.BatchId = i.BatchId)
   
   -- add HQ Close Control for GL Co#s referenced by SL Item
   insert bHQCC (Co, Mth, BatchId, GLCo)
   select i.Co, i.Mth, i.BatchId, p.GLCo
   from inserted i
   join bSLIT p on i.Co = p.SLCo and i.SL = p.SL and i.SLItem = p.SLItem
   where p.GLCo not in (select h.GLCo from bHQCC h join inserted i on h.Co = i.Co and h.Mth = i.Mth 
   						and h.BatchId = i.BatchId)
    
   --lock existing bSLCD Change Order entries pulled into batch
   select @validcnt = count(*) from inserted where BatchTransType in ('C','D')
   if @validcnt <> 0
   	begin
   	update bSLCD
   	set InUseBatchId = i.BatchId
   	from bSLCD d
   	join inserted i on i.Co = d.SLCo and i.Mth = d.Mth and i.SLTrans = d.SLTrans
   	where d.InUseBatchId is null
   	if @@rowcount <> @validcnt
    		begin
    		select @errmsg = 'Unable to lock SL Change Order Detail'
    		goto error
    		end
    	end	
   
   --lock existing SL Headers, unless the batch is from a PM Interface 
   -- PM may create both an Entry and Change Order batch in the same interface, so don't lock the Header
   update bSLHD
   set InUseMth = i.Mth, InUseBatchId = i.BatchId 
   from bSLHD h
   join inserted i on i.Co = h.SLCo and i.SL = h.SL
   join bHQBC b on i.Co = b.Co and i.Mth = b.Mth and i.BatchId = b.BatchId
   where h.InUseMth is null and h.InUseBatchId is null
   	and b.Source <> 'PM Intface' 
   
   -- lock existing SL Items, same rules apply for PM batches
   update bSLIT
   set InUseMth = i.Mth, InUseBatchId = i.BatchId 
   from bSLIT t
   join inserted i on i.Co = t.SLCo and i.SL = t.SL and i.SLItem = t.SLItem
   join bHQBC b on i.Co = b.Co and i.Mth = b.Mth and i.BatchId = b.BatchId
   where t.InUseMth is null and t.InUseBatchId is null
   	and b.Source <> 'PM Intface'
    
   return
   
   error:
       select @errmsg = @errmsg + ' - cannot insert SL Change Order Batch entry (bSLCB)'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Trigger dbo.btSLCBu    Script Date: 8/28/99 9:38:17 AM ******/
   CREATE    trigger [dbo].[btSLCBu] on [dbo].[bSLCB] for UPDATE as
   

/*--------------------------------------------------------------
    *  Created: kf 5/13/97
    *  Modified: EN 3/28/00 - if BatchTransType = 'A' cannot change to 'C' or 'D' and vice versa
    *               EN 3/29/00 - if BatchTransType <> 'A' cannot change SLTrans, SL or SLItem
    *               kb 8/24/00 - issue #10336 to handle a problem with fix listed above for 3/28/00
    *				GG 04/30/02 - #17050 - cleanup 
    *				MV 10/21/04 - #25832 - clear 'inuse' for item, when changing SL
    *
    *  Update trigger for SL Change Order Batch table
    *
    *--------------------------------------------------------------*/
   declare @numrows int,@errmsg varchar(255), @validcnt int
   
   select @numrows=count(*) from inserted
   if @numrows = 0 return
   
   set nocount on
   
   /* check for key changes */
   select @validcnt = count(*) from deleted d
   join inserted i on i.Co = d.Co and i.Mth = d.Mth and i.BatchId = d.BatchId and i.BatchSeq = d.BatchSeq
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
   	select @validcnt = count(*) from deleted d, inserted i
   	where d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId and d.BatchSeq = i.BatchSeq
   	    and (d.BatchTransType = 'A' and i.BatchTransType in ('C','D'))
   	if @validcnt > 0
   	    begin
   	    select @errmsg = 'Cannot change Batch Transaction Type from ''A'' to ''C'' or ''D'''
   	    goto error
   	    end
   	select @validcnt = count(*) from deleted d, inserted i
   	where d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId and d.BatchSeq = i.BatchSeq
   	    and (i.BatchTransType = 'A' and d.BatchTransType in ('C','D'))
   	if @validcnt > 0
   	 	begin
   	 	select @errmsg = 'Cannot change Batch Transaction Type from ''C'' or ''D'' to ''A'''
   	 	goto error
   	 	end
   	end
   
   -- check SL Transaction, change allowed on 'add' needed for user memo updates
   if update(SLTrans)
   	begin
   	select @validcnt = count(*)
   	from deleted d
   	join inserted i on i.Co = d.Co and i.Mth = d.Mth and i.BatchId = d.BatchId and i.BatchSeq = d.BatchSeq
   	where i.BatchTransType in ('C','D') and (i.SLTrans <> d.SLTrans or i.SLTrans is null or d.SLTrans is null)
   	if @validcnt <> 0
   	    begin
   	    select @errmsg = 'Cannot change SL Transaction # on ''C'' or ''D'' entries'
   	    goto error
   	    end
   	end
   /* if change or delete, cannot change SL or SLItem */
   if update(SL) or update(SLItem)
   	begin
   	select @validcnt = count(*)
   	from deleted d
   	join inserted i on d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId and d.BatchSeq = i.BatchSeq
   	where i.BatchTransType in ('C','D') and (d.SL <> i.SL or d.SLItem <> i.SLItem)
   	 if @validcnt > 0
   	 	begin
   	 	select @errmsg = 'Cannot change Subcontract or Item on ''C'' or ''D'' entries'
   	 	goto error
   	 	end
   	end
   /* Validate SL */
   if update(SL)
   	begin
   	select @validcnt = count(*)
   	from bSLHD r
   	JOIN inserted i ON i.Co = r.SLCo and i.SL = r.SL
   	if @validcnt <> @numrows
   		begin
   	 	select @errmsg = 'Invalid Subcontract '
   	 	goto error
   	 	end
       -- unlock old SL Header if no longer in the batch
   	update bSLHD
   	set InUseBatchId = null, InUseMth = null
   	from deleted d
       join bSLHD t on d.Co=t.SLCo and d.SL=t.SL
   	where d.SL not in (select SL from bSLCB r where	r.Co=d.Co and r.SL=d.SL and r.Mth=d.Mth and r.BatchId=d.BatchId)
   
   	-- lock new SL Header	
   	update bSLHD
   	set InUseBatchId = i.BatchId, InUseMth = i.Mth
   	from inserted i
       join bSLHD t on i.Co = t.SLCo and i.SL = t.SL
   	where t.InUseBatchId is null and t.InUseMth is null
   	end
   	
   	/* #25832 */
   	-- unlock item in old SL
   	update bSLIT
   	set InUseBatchId = null, InUseMth = null
   	from deleted d
   	join bSLIT t on d.Co = t.SLCo and d.SL = t.SL and d.SLItem = t.SLItem 
   	where d.SLItem not in (select SLItem from bSLCB r where r.Co=d.Co
   			and r.SL=d.SL and r.SLItem=d.SLItem and r.Mth=d.Mth and r.BatchId=d.BatchId)
       -- lock item in new SL
   	update bSLIT
   	set InUseBatchId = i.BatchId, InUseMth = i.Mth
   	from inserted i
   	join bSLIT t on i.Co = t.SLCo and i.SL = t.SL and i.SLItem = t.SLItem
   	where t.InUseBatchId is null and t.InUseMth is null
   
   -- if SL Item updated, validate, unlock old, and lock new
   if update(SLItem)
   	begin
   	select @validcnt = count(*)
   	from bSLIT r
       join inserted i on i.Co = r.SLCo and i.SL = r.SL and i.SLItem = r.SLItem
   	if @validcnt <> @numrows
   	      begin
   	      select @errmsg = 'Subcontract Item is Invalid '
   	      goto error
   	      end
       -- unlock old SL Item if no longer in the batch
   	update bSLIT
   	set InUseBatchId = null, InUseMth = null
   	from deleted d
   	join bSLIT t on d.Co = t.SLCo and d.SL = t.SL and d.SLItem = t.SLItem 
   	where d.SLItem not in (select SLItem from bSLCB r where r.Co=d.Co
   			and r.SL=d.SL and r.SLItem=d.SLItem and r.Mth=d.Mth and r.BatchId=d.BatchId)
       -- lock new SL Item
   	update bSLIT
   	set InUseBatchId = i.BatchId, InUseMth = i.Mth
   	from inserted i
   	join bSLIT t on i.Co = t.SLCo and i.SL = t.SL and i.SLItem = t.SLItem
   	where t.InUseBatchId is null and t.InUseMth is null
   	end
   
   return
   
   error:
      select @errmsg = @errmsg + ' - cannot update SL Change Order Batch entry (bSLCB)'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction

GO
ALTER TABLE [dbo].[bSLCB] ADD CONSTRAINT [PK_bSLCB] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [IX_bSLCBBatchSeq] ON [dbo].[bSLCB] ([Co], [Mth], [BatchId], [BatchSeq]) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bSLCB].[CurUnitCost]'
GO
