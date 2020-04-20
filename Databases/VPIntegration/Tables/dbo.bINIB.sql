CREATE TABLE [dbo].[bINIB]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[MOItem] [dbo].[bItem] NOT NULL,
[BatchTransType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[Loc] [dbo].[bLoc] NOT NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[Material] [dbo].[bMatl] NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[JCCo] [dbo].[bCompany] NOT NULL,
[Job] [dbo].[bJob] NOT NULL,
[PhaseGroup] [dbo].[bGroup] NOT NULL,
[Phase] [dbo].[bPhase] NOT NULL,
[JCCType] [dbo].[bJCCType] NOT NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[ReqDate] [dbo].[bDate] NULL,
[UM] [char] (3) COLLATE Latin1_General_BIN NOT NULL,
[OrderedUnits] [dbo].[bUnits] NOT NULL,
[UnitPrice] [dbo].[bUnitCost] NOT NULL,
[ECM] [dbo].[bECM] NOT NULL,
[TotalPrice] [dbo].[bDollar] NOT NULL,
[TaxGroup] [dbo].[bGroup] NULL,
[TaxCode] [dbo].[bTaxCode] NULL,
[TaxAmt] [dbo].[bDollar] NOT NULL,
[RemainUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bINIB_RemainUnits] DEFAULT ((0)),
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[OldLoc] [dbo].[bLoc] NULL,
[OldMatlGroup] [dbo].[bGroup] NULL,
[OldMaterial] [dbo].[bMatl] NULL,
[OldDesc] [dbo].[bItemDesc] NULL,
[OldJCCo] [dbo].[bCompany] NULL,
[OldJob] [dbo].[bJob] NULL,
[OldPhaseGroup] [dbo].[bGroup] NULL,
[OldPhase] [dbo].[bPhase] NULL,
[OldJCCType] [dbo].[bJCCType] NULL,
[OldGLCo] [dbo].[bCompany] NULL,
[OldGLAcct] [dbo].[bGLAcct] NULL,
[OldReqDate] [dbo].[bDate] NULL,
[OldUM] [char] (3) COLLATE Latin1_General_BIN NULL,
[OldOrderedUnits] [dbo].[bUnits] NULL,
[OldUnitPrice] [dbo].[bUnitCost] NULL,
[OldECM] [dbo].[bECM] NULL,
[OldTotalPrice] [dbo].[bDollar] NULL,
[OldTaxGroup] [dbo].[bGroup] NULL,
[OldTaxCode] [dbo].[bTaxCode] NULL,
[OldTaxAmt] [dbo].[bDollar] NULL,
[OldRemainUnits] [dbo].[bUnits] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   CREATE trigger [dbo].[btINIBd] on [dbo].[bINIB] for DELETE as
   

/****************************************************
    *  Created: GG 04/29/02
    *  Modified: 
    *
    *	Delete trigger on Material Order Item Batch table
    *
    ***************************************************/
   
   declare @numrows int, @errmsg varchar(255)
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   -- unlock existing MO Items pulled into batch for change or delete
   if exists (select 1 from deleted where BatchTransType in ('C','D'))
   	begin
   	update bINMI
   	set InUseMth = null, InUseBatchId = null
   	from deleted d
   	join bINMB h on d.Co = h.Co and d.Mth = h.Mth and d.BatchId = h.BatchId and d.BatchSeq = h.BatchSeq
   	join bINMI t on t.INCo = h.Co and t.MO = h.MO and t.MOItem = d.MOItem
   	end
   
   return
   
   error:
      select @errmsg = @errmsg + ' - cannot delete Material Order Item Batch entry (bINIB)'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   CREATE   trigger [dbo].[btINIBi] on [dbo].[bINIB] for INSERT as
   

/***************************************************************
    *	Created: GG 04/29/02
    *  Modified: 
    *
    *	Insert trigger for Material Order Item Batch
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
   -- make sure MO Header Batch entry exists
   select @validcnt = count(*)
   from inserted i
   join bINMB h on h.Co = i.Co and h.Mth = i.Mth and h.BatchId = i.BatchId and h.BatchSeq = i.BatchSeq
   if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Missing Material Order Header Batch entry'
    	goto error
    	end
   -- validate Batch Trans Type
   if exists(select 1 from inserted where BatchTransType not in ('A','C','D'))
   	begin
    	select @errmsg = 'Invalid Batch Transaction Type, must be ''A'',''C'', or ''D'''
    	goto error
    	end
   
   -- add HQ Close Control for GL Co#s referenced by MO Item
   insert bHQCC (Co, Mth, BatchId, GLCo)
   select Co, Mth, BatchId, GLCo
   from inserted 
   where GLCo not in (select h.GLCo from bHQCC h join inserted i on h.Co = i.Co and h.Mth = i.Mth 
   						and h.BatchId = i.BatchId)
   
   -- lock existing MO Items 
   select @validcnt = count(*)
   from inserted 
   where BatchTransType in ('C','D')
   if @validcnt <> 0
   	begin
   	update bINMI
   	set InUseMth = i.Mth, InUseBatchId = i.BatchId 
   	from inserted i
   	join bINMB h on h.Co = i.Co and h.Mth = i.Mth and h.BatchId = i.BatchId and h.BatchSeq = i.BatchSeq
   	join bINMI t on t.INCo = i.Co and t.MO = h.MO and t.MOItem = i.MOItem
   	where t.InUseMth is null and t.InUseBatchId is null
   		and i.BatchTransType in ('C','D')
   	if @@rowcount <> @validcnt
   	 	begin
   	 	select @errmsg = 'Unable to lock Material Order Item'
   	 	goto error
   	 	end
   	end	
   
   return
   
   error:
      select @errmsg = @errmsg + ' - cannot insert Material Order Item Batch entry (bINIB)'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   CREATE trigger [dbo].[btINIBu] on [dbo].[bINIB] for UPDATE as 
   

/*-------------------------------------------------------------- 
    *  Created: GG 04/29/02     
    *  Modified: 
    *
    *	Update trigger on Material Order Item Batch
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
   	and d.BatchSeq = i.BatchSeq and d.MOItem=i.MOItem
   if @numrows <> @validcnt
   	begin
   	select @errmsg = 'Cannot change Company, Month, Batch ID #, Batch Sequence # or MO Item'
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
   
   return
   
   error:
      select @errmsg = @errmsg + ' - cannot update Material Order Item Batch entry (bINIB)'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biINIB] ON [dbo].[bINIB] ([Co], [Mth], [BatchId], [BatchSeq], [MOItem]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bINIB].[ECM]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bINIB].[OldECM]'
GO
