SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/******************************************/
CREATE procedure [dbo].[bspMSLBValInv]
/*****************************************************************************
 * Created By:	GG 11/06/00
 * Modified By: GG 02/05/01 - fixed MSIN and MSGL distribution updates
 *				GF 02/08/2006 - issue #120169 use to location material group and validate std um to posted um
 *				GF 10/03/2007 - issue #125660 - use Misc GLAcct, Tax GLAcct same as Ticket Val. INLM, INLO, INCO.
 *				GF 07/08/2008 - issue #128290 international tax GST/PST
 *
 *
 * USAGE:
 *   Called by bspMSLBValDist to create Inventory sales distributions for a single Haul Line.
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
 *   @haulline           Haul Line
 *   @fromloc            Sell from Location
 *   @inco               Sell To IN Co#
 *   @toloc              Sell To Location
 *   @matlgroup          Material Group
 *   @material           Material sold
 *   @matlcategory       Material Category
 *   @stdum              Material standard unit of measure
 *   @matlum             Posted unit of measure
 *   @oldnew             0 = old (sign reversed on amounts), 1 = new
 *   @mstrans            MS Trans # (null for new entries)
 *   @saledate           Sale date
 *   @ecm                Unit price per E,C,M
 *   @haultotal          Haul charge
 *   @taxtotal           Tax amount
 *	 @gsttaxamt			 GST Tax Amount
 *
 * OUTPUT PARAMETERS
 *   @errmsg             error message
 *
 * RETURN
 *   0 = success, 1 = error
 *
 *******************************************************************************/
(@msco bCompany, @mth bMonth, @batchid bBatchID, @seq int, @haulline smallint, @fromloc bLoc,
 @inco bCompany, @toloc bLoc, @matlgroup bGroup, @material bMatl, @matlcategory varchar(10),
 @stdum bUM, @matlum bUM, @oldnew tinyint, @mstrans bTrans, @saledate bDate, @haultotal bDollar,
 @taxtotal bDollar, @gsttaxamt bDollar, @errmsg varchar(255) output)
as
set nocount on

declare @rcode int, @errorstart varchar(30), @errortext varchar(255), @costmethod tinyint,
		@invglacct bGLAcct, @costvarglacct bGLAcct, @toglco bCompany, @incocostmethod tinyint,
		@burdencost bYN, @miscglacct bGLAcct, @taxglacct bGLAcct, @locgroup bGroup,
		@lmcostmethod tinyint, @lminvglacct bGLAcct, @lmcostvarglacct bGLAcct,
		@locostmethod tinyint, @loinvglacct bGLAcct, @locostvarglacct bGLAcct, @tomatlgroup bGroup,
		@tomatlstdum bUM, @incomiscglacct bGLAcct, @lomiscglacct bGLAcct, @lmmiscglacct bGLAcct,
		@incotaxglacct bGLAcct, @lmtaxglacct bGLAcct, @lotaxglacct bGLAcct

select @rcode = 0, @errorstart = 'Seq#' + convert(varchar(6),@seq) + ' Line#' + convert(varchar(6),@haulline)

---- back out GST from tax total
select @taxtotal = @taxtotal - @gsttaxamt

---- get info from 'sell to' IN Company
select @toglco = i.GLCo, @incocostmethod = i.CostMethod, @burdencost = i.BurdenCost,
		@incomiscglacct=i.MiscGLAcct, @incotaxglacct=i.TaxGLAcct, @tomatlgroup=h.MatlGroup	-- get 'sell to' material group
from INCO i with (nolock) join bHQCO h with (nolock) on h.HQCo=i.INCo
where INCo = @inco
if @@rowcount = 0
	begin
	select @errmsg = 'Invalid Sell To IN Company!', @rcode = 1   -- already validated
   	goto bspexit
	end

---- get location group, cost method, and inventory GL accts
select @locgroup=LocGroup, @lmcostmethod=CostMethod, @lminvglacct=InvGLAcct,
		@lmcostvarglacct=CostVarGLAcct, @lmmiscglacct=MiscGLAcct, @lmtaxglacct=TaxGLAcct
from INLM with (nolock) where INCo = @inco and Loc = @toloc
if @@rowcount = 0
	begin
	select @errmsg = 'Invalid Sell To Location!', @rcode = 1   -- already validated
	goto bspexit
	end

---- check for cost method and inventory GL acct overrides based on location and category
select @locostmethod=CostMethod, @loinvglacct=InvGLAcct, @locostvarglacct=CostVarGLAcct,
		@lomiscglacct=MiscGLAcct, @lotaxglacct=TaxGLAcct
from INLO with (nolock)
where INCo = @inco and Loc = @toloc and MatlGroup = @tomatlgroup and Category = @matlcategory

select @costmethod = @incocostmethod    -- company default
if isnull(@lmcostmethod,0) <> 0 select @costmethod = @lmcostmethod  -- override by location
if isnull(@locostmethod,0) <> 0 select @costmethod = @locostmethod  -- override by location / category

select @invglacct = isnull(@loinvglacct,@lminvglacct)   -- Inventory
select @costvarglacct = isnull(@locostvarglacct,@lmcostvarglacct)   -- Cost Variance
---- issue #125603
select @miscglacct = isnull(isnull(@lomiscglacct,@lmmiscglacct),@incomiscglacct)	-- Misc
select @taxglacct = isnull(isnull(@lotaxglacct,@lmtaxglacct),@incotaxglacct)	-- Tax

-- -- -- get std um for material in sell to group #120087
select @tomatlstdum=StdUM from bHQMT with (nolock) where MatlGroup=@tomatlgroup and Material=@material
if @@rowcount = 0 select @tomatlstdum=@stdum

if @tomatlstdum <> @stdum select @stdum=@tomatlstdum


  -- 'Sell To' Inventory Unit Costs are Burdened - include Haul and Tax
  if @burdencost = 'Y'
      begin
      if @costmethod = 3  -- Std Unit Cost, no MSIN distribution needed, Haul and Tax posted to Cost Variance
          begin
          -- validate Cost Variance Account at 'sell to' Location
          exec @rcode = bspGLACfPostable @toglco, @costvarglacct, 'I', @errmsg output
          if @rcode <> 0
              begin
              select @errortext = @errorstart + ' - Cost Variance Account at Sell To Location: ' + isnull(@errmsg,'')
              exec @rcode = bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
    	        goto bspexit
              end
          -- Cost Variance at 'sell to' Location
          update bMSGL set Amount = Amount + (@haultotal + @taxtotal)
          where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @toglco and GLAcct = @costvarglacct
              and BatchSeq = @seq and HaulLine = @haulline and OldNew = @oldnew
          if @@rowcount = 0
              insert bMSGL(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, HaulLine, OldNew, MSTrans, Ticket, SaleDate,
                  FromLoc, MatlGroup, Material, SaleType, INCo, ToLoc, Amount)
              values(@msco, @mth, @batchid, @toglco, @costvarglacct, @seq, @haulline, @oldnew, @mstrans, null, @saledate,
                  @fromloc, @matlgroup, @material, 'I', @inco, @toloc, (@haultotal + @taxtotal))
          end
      if @costmethod <> 3     -- not using Std Unit Cost, MSIN needed, Haul and Tax posted to Inventory
          begin
          -- add purchase entry to IN distribution for 'sell to' IN Co# and Location
          insert bMSIN(MSCo, Mth, BatchId, INCo, Loc, MatlGroup, Material, INTransType, BatchSeq, HaulLine, OldNew,
              MSTrans, SaleDate, SalesINCo, SalesLoc, GLCo, GLAcct, PostedUM, PostedUnits, PostedUnitCost,
              PostECM, PostedTotalCost, StkUM, StkUnits, StkUnitCost, StkECM, StkTotalCost, UnitPrice,
              PECM, TotalPrice)
          values(@msco, @mth, @batchid, @inco, @toloc, @tomatlgroup, @material, 'Purch', @seq, @haulline, @oldnew,
              @mstrans, @saledate, @msco, @fromloc, @toglco, @invglacct, @matlum, 0, 0, 'E', (@haultotal + @taxtotal),
              @stdum, 0, 0, 'E', (@haultotal + @taxtotal), 0, 'E', 0)
  
          -- validate Inventory Account for 'sell to' IN Co# and Location
          exec @rcode = bspGLACfPostable @toglco, @invglacct, 'I', @errmsg output
          if @rcode <> 0
              begin
              select @errortext = @errorstart + ' - Inventory Account at Sell To Location: ' + isnull(@errmsg,'')
              exec @rcode = bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
    	        goto bspexit
              end
          -- Inventory debit to 'sell to' Location
          update bMSGL set Amount = Amount + (@haultotal + @taxtotal)
          where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @toglco and GLAcct = @invglacct
              and BatchSeq = @seq and HaulLine = @haulline and OldNew = @oldnew
          if @@rowcount = 0
              insert bMSGL(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, HaulLine, OldNew, MSTrans, Ticket, SaleDate,
                  FromLoc, MatlGroup, Material, SaleType, INCo, ToLoc, Amount)
              values(@msco, @mth, @batchid, @toglco, @invglacct, @seq, @haulline, @oldnew, @mstrans, null, @saledate,
                  @fromloc, @matlgroup, @material, 'I', @inco, @toloc, (@haultotal + @taxtotal))
          end
      end
  
  -- 'Sell To' Inventory Unit Costs are not Burdened - MSIN not needed, Haul and Tax posted to INCO accounts
  if @burdencost = 'N' and @haultotal <> 0    -- Haul
      begin
      -- validate Misc Account for 'sell to' IN Co# and Location
      exec @rcode = bspGLACfPostable @toglco, @miscglacct, 'I', @errmsg output
      if @rcode <> 0
          begin
          select @errortext = @errorstart + ' - Misc Account in Sell To IN Co#: ' + isnull(@errmsg,'')
          exec @rcode = bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
    	    goto bspexit
          end
      -- Misc debit for haul charges at 'sell to' Location
      update bMSGL set Amount = Amount + @haultotal
      where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @toglco and GLAcct = @miscglacct
          and BatchSeq = @seq and HaulLine = @haulline and OldNew = @oldnew
      if @@rowcount = 0
          insert bMSGL(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, HaulLine, OldNew, MSTrans, Ticket, SaleDate,
              FromLoc, MatlGroup, Material, SaleType, INCo, ToLoc, Amount)
          values(@msco, @mth, @batchid, @toglco, @miscglacct, @seq, @haulline, @oldnew, @mstrans, null, @saledate,
              @fromloc, @matlgroup, @material, 'I', @inco, @toloc, @haultotal)
      end
  if @burdencost = 'N' and @taxtotal <> 0     -- Tax
      begin
      -- validate Tax Expense Account for 'sell to' IN Co# and Location
      exec @rcode = bspGLACfPostable @toglco, @taxglacct, 'I', @errmsg output
      if @rcode <> 0
          begin
          select @errortext = @errorstart + ' - Tax Expense Account in Sell To IN Co#: ' + isnull(@errmsg,'')
          exec @rcode = bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
    	    goto bspexit
          end
      -- Tax expense debit for tax total at 'sell to' Location
      update bMSGL set Amount = Amount + @taxtotal
      where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @toglco and GLAcct = @taxglacct
          and BatchSeq = @seq and HaulLine = @haulline and OldNew = @oldnew
      if @@rowcount = 0
          insert bMSGL(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, HaulLine, OldNew, MSTrans, Ticket, SaleDate,
              FromLoc, MatlGroup, Material, SaleType, INCo, ToLoc, Amount)
          values(@msco, @mth, @batchid, @toglco, @taxglacct, @seq, @haulline, @oldnew, @mstrans, null, @saledate,
              @fromloc, @matlgroup, @material, 'I', @inco, @toloc, @taxtotal)
      end






bspexit:
	if @rcode <> 0 select @errmsg = isnull(@errmsg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSLBValInv] TO [public]
GO
