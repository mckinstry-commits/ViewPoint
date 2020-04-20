SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**********************************************************/
CREATE  procedure [dbo].[bspMSPostIN]
   /***********************************************************
    * Created: GG 10/27/00
    * Modfied: GG 05/30/01 - Added @@rowcount check after bINDT inserts
    *			GF 08/01/2003 - issue #21933 - speed improvements
    *			GF 12/03/2003 - issue #23139 - added INTrans to MSPA and MSIN for rowset update.
    *			GF 10/13/2004 - issue #25766 - when updating INTrans in MSIN not doing by INCo. Duplicate index possible
    *			GF 08/17/2012 TK-17275 write out finish material from MSPA to INDT
    *
    *
    * Called from the bspMSTBPost and bspMSHBPost procedures to post
    * all IN distributions tracked in bMSPA and bMSIN for both Ticket
    * and Hauler Time sheet batches.
    *
    * Sign on values in 'old' entries has already been reversed.
    *
    * INMT OnHand units and Average Unit Cost updates are done in INDT insert trigger
    *
    * IN Sales/Production Interface Levels:
    *	0      No update
    *	1      Summarize entries by Location/Material/INTransType/GLCo/GLAcct/PostedUM
    *  2      Full detail
    *
    * INPUT PARAMETERS
    *	@co			    MS/IN Co#
    *	@mth			Batch month
    *	@batchid		Batch ID#
    *	@dateposted	    Posting date
    *
    * OUTPUT PARAMETERS
    *	@errmsg		    Message used for errors
    *
    * RETURN VALUE
    *	0 = success, 1 = fail
    *****************************************************/
   (@co bCompany, @mth bMonth, @batchid bBatchID, @dateposted bDate = null, @errmsg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @msglco bCompany, @ininterfacelvl tinyint, @inprodinterfacelvl tinyint, @openMSPA tinyint,
       @loc bLoc, @matlgroup bGroup, @material bMatl, @intranstype varchar(10), @units bUnits, @totalcost bDollar,
       @totalprice bDollar, @category varchar(10), @um bUM, @lminvglacct bGLAcct, @salesglacct bGLAcct,
       @loinvglacct bGLAcct, @glacct bGLAcct, @unitcost bUnitCost, @unitprice bUnitCost, @intrans bTrans,
       @msg varchar(255), @seq int, @oldnew tinyint, @mstrans bTrans, @saledate bDate, @selltrnsfrloc bLoc,
       @ecm bECM, @pecm bECM, @trnsfrloc bLoc, @salesinco bCompany, @salesloc bLoc, @openMSIN tinyint,
       @inco bCompany, @postedunits bUnits, @postedtotalcost bDollar, @stkunits bUnits, @stktotalcost bDollar,
       @stdum bUM, @postedunitcost bUnitCost, @stkunitcost bUnitCost, @glco bCompany, @custgroup bGroup,
       @customer bCustomer, @custjob varchar(20), @custpo varchar(20), @jcco bCompany, @job bJob,
       @phase bPhase, @jcct bJCCType, @phasegroup bGroup, @postedum bUM, @postecm bECM, @stkum bUM,
       @stkecm bECM, @haulline smallint, @msin_count bTrans, @msin_trans bTrans, @openMSINTrans TINYINT
       ----TK-17275
       ,@FinishMatl bMatl
   
   select @rcode = 0, @openMSPA = 0, @openMSIN = 0, @openMSINTrans = 0
   
   --get IN interface level
   select @msglco = GLCo, @ininterfacelvl = INInterfaceLvl, @inprodinterfacelvl = INProdInterfaceLvl
   from bMSCO with (nolock) where MSCo = @co
   if @@rowcount <> 1
       begin
       select @errmsg = 'Invalid MS Co#', @rcode = 1
       goto bspexit
       end
   if @inprodinterfacelvl not in (0,1,2)
       begin
       select @errmsg = 'Invalid IN Production Interface level assigned MS Company.', @rcode = 1
       goto bspexit
       end
   if @ininterfacelvl not in (0,1,2)
       begin
       select @errmsg = 'Invalid IN Sales and Purchase Interface level assigned MS Company.', @rcode = 1
       goto bspexit
       end
   
   /** Post Auto Production distributions - will be none in Hauler Time Sheet batches **/
   
   -- No update to IN
   if @inprodinterfacelvl = 0
       begin
       delete bMSPA where MSCo = @co and Mth = @mth and BatchId = @batchid
       goto MSPA_posting_end
    	end
   
   -- Summary update to IN - one entry per Location/Material/INTransType
   if @inprodinterfacelvl = 1
       begin
       -- use summary level cursor on MS IN Production Distributions
       declare bcMSPA cursor LOCAL FAST_FORWARD for
       select Loc, MatlGroup, Material, INTransType, convert(numeric(12,3),sum(Units)),
           convert(numeric(12,2),sum(TotalCost)), convert(numeric(12,2),sum(TotalPrice))
    	from bMSPA
       where MSCo = @co and Mth = @mth and BatchId = @batchid
    	group by Loc, MatlGroup, Material, INTransType
   
       --open cursor
       open bcMSPA
       select @openMSPA = 1
   
       MSPA_summary_loop:
           fetch next from bcMSPA into @loc, @matlgroup, @material, @intranstype, @units, @totalcost, @totalprice
   
           if @@fetch_status = -1 goto MSPA_posting_end
           if @@fetch_status <> 0 goto MSPA_summary_loop
   
           select @category = null, @um = null, @lminvglacct = null, @salesglacct = null, @loinvglacct = null
           -- get Material info (all units already converted to Std UM)
           select @category = Category, @um = StdUM from bHQMT with (nolock) where MatlGroup = @matlgroup and Material = @material
           -- get Inventory and Sales to Inventory Accounts
           select @lminvglacct = InvGLAcct, @salesglacct = InvSalesGLAcct
           from bINLM with (nolock) where INCo = @co and Loc = @loc
           -- check for Inventory Account override
           select @loinvglacct = InvGLAcct
           from bINLO with (nolock)
           where INCo = @co and Loc = @loc and MatlGroup = @matlgroup and Category = @category
   
   	   select @glacct = case @intranstype when 'IN Sale' then @salesglacct else isnull(@loinvglacct,@lminvglacct) end
   
   	   select @unitcost = 0, @unitprice = 0
           if @units <> 0 select @unitcost = @totalcost / @units, @unitprice = @totalprice / @units
   
           begin transaction
   
           if @units <> 0 or @totalcost <> 0 or @totalprice <> 0
               begin
               --get next available transaction # for INDT
               exec @intrans = dbo.bspHQTCNextTrans 'bINDT', @co, @mth, @msg output
    	        if @intrans = 0
                   begin
      	            select @errmsg = 'Unable to update IN Detail.  ' + isnull(@msg,''), @rcode = 1
                   goto MSPA_posting_error
          	        end
   
               --add IN Detail entry
               insert bINDT (INCo, Mth, INTrans, Loc, MatlGroup, Material, ActDate, PostedDate,
                   Source, TransType,  GLCo, GLAcct, Description, PostedUM, PostedUnits, PostedUnitCost,
                   PostECM, PostedTotalCost, StkUM, StkUnits, StkUnitCost, StkECM, StkTotalCost, UnitPrice,
                   PECM, TotalPrice, BatchId)
               values (@co, @mth, @intrans, @loc, @matlgroup, @material, @dateposted, @dateposted,
                   'MS', @intranstype, @msglco, @glacct, 'Auto Production', @um, @units, @unitcost,
                   'E', @totalcost, @um, @units, @unitcost, 'E', @totalcost, @unitprice,
                   'E', @totalprice, @batchid)
   	    if @@rowcount = 0
   			begin
               select @errmsg = 'Unable to add IN Detail entry', @rcode = 1
               goto MSPA_posting_error
               end
           end
   
           --delete distribution entries
   	    delete bMSPA
           where MSCo = @co and Mth = @mth and BatchId = @batchid and Loc = @loc
           	 and MatlGroup = @matlgroup and Material = @material and INTransType = @intranstype
   
           commit transaction
   
           goto MSPA_summary_loop
       end
   
   -- Detail update to IN - one entry per Location/Material/INTransType/BatchSeq
   if @inprodinterfacelvl = 2
       begin
   	-- delete MSPA distributions where Units, TotalCost, and TotalPrice equal zero. Not sent to INDT.
   	delete bMSPA where MSCo=@co and Mth=@mth and BatchId=@batchid and Units=0 and TotalCost=0 and TotalPrice=0
   
   	-- get count of bMSPA rows that need a INTrans
   	select @msin_count = count(*) from bMSPA
   	where MSCo=@co and Mth=@mth and BatchId=@batchid and INTrans is null
   	-- only update HQTC and MSPA if there are MSPA rows that need updating
   	if isnull(@msin_count,0) <> 0
   		begin
     		-- get next available Transaction # for INDT
     		exec @intrans = dbo.bspHQTCNextTransWithCount 'bINDT', @co, @mth, @msin_count, @msg output
     		if @intrans = 0
     			begin
   			select @errmsg = 'Unable to update IN Detail.  ' + isnull(@msg,''), @rcode = 1
     			goto bspexit
     			end
     
   	  	-- set @msin_trans to last transaction from bHQTC as starting point for update
   	  	set @msin_trans = @intrans - @msin_count
     	
   	  	-- update bMSPA and set INTrans
   	  	update bMSPA set @msin_trans = @msin_trans + 1, INTrans = @msin_trans
   	  	where MSCo=@co and Mth=@mth and BatchId=@batchid and INTrans is null
   	  	-- compare count from update with MSIN rows that need to be updated
   	  	if @@rowcount <> @msin_count
   	  		begin
   	  		select @errmsg = 'Error has occurred updating INTrans in MSPA distribution table!', @rcode = 1
   	  		goto bspexit
   	  		end
   		end
   
   
       -- use detail level cursor on MS IN Production Distributions
       declare bcMSPA cursor LOCAL FAST_FORWARD for
       select Loc, MatlGroup, Material, INTransType, BatchSeq, OldNew, MSTrans, SaleDate, SellTrnsfrLoc,
           UM, Units, UnitCost, ECM, TotalCost, UnitPrice, PECM, TotalPrice, INTrans
           ----TK-17275
           ,FinishMatl
    	from bMSPA
       where MSCo = @co and Mth = @mth and BatchId = @batchid
   
       --open cursor
       open bcMSPA
       select @openMSPA = 1
   
       MSPA_detail_loop:
           fetch next from bcMSPA into @loc, @matlgroup, @material, @intranstype, @seq, @oldnew, @mstrans, @saledate,
   			@selltrnsfrloc, @um, @units, @unitcost, @ecm, @totalcost, @unitprice, @pecm, @totalprice, @intrans
   			----TK-17275
   			,@FinishMatl
   
           if @@fetch_status = -1 goto MSPA_posting_end
           if @@fetch_status <> 0 goto MSPA_detail_loop
   
           select @category = null, @lminvglacct = null, @salesglacct = null, @loinvglacct = null
           -- get Material info (all units already converted to Std UM)
           select @category = Category from bHQMT with (nolock) where MatlGroup = @matlgroup and Material = @material
           -- get Inventory and Sales to Inventory Accounts
           select @lminvglacct = InvGLAcct, @salesglacct = InvSalesGLAcct
           from bINLM with (nolock) where INCo = @co and Loc = @loc
           -- check for Inventory Account override
           select @loinvglacct = InvGLAcct
           from bINLO with (nolock) 
           where INCo = @co and Loc = @loc and MatlGroup = @matlgroup and Category = @category
   
   	    select @trnsfrloc = case when @intranstype in('Trnsfr In','Trnsfr Out') then @selltrnsfrloc else null end
           select @salesinco = case when @intranstype in('IN Sale','Purch') then @co else null end
           select @salesloc = case when @intranstype in('IN Sale','Purch') then @selltrnsfrloc else null end
           select @glacct = case @intranstype when 'IN Sale' then @salesglacct else isnull(@loinvglacct,@lminvglacct) end
   
   
           begin transaction
  
   
               --add IN Detail entry
               insert bINDT (INCo, Mth, INTrans, Loc, MatlGroup, Material, ActDate, PostedDate,
                   Source, TransType,  TrnsfrLoc, MSTrans, SellToINCo, SellToLoc, GLCo, GLAcct,
                   Description, PostedUM, PostedUnits, PostedUnitCost, PostECM, PostedTotalCost,
                   StkUM, StkUnits, StkUnitCost, StkECM, StkTotalCost, UnitPrice, PECM, TotalPrice, BatchId
                   ----TK-17275
                   ,FinishMatl)
               values (@co, @mth, @intrans, @loc, @matlgroup, @material, @saledate, @dateposted,
                   'MS', @intranstype, @trnsfrloc, @mstrans, @salesinco, @salesloc, @msglco, @glacct,
                   'Auto production', @um, @units, @unitcost, @ecm, @totalcost,
                   @um, @units, @unitcost, @ecm, @totalcost, @unitprice, @pecm, @totalprice, @batchid
                   ----TK-17275
                   ,@FinishMatl)
               if @@rowcount = 0
   				begin
                   select @errmsg = 'Unable to add IN Detail entry', @rcode = 1
               	goto MSPA_posting_error
               	end
   -- 	    end
   
           --delete distribution entry
   	    delete bMSPA
           where MSCo = @co and Mth = @mth and BatchId = @batchid and Loc = @loc
               and MatlGroup = @matlgroup and Material = @material and INTransType = @intranstype
               and BatchSeq = @seq and OldNew = @oldnew
           if @@rowcount <> 1
               begin
               select @errmsg = 'Unable to delete IN Auto Production entry', @rcode = 1
               goto MSPA_posting_error
               end
   
           commit transaction
   
           goto MSPA_detail_loop
       end
   
   MSPA_posting_error:
       rollback transaction
       goto bspexit
   
   MSPA_posting_end:
       if @openMSPA = 1
           begin
           close bcMSPA
           deallocate bcMSPA
           select @openMSPA = 0
           end
   
   
   -- Post IN Sales and Purchases distributions (not related to Auto Production)
   
   -- No update to IN
   if @ininterfacelvl = 0
       begin
       delete bMSIN where MSCo = @co and Mth = @mth and BatchId = @batchid
       goto MSIN_posting_end
    	end
   
   -- Summary update to IN - one entry per INCo/Location/Material/INTransType/GLAcct/PostedUM
   if @ininterfacelvl = 1
       begin
       -- use summary level cursor on MS IN Production Distributions
       declare bcMSIN cursor LOCAL FAST_FORWARD for
       select INCo, Loc, MatlGroup, Material, INTransType, GLCo, GLAcct, PostedUM,
           convert(numeric(12,3),sum(PostedUnits)), convert(numeric(12,2),sum(PostedTotalCost)),
           convert(numeric(12,3),sum(StkUnits)), convert(numeric(12,2),sum(StkTotalCost)),
           convert(numeric(12,2),sum(TotalPrice))
    	from bMSIN
       where MSCo = @co and Mth = @mth and BatchId = @batchid
    	group by INCo, Loc, MatlGroup, Material, INTransType, GLCo, GLAcct, PostedUM
   
       --open cursor
       open bcMSIN
       select @openMSIN = 1
   
       MSIN_summary_loop:
           fetch next from bcMSIN into @inco, @loc, @matlgroup, @material, @intranstype, @glco, @glacct, @um,
               @postedunits, @postedtotalcost, @stkunits, @stktotalcost, @totalprice
   
           if @@fetch_status = -1 goto MSIN_posting_end
           if @@fetch_status <> 0 goto MSIN_summary_loop
   
           -- get Material info
           select @stdum = null
           select @stdum = StdUM from bHQMT with (nolock) where MatlGroup = @matlgroup and Material = @material
   
   	   --calculate unit cost and price
           select @postedunitcost = 0, @unitprice = 0, @stkunitcost = 0
           if @postedunits <> 0 select @postedunitcost = @postedtotalcost / @postedunits, @unitprice = @totalprice / @postedunits
           if @stkunits <> 0 select @stkunitcost = @stktotalcost / @stkunits
   
           begin transaction
   
           if @postedunits <> 0 or @postedtotalcost <> 0 or @stkunits <> 0 or @stktotalcost <> 0 or @totalprice <> 0
               begin
   			--get next available transaction # for INDT -- use posted to IN Co#
               exec @intrans = dbo.bspHQTCNextTrans 'bINDT', @inco, @mth, @msg output
    	        if @intrans = 0
                   begin
      	            select @errmsg = 'Unable to update IN Detail.  ' + isnull(@msg,''), @rcode = 1
                   goto MSIN_posting_error
          	        end
   
               --add IN Detail entry
               insert bINDT (INCo, Mth, INTrans, Loc, MatlGroup, Material, ActDate, PostedDate,
                   Source, TransType,  GLCo, GLAcct, Description, PostedUM, PostedUnits, PostedUnitCost,
                   PostECM, PostedTotalCost, StkUM, StkUnits, StkUnitCost, StkECM, StkTotalCost, UnitPrice,
                   PECM, TotalPrice, BatchId)
               values (@inco, @mth, @intrans, @loc, @matlgroup, @material, @dateposted, @dateposted,
                   'MS', @intranstype, @glco, @glacct, 'Material Sales', @um, @postedunits, @postedunitcost,
                   'E', @postedtotalcost, @stdum, @stkunits, @stkunitcost, 'E', @stktotalcost, @unitprice,
                   'E', @totalprice, @batchid)
   	    	if @@rowcount = 0
   			begin
   			select @errmsg = 'Unable to add IN Detail entry', @rcode = 1
   			goto MSIN_posting_error
   			end
   		end
   
   	--delete distribution entries
   	delete bMSIN
   	where MSCo = @co and Mth = @mth and BatchId = @batchid and INCo = @inco and MatlGroup = @matlgroup
   	and Material = @material and INTransType = @intranstype and GLCo = @glco and GLAcct = @glacct and PostedUM = @um
   
   	commit transaction
   
   	goto MSIN_summary_loop
   	end
   
   
   -- Detail update to IN - one entry per INCo/Location/Material/INTransType/BatchSeq
   if @ininterfacelvl = 2
       begin
   	-- delete MSIN distributions where StkUnits, StkTotalCost, and TotalPrice equal zero. Not sent to INDT.
   	delete bMSIN where MSCo=@co and Mth=@mth and BatchId=@batchid and StkUnits=0 and StkTotalCost=0 and TotalPrice=0
   
   
   	-- need cursor on bMSIN for each distinct INCo
   	declare bcMSINTrans cursor LOCAL FAST_FORWARD for select distinct(INCo)
   	from bMSIN where MSCo = @co and Mth = @mth and BatchId = @batchid
   	group by INCo
   
   	--open cursor
   	open bcMSINTrans
   	select @openMSINTrans = 1
   
   	MSINTrans_loop:
   	fetch next from bcMSINTrans into @inco
   	if @@fetch_status = -1 goto MSINTrans_end
   	if @@fetch_status <> 0 goto MSINTrans_loop
   
   	-- get count of bMSIN rows that need a INTrans
   	select @msin_count = count(*) from bMSIN
   	where MSCo=@co and Mth=@mth and BatchId=@batchid and INTrans is null and INCo=@inco
   	-- only update HQTC and MSIN if there are MSIN rows that need updating
   	if isnull(@msin_count,0) <> 0
   		begin
     		-- get next available Transaction # for INDT
     		exec @intrans = dbo.bspHQTCNextTransWithCount 'bINDT', @inco, @mth, @msin_count, @msg output
     		if @intrans = 0
     			begin
   			select @errmsg = 'Unable to update IN Detail.  ' + isnull(@msg,''), @rcode = 1
     			goto bspexit
     			end
     
   	  	-- set @msin_trans to last transaction from bHQTC as starting point for update
   	  	set @msin_trans = @intrans - @msin_count
     	
   	  	-- update bMSIN and set INTrans
   	  	update bMSIN set @msin_trans = @msin_trans + 1, INTrans = @msin_trans
   	  	where MSCo=@co and Mth=@mth and BatchId=@batchid and INTrans is null and INCo=@inco
   	  	-- compare count from update with MSIN rows that need to be updated
   	  	if @@rowcount <> @msin_count
   	  		begin
   	  		select @errmsg = 'Error has occurred updating INTrans in MSIN distribution table!', @rcode = 1
   	  		goto bspexit
   	  		end
   		end
   
   	goto MSINTrans_loop
   
   	MSINTrans_end:
   		if @openMSINTrans = 1
   			begin
   			close bcMSINTrans
   			deallocate bcMSINTrans
   			set @openMSINTrans = 0
   			end
   
   
   	-- use detail level cursor on MS IN Production Distributions
   	declare bcMSIN cursor LOCAL FAST_FORWARD for
   	select INCo, Loc, MatlGroup, Material, INTransType, BatchSeq, HaulLine, OldNew, MSTrans, SaleDate, CustGroup,
   		Customer, CustJob, CustPO, JCCo, Job, PhaseGroup, MatlPhase, MatlJCCType, SalesINCo, SalesLoc,
   		GLCo, GLAcct, PostedUM, PostedUnits, PostedUnitCost, PostECM, PostedTotalCost, StkUM, StkUnits, StkUnitCost,
   		StkECM, StkTotalCost, UnitPrice, PECM, TotalPrice, INTrans
   	from bMSIN
   	where MSCo = @co and Mth = @mth and BatchId = @batchid
   
       --open cursor
       open bcMSIN
       select @openMSIN = 1
   
       MSIN_detail_loop:
           fetch next from bcMSIN into @inco, @loc, @matlgroup, @material, @intranstype, @seq, @haulline, @oldnew, @mstrans,
               @saledate, @custgroup, @customer, @custjob, @custpo, @jcco, @job, @phasegroup, @phase, @jcct,
               @salesinco, @salesloc, @glco, @glacct, @postedum, @postedunits, @postedunitcost, @postecm, @postedtotalcost,
               @stkum, @stkunits, @stkunitcost, @stkecm, @stktotalcost, @unitprice, @pecm, @totalprice, @intrans
   
           if @@fetch_status = -1 goto MSIN_posting_end
           if @@fetch_status <> 0 goto MSIN_detail_loop
   
           begin transaction
   
               --add IN Detail entry
               insert bINDT (INCo, Mth, INTrans, Loc, MatlGroup, Material, ActDate, PostedDate,
                   Source, TransType, MSTrans, CustGroup, Customer, CustJob, CustPO, JCCo, Job,
                   PhaseGroup, Phase, JCCType, SellToINCo, SellToLoc, GLCo, GLAcct, Description,
                   PostedUM, PostedUnits, PostedUnitCost, PostECM, PostedTotalCost,
                   StkUM, StkUnits, StkUnitCost, StkECM, StkTotalCost, UnitPrice, PECM, TotalPrice, BatchId)
               values (@inco, @mth, @intrans, @loc, @matlgroup, @material, @saledate, @dateposted,
    				'MS', @intranstype, @mstrans, @custgroup, @customer, @custjob, @custpo, @jcco, @job,
                   @phasegroup, @phase, @jcct, @salesinco, @salesloc, @glco, @glacct, 'Material Sales',
          			@postedum, @postedunits, @postedunitcost, @postecm, @postedtotalcost,
                   @stkum, @stkunits, @stkunitcost, @stkecm, @stktotalcost, @unitprice, @pecm, @totalprice, @batchid)
               if @@rowcount = 0
   				begin
                   select @errmsg = 'Unable to add IN Detail entry', @rcode = 1
               	goto MSIN_posting_error
               	end
   -- 	    	end
   
           --delete distribution entry
   	    delete bMSIN
           where MSCo = @co and Mth = @mth and BatchId = @batchid and INCo = @inco and Loc = @loc
               and MatlGroup = @matlgroup and Material = @material and INTransType = @intranstype
               and BatchSeq = @seq and HaulLine = @haulline and OldNew = @oldnew
           if @@rowcount <> 1
               begin
               select @errmsg = 'Unable to delete IN Sales/Purchase entry', @rcode = 1
               goto MSIN_posting_error
               end
   
           commit transaction
   
           goto MSIN_detail_loop
       end
   
   MSIN_posting_error:
       rollback transaction
       goto bspexit
   
   
   MSIN_posting_end:
       if @openMSIN = 1
           begin
           close bcMSIN
           deallocate bcMSIN
           set @openMSIN = 0
           end
   
   
   
   bspexit:
       if @openMSPA = 1
   		begin
    		close MSPA_cursor
    		deallocate MSPA_cursor
   		set @openMSPA = 0
    		end
   
       if @openMSIN = 1
   		begin
    		close MSIN_cursor
    		deallocate MSIN_cursor
   		set @openMSIN = 0
    		end
   
   	if @rcode <> 0 select @errmsg = isnull(@errmsg,'')
    	return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspMSPostIN] TO [public]
GO
