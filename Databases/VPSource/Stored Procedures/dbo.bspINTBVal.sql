SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspINTBVal]
/*****************************************************************************
* Created: GR 02/23/00
* Modified: GG 03/09/00 - cleanup
*           ae 5/12/00 - added: if @incovalmethod = 4  --only do this if valuation method is standard.
*           GR 6/8/00 - not required the valuation method in IN Company to be std cost, so removed it
*           DANF 08/21/00 - Changed stdtotalcost to bDollar
*           TerryL 06/25/07 - Issue 122475, create validation error when unitcost * units <> total Cost
*			GP 6/29/10 - Issue 140222, added round to 4 decimals when validating total cost
*
* USAGE:
* Validates each entry in bINTB for a selected batch - must be called
* prior to posting the batch.
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
   
    declare @batchseq int, @fromloc bLoc, @toloc bLoc, @matlgroup bGroup, @material bMatl,
    @actdate bDate, @description bDesc, @glco bCompany, @glacct bGLAcct, @um bUM, @units bUnits,
    @unitcost bUnitCost, @ecm bECM, @totalcost bDollar, @jrnl bJrnl, @active bYN, @inlocostmethod tinyint,
    @tolminvglacct bGLAcct, @tolmcostvarglacct bGLAcct, @incocostmethod tinyint,
    @tolmcostmethod tinyint, @incovalmethod tinyint
   
    declare @costvarglacct bGLAcct, @factor int, @stdunitcost bUnitCost, @stdtotalcost bDollar,
    @category varchar(10), @invglacct bGLAcct, @stdecm bECM, @costmethod tinyint, @fromlminvglacct bGLAcct
   
    declare @rcode int, @openintb int, @errorstart varchar(60), @errortext varchar(255), @status int, @stdum bUM
   
    select @rcode = 0, @openintb = 0
   
    if @inco is null
        begin
        select @errmsg='Missing IN Company', @rcode=1
        goto bspexit
        end
   
    if @mth is null
        begin
        select @errmsg='Missing Month', @rcode=1
        goto bspexit
        end
   
    if @batchid is null
        begin
        select @errmsg='Missing BatchId', @rcode=1
        goto bspexit
        end
   
    --validate HQ Batch
    exec @rcode = bspHQBatchProcessVal @inco, @mth, @batchid, 'IN Trnsfr', 'INTB', @errmsg output, @status output
    if @rcode <> 0 goto bspexit
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
    delete bINTG where INCo = @inco and Mth = @mth and BatchId = @batchid
   
    --get default info from IN Company
    select @glco = GLCo, @jrnl = Jrnl, @incocostmethod = CostMethod, @incovalmethod = ValMethod
    from bINCO
    where INCo = @inco
    if @@rowcount = 0
        begin
        select @errmsg = 'Invalid IN Company #!', @rcode = 1
        goto bspexit
        end
    -- validate GL Journal
    if not exists(select * from bGLJR where GLCo = @glco and Jrnl = @jrnl)
        begin
        select @errmsg = @jrnl + ' is an invalid GL Journal.', @rcode = 1
        goto bspexit
        end
    -- validate Month
    exec @rcode = bspHQBatchMonthVal @glco, @mth, 'IN', @errmsg output
    if @rcode <> 0 goto bspexit
   
    -- create a cursor to process each row in batch
    declare INTBbatch_cursor cursor for
    select BatchSeq, FromLoc, ToLoc, MatlGroup, Material, ActDate, Description, UM, Units,
        UnitCost, ECM, TotalCost
    from bINTB

    where Co = @inco and Mth = @mth and BatchId = @batchid
   
    open INTBbatch_cursor            --open the cursor
    select @openintb = 1
   
    INTBbatch_cursor_loop:                  --loop through all the records
        fetch next from INTBbatch_cursor into
            @batchseq, @fromloc, @toloc, @matlgroup, @material, @actdate, @description, @um, @units,
            @unitcost, @ecm, @totalcost
   
       if @@fetch_status = 0
            begin
            select @errorstart = 'Seq#: ' + convert(varchar(6),@batchseq)
   
            --validate 'from' location
            select @active = Active, @fromlminvglacct = InvGLAcct
            from bINLM
        where INCo = @inco and Loc = @fromloc
            if @@rowcount = 0
                begin
                select @errortext = @errorstart + ' - Not a valid (From) Location.'
                exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
       	        if @rcode <> 0 goto bspexit
                goto INTBbatch_cursor_loop
       	        end
            if @active = 'N'
                begin
                select @errortext = @errorstart + ' - (From) Location is not active.'
                exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
       	        if @rcode <> 0 goto bspexit
                goto INTBbatch_cursor_loop
       	        end
   
            --validate 'to' location
            select @active = Active, @tolmcostmethod = CostMethod, @tolminvglacct = InvGLAcct,
                @tolmcostvarglacct = CostVarGLAcct
            from bINLM where INCo = @inco and Loc = @toloc
            if @@rowcount = 0
                begin
                select @errortext = @errorstart + ' - Not a valid (To) Location.'
                exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
       	        if @rcode <> 0 goto bspexit
                goto INTBbatch_cursor_loop
       	        end
            if @active = 'N'
                begin
                select @errortext = @errorstart + ' - (To) Location is not active.'
                exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
       	        if @rcode <> 0 goto bspexit
                goto INTBbatch_cursor_loop
       	        end
   
            if @toloc = @fromloc
                begin
                select @errortext = @errorstart + ' - (From) and (To) Locations cannot be equal.'
                exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
       	        if @rcode <> 0 goto bspexit
                goto INTBbatch_cursor_loop
       	        end
   
            --validate Material
            select @category = Category, @stdum = StdUM
            from bHQMT
            where MatlGroup = @matlgroup and Material = @material
            if @@rowcount = 0
                begin
                select @errortext = @errorstart + ' - Material not setup in HQ Materials.'
                exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
                if @rcode <> 0 goto bspexit
                goto INTBbatch_cursor_loop
                end
            if @stdum <> @um
                begin
                select @errortext = @errorstart + ' - Invalid U/M, must use the material standard U/M.'
                exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
                if @rcode <> 0 goto bspexit
                goto INTBbatch_cursor_loop
                end
   
            -- validate material at 'from' location
            select @active = Active
            from bINMT
            where INCo = @inco and Loc = @fromloc and MatlGroup = @matlgroup and Material = @material
            if @@rowcount = 0
                begin
                select @errortext = @errorstart + ' - Material not setup at the (From) Location.'
                exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
       	        if @rcode <> 0 goto bspexit
                goto INTBbatch_cursor_loop
       	        end
            if @active = 'N'
                begin
                select @errortext = @errorstart + ' - Material is inactive at (From) Location.'
                exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
                if @rcode <> 0 goto bspexit
                goto INTBbatch_cursor_loop
                end
   
            -- validate material at 'to' location
            select @active = Active, @stdunitcost = StdCost, @stdecm = StdECM
            from bINMT
            where INCo = @inco and Loc = @toloc and MatlGroup = @matlgroup and Material = @material
            if @@rowcount = 0
                begin
                select @errortext = @errorstart + ' - Material not setup at the (To) Location.'
                exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
       	        if @rcode <> 0 goto bspexit
                goto INTBbatch_cursor_loop
       	        end
            if @active = 'N'
                begin
                select @errortext = @errorstart + ' - Material is inactive at (To) Location.'
                exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
                if @rcode <> 0 goto bspexit
                goto INTBbatch_cursor_loop
                end
   
            -- validate Unit Cost
            if @unitcost < 0
                begin
                select @errortext = @errorstart + ' - Unit Cost must be greater or equal than 0.00.'
                exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
       	        if @rcode <> 0 goto bspexit
                goto INTBbatch_cursor_loop
       	        end
			
			-- Issue 122475, 140222 (added rounding to 4 decimals, then 2 due to lost precision and approximation)  	        
			-- validate that unit cost * units = total cost
			select @factor = case @ecm when 'C' then 100 when 'M' then 1000 else 1 end
			if Round(Round((@unitcost * @units) / @factor, 4), 2) <>  @totalcost
				begin
				select @errortext = @errorstart + ' - Unit Cost * Units does not equal Total Cost'
				exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
   				if @rcode <> 0 goto bspexit
				goto INTBbatch_cursor_loop
   				end       	        

            --validate ECM
            if @ecm not in ('E', 'C', 'M')
                begin
                select @errortext = @errorstart + ' - Invalid ECM, must be (E, C, M).'
                exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
       	        if @rcode <> 0 goto bspexit
                goto INTBbatch_cursor_loop
       	        end
   
    --Load GL Distributions
   
            -- get Inventory GL Account for 'To' Location
            -- check for Category override
            select @inlocostmethod = null, @invglacct = null, @costvarglacct = null
            select @inlocostmethod = CostMethod, @invglacct = InvGLAcct, @costvarglacct = CostVarGLAcct
            from bINLO
            where INCo = @inco and Loc = @toloc and MatlGroup = @matlgroup and Category = @category
   
            if @invglacct is null select @invglacct = @tolminvglacct
            if @costvarglacct is null select @costvarglacct = @tolmcostvarglacct
   
            --validate Inventory GL Account
            exec @rcode = bspGLACfPostable @glco, @invglacct, 'I', @errmsg output
            if @rcode <> 0
                begin
                select @errortext = @errorstart + ' - ' + @errmsg
                exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
       	        if @rcode <> 0 goto bspexit
                goto INTBbatch_cursor_loop
      	        end
            -- check for Cost Method
   
         select @costmethod = @inlocostmethod
            if @costmethod is null or @costmethod = 0
              select @costmethod = @tolmcostmethod
            if @costmethod is null or @costmethod = 0
              select @costmethod = @incocostmethod
   
            -- use posted cost unless 'to' location using Std Cost Method
          if @costmethod = 3  -- Std Cost, debit Inventory at standard cost, debit difference to Cost Variance
                begin
                select @factor = case @stdecm when 'C' then 100 when 'M' then 1000 else 1 end
                select @stdtotalcost = (@units * @stdunitcost) / @factor
   
                -- add GL Distribution for 'To' Location Inventory
                update bINTG set Cost = Cost + @stdtotalcost
                where INCo = @inco and Mth = @mth and BatchId = @batchid and GLCo = @glco
                    and GLAcct = @invglacct and BatchSeq = @batchseq and Loc = @toloc
                if @@rowcount = 0
                    insert bINTG (INCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, Loc, MatlGroup, Material,
                        Description, ActDate, Cost)
                    values (@inco, @mth, @batchid, @glco, @invglacct, @batchseq, @toloc, @matlgroup, @material,
                   @description, @actdate, @stdtotalcost)
   
                -- Cost Variance only needed if posted cost differs from standard cost
   
                   if @totalcost - @stdtotalcost <> 0
                       begin
                       -- validate Cost Variance GL Account
                       if @costvarglacct is not null --only do this if valuation method is standard.
                           begin
                           exec @rcode = bspGLACfPostable @glco, @costvarglacct, 'I', @errmsg output
                           if @rcode <> 0
                               begin
                               select @errortext = @errorstart + ' - ' + @errmsg
                               exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
       	                    if @rcode <> 0 goto bspexit
                               goto INTBbatch_cursor_loop
       	                    end
                           -- add GL Distribution for 'To' Location Cost Variance
                           update bINTG set Cost = Cost + (@totalcost - @stdtotalcost)
                               where INCo = @inco and Mth = @mth and BatchId = @batchid and GLCo = @glco
                               and GLAcct = @costvarglacct and BatchSeq = @batchseq and Loc = @toloc
                           if @@rowcount = 0
                               insert bINTG (INCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, Loc, MatlGroup,
                                   Material, Description, ActDate, Cost)
                               values (@inco, @mth, @batchid, @glco, @costvarglacct, @batchseq, @toloc, @matlgroup,
                                   @material, @description, @actdate, @totalcost - @stdtotalcost)
                           end --@incovalmethod = 4
                      else
                           begin
                           select @errortext = 'Cost Variance GL Account is not set up for To Location!'
                           exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
       	                  if @rcode <> 0 goto bspexit
       	                end
                   end --if @totalcost - @stdtotalcost <> 0
                end  --end of stdcost
   
            else    -- if @costmethod <> 3
                begin
                -- add GL Distribution for 'To' Location Inventory using posted cost
                update bINTG set Cost = Cost + @totalcost
                where INCo = @inco and Mth = @mth and BatchId = @batchid and GLCo = @glco
                    and GLAcct = @invglacct and BatchSeq = @batchseq and Loc = @toloc
                if @@rowcount = 0
                    insert bINTG (INCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, Loc, MatlGroup, Material,
                        Description, ActDate, Cost)
                    values (@inco, @mth, @batchid, @glco, @invglacct, @batchseq, @toloc, @matlgroup, @material,
                        @description, @actdate, @totalcost)
              end
   
            -- get Inventory GL Account for 'From' Location
            -- check for Category override
            select @invglacct = null
            select @invglacct = InvGLAcct
            from bINLO
            where INCo = @inco and Loc = @fromloc and MatlGroup = @matlgroup and Category = @category
            -- if no override, use standard Inventory GL Account
            if @invglacct is null select @invglacct = @fromlminvglacct
            -- validate Inventory GL Account
            exec @rcode = bspGLACfPostable @glco, @invglacct, 'I', @errmsg output
            if @rcode <> 0
                begin
                select @errortext = @errorstart + ' - ' + @errmsg
                exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
       	        if @rcode <> 0 goto bspexit
                goto INTBbatch_cursor_loop
      	        end
   
             -- add GL Distribution for 'From' Location Inventory (credit)
             update bINTG set Cost = Cost - @totalcost
             where INCo = @inco and Mth = @mth and BatchId = @batchid and GLCo = @glco
                and GLAcct = @invglacct and BatchSeq = @batchseq and Loc = @fromloc
             if @@rowcount = 0
                insert bINTG (INCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, Loc, MatlGroup, Material,
                    Description, ActDate, Cost)
                values (@inco, @mth, @batchid, @glco, @invglacct, @batchseq, @fromloc, @matlgroup, @material,
                    @description, @actdate, -@totalcost)
   
            goto INTBbatch_cursor_loop      -- get the next seq
            end
   
    --close and deallocate cursor
    if @openintb = 1
        begin
        close INTBbatch_cursor
        deallocate INTBbatch_cursor
        select @openintb = 0
        end
   
    -- make sure debits and credits balance
    select @glco = GLCo
    from bINTG
    where INCo = @inco and Mth = @mth and BatchId = @batchid
    group by GLCo
    having isnull(sum(Cost),0) <> 0
    if @@rowcount <> 0
        begin
        select @errortext =  'GL Company ' + convert(varchar(3), @glco) + ' entries do not balance!'
        exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
        if @rcode <> 0 goto bspexit
        end
   
    --check HQ Batch Errors and update HQ Batch Control status
    select @status = 3	-- valid - ok to post
    if exists(select * from bHQBE where Co = @inco and Mth = @mth and BatchId = @batchid)
    	 select @status = 2	-- validation errors
   
    update bHQBC
    set Status = @status
    where Co = @inco and Mth = @mth and BatchId = @batchid
   
    if @@rowcount <> 1
        begin
    	select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
    	goto bspexit
    	end
   
    bspexit:
        if @openintb = 1
            begin
            close INTBbatch_cursor
            deallocate INTBbatch_cursor
            end
   
     --   if @rcode<>0 select @errmsg
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINTBVal] TO [public]
GO
