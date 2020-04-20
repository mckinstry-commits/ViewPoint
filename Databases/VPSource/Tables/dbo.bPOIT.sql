CREATE TABLE [dbo].[bPOIT]
(
[POCo] [dbo].[bCompany] NOT NULL,
[PO] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[POItem] [dbo].[bItem] NOT NULL,
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
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[ReqDate] [dbo].[bDate] NULL,
[TaxGroup] [dbo].[bGroup] NULL,
[TaxCode] [dbo].[bTaxCode] NULL,
[TaxType] [tinyint] NULL,
[OrigUnits] [dbo].[bUnits] NOT NULL,
[OrigUnitCost] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bPOIT_OrigUnitCost] DEFAULT ((0)),
[OrigECM] [dbo].[bECM] NULL,
[OrigCost] [dbo].[bDollar] NOT NULL,
[OrigTax] [dbo].[bDollar] NOT NULL,
[CurUnits] [dbo].[bUnits] NOT NULL,
[CurUnitCost] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bPOIT_CurUnitCost] DEFAULT ((0)),
[CurECM] [dbo].[bECM] NULL,
[CurCost] [dbo].[bDollar] NOT NULL,
[CurTax] [dbo].[bDollar] NOT NULL,
[RecvdUnits] [dbo].[bUnits] NOT NULL,
[RecvdCost] [dbo].[bDollar] NOT NULL,
[BOUnits] [dbo].[bUnits] NOT NULL,
[BOCost] [dbo].[bDollar] NOT NULL,
[TotalUnits] [dbo].[bUnits] NOT NULL,
[TotalCost] [dbo].[bDollar] NOT NULL,
[TotalTax] [dbo].[bDollar] NOT NULL,
[InvUnits] [dbo].[bUnits] NOT NULL,
[InvCost] [dbo].[bDollar] NOT NULL,
[InvTax] [dbo].[bDollar] NOT NULL,
[RemUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bPOIT_RemUnits] DEFAULT ((0)),
[RemCost] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPOIT_RemCost] DEFAULT ((0)),
[RemTax] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPOIT_RemTax] DEFAULT ((0)),
[InUseMth] [dbo].[bMonth] NULL,
[InUseBatchId] [dbo].[bBatchID] NULL,
[PostedDate] [dbo].[bDate] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[RequisitionNum] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[AddedMth] [dbo].[bMonth] NULL,
[AddedBatchID] [dbo].[bBatchID] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[PayCategory] [int] NULL,
[PayType] [tinyint] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[INCo] [dbo].[bCompany] NULL,
[EMCo] [dbo].[bCompany] NULL,
[JCCo] [dbo].[bCompany] NULL,
[JCCmtdTax] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPOIT_JCCmtdTax] DEFAULT ((0.00)),
[Supplier] [dbo].[bVendor] NULL,
[SupplierGroup] [dbo].[bGroup] NULL,
[JCRemCmtdTax] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPOIT_JCRemCmtdTax] DEFAULT ((0.00)),
[TaxRate] [dbo].[bRate] NOT NULL CONSTRAINT [DF_bPOIT_TaxRate] DEFAULT ((0.00)),
[GSTRate] [dbo].[bRate] NOT NULL CONSTRAINT [DF_bPOIT_GSTRate] DEFAULT ((0.00)),
[SMCo] [dbo].[bCompany] NULL,
[SMWorkOrder] [int] NULL,
[InvMiscAmt] [dbo].[bDollar] NULL,
[SMScope] [int] NULL,
[SMPhaseGroup] [dbo].[bGroup] NULL,
[SMPhase] [dbo].[bPhase] NULL,
[SMJCCostType] [dbo].[bJCCType] NULL,
[udSource] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTableID] [decimal] (12, 0) NULL,
[udOnDate] [dbo].[bDate] NULL,
[udPlnOffDate] [dbo].[bDate] NULL,
[udActOffDate] [dbo].[bDate] NULL,
[udRentalNum] [varchar] (32) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biPOIT] ON [dbo].[bPOIT] ([POCo], [PO], [POItem]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPOIT] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

ALTER TABLE [dbo].[bPOIT] ADD
CONSTRAINT [CK_bPOIT_CurECM] CHECK (([CurECM]='E' OR [CurECM]='C' OR [CurECM]='M' OR [CurECM] IS NULL))
ALTER TABLE [dbo].[bPOIT] ADD
CONSTRAINT [CK_bPOIT_OrigECM] CHECK (([OrigECM]='E' OR [OrigECM]='C' OR [OrigECM]='M' OR [OrigECM] IS NULL))
ALTER TABLE [dbo].[bPOIT] ADD
CONSTRAINT [CK_bPOIT_RecvYN] CHECK (([RecvYN]='Y' OR [RecvYN]='N'))
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPOITd    Script Date: 8/28/99 9:38:07 AM ******/
CREATE  trigger [dbo].[btPOITd] on [dbo].[bPOIT] for DELETE as  

/*--------------------------------------------------------------
 *  Created By: LM 2/27/99
 *  Modified: 	GG 10/25/99 - Added checks for Received = Invoviced,
 *                          Remaining, AP Trans.  Add HQ Auditing.
 *			  	GF 09/30/2002 - Issue #18628 Changed the update of PMMF records.
 *				 Now sets interfaced date to null and send flag to 'N'.
 *				MV 12/06/02 - #18808 Add check to prevent deleting if Invoiced costs or units <> 0
 *				MV 08/08/03 - #22076 specify purge or non-purge delete when checking invoice, received, etc. 
 *				MV 09/03/03 - #22330 check of remaining cost, units should only apply to purge
 *				GF 02/14/2006 - issue #120167 when purging to not update bPMMF.
 *
 *
*  Delete trigger for PO Items
*
*--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255)

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

-- -- -- Purge = 'N' or 'Y' - Received must match Invoiced
if exists(select 1 from deleted where (UM = 'LS' and RecvdCost <> InvCost)
        or (UM <> 'LS' and RecvdUnits <> InvUnits))
        begin
        select @errmsg = 'Invoiced must equal Received '
        goto error
        end

-- -- -- Purge = 'Y' - Remaining must equal 0.00
if exists(select 1 from deleted d join bPOHD h WITH (NOLOCK) on d.POCo=h.POCo and d.PO=h.PO
   	 where (RemUnits <> 0 or RemCost <> 0) and h.Purge = 'Y')
        begin
        select @errmsg = 'Remaining units and costs must be 0.00 '
        goto error
        end

-- -- -- Purge = 'N' - check PO Change Detail
if exists(select 1 from deleted d
        join bPOCD c WITH (NOLOCK) on d.POCo = c.POCo and d.PO = c.PO and d.POItem = c.POItem
   	 join bPOHD h WITH (NOLOCK) on d.POCo=h.POCo and d.PO=h.PO
   	 where h.Purge = 'N' )
        begin
        select @errmsg = 'Change Detail exists '
        goto error
        end

-- -- -- Purge = 'N' - check PO Receipts Detail
if exists(select 1 from deleted d 
   	 join bPOHD h WITH (NOLOCK) on d.POCo=h.POCo and d.PO=h.PO
        join bPORD r WITH (NOLOCK) on d.POCo = r.POCo and d.PO = r.PO and d.POItem = r.POItem
   	 where h.Purge = 'N')
        begin
        select @errmsg = 'Receipts Detail exists '
        goto error
        end

-- -- -- Purge = 'N' - check PO Invoiced costs and units, received costs and units
if exists (select 1 from deleted d
   	 join bPOHD h WITH (NOLOCK) on d.POCo=h.POCo and d.PO=h.PO
   	 where (d.InvUnits <> 0 or d.InvCost <> 0) and (d.RecvdUnits <> 0 or d.RecvdCost<>0) and h.Purge = 'N')
         begin
         select @errmsg = 'Invoiced and Received Costs/Units must be zero '
         goto error
         end



-- -- -- Update related PMMF records
-- -- -- if not purging PO's then set interface date to null and send flag to 'N'
-- -- -- otherwise do not do anything with PMMF records
-- -- -- if exists(select 1 from bPMMF p with (nolock)
-- -- -- 		join deleted d on p.POCo = d.POCo and p.PO = d.PO and p.POItem = d.POItem
-- -- -- 		join bPOHD h with (nolock) on d.POCo=h.POCo and d.PO=h.PO and h.Purge = 'N')
-- -- -- 	begin
    update bPMMF Set InterfaceDate=NULL ----, SendFlag='N'
    from bPMMF p 
	join deleted d on p.POCo = d.POCo and p.PO = d.PO and p.POItem = d.POItem
	join bPOHD h on d.POCo=h.POCo and d.PO=h.PO and h.Purge = 'N'
-- -- -- 	end




-- -- -- HQ Auditing
insert bHQMA select 'bPOIT','POCo: ' + convert(varchar(3),d.POCo) + ' PO: ' + d.PO + ' Item: ' + convert(varchar(6),d.POItem),
        d.POCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from deleted d
join bPOCO c on d.POCo = c.POCo
join bPOHD h on d.POCo = h.POCo and d.PO = h.PO
where c.AuditPOs = 'Y' and h.Purge = 'N'  -- check audit and purge flags


return




error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot delete PO Items (bPOIT)'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/****** Object:  Trigger dbo.btPOITi    Script Date: 8/28/99 9:38:07 AM ******/   
CREATE trigger [dbo].[btPOITi] on [dbo].[bPOIT] for INSERT as
/*--------------------------------------------------------------
*  Created By:
*  Modified: GG 10/25/99 - Calculates Total and Remaining values.  Added HQ Audit.
*		DC  04/08/08 - #127019 Co input on grid does not validate, F4 or F5
*		TJL 04/08/09 - Issue #131500, Update POIT JCCmtdTax and JCRemCmtdTax
*		DC  09/29/09 - #122288, Store Tax Rate in POItem
*		GP 07/27/2011 - TK-07144 changed bPO to varchar(30)
*		GF 07/28/2011 - TK-07148 TK-07440 TK-07030 PO Item Disrtibution
*		TL  03/22/2012 - TK-13132 Added code to update new columns SMPhaseGroup,SMPhase,SMJCCostType to POItemLine
*
*
*  Insert trigger on bPOIT - PO Items
*
*--------------------------------------------------------------*/
declare @numrows int, @validcnt int, @errmsg varchar(255) ----, @poco bCompany,
	--@po varchar(30), @poitem bItem, @taxgroup bGroup, @taxcode bTaxCode, @recvdunits bUnits,
	--@recvdcost bDollar, @bounits bUnits, @bocost bDollar, @invunits bUnits, @invcost bDollar,
	--@rcode int, @posteddate bDate, @taxrate bRate, @opencursor tinyint, @um bUM,
	--@curunitcost bUnitCost, @curecm bECM, @factor smallint, @totalunits bUnits,
	--@remunits bUnits, @totalcost bDollar, @remcost bDollar, @totaltax bDollar, @remtax bDollar,
	--@valueadd bYN, @gstrate bRate, @pstrate bRate, @gsttaxamt bDollar, @HQTXdebtGLAcct bGLAcct,
	--@jccmtdtax bDollar, @jcremcmtdtax bDollar, @itemtype TINYINT,
	----TK-07148
	--@POITKeyID BIGINT
   
select @numrows = @@rowcount
if @numrows = 0 return

set nocount on
   
-- validate PO Header
select @validcnt = count(*)
from bPOHD r with (nolock) JOIN inserted i ON i.POCo = r.POCo and i.PO = r.PO
if @validcnt <> @numrows
	BEGIN
	select @errmsg = 'PO is Invalid '
	goto error
	END
   
---- make sure 'LS' Items have 0.00 units and unit costs
if exists(select 1 from inserted where UM = 'LS' and (OrigUnits <> 0 or OrigUnitCost <> 0 or CurUnits <> 0 or CurUnitCost <> 0
				or RecvdUnits <> 0 or BOUnits <> 0 or InvUnits <> 0))
	BEGIN
	select @errmsg = 'Lump sum PO Items must have 0.00 Units and Unit Costs '
	goto error
	END

---- make sure unit based Items have 0.00 Recvd and BO Costs
if exists(select 1 from inserted where UM <> 'LS' and (RecvdCost <> 0 or BOCost <> 0))
	BEGIN
	select @errmsg = 'Unit based PO Items must have 0.00 Received and Backordered Costs '
	goto error
	END
	
---- Check Job Line type PostToCo = JCCo
if exists(select 1 from inserted Where ItemType = 1 and PostToCo <> JCCo) 
	BEGIN
	select @errmsg = 'PostToCo and JCCo are not in sync '
	goto error
	END

--Check Job Line type PostToCo = INCo
if exists(select 1 from inserted Where ItemType = 2 and PostToCo <> INCo) 
	BEGIN
	select @errmsg = 'PostToCo and INCo are not in sync '
	goto error
	END

--Check Job Line type PostToCo = EMCo
if exists(select 1 from inserted Where ItemType IN (4,5) and PostToCo <> EMCo) 
	BEGIN
	select @errmsg = 'PostToCo and EMCo are not in sync '
	goto error
	END

--Check SM Line type PostToCo = SMCo
if exists(select 1 from inserted Where ItemType = 6 and PostToCo <> SMCo) 
	BEGIN
	select @errmsg = 'PostToCo and SMCo are not in sync '
	goto error
	END

---- insert line 1 into PO Item Line table. Line 1 represents the item values.
---- the PO Item Line triggers will update the POIT with Total and Remaining units, costs, and taxes
INSERT INTO dbo.vPOItemLine
	(	POITKeyID, POCo, PO, POItem, POItemLine, ItemType, PostToCo, JCCo, Job,
		PhaseGroup, Phase, JCCType, INCo, Loc, EMCo, EMGroup, Equip, CompType,
		Component, CostCode, EMCType, WO, WOItem, SMCo, SMWorkOrder, SMScope, SMPhaseGroup,SMPhase,SMJCCostType,
		TaxGroup, TaxType, TaxCode, TaxRate, GSTRate, GLCo, GLAcct, ReqDate,
		PayCategory, PayType, OrigUnits, OrigCost, OrigTax, CurUnits, CurCost,
		CurTax, RecvdUnits, RecvdCost, BOUnits, BOCost, InvUnits, InvCost,
		InvTax, InvMiscAmt, RemUnits, RemCost, RemTax, JCCmtdTax, JCRemCmtdTax,
		TotalUnits, TotalCost, TotalTax, PostedDate, JCMonth
	)
SELECT  i.KeyID, i.POCo, i.PO, i.POItem, 1, i.ItemType, i.PostToCo, i.JCCo, i.Job,
		i.PhaseGroup, i.Phase, i.JCCType, i.INCo, i.Loc, i.EMCo, i.EMGroup, i.Equip,
		i.CompType, i.Component, i.CostCode, i.EMCType, i.WO, i.WOItem, i.SMCo, i.SMWorkOrder,i.SMScope,i.SMPhaseGroup,i.SMPhase,i.SMJCCostType,
		 i.TaxGroup, i.TaxType, i.TaxCode, i.TaxRate, i.GSTRate, i.GLCo, i.GLAcct,
		i.ReqDate, i.PayCategory, i.PayType, i.OrigUnits, i.OrigCost, i.OrigTax, i.CurUnits,
		i.CurCost, i.CurTax, i.RecvdUnits, i.RecvdCost, i.BOUnits, i.BOCost, i.InvUnits,
		i.InvCost, i.InvTax, ISNULL(i.InvMiscAmt,0), i.RemUnits, i.RemCost, i.RemTax, i.JCCmtdTax,
		i.JCRemCmtdTax, i.TotalUnits, i.TotalCost, i.TotalTax, i.PostedDate, i.AddedMth
		----TK-07440 TK-07030
		--CASE i.ItemType WHEN 1 THEN i.AddedMth ELSE NULL END
FROM INSERTED i
----WHERE NOT EXISTS(SELECT 1 FROM dbo.vPOItemLine l WHERE l.POITKeyID = i.KeyID AND l.POItemLine = 1)
--FROM dbo.bPOIT i WHERE i.KeyID=@POITKeyID
--if @@rowcount <> 1
--	BEGIN
--	select @errmsg = 'Invalid PO Item, cannot insert PO Item Distribution line.'
--	goto error
--	END

	
	

---- NOW IN THE PO ITEM LINE INSERT TRIGGER
--if @numrows = 1
--	BEGIN
--  	select @poco = POCo, @po = PO, @poitem = POItem, @um = UM, @curunitcost = CurUnitCost,
--		@curecm = CurECM, @taxgroup = TaxGroup, @taxcode = TaxCode, @recvdunits = RecvdUnits,
--		@recvdcost = RecvdCost, @bounits = BOUnits, @bocost = BOCost, @invunits = InvUnits,
--		@invcost = InvCost, @posteddate = PostedDate, @itemtype = ItemType,
--		@taxrate = TaxRate, @gstrate = GSTRate,
--		----TK-07148
--		@POITKeyID = KeyID
--	from inserted
--	END
--else
--	BEGIN
--	-- use a cursor to update Total and Remaining values
--	declare bPOIT_insert cursor for
--   	select POCo, PO, POItem, UM, CurUnitCost, CurECM, TaxGroup, TaxCode, RecvdUnits, RecvdCost,
--		BOUnits, BOCost, InvUnits, InvCost, PostedDate, ItemType,
--		TaxRate, GSTRate,
--		----TK-07148
--		KeyID
--	from inserted

--	open bPOIT_insert
--	select @opencursor = 1

--	-- get 1st Item inserted
--	fetch next from bPOIT_insert into @poco, @po, @poitem, @um, @curunitcost, @curecm,
--		@taxgroup, @taxcode, @recvdunits, @recvdcost, @bounits, @bocost, @invunits, @invcost, @posteddate,
--		@itemtype, @taxrate, @gstrate,
--		----TK-07148
--		@POITKeyID

--	if @@fetch_status <> 0
--		BEGIN
--		select @errmsg = 'Cursor error '
--		goto error
--		END
--	END
   
----Check Job Line type PostToCo = JCCo
--if exists (select 1 from inserted Where POCo = @poco and PO = @po and POItem = @poitem and ItemType = 1 and PostToCo <> JCCo) 
--	BEGIN
--	select @errmsg = 'PostToCo and JCCo are not in sync '
--	goto error
--	END

----Check Job Line type PostToCo = INCo
--if exists (select 1 from inserted Where POCo = @poco and PO = @po and POItem = @poitem and ItemType = 2 and PostToCo <> INCo) 
--	BEGIN
--	select @errmsg = 'PostToCo and INCo are not in sync '
--	goto error
--	END

----Check Job Line type PostToCo = EMCo
--if exists (select 1 from inserted Where POCo = @poco and PO = @po and POItem = @poitem and ItemType in(4,5) and PostToCo <> EMCo) 
--	BEGIN
--	select @errmsg = 'PostToCo and EMCo are not in sync '
--	goto error
--	END

--Get_TaxRate:    -- get Tax Rate to recalculate tax amounts

-- calculate Total and Remaining
--if @um = 'LS'
--	BEGIN
--   	select @recvdunits=0, @bounits=0, @totalunits = 0, @remunits = 0
--	select @totalcost = @recvdcost + @bocost
--	select @remcost = @totalcost - @invcost
--	END
--else
--	BEGIN
--	select @factor = case @curecm when 'C' then 100 when 'M' then 1000 else 1 end
--   	select @totalunits = @recvdunits + @bounits
--	select @totalcost = (@totalunits * @curunitcost) / @factor
--   	select @remunits = @totalunits - @invunits
--	select @remcost =  (@remunits * @curunitcost) / @factor
--	END

---- Calculate POIT Tax amounts
--if @taxgroup is not null and @taxcode is not null
--	BEGIN
--	--select @taxrate = 0, @gstrate = 0, @pstrate = 0  'DC #122288
--	Select @pstrate = 0  --'DC #122288

--	--DC #122288
--	exec @rcode = vspHQTaxRateGet @taxgroup, @taxcode, @posteddate, @valueadd output, NULL, NULL, NULL, 
--		NULL, @pstrate output, NULL, NULL, @HQTXdebtGLAcct output, NULL, NULL, NULL, @errmsg output

--	/*exec @rcode = bspHQTaxRateGetAll @taxgroup, @taxcode, @posteddate, @valueadd output, @taxrate output, @gstrate output, @pstrate output, 
--		null, null, @HQTXdebtGLAcct output, null, null, null, @errmsg output */					
--	if @rcode <> 0
--		BEGIN
--		select @errmsg = 'Tax Rates could not be determined.'
--		goto error
--		END

--	if @gstrate = 0 and @pstrate = 0 and @valueadd = 'Y'
--		BEGIN
--		-- We have an Intl VAT code being used as a Single Level Code
--		if (select GST from bHQTX with (nolock) where TaxGroup = @taxgroup and TaxCode = @taxcode) = 'Y'
--			BEGIN
--			select @gstrate = @taxrate
--			END
--		END

--	-- calculate Tax
--	select @totaltax = @totalcost * @taxrate		--Full TaxAmount:  This is correct whether US, Intl GST&PST, Intl GST only, Intl PST only  1000 * .155 = 155
--	select @remtax = @remcost * @taxrate

--	-- calculate JCCmtdTax
--	select @gsttaxamt = case when @taxrate = 0 then 0 else case @valueadd when 'Y' then (@totaltax * @gstrate) / @taxrate else 0 end end	--GST Tax Amount.  (Calculated)					(155 * .05) / .155 = 50
--	--select @psttaxamt = case @valueadd when 'Y' then @origtax - @gsttaxamt else 0 end														--PST Tax Amount.  (Rounding errors to PST)
--	select @jccmtdtax = case when @itemtype = 1 then @totaltax - (case when @HQTXdebtGLAcct is null then 0 else @gsttaxamt end) else 0 end

--	-- calculate JCRemCmtdTax
--	select @gsttaxamt = case when @taxrate = 0 then 0 else case @valueadd when 'Y' then (@remtax * @gstrate) / @taxrate else 0 end end
--	select @jcremcmtdtax = case when @itemtype = 1 then @remtax - (case when @HQTXdebtGLAcct is null then 0 else @gsttaxamt end) else 0 end  
--	END

---- update Item with Total and Remaining units, costs, and taxes
--update dbo.bPOIT
--set TotalUnits = @totalunits, TotalCost = @totalcost, TotalTax = isnull(@totaltax, TotalTax),
--	RemUnits = @remunits, RemCost = @remcost, RemTax = isnull(@remtax, RemTax), JCCmtdTax = isnull(@jccmtdtax, JCCmtdTax),
--	JCRemCmtdTax = isnull(@jcremcmtdtax, JCRemCmtdTax)
--WHERE KeyID=@POITKeyID
--if @@rowcount <> 1
--	BEGIN
--	select @errmsg = 'Invalid PO Item '
--	goto error
--	END


--if @numrows > 1
--	BEGIN
--	fetch next from bPOIT_insert into @poco, @po, @poitem, @um, @curunitcost, @curecm,
--	@taxgroup, @taxcode, @recvdunits, @recvdcost, @bounits, @bocost, @invunits, @invcost, @posteddate,
--	@itemtype, @taxrate, @gstrate  --DC #122288

--	if @@fetch_status = 0 goto Get_TaxRate

--	close bPOIT_insert
--	deallocate bPOIT_insert
--	select @opencursor = 0
--	END



---- HQ Auditing
insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bPOIT',  'PO:' + i.PO, i.POCo, 'A', null, null, null, getdate(), SUSER_SNAME()
from inserted i
join bPOCO c on i.POCo = c.POCo
where c.AuditPOs = 'Y'
   
return
   
error:
--if @opencursor = 1
--	BEGIN
--	close bPOIT_insert
--	deallocate bPOIT_insert
--	END
   
select @errmsg = @errmsg + ' - cannot insert PO Items'
RAISERROR(@errmsg, 11, -1);
rollback transaction
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/****** Object:  Trigger dbo.btPOITu    Script Date: 8/28/99 9:38:25 AM ******/
CREATE trigger [dbo].[btPOITu] on [dbo].[bPOIT] for UPDATE as   
/*--------------------------------------------------------------
*  Created By:
*  Modified By: kb 12/14/98
*		GG 10/25/99 - Update Total and Remaining values - added HQ audit updates
*		GF 08/12/2003 - issue #22112 - performance
*		MV 03/04/04 - 18769 - add PayCategory to audit.
*		TJL 04/08/09 - Issue #131500, Update POIT JCCmtdTax and JCRemCmtdTax
*		TJL 04/10/09 - Issue #130148, Update Tax Amounts only when TotalCost, RemCost or CurTax change
*		DC 09/30/09 - #122288 - Store Tax Rate in PO Item
*		DC 3/16/10 - #137840 - CurTax and RemTax remains on POItem after TaxType and TaxCode are cleared
*		DC 11/16/10 - #142034 - Only make sure unit based Items have 0.00 Recvd and BO Costs if Recvd or BOCost columns are beginning updated.
*		MH 12/02/10 - 131640 - Added audits for SM
*		GP 7/27/2011 - TK-07144 changed bPO to varchar(30)
*		GF 08/04/2011 - TK-07440 TK-07438 TK-07439 update PO Item Line one with item changes
*		GF 01/22/2012 TK-11964 #145600
*		TL  03/22/2012 - TK-13132 Added code to update new columns SMPhaseGroup,SMPhase,SMJCCostType to POItemLine
*		DAN SO 06/21/2012 - TK-15925 - SMJCostType updates not getting to POItemLine
*
*
*  Update trigger for PO Items
*
*--------------------------------------------------------------*/
declare @numrows int, @validcnt int, @errmsg varchar(255), @poco bCompany,
	@po varchar(30), @poitem bItem, @taxgroup bGroup, @taxcode bTaxCode, @recvdunits bUnits,
	@recvdcost bDollar, @bounits bUnits, @bocost bDollar, @invunits bUnits, @invcost bDollar,
	@rcode int, @posteddate bDate, @taxrate bRate, @opencursor tinyint, @um bUM,
	@curunitcost bUnitCost, @curcost bDollar, @curecm bECM, @factor smallint, @totalunits bUnits,
	@remunits bUnits, @totalcost bDollar, @remcost bDollar, @totaltax bDollar, @remtax bDollar,
	@valueadd bYN, @gstrate bRate, @pstrate bRate, @gsttaxamt bDollar, @HQTXdebtGLAcct bGLAcct,
	@jccmtdtax bDollar, @jcremcmtdtax bDollar, @oldtotalcost bDollar, @oldremcost bDollar,
	@currtax bDollar, @oldcurrtax bDollar, @itemtype tinyint, @oldtaxcode bTaxCode
   
select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

set @opencursor = 0
   
-- check for key changes
if update(POCo) or update(PO) or update(POItem)
	BEGIN
	select @errmsg = 'Cannot change PO Company, PO, or Item '
	goto error
	END
   
-- make sure 'LS' Items have 0.00 units and unit costs
if exists(select 1 from inserted where UM = 'LS' and (OrigUnits <> 0 or OrigUnitCost <> 0 or CurUnits <> 0 or CurUnitCost <> 0
			or RecvdUnits <> 0 or BOUnits <> 0 or InvUnits <> 0))
	BEGIN
	--declare @mykeyid varchar(15)
	--select @mykeyid = cast(KeyID as varchar(15)) from inserted
	--select @errmsg = '*** DAN SO TESTING *** KeyID: ' + @mykeyid
	select @errmsg = 'Lump sum PO Items must have 0.00 Units and Unit Costs '
	goto error
	END
   
--DC #142034
IF UPDATE(UM) or UPDATE(RecvdCost) or UPDATE(BOCost)
	BEGIN
	-- make sure unit based Items have 0.00 Recvd and BO Costs
	if exists(select 1 from inserted where UM <> 'LS' and (RecvdCost <> 0 or BOCost <> 0))
		BEGIN
		select @errmsg = 'Unit based PO Items must have 0.00 Received and Backordered Costs '
		goto error
		END
	END

--Check Job Line type PostToCo = JCCo
if exists (select 1 from inserted Where ItemType = 1 and PostToCo <> JCCo) 
	BEGIN
	select @errmsg = 'PostToCo and JCCo are not in sync '
	goto error
	END

--Check Job Line type PostToCo = INCo
if exists (select 1 from inserted Where ItemType = 2 and PostToCo <> INCo) 
	BEGIN
	select @errmsg = 'PostToCo and INCo are not in sync '
	goto error
	END

--Check Job Line type PostToCo = EMCo
if exists (select 1 from inserted Where ItemType in(4,5) and PostToCo <> EMCo) 
	BEGIN
	select @errmsg = 'PostToCo and EMCo are not in sync '
	goto error
	END
	
--Check SM Line type PostToCo = SMCo
if exists (select 1 from inserted Where ItemType = 6 and PostToCo <> SMCo) 
	BEGIN
	select @errmsg = 'PostToCo and SMCo are not in sync '
	goto error
	END

---- TK-07439
---- the PO Item Line triggers will update the POIT with Total and Remaining units, costs, and taxes
---- update PO Item Line 1 (item line) for existing item info. The where clause will only update
---- PO Item Line when there is a difference between old and new values. Need to do this, so
---- that we do not get stuck in a loop between the line update trigger and the item update trigger.
UPDATE dbo.vPOItemLine
		SET ItemType = i.ItemType, PostToCo = i.PostToCo, Loc = i.Loc, Job = i.Job,
			PhaseGroup = i.PhaseGroup, Phase = i.Phase, JCCType = i.JCCType,
			Equip = i.Equip, CompType = i.CompType, Component = i.Component, EMGroup = i.EMGroup,
			CostCode = i.CostCode, EMCType = i.EMCType, WO = i.WO, WOItem = i.WOItem,
			GLCo = i.GLCo, GLAcct = i.GLAcct, ReqDate = i.ReqDate, TaxGroup = i.TaxGroup,
			TaxCode = i.TaxCode, TaxType = i.TaxType, OrigUnits = i.OrigUnits, OrigCost = i.OrigCost,
			OrigTax = i.OrigTax, CurUnits = i.CurUnits, CurCost = i.CurCost, CurTax = i.CurTax,
			BOUnits = i.BOUnits, BOCost = i.BOCost,
			PayType = i.PayType, PayCategory = i.PayCategory,
			INCo = i.INCo, EMCo = i.EMCo, JCCo = i.JCCo, TaxRate = i.TaxRate,
			GSTRate = i.GSTRate, SMCo = i.SMCo, SMWorkOrder = i.SMWorkOrder,
			SMScope = i.SMScope, SMPhaseGroup=i.SMPhaseGroup,SMPhase=i.SMPhase,SMJCCostType=i.SMJCCostType,
			PostedDate = i.PostedDate,
			----TK-07030 TK-07440 TK-11964
			JCMonth = CASE i.ItemType WHEN 1 THEN ISNULL(i.AddedMth, dbo.vfDateOnlyMonth()) ELSE NULL END
FROM INSERTED i
INNER JOIN DELETED d ON d.KeyID = i.KeyID
INNER JOIN dbo.vPOItemLine l ON l.POITKeyID = i.KeyID AND l.POItemLine = 1
WHERE i.KeyID = l.POITKeyID
	AND l.POItemLine = 1
	AND
	(
		i.ItemType	<> d.ItemType
		OR i.PostToCo <> d.PostToCo
		OR ISNULL(i.Loc,'') <> ISNULL(d.Loc,'')
		OR ISNULL(i.Job,'') <> ISNULL(d.Job,'')
		OR ISNULL(i.PhaseGroup,0) <> ISNULL(d.PhaseGroup,0)
		OR ISNULL(i.Phase,'') <> ISNULL(d.Phase,'')
		OR ISNULL(i.JCCType,0) <> ISNULL(d.JCCType,0)
		OR ISNULL(i.Equip,'') <> ISNULL(d.Equip,'')
		OR ISNULL(i.CompType,'') <> ISNULL(d.CompType,'')
		OR ISNULL(i.Component,'') <> ISNULL(d.Component,'')
		OR ISNULL(i.EMGroup,'') <> ISNULL(d.EMGroup,'')
		OR ISNULL(i.CostCode,'') <> ISNULL(d.CostCode,'')		
		OR ISNULL(i.EMCType,0) <> ISNULL(d.EMCType,0)
		OR ISNULL(i.WO,'') <> ISNULL(d.WO,'')
		OR ISNULL(i.WOItem,'') <> ISNULL(d.WOItem,'')
		OR ISNULL(i.GLCo,0) <> ISNULL(d.GLCo,0)
		OR ISNULL(i.GLAcct,'') <> ISNULL(d.GLAcct,'')
		OR ISNULL(i.ReqDate,'') <> ISNULL(d.ReqDate,'')
		OR ISNULL(i.TaxGroup,0) <> ISNULL(d.TaxGroup,0)
		OR ISNULL(i.TaxCode,'') <> ISNULL(d.TaxCode,'')
		OR ISNULL(i.TaxType,0) <> ISNULL(d.TaxType,0)
		OR ISNULL(i.PayType,0) <> ISNULL(d.PayType,0)
		OR ISNULL(i.PayCategory,0) <> ISNULL(d.PayCategory,0)
		OR ISNULL(i.INCo,0) <> ISNULL(d.INCo,0)
		OR ISNULL(i.EMCo,0) <> ISNULL(d.EMCo,0)
		OR ISNULL(i.JCCo,0) <> ISNULL(d.JCCo,0)
		OR ISNULL(i.SMCo,0) <> ISNULL(d.SMCo,0)
		OR ISNULL(i.SMWorkOrder,0) <> ISNULL(d.SMWorkOrder,0)
		OR ISNULL(i.SMScope,0) <> ISNULL(d.SMScope,0)
		OR ISNULL(i.SMJCCostType,0) <> ISNULL(d.SMJCCostType,0)	-- TK-15925 --
		OR i.OrigUnits <> d.OrigUnits
		OR i.OrigCost <> d.OrigCost
		OR i.OrigTax <> d.OrigTax
		OR i.TaxRate <> d.TaxRate
		OR i.GSTRate <> d.GSTRate

	)




--if @numrows = 1
--	BEGIN
--	select @poco = i.POCo, @po = i.PO, @poitem = i.POItem, @um = i.UM, @curunitcost = i.CurUnitCost,
--		@curcost = i.CurCost, @curecm = i.CurECM, @taxgroup = i.TaxGroup, @taxcode = i.TaxCode, 
--		@recvdunits = i.RecvdUnits, @recvdcost = i.RecvdCost, @bounits = i.BOUnits, @bocost = i.BOCost, 
--		@invunits = i.InvUnits, @invcost = i.InvCost, @posteddate = i.PostedDate, @currtax = i.CurTax,
--		@itemtype = i.ItemType, @oldtotalcost = d.TotalCost, @oldremcost = d.RemCost, @oldcurrtax = d.CurTax,
--		@oldtaxcode = d.TaxCode,
--		@taxrate = i.TaxRate, @gstrate = i.GSTRate  --DC #122288
--	from inserted i
--	join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
--	END
--else
--	BEGIN
--	declare bPOIT_update cursor LOCAL FAST_FORWARD
--   	for select i.POCo, i.PO, i.POItem, i.UM, i.CurUnitCost, i.CurCost, i.CurECM, i.TaxGroup, i.TaxCode, i.RecvdUnits, i.RecvdCost,
--   		i.BOUnits, i.BOCost, i.InvUnits, i.InvCost, i.PostedDate, i.CurTax, i.ItemType, d.TotalCost, d.RemCost, d.CurTax,
--		d.TaxCode, i.TaxRate, i.GSTRate  --DC #122288 
--	from inserted i
--	join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem

--	open bPOIT_update
--	select @opencursor = 1
   
--	fetch next from bPOIT_update into @poco, @po, @poitem, @um, @curunitcost, @curcost, @curecm,
--   		@taxgroup, @taxcode, @recvdunits, @recvdcost, @bounits, @bocost, @invunits, @invcost, @posteddate, @currtax,
--		@itemtype, @oldtotalcost, @oldremcost, @oldcurrtax, @oldtaxcode, @taxrate, @gstrate  --DC #122288
   
--	if @@fetch_status <> 0
--		BEGIN
--		select @errmsg = 'Cursor error '
--		goto error
--		END
--	END

------Check Job Line type PostToCo = JCCo
----if exists (select 1 from inserted Where POCo = @poco and PO = @po and POItem = @poitem and ItemType = 1 and PostToCo <> JCCo) 
----	BEGIN
----	select @errmsg = 'PostToCo and JCCo are not in sync '
----	goto error
----	END

------Check Job Line type PostToCo = INCo
----if exists (select 1 from inserted Where POCo = @poco and PO = @po and POItem = @poitem and ItemType = 2 and PostToCo <> INCo) 
----	BEGIN
----	select @errmsg = 'PostToCo and INCo are not in sync '
----	goto error
----	END

------Check Job Line type PostToCo = EMCo
----if exists (select 1 from inserted Where POCo = @poco and PO = @po and POItem = @poitem and ItemType in(4,5) and PostToCo <> EMCo) 
----	BEGIN
----	select @errmsg = 'PostToCo and EMCo are not in sync '
----	goto error
----	END
   
--Get_TaxRate:    -- get Tax Rate to recalculate tax amounts

---- calculate Total and Remaining
--if @um = 'LS'
--	BEGIN
--   	select @recvdunits=0, @bounits=0, @totalunits = 0, @remunits = 0
--   	select @totalcost = @recvdcost + @bocost
--   	select @remcost = @totalcost - @invcost
--   	END
--else
--   	BEGIN
--   	select @factor = case @curecm when 'C' then 100 when 'M' then 1000 else 1 end
--   	select @totalunits = @recvdunits + @bounits
--   	select @totalcost = (@totalunits * @curunitcost) / @factor
--   	select @remunits = @totalunits - @invunits
--   	select @remcost =  (@remunits * @curunitcost) / @factor
--   	END

----DC #137843  --The @totaltax, @remtax, @jccmtdtax and @jcremcmtdtax do not get set to anything 
----if there is no tax code.  Below if those variable are null, it uses the original value from POIT
----which was causing problems.  I solved those problems by setting these variables to 0.00 if there is no tax code
--IF @taxcode is null
--	BEGIN
--	select @totaltax = 0.00, @remtax = 0.00, @jccmtdtax = 0.00, @jcremcmtdtax = 0.00
--	END

---- Calculate POIT Tax amounts only if we have TaxCode and either TotalCost or RemCost has changed.
--if @taxgroup is not null and @taxcode is not null	
--	and (@totalcost <> @oldtotalcost or @remcost <> @oldremcost or @currtax <> @oldcurrtax or @taxcode <> @oldtaxcode)
--	BEGIN
--	--select @taxrate = 0, @gstrate = 0, @pstrate = 0  'DC #122288
--	select @pstrate = 0  --'DC #122288

--	--DC #122288
--	exec @rcode = vspHQTaxRateGet @taxgroup, @taxcode, @posteddate, @valueadd output, NULL, NULL, NULL, 
--		NULL, @pstrate output, NULL, NULL, @HQTXdebtGLAcct output, NULL, NULL, NULL, @errmsg output

--	/*exec @rcode = bspHQTaxRateGetAll @taxgroup, @taxcode, @posteddate, @valueadd output, @taxrate output, @gstrate output, @pstrate output, 
--		null, null, @HQTXdebtGLAcct output, null, null, null, @errmsg output */					
--	if @rcode <> 0
--		BEGIN
--		select @errmsg = 'Tax Rates could not be determined.'
--		goto error
--		END

--	if @gstrate = 0 and @pstrate = 0 and @valueadd = 'Y'
--		BEGIN
--		-- We have an Intl VAT code being used as a Single Level Code
--		if (select GST from bHQTX with (nolock) where TaxGroup = @taxgroup and TaxCode = @taxcode) = 'Y'
--			BEGIN
--			select @gstrate = @taxrate
--			END
--		END

--	--Calculate Tax Amounts
--	if (@totalcost <> @oldtotalcost or @currtax <> @oldcurrtax or @taxcode <> @oldtaxcode)
--		BEGIN
--		select @totaltax = @totalcost * @taxrate		--Full TaxAmount:  This is correct whether US, Intl GST&PST, Intl GST only, Intl PST only  (1000 * .155 = 155)

--		-- calculate JCCmtdTax
--		select @gsttaxamt = case when @taxrate = 0 then 0 else case @valueadd when 'Y' then (@totaltax * @gstrate) / @taxrate else 0 end end	--GST Tax Amount.  ((Calculated)	(155 * .05) / .155 = 50)
--		--select @psttaxamt = case @valueadd when 'Y' then @origtax - @gsttaxamt else 0 end														--PST Tax Amount.  (Rounding errors to PST)
--		select @jccmtdtax = case when @itemtype = 1 then @totaltax - (case when @HQTXdebtGLAcct is null then 0 else @gsttaxamt end) else 0 end
--		END

--	if (@remcost <> @oldremcost or @currtax <> @oldcurrtax or @taxcode <> @oldtaxcode)
--		BEGIN
--		select @remtax = @remcost * @taxrate

--		-- calculate JCRemCmtdTax
--		select @gsttaxamt = case when @taxrate = 0 then 0 else case @valueadd when 'Y' then (@remtax * @gstrate) / @taxrate else 0 end end
--		select @jcremcmtdtax = case when @itemtype = 1 then @remtax - (case when @HQTXdebtGLAcct is null then 0 else @gsttaxamt end) else 0 end
--		END
-- 	END

---- update Item with Total and Remaining units, costs, and taxes
--update bPOIT
--set TotalUnits = @totalunits, TotalCost = @totalcost, TotalTax = isnull(@totaltax, TotalTax), BOCost=@bocost,
--	RemUnits = @remunits, RemCost = @remcost, RemTax = isnull(@remtax, RemTax), JCCmtdTax = isnull(@jccmtdtax, JCCmtdTax),
--	JCRemCmtdTax = isnull(@jcremcmtdtax, JCRemCmtdTax)
--where POCo = @poco and PO = @po and POItem = @poitem
--if @@rowcount <> 1
--	BEGIN
--	select @errmsg = 'Invalid PO Item '
--	goto error
--	END

--if @numrows > 1
--   	BEGIN
--   	fetch next from bPOIT_update into @poco, @po, @poitem, @um, @curunitcost, @curcost, @curecm,
--   		@taxgroup, @taxcode, @recvdunits, @recvdcost, @bounits, @bocost, @invunits, @invcost, @posteddate, @currtax,
--		@itemtype, @oldtotalcost, @oldremcost, @oldcurrtax, @oldtaxcode, 
--		@taxrate, @gstrate  --DC #122288
   
--   	if @@fetch_status = 0 goto Get_TaxRate
   
--   	close bPOIT_update
--   	deallocate bPOIT_update
--   	select @opencursor = 0
--   	END

-- Insert records into HQMA for changes made to audited fields
IF NOT EXISTS (select 1 from inserted i join dbo.bPOCO c with (nolock) on c.POCo = i.POCo where c.AuditPOs = 'Y')
	BEGIN
	RETURN
	END


if update(ItemType)
	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPOIT', 'PO:' + i.PO + ' Item: ' + convert(varchar(6),i.POItem), i.POCo, 'C',
	 	'Item Type', Convert(varchar(2),d.ItemType), Convert(varchar(2),i.ItemType), getdate(), SUSER_SNAME()
 	from inserted i
    join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
    join bPOCO c with (nolock) on c.POCo = i.POCo
    where i.ItemType <> d.ItemType and c.AuditPOs = 'Y'

if update(MatlGroup)
    insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPOIT', 'PO:' + i.PO + ' Item: ' + convert(varchar(6),i.POItem), i.POCo, 'C',
	 	'Matl Group', convert(varchar(3),d.MatlGroup), convert(varchar(3),i.MatlGroup), getdate(), SUSER_SNAME()
    from inserted i
   	join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
    join bPOCO c with (nolock) on c.POCo = i.POCo
    where i.MatlGroup <> d.MatlGroup and c.AuditPOs = 'Y'

if update(Material)
    insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPOIT', 'PO:' + i.PO + ' Item: ' + convert(varchar(6),i.POItem), i.POCo, 'C',
	 	'Material', d.Material, i.Material, getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
    join bPOCO c with (nolock) on c.POCo = i.POCo
    where isnull(i.Material,'') <> isnull(d.Material,'') and c.AuditPOs = 'Y'

if update(VendMatId)
    insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPOIT', 'PO:' + i.PO + ' Item: ' + convert(varchar(6),i.POItem), i.POCo, 'C',
	 	'Vendor Matl', d.VendMatId, i.VendMatId, getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
    join bPOCO c with (nolock) on c.POCo = i.POCo
    where isnull(i.VendMatId,'') <> isnull(d.VendMatId,'') and c.AuditPOs = 'Y'

if update(Description)
    insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPOIT', 'PO:' + i.PO + ' Item: ' + convert(varchar(6),i.POItem), i.POCo, 'C',
	 	'Description', d.Description, i.Description, getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
    join bPOCO c with (nolock) on c.POCo = i.POCo
    where isnull(i.Description,'') <> isnull(d.Description,'') and c.AuditPOs = 'Y'

if update(UM)
    insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPOIT', 'PO:' + i.PO + ' Item: ' + convert(varchar(6),i.POItem), i.POCo, 'C',
	 	'UM', d.UM, i.UM, getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
    join bPOCO c with (nolock) on c.POCo = i.POCo
    where i.UM <> d.UM and c.AuditPOs = 'Y'

if update(RecvYN)
    insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPOIT', 'PO:' + i.PO + ' Item: ' + convert(varchar(6),i.POItem), i.POCo, 'C',
	 	'Receiving', d.RecvYN, i.RecvYN, getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
    join bPOCO c with (nolock) on c.POCo = i.POCo
    where i.RecvYN <> d.RecvYN and c.AuditPOs = 'Y'

if update(PostToCo)
    insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPOIT', 'PO:' + i.PO + ' Item: ' + convert(varchar(6),i.POItem), i.POCo, 'C',
	 	'Post To Co#', convert(varchar(3),d.PostToCo), convert(varchar(3),i.PostToCo), getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
    join bPOCO c with (nolock) on c.POCo = i.POCo
    where i.PostToCo <> d.PostToCo and c.AuditPOs = 'Y'

if update(Loc)
    insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPOIT', 'PO:' + i.PO + ' Item: ' + convert(varchar(6),i.POItem), i.POCo, 'C',
	 	'Location', d.Loc, i.Loc, getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
    join bPOCO c with (nolock) on c.POCo = i.POCo
    where isnull(i.Loc,'') <> isnull(d.Loc,'') and c.AuditPOs = 'Y'

if update(Job)
    insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPOIT', 'PO:' + i.PO + ' Item: ' + convert(varchar(6),i.POItem), i.POCo, 'C',
	 	'Job', d.Job, i.Job, getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
    join bPOCO c with (nolock) on c.POCo = i.POCo
    where isnull(i.Job,'') <> isnull(d.Job,'') and c.AuditPOs = 'Y'

if update(Phase)
    insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPOIT', 'PO:' + i.PO + ' Item: ' + convert(varchar(6),i.POItem), i.POCo, 'C',
	 	'Phase', d.Phase, i.Phase, getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
    join bPOCO c with (nolock) on c.POCo = i.POCo
    where isnull(i.Phase,'') <> isnull(d.Phase,'') and c.AuditPOs = 'Y'

if update(JCCType)
    insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPOIT', 'PO:' + i.PO + ' Item: ' + convert(varchar(6),i.POItem), i.POCo, 'C',
	 	'JC Cost Type', convert(varchar(3),d.JCCType), convert(varchar(3),i.JCCType), getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
    join bPOCO c with (nolock) on c.POCo = i.POCo
    where isnull(i.JCCType,0) <> isnull(d.JCCType,0) and c.AuditPOs = 'Y'

if update(Equip)
    insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPOIT', 'PO:' + i.PO + ' Item: ' + convert(varchar(6),i.POItem), i.POCo, 'C',
	 	'Equipment', d.Equip, i.Equip, getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
    join bPOCO c with (nolock) on c.POCo = i.POCo
    where isnull(i.Equip,'') <> isnull(d.Equip,'') and c.AuditPOs = 'Y'

if update(Component)
    insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPOIT', 'PO:' + i.PO + ' Item: ' + convert(varchar(6),i.POItem), i.POCo, 'C',
	 	'Component', d.Component, i.Component, getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
    join bPOCO c with (nolock) on c.POCo = i.POCo
    where isnull(i.Component,'') <> isnull(d.Component,'') and c.AuditPOs = 'Y'

if update(CostCode)
    insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPOIT', 'PO:' + i.PO + ' Item: ' + convert(varchar(6),i.POItem), i.POCo, 'C',
	 	'Cost Code', d.CostCode, i.CostCode, getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
    join bPOCO c with (nolock) on c.POCo = i.POCo
    where isnull(i.CostCode,'') <> isnull(d.CostCode,'') and c.AuditPOs = 'Y'

if update(EMCType)
    insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPOIT', 'PO:' + i.PO + ' Item: ' + convert(varchar(6),i.POItem), i.POCo, 'C',
	 	'EM Cost Type', convert(varchar(3),d.EMCType), convert(varchar(3),i.EMCType), getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
    join bPOCO c with (nolock) on c.POCo = i.POCo
    where isnull(i.EMCType,0) <> isnull(d.EMCType,0) and c.AuditPOs = 'Y'

if update(WO)
    insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPOIT', 'PO:' + i.PO + ' Item: ' + convert(varchar(6),i.POItem), i.POCo, 'C',
	 	'Work Order', d.WO, i.WO, getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
    join bPOCO c with (nolock) on c.POCo = i.POCo
    where isnull(i.WO,'') <> isnull(d.WO,'') and c.AuditPOs = 'Y'

if update(WOItem)
    insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPOIT', 'PO:' + i.PO + ' Item: ' + convert(varchar(6),i.POItem), i.POCo, 'C',
	 	'WO Item', convert(varchar(6),d.WOItem), convert(varchar(6),i.WOItem), getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
    join bPOCO c with (nolock) on c.POCo = i.POCo
    where isnull(i.WOItem,0) <> isnull(d.WOItem,0) and c.AuditPOs = 'Y'

if update(GLCo)
    insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPOIT', 'PO:' + i.PO + ' Item: ' + convert(varchar(6),i.POItem), i.POCo, 'C',
	 	'GL Co#', convert(varchar(3),d.GLCo), convert(varchar(3),i.GLCo), getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
    join bPOCO c with (nolock) on c.POCo = i.POCo
    where i.GLCo <> d.GLCo and c.AuditPOs = 'Y'

if update(GLAcct)
    insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPOIT', 'PO:' + i.PO + ' Item: ' + convert(varchar(6),i.POItem), i.POCo, 'C',
	 	'GL Account', d.GLAcct, i.GLAcct, getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
    join bPOCO c with (nolock) on c.POCo = i.POCo
    where i.GLAcct <> d.GLAcct and c.AuditPOs = 'Y'

if update(ReqDate)
    insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPOIT', 'PO:' + i.PO + ' Item: ' + convert(varchar(6),i.POItem), i.POCo, 'C',
	 	'Req Date', convert(varchar(8),d.ReqDate,1), convert(varchar(8),i.ReqDate,1), getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
    join bPOCO c with (nolock) on c.POCo = i.POCo
    where isnull(i.ReqDate,'') <> isnull(d.ReqDate,'') and c.AuditPOs = 'Y'

if update(TaxCode)
    insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPOIT', 'PO:' + i.PO + ' Item: ' + convert(varchar(6),i.POItem), i.POCo, 'C',
	 	'Tax Code', d.TaxCode, i.TaxCode, getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
    join bPOCO c with (nolock) on c.POCo = i.POCo
    where isnull(i.TaxCode,'') <> isnull(d.TaxCode,'') and c.AuditPOs = 'Y'

if update(TaxType)
    insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPOIT', 'PO:' + i.PO + ' Item: ' + convert(varchar(6),i.POItem), i.POCo, 'C',
	 	'Tax Type', convert(varchar(2),d.TaxType), convert(varchar(2),i.TaxType), getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
    join bPOCO c with (nolock) on c.POCo = i.POCo
    where isnull(i.TaxType,99) <> isnull(d.TaxType,99) and c.AuditPOs = 'Y'

if update(OrigUnits)
    insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPOIT', 'PO:' + i.PO + ' Item: ' + convert(varchar(6),i.POItem), i.POCo, 'C',
	 	'Orig Units', convert(varchar(20),d.OrigUnits), convert(varchar(20),i.OrigUnits), getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
    join bPOCO c with (nolock) on c.POCo = i.POCo
    where i.OrigUnits <> d.OrigUnits and c.AuditPOs = 'Y'

if update(OrigUnitCost)
    insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPOIT', 'PO:' + i.PO + ' Item: ' + convert(varchar(6),i.POItem), i.POCo, 'C',
	 	'Orig Unit Cost', convert(varchar(20),d.OrigUnitCost), convert(varchar(20),i.OrigUnitCost), getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
    join bPOCO c with (nolock) on c.POCo = i.POCo
    where i.OrigUnitCost <> d.OrigUnitCost and c.AuditPOs = 'Y'

if update(OrigECM)
    insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPOIT', 'PO:' + i.PO + ' Item: ' + convert(varchar(6),i.POItem), i.POCo, 'C',
	 	'Orig ECM', d.OrigECM, i.OrigECM, getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
    join bPOCO c with (nolock) on c.POCo = i.POCo
    where isnull(i.OrigECM,'') <> isnull(d.OrigECM,'') and c.AuditPOs = 'Y'

if update(OrigCost)
    insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPOIT', 'PO:' + i.PO + ' Item: ' + convert(varchar(6),i.POItem), i.POCo, 'C',
	 	'Orig Cost', convert(varchar(20),d.OrigCost), convert(varchar(20),i.OrigCost), getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
    join bPOCO c with (nolock) on c.POCo = i.POCo
    where i.OrigCost <> d.OrigCost and c.AuditPOs = 'Y'

if update(OrigTax)
    insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPOIT', 'PO:' + i.PO + ' Item: ' + convert(varchar(6),i.POItem), i.POCo, 'C',
	 	'Orig Tax', convert(varchar(20),d.OrigTax), convert(varchar(20),i.OrigTax), getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
    join bPOCO c with (nolock) on c.POCo = i.POCo
    where i.OrigTax <> d.OrigTax and c.AuditPOs = 'Y'

if update(PayType)
    insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPOIT', 'PO:' + i.PO + ' Item: ' + convert(varchar(6),i.POItem), i.POCo, 'C',
	 	'Pay Type', convert(varchar(3),d.PayType), convert(varchar(3),i.PayType), getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
    join bPOCO c with (nolock) on c.POCo = i.POCo
    where i.PayType <> d.PayType and c.AuditPOs = 'Y'

if update(PayCategory)
    insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPOIT', 'PO:' + i.PO + ' Item: ' + convert(varchar(6),i.POItem), i.POCo, 'C',
	 	'Pay Category', isnull(convert(varchar(3),d.PayCategory),''),
		 isnull(convert(varchar(3),i.PayCategory),''), getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
    join bPOCO c with (nolock) on c.POCo = i.POCo
    where i.PayCategory <> d.PayCategory and c.AuditPOs = 'Y'

if update(SMCo)
   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPOIT', 'PO:' + i.PO + ' Item: ' + convert(varchar(6),i.POItem), i.POCo, 'C',
	 	'SM Company', isnull(convert(varchar(3),d.SMCo),''),
		 isnull(convert(varchar(3),i.SMCo),''), getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
    join bPOCO c with (nolock) on c.POCo = i.POCo
    where i.SMCo <> d.SMCo and c.AuditPOs = 'Y'

if update(SMWorkOrder)
    insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPOIT', 'PO:' + i.PO + ' Item: ' + convert(varchar(6),i.POItem), i.POCo, 'C',
	 	'SM Work Order', d.SMWorkOrder, i.SMWorkOrder, getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
    join bPOCO c with (nolock) on c.POCo = i.POCo
    where isnull(i.SMWorkOrder,'') <> isnull(d.SMWorkOrder,'') and c.AuditPOs = 'Y'
   	    
-- TK-15925 --
if update(SMJCCostType)
   	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPOIT', 'PO:' + i.PO + ' Item: ' + convert(varchar(6),i.POItem), i.POCo, 'C',
	 	'SM JCCostType', isnull(convert(varchar(3),d.SMJCCostType),''),
		 isnull(convert(varchar(3),i.SMJCCostType),''), getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
    join bPOCO c with (nolock) on c.POCo = i.POCo
    where i.SMJCCostType <> d.SMJCCostType and c.AuditPOs = 'Y'
      
RETURN
     
error:
	--if @opencursor = 1
	--	BEGIN
	--	close bPOIT_update
	--	deallocate bPOIT_update
	--	END

   select @errmsg = @errmsg + ' - cannot update PO Items (bPOIT)'
   RAISERROR(@errmsg, 11, -1);
   rollback transaction
   
  
 




GO

ALTER TABLE [dbo].[bPOIT] WITH NOCHECK ADD CONSTRAINT [FK_bPOIT_vSMWorkOrderScope] FOREIGN KEY ([SMCo], [SMWorkOrder], [SMScope]) REFERENCES [dbo].[vSMWorkOrderScope] ([SMCo], [WorkOrder], [Scope])
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPOIT].[RecvYN]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPOIT].[OrigUnitCost]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bPOIT].[OrigECM]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPOIT].[CurUnitCost]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bPOIT].[CurECM]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPOIT].[RemUnits]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPOIT].[RemCost]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPOIT].[RemTax]'
GO
