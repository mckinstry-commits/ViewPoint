CREATE TABLE [dbo].[bINCB]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[BatchTransType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[INTrans] [dbo].[bTrans] NULL,
[MO] [dbo].[bMO] NOT NULL,
[MOItem] [dbo].[bItem] NOT NULL,
[Loc] [dbo].[bLoc] NOT NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[Material] [dbo].[bMatl] NOT NULL,
[UM] [dbo].[bUM] NOT NULL,
[ConfirmDate] [dbo].[bDate] NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[ConfirmUnits] [dbo].[bUnits] NOT NULL,
[RemainUnits] [dbo].[bUnits] NOT NULL,
[UnitPrice] [dbo].[bUnitCost] NOT NULL,
[ECM] [dbo].[bECM] NOT NULL,
[ConfirmTotal] [dbo].[bDollar] NOT NULL,
[StkUM] [dbo].[bUM] NOT NULL,
[StkUnits] [dbo].[bUnits] NOT NULL,
[StkUnitCost] [dbo].[bUnitCost] NOT NULL,
[StkECM] [dbo].[bECM] NOT NULL,
[StkTotalCost] [dbo].[bDollar] NOT NULL,
[OldMO] [dbo].[bMO] NULL,
[OldMOItem] [dbo].[bItem] NULL,
[OldLoc] [dbo].[bLoc] NULL,
[OldMatlGroup] [dbo].[bGroup] NULL,
[OldMaterial] [dbo].[bMatl] NULL,
[OldUM] [dbo].[bUM] NULL,
[OldConfirmDate] [dbo].[bDate] NULL,
[OldDesc] [dbo].[bItemDesc] NULL,
[OldConfirmUnits] [dbo].[bUnits] NULL,
[OldRemainUnits] [dbo].[bUnits] NULL,
[OldUnitPrice] [dbo].[bUnitCost] NULL,
[OldECM] [dbo].[bECM] NULL,
[OldConfirmTotal] [dbo].[bDollar] NULL,
[OldStkUM] [dbo].[bUM] NULL,
[OldStkUnits] [dbo].[bUnits] NULL,
[OldStkUnitCost] [dbo].[bUnitCost] NULL,
[OldStkECM] [dbo].[bECM] NULL,
[OldStkTotalCost] [dbo].[bDollar] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   
   CREATE   trigger [dbo].[btINCBd] on [dbo].[bINCB] for DELETE as
   

/*****************************************************
    *	Created: GG 04/16/02
    *	Modified:	GP 05/15/09 - Issue 133436 Removed HQAT delete, added new insert
    *
    *	Delete trigger on IN MO Confirmation Batch entries
    *
    *****************************************************/
   
   declare @numrows int, @errmsg varchar(255)
     
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   -- unlock IN Detail entries
   update bINDT
   set InUseBatchId = null
   from bINDT t
   join deleted d on t.INCo = d.Co and t.Mth = d.Mth and t.INTrans = d.INTrans
   
   -- unlock MO Item if all entries for the Item have been removed
   update bINMI
   set InUseMth = null, InUseBatchId = null
   from bINMI i
   join deleted d on i.INCo = d.Co and i.MO = d.MO and i.MOItem = d.MOItem
   where not exists (select 1 from bINCB b where b.Co = d.Co and b.Mth = d.Mth 
   						and b.BatchId = d.BatchId and b.MO = d.MO and b.MOItem = d.MOItem) 
   
   -- unlock MO Header if all entries have been removed
   update bINMO
   set InUseMth = null, InUseBatchId = null
   from bINMO o
   join deleted d on o.INCo = d.Co and o.MO = d.MO 
   where o.MO not in (select b.MO from bINCB b where b.Co = d.Co and b.Mth = d.Mth 
   						and b.BatchId = d.BatchId) 
   
	-- Delete attachments if they exist. Make sure UniqueAttchID is not null.
	insert vDMAttachmentDeletionQueue (AttachmentID, UserName, DeletedFromRecord)
    select AttachmentID, suser_name(), 'Y' 
	from bHQAT h join deleted d on h.UniqueAttchID = d.UniqueAttchID
	where h.UniqueAttchID not in(select t.UniqueAttchID from bINDT t join deleted d1 on t.UniqueAttchID = d1.UniqueAttchID)
		and d.UniqueAttchID is not null   

   
   return
   
   error:
       select @errmsg = @errmsg + ' - cannot delete IN Confirmation Batch entry (bINCB)'
   
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

 
  
   
   CREATE trigger [dbo].[btINCBi] on [dbo].[bINCB] for INSERT as
    

/*******************************************************
     *	Created:  GG  04/16/2002
     *	Modified: GWC 05/18/2004 #24497: Moved calculations for ConfirmTotal, StkUnits and
     *							 		 StkTotalCost from the frontend to the backend where they belong.
     *			  GF 08/03/2012 TK-16643 change to get conversion factor from INMU
     *
     *
     * Insert trigger for IN MO Confirmation Batch entries
     *
     **********************************************************/
    
    declare @numrows int, @errmsg varchar(255), @validcnt int,
			 @convfactor bUnitCost, @msgout varchar(255), @rcode int,
			 @material bMatl, @matlgroup bGroup, @um bUM
			 ,@co bCompany, @loc bLoc
    
    select @numrows = @@rowcount
    if @numrows = 0 return
      
    set nocount on
    
    select @rcode = 0
   
    --validate batch 
    select @validcnt = count(*)
    from bHQBC r
    JOIN inserted i ON i.Co=r.Co and i.Mth=r.Mth and i.BatchId=r.BatchId
    where r.Status = 0
    if @validcnt<>@numrows
    	begin
    	select @errmsg = 'Invalid or ''closed'' Batch.'
    	goto error
    	end
   
    ---- TK-16643 retrieve the insert Material, MatlGroup and the UM to retrieve the Conversion factor
    SELECT @material = i.Material, @matlgroup = i.MatlGroup, @um = i.UM
			,@co = i.Co, @loc = Loc
    FROM inserted i
   
	----TK-16643 retrieve the Conversion Factor to be used in calculating StkUnits and StkTotalCost
	EXEC @rcode = dbo.bspINMOMatlUMVal @co, @loc, @material, @matlgroup, @um, NULL, NULL, @convfactor OUTPUT, NULL, NULL, @msgout OUTPUT
    if @rcode = 1
    	begin
     	select @errmsg = @msgout
     	goto error
     	end
	
    --retrieve the Conversion Factor to be used in calculating StkUnits and StkTotalCost
    --exec @rcode = dbo.bspINMatlUMVal @material, @matlgroup, @um, @convfactor output, null, null, null, null, @msgout output
    --if @rcode = 1
    --	begin
    -- 	select @errmsg = @msgout
    -- 	goto error
    -- 	end
    
    --calculate ConfirmTotal, StkUnits and StkTotalCost from values being posted
    update bINCB 
   	--ConfirmTotal
       set ConfirmTotal = (i.ConfirmUnits * i.UnitPrice/(case i.ECM when 'E'
    	then 1 when 'C' then 100 when 'M' then 1000 end)),  
   	--StkUnits
   	StkUnits = (i.ConfirmUnits * @convfactor),
       --StkTotalCost
   	StkTotalCost = ((i.ConfirmUnits * @convfactor) * i.StkUnitCost/(case i.StkECM
   	when 'E' then 1 when 'C' then 100 when 'M' then 1000 end))
   
   	from bINCB b, inserted i
   	where b.Co = i.Co and b.Mth = i.Mth and b.BatchId = i.BatchId and b.BatchSeq = i.BatchSeq
    
    -- add HQ Close Control for IN GL Co#
    insert bHQCC (Co, Mth, BatchId, GLCo)
    select i.Co, i.Mth, i.BatchId, c.GLCo
    from inserted i
    join bINCO c on i.Co = c.INCo
    where c.GLCo not in (select h.GLCo from bHQCC h join inserted i on h.Co = i.Co and h.Mth = i.Mth 
    						and h.BatchId = i.BatchId)
    
    -- add HQ Close Control for JC GL Co#s referenced by MO Items
    insert bHQCC (Co, Mth, BatchId, GLCo)
    select i.Co, i.Mth, i.BatchId, c.GLCo
    from inserted i
    join bINMI c on i.Co = c.INCo and i.MO = c.MO and i.MOItem = c.MOItem
    where c.GLCo not in (select h.GLCo from bHQCC h join inserted i on h.Co = i.Co and h.Mth = i.Mth 
    						and h.BatchId = i.BatchId)
    
    --lock existing bINDT Confirmation entries pulled into batch
    select @validcnt = count(*) from inserted where BatchTransType in ('C','D')
    if @validcnt <> 0
    	begin
    	update bINDT
    	set InUseBatchId = i.BatchId
    	from bINDT d
    	join inserted i on i.Co = d.INCo and i.Mth = d.Mth and i.INTrans = d.INTrans
    	if @@rowcount <> @validcnt
     		begin
     		select @errmsg = 'Unable to lock IN Detail'
     		goto error
     		end
     	end
    
    --lock MO Header
    update bINMO
    set InUseMth = i.Mth, InUseBatchId = i.BatchId 
    from bINMO h
    join inserted i on i.Co = h.INCo and i.MO = h.MO
    where h.InUseMth is null and h.InUseBatchId is null
    
    --lock MO Item
    update bINMI
    set InUseMth = i.Mth, InUseBatchId = i.BatchId
    from bINMI h
    join inserted i on i.Co = h.INCo and i.MO = h.MO and i.MOItem = h.MOItem
    where h.InUseMth is null and h.InUseBatchId is null
    
    return
    
    error:
        select @errmsg = @errmsg + ' - cannot insert IN Confirmation Batch entry (bINCB)'
        RAISERROR(@errmsg, 11, -1);
        rollback transaction
    
    
    
    
    
    
    
   
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

 
  
   
   CREATE trigger [dbo].[btINCBu] on [dbo].[bINCB] for UPDATE as
    

/************************************************
     *  Created: GG  04/16/2002
     * Modified: GWC 05/18/2004 #24497: Moved calculations for ConfirmTotal, StkUnits and
     *							 		 StkTotalCost from the frontend to the backend where they belong.
     *			  GF 08/03/2012 TK-16643 change to get conversion factor from INMU
     *
     * Update trigger on IN MO Confirmation Batch
     *
     **********************************************/
    
    declare @numrows int,@errmsg varchar(255), @validcnt int,
   		 @convfactor bUnitCost, @msgout varchar(255), @rcode int,
   		 @material bMatl, @matlgroup bGroup, @um bUM
		 ,@co bCompany, @loc bLoc
    
    select @numrows = count(*) from inserted
    if @numrows = 0 return
    
    set nocount on
    
    /* check for key changes */
    select @validcnt = count(*)
    from deleted d
    join inserted i on i.Co = d.Co and i.Mth = d.Mth and i.BatchId = d.BatchId and i.BatchSeq = d.BatchSeq
    if @numrows <> @validcnt
    	begin
    	select @errmsg = 'Cannot change Company, Month, Batch ID #, or Batch Sequence # '
    	goto error
    	end
    
    -- if BatchTransType is 'C' or 'D' cannot change MO or MOItem
    select @validcnt = count(*) from deleted d
    join inserted i on i.Co = d.Co and i.Mth = d.Mth and i.BatchId = d.BatchId and i.BatchSeq = d.BatchSeq
        where i.BatchTransType in ('C','D') and (i.MO <> d.MO or i.MOItem <> d.MOItem)
    if @validcnt <> 0
        begin
        select @errmsg = 'Cannot change MO or MO Item if Action is not ''A''!'
        goto error
        end
    
    --if BatchTransType is 'A' cannot change to 'C' or 'D' and vice versa
    if update (BatchTransType)
        begin
        select @validcnt = count(*) from inserted i
            join deleted d on i.Co = d.Co and i.Mth = d.Mth and i.BatchId = d.BatchId and i.BatchSeq = d.BatchSeq
            where (d.BatchTransType = 'A' and i.BatchTransType in ('C','D')) or
    			(d.BatchTransType in ('C','D') and i.BatchTransType = 'A')
        if @validcnt <>  0
    		begin
        	select @errmsg = 'Cannot change Action from ''A'' to (''C'' or ''D'') and vice versa.'
    	   	goto error
        	end
        end
    
    --change to IN Transaction not allowed on change or delete entries
    select @validcnt = count(*)
    from deleted d
    join inserted i on d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId and d.BatchSeq = i.BatchSeq
    where i.BatchTransType in ('C','D') and d.INTrans <> i.INTrans
    if @validcnt > 0
    	begin
    	select @errmsg = 'Cannot change IN Trans# on ''change'' or ''delete'''
    	goto error
    	end
   
    ---- TK-16643 retrieve the insert Material, MatlGroup and the UM to retrieve the Conversion factor
    SELECT @material = i.Material, @matlgroup = i.MatlGroup, @um = i.UM
			,@co = i.Co, @loc = Loc
    FROM inserted i
   
	----TK-16643 retrieve the Conversion Factor to be used in calculating StkUnits and StkTotalCost
	EXEC @rcode = dbo.bspINMOMatlUMVal @co, @loc, @material, @matlgroup, @um, NULL, NULL, @convfactor OUTPUT, NULL, NULL, @msgout OUTPUT
    if @rcode = 1
    	begin
     	select @errmsg = @msgout
     	goto error
     	end
   
    --retrieve the Conversion Factor to be used in calculating StkUnits and StkTotalCost
    --exec @rcode = dbo.bspINMatlUMVal @material, @matlgroup, @um, @convfactor output, null, null, null, null, @msgout output
    --if @rcode = 1
    --	begin
    -- 	select @errmsg = @msgout
    -- 	goto error
    -- 	end
    
    --calculate ConfirmTotal, StkUnits and StkTotalCost from values being posted
    update bINCB 
   	--ConfirmTotal
       set ConfirmTotal = (i.ConfirmUnits * i.UnitPrice/(case i.ECM when 'E'
    	then 1 when 'C' then 100 when 'M' then 1000 end)),  
   	--StkUnits
   	StkUnits = (i.ConfirmUnits * @convfactor),
       --StkTotalCost
   	StkTotalCost = ((i.ConfirmUnits * @convfactor) * i.StkUnitCost/(case i.StkECM
   	when 'E' then 1 when 'C' then 100 when 'M' then 1000 end))
   
   	from bINCB b, inserted i
   	where b.Co = i.Co and b.Mth = i.Mth and b.BatchId = i.BatchId and b.BatchSeq = i.BatchSeq
     
    --lock existing bINDT Confirmation entries pulled into batch
    if update(INTrans)
    	begin
    	select @validcnt = count(*) from inserted where BatchTransType in ('C','D')
    	if @validcnt <> 0
    		begin
    		update bINDT
    		set InUseBatchId = i.BatchId
    		from bINDT d
    		join inserted i on i.Co = d.INCo and i.Mth = d.Mth and i.INTrans = d.INTrans
    		if @@rowcount <> @validcnt
    	 		begin
    	 		select @errmsg = 'Unable to update IN Detail as ''In Use''. '
    	 		goto error
    	 		end
    	 	end
    	end
    
   
    --lock MO Header
    if update(MO)
    	begin
    	update bINMO
    	set InUseMth = i.Mth, InUseBatchId = i.BatchId
    	from bINMO h
    	join inserted i on i.Co = h.INCo and i.MO = h.MO
    	where h.InUseMth is null and h.InUseBatchId is null
    	end
    
    --lock MO Item
    if update(MO) or update(MOItem)
    	begin
    	update bINMI
    	set InUseMth = i.Mth, InUseBatchId = i.BatchId
    	from bINMI h
    	join inserted i on i.Co = h.INCo and i.MO = h.MO and i.MOItem = h.MOItem
    	where h.InUseMth is null and h.InUseBatchId is null
    
    	-- add HQ Close Control for JC GL Co#s referenced by MO Items
    	insert bHQCC (Co, Mth, BatchId, GLCo)
    	select i.Co, i.Mth, i.BatchId, c.GLCo
    	from inserted i
    	join bINMI c on i.Co = c.INCo and i.MO = c.MO and i.MOItem = c.MOItem
    	where c.GLCo not in (select h.GLCo from bHQCC h join inserted i on h.Co = i.Co and h.Mth = i.Mth
    							and h.BatchId = i.BatchId)
    	end
    
    return
    
    error:
       select @errmsg = @errmsg + ' - cannot update IN Confirmation Batch entry (bINCB)'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
    
    
    
   
   
  
 




GO
CREATE UNIQUE CLUSTERED INDEX [biINCB] ON [dbo].[bINCB] ([Co], [Mth], [BatchId], [BatchSeq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bINCB] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bINCB].[ECM]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bINCB].[StkECM]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bINCB].[OldECM]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bINCB].[OldStkECM]'
GO
