CREATE TABLE [dbo].[bINDT]
(
[INCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[INTrans] [int] NOT NULL,
[Loc] [dbo].[bLoc] NOT NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[Material] [dbo].[bMatl] NOT NULL,
[ActDate] [dbo].[bDate] NOT NULL,
[PostedDate] [dbo].[bDate] NOT NULL,
[Source] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[TransType] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[APPOCo] [dbo].[bCompany] NULL,
[PO] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[POItem] [dbo].[bItem] NULL,
[POTrans] [dbo].[bTrans] NULL,
[APTrans] [dbo].[bTrans] NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[Vendor] [dbo].[bVendor] NULL,
[APRef] [dbo].[bAPReference] NULL,
[APLine] [smallint] NULL,
[TrnsfrLoc] [dbo].[bLoc] NULL,
[FinishMatl] [dbo].[bMatl] NULL,
[MSTrans] [dbo].[bTrans] NULL,
[MO] [dbo].[bMO] NULL,
[MOItem] [dbo].[bItem] NULL,
[CustGroup] [dbo].[bGroup] NULL,
[Customer] [dbo].[bCustomer] NULL,
[CustJob] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[CustPO] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[JCCo] [dbo].[bCompany] NULL,
[Job] [dbo].[bJob] NULL,
[PhaseGroup] [dbo].[bGroup] NULL,
[Phase] [dbo].[bPhase] NULL,
[JCCType] [dbo].[bJCCType] NULL,
[SellToINCo] [dbo].[bCompany] NULL,
[SellToLoc] [dbo].[bLoc] NULL,
[EMCo] [dbo].[bCompany] NULL,
[WO] [dbo].[bWO] NULL,
[WOItem] [dbo].[bItem] NULL,
[Equip] [dbo].[bEquip] NULL,
[EMGroup] [dbo].[bGroup] NULL,
[CostCode] [dbo].[bCostCode] NULL,
[EMCType] [dbo].[bEMCType] NULL,
[CompType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Component] [dbo].[bEquip] NULL,
[GLCo] [dbo].[bCompany] NULL,
[GLAcct] [dbo].[bGLAcct] NULL,
[Description] [dbo].[bItemDesc] NULL,
[PostedUM] [dbo].[bUM] NOT NULL,
[PostedUnits] [dbo].[bUnits] NOT NULL,
[PostedUnitCost] [dbo].[bUnitCost] NOT NULL,
[PostECM] [dbo].[bECM] NOT NULL,
[PostedTotalCost] [dbo].[bDollar] NOT NULL,
[StkUM] [dbo].[bUM] NOT NULL,
[StkUnits] [dbo].[bUnits] NOT NULL,
[StkUnitCost] [dbo].[bUnitCost] NOT NULL,
[StkECM] [dbo].[bECM] NOT NULL,
[StkTotalCost] [dbo].[bDollar] NOT NULL,
[UnitPrice] [dbo].[bUnitCost] NOT NULL,
[PECM] [dbo].[bECM] NOT NULL,
[TotalPrice] [dbo].[bDollar] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[InUseBatchId] [dbo].[bBatchID] NULL,
[PurgeYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bINDT_PurgeYN] DEFAULT ('N'),
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[SMCo] [dbo].[bCompany] NULL,
[SMWorkOrder] [int] NULL,
[SMScope] [int] NULL,
[POItemLine] [int] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

 
CREATE trigger [dbo].[btINDTd] on [dbo].[bINDT] for DELETE as
/*-----------------------------------------------------------------
* Created: GR 02/22/00
* Modified: GG 03/03/00 - cleanup
*           GG 06/14/00 - modified for new Trans Types
*           GG 7/13/00 - changed avg and last unit cost updates to use (posted total cost / stk units)
*			RM 04/16/01 - Added validation to handle purges and rollups
*			GG 10/18/01 - #14946 - exclude rows being purged from Avg unit cost and onhand updates
*			GG 12/11/01 - #15560 - dont allow negative unit cost
*  			GG 01/29/02 - #16086 - reset bINMT.Audit to Y
*           DANF 08/23/02 - #17716 - Correct Avg unit cost
*           DANF 09/24/02 - #11664 - Added Booked Column
*			MV 08/18/05 - #29558 - calc AvgCost using factor
*			GG 08/22/05 - #29453 - corrected AvgCost calcs on change, validation cleanup
*			DANF 10/03/05 - #25822 - correct AvgCost when Expensing PO's on receipt
*			GG 04/17/07 - #122855 - fix AvgUnitCost calcs when expensing on receipts
*			MV 04/25/08	- #127934 - If cost is burdened and POIT has taxcode include tax in @pounitcost
*			GP 05/15/09 - #133436 Added HQAT code
*			GP 7/27/2011 - TK-07144 changed bPO to varchar(30)
*
* Delete trigger on bINDT (Inventory Detail)
* Updates Avg Cost, OnHand and Booked in Location Materials
*
*/----------------------------------------------------------------
   
declare @errmsg varchar(255), @numrows int, @inco bCompany, @loc bLoc, @matlgroup bGroup,
   @material bMatl, @transtype varchar(10), @units bUnits, @totalcost bDollar, @opencursor tinyint,
   @oldbooked bUnits, @oldavgcost bUnitCost, @oldecm bECM, @avgcost bUnitCost, @avgecm bECM, @factor int,@purgeYN bYN,
   @onhandunits bUnits, @source bSource, @po varchar(30), @poitem bItem, @appoco bCompany,
   @unitcost bUnitCost, @mth bMonth, @batchid bBatchID, @ExpensePO bYN, @pounitcost bUnitCost, @batchsource bSource,
   @avgtotalcost bDollar, @avgunits bUnitCost, @desc bDesc, @postedunits bUnits, @potaxcode bTaxCode,@taxrate bRate,
   @potaxgroup bGroup, @burdenyn bYN, @actdate bDate
   
select @numrows = @@rowcount
if @numrows = 0 return

set nocount on

-- update Avg Cost and On Hand in bINMT
if @numrows = 1
	begin
	-- if only one row inserted, no cursor is needed
  	select @inco = INCo, @loc = Loc, @matlgroup = MatlGroup, @material = Material,@actdate = ActDate,
		@transtype = TransType, @postedunits = PostedUnits, @totalcost = PostedTotalCost, @units = StkUnits,
		@source = Source,  @appoco = APPOCo, @po = PO, @poitem = POItem, @mth = Mth, @batchid = BatchId , @unitcost = PostedUnitCost,  @desc = Description
	from deleted
	where PurgeYN = 'N'	-- exclude rows being purged
	end
else
    begin
    -- use a cursor to process all deleted rows
    declare bINDT_delete cursor for
    select INCo, Loc, MatlGroup, Material, TransType, PostedUnits, PostedTotalCost,
		StkUnits, Source, APPOCo, PO, POItem, Mth, BatchId, PostedUnitCost, Description
    from deleted
   	where PurgeYN = 'N' -- exclude rows being purged
   
    open bINDT_delete
    select @opencursor = 1
   
    -- get 1st row delete
    fetch next from bINDT_delete into @inco, @loc, @matlgroup, @material, @transtype, @postedunits, @totalcost,
		@units, @source, @appoco, @po, @poitem, @mth, @batchid, @unitcost, @desc
    if @@fetch_status <> 0 goto bspexit
    end
   
  -- Flags used to determine if the avg unit cost will need to be updated for PO transactions from AP Entry and PO Receipts
  -- when the user is updating expenses on the receipt of the PO. In the case where expensing PO's on receipt is turned on
  -- Then do not update OnHand and Booked in INMT and only update Average Unit Cost if the Invoice unit cost diffs from
  -- the Unit Cost updated during its receipt, which happens to be the PO's Orig Unit Cost.
  select @batchsource = '', @ExpensePO = 'N', @pounitcost = 0, @avgtotalcost = @totalcost , @avgunits = @units
  
  if (isnull(@po,'') <>'' and isnull(@poitem,'') <>'' and isnull(@appoco,'') <>'') and (@source = 'PO' or @source = 'AP Entry')
  	begin
  
   		if 	exists (select 1 from dbo.bPOIT with (nolock) where POCo = @appoco and PO=@po and POItem = @poitem and RecvYN = 'Y')  and
   		 	exists( select POCo from dbo.bPOCO with (nolock) where POCo=@appoco and ReceiptUpdate = 'Y'	and RecINInterfacelvl>0)
  			begin
           	select @ExpensePO = 'Y'	
  
  
  			-- Need to know if the posting was from AP Entry or PO Receipt
  			select @batchsource = h.Source 
  			from dbo.bHQBC h with (nolock)
  			where h.Co = @appoco and h.Mth = @mth and h.BatchId = @batchid  
  
  			select @pounitcost = OrigUnitCost, @potaxgroup = TaxGroup,@potaxcode=TaxCode
  			from dbo.bPOIT with (nolock)
  			where POCo = @appoco and PO = @po and POItem = @poitem
  
  			if @batchsource = 'AP Entry' -- sources from AP should be 'AP Entry' and 'PO Receipt'
  				begin
  				 	IF @source = 'AP Entry' -- process 'AP Entry' but skip 'PO Receipt' when updating Avg Cost
  						begin
						--#127934 if cost is burdened and POIT has a taxcode, get tax rate and calc @pounitcost + (@pounitcost * taxrate)
						-- so when avgtotalcost is calculated @unitcost (from invoiced postedunitcost which includes tax if burdened
						-- will match @poitunitcost which does not include the tax amount)
						select @burdenyn = BurdenCost from bINCO with (nolock) where INCo=@inco
						if @burdenyn = 'Y' and @potaxcode is not null
						begin
							select @taxrate = dbo.vfHQTaxRate(@potaxgroup,@potaxcode,@actdate)
							select @pounitcost = @pounitcost + (@pounitcost * @taxrate)
						end
  						select @factor = case @avgecm when 'C' then 100 when 'M' then 1000 else 1 end
  			  			select @avgunits = 0, @avgtotalcost = ((@unitcost - @pounitcost) * @postedunits) / @factor -- use the difference
  				  		if @avgtotalcost = 0 goto NextTrans
  						end
  					else
  						goto NextTrans -- Do not update Onhand, Booked or Average unit cost 
  				end
  			end
  
  	end
  
   INMT_update:
       -- Average Unit Cost update only performed for certain types of transactions
       if @transtype in ('Adj','Purch','Prod','Trnsfr In')
           begin
           select @oldbooked = Booked, @oldavgcost = AvgCost, @oldecm = AvgECM
           from dbo.bINMT
           where INCo = @inco and Loc = @loc and MatlGroup = @matlgroup and Material = @material
   		if @@rowcount = 0
   				begin
   				select @errmsg = 'Unable to find INMT entry for Loc:' + @loc + ' Matl:' + @material
   				goto error
   				end
   
           select @avgcost = @oldavgcost, @avgecm = @oldecm    -- default to current values
           if @units <> 0
               begin
               select @factor = case @avgecm when 'C' then 100 when 'M' then 1000 else 1 end
               select @avgcost = (@totalcost / @units) * @factor -- used posted total cost divided by stk units
               end
   
           -- recalculate Avg Unit Cost only if booked is and will be > 0
           if @oldbooked > 0 and (@oldbooked - @avgunits) > 0
               begin
               select @factor = case @avgecm when 'C' then 100 when 'M' then 1000 else 1 end
               select @avgcost = ((((@oldbooked * @oldavgcost) / @factor) - @avgtotalcost) / (@oldbooked - @avgunits)) * @factor --#29558
   			end
   
   		if @avgcost < 0 select @avgcost = 0		-- don't allow negative avg unit cost
   
           update dbo.bINMT set AvgCost = @avgcost, AvgECM = @avgecm, AuditYN = 'N'
           where INCo = @inco and Loc = @loc and MatlGroup = @matlgroup and Material = @material
   		if @@rowcount = 0
   			begin
   			select @errmsg = 'Unable to update Average Cost for Loc:' + @loc + ' Matl:' + @material
   			goto error
   			end
           end
   
   	select @onhandunits = @units
   	/*If the IN transaction is a purchase order from AP Entry, check the PO Company
   	  Receipt Update and Receipt Inventory level for the onhand qty to be updated in INMT.
   	  When the PO Company Receipt Update is off or the Receipt Inventory level is set to none 
   	  then the on hand qty is updated in the PORD trigger. This is only for PO receiving Items.*/
   	if @source = 'AP Entry' and @transtype = 'Purch' and isnull(@po,'') <>'' and isnull(@poitem,'') <>'' and isnull(@appoco,'') <>''
  		begin
  		if exists (select 1 from bPOIT with (nolock) where POCo = @appoco and PO=@po and POItem = @poitem and RecvYN = 'Y') 
  				and not exists( select POCo from bPOCO with (nolock) where POCo=@appoco and ReceiptUpdate = 'Y'	and RecINInterfacelvl>0)
          	select @onhandunits = 0
  		end
  
   	If @source = 'PO' and @desc = 'Receipt Expense Initialize' select @onhandunits = 0
  
       -- do not update On Hand or Booked when Expensing PO receipts from AP Entry
  	if isnull(@ExpensePO,'N') = 'Y' and @batchsource = 'AP Entry' select @onhandunits = 0, @units = 0
  
  	if isnull(@onhandunits,0) <> 0 or isnull(@units,0) <> 0
  		begin
  	     -- On Hand update needed for all transactions types - done after Avg Unit Cost update
  	     update dbo.bINMT set OnHand = OnHand - @onhandunits, Booked = Booked - @units, AuditYN = 'N'
  	     where INCo = @inco and Loc = @loc and MatlGroup = @matlgroup and Material = @material
  	 	 if @@rowcount = 0
  	 		begin
  	 		select @errmsg = 'Unable to update OnHand and Booked Units for Loc:' + @loc + ' Matl:' + @material
  	 		goto error
  	 		end
  		end
   
  NextTrans:
   -- get next row
   if @numrows > 1
       begin
       fetch next from bINDT_delete into @inco, @loc, @matlgroup, @material, @transtype, @postedunits, @totalcost,
			@units, @source, @appoco, @po, @poitem, @mth, @batchid, @unitcost, @desc
       if @@fetch_status = 0 goto INMT_update
   	end
   
   bspexit:
   	if @opencursor = 1
   		begin
       	close bINDT_delete
       	deallocate bINDT_delete
       	end
   
   	-- reset IN Material Audit flag  - #16086
   	update dbo.bINMT
   	set AuditYN = 'Y'
   	from (select distinct INCo, Loc, MatlGroup, Material from deleted where PurgeYN = 'N') as d
   	join dbo.bINMT m on m.INCo = d.INCo and m.Loc = d.Loc and m.MatlGroup = d.MatlGroup and m.Material = d.Material
   
	-- Delete attachments if they exist. Make sure UniqueAttchID is not null
	insert vDMAttachmentDeletionQueue (AttachmentID, UserName, DeletedFromRecord)
    select AttachmentID, suser_name(), 'Y' 
    from bHQAT h join deleted d on h.UniqueAttchID = d.UniqueAttchID                  
    where d.UniqueAttchID is not null  
   
   	return
   
   error:
       if @opencursor = 1
           begin
           close bINDT_delete
           deallocate bINDT_delete
           end
   
   
   	select @errmsg = @errmsg + ' - cannot delete Inventory Detail!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
   
   
   
   
   
  
  
  
  
 
 
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

 
CREATE trigger [dbo].[btINDTi] on [dbo].[bINDT] for insert as
/******************************************************************************
*  Created:	JM 01/03/00
*  Modified:  GR 2/22/00 added the validation for all the fields,
*                 added OnHand, Average UnitCost, LastUnitcost, LastCostUpdate updates
*			GG 03/03/00 - cleanup
*			DANF 03/21/00 - Add source JC CostAdj
*           GR 04/12/00 - Corrected average unit cost update if it is adjustment batch
*           GR 6/12/00 - removed the check to validate PO, doing the validation of PO and Poitem together
*                 and added to update Lastvendor etc if LastCostUpdate in INMT is null too
*           GG 6/14/00 - modified for new Trans Types (Exp, Trnsfr In, and Trnsfr Out)
*           GR 6/15/00 - corrected the source as AP Entry instead of AP
*           GR 6/29/00 - corrected the last unitcost update
*           GG 7/13/00 - changed avg and last unit cost updates to use (posted total cost / stk units)
*           GR 1/30/01 - if um is not equal to stdum then update bINMU LastCost instead of bINMT
*			RM 04/16/01 - Added validation to handle purges and rollups
*	       	RM 04/18/01 - #12981 - Allow insert if material is in inventory if not stocked
*	       	TV 05/10/01 - Change to AP validation issue 13336
*	       	TV 06/06/01 - Change To last cost to be last cost not conversion
*			GG 10/18/01 - #14946 - validation cleanup, corrected Last Unit Cost updates to bINMT and bINMU
*			GG 12/11/01 - #15560 - do not allow negative avg unit cost
*			GG 01/29/02 - #16086 - reset bINMT.Audit to Y
*           DANF 08/23/02 - #17716 - Correct Avg Unit cost calculation.
*           DANF 09/24/02 - #11664 - Added Booked Column
*			GG 10/09/02 - #18848 - include new 'Rec Adj' trans type
*			GF 08/01/2003 - issue #21933 - speed improvements
*			DANF 10/05/2003 - issue 21985 Correct On Hand for Init Rec.
*			MV 08/16/05 - #29558 correct average cost calcs
*			GG 08/22/05 - #29453 - corrected AvgCost calcs on change, validation cleanup
*			DANF 10/03/05 - #25822 - correct AvgCost when Expensing PO's on receipt
*			GG 04/17/07 - #122855 - fix AvgUnitCost calcs when expensing on receipts, converted to ANSI joins
*			TRL 01/15/08 - #124100 - Update Last Cost per std u/m when material purchased in alternative u/ms
*			MV 04/25/08	- #127934 - If cost is burdened and POIT has taxcode include tax in @pounitcost
*			GP 06/15/09 - #133811 - If VendorGroup is null then use HQCO Vendor Group
*			GF 07/30/2011 - TK-07143 PO expanded
*
*	Insert trigger for bINDT (Inventory Detail)
*  Updates Avg Unit Cost, OnHand, Booked, Last Vendor, Last Unit Cost for the material in bINMT, bINMU
*
********************************************************************************/
declare @errmsg varchar(255), @numrows int, @validcnt int, @nullcnt int, @inco bCompany, @loc bLoc,
	@matlgroup bGroup, @material bMatl, @actdate bDate, @transtype varchar(10), @vendorgroup bGroup,
    @vendor bVendor, @units bUnits, @unitcost bUnitCost, @ecm bECM, @totalcost bDollar,@purgeYN bYN,
   	@onhandunits bUnits, @source bSource, @po VARCHAR(30), @poitem bItem,@appoco bCompany,@HQCOVendorGroup bGroup
   
declare @opencursor tinyint, @oldbooked bUnits, @oldavgcost bUnitCost, @oldecm bECM, @avgcost bUnitCost,
	@avgecm bECM, @factor int, @lastcost bUnitCost, @lastecm bECM, @stdum bUM, @um bUM, @desc bDesc,
	@mth bMonth, @batchid bBatchID, @ExpensePO bYN, @pounitcost bUnitCost, @batchsource bSource,
	@avgtotalcost bDollar, @avgunits bUnits, @postedunits bUnits, @potaxcode bTaxCode,@taxrate bRate,
	@potaxgroup bGroup, @burdenyn bYN
   
select @numrows = @@rowcount
if @numrows = 0 return
   
set nocount on
   
--validate Transaction Source 
select @validcnt = count(*) from inserted i
where i.Source in ('IN Adj','IN Trnsfr','IN Prod','IN MO','IN Rollup','AP Entry','PO','JC','EM','MS', 'SM')
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid Transaction Source'
	goto error
	end
--validate Transaction Type
select @validcnt = count(*) from inserted i
where i.TransType in ('Adj','Exp','Trnsfr In','Trnsfr Out','Purch','Usage','Prod','AR Sale','JC Sale','IN Sale','EM Sale','Rec Adj', 'SM Sale')
if @validcnt <> @numrows
   begin
   select @errmsg = 'Invalid Transaction Type'
   goto error
   end
--validate InUseBatchId - must be null
if exists(select 1 from inserted where InUseBatchId is not null)
	begin
	select @errmsg ='In Use Batch ID must be null'
	goto error
	end
-- validate Purge flag
if exists(select 1 from inserted where PurgeYN <> 'N')
	begin
	select @errmsg ='Purge flag must be ''N'''
	goto error
	end
--validate Location
select @validcnt = count(*)
from dbo.INLM l with (nolock)
join inserted i on l.INCo = i.INCo and l.Loc = i.Loc
if @validcnt <> @numrows
	begin
    select @errmsg = 'Invalid Location'
    goto error
    end
--validate Material Group
select @validcnt = count(*)
from dbo.HQCO c with (nolock)
join inserted i on c.HQCo = i.INCo and c.MatlGroup = i.MatlGroup
if @validcnt <> @numrows
    begin
    select @errmsg = 'Invalid Material Group'
    goto error
    end
--validate Material at Posted Location
select @validcnt = count(*) from dbo.INMT t with(nolock)
join inserted i on i.INCo = t.INCo and i.Loc = t.Loc and i.MatlGroup = t.MatlGroup and i.Material = t.Material
where (t.Active = 'Y' or i.Source = 'IN Rollup')	-- allow rollup of inactive materials
if @validcnt <> @numrows
	begin
	select @errmsg = 'Not an Active Material at the Location'
	goto error
	end
--validate AP PO Company 
select @nullcnt = count(*) from inserted i where PO is null
select @validcnt = count(*) from inserted i
join dbo.POCO c with (nolock) on c.POCo = i.APPOCo where i.PO is not null
if (@nullcnt + @validcnt) <> @numrows
	begin
    select @errmsg = 'Invalid PO Company'
    goto error
	end
--validate PO and POItem
select @nullcnt = count(*) from inserted i where i.POItem is null
select @validcnt = count(*)
from inserted i
join dbo.POIT t with(nolock) on t.POCo=i.APPOCo and t.PO=i.PO and t.POItem=i.POItem
if (@nullcnt+@validcnt) <> @numrows
    begin
    select @errmsg = 'Invalid PO/PO Item'
    goto error
    end
--validate Vendor
select @nullcnt = count(*) from inserted where Vendor is null
select @validcnt = count(*)
from dbo.APVM v with(nolock)
join inserted i on v.VendorGroup = i.VendorGroup and v.Vendor = i.Vendor
if (@nullcnt+@validcnt) <> @numrows
    begin
    select @errmsg = 'Invalid Vendor'
    goto error
    end
--validate transfer location
select @nullcnt = count(*) from inserted where TrnsfrLoc is null
select @validcnt = count(*) from inserted i
join dbo.INLM m with(nolock) on i.INCo = m.INCo and i.TrnsfrLoc = m.Loc
if (@nullcnt+@validcnt) <> @numrows
    begin
    select @errmsg = 'Invalid Transfer Location'
    goto error
    end
--validate finished material
select @nullcnt = count(*) from inserted where FinishMatl is null
select @validcnt = count(*) from inserted i
join dbo.HQMT t with(nolock) on t.MatlGroup = i.MatlGroup and t.Material = i.FinishMatl
if (@nullcnt+@validcnt) <> @numrows
	begin
	select @errmsg = 'Invalid Finished Material'
    goto error
    end
 --validate Customer
select @validcnt = count(*) from inserted i
join dbo.ARCM r with(nolock) on i.CustGroup = r.CustGroup  and i.Customer = r.Customer
select @nullcnt  = count(*) from inserted i where i.Customer is null
if (@validcnt + @nullcnt) <> @numrows
	begin
	select @errmsg = 'Invalid Customer'
	goto error
	end
--validate Job
select @nullcnt = count(*) from inserted where Job is null
select @validcnt = count(*) from inserted i
join dbo.JCJM j with(nolock) on j.JCCo = i.JCCo and j.Job = i.Job
if (@nullcnt+@validcnt) <> @numrows
	begin
    select @errmsg = 'Invalid Job'
    goto error
    end
--validate SellToInco
select @nullcnt = count(*) from inserted where SellToINCo is null
select @validcnt = count(*) from inserted i
join dbo.INCO c with(nolock) on i.SellToINCo = c.INCo
if (@nullcnt+@validcnt) <> @numrows
    begin
    select @errmsg = 'Invalid Sell To IN Company'
    goto error
    end
--validate SellToLoc
select @nullcnt = count(*) from inserted where SellToLoc is null
select @validcnt = count(*) from inserted i
join dbo.INLM m (nolock) on i.SellToINCo = m.INCo and i.SellToLoc = m.Loc
if (@nullcnt+@validcnt) <> @numrows
    begin
    select @errmsg = 'Invalid Sell To Location'
    goto error
    end
--validate EM Company
select @nullcnt = count(*) from inserted where EMCo is null
select @validcnt = count(*) from inserted i
join dbo.EMCO e with(nolock) on e.EMCo = i.EMCo
if (@nullcnt+@validcnt) <> @numrows
    begin
    select @errmsg='Invalid EM Company'
    goto error
    end
--validate Equipment
select @nullcnt = count(*) from inserted where Equip is null
select @validcnt = count(*) from inserted i
join dbo.EMEM e with(nolock) on e.EMCo = i.EMCo and e.Equipment = i.Equip
if (@nullcnt+@validcnt) <> @numrows
    begin
	select @errmsg = 'Invalid Equipment'
	goto error
	end
--validate Cost Code
select @nullcnt = count(*) from inserted where CostCode is null
select @validcnt = count(*) from inserted i
join dbo.EMCC c with(nolock) on c.EMGroup = i.EMGroup and c.CostCode = i.CostCode
if (@nullcnt+@validcnt) <> @numrows
    begin
	select @errmsg = 'Invalid EM Cost Code'
	goto error
	end
--validate EM Cost Type
select @nullcnt = count(*) from inserted where EMCType is null
select @validcnt = count(*) from inserted i
join dbo.EMCT t with(nolock) on t.EMGroup = i.EMGroup and t.CostType = i.EMCType
if (@nullcnt+@validcnt) <> @numrows
    begin
	select @errmsg = 'Invalid EM Cost Type'
	goto error
	end
-- validate Work Order
select @nullcnt = count(*) from inserted where WO is null
select @validcnt = count(*) from inserted i
join dbo.EMWH w with(nolock) on w.EMCo = i.EMCo and w.WorkOrder = i.WO
if (@nullcnt+@validcnt) <> @numrows
	begin
	select @errmsg = 'Invalid EM Work Order'
	goto error
    end
--validate Work Order Item
select @nullcnt = count(*) from inserted where WOItem is null
select @validcnt = count(*) from inserted i
join dbo.EMWI w with(nolock) on w.EMCo = i.EMCo and w.WorkOrder = i.WO and w.WOItem = i.WOItem
if (@nullcnt+@validcnt) <> @numrows
	begin
	select @errmsg = 'Invalid EM Work Order Item'
	goto error
   end
--validate GL Company
select @nullcnt = count(*) from inserted where GLCo is null
select @validcnt = count(*) from inserted i
join dbo.GLCO c with(nolock) on c.GLCo=i.GLCo
if (@nullcnt+@validcnt) <> @numrows
    begin
    select @errmsg = 'Invalid GL Company'
    goto error
    end
--validate GL Account
select @nullcnt = count(*) from inserted where GLAcct is null
select @validcnt = count(*) from inserted i
join dbo.GLAC c with(nolock) on c.GLCo=i.GLCo and c.GLAcct=i.GLAcct
if (@nullcnt+@validcnt) <> @numrows
    begin
    select @errmsg = 'Invalid GL Account'
    goto error
    end
   
-- update Last Vendor, Last Cost, Avg Cost, and On Hand in bINMT
if @numrows = 1
	begin
	-- if only one row inserted, no cursor needed
	select @inco = INCo, @loc = Loc, @matlgroup = MatlGroup, @material = Material, @actdate = ActDate,
		@transtype = TransType, @vendorgroup = VendorGroup, @vendor = Vendor, @postedunits = PostedUnits, 
		@unitcost = PostedUnitCost, @ecm = PostECM, @totalcost = PostedTotalCost, @units = StkUnits, @um = PostedUM,
		@stdum = StkUM, @source = Source,  @appoco = APPOCo, @po = PO, @poitem = POItem, @desc = Description,
		@mth = Mth, @batchid = BatchId
	from inserted
	where Source <> 'IN Rollup'		-- exclude Rollup entries
	if @@rowcount = 0 goto bspexit
	end
else
	begin
	-- use a cursor to process inserted rows
	declare bINDT_insert cursor FAST_FORWARD for
	select INCo, Loc, MatlGroup, Material, ActDate, TransType, VendorGroup, Vendor,
		PostedUnits, PostedUnitCost, PostECM, PostedTotalCost, StkUnits, PostedUM,
		StkUM, Source, APPOCo, PO, POItem, Description, Mth, BatchId
	from inserted
	where Source <> 'IN Rollup'	-- exclude Rollup entries

	open bINDT_insert
	select @opencursor = 1

	-- get 1st row inserted
	fetch next from bINDT_insert into @inco, @loc, @matlgroup, @material, @actdate, @transtype, @vendorgroup, @vendor,
		@postedunits, @unitcost, @ecm, @totalcost, @units, @um,
		@stdum, @source, @appoco, @po, @poitem, @desc, @mth, @batchid
	if @@fetch_status <> 0 goto bspexit
	end
  
-- Flags used to determine if the avg unit cost will need to be updated for PO transactions from AP Entry and PO Receipts
-- when the user is updating expenses on the receipt of the PO. In the case where expensing PO's on receipt is turned on
-- Then do not update OnHand and Booked in INMT and only update Average Unit Cost if the Invoice unit cost diffs from
-- the Unit Cost updated during its receipt, which happens to be the PO's Orig Unit Cost.
select @batchsource = '', @ExpensePO = 'N', @pounitcost = 0, @avgtotalcost = @totalcost , @avgunits = @units, @taxrate = 0
  
if (isnull(@po,'') <> '' and isnull(@poitem,'') <> '' and isnull(@appoco,'') <> '') and (@source = 'PO' or @source = 'AP Entry')
	begin
	if exists (select 1 from dbo.POIT with (nolock) where POCo = @appoco and PO=@po and POItem = @poitem and RecvYN = 'Y') and
	 	exists(select POCo from dbo.POCO with (nolock) where POCo=@appoco and ReceiptUpdate = 'Y'	and RecINInterfacelvl>0)
		begin
       	select @ExpensePO = 'Y'	
		-- Need to know if the posting was from AP Entry or PO Receipt
		select @batchsource = h.Source 
		from dbo.HQBC h with (nolock)
		where h.Co = @appoco and h.Mth = @mth and h.BatchId = @batchid 
 
		select @pounitcost = OrigUnitCost, @potaxgroup = TaxGroup,@potaxcode=TaxCode
		from dbo.POIT with (nolock)
		where POCo = @appoco and PO = @po and POItem = @poitem

		if @batchsource = 'AP Entry' 	-- sources from AP should be 'AP Entry' and 'PO Receipt'
			begin
			if @source = 'AP Entry'	-- process 'AP Entry' but skip 'PO Receipt' when updating Avg Cost
				begin
				--#127934 if cost is burdened and POIT has a taxcode, get tax rate and calc @pounitcost + (@pounitcost * taxrate)
				-- so when avgtotalcost is calculated @unitcost (from invoiced postedunitcost which includes tax if burdened
				-- will match @poitunitcost which does not include the tax amount)
				select @burdenyn = BurdenCost from bINCO with (nolock) where INCo=@inco
				if @burdenyn = 'Y' and @potaxcode is not null
				begin
					select @taxrate = dbo.vfHQTaxRate(@potaxgroup,@potaxcode,@actdate)
					select @pounitcost = @pounitcost + (@pounitcost * @taxrate)
				end
				select @factor = case @avgecm when 'C' then 100 when 'M' then 1000 else 1 end
				select @avgunits = 0, @avgtotalcost = ((@unitcost - @pounitcost) * @postedunits) / @factor	-- use difference between receipt and expense
				if @avgtotalcost = 0 goto UpdateLastUnitCost
				end
			else
				goto UpdateLastUnitCost -- Do not update Onhand, Booked or Average unit cost 
			end
		end
	end
   
INMT_update:
	-- Average Unit Cost update only performed for certain types of transactions
	if @transtype in ('Adj','Purch','Prod','Trnsfr In') 
		begin
		-- get current values
		select @oldbooked = Booked, @oldavgcost = AvgCost, @oldecm = AvgECM, @lastcost = LastCost,
			@lastecm = LastECM
		from dbo.INMT with (nolock)
		where INCo = @inco and Loc = @loc and MatlGroup = @matlgroup and Material = @material
		if @@rowcount = 0
			begin
			select @errmsg = 'Unable to find INMT entry for Loc:' + @loc + ' Matl:' + @material
			goto error
			end

		select @avgcost = @oldavgcost, @avgecm = @oldecm    -- default to current values
        if @units <> 0
           begin
           select @factor = case @avgecm when 'C' then 100 when 'M' then 1000 else 1 end
           select @avgcost = (@totalcost / @units) * @factor -- used posted total cost divided by stk units
           end
   
       -- recalculate Avg Unit Cost only if booked is and will be > 0
       if (@oldbooked > 0) and ((@oldbooked + @avgunits) > 0)
           begin
           select @factor = case @avgecm when 'C' then 100 when 'M' then 1000 else 1 end
           select @avgcost = ((((@oldbooked * @oldavgcost) / @factor) + @avgtotalcost) / (@oldbooked + @avgunits)) * @factor --#29558
           end
   
		if @avgcost < 0 select @avgcost = 0 -- don't allow negative avg unit cost
   
        update dbo.INMT set AvgCost = @avgcost, AvgECM = @avgecm, AuditYN = 'N'
        where INCo = @inco and Loc = @loc and MatlGroup = @matlgroup and Material = @material
   		if @@rowcount = 0
			begin
			select @errmsg = 'Unable to update Average Cost for Loc:' + @loc + ' Matl:' + @material
			goto error
			end
       end 
 
-- update OnHand and Booked
select @onhandunits = @units
-- If the IN transaction is a purchase order from AP Entry, check the PO Company
-- Receipt Update and Receipt Inventory level for the onhand qty to be updated in INMT.
-- When the PO Company Receipt Update is off or the Receipt Inventory level is set to none 
-- then the on hand qty is updated in the PORD trigger. This is only for PO receiving Items.
If (@source = 'AP Entry' and @transtype = 'Purch' and isnull(@po,'') <>'' and isnull(@poitem,'') <>'' and isnull(@appoco,'') <>'')
	begin
	if exists (select 1 from dbo.POIT with (nolock) where POCo = @appoco and PO=@po and POItem = @poitem and RecvYN = 'Y') 
			and not exists( select POCo from dbo.POCO with (nolock) where POCo=@appoco and ReceiptUpdate = 'Y'	and RecINInterfacelvl>0)
      	select @onhandunits = 0
	end
  
if @source = 'PO' and @desc = 'Receipt Expense Initialize' select @onhandunits = 0
-- do not update On Hand or Booked when Expensing PO receipts from AP Entry
if isnull(@ExpensePO,'N') = 'Y' and @batchsource = 'AP Entry' select @onhandunits = 0, @units = 0
if isnull(@onhandunits,0) <> 0 or isnull(@units,0) <> 0
	begin
 	-- On Hand update needed for all transactions types - done after Avg Unit Cost update
    update dbo.INMT set OnHand = OnHand + @onhandunits, Booked = Booked + @units, AuditYN = 'N'
    where INCo = @inco and Loc = @loc and MatlGroup = @matlgroup and Material = @material
 	if @@rowcount = 0
 		begin
 		select @errmsg = 'Unable to update OnHand and Booked Units for Loc:' + @loc + ' Matl:' + @material
 		goto error
 		end
	end
  
UpdateLastUnitCost:
-- update Last Vendor and Last Cost for purchases, production, and transfers in only 
-- Last Unit Cost will already include burden if using 'burdened unit cost option'
if (@transtype in ('Purch', 'Prod', 'Trnsfr In'))
	begin
	--Get VendorGroup from HQCO for null VendorGroup insert below, 133811
	select @HQCOVendorGroup = VendorGroup from HQCO with (nolock) where HQCo = @inco
	if @vendorgroup is null set @vendorgroup = @HQCOVendorGroup
	
    if @um = @stdum	-- update bINMT if entry made in standard U/M
		begin
		update dbo.INMT set VendorGroup = @vendorgroup, LastVendor = @vendor, LastCost = @unitcost,
			LastECM = @ecm, LastCostUpdate = @actdate, AuditYN = 'N'
        where INCo = @inco and Loc = @loc and MatlGroup = @matlgroup and Material = @material
                and (@actdate >= LastCostUpdate or LastCostUpdate is null)
        end
	else
		begin	-- update bINMU if entry made in alternative U/M 
			update dbo.INMU set LastCost = @unitcost, LastECM = @ecm, LastCostUpdate = @actdate
			where INCo = @inco and Loc = @loc and MatlGroup = @matlgroup and Material = @material
			and UM = @um and (@actdate >= LastCostUpdate or LastCostUpdate is null)
        -- update bINMT with Last Vendor only
			--update dbo.bINMT set INMT.VendorGroup = @vendorgroup, INMT.LastVendor = @vendor, INMT.AuditYN = 'N'
			--where INCo = @inco and Loc = @newloc and MatlGroup = @newmatlgroup and Material = @newmaterial
			--and (@actdate >= LastCostUpdate or LastCostUpdate is null) 
		--Issue 124100
		update dbo.INMT set INMT.VendorGroup = @vendorgroup, INMT.LastVendor = @vendor, INMT.AuditYN = 'N',
   		INMT.LastCost = case when IsNull(INMU.Conversion,0) <> 0 then @unitcost/INMU.Conversion else @unitcost end,
		INMT.LastECM = @ecm, INMT.LastCostUpdate = @actdate
		From dbo.INMT a with (nolock)
		Left join dbo.INMU with (nolock) on INMU.INCo=a.INCo and INMU.Loc=a.Loc and INMU.MatlGroup=a.MatlGroup
		and INMU.Material=a.Material
		where a.INCo = @inco and a.Loc = @loc and a.MatlGroup = @matlgroup and a.Material = @material
        and (@actdate >= a.LastCostUpdate or a.LastCostUpdate is null) and INMU.UM =@um
		end
	end
   
-- get next row
if @numrows > 1
	begin
	fetch next from bINDT_insert into @inco, @loc, @matlgroup, @material, @actdate, @transtype,
		@vendorgroup, @vendor, @postedunits, @unitcost, @ecm, @totalcost, @units, @um, @stdum,
		@source, @appoco, @po, @poitem, @desc, @mth, @batchid
	if @@fetch_status = 0 goto INMT_update
	end

   
bspexit:
	if @opencursor = 1
		begin
		close bINDT_insert
   		deallocate bINDT_insert
		end
   
	-- reset IN Material Audit flag  - #16086
   	update dbo.INMT set AuditYN = 'Y'
   	from (select distinct INCo, Loc, MatlGroup, Material from inserted) as i
   			join dbo.INMT m with (nolock) on m.INCo = i.INCo and m.Loc = i.Loc 
				and m.MatlGroup = i.MatlGroup and m.Material = i.Material
   
	return
   
error:
   	if @opencursor = 1
		begin
        close bINDT_insert
        deallocate bINDT_insert
        end
   
	select @errmsg = @errmsg + ' - cannot insert IN Detail Transaction!'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
   
   
   
   
   
   
   
   
   
   
  
  
  
  
  
  
  
  
 
 
 
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

 
 
CREATE trigger [dbo].[btINDTu] on [dbo].[bINDT] for UPDATE as
/*--------------------------------------------------------------
* Created:  GR 02/22/00
* Modified: GG 03/03/00 - cleanup
* 			 GR 04/12/00 - Corrected Average Unit Cost update
*           GG 06/14/00 - modified for new Trans Types
*           GG 7/13/00 - changed avg and last unit cost updates to use (posted total cost / stk units)
*           GR 1/30/01 - added update to bINMU if um is not equal to stdum
*			 RM 04/13/01 - Added parameter @actdate to fetch of cursor so it didnt blow up
*			 RM 04/16/01 - Added validation to handle purges and rollups
*	      	 RM 04/18/01 - Allow insert if material is in inventory if not stocked
*			 GG 10/18/01 - #14946 - validation cleanup, corrected Last Unit Cost updates to bINMT and bINMU
*			 GG 12/11/01 - #15560 - don not allow negative avg unit cost
*			 GG 01/29/02 - #16086 - reset bINMT.AuditYN
*           DANF 08/23/02 - #17716 - Correct Avg unit cost
*           DANF 09/24/02 - #11664 - Added Booked Column
*			 MV 08/16/05 - #29558 - corrected AvgCost calc 
*			GG 08/22/05 - #29453 - corrected AvgCost calcs on change, validation cleanup
*			DANF 10/03/05 - #25822 - correct AvgCost when Expensing PO's on receipt
*			GG 04/17/07 - #122855 - fix AvgUnitCost calcs when expensing on receipts
*			TRL 11/12/07- 124100 - Update Last Cost for every cost transation
*			MV 04/25/08	- #127934 - If cost is burdened and POIT has taxcode include tax in @pounitcost
*			JonathanP 01/09/08 - #128879 - Added code to skip procedure if only UniqueAttachID changed.
*			GP 06/15/09 - #133811 - If VendorGroup is null then use HQCO Vendor Group
*			GF 07/30/2011 - TK-07143 PO expanded
*
*  Update trigger on bINDT (Inventory Detail)
*  Updates Avg Unit Cost, OnHand, Booked, Last Vendor, Last Unit Cost for the material in bINMT, bINMU
*
*--------------------------------------------------------------*/
   
declare @numrows int, @validcnt int, @errmsg varchar(255), @inco bCompany,
	@oldloc bLoc, @newloc bLoc, @oldmatlgroup bGroup, @newmatlgroup bGroup, @oldmaterial bMatl,
   	@newmaterial bMatl, @oldtranstype varchar(10), @newtranstype varchar(10), @oldunits bUnits,
   	@newunits bUnits, @oldtotalcost bDollar, @newtotalcost bDollar, @vendorgroup bGroup,
   	@vendor bVendor, @actdate bDate, @factor int, @unitcost bUnitCost, @ecm bECM,
   	@onhandunits bUnits, @source bSource, @po VARCHAR(30), @poitem bItem, @appoco bCompany,
   	@oldsource bSource, @oldpo VARCHAR(30), @oldpoitem bItem, @oldappoco bCompany,
  	@mth bMonth, @batchid bBatchID, @ExpensePO bYN, @pounitcost bUnitCost, @batchsource bSource,
  	@oldmth bMonth, @oldbatchid bBatchID, @oldavgtotalcost bDollar, @oldavgunits bUnits,
  	@newavgtotalcost bDollar, @newavgunits bUnits, @desc bDesc, @HQCOVendorGroup bGroup

declare @opencursor tinyint, @oldbooked bUnits, @oldavgcost bUnitCost, @oldavgecm bECM,
	@avgcost bUnitCost, @avgecm bECM, @stdum bUM, @um bUM, @newpostedunits bUnits, @oldpostedunits bUnits,
	@potaxcode bTaxCode,@taxrate bRate,	@potaxgroup bGroup, @burdenyn bYN
   
select @numrows = @@rowcount
if @numrows = 0 return
   
set nocount on
   
    --If the only column that changed was UniqueAttachID, then skip validation.        
	IF dbo.vfOnlyColumnUpdated(COLUMNS_UPDATED(), 'bINDT', 'UniqueAttchID') = 1
	BEGIN 
		goto Trigger_Skip
	END    
   
-- check for primary key changes
if Update(INCo)
	begin
	select @errmsg = 'IN Company may not be updated'
	goto error
	end
if Update(Mth)
	begin
	select @errmsg = 'Transaction Month may not be updated'
	goto error
	end
if Update(INTrans)
	begin
	select @errmsg = 'Transaction # may not be updated'
	goto error
	end
   
--if setting purge flag get out
if update(PurgeYN) return
   
--validate Location
if update(Loc)
	begin
	select @validcnt=count(*)
	from inserted i
	join dbo.INLM m with (nolock) on i.INCo = m.INCo and i.Loc = m.Loc
	where m.Active = 'Y'
	if @validcnt <> @numrows
       begin
       select @errmsg = 'Invalid or inactive Inventory Location'
       goto error
       end
   end
--validate Material
if update(Material) or update(Loc)
	begin
	select @validcnt = count(*)
	from inserted i
	join dbo.INMT t with (nolock) on i.INCo = t.INCo and i.Loc = t.Loc
		and i.MatlGroup = t.MatlGroup and i.Material = t.Material
	where t.Active = 'Y'
	if @validcnt <> @numrows
       begin
       select @errmsg = 'Not an Active Material at the Location'
       goto error
       end
   end
--validate GL Company and Account
if update(GLCo) or update(GLAcct)
	begin
	if exists(select top 1 1 from inserted i
		join dbo.GLAC a with (nolock) on a.GLCo = i.GLCo and a.GLAcct = i.GLAcct
		where a.AcctType = 'H' or a.Active = 'N' or (a.SubType is not null and a.SubType <> 'I'))
		begin
		select @errmsg = 'Invalid or inactive GL Account'
		goto error
		end
	end
   
-- update Average Cost and On Hand in bINMT
if @numrows = 1
	begin
	-- if only one row updated, no cursor is needed
	select @inco = i.INCo, @oldloc = d.Loc, @newloc = i.Loc, @oldmatlgroup = d.MatlGroup,
		@newmatlgroup = i.MatlGroup, @oldmaterial = d.Material, @newmaterial = i.Material,
		@actdate = i.ActDate, @oldtranstype = d.TransType, @newtranstype = i.TransType,
		@vendorgroup = i.VendorGroup, @vendor = i.Vendor, @oldpostedunits = d.PostedUnits, 
		@newpostedunits = i.PostedUnits, @unitcost = i.PostedUnitCost, @ecm = i.PostECM,
		@oldtotalcost = d.PostedTotalCost,@newtotalcost = i.PostedTotalCost,
		@oldunits = d.StkUnits, @newunits = i.StkUnits, @um = i.PostedUM, @stdum = i.StkUM,
		@source = i.Source,  @appoco = i.APPOCo, @po = i.PO, @poitem = i.POItem,
		@oldsource = d.Source,  @oldappoco = d.APPOCo, @oldpo = d.PO, @oldpoitem = d.POItem,
 		@mth = i.Mth, @batchid = i.BatchId, @oldmth = d.Mth, @oldbatchid = d.BatchId, @desc = i.Description
	from inserted i
	join deleted d on i.INCo = d.INCo and i.Mth = d.Mth and i.INTrans = d.INTrans
	end
else
	begin
	-- use a cursor to process all updated rows
	declare bINDT_update cursor for
	select i.INCo, d.Loc, i.Loc, d.MatlGroup, i.MatlGroup, d.Material, i.Material, i.ActDate,
		d.TransType, i.TransType, i.VendorGroup, i.Vendor, d.PostedUnits, i.PostedUnits, 
		i.PostedUnitCost, i.PostECM, d.PostedTotalCost, i.PostedTotalCost, d.StkUnits, i.StkUnits,
		i.PostedUM, i.StkUM, i.Source, i.APPOCo, i.PO, i.POItem, d.Source, d.APPOCo, d.PO, d.POItem,  
		i.Mth, i.BatchId, d.Mth, d.BatchId, i.Description
	from inserted i
	join deleted d on i.INCo = d.INCo and i.Mth = d.Mth and i.INTrans = d.INTrans

	open bINDT_update
	select @opencursor = 1
   
	-- get 1st row updated
	fetch next from bINDT_update into @inco, @oldloc, @newloc, @oldmatlgroup, @newmatlgroup, @oldmaterial, @newmaterial, @actdate,
		@oldtranstype, @newtranstype, @vendorgroup, @vendor, @oldpostedunits, @newpostedunits,
		@unitcost, @ecm, @oldtotalcost, @newtotalcost, @oldunits, @newunits,
		@um, @stdum, @source, @appoco, @po, @poitem, @oldsource,  @oldappoco, @oldpo, @oldpoitem,
		@mth, @batchid,  @oldmth, @oldbatchid, @desc
	if @@fetch_status <> 0
		begin
		select @errmsg = 'Cursor error '
		goto error
		end
	end

-- Flags used to determine if the avg unit cost will need to be updated for PO transactions from AP Entry and PO Receipts
-- when the user is updating expenses on the receipt of the PO. In the case where expensing PO's on receipt is turned on
-- Then do not update OnHand and Booked in INMT and only update Average Unit Cost if the Invoice unit cost diffs from
-- the Unit Cost updated during its receipt, which happens to be the PO's Orig Unit Cost.
select @batchsource = '', @ExpensePO = 'N', @pounitcost = 0, @oldavgtotalcost = @oldtotalcost , @oldavgunits = @oldunits

if (isnull(@oldpo,'') <>'' and isnull(@oldpoitem,'') <>'' and isnull(@oldappoco,'') <>'') and (@source = 'PO' or @source = 'AP Entry')
	begin
   	if exists (select 1 from dbo.POIT with (nolock) where POCo = @oldappoco and PO=@oldpo and POItem = @oldpoitem and RecvYN = 'Y')  and
		exists( select POCo from dbo.POCO with (nolock) where POCo=@oldappoco and ReceiptUpdate = 'Y'	and RecINInterfacelvl>0)
  		begin
		select @ExpensePO = 'Y'	
		-- Need to know if the posting was from AP Entry or PO Receipt
		select @batchsource = h.Source 
		from dbo.HQBC h with (nolock)
		where h.Co = @oldappoco and h.Mth = @oldmth and h.BatchId = @oldbatchid  

		select @pounitcost = OrigUnitCost, @potaxgroup = TaxGroup,@potaxcode=TaxCode
		from dbo.POIT with (nolock)
		where POCo = @oldappoco and PO = @oldpo and POItem = @oldpoitem

  		if @batchsource = 'AP Entry' -- sources from AP should be 'AP Entry' and 'PO Receipt'
  			begin
  			if @source = 'AP Entry' -- process 'AP Entry' but skip 'PO Receipt' when updating Avg Cost
  				begin
				--#127934 if cost is burdened and POIT has a taxcode, get tax rate and calc @pounitcost + (@pounitcost * taxrate)
				-- so when avgtotalcost is calculated @unitcost (from invoiced postedunitcost which includes tax if burdened
				-- will match @poitunitcost which does not include the tax amount)
				select @burdenyn = BurdenCost from bINCO with (nolock) where INCo=@inco
				if @burdenyn = 'Y' and @potaxcode is not null
				begin
					select @taxrate = dbo.vfHQTaxRate(@potaxgroup,@potaxcode,@actdate)
					select @pounitcost = @pounitcost + (@pounitcost * @taxrate)
				end
  				select @factor = case @avgecm when 'C' then 100 when 'M' then 1000 else 1 end
  				select @oldavgunits = 0, @oldavgtotalcost = ((@unitcost - @pounitcost) * @oldpostedunits) / @factor
  				if @oldavgtotalcost = 0 goto UpdateNewAvgCost
  				end
  			else
  				goto UpdateNewAvgCost -- Do not update Onhand, Booked or Average unit cost 
  			end
  		end
	end
  
INMT_update:
	-- Average Unit Cost update only performed for certain types of transactions
	if @oldloc <> @newloc or @oldmatlgroup <> @newmatlgroup or @oldmaterial <> @newmaterial
		or @oldtranstype <> @newtranstype or @oldunits <> @newunits or @oldtotalcost <> @newtotalcost
		begin
		-- adjust Avg Cost for old units
		if @oldtranstype in ('Adj','Purch','Prod','Trnsfr In')-- only performed for these trans types
			begin
			select @oldbooked = Booked, @oldavgcost = AvgCost, @oldavgecm = AvgECM
			from dbo.INMT with (nolock)
			where INCo = @inco and Loc = @oldloc and MatlGroup = @oldmatlgroup and Material = @oldmaterial
			if @@rowcount = 0
				begin
				select @errmsg = 'Unable to find INMT entry for Loc:' + @oldloc + ' Matl:' + @oldmaterial
				goto error
				end
   
   			select @avgcost = @oldavgcost, @avgecm = @oldavgecm    -- default to current values
   	        if @oldunits <> 0
   	            begin
   	            select @factor = case @avgecm when 'C' then 100 when 'M' then 1000 else 1 end
   	            select @avgcost = (@oldtotalcost / @oldunits) * @factor -- used posted total cost divided by stk units
   	            end
   
			-- recalculate Avg Unit Cost only if booked is and will be > 0
            if @oldbooked > 0 and (@oldbooked - @oldavgunits) > 0
				begin
                select @factor = case @avgecm when 'C' then 100 when 'M' then 1000 else 1 end
                select @avgcost = ((((@oldbooked * @oldavgcost) / @factor) - @oldavgtotalcost) / (@oldbooked - @oldavgunits)) * @factor --#29588
   				end
   
   			if @avgcost < 0 select @avgcost = 0 -- don't allow negative avg unit cost
   
   			update dbo.INMT set AvgCost = @avgcost, AvgECM = @avgecm, AuditYN = 'N'
               where INCo = @inco and Loc = @oldloc and MatlGroup = @oldmatlgroup and Material = @oldmaterial
   			if @@rowcount = 0
   				begin
   				select @errmsg = 'Unable to update Average Cost for Loc:' + @oldloc + ' Matl:' + @oldmaterial
   				goto error
   				end
			end
		-- adjust OnHand and Booked to backout old units
   		select @onhandunits = @oldunits
   		/*If the IN transaction is a purchase order from AP Entry, check the PO Company
   		  Receipt Update and Receipt Inventory level for the onhand qty to be updated in INMT.
   		  When the PO Company Receipt Update is off or the Receipt Inventory level is set to none 
   		  then the on hand qty is updated in the PORD trigger. This is only for PO receiving Items.*/
   		if @oldsource = 'AP Entry' and @oldtranstype = 'Purch' and isnull(@oldpo,'') <>'' and isnull(@oldpoitem,'') <>'' and isnull(@oldappoco,'') <>''
  			begin
  			if exists (select 1 from dbo.POIT with (nolock) where POCo = @oldappoco and PO=@oldpo and POItem = @oldpoitem and RecvYN = 'Y') 
  				and not exists( select POCo from dbo.POCO with (nolock) where POCo=@oldappoco and ReceiptUpdate = 'Y'	and RecINInterfacelvl>0)
          	select @onhandunits = 0
  			end
   
   		if @oldsource = 'PO' and @desc = 'Receipt Expense Initialize' select @onhandunits = 0
  
		-- do not update On Hand or Booked when Expensing PO receipts from AP Entry
  		if isnull(@ExpensePO,'N') = 'Y' and @batchsource = 'AP Entry' select @onhandunits = 0, @oldunits = 0

  		if isnull(@onhandunits,0) <> 0 or isnull(@oldunits,0) <> 0
  			begin
			-- On Hand update needed for all transactions types - done after Avg Unit Cost update
			update dbo.INMT set OnHand = OnHand - @onhandunits, Booked = Booked - @oldunits, AuditYN = 'N'
			where INCo = @inco and Loc = @oldloc and MatlGroup = @oldmatlgroup and Material = @oldmaterial
   			if @@rowcount = 0
   				begin
   				select @errmsg = 'Unable to update OnHand and Booked Units for Loc:' + @oldloc + ' Matl:' + @oldmaterial
   				goto error
   				end
  			end
  
		UpdateNewAvgCost:
  			-- Flags used to determine if the avg unit cost will need to be updated for PO transactions from AP Entry and PO Receipts
  			-- when the user is updating expenses on the receipt of the PO. In the case where expensing PO's on receipt is turned on
  			-- Then do not update OnHand and Booked in INMT and only update Average Unit Cost if the Invoice unit cost diffs from
  			-- the Unit Cost updated during its receipt, which happens to be the PO's Orig Unit Cost.
  			select @batchsource = '', @ExpensePO = 'N', @pounitcost = 0, @newavgtotalcost = @newtotalcost , @newavgunits = @newunits
	  		
  			if (isnull(@po,'') <>'' and isnull(@poitem,'') <>'' and isnull(@appoco,'') <>'') and (@source = 'PO' or @source = 'AP Entry')
  				begin
  		 		if exists (select 1 from dbo.POIT with (nolock) where POCo = @appoco and PO=@po and POItem = @poitem and RecvYN = 'Y')  and
  		 			exists( select POCo from dbo.POCO with (nolock) where POCo=@appoco and ReceiptUpdate = 'Y'	and RecINInterfacelvl>0)
  					begin
  		         	select @ExpensePO = 'Y'	
  					-- Need to know if the posting was from AP Entry or PO Receipt
  					select @batchsource = h.Source 
  					from dbo.HQBC h with (nolock)
  					where h.Co = @appoco and h.Mth = @mth and h.BatchId = @batchid  
  		
  					select @pounitcost = OrigUnitCost, @potaxgroup = TaxGroup,@potaxcode=TaxCode
  					from dbo.POIT with (nolock)
  					where POCo = @appoco and PO = @po and POItem = @poitem
  		
  					if @batchsource = 'AP Entry' -- sources from AP should be 'AP Entry' and 'PO Receipt'
  						begin
  						if @source = 'AP Entry' -- process 'AP Entry' but skip 'PO Receipt' when updating Avg Cost
  							begin
							--#127934 if cost is burdened and POIT has a taxcode, get tax rate and calc @pounitcost + (@pounitcost * taxrate)
							-- so when avgtotalcost is calculated @unitcost (from invoiced postedunitcost which includes tax if burdened
							-- will match @poitunitcost which does not include the tax amount)
							select @burdenyn = BurdenCost from bINCO with (nolock) where INCo=@inco
							if @burdenyn = 'Y' and @potaxcode is not null
							begin
								select @taxrate = dbo.vfHQTaxRate(@potaxgroup,@potaxcode,@actdate)
								select @pounitcost = @pounitcost + (@pounitcost * @taxrate)
							end
  	 						select @factor = case @avgecm when 'C' then 100 when 'M' then 1000 else 1 end
  						 	select @newavgunits = 0, @newavgtotalcost = ((@unitcost - @pounitcost) * @newpostedunits) / @factor -- use the difference
  						  	if @newavgtotalcost = 0 goto UpdateLastUnitCost
  							end
  						else
  							goto UpdateLastUnitCost -- Do not update Onhand, Booked or Average unit cost 
  						end
  					end
   				end
  
           -- adjust Avg Cost for 'new' units
           if @newtranstype in ('Adj','Purch','Prod','Trnsfr In')
  				-- do not reclauate avg unit cost when expensing PO's on receipt from AP Entry and the unit cost did not change
				begin
   				-- reselect values to reflect changes
				select @oldbooked = Booked, @oldavgcost = AvgCost, @oldavgecm = AvgECM
				from dbo.INMT with (nolock)
				where INCo = @inco and Loc = @newloc and MatlGroup = @newmatlgroup and Material = @newmaterial
   				if @@rowcount = 0
   					begin
   					select @errmsg = 'Unable to find INMT entry for Loc:' + @newloc + ' Matl:' + @newmaterial
   					goto error
   					end
   
   	        select @avgcost = @oldavgcost, @avgecm = @oldavgecm    -- default to current values
   	        if @newunits <> 0
   	            begin
   	            select @factor = case @avgecm when 'C' then 100 when 'M' then 1000 else 1 end
   	            select @avgcost = (@newtotalcost / @newunits) * @factor -- used posted total cost divided by stk units
   	            end
   
               -- recalculate Avg Unit Cost only if booked is and will be > 0
               if @oldbooked > 0 and (@oldbooked + @newavgunits) > 0
                   begin
             		select @factor = case @avgecm when 'C' then 100 when 'M' then 1000 else 1 end
                   select @avgcost = ((((@oldbooked * @oldavgcost) / @factor) + @newavgtotalcost) / (@oldbooked + @newavgunits)) * @factor --#29558
   				end
   
   			if @avgcost < 0 select @avgcost = 0 -- don't allow negative avg unit cost
   
               update dbo.INMT set AvgCost = @avgcost, AvgECM = @avgecm, AuditYN = 'N'
               where INCo = @inco and Loc = @newloc and MatlGroup = @newmatlgroup and Material = @newmaterial
               if @@rowcount = 0
   				begin
   				select @errmsg = 'Unable to update Average Cost for Loc:' + @newloc + ' Matl:' + @newmaterial
   				goto error
   				end
               end
   
   		select @onhandunits = @newunits
   		/*If the IN transaction is a purchase order from AP Entry, check the PO Company
   		  Receipt Update and Receipt Inventory level for the onhand qty to be updated in INMT.
   		  When the PO Company Receipt Update is off or the Receipt Inventory level is set to none 
   		  then the on hand qty is updated in the PORD trigger. This is only for PO receiving Items.*/
   		if @source = 'AP Entry' and @newtranstype = 'Purch' and isnull(@po,'') <>'' and isnull(@poitem,'') <>'' and isnull(@appoco,'') <>'' 
  		begin
  		if exists (select 1 from dbo.POIT with (nolock) where POCo = @appoco and PO=@po and POItem = @poitem and RecvYN = 'Y') 
  				and not exists( select POCo from dbo.POCO with (nolock) where POCo=@appoco and ReceiptUpdate = 'Y'	and RecINInterfacelvl>0)
          	select @onhandunits = 0
  		end
  
   	If @source = 'PO' and @desc = 'Receipt Expense Initialize' select @onhandunits = 0
  
      -- do not update On Hand or Booked when Expensing PO receipts from AP Entry
  	if isnull(@ExpensePO,'N') = 'Y' and @batchsource = 'AP Entry' select @onhandunits = 0, @newunits = 0
  
  
  	if isnull(@onhandunits,0) <> 0 or isnull(@newunits,0) <> 0
  		begin
   	         -- On Hand update needed for all transactions types - done after Avg Unit Cost update
  	         update dbo.INMT set OnHand = OnHand + @onhandunits, Booked = Booked + @newunits, AuditYN = 'N'
  	         where INCo = @inco and Loc = @newloc and MatlGroup = @newmatlgroup and Material = @newmaterial
  	 		 if @@rowcount = 0
  	 			begin
  	 			select @errmsg = 'Unable to update OnHand and Booked Units for Loc:' + @newloc + ' Matl:' + @newmaterial
  	 			goto error
  	 			end
  	         end
  		end
  UpdateLastUnitCost:
  
   	-- update Last Vendor and Cost for purchases, production and transfers in only - must be expressed in std u/m
       if @newtranstype in ('Purch', 'Prod', 'Trnsfr In')
   		begin
   		--Get VendorGroup from HQCO for null VendorGroup insert below, 133811
		select @HQCOVendorGroup = VendorGroup from HQCO with (nolock) where HQCo = @inco
		if @vendorgroup is null set @vendorgroup = @HQCOVendorGroup
   		
		--Issue 124100 Removed if/else
   		if @um = @stdum		-- update bINMT if entry made in standard U/M
   			begin
               update dbo.INMT set VendorGroup = @vendorgroup, LastVendor = @vendor, 
				LastCost = @unitcost,LastECM = @ecm, LastCostUpdate = @actdate, AuditYN = 'N'
               where INCo = @inco and Loc = @newloc and MatlGroup = @newmatlgroup and Material = @newmaterial
                   and (@actdate >= LastCostUpdate or LastCostUpdate is null)
               end
   		else
   			begin	-- update bINMU if entry made in alternative U/M
               update dbo.INMU set LastCost = @unitcost, LastECM = @ecm, LastCostUpdate = @actdate
               where INCo = @inco and Loc = @newloc and MatlGroup = @newmatlgroup and Material = @newmaterial
               	and UM = @um and (@actdate >= LastCostUpdate or LastCostUpdate is null)
   			-- update bINMT with Last Vendor only
			end
			
            --update dbo.bINMT set INMT.VendorGroup = @vendorgroup, INMT.LastVendor = @vendor, INMT.AuditYN = 'N'
			--where INCo = @inco and Loc = @newloc and MatlGroup = @newmatlgroup and Material = @newmaterial
            --and (@actdate >= LastCostUpdate or LastCostUpdate is null) 
			--Issue 124100
			update dbo.INMT set INMT.VendorGroup = @vendorgroup, INMT.LastVendor = @vendor, INMT.AuditYN = 'N',
   			INMT.LastCost = case when IsNull(INMU.Conversion,0) <> 0 then @unitcost/INMU.Conversion else @unitcost end,
			INMT.LastECM = @ecm, INMT.LastCostUpdate = @actdate
			From dbo.INMT a with (nolock)
			Left join dbo.INMU with (nolock) on INMU.INCo=a.INCo and INMU.Loc=a.Loc and INMU.MatlGroup=a.MatlGroup
			and INMU.Material=a.Material
			where a.INCo = @inco and a.Loc = @newloc and a.MatlGroup = @newmatlgroup and a.Material = @newmaterial
            and (@actdate >= a.LastCostUpdate or a.LastCostUpdate is null) and INMU.UM =@um
        end
   
   	-- get next row
   	if @numrows > 1
       	begin
       	fetch next from bINDT_update into @inco, @oldloc, @newloc, @oldmatlgroup, @newmatlgroup,
           	@oldmaterial, @newmaterial,@actdate, @oldtranstype, @newtranstype, @vendorgroup, @vendor,
           	@oldpostedunits, @newpostedunits, @unitcost, @ecm, @oldtotalcost, @newtotalcost, @oldunits,
			@newunits, @um, @stdum,	@source,  @appoco, @po, @poitem, @oldsource,  @oldappoco, @oldpo, @oldpoitem,
  		 	@mth, @batchid,  @oldmth, @oldbatchid, @desc
   
       	if @@fetch_status = 0 goto INMT_update
   
       	close bINDT_update
      		 deallocate bINDT_update
       	select @opencursor = 0
       	end
   
   -- reset IN Material Audit flag  - #16086
   update dbo.INMT
   set AuditYN = 'Y'
   from (select distinct INCo, Loc, MatlGroup, Material from inserted
   		union
   		select distinct INCo, Loc, MatlGroup, Material from deleted) as i
   	join dbo.INMT m with(nolock)on m.INCo = i.INCo and m.Loc = i.Loc and m.MatlGroup = i.MatlGroup and m.Material = i.Material
   
   
   Trigger_Skip:
   
   return
   
   error:
       if @opencursor = 1
           begin
           close bINDT_update
           deallocate bINDT_update
           end
   
       select @errmsg = @errmsg + ' - cannot update Inventory Detail'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
   
   
   
   
   
   
   
   
   
  
  
  
  
 
 
 



GO
CREATE NONCLUSTERED INDEX [biINDTReconcile] ON [dbo].[bINDT] ([INCo], [Loc], [MatlGroup], [Material], [Mth]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biINDT] ON [dbo].[bINDT] ([INCo], [Mth], [INTrans]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bINDT] ([KeyID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_bINDT_LocMatl] ON [dbo].[bINDT] ([Mth], [INCo], [Loc], [MatlGroup], [Material]) INCLUDE ([ActDate], [UniqueAttchID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biINDTRollup] ON [dbo].[bINDT] ([Mth], [Loc], [Material], [TransType]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bINDT].[PostECM]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bINDT].[StkECM]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bINDT].[PECM]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bINDT].[PurgeYN]'
GO
