SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspSLXBVal    Script Date: 8/28/99 9:36:38 AM ******/
   CREATE     procedure [dbo].[bspSLXBVal]
   /************************************************************************
    * Created: ???
    * Modified: GG 07/14/99
    *           GR 10/11/99 - added check to see whether subcontract has been posted to
    *                         SL Change detail to the Month later than the proposed Close Month
    *           DANF 09/05/02 - 17738 Added Phase Group to bspJobTypeVal
    *			 RT 12/03/03 - issue 23061, use isnulls when concatenating strings.
    *			 MV 09/16/05 - #29617 - evaluate by UM for JC Distribution
	*			DC 07/30/08 - #128435 - Adding SL Taxes and updating to match bspPOXBVal
	*			DC 11/10/08 - #130997 - Trigger error when validating close batch
	*			MV 02/04/10 - #136500 - bspHQTaxRateGetAll return NULL output param
	*			DC 6/29/10 - #135813 - expand subcontract number
	*			MV 101/25/2011 - TK-09243 - bspHQTaxRateGetAll return NULL output param
    *
    * Usage:
    *  Validates each entry in SL Close Batch - loads JC Distributions in bSLXA
    *  to relieve remaining committed units and costs.
    *
    * Input:
    *  @co         SL Company
    *  @mth        Batch Month for Close
    *  @batchid    Batch ID
    *  @source     Batch Source - 'SL Close'
    *
    * Output:
    *  @errmsg     Error message
    *
    * Return:
    *  0           Success
    *  1           Failure
    *
    *************************************************************************/   
       @co bCompany, @mth bMonth, @batchid bBatchID, @source bSource, @errmsg varchar(60) output
   
   as
   set nocount on
   
   declare @opencursor tinyint, @rcode tinyint, @seq int, @status tinyint, @SL VARCHAR(30), -- bSL,  DC #135813
   @errorhdr varchar(30), @errortext varchar(255), @vendorgroup bGroup, @vendor bVendor, @description bItemDesc, -- bDesc,	DC #135813
   @glco bCompany, @job bJob, @errorstart varchar(255), @um bUM,
   @jcco bCompany, @phase bPhase, @jcum bUM, @remcost bDollar, @remunits bUnits,
   @jcctype bJCCType, @phasegroup bGroup, @invunits bUnits, @invcost bDollar,
   @closedate bDate, @curunitcost bUnitCost, @SLitem bItem, @SLitcursor tinyint,
   @curunits bUnits, @curcost bDollar, @jcunits bUnits, @slstatus tinyint, @lastglco bCompany,
	@taxrate bRate, @taxphase bPhase, @taxjcct bJCCType, @sumRemainCmtdCost bDollar, --DC #128435
	@taxgroup bGroup, @taxcode bTaxCode, @remtax bDollar,  --DC #128435
	@invtax bDollar, @curtax bDollar,@origdate bDate, @dateposted bDate,  --DC #128435
	@valueadd char(1), @gstrate bRate, @pstrate bRate, @HQTXdebtGLAcct bGLAcct  --DC #128435
   
	select @rcode = 0, @sumRemainCmtdCost = 0
   	select @dateposted = convert(varchar(11),getdate())
   
   /* validate HQ Batch */
   exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, @source, 'SLXB', @errmsg output, @status output
   if @rcode <> 0 goto bspexit
   
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
   
   -- clear SL JC Distribution Audit
   delete bSLXA where SLCo = @co and Mth = @mth and BatchId = @batchid
   
   -- declare cursor on SL Close Batch
   declare bcSLXB cursor for
   select BatchSeq, SL, VendorGroup, Vendor, Description, CloseDate
   from bSLXB
   where Co = @co and Mth = @mth and BatchId = @batchid
   
   -- open cursor
   open bcSLXB
   -- set open cursor flag
   select @opencursor = 1
   
   -- process each Subcontract
   SLXB_loop:
       fetch next from bcSLXB into @seq, @SL, @vendorgroup, @vendor, @description, @closedate
   
       if @@fetch_status <> 0 goto SLXB_end
   
    	-- initialize error message
    	select @errorhdr = 'Seq#' + convert(varchar(6),@seq)
   
    	-- validate Subcontract
    	select @slstatus = Status, 
    		@origdate = OrigDate --DC #128435
		from bSLHD
		where SLCo = @co and SL = @SL
		if @@rowcount = 0
    		begin
    		select @errortext = @errorhdr + ' - Invalid Subcontract: ' + @SL
    		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
    		if @rcode <> 0 goto bspexit
			goto SLXB_loop  -- skip Subcontract
    		end
       if @slstatus not in (0,1)
			begin
			select @errortext = @errorhdr + ' - Subcontract: ' + @SL + ' Status must be Open or Completed.'
    		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
    		if @rcode <> 0 goto bspexit
			goto SLXB_loop  -- skip Subcontract
    		end
   
		-- check that no AP Transactions exist in a month later than the Close Month
		if exists(select * from bAPTL where APCo = @co and Mth > @mth and SL = @SL)
			begin
			select @errortext = @errorhdr + ' - Subcontract: ' + @SL + ' has AP Transactions posted later than Close Month.'   
    		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
    		if @rcode <> 0 goto bspexit
           --goto SLXB_loop  skip Subcontract
    		end
   
       -- check that no SL Change detail exist in a month later than the close month
       if exists(select * from bSLCD where SLCo=@co and Mth > @mth and SL=@SL)
           begin
           select @errortext = @errorhdr + ' - Subcontract: ' + @SL + ' has SL Change Orders posted later than Close Month.'
           exec @rcode = bspHQBEInsert  @co, @mth, @batchid, @errortext, @errmsg output
           if @rcode <> 0 goto bspexit
           end
   
    	-- declare cursor on SL Items
    	declare bcSLIT cursor for
        select SLItem, UM, JCCo, Job, PhaseGroup, Phase, JCCType, GLCo, CurUnitCost, CurUnits, CurCost, InvUnits, InvCost,
			TaxGroup, TaxCode, InvTax, CurTax  --DC #128435
    	from bSLIT
        where SLCo = @co and SL=@SL
   
    	-- open item cursor
    	open bcSLIT
    	-- set open cursor flag
    	select @SLitcursor = 1
   
    	-- process each SL Item
		SLIT_loop:
           fetch next from bcSLIT into @SLitem, @um, @jcco, @job, @phasegroup, @phase, @jcctype, @glco,
               @curunitcost, @curunits, @curcost, @invunits, @invcost,
				@taxgroup, @taxcode, @invtax, @curtax  --DC #128435
   
			if @@fetch_status <> 0 goto SLIT_end
   
    		select @errorhdr = @errorhdr + ' Subcontract: ' + @SL + ' SL Item#:' + convert(varchar(6),@SLitem)
   
			-- check for remaining units and costs 
			--and taxes  DC #128435
    	 	select @remunits = @invunits - @curunits, @remcost = @invcost - @curcost--, @remtax = isnull(@invtax,0) - isnull(@curtax,0)  DC #128435
   
 			-- DC  #128435
 			-- need to calculate orig tax for existing item when tax code was null now not null
			if isnull(@taxcode,'') <> ''			
				begin
 				-- if @origdate is null use today's date
 				if isnull(@origdate,'') = '' select @origdate = @dateposted
 				-- get Tax Rate
 				select @taxrate = 0

				exec @rcode = bspHQTaxRateGetAll @taxgroup, @taxcode, @origdate, @valueadd output, @taxrate output, @gstrate output, @pstrate output, 
					null, null, @HQTXdebtGLAcct output, null, null, 
					null, NULL, NULL,@errmsg output

				if @rcode <> 0
					begin
					select @errortext = @errorstart + 'Company : ' + isnull(convert(varchar(10),@co),'') + ' - Tax Group : ' + isnull(convert(varchar(3), @taxgroup),'')
					select @errortext = @errortext + ' - TaxCode : ' + isnull(@taxcode,'') + ' - is not valid! - ' + @errmsg
					exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
					if @rcode <> 0 goto bspexit
					end

				if @HQTXdebtGLAcct is null
					begin
					/* When @pstrate = 0:  Either Standard US, VAT SingleLevel using GST only, or VAT MultiLevel GST/PST with PST set to 0.00 tax rate.  
					   In any case:
					   a)  @taxrate is the correct value.  
					   b)  Standard US:	Credit GLAcct and Credit Retg GLAcct are present
					   c)  VAT:  Credit GLAcct, Credit Retg GLAcct, Debit GLAcct, and Debit Retg GLAcct are present */
					select @remtax = @remcost * @taxrate
					end
				else
					begin
					/* VAT MultiLevel:  Breakout GST and PST for proper GL distribution. */
					if @taxrate <> 0
						begin
						select @remtax = @remcost * @pstrate
						select @taxrate = @pstrate
						end
					end
				end /* tax code validation*/   
   
    		--if @remunits = 0 and @remcost = 0 goto SLIT_loop     -- no JC updates needed
   			if @um = 'LS' and @remcost+@remtax = 0 goto SLIT_loop -- #29617
   			if @um <> 'LS' and @remunits = 0 goto SLIT_loop -- #29617

			--DC #128435
			SELECT @sumRemainCmtdCost  = sum(isnull(RemainCmtdCost,0)) 
			FROM bJCCD 
			WHERE JCCo = @jcco 
				AND Job = @job 
				AND Phase = @phase
				AND CostType = @jcctype
				AND SL = @SL 
				AND SLItem = @SLitem

			if @sumRemainCmtdCost = 0 goto SLIT_loop

           -- check that month is open in JC GL Co#
           if @glco <> @lastglco or @lastglco is null
               begin
               exec @rcode = bspHQBatchMonthVal @glco, @mth, 'SL', @errmsg output
               if @rcode <> 0
					begin
    		        select @errortext = @errorhdr + isnull(@errmsg,'')
    			    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
    			    if @rcode <> 0 goto bspexit
					goto SLIT_loop      -- skip Item
    			    end
               select @lastglco = @glco
               end
   
    		-- validate Job and get JC Unit of Measure
    		exec @rcode = bspJobTypeVal @jcco, @phasegroup, @job, @phase, @jcctype, @jcum output, @errmsg output
    		if @rcode <> 0
    			begin
    		    select @errortext = @errorhdr + isnull(@errmsg,'')
    			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
    			if @rcode <> 0 goto bspexit
                goto SLIT_loop      -- skip Item
    			end
   
            -- get Tax Phase, and Cost Type
            select @taxrate = 0, @taxphase = null, @taxjcct = null
            if @taxcode is not null
                begin
		        exec @rcode = bspHQTaxRateGet @taxgroup, @taxcode, @closedate, @taxrate output, @taxphase output,
                    @taxjcct output, @errmsg output
		        if @rcode <> 0
                    begin
                    select @errortext = @errorstart + ' - ' + isnull(@errmsg,'')
			        exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
                    if @rcode <> 0 goto bspexit
                    goto SLIT_loop
                    end
                end

            -- set Tax Phase and Cost Type
		    if @taxphase is null select @taxphase = @phase
		    if @taxjcct is null select @taxjcct = @jcctype

            if @taxphase = @phase and @taxjcct = @jcctype select @remcost = @remcost + @remtax  -- include tax if not redirected

    		-- remaining committed units expressed in JC UM
           select @jcunits = 0
           if @jcum = @um select @jcunits = @remunits
   
    		-- add JC Distribution    		
            IF isnull(@remunits,0) <> 0 or isnull(@remcost,0) <> 0 or isnull(@sumRemainCmtdCost,0) <>0  --DC #130997
				BEGIN
    			insert bSLXA(SLCo, Mth, BatchId, BatchSeq, JCCo, Job, PhaseGroup, Phase, JCCType, SLItem,
					SL, VendorGroup, Vendor, Description, ActDate, UM, SLUnits, JCUM, CmtdUnits, CmtdCost)
    			values(@co, @mth, @batchid, @seq, @jcco, @job, @phasegroup, @phase, @jcctype, @SLitem,
    				@SL, @vendorgroup, @vendor, @description, @closedate, @um, @remunits, @jcum, @jcunits, isnull(@remcost,0))  --DC #130997
				END

            -- add JC Distribution - if Tax is redirected            
            IF isnull(@remtax,0) <> 0 and (@taxphase <> @phase or @taxjcct <> @jcctype) --DC #130997
				BEGIN
    			insert bSLXA(SLCo, Mth, BatchId, BatchSeq, JCCo, Job, PhaseGroup, Phase, JCCType, SLItem,
					SL, VendorGroup, Vendor, Description, ActDate, UM, SLUnits, JCUM, CmtdUnits, CmtdCost)
    			values(@co, @mth, @batchid, @seq, @jcco, @job, @phasegroup, @taxphase, @taxjcct, @SLitem,
    				@SL, @vendorgroup, @vendor, @description, @closedate, @um, 0, @jcum, 0, isnull(@remtax,0)) --DC #130997
				END
   
    		goto SLIT_loop   -- next Item
   
   
       SLIT_end:   -- finished with Items on Subcontract
           if @SLitcursor=1
    			begin
    			close bcSLIT
    			deallocate bcSLIT
    			select @SLitcursor=0
    			end
   
           goto SLXB_loop  -- next Subcontract
   
   SLXB_end:       -- finished with Subcontracts
       if @opencursor = 1
    		begin
    		close bcSLXB
    		deallocate bcSLXB
           select @opencursor = 0
    		end
   
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
       if @opencursor = 1
           begin
    		close bcSLXB
    		deallocate bcSLXB
    		end
    	if @SLitcursor = 1
    		begin
    		close bcSLIT
    		deallocate bcSLIT
    		end
   
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspSLXBVal] TO [public]
GO
