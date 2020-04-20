SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    procedure [dbo].[bspINXBVal]
   /************************************************************************
    * Created: GG 04/17/02
    * Modified: DANF 09/05/02 - 17738 Added Phase Group to bspJobTypeVal
    *			GP 11/16/2009 - 136015 Added initialization value of 0 to @taxamt
    *
    * Usage:
    *  Validates each entry in IN MO Close Batch - loads JC Distributions in bINXJ
    *  to relieve remaining committed units and costs, and IN Distributions in bINXI
    *	to relieve quantities allocated
    *
    * Input:
    *  @co         IN Company
    *  @mth        Batch Month for Close
    *  @batchid    Batch ID
    *
    * Output:
    *  @errmsg     Error message
    *
    * Return:
    *  0           Success
    *  1           Failure
    *
    *************************************************************************/
   
       (@co bCompany = null, @mth bMonth = null, @batchid bBatchID = null, @errmsg varchar(255) output)
   
   as
   set nocount on
   
   declare @rcode tinyint, @status tinyint, @INXBcursor tinyint, @seq int, @mo bMO, @errorhdr varchar(255),
   	@mostatus tinyint, @jcco bCompany, @glco bCompany, @lastglco bCompany, @moitem bItem, @loc bLoc,
   	@matlgroup bGroup, @material bMatl, @job bJob, @phasegroup bGroup, @phase bPhase, @jcctype bJCCType,
       @um bUM, @unitprice bUnitCost, @ecm bECM, @taxgroup bGroup, @taxcode bTaxCode, @remainunits bUnits,
   	@INMIcursor tinyint, @factor smallint, @remaincost bDollar, @umconv bUnitCost, @stdum bUM, 
   	@alloc bUnits, @jcum bUM, @jcumconv bUnitCost, @closedate bDate, @taxphase bPhase, @taxjcct bJCCType,
   	@taxrate bRate, @taxamt bDollar, @remcmtdcost bDollar, @description bDesc, @jcunits bUnits
   
   
   select  @rcode = 0
   
   /* validate HQ Batch */
   exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, 'MO Close', 'INXB', @errmsg output, @status output
   if @rcode <> 0 
		begin
			goto bspexit
		end

   if @status < 0 or @status > 3
    	begin
		 	select @errmsg = 'Invalid Batch status!', @rcode = 1
    		goto bspexit
    	end
   
   /* set HQ Batch status to 1 (validation in progress) */
   update bHQBC
   set Status = 1
   where Co = @co and Mth = @mth and BatchId = @batchid
   if @@rowcount = 0
    	begin
    		select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
    		goto bspexit
    	end
   
   -- clear HQ Batch Errors
   delete bHQBE where Co = @co and Mth = @mth and BatchId = @batchid
   
   -- clear IN JC Distribution Audit
   delete bINXJ where INCo = @co and Mth = @mth and BatchId = @batchid

   -- clear IN IN Distribution Audit
   delete bINXI where INCo = @co and Mth = @mth and BatchId = @batchid
   
   -- declare cursor on IN MO Close Batch
   declare bcINXB cursor for
   select BatchSeq, MO, CloseDate
   from bINXB
   where Co = @co and Mth = @mth and BatchId = @batchid
   
   open bcINXB
   select @INXBcursor = 1
   
   -- process each Material Order
   INXB_loop:
       fetch next from bcINXB into @seq, @mo, @closedate
   
       if @@fetch_status <> 0 
			begin
				goto INXB_end
			end
   
    	-- initialize error message
    	select @errorhdr = 'Seq#:' + convert(varchar(6),@seq)
   
    	-- validate Material Order
    	select @mostatus = Status, @jcco = JCCo
       from bINMO
       where INCo = @co and MO = @mo
       if @@rowcount = 0
    	    begin
    			select @errmsg = @errorhdr + ' - Invalid Material Order: ' + @mo
    			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errmsg, @errmsg output
    			if @rcode <> 0 
					begin
						goto bspexit
					end
				goto INXB_loop  
    		end
       if @mostatus not in (0,1)
           begin
				select @errmsg = @errorhdr + ' - Material Order: ' + @mo + ' Status must be Open or Completed.'
    			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errmsg, @errmsg output
    			if @rcode <> 0 
					begin
						goto bspexit
					end
				goto INXB_loop 
    		end
   
       -- check that no IN Detail Transactions exist in a month later than the Close Month
       if exists(select 1 from bINDT where INCo = @co and Mth > @mth and MO = @mo)
           begin
				select @errmsg = @errorhdr + ' - Material Order: ' + @mo + ' has IN Confirmation Detail posted later than Close Month.'
    			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errmsg, @errmsg output
    			if @rcode <> 0 
					begin
						goto bspexit
					end
				goto INXB_loop 
    		end
   
   
   	 -- check that month is open in JC GL Co#
   	select @glco = GLCo from bJCCO where JCCo = @jcco
   	if @@rowcount = 0
   		begin
   			select @errmsg = @errorhdr + ' - Material Order: ' + @mo + ' has invalid JC Co#: ' + convert(varchar,@jcco)
    		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errmsg, @errmsg output
    		if @rcode <> 0 
				begin
					goto bspexit
				end
			goto INXB_loop 
    	end
    if @glco <> @lastglco or @lastglco is null
           begin
				exec @rcode = bspHQBatchMonthVal @glco, @mth, 'IN', @errmsg output
				if @rcode <> 0
   					begin
   						select @errmsg = @errorhdr + ' - ' + @errmsg
   						exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errmsg, @errmsg output
   						if @rcode <> 0 
							begin
								goto bspexit
							end
   						goto INXB_loop     
   					end
				select @lastglco = @glco
           end
   
    -- declare cursor on MO Items
    declare bcINMI cursor for
    select MOItem, Loc, MatlGroup, Material, Description, JCCo, Job, PhaseGroup, Phase, JCCType,
   	UM, UnitPrice, ECM, TaxGroup, TaxCode, RemainUnits
    from bINMI
    where INCo = @co and MO = @mo
   
    	-- open item cursor
    	open bcINMI
    	select @INMIcursor = 1
   
    	-- process each MO Item
       INMI_loop:
           fetch next from bcINMI into @moitem, @loc, @matlgroup, @material, @description, @jcco, @job,
   			@phasegroup, @phase, @jcctype, @um, @unitprice, @ecm, @taxgroup, @taxcode, @remainunits
   
           if @@fetch_status <> 0
				begin
					 goto INMI_end
				end
   
    	   select @errorhdr = @errorhdr + ' Material Order: ' + @mo + ' Item#:' + convert(varchar(6),@moitem)
      
           if @remainunits = 0 
				begin
					goto INMI_loop     -- no updates needed
				end
   
   			-- calculate remaining cost, excluding tax
   			select @factor = case @ecm when 'M' then 1000 when 'C' then 100 else 1 end
   			select @remaincost = (@remainunits * @unitprice) / @factor
   
   			-- reset std u/m conversion factor
   			select @umconv = 1
   		
   			-- validate Material, get standard unit of measure
   			select @stdum = StdUM
   			from bHQMT
   			where MatlGroup = @matlgroup and Material = @material
   			if @@rowcount = 0
   				begin
   				select @errmsg = @errorhdr + ' - Invalid Material ' + @material + ', not setup in HQ.'
   				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errmsg, @errmsg output
   				if @rcode <> 0
					begin
						 goto bspexit
					end
            	goto INMI_loop
   	        end
   			
   		-- if not standard u/m, validate and get conversion
           if @um <> @stdum
   			begin
   				select @umconv = Conversion
   				from bINMU
   				where INCo = @co and Loc = @loc and MatlGroup = @matlgroup and Material = @material and UM = @um
   				if @@rowcount = 0
   					begin
   						select @errmsg = @errorhdr + ' - Invalid unit of measure for this Material.'
   						exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errmsg, @errmsg output
   						if @rcode <> 0 
							begin 
								goto bspexit 
							end
   						goto INMI_loop
   					end
               end
   
   		-- allocated units expressed in std u/m
   		select @alloc = @remainunits * @umconv
   
    	-- validate Job and get JC Unit of Measure
    	exec @rcode = bspJobTypeVal @jcco, @phasegroup, @job, @phase, @jcctype, @jcum output, @errmsg output
    	if @rcode <> 0
    		begin
    		    select @errmsg = @errorhdr + @errmsg
    			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errmsg, @errmsg output
    			if @rcode <> 0 
					begin
						goto bspexit
					end
               goto INMI_loop      
    		end
 
   		-- determine conversion factor from posted UM to JC UM
   		select @jcumconv = 0
   		if isnull(@jcum,'') = @um 
			begin
				select @jcumconv = 1
			end
   		if isnull(@jcum,'') <> @um
   			begin
   				exec @rcode = bspHQStdUMGet @matlgroup, @material, @jcum, @jcumconv output, @stdum output, @errmsg output
   				if @rcode <> 0
   					begin
   						select @errmsg = @errorhdr + ' - ' + @errmsg
   						exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errmsg, @errmsg output
   						if @rcode <> 0 
							begin 
								goto bspexit 
							end
   						goto INMI_loop
   					end
   				if @jcumconv <> 0
					begin
						 select @jcumconv = @umconv / @jcumconv
					end
   			end
   
   		-- remaining committed units expressed in JC UM
   		select @jcunits = @remainunits * @jcumconv	
   		
   		-- get Tax Phase, and Cost Type
   		select @taxrate = 0, @taxphase = null, @taxjcct = null
   		if @taxcode is not null
   			begin
   				exec @rcode = bspHQTaxRateGet @taxgroup, @taxcode, @closedate, @taxrate output, @taxphase output,
   				@taxjcct output, @errmsg output
   				if @rcode <> 0
   					begin
   						select @errmsg = @errorhdr + ' - ' + @errmsg
   						exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errmsg, @errmsg output
   						if @rcode <> 0 
							begin 
								goto bspexit
							end
   						goto INMI_loop
   					end
   			end
      		-- set Tax Phase and Cost Type, calculate remaining Tax Amount
   		if @taxphase is null 
			begin
				select @taxphase = @phase
			end
		set @taxamt = 0	--136015
   		if @taxjcct is null
			begin
				select @taxjcct = @jcctype
		   		select @taxamt = @remaincost * @taxrate
   			end
    	-- add JC Distribution, reductions to remaining units and costs stored as negative values 
   		select @remcmtdcost = @remaincost
   		if @taxphase = @phase and @taxjcct = @jcctype 
			begin
				select @remcmtdcost = @remaincost + @taxamt  -- include tax if not redirected

    			insert bINXJ(INCo, Mth, BatchId, BatchSeq, JCCo, Job, PhaseGroup, Phase, JCCType,  MOItem,
               MO, Loc, MatlGroup, Material, Description, ActDate, UM, RemainUnits, JCUM, JCRemCmtdUnits, RemCmtdCost)
    			values(@co, @mth, @batchid, @seq, @jcco, @job, @phasegroup, @phase, @jcctype,  @moitem,
    			@mo, @loc, @matlgroup, @material, @description, @closedate, @um, -(@remainunits),
   				@jcum, -(@jcunits), -(@remcmtdcost))
			end   
   		if @taxamt <> 0 and (@taxphase <> @phase or @taxjcct <> @jcctype)	-- tax is redirected
   			begin
   				-- add JC distribution for remaining tax, no units
   				insert bINXJ(INCo, Mth, BatchId, BatchSeq, JCCo, Job, PhaseGroup, Phase, JCCType, MOItem,
               	MO, Loc, MatlGroup, Material, Description, ActDate, UM, RemainUnits, JCUM, JCRemCmtdUnits, RemCmtdCost)
    			values(@co, @mth, @batchid, @seq, @jcco, @job, @phasegroup, @taxphase, @taxjcct, @moitem,
    			@mo, @loc, @matlgroup, @material, @description, @closedate, @um, 0, @jcum, 0, -(@taxamt))
   			end
   
   		-- add IN Distribution, reductions to allocated stored as negative value
   		insert bINXI (INCo, Mth, BatchId, Loc, MatlGroup, Material, BatchSeq, MOItem,
   			MO, UM, RemainUnits, StdUM, Alloc)
   		values(@co, @mth, @batchid, @loc, @matlgroup, @material, @seq, @moitem,
   			@mo, @um, -(@remainunits), @stdum, -(@alloc))
   	
       		goto INMI_loop   -- next Item
   
   
   	INMI_end:   -- finished with Items on Material Order
    		close bcINMI
    		deallocate bcINMI
    		select @INMIcursor=0
   
   	goto INXB_loop  -- next Material Order
   
   INXB_end:       -- finished with Material Orders
    	close bcINXB
    	deallocate bcINXB
       select @INXBcursor = 0
   
   
   -- check HQ Batch Errors and update HQ Batch Control status */
   select @status = 3	-- valid - ok to post
   if exists(select * from bHQBE where Co = @co and Mth = @mth and BatchId = @batchid)
    	begin
		 	select @status = 2	-- validation errors
    	end
   update bHQBC
   set Status = @status
   where Co = @co and Mth = @mth and BatchId = @batchid
   if @@rowcount <> 1
       begin
    		select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
    		goto bspexit
    	end
   
   bspexit:
       if @INXBcursor = 1
           begin
    			close bcINXB
    			deallocate bcINXB
    		end
    	if @INMIcursor = 1
    		begin
    			close bcINMI
    			deallocate bcINMI
    		end
   
--   	if @rcode <> 0 
--		Begin 
--			select @errmsg
--		End
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINXBVal] TO [public]
GO
