SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE     procedure [dbo].[bspMSTBValProd]
   /*****************************************************************************
   * Created By: GG 10/06/00
   * Modified: GG 02/07/01 - fixed component ECM
   *           GG 02/16/01 - record finish material in bMSPA with Prod entry
   *           GG 03/01/01 - fixed GL distributions when 'selling' components to production location
   *                       - change cost of production account to be based on component at production location
   *			 GG 07/12/01 - reverse sign on units on 'old' entries
   *			 GG 03/07/02 - #16525 - pull sales and qty override GL Accounts from bINLC
   *			 GF 05/23/03 - #21341 - component GL accounts need to be initialized to null for each record
   *			 GF 12/05/2003 - #23205 - check error messages, wrap concatenated values with isnull
   *			GG 02/02/04 - #20538 - split GL units flag
   *			GG 01/13/05 - #14689 - use MS Price Template and Quote pricing for component sales
   *			GG 02/16/05 - #27095 - correct rounding error on units
   *			GP 06/09/2008 - Issue #127986 - added @MatlVendor and @VendorGroup params to bspMSTicMatlPriceGet
   *			GF 08/17/2012 TK-17275 write out the finish material to MSPA
   *
   *			
   *
   * USAGE:
   *   Called by main MS Ticket Batch validation procedure (bspMSTBVal) to
   *   create Inventory production distributions for a single sequence.
   *
   *   Adds/updates entries in bMSPA and bMSGL.
   *
   *   Material has already been validated as an active auto produced material
   *   stocked at the sales/production Location.
   *
   *   Errors in batch added to bHQBE using bspHQBEInsert
   *
   * INPUT PARAMETERS
   *   @msco          MS/IN Co#
   *   @mth           Batch month
   *   @batchid       Batch ID
   *   @seq           Batch Sequence
   *   @prodloc       Production Location (sold from)
   *   @matlgroup     Material Group
   *   @material      Material produced
   *   @matlcategory  Category of produced material
   *   @matlstdum     Standard unit of measure of produced material
   *   @matlunits     Units produced (posted u/m)
   *   @matlum        Posted unit of measure
   *   @oldnew        0 = old (reverse sign on amounts), 1 = new
   *
   * OUTPUT PARAMETERS
   *   @errmsg        error message
   *
   *******************************************************************************/
        (@msco bCompany, @mth bMonth, @batchid bBatchID, @seq int, @prodloc bLoc,
         @matlgroup bGroup, @material bMatl, @matlcategory varchar(10), @matlstdum bUM,
         @matlunits bUnits, @matlum bUM, @oldnew tinyint, @errmsg varchar(max) output)
    as
    
    set nocount on
    
   declare @rcode int, @errorstart varchar(10), @errortext varchar(255), @matlcostmethod tinyint, @matlinvglacct bGLAcct,
   	@costprodglacct bGLAcct, @valprodglacct bGLAcct, @prodqtyglacct bGLAcct, @matlunitcost bUnitCost, @matlecm bECM,
   	@prodglunits bYN, @conv bUnitCost, @produnits numeric(14,5), @opencursor tinyint, @comploc bLoc, @compmatl bMatl, @units numeric(14,5),
   	@category varchar(10), @compstdum bUM, @compcostmethod tinyint, @costglacct bGLAcct, @compunitcost bUnitCost, @compecm bECM,
   	@compunitprice bUnitCost, @glunits bYN, @compunits numeric(14,5), @prodcostmethod tinyint, @produnitcost bUnitCost,
   	@prodecm bECM, @prodinvglacct bGLAcct, @costvarglacct bGLAcct, @factor smallint, @totalcost bDollar,
   	@unitcost bUnitCost, @ecm bECM, @prodtotalcost bDollar, @totalprice bDollar, @compinvglacct bGLAcct, 
   	@mstrans bTrans, @saledate bDate, @ticket bTic, @saletype char(1), @custgroup bGroup, @customer bCustomer, @custjob varchar(20),
   	@jcco bCompany, @job bJob, @inco bCompany, @toloc bLoc, @lmcompinvqtyglacct bGLAcct, @lccompinvqtyglacct bGLAcct,
   	@lmcompinvsalesglacct bGLAcct, @lccompinvsalesglacct bGLAcct,
   	@locpricetemplate smallint, @pricetemplate smallint, @quote varchar(10), @minamt bDollar, @comppecm bECM, 
	@MatlVendor bVendor, @VendorGroup bGroup
   
   -- bINCO declares
   declare @glco bCompany, @incocostmethod tinyint, @usageopt char(1), @invpriceopt tinyint
    
   -- bINLM declares
   declare @locgroup bGroup, @lmcostmethod tinyint, @lminvglacct bGLAcct, @lmcostprodglacct bGLAcct,
    	@lmvalprodglacct bGLAcct, @lmprodqtyglacct bGLAcct, @lmcostglacct bGLAcct, @compinvsalesglacct bGLAcct,
    	@compinvqtyglacct bGLAcct, @lmcostvarglacct bGLAcct
    
   -- bINLO declares
   declare @locostmethod tinyint, @loinvglacct bGLAcct, @locostprodglacct bGLAcct, @lovalprodglacct bGLAcct,
    	@loprodqtyglacct bGLAcct, @locostglacct bGLAcct, @locostvarglacct bGLAcct
    
   select @rcode = 0, @errorstart = 'Seq#' + convert(varchar(6),@seq), @opencursor = 0
    
   if @oldnew = 0 select @matlunits = -1 * @matlunits 	-- if old, reverse sign
   
   -- get old/new info from batch entry, used for bMSPA and bMSGL inserts
   select @mstrans = MSTrans,
        @saledate = case @oldnew when 0 then OldSaleDate else SaleDate end,
        @ticket = case @oldnew when 0 then OldTic else Ticket end,
        @saletype = case @oldnew when 0 then OldSaleType else SaleType end,
        @custgroup = case @oldnew when 0 then OldCustGroup else CustGroup end,
        @customer = case @oldnew when 0 then OldCustomer else Customer end,
        @custjob = case @oldnew when 0 then OldCustJob else CustJob end,
        @jcco = case @oldnew when 0 then OldJCCo else JCCo end,
        @job = case @oldnew when 0 then OldJob else Job end,
        @inco = case @oldnew when 0 then OldINCo else INCo end,
        @toloc = case @oldnew when 0 then OldToLoc else ToLoc end
   from dbo.bMSTB with (nolock) where Co = @msco and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
   if @@rowcount = 0
       begin
       select @errmsg = 'Missing Batch Sequence!', @rcode = 1
     	goto bspexit
       end
    
   -- get production related info from IN Company
   select @glco = GLCo, @incocostmethod = CostMethod, @usageopt = UsageOpt, @invpriceopt = InvPriceOpt
   from dbo.bINCO with (nolock) where INCo = @msco
   if @@rowcount = 0
       begin
       select @errmsg = 'Missing IN Company!', @rcode = 1   -- IN Co# already validated in bspMSTBVal
     	goto bspexit
       end
    
   -- get location group, cost method, and inventory GL accts for produced material
   select @locgroup = LocGroup, @lmcostmethod = CostMethod, @lminvglacct = InvGLAcct,
   	@lmvalprodglacct = ValProdGLAcct, @lmprodqtyglacct = ProdQtyGLAcct, @locpricetemplate = PriceTemplate
   from dbo.bINLM with (nolock) where INCo = @msco and Loc = @prodloc
   if @@rowcount = 0
       begin
       select @errmsg = 'Missing Location!', @rcode = 1   -- production/sales location already validated in bspMSTBVal
       goto bspexit
       end
   
   -- #14689 - look for MS Quote overrides
   select @quote = Quote, @pricetemplate = PriceTemplate
   from dbo.bMSQH (nolock)
   where MSCo = @msco and QuoteType = 'I' and INCo = @msco and Loc = @prodloc and Active = 'Y'
   
   -- Price Template in Quote overrides Location
   if @pricetemplate is null set @pricetemplate = @locpricetemplate
   
   -- check for cost method and inventory GL acct overrides based on production location and category
   select @locostmethod = CostMethod, @loinvglacct = InvGLAcct, @lovalprodglacct = ValProdGLAcct,
   	@loprodqtyglacct = ProdQtyGLAcct
   from dbo.bINLO with (nolock)
   where INCo = @msco and Loc = @prodloc and MatlGroup = @matlgroup and Category = @matlcategory
    
   select @matlcostmethod = @incocostmethod    -- company default
   if isnull(@lmcostmethod,0) <> 0 select @matlcostmethod = @lmcostmethod  -- override by location
   if isnull(@locostmethod,0) <> 0 select @matlcostmethod = @locostmethod  -- override by location / category
    
   select @matlinvglacct = isnull(@loinvglacct,@lminvglacct)   -- Inventory
   select @valprodglacct = isnull(@lovalprodglacct,@lmvalprodglacct)   -- Value of Prod
   select @prodqtyglacct = isnull(@loprodqtyglacct,@lmprodqtyglacct)   -- Prod Qty
    
   -- get unit cost (value) for produced material
   select @matlunitcost = case @matlcostmethod when 1 then AvgCost when 2 then LastCost else StdCost end,
   	@matlecm = case @matlcostmethod when 1 then AvgECM when 2 then LastECM else StdECM end,
       @prodglunits = GLProdUnits   -- flag to update units produced to GL
   from dbo.bINMT with (nolock) 
   where INCo = @msco and Loc = @prodloc and MatlGroup = @matlgroup and Material = @material
   if @@rowcount = 0
   	begin
       select @errmsg = 'Missing Inventory Material!', @rcode = 1   -- material validated in bspMSTBVal
      	goto bspexit
       end
    
   -- get conversion factor for auto produced material
   select @conv = 1
   if @matlum <> @matlstdum
   	begin
       select @conv = Conversion
       from dbo.bINMU with (nolock) 
       where INCo = @msco and Loc = @prodloc and MatlGroup = @matlgroup and Material = @material and UM = @matlum
       if @@rowcount = 0
       	begin
           select @errortext = @errorstart + ' - Invalid U/M, must be setup for Material: ' + isnull(@material,'') + ' at Location: ' + isnull(@prodloc,'')
           exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
      	    goto bspexit
           end
       end
   
   select @produnits = @matlunits * @conv  -- convert units produced to std u/m
    
   -- if Bill of Materials Override exists, use it
   if exists(select 1 from dbo.bINBO with (nolock) where INCo = @msco and Loc = @prodloc and MatlGroup = @matlgroup and FinMatl = @material)
   	begin
       -- create cursor of Components from Bill of Materials override
       declare Component cursor LOCAL FAST_FORWARD
   	for select CompLoc, CompMatl, Units
       from dbo.bINBO with (nolock) 
       where INCo = @msco and Loc = @prodloc and MatlGroup = @matlgroup and FinMatl = @material
       end
   else
       begin
       -- no override, use standard Bill of Materials
       if not exists(select top 1 1 from dbo.bINBM with (nolock) where INCo = @msco and LocGroup = @locgroup and MatlGroup = @matlgroup and FinMatl = @material)
       	begin
           select @errortext = @errorstart + ' - Missing standard Bill of Materials!'
           exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
      	    goto bspexit
           end
       -- create cursor of Components from standard Bill of Materials
       declare Component cursor LOCAL FAST_FORWARD
   	for select @prodloc, CompMatl, Units    -- all components must exist at production location
       from dbo.bINBM with (nolock) 
       where INCo = @msco and LocGroup = @locgroup and MatlGroup = @matlgroup and FinMatl = @material
       end
    
   -- open Component cursor for processing
   open Component
   select @opencursor = 1
    
   Component_loop:      -- loop through all components
   	fetch next from Component into @comploc, @compmatl, @units
       if @@fetch_status <> 0 goto Component_end
    
       -- get component category and std u/m
       select @category = Category, @compstdum = StdUM
       from dbo.bHQMT with (nolock) 
       where MatlGroup = @matlgroup and Material = @compmatl and Active = 'Y'
       if @@rowcount = 0
       	begin
           select @errortext = @errorstart + ' - Invalid Component: ' + isnull(@compmatl,'') + ', must be active in HQ!'
           exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
      	    goto bspexit
           end
    
       -- get component cost method and GL accts based on source location
       select @lmcostmethod = CostMethod, @lminvglacct = InvGLAcct, @lmcostglacct = CostGLAcct,
       	@lmcostprodglacct = CostProdGLAcct, @lmcompinvsalesglacct = InvSalesGLAcct, @lmcompinvqtyglacct = InvQtyGLAcct
       from dbo.bINLM with (nolock) where INCo = @msco and Loc = @comploc
       if @@rowcount = 0
           begin
           select @errortext = @errorstart + ' - Invalid Component Location ' + isnull(@comploc,'')
           exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
      	    goto bspexit
           end
       -- check for cost method and inventory GL acct overrides based on source location and category
       select @locostmethod = null, @loinvglacct = null, @locostglacct = null, @locostprodglacct = null
       select @locostmethod = CostMethod, @loinvglacct = InvGLAcct, @locostglacct = CostGLAcct, @locostprodglacct = CostProdGLAcct
       from dbo.bINLO with (nolock) where INCo = @msco and Loc = @comploc and MatlGroup = @matlgroup and Category = @category
    	-- check for sales accounts overrides based on source location, company, and category
   	-- issue #21341
   	select @lccompinvsalesglacct = null, @lccompinvqtyglacct = null
   	select @lccompinvsalesglacct = InvSalesGLAcct, @lccompinvqtyglacct = InvQtyGLAcct
       from dbo.bINLC with (nolock) 
   	where INCo = @msco and Loc = @comploc and Co = @msco and MatlGroup = @matlgroup and Category = @category
   
       select @compcostmethod = @incocostmethod    -- company default
       if isnull(@lmcostmethod,0) <> 0 select @compcostmethod = @lmcostmethod  -- override by location
       if isnull(@locostmethod,0) <> 0 select @compcostmethod = @locostmethod  -- override by location / category
    
       select @compinvglacct = isnull(@loinvglacct,@lminvglacct)   -- Inventory
       select @costglacct = isnull(@locostglacct,@lmcostglacct)   -- Cost of Sales
   	select @compinvsalesglacct = isnull(@lccompinvsalesglacct,@lmcompinvsalesglacct)	-- Sales to Inventory 
   	select @compinvqtyglacct = isnull(@lccompinvqtyglacct,@lmcompinvqtyglacct)		-- Qty Sales to Inventory
    
    
       -- get component unit cost from source location
       select @compunitcost = case @compcostmethod when 1 then AvgCost when 2 then LastCost else StdCost end,
       	@compecm = case @compcostmethod when 1 then AvgECM when 2 then LastECM else StdECM end,
           @glunits = GLSaleUnits   -- flag to update sales units to GL
   	from dbo.bINMT with (nolock) 
       where INCo = @msco and Loc = @comploc and MatlGroup = @matlgroup and Material = @compmatl and Active = 'Y'
       if @@rowcount = 0
            begin
            select @errortext = @errorstart + ' - Invalid Component ' + isnull(@compmatl,'') + ', must be active at Location ' + isnull(@comploc,'')
            exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
      	     goto bspexit
            end
    
   	select @compunits = @units * @produnits     -- component units used in production
    
       -- set production values equal to compomnent - used when component and production locations are the same
       select @prodcostmethod = @compcostmethod, @produnitcost = @compunitcost, @prodecm = @compecm,
       	@prodinvglacct = @compinvglacct
    
       -- get cost method and GL accounts based on production location
       if @comploc <> @prodloc
       	begin
           select @lmcostmethod = CostMethod, @lminvglacct = InvGLAcct, @lmcostvarglacct = CostVarGLAcct,
           	@lmcostprodglacct = CostProdGLAcct  -- cost of prod based on component and prod location
           from dbo.bINLM with (nolock) where INCo = @msco and Loc = @prodloc
           if @@rowcount = 0
   	        begin
   	        select @rcode = 1   -- production/sales location already validated
   	   	    goto bspexit
   	        end
           -- check for cost method and gl account overrides based on production location and component category
           select @locostmethod = null, @loinvglacct = null, @locostvarglacct = null, @locostprodglacct = null
           select @locostmethod = CostMethod, @loinvglacct = InvGLAcct, @locostvarglacct = CostVarGLAcct,
           	@locostprodglacct = CostProdGLAcct  -- cost of prod override
           from dbo.bINLO with (nolock) where INCo = @msco and Loc = @prodloc and MatlGroup = @matlgroup and Category = @category
    
           select @prodcostmethod = @incocostmethod    -- company default
           if isnull(@lmcostmethod,0) <> 0 select @prodcostmethod = @lmcostmethod  -- override by location
           if isnull(@locostmethod,0) <> 0 select @prodcostmethod = @locostmethod  -- override by location / category
    
 
           select @prodinvglacct = isnull(@loinvglacct,@lminvglacct)   -- Inventory
           select @costvarglacct = isnull(@locostvarglacct,@lmcostvarglacct)   -- Cost Variance
    
           -- get component unit cost and price from production location
           select @produnitcost = case @prodcostmethod when 1 then AvgCost when 2 then LastCost else StdCost end,
           	@prodecm = case @prodcostmethod when 1 then AvgECM when 2 then LastECM else StdECM end
           from dbo.bINMT with (nolock) 
           where INCo = @msco and Loc = @prodloc and MatlGroup = @matlgroup and Material = @compmatl and Active = 'Y'
           if @@rowcount = 0
               begin
               select @errortext = @errorstart + ' - Invalid Component: ' + isnull(@compmatl,'') + ', must be active at Location ' + isnull(@prodloc,'')
               exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
      	        goto bspexit
               end
           end
    
   	-- transfer component from source to production location
       if @comploc <> @prodloc and @usageopt = 'T'
           begin
           -- 'transfer out' of source location -- value based on source cost method
           select @factor = case @compecm when 'C' then 100 when 'M' then 1000 else 1 end
           select @totalcost = (@compunits * @compunitcost) / @factor

--set @errmsg = 'DANSO TESTING - '
--set @errmsg = @errmsg + '1'
--set @rcode = 1
--goto bspexit

           insert dbo.bMSPA(MSCo, Mth, BatchId, Loc, MatlGroup, Material, INTransType, BatchSeq, OldNew,
           	MSTrans, SaleDate, SellTrnsfrLoc, UM, Units, UnitCost, ECM, TotalCost, UnitPrice, PECM, TotalPrice
           	----TK-17275
           	,FinishMatl)
           values(@msco, @mth, @batchid, @comploc, @matlgroup, @compmatl, 'Trnsfr Out', @seq, @oldnew,
                @mstrans, @saledate, @prodloc, @compstdum, -@compunits, @compunitcost, isnull(@compecm,'E'), -@totalcost, 0, 'E', 0
                ----TK-17275
                ,@material)
           
   		-- validate Inventory GL Account for component at source location
           exec @rcode = dbo.bspGLACfPostable @glco, @compinvglacct, 'I', @errmsg output
           if @rcode <> 0
           	begin
               select @errortext = @errorstart + ' - Inventory Account for material ' + isnull(@compmatl,'') + ' at Location ' + isnull(@comploc,'') + ' : ' + isnull(@errmsg,'')
               exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
      	        goto bspexit
               end
           -- Inventory credit to source location
           update dbo.bMSGL set Amount = Amount - @totalcost
           where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @glco and GLAcct = @compinvglacct
           	and BatchSeq = @seq and HaulLine = 0 and OldNew = @oldnew
            if @@rowcount = 0
            	insert dbo.bMSGL(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, HaulLine, OldNew, MSTrans, Ticket, SaleDate,
               	FromLoc, MatlGroup, Material, SaleType, CustGroup, Customer, CustJob, JCCo, Job, INCo, ToLoc, Amount)
               values(@msco, @mth, @batchid, @glco, @compinvglacct, @seq, 0, @oldnew, @mstrans, @ticket, @saledate,
                   @prodloc, @matlgroup, @material, @saletype, @custgroup, @customer, @custjob,
                   @jcco, @job, @inco, @toloc, -@totalcost)
    
           -- 'transfer in' to production location -- value based on cost method, if Std use std unit cost, else use actual
           select @unitcost = case @prodcostmethod when 3 then @produnitcost else @compunitcost end
           select @ecm = case @prodcostmethod when 3 then @prodecm else @compecm end
           select @factor = case @ecm when 'C' then 100 when 'M' then 1000 else 1 end
           select @prodtotalcost = (@compunits * @unitcost) / @factor

  
   		insert dbo.bMSPA(MSCo, Mth, BatchId, Loc, MatlGroup, Material, INTransType, BatchSeq, OldNew,
           	MSTrans, SaleDate, SellTrnsfrLoc, UM, Units, UnitCost, ECM, TotalCost, UnitPrice, PECM, TotalPrice
           	----TK-17275
           	,FinishMatl)
           values(@msco, @mth, @batchid, @prodloc, @matlgroup, @compmatl, 'Trnsfr In', @seq, @oldnew,
               @mstrans, @saledate, @comploc, @compstdum, @compunits, @unitcost, isnull(@ecm,'E'), @prodtotalcost, 0, 'E', 0
               ----TK-17275
               ,@material)
           
   		-- validate Inventory GL Account for component at production location
           exec @rcode = dbo.bspGLACfPostable @glco, @prodinvglacct, 'I', @errmsg output
           if @rcode <> 0
               begin
               select @errortext = @errorstart + ' - Inventory account for material ' + isnull(@compmatl,'') + ' at Location '
                   + isnull(@prodloc,'') + ' : ' + @errmsg
               exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
      	        goto bspexit
               end
           
   		-- Inventory debit to production location
           update dbo.bMSGL set Amount = Amount + @prodtotalcost
           where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @glco and GLAcct = @prodinvglacct
           	and BatchSeq = @seq and HaulLine = 0 and OldNew = @oldnew
           if @@rowcount = 0
           insert dbo.bMSGL(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, HaulLine, OldNew, MSTrans, Ticket, SaleDate,
           	FromLoc, MatlGroup, Material, SaleType, CustGroup, Customer, CustJob, JCCo, Job, INCo, ToLoc, Amount)
           values(@msco, @mth, @batchid, @glco, @prodinvglacct, @seq, 0, @oldnew, @mstrans, @ticket, @saledate,
               @prodloc, @matlgroup, @material, @saletype, @custgroup, @customer, @custjob,
               @jcco, @job, @inco, @toloc, @prodtotalcost)
           -- Cost Variance entry may be needed if production location uses Std Unit Cost
           if @totalcost <> @prodtotalcost
               begin
               -- validate Cost Variance GL Account for component at production location
               exec @rcode = dbo.bspGLACfPostable @glco, @costvarglacct, 'I', @errmsg output
               if @rcode <> 0
               	begin
                   select @errortext = @errorstart + ' - Cost Variance Account for material ' + isnull(@compmatl,'') + ' at Location ' + isnull(@prodloc,'') + ' : ' + isnull(@errmsg,'')
                   exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
      	            goto bspexit
                   end
               -- Cost Variance to production location
               update dbo.bMSGL set Amount = Amount + (@totalcost - @prodtotalcost)
               where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @glco and GLAcct = @costvarglacct
               	and BatchSeq = @seq and HaulLine = 0 and OldNew = @oldnew
               if @@rowcount = 0
               	insert dbo.bMSGL(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, HaulLine, OldNew, MSTrans, Ticket, SaleDate,
                   	FromLoc, MatlGroup, Material, SaleType, CustGroup, Customer, CustJob, JCCo, Job, INCo, ToLoc, Amount)
                   values(@msco, @mth, @batchid, @glco, @costvarglacct, @seq, 0, @oldnew, @mstrans, @ticket, @saledate,
                       @prodloc, @matlgroup, @material, @saletype, @custgroup, @customer, @custjob,
                     	@jcco, @job, @inco, @toloc, (@totalcost - @prodtotalcost))
               end
   		end
    
   	-- sell component from source to production location
       if @comploc <> @prodloc and @usageopt = 'S'
           begin
   		-- #14689 - use MS pricing hierarchy to determine unit price
   		exec @rcode = dbo.bspMSTicMatlPriceGet @msco, @matlgroup, @compmatl, @locgroup, @comploc,
   			@compstdum, @quote, @pricetemplate, @saledate, null, null, null, null, @msco, @prodloc, 
   			@invpriceopt, 'I', null, null, @MatlVendor, @VendorGroup, 
			@compunitprice output, @comppecm output, @minamt output, @errmsg output
   		if @rcode <> 0
   			begin
   			select @errortext = @errorstart + ' - Unit Price for material ' + isnull(@compmatl,'') + ' at Location ' + isnull(@comploc,'') + ' : ' + isnull(@errmsg,'')
               exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
      	        goto bspexit
               end
   
   		-- 'IN sale' from source location -- value based on pricing option
           select @factor = case @compecm when 'C' then 100 when 'M' then 1000 else 1 end
           select @totalcost = (@compunits * @compunitcost) / @factor
    		select @factor = case @comppecm when 'C' then 100 when 'M' then 1000 else 1 end
           select @totalprice = (@compunits * @compunitprice) / @factor
 
--set @errmsg = @errmsg + '3'
--set @rcode = 1
--goto bspexit
  
           insert dbo.bMSPA(MSCo, Mth, BatchId, Loc, MatlGroup, Material, INTransType, BatchSeq, OldNew,
           	MSTrans, SaleDate, SellTrnsfrLoc, UM, Units, UnitCost, ECM, TotalCost, UnitPrice, PECM, TotalPrice
           	----TK-17275
           	,FinishMatl)
           values(@msco, @mth, @batchid, @comploc, @matlgroup, @compmatl, 'IN Sale', @seq, @oldnew,
               @mstrans, @saledate, @prodloc, @compstdum, -@compunits, @compunitcost, isnull(@compecm,'E'), -@totalcost,
               @compunitprice, isnull(@comppecm,'E'), -@totalprice
               ----TK-17275
               ,@material)
    
           -- validate Inventory GL Account for component at source location
           exec @rcode = dbo.bspGLACfPostable @glco, @compinvglacct, 'I', @errmsg output
           if @rcode <> 0
               begin
               select @errortext = @errorstart + ' - Inventory Account for material ' + isnull(@compmatl,'') + ' at Location ' + isnull(@comploc,'') + ' : ' + isnull(@errmsg,'')
               exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
      	        goto bspexit
               end
           -- Inventory credit to source location
           update dbo.bMSGL set Amount = Amount - @totalcost
           where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @glco and GLAcct = @compinvglacct
           	and BatchSeq = @seq and HaulLine = 0 and OldNew = @oldnew
           if @@rowcount = 0
               insert dbo.bMSGL(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, HaulLine, OldNew, MSTrans, Ticket, SaleDate,
               	FromLoc, MatlGroup, Material, SaleType, CustGroup, Customer, CustJob, JCCo, Job, INCo, ToLoc, Amount)
               values(@msco, @mth, @batchid, @glco, @compinvglacct, @seq, 0, @oldnew, @mstrans, @ticket, @saledate,
                   @prodloc, @matlgroup, @material, @saletype, @custgroup, @customer, @custjob,
                   @jcco, @job, @inco, @toloc, -@totalcost)
    
           -- validate Cost of Sales GL Account for component at source location
           exec @rcode = dbo.bspGLACfPostable @glco, @costglacct, 'I', @errmsg output
           if @rcode <> 0
               begin
               select @errortext = @errorstart + ' - Cost of Sales Account for material ' + isnull(@compmatl,'') + ' at Location ' + isnull(@comploc,'') + ' : ' + isnull(@errmsg,'')
               exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
      	        goto bspexit
               end
           -- Cost of Sales debit to source location -- offsets Inventory credit
           update dbo.bMSGL set Amount = Amount + @totalcost
           where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @glco and GLAcct = @costglacct
               and BatchSeq = @seq and HaulLine = 0 and OldNew = @oldnew
           if @@rowcount = 0
               insert dbo.bMSGL(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, HaulLine, OldNew, MSTrans, Ticket, SaleDate,
                   FromLoc, MatlGroup, Material, SaleType, CustGroup, Customer, CustJob, JCCo, Job, INCo, ToLoc, Amount)
               values(@msco, @mth, @batchid, @glco, @costglacct, @seq, 0, @oldnew, @mstrans, @ticket, @saledate,
                   @prodloc, @matlgroup, @material, @saletype, @custgroup, @customer, @custjob,
                   @jcco, @job, @inco, @toloc, @totalcost)
    
           -- validate Sales To Inventory GL Account for component at source location
           exec @rcode = dbo.bspGLACfPostable @glco, @compinvsalesglacct, 'I', @errmsg output
           if @rcode <> 0
               begin
               select @errortext = @errorstart + ' - Sales to Inventory Account for material ' + isnull(@compmatl,'') + ' at Location ' + isnull(@comploc,'') + ' : ' + isnull(@errmsg,'')
               exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
      	        goto bspexit
               end
           -- Sales to Inventory credit to source location -- value based on Inventory pricing option
           update dbo.bMSGL set Amount = Amount - @totalprice
           where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @glco and GLAcct = @compinvsalesglacct
               and BatchSeq = @seq and HaulLine = 0 and OldNew = @oldnew
           if @@rowcount = 0
               insert dbo.bMSGL(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, HaulLine, OldNew, MSTrans, Ticket, SaleDate,
                   FromLoc, MatlGroup, Material, SaleType, CustGroup, Customer, CustJob, JCCo, Job, INCo, ToLoc, Amount)
               values(@msco, @mth, @batchid, @glco, @compinvsalesglacct, @seq, 0, @oldnew, @mstrans, @ticket, @saledate,
                   @prodloc, @matlgroup, @material, @saletype, @custgroup, @customer, @custjob,
                   @jcco, @job, @inco, @toloc, -@totalprice)
    
           -- Qty Sold --
           if @glunits ='Y' and @compinvqtyglacct is not null
               begin
               -- validate Sales Qty To Inventory GL Account for component at source location
               exec @rcode = dbo.bspGLACQtyVal @glco, @compinvqtyglacct, @errmsg output
               if @rcode <> 0
               	begin
                   select @errortext = @errorstart + ' - Sales Qty to Inventory Account for material ' + isnull(@compmatl,'') + ' at Location ' + isnull(@comploc,'') + ' : ' + isnull(@errmsg,'')
                   exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
      	            goto bspexit
                   end
               -- Sales Qty to Inventory credit to source location -- qty of component sold to production location
               update dbo.bMSGL set Amount = Amount - @compunits
               where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @glco and GLAcct = @compinvqtyglacct
                   and BatchSeq = @seq and HaulLine = 0 and OldNew = @oldnew
               if @@rowcount = 0
                   insert dbo.bMSGL(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, HaulLine, OldNew, MSTrans, Ticket, SaleDate,
                    	FromLoc, MatlGroup, Material, SaleType, CustGroup, Customer, CustJob, JCCo, Job, INCo, ToLoc, Amount)
                	values(@msco, @mth, @batchid, @glco, @compinvqtyglacct, @seq, 0, @oldnew, @mstrans, @ticket, @saledate,
                    	@prodloc, @matlgroup, @material, @saletype, @custgroup, @customer, @custjob,
                    	@jcco, @job, @inco, @toloc, -@compunits)
               end
    
   		-- 'Purchase' by production location -- value based on cost method, if Std use std unit cost, else use actual
           select @unitcost = case @prodcostmethod when 3 then @produnitcost else @compunitprice end
           select @ecm = case @prodcostmethod when 3 then @prodecm else @comppecm end
           select @factor = case @ecm when 'C' then 100 when 'M' then 1000 else 1 end
           select @prodtotalcost = (@compunits * @unitcost) / @factor
 
--set @errmsg = @errmsg + '4'
--set @rcode = 1
--goto bspexit
 
           insert dbo.bMSPA(MSCo, Mth, BatchId, Loc, MatlGroup, Material, INTransType, BatchSeq, OldNew,
               MSTrans, SaleDate, SellTrnsfrLoc, UM, Units, UnitCost, ECM, TotalCost, UnitPrice, PECM, TotalPrice
               ----TK-17275
               ,FinishMatl)
           values(@msco, @mth, @batchid, @prodloc, @matlgroup, @compmatl, 'Purch', @seq, @oldnew,
               @mstrans, @saledate, @comploc, @compstdum, @compunits, @unitcost, isnull(@ecm,'E'), @prodtotalcost, 0, 'E', 0
               ----TK-17275
               ,@material)
    
           -- validate Inventory GL Account for component at production location
           exec @rcode = dbo.bspGLACfPostable @glco, @prodinvglacct, 'I', @errmsg output
           if @rcode <> 0
               begin
               select @errortext = @errorstart + ' - Inventory account for material ' + isnull(@compmatl,'') + ' at Location ' + isnull(@prodloc,'') + ' : ' + isnull(@errmsg,'')
               exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
      	        goto bspexit
               end
           -- Inventory debit to production location
           update dbo.bMSGL set Amount = Amount + @prodtotalcost
           where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @glco and GLAcct = @prodinvglacct
               and BatchSeq = @seq and HaulLine = 0 and OldNew = @oldnew
           if @@rowcount = 0
               insert dbo.bMSGL(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, HaulLine, OldNew, MSTrans, Ticket, SaleDate,
                   FromLoc, MatlGroup, Material, SaleType, CustGroup, Customer, CustJob, JCCo, Job, INCo, ToLoc, Amount)
               values(@msco, @mth, @batchid, @glco, @prodinvglacct, @seq, 0, @oldnew, @mstrans, @ticket, @saledate,
                   @prodloc, @matlgroup, @material, @saletype, @custgroup, @customer, @custjob,
                   @jcco, @job, @inco, @toloc, @prodtotalcost)
    
           -- Cost Variance entry may be needed if production location uses Std Unit Cost
           if @totalprice <> @prodtotalcost
               begin
               -- validate Cost Variance GL Account for component at production location
               exec @rcode = dbo.bspGLACfPostable @glco, @costvarglacct, 'I', @errmsg output
               if @rcode <> 0
                   begin
                   select @errortext = @errorstart + ' - Cost Variance Account for material ' + isnull(@compmatl,'') + ' at Location ' + isnull(@prodloc,'') + ' : ' + isnull(@errmsg,'')
                   exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
      	            goto bspexit
                   end
               -- Cost Variance to production location
               update dbo.bMSGL set Amount = Amount + (@totalprice - @prodtotalcost)
               where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @glco and GLAcct = @costvarglacct
                   and BatchSeq = @seq and HaulLine = 0 and OldNew = @oldnew
               if @@rowcount = 0
                   insert dbo.bMSGL(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, HaulLine, OldNew, MSTrans, Ticket, SaleDate,
                       FromLoc, MatlGroup, Material, SaleType, CustGroup, Customer, CustJob, JCCo, Job, INCo, ToLoc, Amount)
                   values(@msco, @mth, @batchid, @glco, @costvarglacct, @seq, 0, @oldnew, @mstrans, @ticket, @saledate,
                       @prodloc, @matlgroup, @material, @saletype, @custgroup, @customer, @custjob,
                       @jcco, @job, @inco, @toloc, (@totalprice - @prodtotalcost))
               end
   		end
    
   -- finished transfering/selling components to production location, generate component usage and cost of production entries
    
   	-- 'Usage' of component at production location
       select @factor = case @prodecm when 'C' then 100 when 'M' then 1000 else 1 end
       select @totalcost = (@compunits * @produnitcost) / @factor
       insert dbo.bMSPA(MSCo, Mth, BatchId, Loc, MatlGroup, Material, INTransType, BatchSeq, OldNew,
           MSTrans, SaleDate, SellTrnsfrLoc, UM, Units, UnitCost, ECM, TotalCost, UnitPrice, PECM, TotalPrice
           ----TK-17275
           ,FinishMatl)
       values(@msco, @mth, @batchid, @prodloc, @matlgroup, @compmatl, 'Usage', @seq, @oldnew,
        	@mstrans, @saledate, @prodloc, @compstdum, -@compunits, @produnitcost, isnull(@ecm,'E'), -@totalcost, 0, 'E', 0
        	----TK-17275
        	,@material)



    
       -- validate Inventory GL Account for component at production location
       exec @rcode = dbo.bspGLACfPostable @glco, @prodinvglacct, 'I', @errmsg output
       if @rcode <> 0
           begin
           select @errortext = @errorstart + ' - Inventory Account for material ' + isnull(@compmatl,'') + ' at Location '
               + isnull(@prodloc,'') + ' : ' + isnull(@errmsg,'')
           exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
      	    goto bspexit
           end
       -- Inventory credit to production location
       update dbo.bMSGL set Amount = Amount - @totalcost
       where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @glco and GLAcct = @prodinvglacct
           and BatchSeq = @seq and HaulLine = 0 and OldNew = @oldnew
       if @@rowcount = 0
           insert dbo.bMSGL(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, HaulLine, OldNew, MSTrans, Ticket, SaleDate,
                   FromLoc, MatlGroup, Material, SaleType, CustGroup, Customer, CustJob, JCCo, Job, INCo, ToLoc, Amount)
           values(@msco, @mth, @batchid, @glco, @prodinvglacct, @seq, 0, @oldnew, @mstrans, @ticket, @saledate,
                   @prodloc, @matlgroup, @material, @saletype, @custgroup, @customer, @custjob,
                   @jcco, @job, @inco, @toloc, -@totalcost)
    
   	-- validate Cost of Prod GL Account, based on production location and component
       select @costprodglacct = isnull(@locostprodglacct,@lmcostprodglacct) -- default in bINLM with override in bIMLO
       exec @rcode = dbo.bspGLACfPostable @glco, @costprodglacct, 'I', @errmsg output
       if @rcode <> 0
       	begin
           select @errortext = @errorstart + ' - Cost of Prod Account for material ' + isnull(@compmatl,'') + ' at Location '
               + isnull(@prodloc,'') + ' : ' + isnull(@errmsg,'')
           exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
      	    goto bspexit
           end
       -- Cost of Production debit offsets Inventory credit
       update dbo.bMSGL set Amount = Amount + @totalcost
       where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @glco and GLAcct = @costprodglacct
       	and BatchSeq = @seq and HaulLine = 0 and OldNew = @oldnew
       if @@rowcount = 0
           insert dbo.bMSGL(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, HaulLine, OldNew, MSTrans, Ticket, SaleDate,
           	FromLoc, MatlGroup, Material, SaleType, CustGroup, Customer, CustJob, JCCo, Job, INCo, ToLoc, Amount)
           values(@msco, @mth, @batchid, @glco, @costprodglacct, @seq, 0, @oldnew, @mstrans, @ticket, @saledate,
               @prodloc, @matlgroup, @material, @saletype, @custgroup, @customer, @custjob,
               @jcco, @job, @inco, @toloc, @totalcost)
    
       goto Component_loop      -- get next Component
    
   Component_end:  -- finished with components in Bill of Materials
       close Component
       deallocate Component
       select @opencursor = 0
    
   -- finished with components, generate production entries for finished good

--set @errmsg = @errmsg + '6'
--set @rcode = 1
--goto bspexit
    
   -- add 'Production' entry -- value based on finished material cost method
   select @factor = case @matlecm when 'C' then 100 when 'M' then 1000 else 1 end
   select @totalcost = (@produnits * @matlunitcost) / @factor
   insert dbo.bMSPA(MSCo, Mth, BatchId, Loc, MatlGroup, Material, INTransType, BatchSeq, OldNew,
   	MSTrans, SaleDate, SellTrnsfrLoc, UM, Units, UnitCost, ECM, TotalCost, UnitPrice, PECM, TotalPrice)
   values(@msco, @mth, @batchid, @prodloc, @matlgroup, @material, 'Prod', @seq, @oldnew,
       @mstrans, @saledate, @prodloc, @matlstdum, @produnits, @matlunitcost, isnull(@matlecm,'E'), @totalcost, 0, 'E', 0)
   -- validate Inventory GL Account for finished material at production location
   exec @rcode = dbo.bspGLACfPostable @glco, @matlinvglacct, 'I', @errmsg output
   if @rcode <> 0
       begin
       select @errortext = @errorstart + ' - Inventory account for material ' + isnull(@material,'') + ' at Location '
       	+ isnull(@prodloc,'') + ' : ' + isnull(@errmsg,'')
       exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
      	goto bspexit
       end
   -- Inventory debit to production location
   update dbo.bMSGL set Amount = Amount + @totalcost
   where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @glco and GLAcct = @matlinvglacct
       and BatchSeq = @seq and HaulLine = 0 and OldNew = @oldnew
   if @@rowcount = 0
       insert dbo.bMSGL(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, HaulLine, OldNew, MSTrans, Ticket, SaleDate,
         	FromLoc, MatlGroup, Material, SaleType, CustGroup, Customer, CustJob, JCCo, Job, INCo, ToLoc, Amount)

       values(@msco, @mth, @batchid, @glco, @matlinvglacct, @seq, 0, @oldnew, @mstrans, @ticket, @saledate,
           @prodloc, @matlgroup, @material, @saletype, @custgroup, @customer, @custjob,
           @jcco, @job, @inco, @toloc, @totalcost)
    
   -- validate Value of Prod GL Account for finished material at production location
   exec @rcode = dbo.bspGLACfPostable @glco, @valprodglacct, 'I', @errmsg output
   if @rcode <> 0
   	begin
       select @errortext = @errorstart + ' - Value of Prod account for material ' + isnull(@material,'') + ' at Location '
       	+ isnull(@prodloc,'') + ' : ' + isnull(@errmsg,'')
      	exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
      	goto bspexit
       end
   -- Value of Prod credit to production location -- offsets Inventory debit
   update dbo.bMSGL set Amount = Amount - @totalcost
   where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @glco and GLAcct = @valprodglacct
   	and BatchSeq = @seq and HaulLine = 0 and OldNew = @oldnew
   if @@rowcount = 0
       insert dbo.bMSGL(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, HaulLine, OldNew, MSTrans, Ticket, SaleDate,
         	FromLoc, MatlGroup, Material, SaleType, CustGroup, Customer, CustJob, JCCo, Job, INCo, ToLoc, Amount)
       values(@msco, @mth, @batchid, @glco, @valprodglacct, @seq, 0, @oldnew, @mstrans, @ticket, @saledate,
           @prodloc, @matlgroup, @material, @saletype, @custgroup, @customer, @custjob,
           @jcco, @job, @inco, @toloc, -@totalcost)
   
   -- Qty Sold --
   if @prodglunits ='Y' and @prodqtyglacct is not null
   	begin
       -- validate Sales Qty To Inventory GL Account for component at source location
       exec @rcode = dbo.bspGLACQtyVal @glco, @prodqtyglacct, @errmsg output
       if @rcode <> 0
       	begin
           select @errortext = @errorstart + ' - Prod Qty Account for material ' + isnull(@material,'') + ' at Location '
             	+ isnull(@prodloc,'') + ' : ' + isnull(@errmsg,'')
           exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
      	    goto bspexit
           end
       -- Prod Qty debit to production location -- qty of finished mateial produced
       update dbo.bMSGL set Amount = Amount + @produnits
       where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @glco and GLAcct = @prodqtyglacct
           and BatchSeq = @seq and HaulLine = 0 and OldNew = @oldnew
       if @@rowcount = 0
           insert dbo.bMSGL(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, HaulLine, OldNew, MSTrans, Ticket, SaleDate,
            	FromLoc, MatlGroup, Material, SaleType, CustGroup, Customer, CustJob, JCCo, Job, INCo, ToLoc, Amount)
           values(@msco, @mth, @batchid, @glco, @prodqtyglacct, @seq, 0, @oldnew, @mstrans, @ticket, @saledate,
               @prodloc, @matlgroup, @material, @saletype, @custgroup, @customer, @custjob,
               @jcco, @job, @inco, @toloc, @produnits)
   	end
    
   
   bspexit:
   	if @opencursor = 1
   		begin
   		close Component
   		deallocate Component
   		end
   
   	if @rcode <> 0 select @errmsg = isnull(@errmsg,'')
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSTBValProd] TO [public]
GO
