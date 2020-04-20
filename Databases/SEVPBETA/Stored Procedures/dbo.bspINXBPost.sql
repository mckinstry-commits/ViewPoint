SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    procedure [dbo].[bspINXBPost]
   /************************************************************************
   * Created: GG 04/30/02
   * Modified:
   * 
   * Usage:          
   * 	Posts a validated batch of Material Order Close entries.  
   *	Relieves committed units and costs in JC, allocated units in IN,
   *	and updates MO Items (set RemainUnits = 0) and Header (Status = 2)
   *
   * Inputs:
   *	@co				IN Company #
   *	@mth			Month
   *	@batchid		Batch ID#
   *	@dateposted		Date posted
   *
   * Outputs:
   *	@errmsg		Error message
   *
   * Return code:
   *	0 = success, 1 = error
   *
   ************************************************************************/
   
   	(@co bCompany, @mth bMonth, @batchid bBatchID, @dateposted bDate = null,
   	 @errmsg varchar(255) output)
   
   as
   set nocount on
   
   declare @rcode int, @status tinyint, --DC #130750  @cmtddetailtojc bYN, 
	@INXJcursor tinyint, @jcco bCompany,
   	@job bJob, @phasegroup bGroup, @phase bPhase, @jcctype bJCCType, @seq int,@moitem bItem,
   	@mo bMO, @loc bLoc, @matlgroup bGroup, @material bMatl, @description bDesc, @actdate bDate,
   	@um bUM, @remainunits bUnits, @jcum bUM, @remcmtdunits bUnits, @remcmtdcost bDollar,
   	@jctrans bTrans, @INXIcursor tinyint, @alloc bUnits, @INXBcursor tinyint, @Notes varchar(256)
   
   select @rcode = 0
   
   /* check for date posted */
   if @dateposted is null
   	begin
   	select @errmsg = 'Missing posting date!', @rcode = 1
   	goto bspexit
   	end
   /* validate HQ Batch */
   exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, 'MO Close', 'INXB', @errmsg output,
   	@status output
   if @rcode <> 0 goto bspexit
   if @status <> 3 and @status <> 4	-- valid - OK to post, or posting in progress 
   	begin
   	select @errmsg = 'Invalid Batch status -  must be ''valid - OK to post'' or ''posting
   		 in progress''', @rcode = 1
   	goto bspexit
   	end
   /* set HQ Batch status to 4 (posting in progress) */
   update bHQBC
   set Status = 4, DatePosted = @dateposted
   where Co = @co and Mth = @mth and BatchId = @batchid
   if @@rowcount = 0
   	begin
   	select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
   	goto bspexit
   	end
   
   -- process JC distributions to relieve committed units and costs
   
   /*--DC #130750
   -- get JC Committed Cost update level from IN Company
   select @cmtddetailtojc = CmtdDetailToJC
   from bINCO
   where INCo = @co
   if @@rowcount=0
   	begin
   	select @errmsg = 'Invalid IN Company!', @rcode = 1
   	goto bspexit
   	end
   */
   
   -- use a cursor to process JC Distributions
   declare bcINXJ cursor for
   select JCCo, Job, PhaseGroup, Phase, JCCType, BatchSeq, MOItem, MO,
   	Loc, MatlGroup, Material, Description, ActDate, UM, RemainUnits,
   	JCUM, JCRemCmtdUnits, RemCmtdCost
   from bINXJ
   where INCo = @co and Mth = @mth and BatchId = @batchid 
   
   open bcINXJ
   select @INXJcursor = 1
   
   -- loop through JC distributions
   INXJ_loop:
   	fetch next from bcINXJ into @jcco, @job, @phasegroup, @phase, @jcctype, @seq,
   		@moitem, @mo, @loc, @matlgroup, @material, @description, @actdate, @um,
   		@remainunits, @jcum, @remcmtdunits, @remcmtdcost 
   
   	if  @@fetch_status <> 0 goto INXJ_end
   
   	begin transaction
   
   --DC #130750
   --	if @cmtddetailtojc = 'Y' -- committed cost update in detail
   --		begin
   		if @remainunits <> 0 or @remcmtdunits <> 0 or @remcmtdcost <> 0
   			begin
   			-- get next available transaction 
   			exec @jctrans = bspHQTCNextTrans 'bJCCD', @jcco, @mth, @errmsg output
   			if @jctrans = 0 goto INXJ_error
   	
   			insert bJCCD (JCCo, Mth, CostTrans, Job, PhaseGroup, Phase, CostType, PostedDate, ActualDate,
   	  			JCTransType, Source, Description, BatchId, PostedUM, PostedUnits, PostTotCmUnits, PostRemCmUnits,
   	  			UM, TotalCmtdUnits, TotalCmtdCost, RemainCmtdUnits, RemainCmtdCost, MO, MOItem, MatlGroup,
   				Material, INCo, Loc)
   			select JCCo, Mth, @jctrans, Job, PhaseGroup, Phase, JCCType, @dateposted, ActDate,
   				'MO', 'IN MatlOrd', Description, BatchId, UM, 0, RemainUnits, RemainUnits,
   				JCUM, JCRemCmtdUnits, RemCmtdCost, JCRemCmtdUnits, RemCmtdCost, MO, MOItem, MatlGroup,
   				Material, INCo, Loc
   			from bINXJ
   			where INCo = @co and Mth = @mth and BatchId = @batchid and JCCo = @jcco and Job = @job
   	             and PhaseGroup = @phasegroup and Phase = @phase and JCCType = @jcctype and BatchSeq = @seq
   	             and MOItem = @moitem 
   			if @@rowcount <> 1
   				begin
   				select @errmsg = 'Unable to add JC Detail for Committed Cost update!'
   				goto INXJ_error
   				end
   			end
   	--	end
   
   /*--DC #130750
   	if @cmtddetailtojc = 'N'  -- committed cost updates to JC Cost By Period only
   		begin
     	    update bJCCP
     	    set TotalCmtdUnits = TotalCmtdUnits + @remcmtdunits, TotalCmtdCost = TotalCmtdCost + @remcmtdcost,
     		    RemainCmtdUnits = RemainCmtdUnits + @remcmtdunits, RemainCmtdCost = RemainCmtdCost + @remcmtdcost
     		where JCCo = @jcco and Mth = @mth and Job = @job and PhaseGroup = @phasegroup
               and Phase = @phase and CostType = @jcctype
     	    if @@rowcount = 0
               begin
               -- add a new JCCP entry
      		  	insert bJCCP (JCCo, Job, PhaseGroup, Phase, CostType, Mth, ActualHours, ActualUnits,
     				ActualCost, OrigEstHours, OrigEstUnits, OrigEstCost, CurrEstHours, CurrEstUnits,
     			    CurrEstCost, ProjHours, ProjUnits, ProjCost, ForecastHours, ForecastUnits, ForecastCost,
     			    TotalCmtdUnits, TotalCmtdCost, RemainCmtdUnits, RemainCmtdCost,	RecvdNotInvcdUnits, RecvdNotInvcdCost)
     		    values (@jcco, @job, @phasegroup, @phase, @jcctype, @mth, 0, 0, 0, 0, 0, 0, 0, 0, 0,
     			    0, 0, 0, 0, 0, 0, @remcmtdunits, @remcmtdcost, @remcmtdunits, @remcmtdcost, 0, 0)
               end
        end
     */
   
   	-- remove JC distribution entry from batch
   	delete bINXJ
   	where INCo = @co and Mth = @mth and BatchId = @batchid and JCCo = @jcco and Job = @job
   	    and PhaseGroup = @phasegroup and Phase = @phase and JCCType = @jcctype and BatchSeq = @seq
   	    and MOItem = @moitem 
   	if @@rowcount <> 1
   	    begin
   	    select @errmsg = 'Unable to remove JC distribution from batch.'
   	    goto INXJ_error
   	    end
   
       commit transaction
   
       goto INXJ_loop
   
   INXJ_error:
       rollback transaction
   	select @rcode = 1
       goto bspexit
   
   INXJ_end:
       close bcINXJ
       deallocate bcINXJ
       select @INXJcursor = 0
   
   -- Process Inventory updates to relieve allocated units 
   -- use a cursor to process IN Distributions
   declare bcINXI cursor for
   select Loc, MatlGroup, Material, BatchSeq, MOItem, MO, Alloc
   from bINXI
   where INCo = @co and Mth = @mth and BatchId = @batchid 
   
   open bcINXI
   select @INXIcursor = 1
   
   -- loop through IN distributions
   INXI_loop:
   	fetch next from bcINXI into @loc, @matlgroup, @material, @seq, @moitem, @mo, @alloc
   
   	if  @@fetch_status <> 0 goto INXI_end
   
   	begin transaction
   
   	-- update allocated units
   	update bINMT set Alloc = Alloc + @alloc
   	where INCo = @co and Loc = @loc and MatlGroup = @matlgroup and Material = @material
   	if @@rowcount <> 1
   		begin
   		select @errmsg = 'Invalid Location: ' + @loc + ' Material: ' + @material + ' - unable to adjust allocated units.'
   	    goto INXI_error
   	    end
   
   	-- remove IN distribution entry from batch
   	delete bINXI
   	where INCo = @co and Mth = @mth and BatchId = @batchid and Loc = @loc and MatlGroup = @matlgroup
   	    and Material = @material and BatchSeq = @seq and MOItem = @moitem 
   	if @@rowcount <> 1
   	    begin
   	    select @errmsg = 'Unable to remove IN distribution from batch.'
   	    goto INXI_error
   	    end
   
       commit transaction
   
       goto INXI_loop
   
   INXI_error:
       rollback transaction
   	select @rcode = 1
       goto bspexit
   
   INXI_end:
       close bcINXI
       deallocate bcINXI
       select @INXIcursor = 0
   	
   -- Process MO Close Batch entries to update MO Items and MO Header 
   -- use a cursor to process MO Close batch entries
   declare bcINXB cursor for
   select BatchSeq, MO
   from bINXB
   where Co = @co and Mth = @mth and BatchId = @batchid 
   
   open bcINXB
   select @INXBcursor = 1
   
   -- loop through batch entries
   INXB_loop:
   	fetch next from bcINXB into @seq, @mo
   
   	if  @@fetch_status <> 0 goto INXB_end
   
   	begin transaction
   
   	-- update MO Items
   	update bINMI set RemainUnits = 0, PostedDate = @dateposted
   	where INCo = @co and MO = @mo
   	
   	-- update MO Header
   	update bINMO set Status = 2, MthClosed = @mth
   	where INCo = @co and MO = @mo
   	if @@rowcount <> 1
   	    begin
   	    select @errmsg = 'Unable to close Material Order header.'
   	    goto INXB_error
   	    end
   	-- remove IN distribution entry from batch
   	delete bINXB
   	where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq 
   	if @@rowcount <> 1
   	    begin
   	    select @errmsg = 'Unable to remove MO Close Batch entry.'
   	    goto INXB_error
   	    end
   
       commit transaction
   
       goto INXB_loop
   
   INXB_error:
       rollback transaction
   	select @rcode = 1
       goto bspexit
   
   INXB_end:
       close bcINXB
       deallocate bcINXB
       select @INXBcursor = 0
   
   -- finished with updates, make sure batch is empty
   if exists(select 1 from bINXJ where INCo = @co and Mth = @mth and BatchId = @batchid)
   	begin
   	select @errmsg = 'Not all JC distributions were posted - unable to close batch!', @rcode = 1
   	goto bspexit
   	end
   if exists(select 1 from bINXI where INCo = @co and Mth = @mth and BatchId = @batchid)
   	begin
   	select @errmsg = 'Not all IN distributions were posted - unable to close batch!', @rcode = 1
   	goto bspexit
   	end
   if exists(select 1 from bINXB where Co = @co and Mth = @mth and BatchId = @batchid)
   	begin
   	select @errmsg = 'Not all batch entries were posted - unable to close batch!', @rcode = 1
   	goto bspexit
   	end
   
   -- set interface levels note string
   select @Notes=Notes from bHQBC
   where Co = @co and Mth = @mth and BatchId = @batchid
   if @Notes is NULL select @Notes='' else select @Notes=@Notes + char(13) + char(10)
   select @Notes=@Notes +
       'JC Committed Detail Interface: Y'  --DC #130750  + convert(char(1), a.CmtdDetailToJC) + char(13) + char(10)
   --from bINCO a where INCo=@co  DC #130750
   
   /* delete HQ Close Control entries */
   delete bHQCC where Co = @co and Mth = @mth and BatchId = @batchid
   
   /* set HQ Batch status to 5 (posted) */
   update bHQBC
   set Status = 5, DateClosed = getdate(), Notes = convert(varchar(max),@Notes)
   where Co = @co and Mth = @mth and BatchId = @batchid
   if @@rowcount = 0
   	begin
   	select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
   	goto bspexit
   	end
   
   bspexit:
   	if @INXJcursor = 1
   		begin
   		close bcINXJ
   		deallocate bcINXJ
   		end
   	if @INXIcursor = 1
   		begin
   		close bcINXI
   		deallocate bcINXI
   		end
   	if @INXBcursor = 1
   		begin
   		close bcINXB
   		deallocate bcINXB
   		end
   	
   --	if @rcode <> 0 select @errmsg
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINXBPost] TO [public]
GO
