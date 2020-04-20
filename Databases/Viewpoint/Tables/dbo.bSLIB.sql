CREATE TABLE [dbo].[bSLIB]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[SLItem] [dbo].[bItem] NOT NULL,
[BatchTransType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[ItemType] [tinyint] NOT NULL,
[Addon] [tinyint] NULL,
[AddonPct] [dbo].[bPct] NOT NULL,
[JCCo] [dbo].[bCompany] NOT NULL,
[Job] [dbo].[bJob] NOT NULL,
[PhaseGroup] [dbo].[bGroup] NOT NULL,
[Phase] [dbo].[bPhase] NOT NULL,
[JCCType] [dbo].[bJCCType] NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[UM] [dbo].[bUM] NOT NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[WCRetPct] [dbo].[bPct] NOT NULL,
[SMRetPct] [dbo].[bPct] NOT NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Supplier] [dbo].[bVendor] NULL,
[OrigUnits] [dbo].[bUnits] NOT NULL,
[OrigUnitCost] [dbo].[bUnitCost] NOT NULL,
[OrigCost] [dbo].[bDollar] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[OldItemType] [tinyint] NULL,
[OldAddon] [tinyint] NULL,
[OldAddonPct] [dbo].[bPct] NULL,
[OldJCCo] [dbo].[bCompany] NULL,
[OldJob] [dbo].[bJob] NULL,
[OldPhaseGroup] [dbo].[bGroup] NULL,
[OldPhase] [dbo].[bPhase] NULL,
[OldJCCType] [dbo].[bJCCType] NULL,
[OldDesc] [dbo].[bItemDesc] NULL,
[OldUM] [dbo].[bUM] NULL,
[OldGLCo] [dbo].[bCompany] NULL,
[OldGLAcct] [dbo].[bGLAcct] NULL,
[OldWCRetPct] [dbo].[bPct] NULL,
[OldSMRetPct] [dbo].[bPct] NULL,
[OldSupplier] [dbo].[bVendor] NULL,
[OldOrigUnits] [dbo].[bUnits] NULL,
[OldOrigUnitCost] [dbo].[bUnitCost] NULL,
[OldOrigCost] [dbo].[bDollar] NULL,
[TaxType] [tinyint] NULL,
[OldTaxType] [tinyint] NULL,
[TaxCode] [dbo].[bTaxCode] NULL,
[OldTaxCode] [dbo].[bTaxCode] NULL,
[TaxGroup] [dbo].[bGroup] NULL,
[OldTaxGroup] [dbo].[bGroup] NULL,
[OrigTax] [dbo].[bDollar] NULL,
[OldOrigTax] [dbo].[bDollar] NULL,
[JCCmtdTax] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bSLIB_JCCmtdTax] DEFAULT ((0.00)),
[OldJCCmtdTax] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bSLIB_OldJCCmtdTax] DEFAULT ((0.00)),
[TaxRate] [dbo].[bRate] NOT NULL CONSTRAINT [DF_bSLIB_TaxRate] DEFAULT ((0.00)),
[GSTRate] [dbo].[bRate] NOT NULL CONSTRAINT [DF_bSLIB_GSTRate] DEFAULT ((0.00)),
[OldTaxRate] [dbo].[bRate] NOT NULL CONSTRAINT [DF_bSLIB_OldTaxRate] DEFAULT ((0.00)),
[OldGSTRate] [dbo].[bRate] NOT NULL CONSTRAINT [DF_bSLIB_OldGSTRate] DEFAULT ((0.00)),
[JCRemCmtdTax] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bSLIB_JCRemCmtdTax] DEFAULT ((0.00)),
[OldJCRemCmtdTax] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bSLIB_OldJCRemCmtdTax] DEFAULT ((0.00))
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biSLIB] ON [dbo].[bSLIB] ([Co], [Mth], [BatchId], [BatchSeq], [SLItem]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btSLIBd    Script Date: 8/28/99 9:38:18 AM ******/
    
     CREATE   trigger [dbo].[btSLIBd] on [dbo].[bSLIB] for DELETE as
    
      

/***  basic declares for SQL Triggers ****/
     declare @numrows int, @errmsg varchar(255),
             @validcnt int, @validcnt2 int
    
    
    
     /*--------------------------------------------------------------
      *
      *  Delete trigger for SLIB
      *  Created By: kb 9/13/98
      *  Modified : kb 3/10/99
      *             jre 5/12/99 - some slit records are already deleted so can't update inuse
      *
      *--------------------------------------------------------------*/
      select @numrows = @@rowcount
      if @numrows = 0 return
    
     set nocount on
    
    
     select @validcnt2 = count(*) from deleted d  where d.BatchTransType='C'
    
     update bSLIT
     set InUseMth=null, InUseBatchId=null from deleted d, bSLHB h, bSLIT t
             where d.Co=h.Co and d.Mth=h.Mth and d.BatchId=h.BatchId and d.BatchSeq=h.BatchSeq and
     	t.SLCo=h.Co and t.SL=h.SL and t.SLItem=d.SLItem and d.BatchTransType in ('C','D')
    /*if @@rowcount<>@validcnt2   -----took this out because user may be clearing out batch
                                    after setting the BatchTransType to 'D', Jim and I
                                    decided that this check really isn't that important
                                    and the consequences of keeping it in could be worse.
                                    per issue #10349
     	begin
     	select @errmsg = 'Unable to remove InUse Flag from SL Item.'
    
     	goto error
     	end*/
    
    
     return
    
     error:
        select @errmsg = @errmsg + ' - cannot remove SL Item Batch'
        RAISERROR(@errmsg, 11, -1);
        rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   CREATE       trigger [dbo].[btSLIBi] on [dbo].[bSLIB] for INSERT as
    

/****************************************************
     * Created: SE 6/4/97
     * Modified: GG 04/18/02 - #17050 cleanup
     *				kb 6/10/2 - issue #17602
     *			  GF 09/25/2002 - issue #18678 duplicate index error in HQCC.
     *
     * Insert trigger for SL Entry Item batch entries
     *
     ****************************************************/
    
    declare @numrows int, @errmsg varchar(255), @validcnt int
    
    select @numrows = @@rowcount
    if @numrows = 0 return
    
    set nocount on
    
    -- SL Entry Batch Header must exist
    select @validcnt = count(*)
    from bSLHB r
    JOIN inserted i ON i.Co = r.Co and i.Mth = r.Mth and i.BatchId = r.BatchId and i.BatchSeq = r.BatchSeq
    if @validcnt <> @numrows
     	begin
     	select @errmsg = 'Invalid SL Entry Batch header'
     	goto error
     	end
    
    -- add HQ Close Control for GL Co#s referenced by SL Item
    insert bHQCC (Co, Mth, BatchId, GLCo)
    select Co, Mth, BatchId, GLCo
    from inserted
    where GLCo not in (select h.GLCo from bHQCC h join inserted i on h.Co = i.Co and h.Mth = i.Mth 
    						and h.BatchId = i.BatchId)
    group by Co, Mth, BatchId, GLCo
   
    -- lock existing SL Items, unless the batch is from a PM Interface 
    -- PM may create both an Entry and Change Order batch in the same interface, so don't lock the Header
    update bSLIT
    set InUseMth = i.Mth, InUseBatchId = i.BatchId 
    from inserted i
    join bSLHB s on s.Co = i.Co and s.Mth = i.Mth and s.BatchId = i.BatchId
    and s.BatchSeq = i.BatchSeq
    join bSLHD h on h.SLCo = s.Co and h.SL = s.SL 
    join bSLIT t on t.SLCo = h.SLCo and t.SL = h.SL and t.SLItem = i.SLItem
    join bHQBC b on b.Co = i.Co and b.Mth = i.Mth and b.BatchId = i.BatchId
    where t.InUseMth is null and t.InUseBatchId is null
    	and b.Source <> 'PM Intface'
    
    return
    
    error:
       select @errmsg = @errmsg + ' - cannot insert SL Item Batch'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   /****** Object:  Trigger dbo.btSLIBu    Script Date: 8/28/99 9:38:18 AM ******/
    CREATE   trigger [dbo].[btSLIBu] on [dbo].[bSLIB] for UPDATE as
    
     

/***  basic declares for SQL Triggers ****/
    declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15),
            @errno tinyint, @audit bYN, @validcnt int, @validcnt2 int, @typecnt int,
            @keyco bCompany, @keymth bMonth, @keybatchid bBatchID, @glco bCompany
    
    /*--------------------------------------------------------------
     *
     *  Update trigger for SLIB
     *  Created By: SE
     *  Date: 6/4/97
     *  Modified by: kb 1/4/99
     *				  MV 06/06/03 - #17050 - clean up pseudo cursor
     *
     *--------------------------------------------------------------*/
     select @numrows = @@rowcount
     if @numrows = 0 return
     set nocount on
    
    /* check for key changes */
    select @validcnt = count(*) from deleted d, inserted i
    	where d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId
    	and d.BatchSeq = i.BatchSeq and d.SLItem=i.SLItem
    
    if @numrows <> @validcnt
    	begin
    	select @errmsg = 'Cannot change Company, Month, Batch ID #, Batch Sequence # or SLItem'
    	goto error
    	end
   
   -- add HQ Close Control for GL Co#s referenced by SL Item
     insert bHQCC (Co, Mth, BatchId, GLCo)
     select Co, Mth, BatchId, GLCo
     from inserted
     where GLCo not in (select h.GLCo from bHQCC h join inserted i on h.Co = i.Co and h.Mth = i.Mth 
     						and h.BatchId = i.BatchId)
     group by Co, Mth, BatchId, GLCo
    
   /* select @keyco = min(Co) from inserted
    while @keyco is not null
    	begin
    	select @keymth = min(Mth) from inserted where Co = @keyco
    	while @keymth is not null
    		begin
    		select @keybatchid = min(BatchId) from inserted where Co = @keyco and Mth = @keymth
    		while @keybatchid is not null
    			begin
    			select @glco = i. GLCo
    			  from inserted i where i.Co = @keyco and i.Mth = @keymth and i.BatchId = @keybatchid
    
    			-- insert the HQCC record for the GL Company for the CM account 
    			if not exists(select * from bHQCC where Co = @keyco and Mth = @keymth and BatchId = @keybatchid
    			  and GLCo = @glco)
    				begin
    				insert bHQCC (Co, Mth, BatchId, GLCo)
    				values (@keyco, @keymth, @keybatchid, @glco)
    				end
    			select @keybatchid = min(BatchId) from inserted where Co = @keyco and  Mth = @keymth
    				and BatchId > @keybatchid
    			if @@rowcount = 0 select @keybatchid = null
    			end
    		select @keymth = min(Mth) from inserted where Co = @keyco and Mth > @keymth
    		if @@rowcount = 0 select @keymth = null
    		end
    	select @keyco = min(Co) from inserted where Co > @keyco
    	if @@rowcount = 0 select @keyco = null
    	end*/
   
   
    
    return
    
    error:
       select @errmsg = @errmsg + ' - cannot update SL Item Batch'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
    
    
    
   
   
   
  
 



GO

EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bSLIB].[OrigUnitCost]'
GO
