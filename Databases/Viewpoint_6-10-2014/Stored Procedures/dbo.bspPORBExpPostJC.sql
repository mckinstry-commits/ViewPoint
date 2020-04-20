SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspPORBExpPostJC    Script Date: 8/28/99 9:36:00 AM ******/
    CREATE       procedure [dbo].[bspPORBExpPostJC]
    /***********************************************************
     * CREATED BY:  DANF 04/21/01
     * MODIFIED By: DANF 08/31/01 - Issue 14506 - Check for no PO Company
     *              DANF 12/18/01 - Corrected JC Interfaced Flag.
     *              CMW 03/15/02 - issue # 16503 JCCP column name changes.
     *              DANF 05/01/02 - Added Interface levels from PORH for Initializing Receipts.
     *				GF 08/11/2003 - issue #22116 - performance improvements
     *				DANF 09/25/03 - issue 21985 - Corrected Backingout or turning Reciept expenses.
     *							  - Only the PO Receipt batch and AP Invoice batch should update Received Not Invoiced
     *				DANF 12/01/03 - issue 23111 missing APLine casues error in delete.
     *				RT 12/04/03 - #23061, use isnulls when concatenating message strings, added with (nolock)s.
     *				DC 10/22/08 - #128052  - Remove Committed Cost Flag
     *				DC 12/11/09 - #122288 - Store Tax Rate in POIT
     *				DC 6/29/10 - #135813 - expand subcontract number
     *				GF 08/22/2011 TK-07879 PO ITEM LINE
     *
     *
     * USAGE:
     * Called from the bspPORBPost procedure to post JC distributions
     * tracked in bPORJ.  Interface level to JC is assigned in PO Company.
     * Even if the JC Interface level is set at 0 (none), committed units and
     * costs must be updated to JC for POs.
     *
     * Interface levels:
     *  0       No update of actual units or costs to JC, but will still update
     *          committed and received n/invcd units and cost to JCCP.
     *  1       Interface at the transaction line level.  Each receipt creates a JCCD entry.
     *
     * INPUT PARAMETERS
     *   @co            PO Co#
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
    (@co bCompany, @mth bMonth, @batchid bBatchID, @dateposted bDate = null, @errmsg varchar(100) output)
    as
    set nocount on
    
declare @rcode int,	@jcinterfacelvl tinyint,
		@openPOSLcursor tinyint, @openLvl0cursor tinyint, @openLvl1cursor tinyint, @openLvl2cursor tinyint,
		@jcco bCompany, @job bJob, @phasegroup bGroup, @phase bPhase, @jcctype bJCCType, @units bUnits,
		@detailcmtdunits bUnits, @jcunits bUnits, @jccmtdunits bUnits, @totalcost bDollar, @remcmtdcost bDollar,
		@jcunitcost bUnitCost, @ecm bECM, @jctrans bTrans, @msg varchar(200), @rniunits bUnits, @rnicost bDollar,
		@potrans bTrans, @apline smallint,
		@seq int, @recdate bDate, @oldnew tinyint,
		@um bUM, @vendorgroup bGroup, @vendor bVendor, @jcum bUM, @desc bDesc,
		@po varchar(30), @poitem bItem, @matlgroup bGroup, @material bMatl, @glco bCompany, @glacct bGLAcct,
		@taxtype tinyint, @taxgroup bGroup, @taxcode bTaxCode, @taxbasis bDollar, @taxamt bDollar, 
		@receiver# varchar(20), @source bSource, @oldjcinterfacelvl tinyint,
		@totalcmtdtax bDollar, @remcmtdtax bDollar,
		----TK-07879
		@POItemLine INT
		
    select @rcode = 0, @openPOSLcursor = 0, @openLvl0cursor = 0, @openLvl1cursor = 0, @openLvl2cursor = 0
    
    -- get JC interface level and Committed Cost Update option for POs
    select @jcinterfacelvl = RecJCInterfacelvl
    from bPOCO with (nolock) where POCo = @co
    if @@rowcount = 0
        begin
        --- Not every one will have PO /// select @errmsg = 'Missing PO Company!', @rcode = 1
        goto bspexit
        end
    
    --   Over Ride Interface levels if Initializing Expenses from Receipts.
    select @source=Source from bHQBC with (nolock) 
    where Co = @co and Mth = @mth and BatchId = @batchid
    if isnull(@source,'') = 'PO InitRec'
    	begin
    	-- get PORH info
    	select @jcinterfacelvl = RecJCInterfacelvl, @oldjcinterfacelvl = OldRecJCInterfacelvl
        from bPORH with (nolock) 
    	where Co = @co and Mth = @mth and BatchId = @batchid
    	if @@rowcount = 0
    		begin
    		select @errmsg = ' Missing Receipt Header for Interface levels!', @rcode = 1
    		goto bspexit
    		end
        -- if turning off receipt expenses swith interface level to on for backing out receipt expenses
    	if @oldjcinterfacelvl = 1 and @jcinterfacelvl = 0 select @jcinterfacelvl =1
    	end
    
    -- if updating Committed units or costs in detail from PO process each receipt
    declare bcPOSL cursor LOCAL FAST_FORWARD
    for select JCCo, Job, PhaseGroup, Phase, JCCType, BatchSeq, APLine, OldNew,
			POTrans, VendorGroup, Vendor, RecDate, Receiver#, PO, POItem,
			MatlGroup, Material, Description, GLCo, GLAcct,
			UM, Units, JCUM, JCUnits, JCUnitCost, ECM, TotalCost,
			RNIUnits, RNICost, RemCmtdCost,
			TaxGroup, TaxCode, TaxType, TaxBasis, TaxAmt,
			--DC #122288
			TotalCmtdTax, RemCmtdTax,
			----TK-07879
			POItemLine
    from dbo.bPORJ
    where POCo = @co and Mth = @mth
		AND BatchId = @batchid
		AND PO is not null
    
    -- open cursor
    open bcPOSL
    select @openPOSLcursor = 1
    
    -- loop through all rows in cursor
    posl_posting_loop:
    fetch next from bcPOSL into @jcco, @job, @phasegroup, @phase, @jcctype, @seq, @apline, @oldnew,
            @potrans, @vendorgroup, @vendor, @recdate, @receiver#, @po, @poitem,
     	    @matlgroup, @material, @desc, @glco, @glacct,
            @um, @units, @jcum, @jcunits, @jcunitcost, @ecm, @totalcost,
            @rniunits, @rnicost, @remcmtdcost,
            @taxgroup, @taxcode, @taxtype, @taxbasis, @taxamt,
            --DC #122288
            @totalcmtdtax, @remcmtdtax,
            ----TK-07879
            @POItemLine
    
if @@fetch_status = -1 goto posl_posting_end
if @@fetch_status <> 0 goto posl_posting_loop

-- change to Remaining Committed Units and Cost
select @detailcmtdunits = @units, @jccmtdunits = @jcunits

if @jcinterfacelvl = 0      -- not interfacing Actual units or costs
	begin
	select @units = 0, @jcunits = 0, @jcunitcost = 0, @totalcost = 0,
		   @rniunits =0, @rnicost = 0, @detailcmtdunits =0, @remcmtdcost =0, @taxbasis =0
	end

begin transaction
    
---- add JC Cost Detail - update Actuals (unless JC interface level = 0) and Remaining Committed
if @units <> 0 or @totalcost <> 0 or @detailcmtdunits <> 0 or @remcmtdcost <> 0 or @taxbasis <> 0
	BEGIN
	
	IF @POItemLine IS null
		begin
		select @errmsg = 'Unable to update JC Cost Detail.', @rcode=1
		goto posl_posting_error
		end
	
	-- get next available transaction # for JCCD
	exec @jctrans = bspHQTCNextTrans 'bJCCD', @jcco, @mth, @msg output
	if @jctrans = 0
		begin
		select @errmsg = 'Unable to update JC Cost Detail.  ' + isnull(@msg,''), @rcode=1
		goto posl_posting_error
		end

	-- add JC Cost Detail entry
	insert bJCCD (JCCo, Mth, CostTrans, Job, PhaseGroup, Phase, CostType, PostedDate, ActualDate,
            JCTransType, Source, Description, BatchId, PostedUM, PostedUnits, PostRemCmUnits, UM,
            ActualUnitCost, PerECM, ActualUnits, ActualCost, RemainCmtdUnits, RemainCmtdCost,
            APCo, VendorGroup, Vendor, PO, POItem, MatlGroup, Material, GLCo, GLTransAcct,
            TaxType, TaxGroup, TaxCode, TaxBasis, TaxAmt,
            TotalCmtdTax, RemCmtdTax,
            ----TK-07879
            POItemLine)
	values (@jcco, @mth, @jctrans, @job, @phasegroup, @phase, @jcctype, @dateposted, @recdate,
            'PO', 'PO Receipt', @desc, @batchid, @um, @units, -(@detailcmtdunits), @jcum,
            @jcunitcost, @ecm, @jcunits, @totalcost, -(@jccmtdunits), @remcmtdcost,
            @co, @vendorgroup, @vendor, @po, @poitem, @matlgroup, @material, @glco, @glacct,
            @taxtype, @taxgroup, @taxcode, @taxbasis, @taxamt,
            @totalcmtdtax, @remcmtdtax,
            ----TK-07879
            @POItemLine)
	if @@error <> 0 goto posl_posting_error
	end   
   
   	select @rniunits =0, @rnicost=0 -- Set Received Not Invoiced to Zero
   
    -- update Received not Invoiced in JCCP
    if (@rniunits <> 0 or @rnicost <> 0)
    	begin
    	update bJCCP
    	set RecvdNotInvcdUnits = RecvdNotInvcdUnits + @rniunits, RecvdNotInvcdCost = RecvdNotInvcdCost + @rnicost
    	where JCCo = @jcco and Mth = @mth and Job = @job and PhaseGroup = @phasegroup
    	and Phase = @phase and CostType = @jcctype
    	if @@rowcount = 0
    		begin
    		insert bJCCP (JCCo, Job, PhaseGroup, Phase, CostType, Mth, RecvdNotInvcdUnits, RecvdNotInvcdCost)
    		values(@jcco, @job, @phasegroup, @phase, @jcctype, @mth, @rniunits, @rnicost)
    		if @@error <> 0 goto posl_posting_error
    		end
    	end
    
    -- delete current row from cursor
    delete from bPORJ
    where POCo = @co and Mth = @mth and BatchId = @batchid and JCCo = @jcco and Job = @job
    and PhaseGroup = @phasegroup and Phase = @phase and	JCCType = @jcctype and BatchSeq = @seq 
    and APLine = @apline and OldNew = @oldnew
    if @@rowcount <> 1
    	begin
    	select @errmsg = 'Unable to remove posted distributions from PORJ.', @rcode = 1
    	goto posl_posting_error
    	end
    
    commit transaction
    
    goto posl_posting_loop
    
    posl_posting_error:
    	rollback transaction
    	goto bspexit
    
    posl_posting_end:       -- finished with PO & SL transactions requiring detail committed cost updates
    	close bcPOSL
    	deallocate bcPOSL
    	select @openPOSLcursor = 0
    
    -- JC Interface Level = 0 - No Actuals, but must update changes to Remaining Committed and Recvd n/Invcd
    if @jcinterfacelvl = 0
        begin
        declare bcLvl0 cursor LOCAL FAST_FORWARD
    	for select JCCo, Job, PhaseGroup, Phase, JCCType, convert(numeric(12,3), sum(RNIUnits)),
    			convert(numeric(12,2), sum(RNICost)), convert(numeric(12,2), sum(RemCmtdCost))
        from bPORJ with (nolock)
        where POCo = @co and Mth = @mth and BatchId = @batchid
        group by JCCo, Job, PhaseGroup, Phase, JCCType
    
        -- open cursor
        open bcLvl0
        select @openLvl0cursor = 1
    
        -- loop through all rows in cursor
        lvl0_posting_loop:
    	fetch next from bcLvl0 into @jcco, @job, @phasegroup, @phase, @jcctype, @rniunits, @rnicost, @remcmtdcost
    
    	if @@fetch_status = -1 goto lvl0_posting_end
    	if @@fetch_status <> 0 goto lvl0_posting_loop
    
    	-- get Remaining Committed Units - only come from PO and SLs
    	select @jccmtdunits = 0
    	select @jccmtdunits = isnull(sum(JCUnits),0)
    	from bPORJ with (nolock)
    	where POCo = @co and Mth = @mth and BatchId = @batchid and JCCo = @jcco
    	and Job = @job and PhaseGroup = @phasegroup and Phase = @phase and JCCType = @jcctype
    	and (PO is not null or SL is not null)
   
    	select @rniunits =0, @rnicost=0 -- Set Received Not Invoiced to Zero. 
   
    	begin transaction
    	-- update Remaining Committed and Received not Invoiced in JCCP
    	if (@jccmtdunits <> 0 or @rniunits <> 0 or @rnicost <> 0 or @remcmtdcost <> 0)
    		begin
    		update bJCCP
    		set RemainCmtdUnits = RemainCmtdUnits - @jccmtdunits, RemainCmtdCost = RemainCmtdCost + @remcmtdcost,
                    RecvdNotInvcdUnits = RecvdNotInvcdUnits + @rniunits, RecvdNotInvcdCost = RecvdNotInvcdCost + @rnicost
    		where JCCo = @jcco and Mth = @mth and Job = @job and PhaseGroup = @phasegroup
    		and Phase = @phase and CostType = @jcctype
    		if @@rowcount = 0
    			begin
    			insert bJCCP (JCCo, Job, PhaseGroup, Phase, CostType, Mth, RemainCmtdUnits, RemainCmtdCost,
                        RecvdNotInvcdUnits, RecvdNotInvcdCost)
    			values(@jcco, @job, @phasegroup, @phase, @jcctype, @mth, -(@jccmtdunits), @remcmtdcost,
                        @rniunits, @rnicost)
    			if @@error <> 0 goto lvl0_posting_error
    			end
    		end
    
    	-- delete current row from cursor
    	delete from bPORJ where POCo = @co and Mth = @mth and BatchId = @batchid and JCCo = @jcco and Job = @job
    	and PhaseGroup = @phasegroup and Phase = @phase and	JCCType = @jcctype
    
    	commit transaction
    
    	goto lvl0_posting_loop
    
    	lvl0_posting_error:
    		rollback transaction
            goto bspexit
    
    	lvl0_posting_end:       -- finished JC inteface level 0 - none
    		close bcLvl0
            deallocate bcLvl0
            select @openLvl0cursor = 0
    
    	end
    
    -- JC Interface Level = 1 - Line - One entry in JCCD per Receipt Entry
    if @jcinterfacelvl = 1
        begin
        declare bcLvl1 cursor LOCAL FAST_FORWARD
    	for select JCCo, Job, PhaseGroup, Phase, JCCType, BatchSeq, OldNew, APLine,
            POTrans, VendorGroup, Vendor, RecDate, Receiver#, PO, POItem,
            MatlGroup, Material, Description, GLCo, GLAcct,
            UM, Units, JCUM, JCUnits, JCUnitCost, ECM, TotalCost,
            RNIUnits, RNICost, RemCmtdCost,
            TaxGroup, TaxCode, TaxType, TaxBasis, TaxAmt,
            ---- TK-07879
            POItemLine
        from bPORJ with (nolock)
        where POCo = @co and Mth = @mth and BatchId = @batchid
    
        -- open cursor
        open bcLvl1
        select @openLvl1cursor = 1
    
        -- loop through all rows in cursor
        lvl1_posting_loop:
    	fetch next from bcLvl1 into @jcco, @job, @phasegroup, @phase, @jcctype, @seq, @oldnew, @apline,
            @potrans, @vendorgroup, @vendor, @recdate, @receiver#, @po, @poitem,
     	    @matlgroup, @material, @desc, @glco, @glacct,
            @um, @units, @jcum, @jcunits, @jcunitcost, @ecm, @totalcost,
            @rniunits, @rnicost, @remcmtdcost,
            @taxgroup, @taxcode, @taxtype, @taxbasis, @taxamt,
            ---- TK-07879
            @POItemLine
    
    	if @@fetch_status = -1 goto lvl1_posting_end
    	if @@fetch_status <> 0 goto lvl1_posting_loop
    
    	-- get Remaining Committed Units - must be a PO or SL
    	select @jccmtdunits = 0
    	if @po is not null select @jccmtdunits = isnull(@jcunits,0)
    
    	begin transaction
    	-- add JC Cost Detail - update Actuals only
    	if @units <> 0 or @totalcost <> 0
    		BEGIN
    		
    	IF @POItemLine IS null
		begin
		select @errmsg = 'Unable to update JC Cost Detail.', @rcode=1
		goto posl_posting_error
		END
		
    		-- get next available transaction # for JCCD
    		exec @jctrans = bspHQTCNextTrans 'bJCCD', @jcco, @mth, @msg output
    		if @jctrans = 0
    			begin
    			select @errmsg = 'Unable to update JC Cost Detail.  ' + @msg, @rcode=1
    			goto lvl1_posting_error
    			end
    
    		-- add JC Cost Detail entry
    		insert bJCCD (JCCo, Mth, CostTrans, Job, PhaseGroup, Phase, CostType, PostedDate, ActualDate,
                    JCTransType, Source, Description, BatchId, PostedUM, PostedUnits, UM, ActualUnitCost, PerECM, ActualUnits, ActualCost,
                    APCo, VendorGroup, Vendor, PO, POItem, MatlGroup, Material,
                    GLCo, GLTransAcct, TaxType, TaxGroup, TaxCode, TaxBasis, TaxAmt,
                    TotalCmtdTax, RemCmtdTax,
                    ----TK-07879
                    POItemLine)
    		values (@jcco, @mth, @jctrans, @job, @phasegroup, @phase, @jcctype, @dateposted, @recdate,
                    'PO', 'PO Receipt', @desc, @batchid, @um, @units, @jcum, @jcunitcost, @ecm, @jcunits, @totalcost,
                    @co, @vendorgroup, @vendor, @po, @poitem, @matlgroup, @material,
                    @glco, @glacct, @taxtype, @taxgroup, @taxcode, @taxbasis, @taxamt,
                    @totalcmtdtax, @remcmtdtax,
                    ----TK-07879
                    @POItemLine)
    		if @@error <> 0 goto lvl1_posting_error
    		end
   	
   	select @rniunits =0, @rnicost=0 -- Set Received Not Invoiced to Zero
    	-- update Remaining Committed and Received not Invoiced in JCCP
    	if (@rniunits <> 0 or @rnicost <> 0 or @jccmtdunits <> 0 or @remcmtdcost <> 0)
    		begin
    		update bJCCP
    		set RemainCmtdUnits = RemainCmtdUnits - @jccmtdunits, RemainCmtdCost = RemainCmtdCost + @remcmtdcost,
                    RecvdNotInvcdUnits = RecvdNotInvcdUnits + @rniunits, RecvdNotInvcdCost = RecvdNotInvcdCost + @rnicost
    		where JCCo = @jcco and Mth = @mth and Job = @job and PhaseGroup = @phasegroup
    		and Phase = @phase and CostType = @jcctype
    		if @@rowcount = 0
    			begin
    			select @jccmtdunits = isnull(@jccmtdunits,0)
    			insert bJCCP (JCCo, Job, PhaseGroup, Phase, CostType, Mth, RemainCmtdUnits, RemainCmtdCost,
                        RecvdNotInvcdUnits, RecvdNotInvcdCost)
    			values(@jcco, @job, @phasegroup, @phase, @jcctype, @mth, -(@jccmtdunits), @remcmtdcost,
                        @rniunits, @rnicost)
    			if @@error <> 0 goto lvl1_posting_error
    			end
    		end
    
    	-- delete current row from cursor
    	delete from bPORJ where POCo = @co and Mth = @mth and BatchId = @batchid and JCCo = @jcco and Job = @job
    	and PhaseGroup = @phasegroup and Phase = @phase and	JCCType = @jcctype and BatchSeq = @seq and APLine = @apline and OldNew = @oldnew
    	if @@rowcount <> 1
    		begin
    		select @errmsg = 'Unable to remove posted distributions from PORJ.', @rcode = 1
    		goto lvl1_posting_error
    		end
    
    	commit transaction
    
    	goto lvl1_posting_loop
    
    	lvl1_posting_error:
    		rollback transaction
            goto bspexit
    
        lvl1_posting_end:       -- finished with JC interface level 1 - Line
            close bcLvl1
            deallocate bcLvl1
            select @openLvl1cursor = 0
    
        end
                
    
    bspexit:
        if @openPOSLcursor = 1
            begin
     		close bcPOSL
     		deallocate bcPOSL
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
    
        return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspPORBExpPostJC] TO [public]
GO
