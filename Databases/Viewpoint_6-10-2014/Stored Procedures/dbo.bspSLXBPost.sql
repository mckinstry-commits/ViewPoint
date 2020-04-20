SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspSLXBPost    Script Date: 8/28/99 9:36:38 AM ******/
   CREATE      procedure [dbo].[bspSLXBPost]
   /************************************************************************
   * Modified by: kb 12/7/98
   *           GG 01/07/00 - fixed VendorGroup update to bJCCD
   *           kb 6/19/00 - issue #7199
   *           CMW 03/15/02 - issue # 16503 JCCP column name changes.
   *           CMW 04/04/02 - added bHQBC.Notes interface levels update (issue # 16692).
   *			GG 06/11/02 - #17564 - insert bJCCD.PostedUnits = 0
   *			RT 12/03/03 - issue 23061, use isnulls when concatenating strings.
   *			MV 09/15/05 - #29530 - update ChangeCurCost in SLCD for units based SLs.
   *			MV 09/16/05 - #29617 - evaluate by UM for update to JCCD
	*			DC 04/30/08 - #127181 - Store the batch ID of the SL Close batch in the SLHD table
	*			DC 07/01/08 - #128435 - Add SL Taxes
	*			DC 10/23/08 - #130749 - Remove Committed Cost Flag
	*			GP 10/31/08	- Issue 130576, changed text datatype to varchar(max)
	*			DC 6/29/10 - #135813 - expand subcontract number
	*			AJW 6/7/13 - TFS 52074 Don't do SLCO for Backcharge items
	*
   *
   * Posts a validated batch of SLXB entries
   *
   * pass in Co#, Month, Batch ID#, and Posting Date
   *
   * deletes successfully posted bSLXB rows
   * clears bHQCC when complete
   *
   * returns 1 and message if error
   ************************************************************************/   
   	(@co bCompany, @mth bMonth, @batchid bBatchID,
   	@dateposted bDate = null, @source bSource, @errmsg varchar(60) output)
   
   as
   set nocount on
   
   declare @rcode int, @SLxbcursor tinyint, @tablename char(20),
   	@status tinyint, --DC #130749 @cmtddetailtojc bYN, 
   	@jcco bCompany, @lastseq int,
   	@jctrans bTrans, @SLtrans bTrans, @job bJob, @seq int, @cmtdunits bUnits,
   	@phasegroup bGroup, @cmtdcost bDollar, @SL VARCHAR(30), --bSL, DC #135813
   	@phase bPhase, @vendorgroup bGroup, @SLitem bItem, @jcctype bJCCType, 
   	@vendor bVendor, @closedate bDate, @description bItemDesc, --bDesc,  DC #135813
   	@um bUM, @remaining bDollar, @SLunits bUnits, @ecm bECM,
   	@jcum bUM, @SLitcursor tinyint, @itemtype tinyint, @bounits bUnits,
   	@bocost bDollar, @curunitcost bUnitCost, @actdate bDate, @SLxacursor tinyint,
   	@invunits bUnits, @invcost bDollar, @errflag char(1), @Notes varchar(256),
	@sumRemainCmtdCost bDollar --DC #128435
   
   select @rcode = 0
   
   /* set open cursor flag to false */
   select @SLxacursor = 0, @SLxbcursor = 0, @SLitcursor=0
   
   /* check for date posted */
   if @dateposted is null
   	begin   
   	select @errmsg = 'Missing posting date!', @rcode = 1
   	goto bspexit
   	end
   	
   /* select @source='SL Close' - changed @source to be an input parameter */
   /* validate HQ Batch */
   exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, @source, 'SLXB', @errmsg output,
   	@status output   
	if @rcode <> 0
   		begin   
       	select @errmsg = @errmsg, @rcode = 1
       	goto bspexit
      	end
   
	if @status <> 3 and @status <> 4	/* valid - OK to post, or posting in progress */
   		begin
   		select @errmsg = 'Invalid Batch status -  must be (valid - OK to post) or (posting in progress)!', @rcode = 1
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
   	
   	/*--DC #130749
   /* check level of update to jc */
   select @cmtddetailtojc=CmtdDetailToJC from bSLCO where SLCo=@co
   	if @@rowcount=0
   	begin
   	select @errmsg = 'Invalid SL Company!', @rcode = 1
   	goto bspexit
   	end
   	*/
      
   jcposting_loop:
      
   /* declare cursor on SL Close JC Distribution Batch for posting */
   declare bcSLXA cursor for select JCCo, Job, PhaseGroup, Phase, JCCType, BatchSeq, SL, SLItem,
   	VendorGroup, Vendor, Description, UM, SLUnits, JCUM, CmtdUnits, CmtdCost, ActDate
   	from bSLXA where SLCo = @co and Mth = @mth and BatchId = @batchid for update
   
   /* open cursor */
   open bcSLXA
      
   /* set open cursor flag to true */
   select @SLxacursor = 1
   
   /* loop through all rows in this batch */
   jcposting_loopa:
   fetch next from bcSLXA into @jcco, @job, @phasegroup, @phase, @jcctype, @seq, @SL, @SLitem,
   	@vendorgroup, @vendor, @description, @um, @SLunits, @jcum, @cmtdunits, @cmtdcost, @actdate
   if (@@fetch_status <> 0) goto posting_loop
      
   if (@lastseq=@seq)
		begin
    	select @errmsg='Same Seq repeated, cursor error.', @rcode=1
   		goto bspexit
   		end
   
   begin transaction
   --DC #130749   
   --IF @cmtddetailtojc='Y' /* only update JCCD if posting detail to JC (flag in SLCO) */
	--	BEGIN
		--IF (@um='LS' and @cmtdcost<>0) or (@um<>'LS' and @cmtdunits<>0) --#29617
		IF @SLunits <> 0 or @cmtdunits <> 0 or @cmtdcost <> 0  --DC #128435   		
   			BEGIN

   			/* get next available transaction # for JCCD */
   			select @tablename = 'bJCCD'
   			exec @jctrans = bspHQTCNextTrans @tablename, @jcco, @mth, @errmsg output
       		select @errmsg= isnull(@errmsg,'') + ' T:' + convert(varchar(5), @seq)
   			if @SLtrans = 0
    			BEGIN
     			select @errmsg = isnull(@errmsg,'') + ' T:' + convert(varchar(5), @seq), @errflag = 'j'
				goto posting_error
     			END
	      
   			/* insert JC Detail */
   			insert bJCCD (JCCo, Mth, CostTrans, Job, PhaseGroup, Phase, CostType, PostedDate,
   				ActualDate, JCTransType, Source, Description, BatchId, PostedUM,
   				PostedUnits, PostTotCmUnits, PostRemCmUnits, UM, TotalCmtdUnits,
   				TotalCmtdCost, RemainCmtdUnits, RemainCmtdCost, VendorGroup, Vendor, APCo,
   				SL, SLItem)
   			values (@jcco, @mth, @jctrans, @job, @phasegroup, @phase, @jcctype, @dateposted,
   				@actdate, 'SL', @source, @description, @batchid, @um,
   				0, @SLunits, @SLunits, @jcum, @cmtdunits, @cmtdcost, @cmtdunits, @cmtdcost,
   				@vendorgroup, @vendor, @co, @SL, @SLitem)	   
   			if @@rowcount = 0   
   				BEGIN
   				select @errmsg = isnull(@errmsg,'') + ' A:' + convert(varchar(5), @seq), @errflag = 'j'
   				goto posting_error   
     			END

			--DC #128435  START
			/*
			 Check the RemainCmtdCost to see if there is anything remaining.  There are times 
			when you close out a SL that there will be a few cents remaining because of rounding 
			issues. if there is anything remaining then we will insert a negative for that same 
			amount to zero out any RemainCmtdCost.
			*/ 
			SELECT @sumRemainCmtdCost  = sum(isnull(RemainCmtdCost,0)) 
			FROM bJCCD 
			WHERE JCCo = @jcco 
				AND Job = @job 
				AND Phase = @phase
				AND CostType = @jcctype
				AND SL = @SL 
				AND SLItem = @SLitem

			IF @sumRemainCmtdCost <> 0 
				BEGIN
					SELECT @sumRemainCmtdCost = @sumRemainCmtdCost * -1

					--  get next available transaction # for JCCD
					exec @jctrans = bspHQTCNextTrans 'bJCCD', @jcco, @mth, @errmsg output
					if @jctrans = 0
						begin
						select @errmsg = isnull(@errmsg,'') + ' T:' + convert(varchar(5), @seq), @errflag = 'j'
						goto posting_error
						end

					INSERT bJCCD (JCCo, Mth, CostTrans, Job, PhaseGroup, Phase, CostType, PostedDate, ActualDate,
						JCTransType, Source, Description, BatchId, PostedUM, PostedUnits, PostTotCmUnits, PostRemCmUnits,
						UM, TotalCmtdUnits, TotalCmtdCost, RemainCmtdUnits, RemainCmtdCost, VendorGroup, Vendor, APCo,
						SL, SLItem)
					VALUES (@jcco, @mth, @jctrans, @job, @phasegroup, @phase, @jcctype, @dateposted, @actdate,
					   'SL', @source, 'Remaining Committed Cost adjustment for zero remaining units', @batchid, @um, 0, 0, 0,
						@jcum, 0, @sumRemainCmtdCost, 0, @sumRemainCmtdCost, @vendorgroup, @vendor, @co,
						@SL, @SLitem)
					IF @@rowcount <> 1
						BEGIN
						select @errmsg = isnull(@errmsg,'') + ' A:' + convert(varchar(5), @seq), @errflag = 'j'
						goto posting_error
						END
				END
				--DC #128435  END
			END
		ELSE
			BEGIN
				--DC #128435  START
				/*
				If the POUnits, CmtdUnits, CmtdCost are all zero there could still be RemainCmtdCost
				 Check the RemainCmtdCost to see if there is anything remaining.  There are times 
				when you close out a PO that there will be a few cents remaining because of rounding 
				issues. if there is anything remaining then we will insert a negative for that same 
				amount to zero out any RemainCmtdCost.
				*/ 
				SELECT @sumRemainCmtdCost  = sum(isnull(RemainCmtdCost,0)) 
				FROM bJCCD 
				WHERE JCCo = @jcco 
					AND Job = @job 
					AND Phase = @phase
					AND CostType = @jcctype
					AND SL = @SL 
					AND SLItem = @SLitem

				IF @sumRemainCmtdCost <> 0 
					BEGIN
						SELECT @sumRemainCmtdCost = @sumRemainCmtdCost * -1

						--  get next available transaction # for JCCD
						exec @jctrans = bspHQTCNextTrans 'bJCCD', @jcco, @mth, @errmsg output
						if @jctrans = 0
							BEGIN
							select @errmsg = isnull(@errmsg,'') + ' T:' + convert(varchar(5), @seq), @errflag = 'j'
							goto posting_error
							END

						INSERT bJCCD (JCCo, Mth, CostTrans, Job, PhaseGroup, Phase, CostType, PostedDate, ActualDate,
							JCTransType, Source, Description, BatchId, PostedUM, PostedUnits, PostTotCmUnits, PostRemCmUnits,
							UM, TotalCmtdUnits, TotalCmtdCost, RemainCmtdUnits, RemainCmtdCost, VendorGroup, Vendor, APCo,
							SL, SLItem)
						VALUES (@jcco, @mth, @jctrans, @job, @phasegroup, @phase, @jcctype, @dateposted, @actdate,
						   'SL', @source, 'Remaining Committed Cost adjustment for zero remaining units', @batchid, @um, 0, 0, 0,
							@jcum, 0, @sumRemainCmtdCost, 0, @sumRemainCmtdCost, @vendorgroup, @vendor, @co,
							@SL, @SLitem)
						IF @@rowcount <> 1
							BEGIN
							select @errmsg = isnull(@errmsg,'') + ' A:' + convert(varchar(5), @seq), @errflag = 'j'
							goto posting_error
							END
					END
				--DC #128435  END
			END
   	--	END
   	
   	/*--DC #130749
	IF @cmtddetailtojc='N'
		BEGIN
   		IF (@um='LS' and @cmtdcost<>0) or (@um<>'LS' and @cmtdunits<>0) --#29617
			BEGIN
			update bJCCP
			set TotalCmtdUnits = TotalCmtdUnits  +@cmtdunits, TotalCmtdCost = TotalCmtdCost + @cmtdcost,
				RemainCmtdUnits = RemainCmtdUnits + @cmtdunits,
				RemainCmtdCost = RemainCmtdCost + @cmtdcost
				where JCCo=@jcco and Mth=@mth and Job=@job and PhaseGroup=@phasegroup and Phase=@phase and
				CostType=@jcctype
			if @@rowcount=0
 				BEGIN
				insert bJCCP (JCCo, Job, PhaseGroup, Phase, CostType, Mth, ActualHours, ActualUnits,
					ActualCost, OrigEstHours, OrigEstUnits, OrigEstCost, CurrEstHours, CurrEstUnits,
					CurrEstCost, ProjHours, ProjUnits, ProjCost, ForecastHours, ForecastUnits, ForecastCost,
					TotalCmtdUnits, TotalCmtdCost, RemainCmtdUnits, RemainCmtdCost,
					RecvdNotInvcdUnits, RecvdNotInvcdCost)
				values (@jcco, @job, @phasegroup, @phase, @jcctype, @mth, 0, 0, 0, 0, 0, 0, 0, 0, 0,
					0, 0, 0, 0, 0, 0,
					@cmtdunits, @cmtdcost, @cmtdunits, @cmtdcost,
					0, 0)
	 			END			
			END
   		END
   	*/

   /* delete current row from cursor */
   delete from bSLXA where SLCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq and
   	JCCo = @jcco and Job = @job and PhaseGroup = @phasegroup and Phase = @phase and JCCType = @jcctype and
   	SLItem = @SLitem
   
   	if @@rowcount <> 1
		begin
   		rollback transaction
        select @errmsg = 'Error removing batch sequence ' + convert(varchar(10), @seq) + ' from batch.'
    	goto bspexit
   		end   
   
   /* commit transaction */   
   
   commit transaction
   goto jcposting_loopa
      
   posting_loop:
   
   /* declare cursor on SL Close Batch for posting */
   
   declare bcSLXB cursor for select BatchSeq, SL, VendorGroup, Vendor, Description, JCCo, Job, RemainCost, CloseDate
   	from bSLXB where Co = @co and Mth = @mth and BatchId = @batchid for update
   
   /* open cursor */
   open bcSLXB
   
   /* set open cursor flag to true */
   select @SLxbcursor = 1
   
   /* loop through all rows in this batch */
   posting_loopa:
   	fetch next from bcSLXB into @seq, @SL, @vendorgroup, @vendor, @description, @jcco, @job, @remaining,
   			@closedate
   
   	if (@@fetch_status <> 0) goto posting_loop_end
      
   	if (@lastseq=@seq)
   		begin
        select @errmsg='Same Seq repeated, cursor error.', @rcode=1
   	    goto bspexit
        end
   
   	begin transaction   
   
   	item_loop:
   	/* declare cursor on SL Item Batch for posting */
   	declare bcSLIT cursor for select SLItem, ItemType, CurCost, CurUnits, CurUnitCost,
   		InvUnits, InvCost, UM
   		from bSLIT where SLCo = @co and SL=@SL for update
   
   	if @SLitcursor=0
   		begin
   		/* open cursor */
   		open bcSLIT
   
   		/* set open cursor flag to true */   
   		select @SLitcursor = 1
   		end
   
   	/* loop through all items on this SL */
   	item_loopa:
   	fetch next from bcSLIT into @SLitem, @itemtype, @bocost, @bounits, @curunitcost,
   		@invunits, @invcost, @um
   
   	if (@@fetch_status <> 0) goto posting_loopb
   
   	/* get next available transaction # for SLCD */
   
   	select @bounits=InvUnits-CurUnits, @bocost=InvCost-CurCost from bSLIT
   		where SLCo=@co and SL=@SL and SLItem=@SLitem
   
   	select @tablename = 'bSLCD'
   	exec @SLtrans = bspHQTCNextTrans @tablename, @co, @mth, @errmsg output
    select @errmsg = isnull(@errmsg,'') + ' T:' + convert(varchar(5), @seq)
   	if @SLtrans = 0
   		begin
     	select @errmsg = isnull(@errmsg,'') + ' T:' + convert(varchar(5), @seq), @errflag = 'i'
    	goto posting_error
   	   	end
   
   	if @itemtype <> 3 and (@bounits<>0 or @bocost<>0)
   		begin
   		/* insert SL Change Detail */
   		insert bSLCD (SLCo, Mth, SLTrans, SL, SLItem, SLChangeOrder, ActDate, Description, UM, ChangeCurUnits,   
   			ChangeCurUnitCost, ChangeCurCost, BatchId, PostedDate, InUseBatchId)
   	 	values (@co, @mth, @SLtrans, @SL, @SLitem, 0, @closedate, @description, @um, @bounits, 0,
   			/* #29530 Case when @um='LS' then */ @bocost /* else 0 end*/, @batchid, @dateposted, null)
   		if @@rowcount = 0
   			begin
    		select @errmsg = isnull(@errmsg,'') + ' A:' + convert(varchar(5), @seq), @errflag = 'i'   
   	 		goto posting_error
   			end   
   		end
   
   	update bSLIT
   	set CurUnits=InvUnits,   
   		CurCost= InvCost,
		CurTax = InvTax  --DC #128435
   	where SLCo=@co and SL=@SL and SLItem=@SLitem
   
   	goto item_loopa
   
   	posting_loopb:
   	if @SLitcursor=1
   		begin   
   		close bcSLIT
   		deallocate bcSLIT
   		select @SLitcursor=0
   		end
   
   	update bSLHD
   	set Status=2, MthClosed=@mth,
		SLCloseBatchID = @batchid  --DC #127181
   	where SLCo=@co and SL=@SL
   
   		/* delete current row from cursor */
	delete from bSLXB where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq   
	if @@rowcount <> 1
		begin
   	    rollback transaction
        select @errmsg = 'Error removing batch sequence ' + convert(varchar(10), @seq) + ' from batch.'
        goto bspexit
   		end
   
   	/* commit transaction */
   	commit transaction
   
   	goto posting_loopa      
   
   posting_error:		/* error occured within transaction - rollback any updates and continue */
   	rollback transaction
   	if @errflag = 'i' goto item_loopa
   	if @errflag = 'j' goto jcposting_loopa
   
   posting_loop_end:	/* no more rows to process */
   	/* make sure batch is empty */
      
   	if exists(select * from bSLXB where Co = @co and Mth = @mth and BatchId = @batchid)
   		begin
   		select @errmsg = isnull(@errmsg,'') + 'Not all batch entries were posted - unable to close batch!', @rcode = 1
   		goto bspexit
   		end
   
   -- set interface levels note string
       select @Notes=Notes from bHQBC
       where Co = @co and Mth = @mth and BatchId = @batchid
       if @Notes is NULL select @Notes='' else select @Notes=@Notes + char(13) + char(10)
       select @Notes=@Notes +
           'JC Interface set at: Y' -- DC #130749  + convert(char(1), a.CmtdDetailToJC) + char(13) + char(10)
       -- DC #130749 from bSLCO a where SLCo=@co
   
   	/* delete HQ Close Control entries */
   	delete bHQCC where Co = @co and Mth = @mth and BatchId = @batchid
   
   	/* clear SL Receipts JC Audit entries */
   	delete bSLXA where SLCo = @co and Mth = @mth and BatchId = @batchid
   
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
   
   	if @SLxbcursor = 1
   		begin
   		close bcSLXB
   		deallocate bcSLXB
   		end
   	if @SLxacursor=1
   		begin
   		close bcSLXA
   		deallocate bcSLXA   
   		end
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspSLXBPost] TO [public]
GO
