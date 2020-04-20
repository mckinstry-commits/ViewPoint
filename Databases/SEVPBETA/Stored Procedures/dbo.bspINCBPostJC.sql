SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    procedure [dbo].[bspINCBPostJC]
    /***********************************************************
     * Created: GG 04/13/02
     * Modified: GG 03/31/03 - #20719 - fix JC committed cost update
     *      		TRL 08/03/05 - # 28448 - Add TaxBasis Field to INJC
     *				DANF 09/29/2005 - Issue 28992 burden posted unit cost
     *              TRL 07/31/07  added With(nolock) and dbo. 
     *				DC 10/28/08 - #130750 - Removed Committed Cost Flag
     *
     *
     * Usage:
     * Called from the bspINCBPost procedure to post JC distributions
     * tracked in bINCJ.  MO interface level to JC is assigned in IN Company.
     * Even if the JC Interface level is set at 0 (none), committed units and
     * costs must be updated to JC for MOs.
     *
     * Interface levels:
     *  0       No update of actual units or costs to JC, but will still update
     *          total and remaining committed units and costs to bJCCP.
     *  1       Interface at the transaction level.  Each confirmation entry
     *          creates a JCCD entry.
     *  2       Interface at the summary level.  All confirmations posted to 
     *			the same Job, Phase, CostType, MO, UM, Tax Code, and JCUM will
     *			be summarized into a single JCCD entry.  MO Item and material
     *			specific info not included.
     *
     * INPUT PARAMETERS
     *   @co            IN Co#
     *   @mth           Batch month
     *   @batchid       Batch ID#
     *   @dateposted    Posting date
     *
     * OUTPUT PARAMETERS
     *   @errmsg        Message used for errors
     *
     * RETURN VALUE
     *   0              success
     *   1              fail
     *****************************************************/
    
    	(@co bCompany = null, @mth bMonth = null, @batchid bBatchID = null, 
    	@dateposted bDate = null, @errmsg varchar(255) output)
    as
    
    set nocount on
    
    declare @rcode int,	@jcmointerfacelvl tinyint, -- DC #130750  @cmtddetailtojc bYN, 
		@jcco bCompany, @openINCJcursor tinyint,
    	@job bJob, @phasegroup bGroup, @phase bPhase, @jcctype bJCCType, @seq int, @oldnew tinyint,
    	@mo bMO, @moitem bItem, @loc bLoc, @matlgroup bGroup, @material bMatl, @um bUM, @confirmdate bDate,
    	@description bDesc, @confirmunits bUnits, @remainunits bUnits, @unitprice bUnitCost, @ecm bECM,
    	@confirmtotal bDollar, @taxgroup bGroup, @taxcode bTaxCode, @taxamt bDollar, @stkum bUM,
    	@stkunitcost bUnitCost, @stkecm bECM, @jcum bUM, @jcconfirmunits bUnits, @jcremunits bUnits,
    	@jctotalcmtdcost bDollar, @jcremcmtdcost bDollar, @glco bCompany, @glacct bGLAcct,
    	@jcunitcost bUnitCost, @perecm bECM, @jcunits bUnits, @actualunits bUnits, @taxtype tinyint,
    	@taxbasis bDollar, @jctrans bTrans, @openLvl0cursor tinyint, @openLvl1cursor tinyint, @openLvl2cursor tinyint
    
    
    select @rcode = 0
    
    -- get interface levels
    select --DC #130750  @cmtddetailtojc = CmtdDetailToJC, 
			@jcmointerfacelvl = JCMOInterfaceLvl
    from dbo.INCO with(nolock) where INCo = @co
    if @@rowcount = 0
    	begin
    	select @errmsg = 'Invalid IN Co#!', @rcode = 1
    	goto bspexit
    	end
    
    -- if updating Committed in Detail, process Actuals with Committed at this level
    --DC #130750
    --if @cmtddetailtojc = 'Y'
    	--begin
    	declare bcINCJ cursor for
    	select JCCo, Job, PhaseGroup, Phase, JCCType, BatchSeq, OldNew,
    		MO, MOItem, Loc, MatlGroup, Material, UM, ConfirmDate, Description, ConfirmUnits,
    		RemainUnits, UnitPrice, ECM, ConfirmTotal, TaxGroup, TaxCode, TaxAmt, TaxBasis,/*Issue 28448*/StkUM,
    		StkUnitCost, StkECM, JCUM, JCConfirmUnits, JCRemUnits, JCTotalCmtdCost, JCRemainCmtdCost
    	from dbo.INCJ with (nolock)
    	where INCo = @co and Mth = @mth and BatchId = @batchid
    
    	open bcINCJ
    	select @openINCJcursor = 1
    
    	-- process each JC Distribution entry
    	INCJ_posting_loop:
    		fetch next from bcINCJ into @jcco, @job, @phasegroup, @phase, @jcctype, @seq, @oldnew,
    			@mo, @moitem, @loc, @matlgroup, @material, @um, @confirmdate, @description, @confirmunits,
    			@remainunits, @unitprice, @ecm, @confirmtotal, @taxgroup, @taxcode, @taxamt, @taxbasis /*Issue 28448*/, @stkum,
    			@stkunitcost, @stkecm, @jcum, @jcconfirmunits, @jcremunits, @jctotalcmtdcost, @jcremcmtdcost
    
    		if @@fetch_status <> 0 goto INCJ_posting_end
    
    		-- get JC Expense GL Account from MO Item 
    		select @glco = GLCo, @glacct = GLAcct
    		from dbo.INMI with (nolock) where INCo = @co and MO = @mo and MOItem = @moitem
    		if @@rowcount = 0
    			begin
    			select @errmsg = 'Invalid Material Order Item!', @rcode = 1
    			goto bspexit
    			end
    
    		-- calculate actual unit cost in JC U/M - will include tax unless redirected
    		select @jcunitcost = 0, @perecm = null, @jcunits = @jcconfirmunits, @actualunits = @confirmunits
    		if @jcconfirmunits <> 0 select @jcunitcost = (@confirmtotal / @jcconfirmunits), @perecm = 'E'
    		
   		-- set Tax info
    		select @taxtype = null --, @taxbasis = 0 Issue 28448
    		if @taxcode is not null select /*@taxbasis = @confirmtotal - @taxamt, Issue 28448*/ @taxtype = 2	-- use tax
   
    		-- issue 28992 burden posted unit cost
   		if isnull(@taxamt,0)<>0 and isnull(@confirmunits,0)<>0 select @unitprice = @confirmtotal/@confirmunits
   
    		if @jcmointerfacelvl = 0      -- not interfacing Actuals, set values to 0
    	        begin
    	        select @jcunitcost = 0, @perecm = null, @jcunits = 0, @confirmtotal = 0, @actualunits = 0,
    				@unitprice = 0, @ecm = null, @stkunitcost = 0, @stkecm = null, @taxbasis = 0, @taxamt = 0, @taxtype = null
            	end
     		 
    		begin transaction
    
    		-- get next available transaction # for bJCCD
    		exec @jctrans = bspHQTCNextTrans 'bJCCD', @jcco, @mth, @errmsg output
    		if @jctrans = 0 goto INCJ_posting_error
    			
    		-- add JC Cost Detail
    		insert dbo.JCCD (JCCo, Mth, CostTrans, Job, PhaseGroup, Phase, CostType, PostedDate, ActualDate,
    		    JCTransType, Source, Description, BatchId, GLCo, GLTransAcct, UM, ActualUnitCost,
    			PerECM, ActualUnits, ActualCost, PostedUM, PostedUnits, PostedUnitCost, PostedECM, PostTotCmUnits,
    			PostRemCmUnits, TotalCmtdUnits, TotalCmtdCost, RemainCmtdUnits, RemainCmtdCost, MO, MOItem,
    			MatlGroup, Material, INCo, Loc, INStdUnitCost, INStdECM, INStdUM, TaxType, TaxGroup,
    			TaxCode, TaxBasis, TaxAmt)
    		values (@jcco, @mth, @jctrans, @job, @phasegroup, @phase, @jcctype, @dateposted, @confirmdate,
    			'MO', 'IN MatlOrd', @description, @batchid, @glco, @glacct, @jcum, @jcunitcost,
    			@perecm, @jcunits, @confirmtotal, @um, @actualunits, @unitprice, @ecm, (@confirmunits + @remainunits),
    			@remainunits, (@jcconfirmunits + @jcremunits), @jctotalcmtdcost, @jcremunits, @jcremcmtdcost,
    			@mo, @moitem, @matlgroup, @material, @co, @loc, @stkunitcost, @stkecm, @stkum, @taxtype, @taxgroup,
    			@taxcode, @taxbasis, @taxamt)
   		if @@error <> 0 goto INCJ_posting_error
    
    		-- delete current row from cursor
    		delete from dbo.INCJ
    		where INCo = @co and Mth = @mth and BatchId = @batchid and JCCo = @jcco and Job = @job
    			and PhaseGroup = @phasegroup and Phase = @phase and	JCCType = @jcctype
    			and	BatchSeq = @seq and OldNew = @oldnew
    		if @@rowcount <> 1
    			begin
    			select @errmsg = 'Unable to remove posted distributions from bINCJ.' 
    			goto INCJ_posting_error
    			end
    		
    		commit transaction
    		
    		goto INCJ_posting_loop
    		
    		INCJ_posting_error:
    			rollback transaction
    			select @rcode = 1
    			goto bspexit
    
    		INCJ_posting_end:       -- finished with MO Confirmations requiring detail committed cost updates
    			close bcINCJ
    			deallocate bcINCJ
    			select @openINCJcursor = 0
    --	end
    
    
    -- JC Interface Level = 0 - No Actuals, but summary update Committed to bJCCP 
    if @jcmointerfacelvl = 0
        begin
        declare bcLvl0 cursor for
        select JCCo, Job, PhaseGroup, Phase, JCCType, convert(numeric(12,3), sum(JCConfirmUnits)),
            convert(numeric(12,3), sum(JCRemUnits)), convert(numeric(12,2), sum(JCTotalCmtdCost)),
    		convert(numeric(12,2), sum(JCRemainCmtdCost))
        from dbo.INCJ with(nolock)
        where INCo = @co and Mth = @mth and BatchId = @batchid
        group by JCCo, Job, PhaseGroup, Phase, JCCType
    
  
        -- open cursor
        open bcLvl0
        select @openLvl0cursor = 1
    
        -- loop through all rows in cursor
        lvl0_posting_loop:
            fetch next from bcLvl0 into @jcco, @job, @phasegroup, @phase, @jcctype,
                @jcconfirmunits, @jcremunits, @jctotalcmtdcost, @jcremcmtdcost
    
            if @@fetch_status = -1 goto lvl0_posting_end
            if @@fetch_status <> 0 goto lvl0_posting_loop
    
            begin transaction
    
            -- update changes to Total and Remaining Committed in JCCP
            if @jcremunits <> 0 or @jcremcmtdcost <> 0
                begin
                update dbo.JCCP
     	        set TotalCmtdUnits = TotalCmtdUnits + (@jcconfirmunits + @jcremunits),
    				TotalCmtdCost = TotalCmtdCost + @jctotalcmtdcost, RemainCmtdUnits = RemainCmtdUnits + @jcremunits,
    				RemainCmtdCost = RemainCmtdCost + @jcremcmtdcost
                where JCCo = @jcco and Mth = @mth and Job = @job and PhaseGroup = @phasegroup
                    and Phase = @phase and CostType = @jcctype
                if @@rowcount = 0
                    begin
                    insert dbo.JCCP (JCCo, Job, PhaseGroup, Phase, CostType, Mth, TotalCmtdUnits,
    					TotalCmtdCost, RemainCmtdUnits, RemainCmtdCost)
                    values(@jcco, @job, @phasegroup, @phase, @jcctype, @mth, (@jcconfirmunits + @jcremunits),
    					@jctotalcmtdcost, @jcremunits, @jcremcmtdcost)
                    end
                end
    
            -- delete current row from cursor
      	    delete from dbo.INCJ
            where INCo = @co and Mth = @mth and BatchId = @batchid and JCCo = @jcco and Job = @job
                and PhaseGroup = @phasegroup and Phase = @phase and	JCCType = @jcctype
    
            commit transaction
    
            goto lvl0_posting_loop
    
        lvl0_posting_error:
            rollback transaction
    		select @rcode = 1
            goto bspexit
    
        lvl0_posting_end:       -- finished JC inteface level 0 - none
            close bcLvl0
            deallocate bcLvl0
            select @openLvl0cursor = 0
    
        end
    
    -- JC Interface Level = 1 - Detail - One entry in bJCCD per Job/Phase/CT/BatchSeq/OldNew
    if @jcmointerfacelvl = 1
        begin
        declare bcLvl1 cursor for
        select JCCo, Job, PhaseGroup, Phase, JCCType, BatchSeq, OldNew,
    		MO, MOItem, Loc, MatlGroup, Material, UM, ConfirmDate, Description, ConfirmUnits,
    		RemainUnits, UnitPrice, ECM, ConfirmTotal, TaxGroup, TaxCode, TaxAmt, StkUM,
    		StkUnitCost, StkECM, JCUM, JCConfirmUnits, JCRemUnits, JCTotalCmtdCost, JCRemainCmtdCost, 
   		TaxBasis
   
    	from dbo.INCJ with(nolock)
    	where INCo = @co and Mth = @mth and BatchId = @batchid
    
        -- open cursor
        open bcLvl1
        select @openLvl1cursor = 1
    
        -- loop through all rows in cursor
        lvl1_posting_loop:
            fetch next from bcLvl1 into @jcco, @job, @phasegroup, @phase, @jcctype, @seq, @oldnew,
    			@mo, @moitem, @loc, @matlgroup, @material, @um, @confirmdate, @description, @confirmunits,
    			@remainunits, @unitprice, @ecm, @confirmtotal, @taxgroup, @taxcode, @taxamt, @stkum,
    			@stkunitcost, @stkecm, @jcum, @jcconfirmunits, @jcremunits, @jctotalcmtdcost, @jcremcmtdcost,
   			@taxbasis
    
            if @@fetch_status = -1 goto lvl1_posting_end
            if @@fetch_status <> 0 goto lvl1_posting_loop
    
    		-- get JC Expense GL Account from MO Item 
    		select @glco = GLCo, @glacct = GLAcct
    		from dbo.INMI with(nolock) where INCo = @co and MO = @mo and MOItem = @moitem
    		if @@rowcount = 0
    			begin
    			select @errmsg = 'Invalid Material Order Item!', @rcode = 1
    			goto bspexit
    			end
    
   		-- calculate actual unit cost in JC U/M - will include tax unless redirected
    		select @jcunitcost = 0, @perecm = null, @jcunits = @jcconfirmunits, @actualunits = @confirmunits
    		if @jcconfirmunits <> 0 select @jcunitcost = (@confirmtotal / @jcconfirmunits), @perecm = 'E'
    		
    		-- set Tax info
    		select @taxtype = null--, @taxbasis = 0 Issue 28448
  
    		if @taxcode is not null select /*@taxbasis = @confirmtotal - @taxamt, Issue 28448*/ @taxtype = 2	-- use tax
     
    		-- issue 28992 burden posted unit cost
   		if isnull(@taxamt,0)<>0 and isnull(@confirmunits,0)<>0 select @unitprice = @confirmtotal/@confirmunits
   
            begin transaction
    
            -- add JC Cost Detail - update Actuals only
            if @confirmunits <> 0 or @confirmtotal <> 0
        		begin
                -- get next available transaction # for JCCD
                exec @jctrans = bspHQTCNextTrans 'bJCCD', @jcco, @mth, @errmsg output
     	        if @jctrans = 0 goto lvl1_posting_error
                    
                -- add JC Cost Detail entry
                insert dbo.JCCD (JCCo, Mth, CostTrans, Job, PhaseGroup, Phase, CostType, PostedDate, ActualDate,
    			    JCTransType, Source, Description, BatchId, GLCo, GLTransAcct, UM, ActualUnitCost,
    				PerECM, ActualUnits, ActualCost, PostedUM, PostedUnits, PostedUnitCost, PostedECM, PostTotCmUnits,
    				PostRemCmUnits, TotalCmtdUnits, TotalCmtdCost, RemainCmtdUnits, RemainCmtdCost, MO, MOItem,
    				MatlGroup, Material, INCo, Loc, INStdUnitCost, INStdECM, INStdUM, TaxType, TaxGroup,
    				TaxCode, TaxBasis, TaxAmt)
    			values (@jcco, @mth, @jctrans, @job, @phasegroup, @phase, @jcctype, @dateposted, @confirmdate,
    				'MO', 'IN MatlOrd', @description, @batchid, @glco, @glacct, @jcum, @jcunitcost,
    				@perecm, @jcunits, @confirmtotal, @um, @confirmunits, @unitprice, @ecm, 0,
    				0, 0, 0, 0, 0, @mo, @moitem, @matlgroup, @material, @co, @loc, @stkunitcost, @stkecm, @stkum,
    				@taxtype, @taxgroup, @taxcode, @taxbasis, @taxamt)
                end
    
            -- update Total and Remaining Committed in bJCCP
            if @jcremunits <> 0 or @jcremcmtdcost <> 0 
                begin
    			update dbo.JCCP
                set TotalCmtdUnits = TotalCmtdUnits + (@jcconfirmunits + @jcremunits),
    				TotalCmtdCost = TotalCmtdCost + @jctotalcmtdcost, RemainCmtdUnits = RemainCmtdUnits + @jcremunits,
    				RemainCmtdCost = RemainCmtdCost + @jcremcmtdcost
                where JCCo = @jcco and Mth = @mth and Job = @job and PhaseGroup = @phasegroup
                    and Phase = @phase and CostType = @jcctype
                if @@rowcount = 0
                    begin
                    insert dbo.JCCP (JCCo, Job, PhaseGroup, Phase, CostType, Mth, TotalCmtdUnits,
    					TotalCmtdCost, RemainCmtdUnits, RemainCmtdCost)
                    values(@jcco, @job, @phasegroup, @phase, @jcctype, @mth, (@jcconfirmunits + @jcremunits),
    					@jctotalcmtdcost, @jcremunits, @jcremcmtdcost)
                    end
                end
    
            -- delete current row from cursor
      	    delete from dbo.INCJ
            where INCo = @co and Mth = @mth and BatchId = @batchid and JCCo = @jcco and Job = @job
                and PhaseGroup = @phasegroup and Phase = @phase and	JCCType = @jcctype and
                BatchSeq = @seq and OldNew = @oldnew
            if @@rowcount <> 1
                begin
     	        select @errmsg = 'Unable to remove posted distributions from INCJ.', @rcode = 1
      	        goto lvl1_posting_error
     	        end
    
            commit transaction
    
            goto lvl1_posting_loop
    
        lvl1_posting_error:
            rollback transaction
            goto bspexit
    
        lvl1_posting_end:       -- finished with JC interface level 1 - Detail
            close bcLvl1
            deallocate bcLvl1
            select @openLvl1cursor = 0
    
        end
    
    -- JC Interface Level = 2 - Summary - One entry in bJCCD per Job/Phase/CT/MO/UM/Tax/JCUM
    if @jcmointerfacelvl = 2
        begin
        declare bcLvl2 cursor for
        select JCCo, Job, PhaseGroup, Phase, JCCType, MO, UM, TaxGroup, TaxCode, JCUM,
        	convert(numeric(12,3), sum(ConfirmUnits)), convert(numeric(12,3), sum(RemainUnits)),
            convert(numeric(12,2), sum(ConfirmTotal)), convert(numeric(12,2), sum(TaxAmt)),
            convert(numeric(12,3), sum(JCConfirmUnits)), convert(numeric(12,3), sum(JCRemUnits)),
            convert(numeric(12,2), sum(JCTotalCmtdCost)), convert(numeric(12,2), sum(JCRemainCmtdCost)),
   		convert(numeric(12,2), sum(TaxBasis))
        from dbo.INCJ with (nolock)
        where INCo = @co and Mth = @mth and BatchId = @batchid
        group by JCCo, Job, PhaseGroup, Phase, JCCType, MO, UM, TaxGroup, TaxCode, JCUM
    
   
        -- open cursor
        open bcLvl2
        select @openLvl2cursor = 1
    
        -- loop through all rows in cursor
        lvl2_posting_loop:
         fetch next from bcLvl2 into @jcco, @job, @phasegroup, @phase, @jcctype, @mo, @um, @taxgroup,
    		@taxcode, @jcum, @confirmunits, @remainunits, @confirmtotal, @taxamt, @jcconfirmunits,
    		@jcremunits, @jctotalcmtdcost, @jcremcmtdcost, @taxbasis
               
            if @@fetch_status = -1 goto lvl2_posting_end
            if @@fetch_status <> 0 goto lvl2_posting_loop
    
            -- calculate Unit Cost
            select @jcunitcost = 0, @perecm = 'E'
            if @jcconfirmunits <> 0 select @jcunitcost = @confirmtotal / @jcconfirmunits
    		select @unitprice = 0, @ecm = 'E'
    		if @confirmunits <> 0 select @unitprice = @confirmtotal / @confirmunits
    
    		-- set Tax info
    		select @taxtype = null--, @taxbasis = 0 Issue 28448
    		if @taxcode is not null select /*@taxbasis = @confirmtotal - @taxamt, Issue 28448 */ @taxtype = 2	-- use tax
     
    		-- issue 28992 burden posted unit cost
   		if isnull(@taxamt,0)<>0 and isnull(@confirmunits,0)<>0 select @unitprice = @confirmtotal/@confirmunits
   
            begin transaction
    
            -- add JC Cost Detail - update Actuals only
            if @confirmunits <> 0 or @confirmtotal <> 0
                begin
                -- get next available transaction # for JCCD
                exec @jctrans = bspHQTCNextTrans 'bJCCD', @jcco, @mth, @errmsg output
     	        if @jctrans = 0 goto lvl2_posting_error
                    
                 -- add JC Cost Detail entry
                insert dbo.JCCD (JCCo, Mth, CostTrans, Job, PhaseGroup, Phase, CostType, PostedDate, ActualDate,
    			    JCTransType, Source, Description, BatchId, UM, ActualUnitCost,
    				PerECM, ActualUnits, ActualCost, PostedUM, PostedUnits, PostedUnitCost, PostedECM, PostTotCmUnits,
    				PostRemCmUnits, TotalCmtdUnits, TotalCmtdCost, RemainCmtdUnits, RemainCmtdCost, MO, MOItem,
    				INCo, Loc, INStdUnitCost, INStdECM, INStdUM, TaxType, TaxGroup, TaxCode, TaxBasis, TaxAmt)
    			values (@jcco, @mth, @jctrans, @job, @phasegroup, @phase, @jcctype, @dateposted, @dateposted,
    				'MO', 'IN MatlOrd', 'MO Confirmation', @batchid, @jcum, @jcunitcost,
    				@perecm, @jcconfirmunits, @confirmtotal, @um, @confirmunits, @unitprice, @ecm, 0,
    				0, 0, 0, 0, 0, @mo, null, @co, null, 0, null, null, @taxtype, @taxgroup,
    				@taxcode, @taxbasis, @taxamt)
    
            -- update Total and Remaining Committed in bJCCP
             if @jcremunits <> 0 or @jcremcmtdcost <> 0 
                begin
    			update dbo.JCCP
                set TotalCmtdUnits = TotalCmtdUnits + (@jcconfirmunits + @jcremunits),
    				TotalCmtdCost = TotalCmtdCost + @jctotalcmtdcost, RemainCmtdUnits = RemainCmtdUnits + @jcremunits,
    				RemainCmtdCost = RemainCmtdCost + @jcremcmtdcost
                where JCCo = @jcco and Mth = @mth and Job = @job and PhaseGroup = @phasegroup
                    and Phase = @phase and CostType = @jcctype
                if @@rowcount = 0
                    begin
                    insert dbo.JCCP (JCCo, Job, PhaseGroup, Phase, CostType, Mth, TotalCmtdUnits,
    					TotalCmtdCost, RemainCmtdUnits, RemainCmtdCost)
                    values(@jcco, @job, @phasegroup, @phase, @jcctype, @mth, (@jcconfirmunits + @jcremunits),
    					@jctotalcmtdcost, @jcremunits, @jcremcmtdcost)
                    end
                end
    
            -- delete current row from cursor
      	    delete from dbo.INCJ
            where INCo = @co and Mth = @mth and BatchId = @batchid and JCCo = @jcco and Job = @job
                and PhaseGroup = @phasegroup and Phase = @phase and	JCCType = @jcctype and
                MO = @mo and UM = @um and isnull(TaxGroup,0) = isnull(@taxgroup,0)
                and isnull(TaxCode,'') = isnull(@taxcode,'') and isnull(JCUM,'') = isnull(@jcum,'')
            
            commit transaction
    
            goto lvl2_posting_loop
    
        lvl2_posting_error:
            rollback transaction
            goto bspexit
    
        lvl2_posting_end:       -- finished with JC interface level 2 - Summary
            close bcLvl2
            deallocate bcLvl2
       		select @openLvl2cursor = 0
        	end
    	end
    
    bspexit:
        if @openINCJcursor = 1
            begin
     		close bcINCJ
     		deallocate bcINCJ
     		end
        if @openLvl0cursor = 1
            begin
     		close bcLvl0
     		deallocate bcLvl0
     		end
        if @openLvl1cursor = 1
            begin
     		close bcLvl1
     		deallocate bcLvl1
     		end
        if @openLvl2cursor = 1
            begin
     		close bcLvl2
     		deallocate bcLvl2
     		end
    
    	--if @rcode <> 0 select @errmsg
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINCBPostJC] TO [public]
GO
