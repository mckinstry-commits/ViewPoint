SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/************************************************/
CREATE   procedure [dbo].[bspMSTBValInv]
/*****************************************************************************
 * Created By:	GG 10/21/00
 * Modified By:	GG 02/13/02 - #16085 - use 'sell to' MatlGroup for cross-company sales
 *				GG 07/10/02 - #17159 - use override Misc and Tax accounts from bINLM and bINLO
 *				GF 12/05/2003 - #23205 - check error messages, wrap concatenated values with isnull
 *				GF 02/08/2006 - issue #120087 - use to location standard UM if same as posted UM
 *				GF 07/08/2008 - issue #128290 international tax GST/PST
 *				GF 03/29/2010 - issue #129350 surcharges
 *				GF 05/26/2010 - issue #139945 surcharges for inventory sale distributions (IN/GL) changed based on burden.
 *				GF 04/05/2013 TFS-46115 more information for surcharge ticket errors
 *
 *
 *
  * USAGE:
  *   Called by bspMSTBValDist to create Inventory sales distributions for a single sequence.
  *
  *   Adds/updates entries in bMSIN and bMSGL.
  *
  *   Errors in batch added to bHQBE using bspHQBEInsert
  *
  * INPUT PARAMETERS
  *   @msco               MS/IN Co#
  *   @mth                Batch month
  *   @batchid            Batch ID
  *   @seq                Batch Sequence
  *   @fromloc            Sell from Location
  *   @inco               Sell To IN Co#
  *   @toloc              Sell To Location
  *   @matlgroup          Material Group (based sell from IN Co#)
  *   @material           Material sold
  *   @matlcategory       Material Category
  *   @stdum              Material standard unit of measure
  *   @matlunits          Units sold (posted u/m)
  *   @matlum             Posted unit of measure
  *   @oldnew             0 = old (sign reversed on amounts), 1 = new
  *   @mstrans            MS Trans # (null for new entries)
  *   @ticket             Ticket #
  *   @saledate           Sale date
  *   @matltotal          Material sales total
  *   @unitprice          Material unit price (posted u/m)
  *   @ecm                Unit price per E,C,M
  *   @haultotal          Haul charge
  *   @taxtotal           Tax amount
  *	  @gsttaxamt		GST Tax Amount
  *
  * OUTPUT PARAMETERS
  *   @errmsg             error message
  *
  * RETURN
  *   0 = success, 1 = error
  *
  *******************************************************************************/
(@msco bCompany, @mth bMonth, @batchid bBatchID, @seq int, @fromloc bLoc, @inco bCompany,
 @toloc bLoc, @matlgroup bGroup, @material bMatl, @matlcategory varchar(10), @stdum bUM,
 @matlunits bUnits, @matlum bUM, @oldnew tinyint, @mstrans bTrans, @ticket bTic, @saledate bDate,
 @matltotal bDollar, @unitprice bUnitCost, @ecm bECM, @haultotal bDollar, @taxtotal bDollar, @gsttaxamt bDollar, 
 @SurchargeKeyID bigint = null, @SurchargeCode varchar(10) = null, @SurchargeTotal bDollar = 0,
 @SurchargeTax bDollar = 0, ----#129350
 @errmsg varchar(255) output)
as
set nocount on
  
declare @rcode int, @errorstart varchar(80), @errortext varchar(255), @costmethod tinyint, @invglacct bGLAcct,
		@costvarglacct bGLAcct, @stdunitcost bUnitCost, @stdecm bECM, @umconv bUnitCost, @stkunits bUnits, @postedtotalcost bDollar,
		@postedunitcost bUnitCost, @postedecm bECM, @stkunitcost bUnitCost, @stkecm bECM, @factor smallint, @stktotalcost bDollar,
		@toglco bCompany, @incocostmethod tinyint, @burdencost bYN, @miscglacct bGLAcct, @taxglacct bGLAcct,
		@locgroup bGroup, @lmcostmethod tinyint, @lminvglacct bGLAcct, @lmcostvarglacct bGLAcct, @locostmethod tinyint,
		@loinvglacct bGLAcct, @locostvarglacct bGLAcct, @tomatlgroup bGroup, @incomiscglacct bGLAcct, @lmmiscglacct bGLAcct,
		@lomiscglacct bGLAcct, @incotaxglacct bGLAcct, @lmtaxglacct bGLAcct, @lotaxglacct bGLAcct, @tomatlstdum bUM
 		----TFS-46115
		,@ParentSeq INT
        
select @rcode = 0

----TFS-46115
SET @errorstart = 'Seq# ' + dbo.vfToString(@seq)
IF @SurchargeKeyID IS NOT NULL
	BEGIN
	SELECT @ParentSeq = MSTB.BatchSeq
	FROM dbo.bMSTB MSTB WITH (NOLOCK)
	WHERE MSTB.KeyID = @SurchargeKeyID
	IF @@ROWCOUNT = 1
		BEGIN
		SELECT @errorstart = @errorstart + ' Parent Seq: ' + dbo.vfToString(@ParentSeq) + ' Surcharge Code: ' + dbo.vfToString(@SurchargeCode)
		END
	END



---- back out GST from tax total
select @taxtotal = @taxtotal - @gsttaxamt

---- get info from 'sell to' IN Company
select @toglco = i.GLCo, @incocostmethod = i.CostMethod, @burdencost = i.BurdenCost,
		@incomiscglacct = i.MiscGLAcct, @incotaxglacct = i.TaxGLAcct, @tomatlgroup = h.MatlGroup	-- get 'sell to' material group
from bINCO i with (nolock) join bHQCO h with (nolock) on h.HQCo = i.INCo
where i.INCo = @inco
if @@rowcount = 0
	begin
	select @errmsg = 'Invalid Sell To IN Company!', @rcode = 1   -- already validated
	goto bspexit
	end

---- issue #139945 if the batch record is a surcharge and has been included in the parent
---- as burdened we are done.
if @SurchargeKeyID is not null and @burdencost = 'Y'
	begin
	goto bspexit
	end

---- get location group, cost method, and inventory GL accts
select @locgroup = LocGroup, @lmcostmethod = CostMethod, @lminvglacct = InvGLAcct,
		@lmcostvarglacct = CostVarGLAcct, @lmmiscglacct = MiscGLAcct, @lmtaxglacct = TaxGLAcct
from bINLM with (nolock) where INCo = @inco and Loc = @toloc
if @@rowcount = 0
	begin
	select @errmsg = 'Invalid Sell To Location!', @rcode = 1   -- already validated
	goto bspexit
	end

---- check for cost method and inventory GL acct overrides based on location and category
select @locostmethod = CostMethod, @loinvglacct = InvGLAcct,  @locostvarglacct = CostVarGLAcct,
		@lomiscglacct = MiscGLAcct, @lotaxglacct = TaxGLAcct
from bINLO with (nolock) 
where INCo = @inco and Loc = @toloc and MatlGroup = @tomatlgroup and Category = @matlcategory

select @costmethod = @incocostmethod    -- company default
if isnull(@lmcostmethod,0) <> 0 select @costmethod = @lmcostmethod  -- override by location
if isnull(@locostmethod,0) <> 0 select @costmethod = @locostmethod  -- override by location / category

select @invglacct = isnull(@loinvglacct,@lminvglacct)   -- Inventory
select @costvarglacct = isnull(@locostvarglacct,@lmcostvarglacct)   -- Cost Variance
select @miscglacct = isnull(isnull(@lomiscglacct,@lmmiscglacct),@incomiscglacct)	-- Misc
select @taxglacct = isnull(isnull(@lotaxglacct,@lmtaxglacct),@incotaxglacct)	-- Tax

---- get std unit cost at 'sell to' Location
select @stdunitcost = StdCost, @stdecm = StdECM
from bINMT with (nolock) 
where INCo = @inco and Loc = @toloc and MatlGroup = @tomatlgroup and Material = @material
if @@rowcount = 0
	begin
	select @errmsg = 'Invalid Material at Sell To Location!', @rcode = 1   -- already validated
	goto bspexit
	end

---- get std um for material in sell to group #120087
select @tomatlstdum=StdUM from bHQMT with (nolock) where MatlGroup=@tomatlgroup and Material=@material
if @@rowcount = 0 select @tomatlstdum=@stdum

if @tomatlstdum <> @stdum select @stdum=@tomatlstdum
---- get material conversion factor
select @umconv = 1
if @matlum <> @stdum
	begin
	select @umconv = Conversion
	from bINMU with (nolock) 
	where INCo = @inco and Loc = @toloc and MatlGroup = @tomatlgroup and Material = @material and UM = @matlum
	if @@rowcount = 0
		begin
		select @errmsg = 'Invalid UM at Sell To Location!', @rcode = 1  -- already validated
		goto bspexit
		end
	end

select @stkunits = @matlunits * @umconv  -- convert units sold to std u/m
	
-- determine 'posted' total and unit cost
select @postedtotalcost = @matltotal, @postedunitcost = @unitprice, @postedecm = @ecm
if @burdencost = 'Y'
	begin
	---- if burdened, include haul and tax
	select @postedtotalcost = @matltotal + @haultotal + @taxtotal + @SurchargeTotal - @SurchargeTax
	select @postedunitcost = 0, @postedecm = 'E'
	if @matlunits <> 0 select @postedunitcost = @postedtotalcost / @matlunits
	end

---- determine 'stocked' values based on cost method
if @costmethod = 3  -- Std Unit Cost
	begin
	select @stkunitcost = @stdunitcost, @stkecm = @stdecm
	select @factor = case @stkecm when 'C' then 100 when 'M' then 1000 else 1 end
	select @stktotalcost = (@stkunits * @stkunitcost) / @factor
	end
else    ---- all other cost methods use posted values converted to std u/m
	begin
	select @stktotalcost = @postedtotalcost, @stkunitcost = 0, @stkecm = 'E'
	if @stkunits <> 0 select @stkunitcost = @postedtotalcost / @stkunits
	end

---- #139945 parent ticket only
if @SurchargeKeyID is null
	begin
	-- add purchase entry to IN distribution for 'sell to' IN Co# and Location
	insert bMSIN(MSCo, Mth, BatchId, INCo, Loc, MatlGroup, Material, INTransType, BatchSeq, HaulLine, OldNew,
			MSTrans, SaleDate, SalesINCo, SalesLoc, GLCo, GLAcct, PostedUM, PostedUnits, PostedUnitCost,
			PostECM, PostedTotalCost, StkUM, StkUnits, StkUnitCost, StkECM, StkTotalCost, UnitPrice,
			PECM, TotalPrice)
	values(@msco, @mth, @batchid, @inco, @toloc, @tomatlgroup, @material, 'Purch', @seq, 0, @oldnew,
			@mstrans, @saledate, @msco, @fromloc, @toglco, @invglacct, @matlum, @matlunits, @postedunitcost,
			@postedecm, @postedtotalcost, @stdum, @stkunits, @stkunitcost, @stkecm, @stktotalcost, 0, 'E', 0)
	end
	
-- validate Inventory Account for 'sell to' IN Co# and Location
exec @rcode = dbo.bspGLACfPostable @toglco, @invglacct, 'I', @errmsg output
if @rcode <> 0
	begin
	select @errortext = @errorstart + ' - Inventory Account at Sell To Location: ' + isnull(@errmsg,'')
	exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
	goto bspexit
	end
  
---- Inventory debit to 'sell to' Location
IF @SurchargeKeyID is null
	begin
	update bMSGL set Amount = Amount + @stktotalcost
	where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @toglco and GLAcct = @invglacct
	and BatchSeq = @seq and HaulLine = 0 and OldNew = @oldnew
	if @@rowcount = 0
		begin
		insert bMSGL(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, HaulLine, OldNew, MSTrans, Ticket, SaleDate,
				FromLoc, MatlGroup, Material, SaleType, INCo, ToLoc, Amount)
		values(@msco, @mth, @batchid, @toglco, @invglacct, @seq, 0, @oldnew, @mstrans, @ticket, @saledate,
				@fromloc, @matlgroup, @material, 'I', @inco, @toloc, @stktotalcost)
		end
	end
	
-- Cost Variance entry may be needed if 'sell to' Location uses Std Unit Cost
if @postedtotalcost <> @stktotalcost
	begin
	---- validate Cost Variance Account at 'sell to' Location
	exec @rcode = dbo.bspGLACfPostable @toglco, @costvarglacct, 'I', @errmsg output
	if @rcode <> 0
		begin
		select @errortext = @errorstart + ' - Cost Variance Account at Sell To Location: ' + isnull(@errmsg,'')
		exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
		goto bspexit
		end
		
	---- Cost Variance at 'sell to' Location
	IF @SurchargeKeyID is null ----or (@SurchargeKeyID is not null and @burdencost = 'N')
		begin
		update bMSGL set Amount = Amount + (@postedtotalcost - @stktotalcost)
		where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @toglco and GLAcct = @costvarglacct
		and BatchSeq = @seq and HaulLine = 0 and OldNew = @oldnew
		if @@rowcount = 0
			begin
			insert bMSGL(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, HaulLine, OldNew, MSTrans, Ticket, SaleDate,
					FromLoc, MatlGroup, Material, SaleType, INCo, ToLoc, Amount)
			values(@msco, @mth, @batchid, @toglco, @costvarglacct, @seq, 0, @oldnew, @mstrans, @ticket, @saledate,
					@fromloc, @matlgroup, @material, 'I', @inco, @toloc, (@postedtotalcost - @stktotalcost))
			end
		end
	end

---- Haul Expense entry may be needed if unit cost is not burdened
if @burdencost = 'N' and @haultotal <> 0
	begin
	---- validate Misc Account for 'sell to' IN Co# and Location
	exec @rcode = dbo.bspGLACfPostable @toglco, @miscglacct, 'I', @errmsg output
	if @rcode <> 0
		begin
		select @errortext = @errorstart + ' - Misc Account in Sell To IN Co#: ' + isnull(@errmsg,'')
		exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
		goto bspexit
		end
		
	---- Misc debit for haul charges at 'sell to' Location
	update bMSGL set Amount = Amount + @haultotal
	where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @toglco and GLAcct = @miscglacct
	and BatchSeq = @seq and HaulLine = 0 and OldNew = @oldnew
	if @@rowcount = 0
		begin
		insert bMSGL(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, HaulLine, OldNew, MSTrans, Ticket, SaleDate,
			FromLoc, MatlGroup, Material, SaleType, INCo, ToLoc, Amount)
		values(@msco, @mth, @batchid, @toglco, @miscglacct, @seq, 0, @oldnew, @mstrans, @ticket, @saledate,
			@fromloc, @matlgroup, @material, 'I', @inco, @toloc, @haultotal)
		end
	end


---- Tax Expense entry may be needed if unit cost is not burdened
if @burdencost = 'N' and @taxtotal <> 0
	begin
	---- validate Tax Expense Account for 'sell to' IN Co# and Location
	exec @rcode = dbo.bspGLACfPostable @toglco, @taxglacct, 'I', @errmsg output
	if @rcode <> 0
		begin
		select @errortext = @errorstart + ' - Tax Expense Account in Sell To IN Co#: ' + isnull(@errmsg,'')
		exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
		goto bspexit
		end
		
	---- Tax expense debit for tax total at 'sell to' Location
	update bMSGL set Amount = Amount + @taxtotal
	where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @toglco and GLAcct = @taxglacct
	and BatchSeq = @seq and HaulLine = 0 and OldNew = @oldnew
	if @@rowcount = 0
		begin
		insert bMSGL(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, HaulLine, OldNew, MSTrans, Ticket, SaleDate,
				FromLoc, MatlGroup, Material, SaleType, INCo, ToLoc, Amount)
		values(@msco, @mth, @batchid, @toglco, @taxglacct, @seq, 0, @oldnew, @mstrans, @ticket, @saledate,
				@fromloc, @matlgroup, @material, 'I', @inco, @toloc, @taxtotal)
		end
	end

---- #139945 Surcharge Expense entry may be needed if unit cost is not burdened
if @SurchargeKeyID is not null and @burdencost = 'N' and @matltotal <> 0
	begin
	---- validate Misc Account for 'sell to' IN Co# and Location
	exec @rcode = dbo.bspGLACfPostable @toglco, @miscglacct, 'I', @errmsg output
	if @rcode <> 0
		begin
		select @errortext = @errorstart + ' - Misc Account in Sell To IN Co#: ' + isnull(@errmsg,'')
		exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
		goto bspexit
		end
		
	---- Misc debit for surcharges at 'sell to' Location
	update bMSGL set Amount = Amount + @matltotal
	where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @toglco and GLAcct = @miscglacct
	and BatchSeq = @seq and HaulLine = 0 and OldNew = @oldnew
	if @@rowcount = 0
		begin
		insert bMSGL(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, HaulLine, OldNew, MSTrans, Ticket, SaleDate,
			FromLoc, MatlGroup, Material, SaleType, INCo, ToLoc, Amount)
		values(@msco, @mth, @batchid, @toglco, @miscglacct, @seq, 0, @oldnew, @mstrans, @ticket, @saledate,
			@fromloc, @matlgroup, @material, 'I', @inco, @toloc, @matltotal)
		end
	end




bspexit:
	if @rcode <> 0 select @errmsg = @errmsg
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSTBValInv] TO [public]
GO
