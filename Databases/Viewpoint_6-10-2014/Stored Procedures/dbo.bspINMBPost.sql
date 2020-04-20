SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   procedure [dbo].[bspINMBPost]
   /***********************************************************
    * Created:  GG  03/14/02
    * Modified: CMW 04/04/02 - added bHQBC.Notes interface levels update (issue # 16692).
    *           RM 04/09/02 - Removed @trans parameter from bspBatchUserMemoUpdate call (#16702)
    *			 GG 06/04/02 - #17529 - Set bINMI.RemainingUnits to 0.00 prior to delete
    *			 GG 06/25/02 - #17735 - Clear bINMO.MthClosed when MO Header is reopened
    *          GWC 04/01/04 - #18616 - Re-index Attachments
    *                       - added dbo. in front of stored procedure calls 
    *			DC 10/28/08 - #130750 - Remove Committed Cost Flag
	*			GP 11/25/08 - 131225, fixed error dealing with remaining units by deleting from bINMI table.
	*			GP 12/19/08 - 131508, changed all transactions to work from the tables instead of the views.
	*			GP 05/15/09 - 133436 Removed HQAT code
    *
    * Usage:
    * Posts a validated Material Order Entry batch.  Updates IN
    * Material Order tables, allocates Materials, and posts committed
    * units and costs to JC.
    *
    * Inputs:
    *  @co           	IN Co#
    *  @mth          	Month of batch
    *  @batchid      	Batch ID
    *  @dateposted   	Posting date
    *	@source			Batch source - 'MO Entry' or 'PM Intrfce'
    *
    * Outputs:
    *  @errmsg     	error message
    *
    * Returns:
    *  @rcode			0 = success, 1 = error
    *
    *****************************************************/
     	(@co bCompany = null, @mth bMonth = null, @batchid bBatchID = null,
   	 @dateposted bDate = null, @source varchar(10) = null, @errmsg varchar(255) output)
   
   as
   set nocount on
   
   declare @rcode int, @opencursor tinyint, @opencursorINJC tinyint, @status tinyint, --DC #130750  @cmtddetailtojc bYN,
   	@seq int, @transtype char(1), @mo bMO, @guid uniqueidentifier, @errorstart varchar(20), @itemcount int,
   	@jcco bCompany, @job bJob, @phasegroup bGroup, @phase bPhase, @jcctype bJCCType, @moitem bItem,
   	@oldnew tinyint, @orderedunits bUnits, @totalcmtdcost bDollar, @remaincmtdcost bDollar, @jcunits bUnits,
   	@jcremainunits bUnits, @jctrans bTrans, @Notes varchar(256)
   
   select @rcode = 0, @opencursor = 0, @opencursorINJC = 0
   
   -- check for date posted
   if @dateposted is null
   	begin
   	select @errmsg = 'Missing Posting Date!', @rcode = 1
   	goto bspexit
   	end
   
   -- validate HQ Batch
   exec @rcode = dbo.bspHQBatchProcessVal @co, @mth, @batchid, @source, 'INMB', @errmsg output, @status output
   if @rcode <> 0 goto bspexit
   if @status <> 3 and @status <> 4	-- valid - OK to post, or posting in progress
       begin
       select @errmsg = 'Invalid Batch status -  must be (valid - OK to post) or (posting in progress)!', @rcode = 1
       goto bspexit
       end
   
   -- set HQ Batch status to 4 (posting in progress)
   update dbo.bHQBC
   set Status = 4, DatePosted = @dateposted
   where Co = @co and Mth = @mth and BatchId = @batchid
   if @@rowcount = 0
       begin
       select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
       goto bspexit
       end
   
   -- declare cursor on MO Header Batch
   declare bcINMB cursor for
   select BatchSeq, BatchTransType, MO, UniqueAttchID
   from dbo.bINMB
   where Co = @co and Mth = @mth and BatchId = @batchid
   
   open bcINMB
   select @opencursor = 1
   
   -- loop through all MO Headers in the batch
   mo_posting_loop:
   	fetch next from bcINMB into @seq, @transtype, @mo, @guid
   
       if @@fetch_status <> 0 goto mo_posting_end
   
       select @errorstart = 'Seq#: ' + convert(varchar(6),@seq)
   
       begin transaction
   
   	if @transtype = 'A'		-- new entry
   		begin
   		-- add Material Order Header
          	insert dbo.bINMO (INCo, MO, Description, JCCo, Job, OrderDate, OrderedBy, Status, AddedMth,
   			AddedBatchId, Purge, Notes, UniqueAttchID)
   		select Co, MO, Description, JCCo, Job, OrderDate, OrderedBy, Status, Mth,
   			BatchId, 'N', Notes, UniqueAttchID
   		from dbo.bINMB with(nolock)
   		where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
   		if @@rowcount <> 1
   			begin
   			select @errmsg = @errorstart + ' - Unable to add Material Order Header!'
   			goto mo_posting_error
   			end
   
   		-- get Item count
   		select @itemcount = count(*) from dbo.bINIB with(nolock)
   		where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
           -- add Mateial Order Items
           insert dbo.bINMI (INCo, MO, MOItem, Loc, MatlGroup, Material, Description, JCCo, Job, PhaseGroup,
   			Phase, JCCType, GLCo, GLAcct, ReqDate, UM, OrderedUnits, UnitPrice, ECM, TotalPrice,
   			TaxGroup, TaxCode, TaxAmt, ConfirmedUnits, RemainUnits, PostedDate, AddedMth, AddedBatchId, Notes)
   		select Co, @mo, MOItem, Loc, MatlGroup, Material, Description, JCCo, Job, PhaseGroup,
   			Phase, JCCType, GLCo, GLAcct, ReqDate, UM, OrderedUnits, UnitPrice, ECM, TotalPrice,
   			TaxGroup, TaxCode, TaxAmt, 0, OrderedUnits, @dateposted, Mth, BatchId, Notes
   		from dbo.bINIB with(nolock)
   		where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
   		if @@rowcount <> @itemcount
   			begin
   			select @errmsg = @errorstart + ' - Unable to add Material Order Item(s)!'
   			goto mo_posting_error
   			end
   		end
   
   	if @transtype = 'C'	-- update existing MOs
           begin
   		-- update Material Order Header
           update dbo.bINMO
           set Description = b.Description, JCCo = b.JCCo, Job = b.Job, OrderDate = b.OrderDate,
   			OrderedBy = b.OrderedBy, Status = b.Status,
               MthClosed = case b.Status when 2 then o.MthClosed else null end,    -- clear Mth Closed if not 'Closed'
    			InUseMth = null, InUseBatchId = null, Notes = b.Notes, UniqueAttchID = b.UniqueAttchID
   		from dbo.bINMO o with(nolock)
   		join dbo.bINMB b with(nolock)on o.INCo = b.Co and o.MO = b.MO
           where b.Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @seq
           if @@rowcount <> 1
   			begin
               select @errmsg = @errorstart + ' - Unable to update Material Order Header.'
               goto mo_posting_error
               end
   
   		-- get count for 'add' Items
   		select @itemcount = count(*) from dbo.bINIB with(nolock)
   		where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq and BatchTransType = 'A'
           -- add all 'add' Items
   		insert dbo.bINMI (INCo, MO, MOItem, Loc, MatlGroup, Material, Description, JCCo, Job, PhaseGroup,
   			Phase, JCCType, GLCo, GLAcct, ReqDate, UM, OrderedUnits, UnitPrice, ECM, TotalPrice,
   			TaxGroup, TaxCode, TaxAmt, ConfirmedUnits, RemainUnits, PostedDate, AddedMth, AddedBatchId, Notes)
   		select Co, @mo, MOItem, Loc, MatlGroup, Material, Description, JCCo, Job, PhaseGroup,
   			Phase, JCCType, GLCo, GLAcct, ReqDate, UM, OrderedUnits, UnitPrice, ECM, TotalPrice,
   			TaxGroup, TaxCode, TaxAmt, 0, OrderedUnits, @dateposted, Mth, BatchId, Notes
   		from dbo.bINIB with(nolock)
   		where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq and BatchTransType = 'A'
   		if @@rowcount <> @itemcount
   			begin
   			select @errmsg = @errorstart + ' - Unable to add new Material Order Item(s)!'
   			goto mo_posting_error
   			end
   
   		-- get count for 'change' Items
   		select @itemcount = count(*) from dbo.bINIB with(nolock)
   		where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq and BatchTransType = 'C'
           -- update all 'change' Items
           update dbo.bINMI
      		set Loc = b.Loc, MatlGroup = b.MatlGroup, Material = b.Material, Description = b.Description,
   			JCCo = b.JCCo, Job = b.Job, PhaseGroup = b.PhaseGroup, Phase = b.Phase, JCCType = b.JCCType,
   			GLCo = b.GLCo, GLAcct = b.GLAcct, ReqDate = b.ReqDate, UM = b.UM, OrderedUnits = b.OrderedUnits,
   			UnitPrice = b.UnitPrice, ECM = b.ECM, TotalPrice = b.TotalPrice, TaxGroup = b.TaxGroup,
   			TaxCode = b.TaxCode, TaxAmt = b.TaxAmt, RemainUnits = b.RemainUnits, PostedDate = @dateposted,
   			Notes = b.Notes
   		from dbo.bINMI i with(nolock)
   		join dbo.bINIB b with(nolock)on i.INCo = b.Co and i.MOItem = b.MOItem
   		where b.Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @seq
                and i.MO = @mo and b.BatchTransType = 'C'
   		if @@rowcount <> @itemcount
   			begin
   			select @errmsg = @errorstart + ' - Unable to update Material Order Item(s)!'
   			goto mo_posting_error
   			end
   
   		-- get count for 'deleted' Items
   		select @itemcount = count(*) from dbo.bINIB with(nolock)
   		where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq and BatchTransType = 'D'
   
   		-- set Remaining Units to 0.00 for all Items to be deleted, required to pass trigger validation
   		update dbo.bINMI set RemainUnits = 0
   		from dbo.bINMI i with(nolock)
           join dbo.bINIB b with(nolock) on i.INCo = b.Co and i.MOItem = b.MOItem
   		where b.Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @seq
                and i.MO = @mo and b.BatchTransType = 'D'
   		if @@rowcount <> @itemcount
   			begin
   			select @errmsg = @errorstart + ' - Unable to update Material Order Item(s) prior to removal!'
   			goto mo_posting_error
   			end
   
           -- remove all 'delete' Items
     	    delete dbo.bINMI
           from dbo.bINMI i 
           join dbo.bINIB b on i.INCo = b.Co and i.MOItem = b.MOItem
   		where b.Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @seq
                and i.MO = @mo and b.BatchTransType = 'D'
   		if @@rowcount <> @itemcount
   			begin
   			select @errmsg = @errorstart + ' - Unable to delete Material Order Item(s)!'
   			goto mo_posting_error
   			end
            end
   
   	if @transtype = 'D'		-- Delete Material Order and all Items
   		begin
   		-- count # of Items for this batch seq
   		select @itemcount = count(*) from dbo.bINIB with(nolock)
   		where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
   		-- set Remaining Units to 0.00 for all Items, required to pass trigger validation
   		update dbo.bINMI set RemainUnits = 0
   		where INCo = @co and MO = @mo	-- update all Items
   		if @@rowcount <> @itemcount
   			begin
   			select @errmsg = @errorstart + ' - Unable to update Material Order Item(s) prior to removal!'
   			goto mo_posting_error
   			end
   		delete dbo.bINMI where INCo = @co and MO = @mo	-- remove Items
   		if @@rowcount <> @itemcount
   			begin
   			select @errmsg = @errorstart + ' - Unable to delete all Material Order Item(s)!'
   			goto mo_posting_error
   			end
   		delete dbo.bINMO where INCo = @co and MO = @mo	-- remove Header
   		if @@rowcount <> 1
   			begin
   			select @errmsg = @errorstart + ' - Unable to delete Material Order Header!'
   			goto mo_posting_error
   			end
           end
   
        -- update Interface date in PM if source is PM Intface
        if @source = 'PM Intface'
           begin
           -- update records in PMMF, set interface date
           update dbo.bPMMF set InterfaceDate=@dateposted
           from dbo.bPMMF p with(nolock) join dbo.bINIB s with(nolock)on p.INCo=s.Co and p.MOItem=s.MOItem
           where p.INCo=@co and p.Project=s.Job and p.MO=@mo and p.MOItem=s.MOItem and s.Co=@co and s.Mth=@mth and s.BatchId=@batchid
           and s.BatchSeq=@seq and p.InterfaceDate is null and p.SendFlag='Y'
           end --PM MO Interface section
   
   	-- update IN Allocations
   	exec @rcode = dbo.bspINMBPostIN @co, @mth, @batchid, @seq, @errmsg output
   	if @rcode <> 0
   		begin
   		select @errmsg = @errorstart + ' - ' + @errmsg
   		goto mo_posting_error
   		end
   
   	-- User Memo updates for MO Items
   	if @transtype in ('A','C')
   		begin
   	    exec @rcode = dbo.bspBatchUserMemoUpdate @co, @mth, @batchid, @seq, 'MO Entry Items',  @errmsg output
   		if @rcode <> 0 goto mo_posting_error
   	    end
   	-- remove Batch Item entries
   	delete dbo.bINIB where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
   
   	-- User Memo updates for MO Header
   	if @transtype in ('A','C')
   	    begin
   	    exec @rcode = dbo.bspBatchUserMemoUpdate @co, @mth, @batchid, @seq, 'MO Entry',  @errmsg output
   		if @rcode <> 0 goto mo_posting_error
   	    end
   	-- delete Batch Header
   	delete dbo.bINMB where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
      
   	commit transaction
   
      --Re-index attachments	
   	if @transtype in ('A','C')
   	begin
   		if @guid is not null
   		begin
   			exec @rcode = dbo.bspHQRefreshIndexes null, null, @guid
   		end
   	end
   	goto mo_posting_loop
   
   mo_posting_error:		-- error occured within transaction - rollback any updates and exit
       rollback transaction
   	select @rcode = 1
       goto bspexit
   
   mo_posting_end:
   	if @opencursor = 1
           begin
           close bcINMB
           deallocate bcINMB
           select @opencursor = 0
           end
   
   -- make sure batch is empty
   if exists(select 1 from dbo.bINMB with(nolock) where Co = @co and Mth = @mth and BatchId = @batchid)
   	begin
       select @errmsg = 'Not all Material Order Header entries were posted - unable to close batch!', @rcode = 1
       goto bspexit
       end
   if exists(select 1 from dbo.bINIB with(nolock) where Co = @co and Mth = @mth and BatchId = @batchid)
       begin
       select @errmsg = 'Not all Material Order Item entries were posted - unable to close batch!', @rcode = 1
       goto bspexit
       end
   
   jc_update:		-- update Committed Units and Costs to JC
   
    /*--DC #130750
    -- get Committed Detail to JC option
    select @cmtddetailtojc = CmtdDetailToJC
   	from dbo.bINCO with(nolock) where INCo = @co
   	if @@rowcount = 0
   		begin
   		select @errmsg = 'Invalid IN Co#: ' + convert(varchar,@co), @rcode = 1
   		goto bspexit
   		end
   */
   
       -- declare cursor on MO JC Distribution Batch for posting
       declare bcINJC cursor for
       select JCCo, Job, PhaseGroup, Phase, JCCType, BatchSeq,
   		MOItem, OldNew, OrderedUnits, TotalCmtdCost, RemainCmtdCost, JCUnits, JCRemainUnits
     	from dbo.bINJC with(nolock)
       where INCo = @co and Mth = @mth and BatchId = @batchid
   
       open bcINJC
       select @opencursorINJC = 1
   
   	/* loop through all rows in this batch */
       jc_posting_loop:
   		fetch next from bcINJC into @jcco, @job, @phasegroup, @phase, @jcctype, @seq,
               @moitem, @oldnew, @orderedunits, @totalcmtdcost, @remaincmtdcost, @jcunits, @jcremainunits
   
   		if @@fetch_status <> 0 goto jc_posting_end
   
           begin transaction
   
		--DC #130750
   		--if @cmtddetailtojc = 'Y' -- posting committed cost detail to JC
   		--	begin
     	        if @orderedunits <> 0  or @totalcmtdcost <> 0
       	        begin
     	            -- get next available JCCD transaction #
     	            exec @jctrans = dbo.bspHQTCNextTrans 'bJCCD', @jcco, @mth, @errmsg output
     	            if @jctrans = 0 goto jc_posting_error
   
     	    		insert dbo.bJCCD (JCCo, Mth, CostTrans, Job, PhaseGroup, Phase, CostType, PostedDate, ActualDate,
     			        JCTransType, Source, Description, BatchId, PostedUM, PostedUnits, PostTotCmUnits, PostRemCmUnits,
     			        UM, TotalCmtdUnits, TotalCmtdCost, RemainCmtdUnits, RemainCmtdCost, MO, MOItem, MatlGroup,
   					Material, INCo, Loc)
   				select JCCo, Mth, @jctrans, Job, PhaseGroup, Phase, JCCType, @dateposted, @dateposted,
   					'MO', case @source when 'MO Entry' then 'IN MatlOrd' else @source end, Description, BatchId, UM, 0, OrderedUnits, RemainUnits,
   					JCUM, JCUnits, TotalCmtdCost, JCRemainUnits, RemainCmtdCost, MO, MOItem, MatlGroup,
   					Material, INCo, Loc
   				from dbo.bINJC with(nolock)
   				where INCo = @co and Mth = @mth and BatchId = @batchid and JCCo = @jcco and Job = @job
                		and PhaseGroup = @phasegroup and Phase = @phase and JCCType = @jcctype and BatchSeq = @seq
                		and MOItem = @moitem and OldNew = @oldnew
   				if @@rowcount <> 1
   					begin
   					select @errmsg = 'Unable to add JC Detail for Committed Cost update!'
   					goto jc_posting_error
   					end
          	   end
        --  end
               
        /*--DC #130750
   		if @cmtddetailtojc = 'N'  -- committed cost updates to JC Cost By Period only
   			begin
     	        update dbo.bJCCP
     	     	set TotalCmtdUnits = TotalCmtdUnits + @jcunits, TotalCmtdCost = TotalCmtdCost + @totalcmtdcost,
     		    	RemainCmtdUnits = RemainCmtdUnits + @jcremainunits, RemainCmtdCost = RemainCmtdCost + @remaincmtdcost
     		    where JCCo = @jcco and Mth = @mth and Job  =@job and PhaseGroup = @phasegroup
                   and Phase = @phase and CostType = @jcctype
     	        if @@rowcount = 0
                   begin
                    -- add a new JCCP entry
      		  		insert dbo.bJCCP (JCCo, Job, PhaseGroup, Phase, CostType, Mth, ActualHours, ActualUnits,
     			        ActualCost, OrigEstHours, OrigEstUnits, OrigEstCost, CurrEstHours, CurrEstUnits,
     			        CurrEstCost, ProjHours, ProjUnits, ProjCost, ForecastHours, ForecastUnits, ForecastCost,
     			        TotalCmtdUnits, TotalCmtdCost, RemainCmtdUnits, RemainCmtdCost,	RecvdNotInvcdUnits, RecvdNotInvcdCost)
     		        values (@jcco, @job, @phasegroup, @phase, @jcctype, @mth, 0, 0, 0, 0, 0, 0, 0, 0, 0,
     			        0, 0, 0, 0, 0, 0, @jcunits, @totalcmtdcost, @jcremainunits, @remaincmtdcost, 0, 0)
                   end
            end
        */    
               
   
   		-- remove JC distribution entry from batch
           delete dbo.bINJC
           where INCo = @co and Mth = @mth and BatchId = @batchid and JCCo = @jcco and Job = @job
               and PhaseGroup = @phasegroup and Phase = @phase and JCCType = @jcctype and BatchSeq = @seq
               and MOItem=@moitem and OldNew = @oldnew
     	    if @@rowcount <> 1
               begin
     	        select @errmsg = 'Error removing JC distribution from batch.'
               goto jc_posting_error
      	        end
   
           commit transaction
   
           goto jc_posting_loop
   
   	jc_posting_error:
           rollback transaction
   		select @rcode = 1
           goto bspexit
   
       jc_posting_end:
           if @opencursorINJC=1
           	begin
               close bcINJC
               deallocate bcINJC
   
               select @opencursorINJC = 0
               end
   
   -- check for unposted JC distributions
   if exists(select 1 from dbo.bINJC with(nolock) where INCo = @co and Mth = @mth and BatchId = @batchid)
        begin
        select @errmsg = 'Not all JC distributions were posted - unable to close batch!', @rcode = 1
        goto bspexit
        end
   
   -- set interface levels note string
       select @Notes=Notes from dbo.bHQBC with(nolock)
       where Co = @co and Mth = @mth and BatchId = @batchid
       if @Notes is NULL select @Notes='' else select @Notes=@Notes + char(13) + char(10)
       select @Notes=@Notes +
           'GL Adjustment Interface Level set at: ' + convert(char(1), a.GLAdjInterfaceLvl) + char(13) + char(10) +
           'GL Transfer Interface Level set at: ' + convert(char(1), a.GLTrnsfrInterfaceLvl) + char(13) + char(10) +
           'GL Production Interface Level set at: ' + convert(char(1), a.GLProdInterfaceLvl) + char(13) + char(10) +
           'GL MO Interface Level set at: ' + convert(char(1), a.GLMOInterfaceLvl) + char(13) + char(10) +
           'JC MO Interface Level set at: ' + convert(char(1), a.JCMOInterfaceLvl) + char(13) + char(10)
       from dbo.bINCO a with(nolock) where INCo=@co
   
   -- delete HQ Close Control entries
   delete dbo.bHQCC where Co = @co and Mth = @mth and BatchId = @batchid
   
   -- set HQ Batch status to 5 (posted)
   update dbo.bHQBC
   set Status = 5, DateClosed = getdate(), Notes = convert(varchar(max),@Notes)
   where Co = @co and Mth = @mth and BatchId = @batchid
   if @@rowcount = 0
       begin
     	select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
     	goto bspexit
     	end
   
   bspexit:
     	if @opencursor = 1
     		begin
     		close bcINMB
     		deallocate bcINMB
     		end
     	if @opencursorINJC = 1
     		begin
     		close bcINJC
     		deallocate bcINJC
     		end
   
   --    if @rcode<>0 select @errmsg
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINMBPost] TO [public]
GO
