CREATE TABLE [dbo].[bPOIB]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[POItem] [dbo].[bItem] NOT NULL,
[BatchTransType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[ItemType] [tinyint] NOT NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[Material] [dbo].[bMatl] NULL,
[VendMatId] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[Description] [dbo].[bItemDesc] NULL,
[UM] [dbo].[bUM] NOT NULL,
[RecvYN] [dbo].[bYN] NOT NULL,
[PostToCo] [dbo].[bCompany] NOT NULL,
[Loc] [dbo].[bLoc] NULL,
[Job] [dbo].[bJob] NULL,
[PhaseGroup] [dbo].[bGroup] NULL,
[Phase] [dbo].[bPhase] NULL,
[JCCType] [dbo].[bJCCType] NULL,
[Equip] [dbo].[bEquip] NULL,
[CompType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Component] [dbo].[bEquip] NULL,
[EMGroup] [dbo].[bGroup] NULL,
[CostCode] [dbo].[bCostCode] NULL,
[EMCType] [dbo].[bEMCType] NULL,
[WO] [dbo].[bWO] NULL,
[WOItem] [dbo].[bItem] NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NULL,
[ReqDate] [dbo].[bDate] NULL,
[TaxGroup] [dbo].[bGroup] NULL,
[TaxCode] [dbo].[bTaxCode] NULL,
[TaxType] [tinyint] NULL,
[OrigUnits] [dbo].[bUnits] NOT NULL,
[OrigUnitCost] [dbo].[bUnitCost] NOT NULL,
[OrigECM] [dbo].[bECM] NULL,
[OrigCost] [dbo].[bDollar] NOT NULL,
[OrigTax] [dbo].[bDollar] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[OldItemType] [tinyint] NULL,
[OldMatlGroup] [dbo].[bGroup] NULL,
[OldMaterial] [dbo].[bMatl] NULL,
[OldVendMatId] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[OldDesc] [dbo].[bItemDesc] NULL,
[OldUM] [dbo].[bUM] NULL,
[OldRecvYN] [dbo].[bYN] NULL,
[OldPostToCo] [dbo].[bCompany] NULL,
[OldLoc] [dbo].[bLoc] NULL,
[OldJob] [dbo].[bJob] NULL,
[OldPhaseGroup] [dbo].[bGroup] NULL,
[OldPhase] [dbo].[bPhase] NULL,
[OldJCCType] [dbo].[bJCCType] NULL,
[OldEquip] [dbo].[bEquip] NULL,
[OldCompType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[OldComponent] [dbo].[bEquip] NULL,
[OldEMGroup] [dbo].[bGroup] NULL,
[OldCostCode] [dbo].[bCostCode] NULL,
[OldEMCType] [dbo].[bEMCType] NULL,
[OldWO] [dbo].[bWO] NULL,
[OldWOItem] [dbo].[bItem] NULL,
[OldGLCo] [dbo].[bCompany] NULL,
[OldGLAcct] [dbo].[bGLAcct] NULL,
[OldReqDate] [dbo].[bDate] NULL,
[OldTaxGroup] [dbo].[bGroup] NULL,
[OldTaxCode] [dbo].[bTaxCode] NULL,
[OldTaxType] [tinyint] NULL,
[OldOrigUnits] [dbo].[bUnits] NULL,
[OldOrigUnitCost] [dbo].[bUnitCost] NULL,
[OldOrigECM] [dbo].[bECM] NULL,
[OldOrigCost] [dbo].[bDollar] NULL,
[OldOrigTax] [dbo].[bDollar] NULL,
[RequisitionNum] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[OldRequisitionNum] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[PayCategory] [int] NULL,
[OldPayCategory] [int] NULL,
[PayType] [tinyint] NULL,
[OldPayType] [tinyint] NULL,
[INCo] [dbo].[bCompany] NULL,
[EMCo] [dbo].[bCompany] NULL,
[JCCo] [dbo].[bCompany] NULL,
[JCCmtdTax] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPOIB_JCCmtdTax] DEFAULT ((0.00)),
[OldJCCmtdTax] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPOIB_OldJCCmtdTax] DEFAULT ((0.00)),
[Supplier] [dbo].[bVendor] NULL,
[SupplierGroup] [dbo].[bGroup] NULL,
[JCRemCmtdTax] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPOIB_JCRemCmtdTax] DEFAULT ((0.00)),
[OldJCRemCmtdTax] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPOIB_OldJCRemCmtdTax] DEFAULT ((0.00)),
[TaxRate] [dbo].[bRate] NOT NULL CONSTRAINT [DF_bPOIB_TaxRate] DEFAULT ((0.00)),
[GSTRate] [dbo].[bRate] NOT NULL CONSTRAINT [DF_bPOIB_GSTRate] DEFAULT ((0.00)),
[OldTaxRate] [dbo].[bRate] NOT NULL CONSTRAINT [DF_bPOIB_OldTaxRate] DEFAULT ((0.00)),
[OldGSTRate] [dbo].[bRate] NOT NULL CONSTRAINT [DF_bPOIB_OldGSTRate] DEFAULT ((0.00)),
[SMCo] [dbo].[bCompany] NULL,
[SMWorkOrder] [int] NULL,
[SMScope] [int] NULL,
[OldSMCo] [dbo].[bCompany] NULL,
[OldSMWorkOrder] [int] NULL,
[OldScope] [int] NULL,
[SMPhaseGroup] [dbo].[bGroup] NULL,
[SMPhase] [dbo].[bPhase] NULL,
[SMJCCostType] [dbo].[bJCCType] NULL,
[OldSMPhaseGroup] [dbo].[bGroup] NULL,
[OldSMPhase] [dbo].[bPhase] NULL,
[OldSMJCCostType] [dbo].[bJCCType] NULL,
[udOnDate] [dbo].[bDate] NULL,
[udPlnOffDate] [dbo].[bDate] NULL,
[udActOffDate] [dbo].[bDate] NULL,
[udRentalNum] [varchar] (32) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btPOIBd    Script Date: 8/28/99 9:38:07 AM ******/
     CREATE       trigger [dbo].[btPOIBd] on [dbo].[bPOIB] for DELETE as
     

/****************************************************
      *  Created: SE 5/14/97
      *  Modified: EN 3/26/99
      *            kb 8/28/00 issue #10349
      *			GG 04/29/02 - #17051 - cleanup
      *			DC 10/07/04 - #20981 - Clear PO and POItem in RQRL if PO Item is deleted from a PO Add Batch
      *			DC 12/22/2008 - #130129 - Combine RQ and PO into a single module
      *
      *	Delete trigger on PO Item Batch table
      *
      ***************************************************/
     declare @numrows int, @errmsg varchar(255)
     
     select @numrows = @@rowcount
     if @numrows = 0 return
     
     set nocount on
     
     -- unlock existing PO Items pulled into batch for change or delete
     if exists (select 1 from deleted where BatchTransType in ('C','D'))
     	begin
     	update bPOIT
     	set InUseMth = null, InUseBatchId = null
     	from deleted d
     	join bPOHB h on d.Co = h.Co and d.Mth = h.Mth and d.BatchId = h.BatchId and d.BatchSeq = h.BatchSeq
     	join bPOIT t on t.POCo = h.Co and t.PO = h.PO and t.POItem = d.POItem
     	end
     
   --  Need to reset RQRL
   	-- first check to see if the POIB company exist in RQCO.  If the customer does not have RQ then 
   	-- I don't want to add additional overhead to this trigger.
   	--DC #130129
   	--if exists(SELECT top 1 1 FROM deleted d join RQCO c with (NOLOCK) on c.RQCo = d.Co)
   	--	BEGIN
   		-- IF the deleted record, exists in RQRL and does not exist in POIT and BatchTransType = A, then 
   		-- reset PO and POItem in RQRL
   		if exists(SELECT top 1 1 
   					FROM deleted d 
   						join POHB h with (NOLOCK) on d.Co = h.Co and d.Mth = h.Mth and d.BatchId = h.BatchId and d.BatchSeq = h.BatchSeq				
   						join RQRL r with (NOLOCK) on h.PO = r.PO and d.POItem = r.POItem and r.RQCo = d.Co
   						left join POIT t with (NOLOCK) on t.POCo = d.Co and t.POItem = d.POItem and t.PO = h.PO 
   					WHERE d.BatchTransType = 'A' and t.POItem is null)
   			BEGIN
   				UPDATE RQRL
   				Set PO = null, POItem = null
   				FROM RQRL r with (NOLOCK)
   					join deleted d on d.Co = r.RQCo and r.POItem = d.POItem
   					join POHB h with (NOLOCK) on d.Co = h.Co and d.Mth = h.Mth and d.BatchId = h.BatchId and d.BatchSeq = h.BatchSeq and r.PO = h.PO
   				WHERE r.PO is not null
   					and r.POItem is not null
   					and d.BatchTransType = 'A'
   			END
   	--	END
   
     return
     
     error:
        select @errmsg = @errmsg + ' - cannot delete PO Item Batch entry (bPOIB)'
        RAISERROR(@errmsg, 11, -1);
        rollback transaction
     
    
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   /****** Object:  Trigger dbo.btPOIBi    Script Date: 8/28/99 9:38:07 AM ******/
   CREATE      trigger [dbo].[btPOIBi] on [dbo].[bPOIB] for INSERT as
   

/***************************************************************
    *	Created: SE 5/14/97
    *  Modified: kb 1/4/99
    *			GG 04/18/02 - #17051 cleanup, removed pseudo-cursor used to lock bPOHD
     *			GF 09/25/2002 - issue #18678 duplicate index error in HQCC.
    *
    *	Insert trigger for PO Item Batch
    *
    ***************************************************************/
   declare @numrows int, @errmsg varchar(255), @validcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   -- validate Batch
   select @validcnt = count(*)
   from bHQBC r
   JOIN inserted i ON i.Co = r.Co and i.Mth = r.Mth and i.BatchId = r.BatchId
   where r.Status = 0
   if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Invalid Batch or incorrect status, must be ''open'''
    	goto error
    	end
   
   -- make sure PO Header Batch entry exists
   select @validcnt = count(*)
   from inserted i
   join bPOHB h on h.Co = i.Co and h.Mth = i.Mth and h.BatchId = i.BatchId and h.BatchSeq = i.BatchSeq
   if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Missing PO Header Batch entry'
    	goto error
    	end
   
   -- validate Batch Trans Type
   if exists(select 1 from inserted where BatchTransType not in ('A','C','D'))
   	begin
    	select @errmsg = 'Invalid Batch Transaction Type, must be ''A'',''C'', or ''D'''
    	goto error
    	end
   
   -- add HQ Close Control for GL Co#s referenced by PO Item
   insert bHQCC (Co, Mth, BatchId, GLCo)
   select Co, Mth, BatchId, GLCo
   from inserted 
   where GLCo not in (select h.GLCo from bHQCC h join inserted i on h.Co = i.Co and h.Mth = i.Mth 
   						and h.BatchId = i.BatchId)
   group by Co, Mth, BatchId, GLCo
   
   -- lock existing PO Items 
   select @validcnt = count(*)
   from inserted 
   where BatchTransType in ('C','D')
   if @validcnt <> 0
   	begin
   	update bPOIT
   	set InUseMth = i.Mth, InUseBatchId = i.BatchId 
   	from inserted i
   	join bPOHB h on h.Co = i.Co and h.Mth = i.Mth and h.BatchId = i.BatchId and h.BatchSeq = i.BatchSeq
   	join bPOIT t on t.POCo = i.Co and t.PO = h.PO and t.POItem = i.POItem
   	where t.InUseMth is null and t.InUseBatchId is null
   		and i.BatchTransType in ('C','D')
   	if @@rowcount <> @validcnt
   	 	begin
   	 	select @errmsg = 'Unable to lock Purchase Order Item'
   	 	goto error
   	 	end
   	end	
   
   return
   
   error:
      select @errmsg = @errmsg + ' - cannot insert PO Item Batch entry (bPOIB)'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   CREATE   trigger [dbo].[btPOIBu] on [dbo].[bPOIB] for UPDATE as 
   

/*-------------------------------------------------------------- 
    *  Created: SE 5/14/97      
    *  Modified: kb 1/4/99
    *			GG 04/29/02 - #17051 - cleanup, remove pseudo curso
    *            bc 5/6/3 - #20794
    *
    *	Update trigger on PO Item Batch
    *
    *--------------------------------------------------------------*/
   declare @numrows int, @errmsg varchar(255), @validcnt int
           
   select @numrows = @@rowcount 
   if @numrows = 0 return
   
   set nocount on
    
   /* check for key changes */
   select @validcnt = count(*)
   from deleted d
   join inserted i on d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId 
   	and d.BatchSeq = i.BatchSeq and d.POItem=i.POItem
   if @numrows <> @validcnt
   	begin
   	select @errmsg = 'Cannot change Company, Month, Batch ID #, Batch Sequence # or PO Item'
   	goto error 
   	end
   -- check Batch Transaction Type
   select @validcnt = count(*) from inserted i where i.BatchTransType in ('A','C','D')
   if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Batch Transaction Type must be ''A'',''C'', or ''D'''
    	goto error
    	end
   -- check for change
   select @validcnt = count(*) from deleted d, inserted i
   where d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId and d.BatchSeq = i.BatchSeq and d.POItem = i.POItem
       and (d.BatchTransType = 'A' and i.BatchTransType in ('C','D'))
   if @validcnt > 0
       begin
       select @errmsg = 'Cannot change Batch Transaction Type from ''A'' to ''C'' or ''D'''
       goto error
       end
   select @validcnt = count(*) from deleted d, inserted i
   where d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId and d.BatchSeq = i.BatchSeq and d.POItem = i.POItem
       and (i.BatchTransType = 'A' and d.BatchTransType in ('C','D'))
   if @validcnt > 0
    	begin
    	select @errmsg = 'Cannot change Batch Transaction Type from ''C'' or ''D'' to ''A'''
    	goto error
    	end
   
   return
   
   error:
      select @errmsg = @errmsg + ' - cannot update PO Item Batch entry (bPOIB)'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biPOIB] ON [dbo].[bPOIB] ([Co], [Mth], [BatchId], [BatchSeq], [POItem]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bPOIB] WITH NOCHECK ADD CONSTRAINT [FK_bPOIB_vSMWorkOrderScope] FOREIGN KEY ([SMCo], [SMWorkOrder], [SMScope]) REFERENCES [dbo].[vSMWorkOrderScope] ([SMCo], [WorkOrder], [Scope])
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPOIB].[RecvYN]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPOIB].[OrigUnitCost]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bPOIB].[OrigECM]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPOIB].[OrigTax]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPOIB].[OldRecvYN]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bPOIB].[OldOrigECM]'
GO
