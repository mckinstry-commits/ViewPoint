SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspSLHBInsertExistingTrans]
	/************************************************************************
	* Created ???
	* Modified by: MV 7/9/01 -Issue 12769 BatchUserMemoInsertExisting
	*              kb 8/21/1 - issue #14335
	*              TV 06/04/02 insert UniqueAttchID into batch header
	*			     MV 08/01/02 - #18173 added cursor to update bSLIB user memos
	*				 RT 12/03/03 - issue 23061, use isnulls when concatenating strings.
	*				DC 09/04/07 - #125159, Values for UD item fields not added back to batch
	*					The issue was because of a misplaced GOTO bspexit & END statement
	*				DC 06/26/08 - #128435 - Add taxes to SL
	*				DC 11/11/08 - #130029 - JCCD tax amounts doesn't match SLIT after tax rate change
	*				DC 03/30/09 - #129889 - AUS SL - Track Claimed  and Certified amounts
	*				DC 12/30/09 - #130175 - SLIT needs to match POIT
	*				DC 02/03/10 - #129892 - Handle max retainage
	*				DC 6/24/10 - #135813 - expand subcontract number 
	*				JG 9/23/10 - TFS# 491 - Inclusions/Exclusions
	*				JG 10/06/10 - TFS# 491 - Inclusions/Exclusions
	*				GF 11/09/2012 TK-18033 SL Claim Enhancement. Changed to Use ApprovalRequired
	*
	*
	* This procedure is used by the SL Entry program to pull existing
	* transactions from bSLHD into bSLHB for editing.
	*
	* Checks batch info in bHQBC, and transaction info in bSLHD.
	* Adds entry to next available Seq# in bSLHB.
	*
	* SLHB insert trigger will update InUseBatchId in bSLHD
	*
	* pass in Co, Mth, BatchId, and SL Trans#
	* returns 0 if successfull
	* returns 1 and error msg if failed
	*
	*************************************************************************/    
	@co bCompany, @mth bMonth, @batchid bBatchID,
	@sl VARCHAR(30), --bSL,   DC #135813
	@includeitems bYN, @errmsg varchar(120) output
    
     as
     set nocount on
     declare @rcode int,@inusemth bMonth, @status tinyint, @slstatus tinyint,
     	 @inusebatchid bBatchID, @seq int, @errtext varchar(200), @source bSource,
   		@openslib int, @slitem int
    
     select @rcode = 0
    
     /* validate HQ Batch */
     exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, 'SL Entry', 'SLHB', @errtext output, @status output
     if @rcode <> 0
        begin
		select @errmsg = @errtext, @rcode = 1
		goto bspexit
        end
    
     if @status <> 0
        begin
		select @errmsg = 'Invalid Batch status -  must be (open)!', @rcode = 1
		goto bspexit
        end
    
     /* validate existing SL Change Order Trans */
     select  @inusemth=InUseMth, @inusebatchid=InUseBatchId, @slstatus=Status
     	from bSLHD Where SL=@sl and SLCo=@co
     if @@rowcount = 0
     	begin
     	select @errmsg = 'Subcontract ' + isnull(convert(VARCHAR(30),@sl),'') + ' not found!', @rcode = 1  --DC #135813
     	goto bspexit
     	end
     if @inusebatchid is not null
     	begin
     	select @source=Source
     	from HQBC
     	where Co=@co and BatchId=@inusebatchid and Mth=@inusemth
     	if @@rowcount<>0
     		begin
     		select @errmsg = 'SL already in use by ' +
     					isnull(convert(varchar(2),DATEPART(month, @inusemth)) + '/' +
     					substring(convert(varchar(4),DATEPART(year, @inusemth)),3,4),'') +
     					' batch # ' + isnull(convert(varchar(6),@inusebatchid),'') + ' - ' + 'Batch Source: ' + isnull(@source,''), @rcode = 1
     		goto bspexit
     		end
     	else
     	    begin
     		select @errmsg='Transaction already in use by another batch!', @rcode=1
     		goto bspexit
     	    end
     	end
     if @slstatus = 3
     	begin
     	select @errmsg = 'The SL:' + isnull(@sl,'') + ' status is pending.' , @rcode = 1
     	goto bspexit
     	end    
    
     /* get next available sequence # for this batch */
     select @seq = isnull(max(BatchSeq),0)+1 from bSLHB where Co = @co and Mth = @mth and BatchId = @batchid
    
     /* add Subcontract to SLHB*/
    
     insert into bSLHB (Co, Mth, BatchId, BatchSeq, BatchTransType, SL, JCCo, Job,
     	Description, VendorGroup, Vendor, HoldCode, PayTerms, CompGroup, Status, Notes,
     	OldJCCo, OldJob, OldDesc, OldVendor, OldHoldCode, OldPayTerms, OldCompGroup,
     	OldStatus, OrigDate, UniqueAttchID, 
		OldOrigDate,  --DC #128435
		MaxRetgOpt, MaxRetgPct, MaxRetgAmt, InclACOinMaxYN, MaxRetgDistStyle
		----TK-18033
		,ApprovalRequired)
     select SLCo, @mth, @batchid, @seq, 'C', SL, JCCo, Job,
     	Description, VendorGroup, Vendor, HoldCode, PayTerms, CompGroup, Status, Notes,
     	JCCo, Job, Description, Vendor, HoldCode, PayTerms, CompGroup, Status, OrigDate, UniqueAttchID,
		OrigDate, --DC #128435
		MaxRetgOpt, MaxRetgPct, MaxRetgAmt, InclACOinMaxYN, MaxRetgDistStyle
		----TK-18033
		,ApprovalRequired
     from bSLHD where SLCo=@co and SL=@sl
     if @@rowcount <> 1
     	begin
     	select @errmsg = 'Unable to add entry to Subcontract Entry Batch!', @rcode = 1
     	goto bspexit
     	end
     	
     /* update user memo to SLHB batch table- BatchUserMemoInsertExisting */
     exec @rcode = bspBatchUserMemoInsertExisting @co, @mth, @batchid, @seq, 'SL Entry', 0, @errmsg output
     if @rcode <> 0
		begin
    	select @errmsg = 'Unable to update user memo to SL Entry Batch!', @rcode = 1
    	goto bspexit
    	end
    
    
    /* Copy inclusions/exclusions over - JG TFS# 491 */
    INSERT INTO vSLInExclusionsBatch	(Co, Mth, BatchId, BatchSeq, Seq, BatchTransType
										, [Type], PhaseGroup, Phase, Detail, DateEntered, EnteredBy
										, Notes, UniqueAttchID)
	SELECT	@co, @mth, @batchid, @seq, i.Seq
			, 'C', i.[Type], i.PhaseGroup, i.Phase, i.Detail, i.DateEntered
			, i.EnteredBy, i.Notes, i.UniqueAttchID
    FROM vSLInExclusions i
    WHERE i.Co=@co AND i.SL=@sl
    
	if @includeitems = 'Y'
		begin
		insert into bSLIB(Co, Mth, BatchId, BatchSeq, SLItem, BatchTransType, ItemType,
				Addon, AddonPct, JCCo, Job, PhaseGroup, Phase, JCCType, Description,
				UM, GLCo, GLAcct, WCRetPct, SMRetPct, VendorGroup, Supplier,
				OrigUnits, OrigUnitCost, OrigCost, Notes,
				OldItemType, OldAddon, OldAddonPct, OldJCCo, OldJob, OldPhaseGroup,
				OldPhase, OldJCCType, OldDesc, OldUM, OldGLCo, OldGLAcct, OldWCRetPct,
				OldSMRetPct, OldSupplier, OldOrigUnits, OldOrigUnitCost, OldOrigCost,
				TaxType,TaxCode,TaxGroup,OrigTax,  --DC #128761
				OldTaxType,OldTaxCode,OldTaxGroup,OldOrigTax, --DC #128761
				JCCmtdTax, OldJCCmtdTax,  --DC #130029
				TaxRate, GSTRate, OldTaxRate, OldGSTRate, JCRemCmtdTax, OldJCRemCmtdTax)  --DC #130175				
		select SLCo, @mth, @batchid, @seq, SLItem,'C', ItemType,
				Addon, AddonPct, JCCo, Job, PhaseGroup, Phase, JCCType, Description,
				UM, GLCo, GLAcct, WCRetPct, SMRetPct, VendorGroup, Supplier,
				OrigUnits, OrigUnitCost, OrigCost, Notes,
				ItemType, Addon, AddonPct, JCCo, Job, PhaseGroup,
				Phase, JCCType, Description, UM, GLCo, GLAcct, WCRetPct,
				SMRetPct, Supplier, OrigUnits, OrigUnitCost, OrigCost,
				TaxType,TaxCode,TaxGroup,OrigTax, --DC #128761
				TaxType,TaxCode,TaxGroup,OrigTax,  --DC #128761
				JCCmtdTax, JCCmtdTax,  --DC #130029
				TaxRate, GSTRate, TaxRate, GSTRate, JCRemCmtdTax, JCRemCmtdTax --DC #130175
		from bSLIT where SLCo=@co and SL =@sl
    	if @@rowcount > 0 
   			begin
				-- update user memo to SLIB batch table- BatchUserMemoInsertExisting 
				-- Declare cursor on SLIB to update user memos in line items 
				declare SLIB_cursor cursor for select Co,Mth, BatchId,BatchSeq, SLItem from bSLIB
				where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq for update
    			open SLIB_cursor
				select @openslib = 1
				-- loop through all rows in this batch 
				SLIB_cursor_loop:
				fetch next from SLIB_cursor into @co,@mth, @batchid, @seq, @slitem
				if @@fetch_status = -1 goto SL_posting_end
				if @@fetch_status <> 0 goto SLIB_cursor_loop
				if @@fetch_status = 0
				begin
					exec @rcode = bspBatchUserMemoInsertExisting @co, @mth, @batchid, @seq, 'SL Entry Items',
					@slitem, @errmsg output
					if @rcode <> 0
						begin
	     				select @errmsg = 'Unable to update user memo to SL Entry Item Batch!', @rcode = 1
	     				goto bspexit
	     				end
					/* DC 09/04/07 - #125159
		    		 goto bspexit
					end */
					goto SLIB_cursor_loop   --get the next seq
				end
			END  -- DC 09/04/07 - #125159
    		
	      SL_posting_end:
	          if @openslib = 1
	              begin
					close SLIB_cursor
					deallocate SLIB_cursor
					select @openslib = 0
	              end
   			end       	
    
     bspexit:
   	if @openslib = 1
            begin
            close SLIB_cursor
            deallocate SLIB_cursor
            select @openslib = 0
            end
     	return @rcode
GO
GRANT EXECUTE ON  [dbo].[bspSLHBInsertExistingTrans] TO [public]
GO
