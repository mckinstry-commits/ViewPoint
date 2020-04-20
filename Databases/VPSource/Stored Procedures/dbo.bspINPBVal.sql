SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspINPBVal]
    /*****************************************************************************
    * Created: GR 5/01/00
    * Modified: GG 10/02/01 - rewritten
    *           GH 10/29/01 - changed total variables to bDollar instead of bUnitCost, causing rounding problems Issue 15076  
    *			GG 03/07/02 - #16525 - pull sales and qty override GL Accounts from bINLC
    *			RM 08/05/02 - Fixed Pulling from wrong GL acct, issue #18161
    *			RM 08/22/03 - Made possible to have same material for component, from different location, #21241
    *			GG 02/02/04 - #20538 - split GL units flag
    *
    * USAGE:
    * Validates each entry in an Inventory Production batch (bINPB, bINPD)
    * Called prior to posting the batch. Loads GL Distribution table.
    *
    * Errors in batch added to bHQBE using bspHQBEInsert
    *
    * INPUT PARAMETERS
    *   @inco          INCo
    *   @mth           Batch month
    *   @batchid       Batch ID to validate
    *
    * OUTPUT PARAMETERS
    *   @errmsg        error message
    *
    *******************************************************************************/
    	(@inco bCompany = null , @mth bMonth = null, @batchid bBatchID = null, @errmsg varchar(255) output)
   as
   
   set nocount on
   
   declare @batchseq int, @prodloc bLoc, @matlgroup bGroup, @finmatl bMatl, @actdate bDate,
   	@description bDesc, @um bUM, @unitcost bUnitCost, @ecm bECM, @totalcost bDollar,
       @stdecm bECM, @stdtotalcost bDollar, @stdunitcost bUnitCost, @usageopt varchar(1),
       @factor int, @costvarglacct bGLAcct, @costglacct bGLAcct, @compinvsalesglacct bGLAcct,
   	@totalprice bDollar, @compinvqtyglacct bGLAcct, @lmcompinvqtyglacct bGLAcct, @lccompinvqtyglacct bGLAcct,
       @prodinvglacct bGLAcct, @valprodglacct bGLAcct, @lmvalprodglacct bGLAcct, @lmprodqtyglacct bGLAcct,
   	@loprodqtyglacct bGLAcct, @lmcostglacct bGLAcct, @locostglacct bGLAcct,
       @prodglunits bYN, @compglunits bYN, @costprodglacct bGLAcct, @compcostmethod tinyint,
       @prodqtyglacct bGLAcct, @produnits bUnits, @incocostmethod tinyint,
   	@matlcategory varchar(10), @lminvglacct bGLAcct, @loinvglacct bGLAcct, @lovalprodglacct bGLAcct,
   	@loproqtyglacct bGLAcct, @lmcostmethod tinyint, @locostmethod tinyint, @lmcostprodglacct bGLAcct,
   	@locostprodglacct bGLAcct, @lmcostvarglacct bGLAcct, @locostvarglacct bGLAcct, @prodcostmethod tinyint,
   	@produnitcost bUnitCost, @prodecm bECM, @lmcompinvsalesglacct bGLAcct, @lccompinvsalesglacct bGLAcct
   	
   
   declare @comploc bLoc, @compmatl bMatl, @compmatlgroup bGroup, @compum bUM,
        @compunits bUnits, @compunitcost bUnitCost, @compecm bECM, @compunitprice bUnitCost,
        @comppecm bECM, @prodseq int, @glco bCompany, @compinvglacct bGLAcct,
        @matlinvglacct bGLAcct, @compcategory varchar(10), @compstdum bUM,
        @postedtotalcost bDollar
   
   declare @rcode int, @openinpb int, @openinpd int, @errorstart varchar(60), @errortext varchar(255),
        @status int, @active bYN, @stdum bUM
   
   select @rcode = 0, @openinpb = 0, @openinpd = 0
   
   --validate HQ Batch
   exec @rcode = bspHQBatchProcessVal @inco, @mth, @batchid, 'IN Prod', 'INPB', @errmsg output, @status output
   if @rcode <> 0 
		begin
			goto bspexit
		end
   if @status < 0 or @status > 3
		begin
			select @errmsg = 'Invalid Batch status!', @rcode = 1
			goto bspexit
		end
   --set HQ Batch status to 1 (validation in progress)
   update bHQBC set Status = 1
   where Co = @inco and Mth = @mth and BatchId = @batchid
   if @@rowcount = 0
       begin
			select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
			goto bspexit
       end
   
   --clear HQ Batch Errors
   delete bHQBE where Co = @inco and Mth = @mth and BatchId = @batchid
   --clear GL Distribution
   delete bINPG where INCo = @inco and Mth = @mth and BatchId = @batchid
   
   -- validate IN Company - get production related info
   select @glco = GLCo, @incocostmethod = CostMethod, @usageopt = UsageOpt
   from bINCO where INCo = @inco
   if @@rowcount = 0
   	begin
       select @errmsg = 'Missing IN Company!', @rcode = 1   
     	goto bspexit
     end
   -- validate Usage Option
   if @usageopt not in ('S','T')
   	begin
      	select @errmsg = 'Usage option for multi-location Bill of Materials must be set to ''Sale'' or ''Transfer'' in IN Company.', @rcode = 1
	 	goto bspexit
   	end
               
   -- create a cursor to process all entries in batch
   declare INPBbatch_cursor cursor for
   select BatchSeq, ActDate, ProdLoc, MatlGroup, FinMatl, UM, Units, UnitCost, ECM, Description
   from bINPB
   where Co = @inco and Mth = @mth and BatchId = @batchid
   
   open INPBbatch_cursor            -- open the cursor
   select @openinpb = 1
   
   INPBbatch_cursor_loop:                  --loop through all the records
   	fetch next from INPBbatch_cursor into @batchseq, @actdate, @prodloc, @matlgroup,
   		@finmatl, @um, @produnits, @unitcost, @ecm, @description
   
   	if @@fetch_status <> 0 
			begin
				goto INPBbatch_cursor_end
			end
   
       select @errorstart = 'Seq#: ' + convert(varchar(6),@batchseq)
   
   		-- validate Finished Material 
       select @matlcategory = Category, @stdum = StdUM
       from bHQMT
       where MatlGroup = @matlgroup and Material = @finmatl and Active = 'Y'
       if @@rowcount = 0
   		 begin
				select @errortext = @errorstart + ' - Material: ' + @finmatl + ' is not a valid, active HQ Material.'
				exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
       			if @rcode <> 0
					begin
						 goto bspexit
					end
				goto INPBbatch_cursor_loop
       	 end
   
   		-- validate Production Location  
    	select @lminvglacct = InvGLAcct, @lmvalprodglacct = ValProdGLAcct, @lmprodqtyglacct = ProdQtyGLAcct
    	from bINLM
   		where INCo = @inco and Loc = @prodloc and Active = 'Y'
    	if @@rowcount = 0
        	begin
				select @errortext = @errorstart + ' - Location: ' + @prodloc + ' is not a valid, active IN Location.'
				exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
       			if @rcode <> 0 
					begin 
						goto bspexit
					end
				goto INPBbatch_cursor_loop
        	end
    	-- check for cost method and inventory GL acct overrides based on production location and category
    	select @loinvglacct = null, @lovalprodglacct = null, @loprodqtyglacct = null
   		select @loinvglacct = InvGLAcct, @lovalprodglacct = ValProdGLAcct, @loprodqtyglacct = ProdQtyGLAcct
    	from bINLO
   		where INCo = @inco and Loc = @prodloc and MatlGroup = @matlgroup and Category = @matlcategory
   
   		-- GL Accounts based on Production Location
    	select @matlinvglacct = isnull(@loinvglacct,@lminvglacct)   -- Inventory
    	select @valprodglacct = isnull(@lovalprodglacct,@lmvalprodglacct)   -- Value of Prod
    	select @prodqtyglacct = isnull(@loprodqtyglacct,@lmprodqtyglacct)   -- Prod Qty
    
   		-- validate Finished Material at Production Location
    	select @prodglunits = GLProdUnits   -- flag to update produced units to GL
    	from bINMT
    	where INCo = @inco and Loc = @prodloc and MatlGroup = @matlgroup and Material = @finmatl
   		and Active = 'Y'
    	if @@rowcount = 0
           begin
			   select @errortext = @errorstart + ' - Material: ' + @finmatl + ' - is not a valid, active material at Location: ' + @prodloc
				exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
       			if @rcode <> 0 
					begin
						goto bspexit
					end
				goto INPBbatch_cursor_loop
           end
       -- validate ECM
       if @ecm not in ('E','C','M')
           begin
				select @errortext = @errorstart + ' - Invalid ECM on Finished Material Unit Cost, must be ''E'', ''C'' or ''M''.'
				exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
       			if @rcode <> 0 
					begin 
						goto bspexit
					end
				goto INPBbatch_cursor_loop
       		end
       -- validate Finished Material UM
       if @um <> @stdum
           begin
				select @errortext = @errorstart + ' - Invalid U/M on Finished Material, must equal its Std U/M assigned in HQ Materials.'
				exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0
					begin
						 goto bspexit
					end
           end
   
       -- create a cursor to validate Components
       declare INPDbatch_cursor cursor for
   	   select ProdSeq, CompLoc, MatlGroup, CompMatl, UM, Units, UnitCost, ECM, UnitPrice, PECM
       from bINPD
       where Co = @inco and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
   
       open INPDbatch_cursor
   	   select @openinpd = 1
   
       INPDbatch_cursor_loop:               -- loop through all the components
   		fetch next from INPDbatch_cursor into
               @prodseq, @comploc, @compmatlgroup, @compmatl, @compum, @compunits, @compunitcost,
               @compecm, @compunitprice, @comppecm
   		
   		-- component unit cost used to relieve IN at source location regardless of cost method
   		-- component unit price used to record purchase at prod location - applies to sales only
   
           if @@fetch_status <> 0 goto INPDbatch_cursor_end
   				
   		-- make sure Finished Material not used as Component w/in this Bill of Materials
           if @finmatl = @compmatl and @prodloc=@comploc
    			begin
			    	select @errortext = @errorstart + ' - Finished Material is not allowed as a Component within its own Bill of Materials at the same location.'
					exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
       				if @rcode <> 0 
						begin
							 goto bspexit
						end
					goto INPDbatch_cursor_loop
       			end
   		-- validate Component Material - get Category and Std U/M for later use
   		select @compcategory = Category, @compstdum = StdUM
        from bHQMT
        where MatlGroup = @compmatlgroup and Material = @compmatl and Active = 'Y'
        if @@rowcount = 0
           	begin
               select @errortext = @errorstart + ' - Component: ' + @compmatl + ' is not a valid, active HQ Material.'
               exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
       		    if @rcode <> 0
						begin
							 goto bspexit
						end
				goto INPDbatch_cursor_loop
       		end
   		-- validate Component Source Location - get GL Accounts
   		select @lmcostmethod = CostMethod, @lminvglacct = InvGLAcct, @lmcostglacct = CostGLAcct,
   		@lmcostprodglacct = CostProdGLAcct, @lmcompinvsalesglacct = InvSalesGLAcct, @lmcompinvqtyglacct = InvQtyGLAcct
        from bINLM
   		where INCo = @inco and Loc = @comploc and Active = 'Y'
        if @@rowcount = 0
           	begin
		    	select @errortext = @errorstart + ' - Component Location: ' + @comploc + ' is not a valid, active IN Location.'
                exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
       		    if @rcode <> 0 
					begin
						goto bspexit
					end
				goto INPDbatch_cursor_loop
            end
        -- check for cost method and inventory GL acct overrides based on source location and category
        select @locostmethod = null, @loinvglacct = null, @locostglacct = null, @locostprodglacct = null
        select @locostmethod = CostMethod, @loinvglacct = InvGLAcct, @locostglacct = CostGLAcct, @locostprodglacct = CostProdGLAcct
        from bINLO
   		where INCo = @inco and Loc = @comploc and MatlGroup = @compmatlgroup and Category = @compcategory
    	-- check for sales accounts overrides based on source location, company, and category
   		select @lccompinvsalesglacct = null,@lccompinvqtyglacct=null
   		select @lccompinvsalesglacct = InvSalesGLAcct, @lccompinvqtyglacct = InvQtyGLAcct
        from bINLC
   		where INCo = @inco and Loc = @comploc and Co = @inco and MatlGroup = @compmatlgroup and Category = @compcategory
   
        	select @compcostmethod = @incocostmethod    -- company default
        	if isnull(@lmcostmethod,0) <> 0 
					begin
						select @compcostmethod = @lmcostmethod  -- override by location
					end
        	if isnull(@locostmethod,0) <> 0 
					begin
						select @compcostmethod = @locostmethod  -- override by location / category
					end
    				
   		-- GL Accounts for Component at Source Location
       	select @compinvglacct = isnull(@loinvglacct,@lminvglacct)   -- Inventory 
       	select @costglacct = isnull(@locostglacct,@lmcostglacct)   -- Cost of Sales
   		select @compinvsalesglacct = isnull(@lccompinvsalesglacct,@lmcompinvsalesglacct)	-- Sales to Inventory 
   		select @compinvqtyglacct = isnull(@lccompinvqtyglacct,@lmcompinvqtyglacct)		-- Qty Sales to Inventory
    
   		-- make sure Posted U/M equals Component's Std U/M          		
         if @compum <> @compstdum
               begin
			       select @errortext = @errorstart + ' - Posted U/M must match Std U/M assigned in HQ Material for Component: ' + @compmatl
				   exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
				   if @rcode <> 0 
						begin
							goto bspexit
						end
   				end
   
   		-- validate Component at Source Location 
       	select @compglunits = GLSaleUnits   -- flag to update sales units to GL
       	from bINMT
       	where INCo = @inco and Loc = @comploc and MatlGroup = @compmatlgroup
   		and Material = @compmatl and Active = 'Y'
       	if @@rowcount = 0
            	begin
		           select @errortext = @errorstart + ' - Component Material: ' + @compmatl + ' is not a valid, active material setup at the Source Location.'
			       exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
       			   if @rcode <> 0 
						begin
							goto bspexit
						end
				   goto INPDbatch_cursor_loop
            	end
     
   		-- set production values equal to compomnent - used when component and production locations are the same
        	select @prodinvglacct = @compinvglacct
   
   		-- additional validation and info needed if Source and Production Locations are different
        	if @comploc <> @prodloc
            	begin
            		select @lmcostmethod = CostMethod, @lminvglacct = InvGLAcct, @lmcostvarglacct = CostVarGLAcct,
                	@lmcostprodglacct = CostProdGLAcct  -- Cost of Prod based on Component and Prod Location
            		from bINLM
   					where INCo = @inco and Loc = @prodloc
            		if @@rowcount = 0
            			begin
            				select @rcode = 1   -- Prod Location already validated
      	    				goto bspexit
            			end
            		-- check for cost method and gl account overrides based on Prod Location and Component category
            		select @locostmethod = null, @loinvglacct = null, @locostvarglacct = null, @locostprodglacct = null
            		select @locostmethod = CostMethod, @loinvglacct = InvGLAcct, @locostvarglacct = CostVarGLAcct,
                	@locostprodglacct = CostProdGLAcct  -- cost of prod override
            		from bINLO
   					where INCo = @inco and Loc = @prodloc and MatlGroup = @matlgroup and Category = @compcategory
   					select @prodcostmethod = @incocostmethod    -- company default
            		if isnull(@lmcostmethod,0) <> 0 
							begin
								select @prodcostmethod = @lmcostmethod  -- override by location
							end
            		if isnull(@locostmethod,0) <> 0 
							begin 
								select @prodcostmethod = @locostmethod  -- override by location / category
							end
    					
   					-- GL Accounts for Component at Production Location
            		select @prodinvglacct = isnull(@loinvglacct,@lminvglacct)   -- Inventory
            		select @costvarglacct = isnull(@locostvarglacct,@lmcostvarglacct)   -- Cost Variance
    
            		-- validate Component at Prod Location - get default unit cost 
            		select @produnitcost = case @prodcostmethod when 1 then AvgCost when 2 then LastCost else StdCost end,
					@prodecm = case @prodcostmethod when 1 then AvgECM when 2 then LastECM else StdECM end
					from bINMT
					where INCo = @inco and Loc = @prodloc and MatlGroup = @matlgroup
   					and Material = @compmatl and Active = 'Y'
            		if @@rowcount = 0
                		begin
                			select @errortext = @errorstart + ' - Invalid Component: ' + @compmatl + ', must be active at Location ' + @prodloc
                			exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
      	        			if @rcode <> 0 
								begin 
									goto bspexit
								end
   							goto INPDbatch_cursor_loop
                		end
            	end
   				
   		-- Load GL Distributions
         if @prodloc <> @comploc and @usageopt = 'T'     -- Transfer Component to Prod Location before production
           	begin
               -- 'transfer out' at source location -- use cost value from component detail
               select @factor = case @compecm when 'C' then 100 when 'M' then 1000 else 1 end
               select @totalcost = (@compunits * @compunitcost) / @factor	
   			-- validate Component Inventory GL Account at Source Location
               exec @rcode = bspGLACfPostable @glco, @compinvglacct, 'I', @errmsg output
               if @rcode <> 0
	               	begin
		               select @errortext = @errorstart + ' - Inventory Account for Component: ' + @compmatl + ' at Location: ' + @comploc + char(13) + @errmsg
			           exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
       			       if @rcode <> 0 
								begin 
									goto bspexit
								end
						goto INPDbatch_cursor_loop
      	            end
               -- Credit Component Inventory at Source Location
               update bINPG set Amount = Amount - @totalcost
               where INCo = @inco and Mth = @mth and BatchId = @batchid and GLCo = @glco
               and GLAcct = @compinvglacct and BatchSeq = @batchseq and ProdSeq = @prodseq
               if @@rowcount = 0
				   begin
               			insert bINPG (INCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, ProdSeq, Loc, MatlGroup, Material,Description, Amount)
						values (@inco, @mth, @batchid, @glco, @compinvglacct, @batchseq, @prodseq, @comploc, @compmatlgroup, @compmatl,
		                @description, -@totalcost)
					end
   
	   			-- 'transfer in' at production location - use posted cost unless production location using Std Cost Method
   			 select @stdtotalcost = @totalcost
   			 if @prodcostmethod = 3  -- Std Cost, debit Inventory at standard cost, debit difference to Cost Variance
                   begin
				      select @factor = case @prodecm when 'C' then 100 when 'M' then 1000 else 1 end
					   select @stdtotalcost = (@compunits * @produnitcost) / @factor
   					end
   			-- validate Component Inventory GL Account at Production Location
   			exec @rcode = bspGLACfPostable @glco, @prodinvglacct, 'I', @errmsg output
               if @rcode <> 0
               	begin
				       select @errortext = @errorstart + ' - Inventory Account for Component: ' + @compmatl + ' at Location ' + @prodloc + char(13) + @errmsg
					   exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
       					if @rcode <> 0
								begin
									goto bspexit
								end
						 goto INPDbatch_cursor_loop
      	          end
   			-- Debit Component Inventory at Production Location
    		update bINPG set Amount = Amount + @stdtotalcost
            where INCo = @inco and Mth = @mth and BatchId = @batchid and GLCo = @glco
            and GLAcct = @prodinvglacct and BatchSeq = @batchseq and ProdSeq = @prodseq
            if @@rowcount = 0
			   begin
					insert bINPG (INCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, ProdSeq, Loc, MatlGroup, Material,Description, Amount)
					values (@inco, @mth, @batchid, @glco, @prodinvglacct, @batchseq, @prodseq, @prodloc, @compmatlgroup, @compmatl,
					@description, @stdtotalcost)
			  end
   
   			-- Cost Variance only needed if using Std Unit Cost at Prod Location and posted cost differs from standard cost
            if @totalcost - @stdtotalcost <> 0
              	begin
					   -- validate Production Location Cost Variance Account 
					  exec @rcode = bspGLACfPostable @glco, @costvarglacct, 'I', @errmsg output
				       if @rcode <> 0
						   	begin
							select @errortext = @errorstart + ' - Cost Variance Account for Component: ' + @compmatl + ' at Location ' + @prodloc + char(13) + @errmsg
							exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
       						if @rcode <> 0 
								begin 
									goto bspexit
								end
							goto INPDbatch_cursor_loop
       	          end
                  -- Debit/Credit Component Cost Variance at Production Location 
                  update bINPG set Amount = Amount + (@totalcost - @stdtotalcost)
                  where INCo = @inco and Mth = @mth and BatchId = @batchid and GLCo = @glco
                  and GLAcct = @costvarglacct and BatchSeq = @batchseq and ProdSeq = @prodseq
                   if @@rowcount = 0
					  begin
							insert bINPG (INCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, ProdSeq, Loc, MatlGroup,
							Material, Description, Amount)
							values (@inco, @mth, @batchid, @glco, @costvarglacct, @batchseq, @prodseq, @prodloc, @compmatlgroup,
                           @compmatl, @description, @totalcost - @stdtotalcost)
						end
                   end 
   			end    -- 'Transfer' end
   
   		if @prodloc <> @comploc and @usageopt = 'S'  -- Sell Component to Prod Location before production
           	begin
   			-- 'sale' from Source Location -- use posted cost to relieve Component Inventory
               select @factor = case @compecm when 'C' then 100 when 'M' then 1000 else 1 end
               select @totalcost = (@compunits * @compunitcost) / @factor	
   			-- validate Component Inventory GL Account at Source Location
               exec @rcode = bspGLACfPostable @glco, @compinvglacct, 'I', @errmsg output
               if @rcode <> 0
               	begin
                   select @errortext = @errorstart + ' - Inventory Account for Component: ' + @compmatl + ' at Location: ' + @comploc + char(13) + @errmsg
                   exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
       	        if @rcode <> 0 goto bspexit
                   goto INPDbatch_cursor_loop
      	            end
               -- Credit Component Inventory at Source Location
               update bINPG set Amount = Amount - @totalcost
               where INCo = @inco and Mth = @mth and BatchId = @batchid and GLCo = @glco
               	and GLAcct = @compinvglacct and BatchSeq = @batchseq and ProdSeq = @prodseq
               if @@rowcount = 0
               	insert bINPG (INCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, ProdSeq, Loc, MatlGroup, Material,
                   	Description, Amount)
                   values (@inco, @mth, @batchid, @glco, @compinvglacct, @batchseq, @prodseq, @comploc, @compmatlgroup, @compmatl,
                       @description, -@totalcost)
   			-- validate Cost of Sales GL Account at Source Location
               exec @rcode = bspGLACfPostable @glco, @costglacct, 'I', @errmsg output
               if @rcode <> 0
               	begin
                   select @errortext = @errorstart + ' - Cost of Sales Account for Component: ' + @compmatl + ' at Location: ' + @comploc + char(13) + @errmsg
                   exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
       	        if @rcode <> 0 goto bspexit
                   goto INPDbatch_cursor_loop
      	            end
               -- Debit Cost of Sales at Source Location
               update bINPG set Amount = Amount + @totalcost
               where INCo = @inco and Mth = @mth and BatchId = @batchid and GLCo = @glco
               	and GLAcct = @costglacct and BatchSeq = @batchseq and ProdSeq = @prodseq
               if @@rowcount = 0
               	insert bINPG (INCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, ProdSeq, Loc, MatlGroup, Material,
                   	Description, Amount)
                   values (@inco, @mth, @batchid, @glco, @costglacct, @batchseq, @prodseq, @comploc, @compmatlgroup, @compmatl,
                       @description, @totalcost)
   
   			-- 'sale' from Source Location - use posted price for revenue
   			select @factor = case @comppecm when 'C' then 100 when 'M' then 1000 else 1 end
               select @totalprice = (@compunits * @compunitprice) / @factor
  
   			-- validate Sales to Inventory GL Account at Source Location
              	exec @rcode = bspGLACfPostable @glco, @compinvsalesglacct, 'I', @errmsg output
              	if @rcode <> 0
   				begin
                   select @errortext = @errorstart + ' - Sales to Inventory Account for Component: ' + @compmatl + ' at Location: ' + @comploc + char(13) + @errmsg
                   exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
       	        if @rcode <> 0 goto bspexit
                   goto INPDbatch_cursor_loop
      	            end
   			-- Credit Sales to Inventory from Source Location
               update bINPG set Amount = Amount - @totalprice
               where INCo = @inco and Mth = @mth and BatchId = @batchid and GLCo = @glco
               	and GLAcct = @compinvsalesglacct and BatchSeq = @batchseq and ProdSeq = @prodseq
               if @@rowcount = 0
               	insert bINPG (INCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, ProdSeq, Loc, MatlGroup, Material,
                   	Description, Amount)
                   values (@inco, @mth, @batchid, @glco, @compinvsalesglacct, @batchseq, @prodseq, @comploc, @compmatlgroup, @compmatl,
                       @description, -@totalprice)
   
   			-- 'sale' to Prod Location - use posted price unless Prod Location using Std Cost Method
   			select @stdtotalcost = @totalprice
   			if @prodcostmethod = 3  -- Std Cost, debit Inventory at standard cost, debit difference to Cost Variance
                   begin
                   select @factor = case @prodecm when 'C' then 100 when 'M' then 1000 else 1 end
                   select @stdtotalcost = (@compunits * @produnitcost) / @factor
   				end
   
   			-- validate Component Inventory GL Account at Production Location
   			exec @rcode = bspGLACfPostable @glco, @prodinvglacct, 'I', @errmsg output
               if @rcode <> 0
               	begin
                   select @errortext = @errorstart + ' - Inventory Account for Component: ' + @compmatl + ' at Location ' + @prodloc + char(13) + @errmsg
                   exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
       	        if @rcode <> 0 goto bspexit
                   goto INPDbatch_cursor_loop
      	            end
   			-- Debit Component Inventory at Production Location
    			update bINPG set Amount = Amount + @stdtotalcost
               where INCo = @inco and Mth = @mth and BatchId = @batchid and GLCo = @glco
               	and GLAcct = @prodinvglacct and BatchSeq = @batchseq and ProdSeq = @prodseq
               if @@rowcount = 0
               insert bINPG (INCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, ProdSeq, Loc, MatlGroup, Material,
                   Description, Amount)
               values (@inco, @mth, @batchid, @glco, @prodinvglacct, @batchseq, @prodseq, @prodloc, @compmatlgroup, @compmatl,
               	@description, @stdtotalcost)
   
   			-- Cost Variance only needed if using Std Unit Cost at Prod Location and posted cost differs from standard cost
               if @totalprice - @stdtotalcost <> 0
               	begin
                   -- validate Production Location Cost Variance Account 
                   exec @rcode = bspGLACfPostable @glco, @costvarglacct, 'I', @errmsg output
                   if @rcode <> 0
                   	begin
                       select @errortext = @errorstart + ' - Cost Variance Account for Component: ' + @compmatl + ' at Location ' + @prodloc + char(13) + @errmsg
                       exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
       	            if @rcode <> 0 goto bspexit
                       goto INPDbatch_cursor_loop
       	            end
                   -- Debit/Credit Component Cost Variance at Production Location 
                   update bINPG set Amount = Amount + (@totalprice - @stdtotalcost)
                   where INCo = @inco and Mth = @mth and BatchId = @batchid and GLCo = @glco
                   	and GLAcct = @costvarglacct and BatchSeq = @batchseq and ProdSeq = @prodseq
                   if @@rowcount = 0
                       insert bINPG (INCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, ProdSeq, Loc, MatlGroup,
                       	Material, Description, Amount)
                       values (@inco, @mth, @batchid, @glco, @costvarglacct, @batchseq, @prodseq, @prodloc, @compmatlgroup,
                           @compmatl, @description, @totalprice - @stdtotalcost)
                   end
   
   			-- Qty Sold --
   			if @compglunits = 'Y' and @compinvqtyglacct is not null
                   begin
                   -- validate Qty Sold to Inventory GL Account
                   exec @rcode = bspGLACQtyVal @glco, @compinvqtyglacct, @errmsg output
                   if @rcode <> 0
                       begin
                       select @errortext = @errorstart + ' - Qty Sold to Inventory Account for Component: ' + @compmatl + ' at Location ' + @comploc + char(13) + @errmsg
                       exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
       	            if @rcode <> 0 goto bspexit
                       goto INPDbatch_cursor_loop
      	                end
                   -- add Qty Sold to Inventory GL Distribution for Component at Source Location 
                   update bINPG set Amount = Amount - @compunits
                   where INCo = @inco and Mth = @mth and BatchId = @batchid and GLCo = @glco
                   	and GLAcct = @compinvqtyglacct and BatchSeq = @batchseq and ProdSeq = @prodseq
                   if @@rowcount = 0
                       insert bINPG (INCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, ProdSeq, Loc, MatlGroup, Material,
                           Description, Amount)
                       values (@inco, @mth, @batchid, @glco, @compinvqtyglacct, @batchseq, @prodseq, @comploc, @compmatlgroup, @compmatl,
                           @description, -@compunits)
                   end 
   			end    -- 'Sale' end
                 
   		-- finished transfering/selling Components to Prod Location, generate Usage and Cost of Prod entries
   		
   		-- use posted cost if Source and Prod Locations are equal
   		select @factor = case @compecm when 'C' then 100 when 'M' then 1000 else 1 end
           select @totalcost = (@compunits * @compunitcost) / @factor	
   		if @prodloc <> @comploc		-- use cost method and current costs to determine 'usage' value         
   			begin
   			select @factor = case @prodecm when 'C' then 100 when 'M' then 1000 else 1 end
               select @totalcost = (@compunits * @produnitcost) / @factor
   			end
   		-- validate Inventory Account for Component at Production Location
           exec @rcode = bspGLACfPostable @glco, @prodinvglacct, 'I', @errmsg output
           if @rcode <> 0
               begin
               select @errortext = @errorstart + ' - Inventory Account for Component: ' + @compmatl + ' at Location ' + @prodloc + char(13) + @errmsg
               exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
       	    if @rcode <> 0 goto bspexit
               goto INPDbatch_cursor_loop
      	        end
           -- Credit Production Location Inventory for Component (usage)
           update bINPG set Amount = Amount - @totalcost
           where INCo = @inco and Mth = @mth and BatchId = @batchid and GLCo = @glco
           	and GLAcct = @prodinvglacct and BatchSeq = @batchseq and ProdSeq = @prodseq
           if @@rowcount = 0
 
           	insert bINPG (INCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, ProdSeq, Loc, MatlGroup, Material,
               	Description, Amount)
               values (@inco, @mth, @batchid, @glco, @prodinvglacct, @batchseq, @prodseq, @prodloc, @compmatlgroup, @compmatl,
                   @description, -@totalcost)
   		-- validate Cost of Prod GL Account, based on production location and component
   		select @costprodglacct = isnull(@locostprodglacct,@lmcostprodglacct) -- default in bINLM with override in bIMLO
           exec @rcode = bspGLACfPostable @glco, @costprodglacct, 'I', @errmsg output
           if @rcode <> 0
               begin
               select @errortext = @errorstart + ' - Cost of Production Account for Component: ' + @compmatl + ' at Location ' + @prodloc + char(13) + @errmsg
               exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
       	    if @rcode <> 0 goto bspexit
               goto INPDbatch_cursor_loop
      	        end
           -- Debit Cost of Production Location Inventory for Component (usage)
           update bINPG set Amount = Amount + @totalcost
           where INCo = @inco and Mth = @mth and BatchId = @batchid and GLCo = @glco
           	and GLAcct = @costprodglacct and BatchSeq = @batchseq and ProdSeq = @prodseq
           if @@rowcount = 0
           	insert bINPG (INCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, ProdSeq, Loc, MatlGroup, Material,
               	Description, Amount)
               values (@inco, @mth, @batchid, @glco, @costprodglacct, @batchseq, @prodseq, @prodloc, @compmatlgroup, @compmatl,
                   @description, @totalcost)
   
   		goto INPDbatch_cursor_loop  -- get next Component
   
   	INPDbatch_cursor_end:	-- finished with Components
           close INPDbatch_cursor
           deallocate INPDbatch_cursor
           select @openinpd = 0
   
    	-- finished with Components, generate production entries for Finished material
   	
   	-- use posted costs for Finished Material as Inventory value
       select @factor = case @ecm when 'C' then 100 when 'M' then 1000 else 1 end
       select @totalcost = (@produnits  * @unitcost) / @factor
   
       -- validate Inventory Account for Finished Material at Prod Location
       exec @rcode = bspGLACfPostable @glco, @matlinvglacct, 'I', @errmsg output
       if @rcode <> 0
   		begin
         	select @errortext = @errorstart + ' - Inventory Account for Material: ' + @finmatl + ' at Location ' + @prodloc + char(13) + @errmsg
           exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
       	if @rcode <> 0 goto bspexit
           goto INPBbatch_cursor_loop
      	    end
       -- Debit Finished Material Inventory at Production Location 
       update bINPG set Amount = Amount + @totalcost
       where INCo = @inco and Mth = @mth and BatchId = @batchid and GLCo = @glco
       	and GLAcct = @matlinvglacct and BatchSeq = @batchseq and ProdSeq = 0
       if @@rowcount = 0
           insert bINPG (INCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, ProdSeq, Loc, MatlGroup, Material,
           	Description, Amount)
   		values (@inco, @mth, @batchid, @glco, @matlinvglacct, @batchseq, 0, @prodloc, @matlgroup, @finmatl,
               @description, @totalcost)
   
   	-- validate Value of Production Account for Finished Material at Prod Location
       exec @rcode = bspGLACfPostable @glco, @valprodglacct, 'I', @errmsg output
   	if @rcode <> 0
       	begin
           select @errortext = @errorstart + ' - Value of Prod Account for Material: ' + @finmatl + ' at Location ' + @prodloc + char(13) + @errmsg
           exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
       	if @rcode <> 0 goto bspexit
   		goto INPBbatch_cursor_loop
      	    end
   	-- Credit Value of Production for Finished Material at Prod Location
       update bINPG set Amount = Amount - @totalcost
       where INCo = @inco and Mth = @mth and BatchId = @batchid and GLCo = @glco
       	and GLAcct = @valprodglacct and BatchSeq = @batchseq and ProdSeq = 0
       if @@rowcount = 0
       	insert bINPG (INCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, ProdSeq, Loc, MatlGroup, Material,
           	Description, Amount)
           values (@inco, @mth, @batchid, @glco, @valprodglacct, @batchseq, 0, @prodloc, @matlgroup, @finmatl,
               @description, -@totalcost)
   
   	if @prodglunits = 'Y' and @prodqtyglacct is not null  --if finished good flagged for unit update
       	begin
           -- validate Production Quantity GL Account
           exec @rcode = bspGLACQtyVal @glco, @prodqtyglacct, @errmsg output
           if @rcode <> 0
           	begin
               select @errortext = @errorstart + ' - Production Qty Account for Material: ' + @finmatl + ' at Location ' + @prodloc + char(13) + @errmsg
               exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
       	    if @rcode <> 0 goto bspexit
               goto INPBbatch_cursor_loop
      	        end
   		-- Debit Production Qty Account for Finished Material
           update bINPG set Amount = Amount + @produnits
           where INCo = @inco and Mth = @mth and BatchId = @batchid and GLCo = @glco
           	and GLAcct = @prodqtyglacct and BatchSeq = @batchseq and ProdSeq = 0
           if @@rowcount = 0
               insert bINPG (INCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, ProdSeq, Loc, MatlGroup, Material,
               	Description, Amount)
               values (@inco, @mth, @batchid, @glco, @prodqtyglacct, @batchseq, 0, @prodloc, @matlgroup, @finmatl,
                   @description, @produnits)
           end   -- end of production units update to GL
   
   	goto INPBbatch_cursor_loop      -- get next Production entry
   
   INPBbatch_cursor_end:	-- finished validating all batch entries
   	close INPBbatch_cursor
       deallocate INPBbatch_cursor
       select @openinpb = 0
   
   -- make sure debits and credits balance
   select @glco = i.GLCo
   from bINPG i
   join bGLAC g on i.GLCo=g.GLCo and i.GLAcct=g.GLAcct 
   where i.INCo = @inco and i.Mth = @mth and i.BatchId = @batchid
   	and g.AcctType <> 'M'    -- exclude Memo Accounts used for production quantity
   group by i.GLCo
   having isnull(sum(Amount),0) <> 0
   if @@rowcount <> 0
   		begin
			select @errortext =  'GL Company ' + convert(varchar(3), @glco) + ' entries do not balance!'
			exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 
				begin
					goto bspexit
				end
       end
   
   --check HQ Batch Errors and update HQ Batch Control status
   select @status = 3	-- valid - ok to post
   if exists(select * from bHQBE where Co = @inco and Mth = @mth and BatchId = @batchid)
		begin
    		select @status = 2	-- validation errors
		end
   
   update bHQBC
   set Status = @status
   where Co = @inco and Mth = @mth and BatchId = @batchid
   if @@rowcount <> 1
       begin
    		select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
    		goto bspexit
    	end
   
   bspexit:
   	if @openinpd = 1
   		begin
          	close INPDbatch_cursor
          	deallocate INPDbatch_cursor
          end
       if @openinpb = 1
   		begin
          	close INPBbatch_cursor
          	deallocate INPBbatch_cursor
          end
   
--       if @rcode<>0 
--			begin
--				select @errmsg
--			end
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINPBVal] TO [public]
GO
