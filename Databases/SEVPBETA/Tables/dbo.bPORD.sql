CREATE TABLE [dbo].[bPORD]
(
[POCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[POTrans] [dbo].[bTrans] NOT NULL,
[PO] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[POItem] [dbo].[bItem] NOT NULL,
[RecvdDate] [dbo].[bDate] NOT NULL,
[RecvdBy] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Description] [dbo].[bDesc] NULL,
[RecvdUnits] [dbo].[bUnits] NOT NULL,
[RecvdCost] [dbo].[bDollar] NOT NULL,
[BOUnits] [dbo].[bUnits] NOT NULL,
[BOCost] [dbo].[bDollar] NOT NULL,
[PostedDate] [dbo].[bDate] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[InUseBatchId] [dbo].[bBatchID] NULL,
[Purge] [dbo].[bYN] NOT NULL,
[Receiver#] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[InvdFlag] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPORD_InvdFlag] DEFAULT ('N'),
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[APTrans] [dbo].[bTrans] NULL,
[APLine] [int] NULL,
[UISeq] [int] NULL,
[UILine] [int] NULL,
[APMth] [dbo].[bMonth] NULL,
[UIMth] [dbo].[bMonth] NULL,
[POItemLine] [int] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

    CREATE trigger [dbo].[btPORDd] on [dbo].[bPORD] for DELETE as

/***  basic declares for SQL Triggers ****/
    declare @numrows int,@errmsg varchar(255), @errno tinyint, @validcnt int, @rcode tinyint
   
    /*--------------------------------------------------------------
     *
     *  Update trigger for PORD
     *  Created By: DANF 9/25/02 - Add update to On Hand For PO Inventory items when not updating the IN Sub Ledger for expenses.
     *				 DANF 2/23/2005 - Update Aduit flag on INMT.
     * 			 MV 04/15/05 - #28436 - get conversion factor from bINMU, change @umconv datatype to bUnitCost.
     *				 MV 06/01/05 - #28825 - exclude purged POs from INMT.OnHand update
	*			DC #119886 01/23/08 - Add auditing on PO Receipts
	 *			JonathanP 05/29/09 issue 133438 - Added attachment deletion code.
	 *			GP 7/27/2011 - TK-07144 changed bPO to varchar(30)
	 *			GF 08/21/2011 - TK-07879 PO ITEM LINE
	 *
     *  Date:      
     *
     *  Rejects any primary key changes and validates PO and PO Item.
     *--------------------------------------------------------------*/
     select @numrows = @@rowcount
     if @numrows = 0 return
     set nocount on
   
   
   -- validate PO
   select @validcnt = count(*)
   from bPOHD r
   JOIN deleted d ON d.POCo = r.POCo and d.PO = r.PO
   if @validcnt <> @numrows
      begin
      select @errmsg = 'PO is Invalid '
      goto error
      end
   
   -- validate PO Item
   select @validcnt = count(*)
   from bPOIT r
   JOIN deleted d ON d.POCo = r.POCo and d.PO = r.PO and d.POItem = r.POItem
   if @validcnt <> @numrows
      begin
      select @errmsg = 'PO item is Invalid '
      goto error
      end
   
---- validate PO Item Line TK-07879
select @validcnt = count(*)
from dbo.vPOItemLine r
JOIN deleted d ON d.POCo = r.POCo and d.PO = r.PO and d.POItem = r.POItem AND d.POItemLine=r.POItemLine
if @validcnt <> @numrows
  begin
  select @errmsg = 'PO Item Line is Invalid '
  goto error
  end
   
   
declare @opencursor int, @stdunits bUnits, @stdum bUM, @umconv bUnitCost,  
		@oldpoco bCompany, @oldpo varchar(30), @oldmatlgroup bGroup, @oldinco bCompany,
		@oldpoitem bItem, @oldmaterial bMatl, @oldum bUM, @oldloc bLoc, @oldrecunits bUnits,
		@msg varchar(120), @purgeyn bYN,
		----TK-07879
		@OldPOItemLine INT
   
   
   /*If PO Company Inventory interface level is greater than one and the Update SubLedger on Receipts is Yes
   then the units received is account for in the INDT trigger*/
   
-- update On Hand in bINMT for Inventory purchase order Items
if @numrows = 1
	begin
	-- if only one row inserted, no cursor is needed TK-07879
	select @oldpoco = d.POCo, @oldpo=d.PO, @oldpoitem=d.POItem, @oldrecunits= d.RecvdUnits,
			@oldinco = l.PostToCo, @oldloc = l.Loc,
			@oldmaterial = o.Material, @oldum = o.UM, @oldmatlgroup = o.MatlGroup,
			@OldPOItemLine = d.POItemLine
	from deleted d 
	INNER JOIN dbo.vPOItemLine l ON l.POCo=d.POCo AND l.PO=d.PO AND l.POItem=d.POItem AND l.POItemLine=d.POItemLine
	join bPOIT o on o.POCo=d.POCo and o.PO=d.PO and o.POItem=d.POItem
	join bPOCO c on c.POCo=d.POCo
	join bAPCO a on a.APCo=d.POCo
	where l.ItemType = 2 and (c.ReceiptUpdate = 'N' or c.RecINInterfacelvl=0) 
	and a.INInterfaceLvl=1 and d.Purge='N' -- include inventroy items, #28825 exclude purged POs
	if @@rowcount = 0 goto btexit
	end
else
	begin
	-- use a cursor to process inserted rows TK-07879
	declare POInventory cursor for
	select d.POCo, d.PO, d.POItem, d.RecvdUnits, d.POItemLine,
			l.PostToCo, l.Loc,
			o.Material, o.UM, o.MatlGroup
	from deleted d
	INNER JOIN dbo.vPOItemLine l ON l.POCo=d.POCo AND l.PO=d.PO AND l.POItem=d.POItem AND l.POItemLine=d.POItemLine
	join bPOIT o on o.POCo=d.POCo and o.PO=d.PO and o.POItem=d.POItem
	join bPOCO c on c.POCo=d.POCo
	join bAPCO a on a.APCo=d.POCo
	where l.ItemType = 2 and (c.ReceiptUpdate = 'N' or c.RecINInterfacelvl=0) 
	and a.INInterfaceLvl=1 and d.Purge='N'-- include inventory items, #28825 exclude purged POs

	open POInventory 
	select @opencursor = 1

	-- get 1st row inserted
	fetch next from POInventory  into @oldpoco, @oldpo, @oldpoitem, @oldrecunits, @OldPOItemLine,
				@oldinco, @oldloc, @oldmaterial, @oldum, @oldmatlgroup
	if @@fetch_status <> 0 goto btexit
	end
   
   
next_INMT:
-- Update Old Values
select @stdunits = 0
-- validate Material, get conversion for posted unit of measure
exec @rcode = bspHQStdUMGet @oldmatlgroup, @oldmaterial, @oldum, @umconv output, @stdum output, @msg output
if @rcode <> 0 goto next_row
   
   -- if std unit of measure equals posted unit of measure, set IN units equal to posted
   if @stdum = @oldum
       begin
       select @stdunits = @oldrecunits
       goto update_OldINMT
       end
   -- get conversion factor from bINMU if exists, overrides bHQMU -- #28436
   if @stdum <> @oldum
   	  begin
   	  select @umconv = Conversion
   	  from bINMU with (nolock)
   	  where INCo = @oldinco and Loc = @oldloc and MatlGroup = @oldmatlgroup
   	      and Material = @oldmaterial and UM = @oldum
   	  end
   
   if @umconv <> 0 select @stdunits = @oldrecunits * @umconv
   
   -- On Hand update needed
   update_OldINMT:
   update bINMT set OnHand = OnHand - @stdunits, AuditYN = 'N'
   where INCo = @oldinco and Loc = @oldloc and MatlGroup = @oldmatlgroup and Material = @oldmaterial
   
   update bINMT set AuditYN = 'Y'
   where INCo = @oldinco and Loc = @oldloc and MatlGroup = @oldmatlgroup and Material = @oldmaterial
   
   -- get next row
   next_row:
    	if @numrows > 1
       	begin
       	fetch next from POInventory  into @oldpoco, @oldpo, @oldpoitem, @oldrecunits, @OldPOItemLine,
       			@oldinco, @oldloc, @oldmaterial, @oldum, @oldmatlgroup
   
       	if @@fetch_status = 0 goto next_INMT
   		end

btexit:
	if @opencursor = 1
		begin
		close POInventory  
   		deallocate POInventory  
		end
   
/* Audit PO Receipts deletions */
insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bPORD', 'Mth:' + convert(varchar(8), d.Mth,1) + ' POTrans:' + convert(varchar(7),d.POTrans),
		d.POCo, 'D', null, null, null, getdate(), SUSER_SNAME()
from deleted d
join bPOCO c on d.POCo = c.POCo
where c.AuditPOReceipts = 'Y' and d.Purge='N'

-- Delete attachments if they exist. Make sure UniqueAttchID is not null
insert vDMAttachmentDeletionQueue (AttachmentID, UserName, DeletedFromRecord)
select AttachmentID, suser_name(), 'Y' 
from bHQAT h join deleted d on h.UniqueAttchID = d.UniqueAttchID                  
where d.UniqueAttchID is not null    


return



error:
	select @errmsg = @errmsg + ' - cannot update PO Receiving detail'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
   
   
   
   
   
   
   
   
   
   
   
  
 





GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

 
   
   
   /****** Object:  Trigger dbo.btPORDi    Script Date: 12/16/99 02:32:00 PM ******/
   
   CREATE        trigger [dbo].[btPORDi] on [dbo].[bPORD] for INSERT as
   

/*--------------------------------------------------------------
    *  Insert trigger for PORD
    *  Created By: EN
    *  Date:       12/18/99
    *              DANF 9/25/02 - Add update to On Hand For PO Inventory items when not updating the IN Sub Ledger for expenses.
    *      		 DANF 2/23/2005 - Update Aduit flag on INMT.
    *				MV 03/16/05 - #27362 - get conversion factor from bINMU, change @umconv datatype to bUnitCost.
	*				DC 01/23/08 - #119886 - Add auditing on PO Receipts
	*				GP 7/27/2011 - TK-07144 changed bPO to varchar(30)
	*				GF 08/22/2011 - TK-07879 PO ITEM LINE
	*
    *
    *  Insert trigger for PORD - PO Receiving Detail
    *
    *--------------------------------------------------------------*/
   declare @numrows int, @validcnt int, @errmsg varchar(255)
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   -- validate PO company
   select @validcnt = count(*)
   from bPOCO r
   JOIN inserted i ON i.POCo = r.POCo
   if @validcnt <> @numrows
      begin
      select @errmsg = 'PO company is Invalid '
      goto error
      end
   
   -- validate PO
   select @validcnt = count(*)
   from bPOHD r
   JOIN inserted i ON i.POCo = r.POCo and i.PO = r.PO
   if @validcnt <> @numrows
      begin
      select @errmsg = 'PO is Invalid '
      goto error
      end
   
   -- validate PO Item
   select @validcnt = count(*)
   from bPOIT r
   JOIN inserted i ON i.POCo = r.POCo and i.PO = r.PO and i.POItem = r.POItem
   if @validcnt <> @numrows
      begin
      select @errmsg = 'PO item is Invalid '
      goto error
      end
   
   
   ---
   
   declare @poco bCompany, @opencursor int, @stdunits bUnits, @rcode int, @stdum bUM, @umconv bUnitCost, @po varchar(30), 
   		@matlgroup bGroup, @inco bCompany, @poitem bItem, @material bMatl, @um bUM, @loc bLoc, @recunits bUnits,
   		@msg varchar(120)
   
   
   /*If PO Company Inventory interface level is greater than one and the Update SubLedger on Receipts is Yes and 
   AP Company is updatind inventory then the units received is account for in the INDT trigger*/
   
   -- update On Hand in bINMT for Inventory purchase order Items
   if @numrows = 1
       begin
		-- if only one row inserted, no cursor is needed
		----TK-07879
		select @poco = i.POCo, @po=i.PO, @poitem=i.POItem, @recunits= i.RecvdUnits,
				@inco = l.PostToCo, @loc = l.Loc, 
				@material = p.Material, @um = p.UM, @matlgroup = p.MatlGroup
		from inserted i
		INNER JOIN dbo.vPOItemLine l ON l.POCo=i.POCo AND l.PO=i.PO AND l.POItem=i.POItem AND l.POItemLine=i.POItemLine
		join bPOIT p on p.POCo=i.POCo and p.PO=i.PO and p.POItem=i.POItem
		join bPOCO c on c.POCo=i.POCo
		join bAPCO a on a.APCo=i.POCo
		---- include inventroy items
		where l.ItemType = 2 and (c.ReceiptUpdate = 'N' or c.RecINInterfacelvl=0) and a.INInterfaceLvl=1 
		if @@rowcount = 0 goto btexit
		end
   else
       begin
       -- use a cursor to process inserted rows
		declare POInventory cursor FOR
		----TK-07879
		select i.POCo, i.PO, i.POItem, i.RecvdUnits,
				l.PostToCo, l.Loc, 
				p.Material, p.UM, p.MatlGroup
		from inserted i
		INNER JOIN dbo.vPOItemLine l ON l.POCo=i.POCo AND l.PO=i.PO AND l.POItem=i.POItem AND l.POItemLine=i.POItemLine
		join bPOIT p on p.POCo=i.POCo and p.PO=i.PO and p.POItem=i.POItem
		join bPOCO c on c.POCo=i.POCo
		join bAPCO a on a.APCo=i.POCo
		---- include inventory items
		where l.ItemType = 2 and (c.ReceiptUpdate = 'N' or c.RecINInterfacelvl=0) and a.INInterfaceLvl=1 

		open POInventory 
		select @opencursor = 1

		-- get 1st row inserted
		fetch next from POInventory  into @poco, @po, @poitem, @recunits, @inco, @loc, @material, @um, @matlgroup
		if @@fetch_status <> 0 goto btexit
		end
   
   next_INMT:
   select @stdunits = 0
   -- validate Material, get conversion for posted unit of measure
   exec @rcode = bspHQStdUMGet @matlgroup, @material, @um, @umconv output, @stdum output, @msg output
   if @rcode <> 0 goto next_row
   
   -- if std unit of measure equals posted unit of measure, set IN units equal to posted
   if @stdum = @um
       begin
       select @stdunits = @recunits
       goto update_INMT
       end
   -- get conversion factor from bINMU if exists, overrides bHQMU -- #27362
   if @stdum <> @um
   	  begin
   	  select @umconv = Conversion
   	  from bINMU with (nolock)
   	  where INCo = @inco and Loc = @loc and MatlGroup = @matlgroup
   	      and Material = @material and UM = @um
   	  end
   if @umconv <> 0 select @stdunits = @recunits * @umconv
   
   -- On Hand update needed
   update_INMT:
   update bINMT set OnHand = OnHand + @stdunits, AuditYN = 'N'
   where INCo = @inco and Loc = @loc and MatlGroup = @matlgroup and Material = @material
   
   update bINMT set AuditYN = 'Y'
   where INCo = @inco and Loc = @loc and MatlGroup = @matlgroup and Material = @material
   
   -- get next row
   next_row:
    	if @numrows > 1
       	begin
       	fetch next from POInventory  into @poco, @po, @poitem, @recunits, @inco, @loc, @material, @um, @matlgroup
       	if @@fetch_status = 0 goto next_INMT
   		end
   
btexit:
	if @opencursor = 1
	begin
	close POInventory  
	deallocate POInventory  
	end

-- -- -- HQ Auditing
INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
SELECT 'bPORD','Mth:' + convert(varchar(8), i.Mth,1) + ' POTrans:' + convert(varchar(7),i.POTrans), 
	i.POCo, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
FROM inserted i
join bPOCO c on c.POCo = i.POCo
where i.POCo = c.POCo and c.AuditPOReceipts = 'Y'



return


error:
	select @errmsg = @errmsg + ' - cannot insert PO Receiving Detail'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
   
   
   
   
   
   
   
   
   
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

 

   
   /****** Object:  Trigger dbo.btPORDu    Script Date: 8/28/99 9:38:06 AM ******/
   
CREATE        trigger [dbo].[btPORDu] on [dbo].[bPORD] for UPDATE as
   
     
/***  basic declares for SQL Triggers ****/
    declare @numrows int,@errmsg varchar(255), @errno tinyint, @validcnt int, @rcode tinyint
    /*--------------------------------------------------------------
     *
     *  Update trigger for PORD
     *  Created By: EN
     *  Date:       12/18/99
     *              DANF 9/25/02 - Add update to On Hand For PO Inventory items when not updating the IN Sub Ledger for expenses.
     *      		DANF 2/23/2005 - Update Aduit flag on INMT.
     *				MV 04/15/05 - #28436 - get conversion factor from bINMU, change @umconv datatype to bUnitCost.
	 *       		DC 01/23/08 - #119886 - Add auditing on PO Receipts
	 *			    JonathanP 01/09/08 - #128879 - Added code to skip procedure if only UniqueAttachID changed.
	 *				GP 7/27/2011 - TK-07144 changed bPO to varchar(30)
	 *				gf 08/22/2011 - TK-07879
	 *
	 *
     *  Rejects any primary key changes and validates PO and PO Item.
     *--------------------------------------------------------------*/
     select @numrows = @@rowcount
     if @numrows = 0 return
     set nocount on
   
    --If the only column that changed was UniqueAttachID, then skip validation.        
	IF dbo.vfOnlyColumnUpdated(COLUMNS_UPDATED(), 'bPORD', 'UniqueAttchID') = 1
	BEGIN 
		goto Trigger_Skip
	END    
   
    /* check for key changes */
    select @validcnt = count(*) from deleted d, inserted i
    	where d.POCo = i.POCo and d.Mth = i.Mth and d.POTrans = i.POTrans
    if @numrows <> @validcnt
    	begin
    	select @errmsg = 'Cannot change PO Company, Month, or PO Transaction number ', @rcode = 1
    	goto error
    	end
   
   -- validate PO
   select @validcnt = count(*)
   from bPOHD r
   JOIN inserted i ON i.POCo = r.POCo and i.PO = r.PO
   if @validcnt <> @numrows
      begin
      select @errmsg = 'PO is Invalid '
      goto error
      end
   
   -- validate PO Item
   select @validcnt = count(*)
   from bPOIT r
   JOIN inserted i ON i.POCo = r.POCo and i.PO = r.PO and i.POItem = r.POItem
   if @validcnt <> @numrows
      begin
      select @errmsg = 'PO item is Invalid '
      goto error
      end
   
   
   declare @poco bCompany, @opencursor int, @stdunits bUnits, @stdum bUM, @umconv bUnitCost, @po varchar(30), 
   		@matlgroup bGroup, @inco bCompany, @poitem bItem, @material bMatl, @um bUM, @loc bLoc, @recunits bUnits,
   		@oldpoco bCompany, @oldpo varchar(30), @oldmatlgroup bGroup, @oldinco bCompany, @oldpoitem bItem, 
   		@oldmaterial bMatl, @oldum bUM, @oldloc bLoc, @oldrecunits bUnits,
   		@msg varchar(120)
   
   
   /*If PO Company Inventory interface level is greater than one and the Update SubLedger on Receipts is Yes
   then the units received is account for in the INDT trigger*/
   
   -- update On Hand in bINMT for Inventory purchase order Items
   if @numrows = 1
       begin
       -- if only one row inserted, no cursor is needed
       ----TK-07879
       select @poco = i.POCo, @po=i.PO, @poitem=i.POItem, @recunits= i.RecvdUnits,
				@inco = l.PostToCo, @loc = l.Loc,
				@material = p.Material, @um = p.UM, @matlgroup = p.MatlGroup,
				@oldpoco = d.POCo, @oldpo=d.PO, @oldpoitem=d.POItem, @oldrecunits= d.RecvdUnits,
				@oldinco = x.PostToCo, @oldloc = x.Loc,
				@oldmaterial = o.Material, @oldum = o.UM, @oldmatlgroup = o.MatlGroup
       from inserted i
		join deleted d on d.POCo=i.POCo and d.Mth=i.Mth and d.POTrans=i.POTrans
		INNER JOIN dbo.vPOItemLine l ON l.POCo=i.POCo AND l.PO=i.PO AND l.POItem=i.POItem AND l.POItemLine=i.POItemLine
		INNER JOIN dbo.vPOItemLine x ON x.POCo=d.POCo AND x.PO=d.PO AND x.POItem=d.POItem AND x.POItemLine=d.POItemLine
		join bPOIT p on p.POCo=i.POCo and p.PO=i.PO and p.POItem=i.POItem
		join bPOIT o on o.POCo=d.POCo and o.PO=d.PO and o.POItem=d.POItem
		join bPOCO c on c.POCo=i.POCo
		join bAPCO a on a.APCo=d.POCo
		---- include inventroy items
		WHERE l.ItemType = 2 and (c.ReceiptUpdate = 'N' or c.RecINInterfacelvl=0) and a.INInterfaceLvl=1
		if @@rowcount = 0 goto btexit
		end
   else
       begin
		-- use a cursor to process inserted rows
		declare POInventory cursor FOR
		----TK-07879
		select i.POCo, i.PO, i.POItem, i.RecvdUnits,
				l.PostToCo, l.Loc, 
				p.Material, p.UM, p.MatlGroup,
				d.POCo, d.PO, d.POItem, d.RecvdUnits,
				x.PostToCo, x.Loc, 
				o.Material, o.UM, o.MatlGroup
		from inserted i
		join deleted d on d.POCo=i.POCo and d.Mth=i.Mth and d.POTrans=i.POTrans
		INNER JOIN dbo.vPOItemLine l ON l.POCo=i.POCo AND l.PO=i.PO AND l.POItem=i.POItem AND l.POItemLine=i.POItemLine
		INNER JOIN dbo.vPOItemLine x ON x.POCo=d.POCo AND x.PO=d.PO AND x.POItem=d.POItem AND x.POItemLine=d.POItemLine
		join bPOIT p on p.POCo=i.POCo and p.PO=i.PO and p.POItem=i.POItem
		join bPOIT o on o.POCo=d.POCo and o.PO=d.PO and o.POItem=d.POItem
		join bPOCO c on c.POCo=i.POCo
		join bAPCO a on a.APCo=d.POCo
		---- include inventory items
		where l.ItemType = 2 and (c.ReceiptUpdate = 'N' or c.RecINInterfacelvl=0) and a.INInterfaceLvl=1 
   
       open POInventory 
       select @opencursor = 1
   
       -- get 1st row inserted
       fetch next from POInventory  into @poco, @po, @poitem, @recunits, @inco, @loc, @material, @um, @matlgroup,
          								 @oldpoco, @oldpo, @oldpoitem, @oldrecunits, @oldinco, @oldloc, 
          								 @oldmaterial, @oldum, @oldmatlgroup
   
       if @@fetch_status <> 0 goto btexit
       end
   
   
   next_INMT:
   -- Update New Values
   select @stdunits = 0
   -- validate Material, get conversion for posted unit of measure
   exec @rcode = bspHQStdUMGet @matlgroup, @material, @um, @umconv output, @stdum output, @msg output
   if @rcode <> 0 goto next_row
   
   -- if std unit of measure equals posted unit of measure, set IN units equal to posted
   if @stdum = @um
       begin
       select @stdunits = @recunits
       goto update_NewINMT
       end
   
   -- get conversion factor from bINMU if exists, overrides bHQMU -- #27362
   if @stdum <> @um
   	  begin
   	  select @umconv = Conversion
   	  from bINMU with (nolock)
   	  where INCo = @inco and Loc = @loc and MatlGroup = @matlgroup
   	      and Material = @material and UM = @um
   	  end
   if @umconv <> 0 select @stdunits = @recunits * @umconv
   
   -- On Hand update needed
   update_NewINMT:
   update bINMT set OnHand = OnHand + @stdunits, AuditYN = 'N'
   where INCo = @inco and Loc = @loc and MatlGroup = @matlgroup and Material = @material
   
   update bINMT set AuditYN = 'Y'
   where INCo = @inco and Loc = @loc and MatlGroup = @matlgroup and Material = @material
   
   -- Update Old Values
   select @stdunits = 0
   -- validate Material, get conversion for posted unit of measure
   exec @rcode = bspHQStdUMGet @oldmatlgroup, @oldmaterial, @oldum, @umconv output, @stdum output, @msg output
   if @rcode <> 0 goto next_row
   
   -- if std unit of measure equals posted unit of measure, set IN units equal to posted
   if @stdum = @oldum
       begin
       select @stdunits = @oldrecunits
       goto update_OldINMT
       end
   -- get conversion factor from bINMU if exists, overrides bHQMU -- #28436
   if @stdum <> @oldum
   	  begin
   	  select @umconv = Conversion
   	  from bINMU with (nolock)
   	  where INCo = @oldinco and Loc = @oldloc and MatlGroup = @oldmatlgroup
   	      and Material = @oldmaterial and UM = @oldum
   	  end
   if @umconv <> 0 select @stdunits = @oldrecunits * @umconv
   
   -- On Hand update needed
   update_OldINMT:
   update bINMT set OnHand = OnHand - @stdunits, AuditYN = 'N'
   where INCo = @oldinco and Loc = @oldloc and MatlGroup = @oldmatlgroup and Material = @oldmaterial
   
   update bINMT set AuditYN = 'Y'
   where INCo = @oldinco and Loc = @oldloc and MatlGroup = @oldmatlgroup and Material = @oldmaterial
   
   -- get next row
   next_row:
    	if @numrows > 1
       	begin
       	fetch next from POInventory  into @poco, @po, @poitem, @recunits, @inco, @loc, @material, @um, @matlgroup,
          								  @oldpoco, @oldpo, @oldpoitem, @oldrecunits, @oldinco, @oldloc, 
          								  @oldmaterial, @oldum, @oldmatlgroup
       	if @@fetch_status = 0 goto next_INMT
   		end
   
   btexit:
   	if @opencursor = 1
   		begin
   		close POInventory  
       	deallocate POInventory  
   		end
   
   -- HQ Auditing
   if exists(select * from inserted i join bPOCO a on i.POCo = a.POCo and a.AuditPOReceipts = 'Y')
	BEGIN
		IF UPDATE(PO)
		BEGIN
			insert into bHQMA select 'bPORD', 'Mth:' + convert(varchar(8), d.Mth,1) + ' POTrans:' + convert(varchar(7),d.POTrans), 
			i.POCo, 'C', 'PO', d.PO, i.PO, getdate(), SUSER_SNAME()
    		from inserted i
			join deleted d on d.POCo = i.POCo and d.Mth = i.Mth and d.POTrans = i.POTrans
    		where d.PO <> i.PO
		END
		IF UPDATE(POItem)
		BEGIN
			insert into bHQMA select 'bPORD', 'Mth:' + convert(varchar(8), d.Mth,1) + ' POTrans:' + convert(varchar(7),d.POTrans), 
			i.POCo, 'C', 'POItem', convert(varchar(5),d.POItem), convert(varchar(5),i.POItem), getdate(), SUSER_SNAME()
    		from inserted i
			join deleted d on d.POCo = i.POCo and d.Mth = i.Mth and d.POTrans = i.POTrans 
    		where d.POItem <> i.POItem
		END
		IF UPDATE(RecvdDate)
		BEGIN
			insert into bHQMA select 'bPORD', 'Mth:' + convert(varchar(8), d.Mth,1) + ' POTrans:' + convert(varchar(7),d.POTrans), 
			i.POCo, 'C', 'RecvdDate', convert(varchar(8),d.RecvdDate,1), convert(varchar(8),i.RecvdDate,1), getdate(), SUSER_SNAME()
    		from inserted i
			join deleted d on d.POCo = i.POCo and d.Mth = i.Mth and d.POTrans = i.POTrans 
    		where d.RecvdDate <> i.RecvdDate
		END
		IF UPDATE(RecvdBy)
		BEGIN
			insert into bHQMA select 'bPORD', 'Mth:' + convert(varchar(8), d.Mth,1) + ' POTrans:' + convert(varchar(7),d.POTrans), 
			i.POCo, 'C', 'RecvdBy', d.RecvdBy, i.RecvdBy, getdate(), SUSER_SNAME()
    		from inserted i
			join deleted d on d.POCo = i.POCo and d.Mth = i.Mth and d.POTrans = i.POTrans 
    		where d.RecvdBy <> i.RecvdBy
		END
		IF UPDATE(Description)
		BEGIN
			insert into bHQMA select 'bPORD', 'Mth:' + convert(varchar(8), d.Mth,1) + ' POTrans:' + convert(varchar(7),d.POTrans), 
			i.POCo, 'C', 'Description', d.Description, i.Description, getdate(), SUSER_SNAME()
    		from inserted i
			join deleted d on d.POCo = i.POCo and d.Mth = i.Mth and d.POTrans = i.POTrans 
    		where d.Description <> i.Description
		END
		IF UPDATE(RecvdUnits)
		BEGIN
			insert into bHQMA select 'bPORD', 'Mth:' + convert(varchar(8), d.Mth,1) + ' POTrans:' + convert(varchar(7),d.POTrans), 
			i.POCo, 'C', 'RecvdUnits', convert(varchar(12),d.RecvdUnits), convert(varchar(12),i.RecvdUnits), getdate(), SUSER_SNAME()
    		from inserted i
			join deleted d on d.POCo = i.POCo and d.Mth = i.Mth and d.POTrans = i.POTrans 
    		where d.RecvdUnits <> i.RecvdUnits
		END
		IF UPDATE(RecvdCost)
		BEGIN
			insert into bHQMA select 'bPORD', 'Mth:' + convert(varchar(8), d.Mth,1) + ' POTrans:' + convert(varchar(7),d.POTrans), 
			i.POCo, 'C', 'RecvdCost', convert(varchar(12),d.RecvdCost), convert(varchar(12),i.RecvdCost), getdate(), SUSER_SNAME()
    		from inserted i
			join deleted d on d.POCo = i.POCo and d.Mth = i.Mth and d.POTrans = i.POTrans 
    		where d.RecvdCost <> i.RecvdCost
		END
		IF UPDATE(BOUnits)
		BEGIN
			insert into bHQMA select 'bPORD', 'Mth:' + convert(varchar(8), d.Mth,1) + ' POTrans:' + convert(varchar(7),d.POTrans), 
			i.POCo, 'C', 'BOUnits', convert(varchar(12),d.BOUnits), convert(varchar(12),i.BOUnits), getdate(), SUSER_SNAME()
    		from inserted i
			join deleted d on d.POCo = i.POCo and d.Mth = i.Mth and d.POTrans = i.POTrans 
    		where d.BOUnits <> i.BOUnits
		END
		IF UPDATE(BOCost)
		BEGIN
			insert into bHQMA select 'bPORD', 'Mth:' + convert(varchar(8), d.Mth,1) + ' POTrans:' + convert(varchar(7),d.POTrans), 
			i.POCo, 'C', 'BOCost', convert(varchar(12),d.BOCost), convert(varchar(12),i.BOCost), getdate(), SUSER_SNAME()
    		from inserted i
			join deleted d on d.POCo = i.POCo and d.Mth = i.Mth and d.POTrans = i.POTrans 
    		where d.BOCost <> i.BOCost
		END
		IF UPDATE(PostedDate)
		BEGIN
			insert into bHQMA select 'bPORD', 'Mth:' + convert(varchar(8), d.Mth,1) + ' POTrans:' + convert(varchar(7),d.POTrans), 
			i.POCo, 'C', 'PostedDate', convert(varchar(8),d.PostedDate,1), convert(varchar(8),i.PostedDate,1), getdate(), SUSER_SNAME()
    		from inserted i
			join deleted d on d.POCo = i.POCo and d.Mth = i.Mth and d.POTrans = i.POTrans 
    		where d.PostedDate <> i.PostedDate
		END
		IF UPDATE(Purge)
		BEGIN
			insert into bHQMA select 'bPORD', 'Mth:' + convert(varchar(8), d.Mth,1) + ' POTrans:' + convert(varchar(7),d.POTrans), 
			i.POCo, 'C', 'Purge', d.Purge, i.Purge, getdate(), SUSER_SNAME()
    		from inserted i
			join deleted d on d.POCo = i.POCo and d.Mth = i.Mth and d.POTrans = i.POTrans 
    		where d.Purge <> i.Purge
		END
		IF UPDATE(Receiver#)
		BEGIN
			insert into bHQMA select 'bPORD', 'Mth:' + convert(varchar(8), d.Mth,1) + ' POTrans:' + convert(varchar(7),d.POTrans), 
			i.POCo, 'C', 'Receiver#', d.Receiver#, i.Receiver#, getdate(), SUSER_SNAME()
    		from inserted i
			join deleted d on d.POCo = i.POCo and d.Mth = i.Mth and d.POTrans = i.POTrans 
    		where d.Receiver# <> i.Receiver#
			-- Update APTL with new Receiver#
			if exists(select 1 from bAPTL l join deleted d on l.APCo=d.POCo and l.PO=d.PO and l.POItem=d.POItem and l.Receiver#=d.Receiver#)
			begin
			update bAPTL set Receiver#=i.Receiver# 
			from inserted i
			join deleted d on d.POCo = i.POCo and d.Mth = i.Mth and d.POTrans = i.POTrans
			join bAPTL l on l.APCo=d.POCo and l.PO=d.PO and l.POItem=d.POItem and l.Receiver#=d.Receiver#
			end
			
		END
		IF UPDATE(InvdFlag)
		BEGIN
			insert into bHQMA select 'bPORD', 'Mth:' + convert(varchar(8), d.Mth,1) + ' POTrans:' + convert(varchar(7),d.POTrans), 
			i.POCo, 'C', 'InvdFlag', d.InvdFlag, i.InvdFlag, getdate(), SUSER_SNAME()
    		from inserted i
			join deleted d on d.POCo = i.POCo and d.Mth = i.Mth and d.POTrans = i.POTrans 
    		where d.InvdFlag <> i.InvdFlag
		END

	END

Trigger_Skip:

    return
   
    error:
       select @errmsg = @errmsg + ' - cannot update PO Job Material'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
   
   
   
   
   
   
  
 




GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPORD] ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biPORDMonth] ON [dbo].[bPORD] ([POCo], [Mth], [POTrans]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPORD] ON [dbo].[bPORD] ([POCo], [PO], [POItem], [Mth], [POTrans]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biPORDTrans] ON [dbo].[bPORD] ([POTrans], [Mth], [POCo]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPORD].[Purge]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPORD].[InvdFlag]'
GO
