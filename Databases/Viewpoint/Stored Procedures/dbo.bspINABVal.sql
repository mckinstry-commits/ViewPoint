SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   procedure [dbo].[bspINABVal]
   /*****************************************************************************
   * Created By: GR 12/9/99
   * Modified: GG 03/01/00 - cleanup
   *	        RM 09/11/01 - #14422 - Changed so that second insert into INAG is an update if GLAccts are the same.
   *			GG 10/01/01 - #14422 - added update to bINAG for 'changed' entries
   *
   * USAGE:
   * Validates each entry in bINAB for a selected batch - must be called
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
   
   declare @batchseq int, @batchtranstype varchar(3), @intrans int, @loc bLoc, @matlgroup bGroup,
       @material bMatl, @actdate bDate, @description bDesc, @glco bCompany,
       @glacct bGLAcct, @um bUM, @units bUnits, @unitcost bUnitCost, @ecm bECM,
       @totalcost bDollar, @oldloc bLoc, @oldmaterial bMatl, @oldactdate bDate,
       @olddescription bDesc, @oldglacct bGLAcct, @oldunits bUnits, @oldunitcost bUnitCost,
       @oldecm bECM, @oldtotalcost bDollar
   
   declare @detloc bLoc, @detmatl bMatl, @detactdate bDate, @detglacct bGLAcct,
       @detunits bUnits, @detunitcost bUnitCost, @detecm bECM, @dettotalcost bDollar,
       @invglacct bGLAcct, @category varchar(10)
   
   declare @rcode int, @openinab int, @errorstart varchar(60), @errortext varchar(255),
       @status int, @active bYN, @stdum bUM
   
   select @rcode = 0, @openinab = 0
   
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
   exec @rcode = bspHQBatchProcessVal @inco, @mth, @batchid, 'IN Adj', 'INAB', @errmsg output, @status output
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
   delete bINAG where INCo = @inco and Mth = @mth and BatchId = @batchid
   
   -- create a cursor to process all entries in batch
   declare INABbatch_cursor cursor for
   select BatchSeq, BatchTransType, Loc, MatlGroup, Material, INTrans, ActDate, Description,
       GLCo, GLAcct, UM, Units, UnitCost, ECM, TotalCost, OldLoc, OldMaterial, OldActDate,
       OldDescription, OldGLAcct, OldUnits, OldUnitCost, OldECM, OldTotalCost
   from bINAB
   where Co = @inco and Mth = @mth and BatchId = @batchid
   
   open INABbatch_cursor            --open the cursor
   select @openinab =1
   
   INABbatch_cursor_loop:                  --loop through all the records
   
   fetch next from INABbatch_cursor into
       @batchseq, @batchtranstype, @loc, @matlgroup, @material, @intrans, @actdate, @description, @glco,
       @glacct, @um, @units, @unitcost, @ecm, @totalcost, @oldloc, @oldmaterial, @oldactdate,
       @olddescription, @oldglacct, @oldunits, @oldunitcost, @oldecm, @oldtotalcost
   
       if @@fetch_status = 0
           begin
           select @errorstart = 'Seq#: ' + convert(varchar(6),@batchseq)
   
           --  validate Batch Transaction Type
           if @batchtranstype not in ('A', 'C', 'D')
               begin
      	        select @errortext = @errorstart + ' -  Invalid transaction type, must be ''A'',''C'', or ''D''.'
               exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
    	        if @rcode <> 0 goto bspexit
               goto INABbatch_cursor_loop
      	    end
   
           --validation general to add or change entries
        	if @batchtranstype in ('A', 'C')
               begin
          		if @batchtranstype = 'A'
                   begin
                   -- check Trans number to make sure it is null
                   if @intrans is not null
                       begin
   	                select @errortext = @errorstart + ' - New entries must have a null Transaction #!'
                       exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
    	                if @rcode <> 0 goto bspexit
                       goto INABbatch_cursor_loop
                       end
   
                   if @oldloc is not null or @oldmaterial is not null or @oldactdate is not null
                       or @olddescription is not null or @oldglacct is not null
                       or @oldunits is not null or @oldunitcost is not null
                       or @oldecm is not null or @oldtotalcost is not null
                       begin
                       select @errortext = @errorstart + ' - Old entries in batch must be ''null'' for ''Add'' type entries.'
                       exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
      	                if @rcode <> 0 goto bspexit
                       goto INABbatch_cursor_loop
      	                end
                   end
   
               --validate Location
               select @active = Active from bINLM where INCo=@inco and Loc=@loc
               if @@rowcount = 0
                   begin
                   select @errortext = @errorstart + ' - Not a valid Location.'
                   exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
      	            if @rcode <> 0 goto bspexit
                   goto INABbatch_cursor_loop
      	            end
               if @active ='N'
                   begin
                   select @errortext = @errorstart + ' - Location is not active.'
                   exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
      	            if @rcode <> 0 goto bspexit
                   goto INABbatch_cursor_loop
      	            end
   
               -- validate Material - get Category and Std U/M for later use
               select @category = Category, @stdum = StdUM
               from bHQMT
               where MatlGroup = @matlgroup and Material = @material
               if @@rowcount = 0
                   begin
                   select @errortext = @errorstart + ' - Not a valid HQ material.'
                   exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
      	            if @rcode <> 0 goto bspexit
                   goto INABbatch_cursor_loop
      	            end
   
               --validate material at location
               select @active = Active from bINMT where INCo=@inco and Loc=@loc and Material=@material and MatlGroup=@matlgroup
               if @@rowcount = 0
                   begin
                   select @errortext = @errorstart + ' - Material not setup at this Location.'
                   exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
      	            if @rcode <> 0 goto bspexit
                   goto INABbatch_cursor_loop
      	            end
               if @active = 'N'
                   begin
                   select @errortext = @errorstart + ' - Material is not active at this Location.'
                   exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
      	            if @rcode <> 0 goto bspexit
                   goto INABbatch_cursor_loop
      	            end
   
               --validate GL Account
               exec @rcode = bspGLACfPostable @glco, @glacct, 'I', @errmsg output
               if @rcode <> 0
                   begin
                   select @errortext = @errorstart + ' - ' + @errmsg
                   exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
      	            if @rcode <> 0 goto bspexit
                   goto INABbatch_cursor_loop
      	            end
   
               --validate ECM
               if @ecm not in ('E', 'C', 'M')
                   begin
                   select @errortext = @errorstart + ' - Invalid ECM, must be ''E'', ''C'' or ''M''.'
                   exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
      	            if @rcode <> 0 goto bspexit
                   goto INABbatch_cursor_loop
      	            end
   
               --validate UM
               if not exists(select * from bHQUM where UM = @um)
                   begin
                   select @errortext = @errorstart + ' - Not a valid unit of measure.'
                   exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
      	            if @rcode <> 0 goto bspexit
                   goto INABbatch_cursor_loop
      	            end
               if @um <> @stdum
                   begin
                   select @errortext = @errorstart + ' - Must be the standard unit of measure set up in HQ Materials.'
                   exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
                   if @rcode <> 0 goto bspexit
                   end
   
               --Load GL Distribution table with Posted GL Account (new entry)
               --to reduce Inventory, user must enter negative units, so reverse sign on @totalcost for expense
               insert bINAG (INCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, OldNew, INTrans,
                   Loc, MatlGroup, Material, Description, ActDate, Amt)
               values (@inco, @mth, @batchid, @glco, @glacct, @batchseq , 1, @intrans,
                   @loc, @matlgroup, @material, @description, @actdate, -@totalcost)
   
               --get Inventroy GL Account - check for override by Location Category
               select @invglacct = null
               select @invglacct = InvGLAcct
               from bINLO
               where INCo = @inco and Loc = @loc and MatlGroup = @matlgroup and Category=@category
               if @invglacct is null
                   begin
                   -- if no override get Inventory GL Account from Location Master
                   select @invglacct = InvGLAcct from bINLM
                   where INCo = @inco and Loc = @loc
                   end
               -- validate Inventory GL Account
               exec @rcode = bspGLACfPostable @glco, @invglacct, 'I', @errmsg output
               if @rcode <> 0
                   begin
                   select @errortext = @errorstart + ' - ' + @errmsg
                   exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
      	            if @rcode <> 0 goto bspexit
                   goto INABbatch_cursor_loop
      	            end
   
   			-- add GL Dist entry for Inventory - use posted total cost, should typically be
   	        -- negative to represent inventory credit
   			-- Inventory Account may equal posted Account, so try update first
   			update bINAG
   			set Amt = Amt + @totalcost
   			where INCo = @inco and Mth = @mth and BatchId = @batchid and GLCo = @glco and
   				GLAcct = @invglacct and BatchSeq = @batchseq and OldNew = 1
   			if @@rowcount = 0
   	            insert bINAG (INCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, OldNew, INTrans,
   	                Loc, MatlGroup, Material, Description, ActDate, Amt)
   	            values (@inco, @mth, @batchid, @glco, @invglacct, @batchseq , 1, @intrans,
   	                @loc, @matlgroup, @material, @description, @actdate, @totalcost)
               end		-- finished with 'new' ditributions for Add or Change entry
   
   		if @batchtranstype in ('C', 'D')  --check to see whether detail and old entries match
               begin
               select @detloc = Loc, @detmatl = Material, @detactdate = ActDate,
               	@detglacct = GLAcct, @detunits = PostedUnits, @detunitcost = PostedUnitCost,
                   @detecm = PostECM, @dettotalcost = PostedTotalCost
               from bINDT
               where INCo = @inco and Mth = @mth and INTrans = @intrans
               -- compare 'old' values with existing detail
   			if @detloc <> @oldloc and @detmatl <> @oldmaterial and @detactdate <> @oldactdate
                   and @detglacct <> @oldglacct and @detunits <> @oldunits and
                   @detunitcost <> @oldunitcost and @detecm <> @oldecm and @dettotalcost <> @oldtotalcost
                   begin
                   select @errortext = @errorstart + ' - ''Old'' batch values do not match current values!'
                   exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
      	            if @rcode <> 0 goto bspexit
                   goto INABbatch_cursor_loop
                   end
               --validate old Location
               select @active = Active from bINLM where INCo=@inco and Loc=@oldloc
               if @@rowcount = 0
                   begin
                   select @errortext = @errorstart + ' - ''Old'' Location is invalid.'
                   exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
      	            if @rcode <> 0 goto bspexit
                   goto INABbatch_cursor_loop
      	            end
               if @active ='N'
                   begin
                   select @errortext = @errorstart + ' - ''Old'' Location is not active.'
                   exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
      	            if @rcode <> 0 goto bspexit
                   goto INABbatch_cursor_loop
      	            end
               -- validate old Material - get Category and Std U/M for later use
               select @category = Category, @stdum = StdUM
               from bHQMT
               where MatlGroup = @matlgroup and Material = @oldmaterial
               if @@rowcount = 0
                   begin
                   select @errortext = @errorstart + ' - ''Old'' HQ material is not valid.'
                   exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
      	            if @rcode <> 0 goto bspexit
                   goto INABbatch_cursor_loop
      	            end
               --validate old Material at old Location
               select @active = Active
               from bINMT
               where INCo=@inco and Loc=@oldloc and Material=@oldmaterial and MatlGroup=@matlgroup
               if @@rowcount = 0
                   begin
                   select @errortext = @errorstart + ' - ''Old'' Material not setup at ''old'' Location.'
                   exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
      	            if @rcode <> 0 goto bspexit
                   goto INABbatch_cursor_loop
      	            end
               if @active = 'N'
                   begin
                   select @errortext = @errorstart + ' - ''Old'' Material is not active at this ''old'' Location.'
                   exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
      	            if @rcode <> 0 goto bspexit
                   goto INABbatch_cursor_loop
      	            end
               --validate old posted GL Account
               exec @rcode = bspGLACfPostable @glco, @oldglacct, 'I', @errmsg output
               if @rcode <> 0
                   begin
                   select @errortext = @errorstart + ' - ' + @errmsg
                   exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
      	            if @rcode <> 0 goto bspexit
                   goto INABbatch_cursor_loop
      	            end
   
               --Load GL Distribution table with Posted GL Account (use old values)
               -- don't reverse sign on @oldtotalcost
               insert bINAG (INCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, OldNew, INTrans,
                   Loc, MatlGroup, Material, Description, ActDate, Amt)
               values (@inco, @mth, @batchid, @glco, @oldglacct, @batchseq , 0, @intrans,
                   @oldloc, @matlgroup, @oldmaterial, @olddescription, @oldactdate, @oldtotalcost)
   
               --get Inventroy GL Account - check for override by Location Category
               select @invglacct = null
               select @invglacct = InvGLAcct
               from bINLO
               where INCo = @inco and Loc = @oldloc and MatlGroup = @matlgroup and Category=@category
               if @invglacct is null
                   begin
                   -- if no override get Inventory GL Account from Location Master
                   select @invglacct = InvGLAcct from bINLM
                   where INCo = @inco and Loc = @oldloc
                   end
               -- validate Inventory GL Account
               exec @rcode = bspGLACfPostable @glco, @invglacct, 'I', @errmsg output
               if @rcode <> 0
                   begin
                   select @errortext = @errorstart + ' - ' + @errmsg
                   exec @rcode = bspHQBEInsert @inco, @mth, @batchid, @errortext, @errmsg output
      	            if @rcode <> 0 goto bspexit
                   goto INABbatch_cursor_loop
      	            end
   
               -- add GL distribution for Old Inventory - reverse sign on @oldtotalcost
   			-- Inventory Account may equal posted Account, so try update first
   			update bINAG
   			set Amt = Amt - @oldtotalcost
   			where INCo = @inco and Mth = @mth and BatchId = @batchid and GLCo = @glco and
   				GLAcct = @invglacct and BatchSeq = @batchseq and OldNew = 0
   			if @@rowcount = 0
                   insert bINAG (INCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, OldNew, INTrans,
                       Loc, MatlGroup, Material, Description, ActDate, Amt)
                   values (@inco, @mth, @batchid, @glco, @invglacct, @batchseq , 0, @intrans,
                       @oldloc, @matlgroup, @oldmaterial, @olddescription, @oldactdate, -@oldtotalcost)
               end		-- finished 'old' entries for Change or Delete entry
   
           goto INABbatch_cursor_loop               -- get the next seq
           end
   
       --close and deallocate cursor
       if @openinab = 1
           begin
           close INABbatch_cursor
           deallocate INABbatch_cursor
           select @openinab = 0
           end
   
   -- make sure debits and credits balance
   select @glco = GLCo
   from bINAG
   where INCo = @inco and Mth = @mth and BatchId = @batchid
   group by GLCo
   having isnull(sum(Amt),0) <> 0
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
       if @openinab = 1
          begin
          close INABbatch_cursor
          deallocate INABbatch_cursor
          end
   
		return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINABVal] TO [public]
GO
