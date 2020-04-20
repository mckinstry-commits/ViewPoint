SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspSLHBVal]
/***********************************************************
* CREATED BY: SE   5/28/97
* MODIFIED By : SE 5/28/97
* MODIFIED By : kb 8/30/99
*               EN 5/10/00 - produce error if try to delete partially invoiced item
*               kb 12/14/00 - issue #7640
*               kb 8/8/1 - issue #14268
*               kb 10/10/1 - issue #14804
*               danf 09/05/02 - 17738 added phase group to bspJobTypeVal
*				SR 09/10/02 - issue 18508- Header Status must be Open or Pending - cannot delete item
*				SR 09/17/02 - issue 18601
*				GG 09/30/02 - #18601 - cleanup
*				MV 01/21/03 - #20008 - fixed err msg for Delete of SL Header
*				MV 02/18/03 - #20237 - compgroup validation
*				RT 12/03/03 - issue 23061, use isnulls when concatenating strings.
*				ES 03/09/04 - Issue 23730 Check for unapproved invoices 
*				MV 06/15/04 - #24810 - validate unique SL # in other open batches.  For imports.
*				DC	8/10/07 - #124025 - has mispelled word "deleteed"
*				DC  06/23/08 - #128435 - Add Tax to SL
*				DC  11/10/08 - #130029 - JCCD tax amounts doesn't match SLIT after tax rate change
*				DC  04/21/09 - #132527 -  incorrect units/amounts in SLIA when adding SL back in
*				DC 09/03/09 - #134351 - Adding SL with change order back into batch produces a JC Distribution
*				DC 12/23/09 - #130175 - SLIT needs to match POIT
*				DC 06/25/10 - #135813 - expand subcontract number  (** removed unused varibles.)
*				GF 09/09/2010 - issue #141031 changed to use function vfDateOnly
*				JG 09/23/2010 - TFS# 491 - Inclusions/Exclusions Delete Validation
*				GF 09/28/2010 - issue #141349 better error messages (with SL)
*				JG 10/06/2010 - TFS# 491 - Inclusions/Exclusions Delete Validation
*
* USAGE:
* Validates each entry in bSLHB and bSLIB for a selected batch - must be called
* prior to posting the batch.
*
* INPUT PARAMETERS
*   @co			SL Co#
*   @mth			Month of batch
*   @batchid		Batch ID to validate
*	 @source		Batch source
*
* OUTPUT PARAMETERS
*   @errmsg     if something went wrong
*
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/   
   	@co bCompany = null, @mth bMonth = null, @batchid bBatchID = null, @source bSource = null,
   	@errmsg varchar(255) output
   as
   
   set nocount on
   
DECLARE @rcode int, @errortext varchar(255), 
   	@status tinyint, @opencursorSLHB tinyint, @opencursorSLIB tinyint,
   	@itemcount int, @deletecount int, @errorstart varchar(50), @slhbmth bMonth, @slhbbatchid bBatchID,
   	@inexcount int, @delinexcount int
   
/*Header declares*/
DECLARE @transtype char(1), @sl VARCHAR(30), --bSL, DC #135813
	@seq int, @jcco bCompany, @job bJob, --@description bItemDesc, --bDesc, DC #135813
	@vendorgroup bGroup, @vendor bVendor, @compgroup varchar(10), @holdcode bHoldCode, @payterms bPayTerms,
	@compgropu varchar(10), @oldjcco bCompany, @oldjob bJob, --@olddesc bItemDesc, -- bDesc,  DC #135813
	@oldvendor bVendor, @oldholdcode bHoldCode, @oldpayterms bPayTerms, @oldcompgroup varchar(10),
	@oldstatus tinyint,
	@origdate bDate  --DC #128435
   
/*item declares*/
DECLARE @slitem bItem, @itemtranstype char(1), @itemtype tinyint, @addon tinyint, @addonpct bPct,
   	@phasegroup bGroup, @phase bPhase,@jcctype bJCCType, @um bUM,  @glco bCompany, @glacct bGLAcct,
   	@wcretpct bPct, @smretpct bPct, @supplier bVendor,  @origunits bUnits, @origunitcost bUnitCost,
   	@origcost bDollar, @itemdescription bItemDesc, @olditemtype tinyint, @oldaddon tinyint, @oldaddonpct bPct,
   	@oldphasegroup bGroup, @oldphase bPhase,@oldjcctype bJCCType, --@olddescription bItemDesc,  DC #135813
   	@oldum bUM,  @oldglco bCompany, @oldglacct bGLAcct, @oldwcretpct bPct, @oldsmretpct bPct,
   	@oldsupplier bVendor,  @oldorigunits bUnits, @oldorigunitcost bUnitCost,
   	@oldorigcost bDollar, @olditemdesc bItemDesc,
	@taxgroup bGroup, @taxcode bTaxCode, @taxtype tinyint, @origtax bDollar,  --DC #128435
	@oldtaxgroup bGroup, @oldtaxcode bTaxCode, @oldtaxtype tinyint, @oldorigtax bDollar  --DC #128435
   
DECLARE @jcum bUM, @oldjcum bUM, @jcumconv bRate, @oldjcumconv bRate, @slitinvunits bUnits, @slitinvcost bDollar,
	@slitorigunits bUnits, @slitorigcost bDollar, @slitcurunits bUnits, @slitcurcost bDollar, @activity tinyint,
	@dateposted bDate, @taxrate bRate, --DC #128435
	@oldtaxphase bPhase, @oldtaxct bJCCType, @oldtaxjcum bUM,  --DC #128435
	@taxphase bPhase, @taxct bJCCType, @taxjcum bUM,  --DC #128435
	@gstrate bRate, @pstrate bRate, @HQTXcrdGLAcct bGLAcct, @HQTXcrdGLAcctPST bGLAcct,  --DC #128435
	@HQTXdebtGLAcct bGLAcct, @slitcurtax bDollar, @currentunits bUnits, @currenttax bDollar,  --DC #128435
	@cmtdunits bUnits, @cmtdcost bDollar, @valueadd char(1), @oldvalueadd char(1), --DC #128435
	@oldtaxrate bRate, @oldHQTXdebtGLAcct bGLAcct, --DC #128435
	@oldgstrate bRate, @oldpstrate bRate,  --DC #128435
	@oldjccmtdtax bDollar,  --DC #130029
	@jccmtdtax bDollar, --DC #134351
	@gsttaxamt bDollar, @tempgsttaxamt bDollar, @psttaxamt bDollar,
	@oldjcremcmtdtax bDollar, @jcremcmtdtax bDollar, @slitinvtax bDollar, @cmtdremcost bDollar, @remtax bDollar --DC #130175

select @rcode = 0, @jcumconv=0, @oldjcumconv=0, @opencursorSLHB = 0,@opencursorSLIB = 0
----#141031
set @dateposted = dbo.vfDateOnly()
   
	/* validate HQ Batch */
	exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, @source, 'SLHB', @errmsg output, @status output
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
   
	/* clear HQ Batch Errors */
	delete bHQBE where Co = @co and Mth = @mth and BatchId = @batchid

	/* clear JC Distributions Audit */
	delete bSLIA where SLCo = @co and Mth = @mth and BatchId = @batchid

	/* declare cursor on PO Header Batch for validation */
	declare bcSLHB cursor for
	select BatchSeq, BatchTransType, SL, VendorGroup, Vendor, HoldCode, PayTerms,
		CompGroup, Status, OldVendor,
		OrigDate  --DC #128435
	from bSLHB
	where Co = @co and Mth = @mth and BatchId = @batchid
	  
	open bcSLHB
	select @opencursorSLHB = 1
   
	header_loop:
	fetch next from bcSLHB into @seq, @transtype, @sl, @vendorgroup, @vendor, @holdcode, @payterms,
      		@compgroup, @status, @oldvendor, 
			@origdate  --DC #128435
   
   	if @@fetch_status <> 0 goto header_end
   
    	/* validate SL Detail Batch info for each entry */
    	----#141349
     	select @errorstart = 'SL: ' + ISNULL(@sl,'') + ' Seq#: ' + convert(varchar(6),@seq)
   
     	if @transtype not in('A','C','D')  /* validate transaction type */
       		begin
         	select @errortext = @errorstart + ' -  Invalid transaction type, must be ''A'',''C'', or ''D''.'
         	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
         	if @rcode <> 0 goto bspexit
   			goto header_loop
        	end
   
      	/* validation specific to Add types of SL Header*/
     	if @transtype = 'A'
        	begin
        	/* check SL to make sure it is unique */
         	if @sl is null
   	 			begin
   	  			select @errortext = @errorstart + ' - Subcontract may not be null!'
             	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
    	  		if @rcode <> 0 goto bspexit
   				goto header_loop
   	 			end
   			if exists(select 1 from bSLHD WITH (NOLOCK) where SLCo=@co and SL=@sl)
   	   			begin
   	    		select @errortext = @errorstart + ' - Subcontract already exists!'
    	    	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   	    		if @rcode <> 0 goto bspexit
   				goto header_loop
   	   			end
        	/* check SL uniqueness in current batch */
         	if exists(select 1 from bSLHB WITH (NOLOCK) where Co=@co and Mth=@mth and BatchId=@batchid and  SL=@sl and BatchSeq<>@seq)
   	 			begin
   	  			select @errortext = @errorstart + ' - Subcontract already exists in this batch!'
    	  		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   	  			if @rcode <> 0 goto bspexit
   				goto header_loop
   	 			end
   			-- check for uniqueness in other open batches for imports - #24810
			select @slhbmth = Mth, @slhbbatchid = BatchId from bSLHB WITH (NOLOCK) where Co=@co and (Mth<> @mth or BatchId<>@batchid) and  SL = @sl
			if @@rowcount <> 0
				begin
				select @errortext = @errorstart + ' - SL number already exists in Month: ' + convert(varchar(8), @slhbmth, 1) +
					' BatchId: ' + convert(varchar(10),@slhbbatchid)
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				goto header_loop
				End
        	end /*Add Types */
   
   		/* validation specific for Add and Change of SL Header */
		if @transtype in('A','C')
   			begin
   			-- check for uniqueness in other open batches for imports - #24810
			select @slhbmth = Mth, @slhbbatchid = BatchId from bSLHB WITH (NOLOCK) where Co=@co and (Mth<> @mth or BatchId<>@batchid) and  SL = @sl
			if @@rowcount <> 0
				begin
				select @errortext = @errorstart + ' - SL number already exists in Month: ' + convert(varchar(8), @slhbmth, 1) +
					' BatchId: ' + convert(varchar(10),@slhbbatchid)
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				goto header_loop
				End
   			/* make sure vendor exists */
			if not exists(select 1 from bAPVM WITH (NOLOCK) where VendorGroup=@vendorgroup and Vendor=@vendor)
   	    		begin
   	     		select @errortext = @errorstart + ' - Vendor ' + isnull(convert(varchar(10),@vendor),'') + ' is not a valid vendor!'
   	     		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   	     		if @rcode <> 0 goto bspexit
   				goto header_loop
   	    		end
   			/*validate compliance */
   			if @compgroup is not null
   				begin
   		 		select 1 from bHQCG WITH (NOLOCK) where CompGroup = @compgroup
   				if @@rowcount = 0
   			 		begin
   			 		select @errortext = @errorstart + ' - Compliance group ' + isnull(@compgroup,'') + ' is not valid.'
   			 		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   		      		if @rcode <> 0 goto bspexit
   					goto header_loop
   		     		end
   				end	   
			end /*A-C Val*/
   
   		/* validation specific for Delete of SL Header */
		if @transtype = 'D' 
			begin	
			-- check for Worksheets
			if exists(select 1 from bSLWH WITH (NOLOCK) where SLCo = @co and SL = @sl)
				begin
				select @errortext = @errorstart + ' - Subcontract assigned to a Worksheet, cannot be deleted.'
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				goto header_loop
				end
   			-- check Compliance Tracking
			if exists(select 1 from bSLCT WITH (NOLOCK) where SLCo=@co and SL=@sl)
 				begin
 				select @errortext = @errorstart + ' - Subcontract has Compliance entries, cannot be deleted.'  --#124025
  				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
  				if @rcode <> 0 goto bspexit
				goto header_loop
 				end
 			
 			-- make sure all Inclusions/Exclusions are in the batch and flagged for deletion - JG TFS# 491
 			select @inexcount = count(*) from vSLInExclusions WITH (NOLOCK) where Co=@co and SL=@sl
			SELECT @delinexcount = COUNT(*)
			FROM vSLInExclusionsBatch WITH (NOLOCK)
			WHERE Co=@co AND Mth=@mth AND BatchId=@batchid AND BatchSeq=@seq AND BatchTransType='D'
			if @inexcount <> @delinexcount
				begin
				select @errortext = @errorstart + ' - In order to delete a Subcontract all Inclusions/Exclusions must be deleted in the current batch.'
   	     		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   	     		if @rcode <> 0 goto bspexit
   				goto header_loop
				end
			-- make sure the batch does not contain any 'add' or 'change' inclusions/exclusions for the SL
			select @inexcount = count(*) 
			from vSLInExclusionsBatch 
			WITH (NOLOCK) where Co=@co 
							and BatchId=@batchid 
							and BatchSeq=@seq
							and BatchTransType<>'D'
			if @inexcount <> 0
				begin
				select @errortext = @errorstart + ' - In order to delete a Subcontract you cannot have any add or change Inclusions/Exclusions associated with it.'
   	     		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   	     		if @rcode <> 0 goto bspexit
   				goto header_loop
				end
 				
   			-- make sure all items are in the batch and flagged for deletion
			select @itemcount = count(*) from bSLIT WITH (NOLOCK) where SLCo=@co and SL=@sl
			select @deletecount= count(*)
   			from bSLIB WITH (NOLOCK)
   			where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq and BatchTransType='D'
			if @itemcount <> @deletecount
   	    		begin
   	     		select @errortext = @errorstart + ' - In order to delete a Subcontract all Items must be in the current batch and marked for delete.'
   	     		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   	     		if @rcode <> 0 goto bspexit
   				goto header_loop
   	    		end
   			-- make sure the batch does not contain any 'add' or 'change' item for the subcontract
			select @deletecount= count(*)
   			from bSLIB WITH (NOLOCK)
   			where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq and BatchTransType <> 'D'
			if @deletecount <>0
   	    		begin
   	     		select @errortext = @errorstart + ' - In order to delete a Subcontract you cannot have any add or change Items associated with it.'
   	     		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   	     		if @rcode <> 0 goto bspexit
   				goto header_loop
   	    		end
   			end

		--DC #128435
 		-- need to make sure original tax is 0 if no tax code 
 		update bSLIB 
 		set OrigTax = 0,
 			JCCmtdTax = 0, JCRemCmtdTax = 0, TaxRate = 0, GSTRate = 0  --DC #130175
 		where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq and TaxCode is null
   
   		/* now validate all the items for this Subcontract */
		declare bcSLIB cursor for
   		select SLItem, BatchTransType,ItemType, Addon, AddonPct, JCCo, Job,
   			PhaseGroup, Phase, JCCType, Description, UM, GLCo, GLAcct, WCRetPct, SMRetPct,
   			VendorGroup, Supplier, OrigUnits, OrigUnitCost, OrigCost,
        	OldItemType, OldAddon, OldAddonPct, OldJCCo, OldJob, OldPhaseGroup,
        	OldPhase, OldJCCType, OldDesc, OldUM, OldGLCo, OldGLAcct, OldWCRetPct,
        	OldSMRetPct, OldSupplier, OldOrigUnits, OldOrigUnitCost, OldOrigCost,
			TaxType, TaxCode, TaxGroup,OrigTax, --DC #128435
			OldTaxType,OldTaxCode,OldTaxGroup,OldOrigTax,  --DC #128435			
			OldJCCmtdTax,   --DC #130029			
			JCCmtdTax, --DC #134351
			OldJCRemCmtdTax, -- DC #130175
			TaxRate, GSTRate, OldTaxRate, OldGSTRate, JCRemCmtdTax  --DC #130175			
   		from bSLIB WITH (NOLOCK)
   		where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq=@seq
   
		open bcSLIB
		select @opencursorSLIB = 1
   
   	item_loop:
   		fetch next from bcSLIB into @slitem, @itemtranstype, @itemtype, @addon, @addonpct, @jcco, @job,
   			@phasegroup, @phase, @jcctype, @itemdescription, @um, @glco, @glacct, @wcretpct, @smretpct,
   			@vendorgroup, @supplier, @origunits, @origunitcost, @origcost,
        		@olditemtype, @oldaddon, @oldaddonpct, @oldjcco, @oldjob, @oldphasegroup,
        		@oldphase, @oldjcctype, @olditemdesc, @oldum, @oldglco, @oldglacct, @oldwcretpct,
        		@oldsmretpct, @oldsupplier, @oldorigunits, @oldorigunitcost, @oldorigcost,
				@taxtype, @taxcode, @taxgroup, @origtax, --DC #128435
				@oldtaxtype, @oldtaxcode, @oldtaxgroup, @oldorigtax,   --DC #128435				
				@oldjccmtdtax,  --DC #130029
				@jccmtdtax,  --DC #134351
				@oldjcremcmtdtax, -- #130175
				@taxrate, @gstrate, @oldtaxrate, @oldgstrate, @jcremcmtdtax  --DC #130175   
   
   		if @@fetch_status <> 0 goto item_end
   
		--DC #132748
		--Reset tax varibles
		select @origtax = 0, @currenttax = 0, @gsttaxamt = 0, @psttaxamt = 0	
   
     	/* validate SL item Detail Batch info for each entry */
     	----#141349
      	select @errorstart = 'SL: ' + ISNULL(@sl,'') + ' Seq#: ' + isnull(convert(varchar(6),@seq),'') + ' Item: ' + isnull(convert(varchar(6),@slitem),'') + ' '

      	/* validate transaction type */
      	if @itemtranstype not in('A','C','D')
         	begin
   			select @errortext = @errorstart + ' -  Invalid transaction type, must be ''A'',''C'', or ''D''.'
   			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   			if @rcode <> 0 goto bspexit
			goto item_loop
  			end

 		-- DC  #128435
 		-- need to calculate orig tax for existing item when tax code was null now not null
		if isnull(@taxcode,'') <> ''			
			begin
 			-- if @origdate is null use today's date
 			if isnull(@origdate,'') = '' select @origdate = @dateposted
 			-- get Tax Rate
 			--select @taxrate = 0
 			select @pstrate = 0  --DC #130175

			--DC #122288
			exec @rcode = vspHQTaxRateGet @taxgroup, @taxcode, @origdate, @valueadd output, NULL, NULL, NULL, 
				NULL, NULL, NULL, NULL, @HQTXdebtGLAcct output, NULL, NULL, NULL, @errmsg output						
			if @rcode <> 0
				begin
				select @errortext = @errorstart + 'Company : ' + isnull(convert(varchar(10),@co),'') + ' - Tax Group : ' + isnull(convert(varchar(3), @taxgroup),'')
				select @errortext = @errortext + ' - TaxCode : ' + isnull(@taxcode,'') + ' - is not valid! - ' + @errmsg
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				end
				
			select @pstrate = (case when @gstrate = 0 then 0 else @taxrate - @gstrate end)				

			if @gstrate = 0 and @pstrate = 0 and @valueadd = 'Y'
				begin
				-- We have an Intl VAT code being used as a Single Level Code
				if (select GST from bHQTX with (nolock) where TaxGroup = @taxgroup and TaxCode = @taxcode) = 'Y'
					begin
					select @gstrate = @taxrate
					end
				end

			select @origtax = @origcost * @taxrate		--Full TaxAmount:  This is correct whether US, Intl GST&PST, Intl GST only, Intl PST only		1000 * .155 = 155
			select @gsttaxamt = case @taxrate when 0 then 0 else case @valueadd when 'Y' then (@origtax * @gstrate) / @taxrate else 0 end end --GST Tax Amount.  (Calculated)					(155 * .05) / .155 = 50
			select @psttaxamt = case @valueadd when 'Y' then @origtax - @gsttaxamt else 0 end			--PST Tax Amount.  (Rounding errors to PST)

			end /* tax code validation*/
   
   		/* validation specific for Add and Change*/
   		if @itemtranstype in ('A','C')
   	   		begin
   	   		/* make sure its a valid  Item Type*/
   	    	if @itemtype not in (1,2,3,4)
   	       		begin
   				select @errortext = @errorstart + ' - Item type must be 1, 2, 3, or 4.'
    	 		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   				if @rcode <> 0 goto bspexit
   				goto item_loop
   	       		end
   
            /* validate Unit of measure */
   	    	if not exists(select 1 from bHQUM where UM = @um)
   	       		begin
   				select @errortext = @errorstart + ' - UM ' + isnull(@um,'') + ' is not setup in HQ Units of Measure'
    	        exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   				if @rcode <> 0 goto bspexit
   				goto item_loop
   	       		end
   
    	    -- validate Job info
   			exec @rcode = bspJobTypeVal @jcco, @phasegroup, @job, @phase, @jcctype, @jcum output, @errmsg output
   			if @rcode <> 0
   		   		begin
   		    	select @errortext = @errorstart + ' - ' + isnull(@errmsg,'')
   		    	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   		    	if @rcode <> 0 goto bspexit
   				goto item_loop
   		   		end
   
   			-- assign U/M conversion for 'actual' units update to JC
           	if @jcum is null select @jcum = @um
   			if @um = @jcum
   		   		select @jcumconv = 1	
   			else
   		   		select @jcumconv = 0
   
   			-- validate Job Expense GL Account, must be subledger type 'J'
   			exec @rcode = bspGLACfPostable @glco, @glacct, 'J', @errmsg output
   			if @rcode <> 0
   		   		begin
   		    	select @errortext = @errorstart + '- GL Account:' + isnull(@glacct,'') + ':  ' + isnull(@errmsg,'')
   		    	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   		    	if @rcode <> 0 goto bspexit
   				goto item_loop
   		   		end
   
   			-- make sure month is open
   	       	exec @rcode = bspGLMonthVal @glco, @mth, @errmsg output
   	       	if @rcode <> 0
   	          	begin
   	           	select @errortext = @errorstart + ' - ' + isnull(@errmsg,'')
    	        exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   		   		if @rcode <> 0 goto bspexit
   				goto item_loop
   		  		end
   
			set @taxphase = null
			set @taxct = null
			-- get old Tax code info
			if @taxcode is not null
				begin
				exec @rcode = bspPOTaxCodeVal @taxgroup, @taxcode, @taxtype, @taxphase output, @taxct output, @errmsg output
				if @rcode <> 0
					begin
					select @errortext = @errorstart + '- entries ' + isnull(@errmsg,'')
					exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
					if @rcode <> 0 goto bspexit
					End

				if @taxphase is null select @taxphase = @phase
				if @taxct is null select @taxct = @jcctype
   	    		-- validate 'old' job info
   				exec @rcode = bspJobTypeVal @jcco, @phasegroup, @job, @taxphase, @taxct, @taxjcum output, @errmsg output
   				if @rcode <> 0
   	       			begin
   	        		select @errortext = @errorstart + '- entries ' + isnull(@errmsg,'')
   	        		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   	        		if @rcode <> 0 goto bspexit
   					goto item_loop
   	       			end
				End

   			-- validate Lump Sum Items
   	      	if @um = 'LS' and (@origunits <> 0 or @origunitcost <> 0)
                begin
   	            select @errortext = @errorstart + ' - Items with LS unit of measure must have 0.00 Units and Unit Cost.'
    	   		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   		    	if @rcode <> 0 goto bspexit
   				goto item_loop
   	           	end
   	           	
			--update SLIB ! JCCmtdTax column
			--DC #132527
			IF @itemtranstype = 'A' 
				BEGIN
				UPDATE SLIB
				SET JCCmtdTax = isnull(@origtax,0) - (case when @HQTXdebtGLAcct is null then 0 else @gsttaxamt end),
					JCRemCmtdTax = isnull(@origtax,0) - (case when @HQTXdebtGLAcct is null then 0 else @gsttaxamt end)  --DC #130175
				WHERE Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq=@seq and SLItem = @slitem				
				END   	           	   	           				   	           	   	           	   	           	
   	      	end /*A or C */
   
   		-- validation specific to 'change' or 'delete' items
   		if @itemtranstype in ('C','D')
   			begin
			-- validate existing Item
			select @slitinvunits = InvUnits, @slitinvcost = InvCost, @slitorigunits = OrigUnits,
				@slitorigcost = OrigCost, @slitcurunits = CurUnits, @slitcurcost = CurCost,
				@slitcurtax = CurTax, --DC #128435					
				@slitinvtax = InvTax  --DC #130175
			from bSLIT
   			where SLCo = @co and SL = @sl and SLItem = @slitem
			if @@rowcount = 0
				begin
				select @errortext = @errorstart + ' - Invalid Item.'
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				goto item_loop
				end
			-- check for Item activity - limits changes
			select @activity = 0
			if @slitinvunits <> 0 or @slitinvcost<> 0 or @slitorigunits <> @slitcurunits or @slitorigcost <> @slitcurcost select @activity = 1
	   
 			-- Item has had invoice or change order activity, or flagged for deletion
     		if @activity = 1 or @itemtranstype = 'D'	
				begin
	 			if @itemtype <> @olditemtype
					begin
         			select @errortext = @errorstart + ' - Activity exists for this Item, cannot change it''s type.'
             		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     				if @rcode <> 0 goto bspexit
					goto item_loop
            		end
				if @um <> @oldum
					begin
     				select @errortext = @errorstart + ' - Activity exists for this Item, cannot change it''s unit of measure.'
         			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
 					if @rcode <> 0 goto bspexit
					goto item_loop
            		end
				if @jcco <> @oldjcco or @job <> @oldjob
					begin
         			select @errortext = @errorstart + ' - Activity exists for this Item, cannot change it''s Job.'
             		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     				if @rcode <> 0 goto bspexit
					goto item_loop
            		end
	 			if @phase <> @oldphase
					begin
         			select @errortext = @errorstart + ' - Activity exists for this Item, cannot change it''s Phase.'
             		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     				if @rcode <> 0 goto bspexit
					goto item_loop
    				end
	 			if @jcctype <> @oldjcctype
					begin
         			select @errortext = @errorstart + ' - Activity exists for this Item, cannot change it''s Cost Type.'
             		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     				if @rcode <> 0 goto bspexit
					goto item_loop
            		end
				if isnull(@taxcode,'') <> isnull(@oldtaxcode,'')
					begin
					select @errortext = @errorstart + ' - Activity exists for this Item - cannot change Tax Code!'
					exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
					if @rcode <> 0 goto bspexit
					goto item_loop
					End
				if isnull(@taxtype,0) <> isnull(@oldtaxtype,0) and (@slitinvunits<>0 or @slitinvcost<>0)
					begin
					select @errortext = @errorstart + ' Activity exists for this Item - cannot change its Tax Type!'
					exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
					if @rcode <> 0 goto bspexit
					goto item_loop
					End
				end

    	    -- validate Job info
   			exec @rcode = bspJobTypeVal @oldjcco, @oldphasegroup, @oldjob, @oldphase, @oldjcctype, @oldjcum output, @errmsg output
   			if @rcode <> 0
   		   		begin
   		    	select @errortext = @errorstart + ' - ' + isnull(@errmsg,'')
   		    	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   		    	if @rcode <> 0 goto bspexit
   				goto item_loop
   		   		end
   					
			-- assign 'old' U/M conversion for 'actual' units update to JC
			if @oldjcum is null select @oldjcum = @oldum
			if @oldjcum = @oldum
				select @oldjcumconv=1
			else
				select @oldjcumconv=0 

			set @oldtaxphase = null
			set @oldtaxct = null
			-- get old Tax code info
			if @oldtaxcode is not null
				begin
				exec @rcode = bspPOTaxCodeVal @oldtaxgroup, @oldtaxcode, @oldtaxtype, @oldtaxphase output, @oldtaxct output, @errmsg output
				if @rcode <> 0
					begin
					select @errortext = @errorstart + '- Old entries ' + isnull(@errmsg,'')
					exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
					if @rcode <> 0 goto bspexit
					End
				End

            if @oldtaxphase is null select @oldtaxphase = @oldphase
            if @oldtaxct is null select @oldtaxct = @oldjcctype
   	    	-- validate 'old' job info
   			exec @rcode = bspJobTypeVal @oldjcco, @oldphasegroup, @oldjob, @oldtaxphase, @oldtaxct, @oldtaxjcum output, @errmsg output
   		    if @rcode <> 0
   	       		begin
   	        	select @errortext = @errorstart + '- Old entries ' + isnull(@errmsg,'')
   	        	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   	        	if @rcode <> 0 goto bspexit
   				goto item_loop
   	       		end   
			end  /* C or 'D' */
   
   		/* validation specific for Deletes*/
      	if @itemtranstype = 'D'
     		begin
			-- #18508, restrict deletions to 'open' and 'pending' Items
			if exists(select 1 from bSLHD WITH (NOLOCK) where SLCo = @co and SL = @sl and Status not in (0,3))
				begin
				select @errortext = @errorstart + ' - Subcontract must be Open or Pending - cannot delete item.'
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				goto item_loop
				end
			-- check for Change Order detail
			if exists(select 1 from bSLCD WITH (NOLOCK) where SLCo = @co and SL = @sl and @slitem = SLItem)
				begin
				select @errortext = @errorstart + ' - Change Order detail exists, cannot delete Item.'
    			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				goto item_loop
      			end    
			/* The item to be deleted must not have any invoiced units or costs */
    		if (@slitinvcost <> 0 or @slitinvunits <> 0)
   				begin
				select @errortext = @errorstart + ' - Cannot delete Item if Invoiced Units or Invoiced Cost not 0.00!'
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				goto item_loop
   				end
			--Issue 23730 ES 03/09/04 - Check unapproved invoices as well
			if exists (select * from bAPUL WITH (NOLOCK) where APCo = @co and SL = @sl and SLItem = @slitem)
				begin
				declare @UIMth datetime, @UISeq smallint
				select top 1 @UIMth = UIMth, @UISeq = UISeq from bAPUL where APCo = @co and SL = @sl and SLItem = @slitem
     			select @errortext = @errorstart + ' - Unapproved Invoice exists for subcontract Item: ' 
				+ isnull(convert(varchar(2), @slitem), '') + ' UI Month: ' + 
				isnull(convert(varchar(2),DATEPART(month, @UIMth)) + '/' +
				substring(convert(varchar(4),DATEPART(year, @UIMth)),3,4), '') + 
				', UI Seq: ' + isnull(convert(varchar(2), @UISeq), '') + ' -- Cannot delete SL Item!'
         		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
 				if @rcode <> 0 goto bspexit
				goto item_loop
				end   
   	     	end /* deletions */
   
   	update_audit:	/* update SL Entry Batch Distributions */
	if @itemtranstype = 'C' 
		and (@itemtype = @olditemtype 
		and @jcco = @oldjcco 
		and @job = @oldjob 
		and @phase = @oldphase 
		and @jcctype = @oldjcctype 
		and @um = @oldum 
		and @origunits = @oldorigunits 
		and @origcost = @oldorigcost 
		and @jcum = @oldjcum 
		and isnull(@taxcode,'') = isnull(@oldtaxcode,'') --DC #128435
		and isnull(@origtax,0) = isnull(@oldorigtax,0)  --DC #134351
		and isnull(@jccmtdtax,0) = isnull(@oldjccmtdtax,0)) --DC #134351
		and isnull(@jcremcmtdtax,0) = isnull(@oldjcremcmtdtax,0) --DC #130175		     
		goto item_loop	-- skip if no changes
			
   		-- add 'old' entries
   		if @itemtranstype in ('C','D') and @olditemtype <> 3 
			BEGIN
   			-- add SL JC Distribution
 			if @oldtaxphase is null select @oldtaxphase = @oldphase
 			if @oldtaxct is null select @oldtaxct = @oldjcctype
			
			-- if tax is not redirected, add a single entry   
			IF (isnull(@oldtaxphase,'') = isnull(@oldphase,'') and isnull(@oldtaxct,0) = isnull(@oldjcctype,0))
				BEGIN
				insert bSLIA (SLCo, Mth, BatchId, JCCo, Job, PhaseGroup, Phase, JCCType, BatchSeq,
					SLItem, OldNew, SL, Description, VendorGroup, Vendor, ItemType, UM, ChangeUnits,
					ChangeCost, 
					JCUM, JCUnits,
					TotalCmtdTax, RemCmtdTax)  --DC #130175
				values (@co, @mth, @batchid, @oldjcco, @oldjob, @oldphasegroup, @oldphase, @oldjcctype, @seq,
					@slitem, 0, @sl, @olditemdesc, @vendorgroup, @oldvendor, @olditemtype, @oldum, (-1*@slitcurunits),
					(-1*(@slitcurcost+@oldjccmtdtax)), --(-1*(@slitcurcost+@slitcurtax))
					@oldjcum,(-1*(@slitcurunits*@oldjcumconv)), --(-1*(@origunits*@oldjcumconv)))  DC #132527
					(-1 * isnull(@oldjccmtdtax,0)), (-1 * isnull(@oldjcremcmtdtax,0)))  --DC #130175
				END
			ELSE
				BEGIN
				-- tax is redirected, add two entries
				IF @oldorigtax <> 0 or @origtax <> 0
					BEGIN
					insert bSLIA (SLCo, Mth, BatchId, JCCo, Job, PhaseGroup, Phase, JCCType, BatchSeq,
						SLItem, OldNew, SL, Description, VendorGroup, Vendor, ItemType, UM, ChangeUnits,
						ChangeCost, 
						JCUM, JCUnits,
           				TotalCmtdTax, RemCmtdTax)  --DC #130175)						
					values (@co, @mth, @batchid, @oldjcco, @oldjob, @oldphasegroup, @oldtaxphase, @oldtaxct, @seq,
						@slitem, 0, @sl, @olditemdesc, @vendorgroup, @oldvendor, @olditemtype, @oldum, 0,
						(-1*@oldjccmtdtax), --(-1*@slitcurtax)
						@oldjcum,0,
						(-1 * isnull(@oldjccmtdtax,0)), (-1 * isnull(@oldjcremcmtdtax,0)))  --DC #130175						
					END

				insert bSLIA (SLCo, Mth, BatchId, JCCo, Job, PhaseGroup, Phase, JCCType, BatchSeq,
					SLItem, OldNew, SL, Description, VendorGroup, Vendor, ItemType, UM, ChangeUnits,
					ChangeCost, JCUM, JCUnits,
					TotalCmtdTax, RemCmtdTax)  --DC #130175)
				values (@co, @mth, @batchid, @oldjcco, @oldjob, @oldphasegroup, @oldphase, @oldjcctype, @seq,
					@slitem, 0, @sl, @olditemdesc, @vendorgroup, @oldvendor, @olditemtype, @oldum, (-1*@slitcurunits),
					(-1*@slitcurcost), @oldjcum,(-1*(@slitcurunits*@oldjcumconv)),
					0, 0)  --DC #130175)			
				END				
			END							

   			-- add 'new' entries
        if (@itemtranstype in ('A','C') and @itemtype <> 3)		-- exclude 'backcharges'
			BEGIN				 
			 --DC #128435
			select @tempgsttaxamt = case when @HQTXdebtGLAcct is null then 0 else @gsttaxamt end				 
			select @currentunits = case @itemtranstype when 'A' then @origunits else (@slitcurunits + (@origunits - @oldorigunits)) end 
			select @currenttax = case @itemtranstype when 'A' then (@origtax - @tempgsttaxamt) else --Full TaxAmount - GST
				(@slitcurtax  + ((@origtax - @tempgsttaxamt) - @oldorigtax)) end  --Total may not be same as Orig.  We are changing original.  Add difference of
																				--this Trans (Full TaxAmt - GST) - old JC Tax Amt (oldCmtdTaxAmt, which does not include GST) to TotalTax
			
			if @itemtranstype = 'C' 
				begin
				if ((@um <> 'LS' and (@slitcurunits = 0 and @origunits > 0)) or (@um = 'LS' and (@slitcurcost = 0 and @origcost > 0))) 					
					begin	
					select  @currentunits = @origunits, --#30001
							@cmtdunits = @origunits * @jcumconv,--#30001
							@cmtdcost = case @um when 'LS' then @origcost else (@origunits * @origunitcost) end, --#30001
							@currenttax = @origtax - @tempgsttaxamt,		--#30001
							@remtax = ((@origtax - @tempgsttaxamt) - @slitinvtax)							--#130175 (No POIT RecvTax)
					end
				else
					begin
					select	@cmtdunits =  @currentunits  * @jcumconv,
							@cmtdcost = case @um when 'LS' then @slitcurcost + (@origcost - @oldorigcost)  else (@currentunits * @origunitcost) end, --#30001
							--@currenttax = (@slitcurtax  + (@origtax - @oldorigtax))  DC #128435
							@cmtdremcost = case @um when 'LS' then (@cmtdcost - @slitinvcost) else				
										((@currentunits - @slitinvunits)* @origunitcost) end,									
							@remtax = (@cmtdremcost * @taxrate) - case when @taxrate = 0 then 0 else
								(case when @HQTXdebtGLAcct is null then 0 else (((@cmtdremcost * @taxrate) * @gstrate) / @taxrate) end) end,	--(TaxAmount - GST (calculated))  --#30001 (A change gets recalculated using NEW taxrate for NEW record to JCCD)
							@currenttax = (@cmtdcost * @taxrate) - (case @taxrate when 0 then 0 else (case when @HQTXdebtGLAcct is null then 0 else (((@cmtdcost * @taxrate) * @gstrate) / @taxrate) end) end)	-- (TaxAmount - GST (calculated)) --#128925 (A change gets recalculated using NEW taxrate for NEW record to JCCD)  --DC #128435
					end
				end
			else	-- ItemTransType = 'A'
				begin
				select @cmtdunits = @origunits * @jcumconv,
					   @cmtdcost = @origcost,
					   @remtax = @currenttax  --DC #130175
				end

 			IF @taxphase is null select @taxphase = @phase
			IF @taxct is null select @taxct = @jcctype
			IF @taxcode is null select @currenttax = 0

			IF (isnull(@taxphase,'') = isnull(@phase,'') and isnull(@taxct,0) = isnull(@jcctype,0))
				BEGIN
				insert bSLIA (SLCo, Mth, BatchId, JCCo, Job, PhaseGroup, Phase, JCCType, BatchSeq, 
					SLItem, OldNew, SL, Description, VendorGroup, Vendor, ItemType, UM, ChangeUnits,
					ChangeCost, JCUM, JCUnits,
					TotalCmtdTax, RemCmtdTax)  --DC #130175
					values (@co, @mth, @batchid, @jcco, @job, @phasegroup, @phase, @jcctype, @seq,
					@slitem, 1, @sl, @itemdescription, @vendorgroup, @vendor, @itemtype, @um, @currentunits, --@origunits, #132527
					(@cmtdcost+isnull(@currenttax,0)), @jcum, (@currentunits*@jcumconv),--(@origunits*@jcumconv))
					isnull(@currenttax,0), isnull(@remtax,0))  --DC #130175)								 
				END
			ELSE
				BEGIN
				IF @currenttax <> 0 or @remtax <> 0  --DC #130175
					BEGIN
					insert bSLIA (SLCo, Mth, BatchId, JCCo, Job, PhaseGroup, Phase, JCCType, BatchSeq, 
						SLItem, OldNew, SL, Description, VendorGroup, Vendor, ItemType, UM, ChangeUnits,
						ChangeCost, JCUM, JCUnits,
						TotalCmtdTax, RemCmtdTax)  --DC #130175)						
						values (@co, @mth, @batchid, @jcco, @job, @phasegroup, @taxphase, @taxct, @seq,
						@slitem, 1, @sl, @itemdescription, @vendorgroup, @vendor, @itemtype, @um, 0,
						@currenttax, @jcum, 0,
						isnull(@currenttax,0), isnull(@remtax,0))  --DC #130175)
					END				

				insert bSLIA (SLCo, Mth, BatchId, JCCo, Job, PhaseGroup, Phase, JCCType, BatchSeq, 
					SLItem, OldNew, SL, Description, VendorGroup, Vendor, ItemType, UM, ChangeUnits,
					ChangeCost, JCUM, JCUnits,
					TotalCmtdTax, RemCmtdTax)  --DC #130175))					
					values (@co, @mth, @batchid, @jcco, @job, @phasegroup, @phase, @jcctype, @seq,
					@slitem, 1, @sl, @itemdescription, @vendorgroup, @vendor, @itemtype, @um, @currentunits, --@origunits, #132527
					@cmtdcost, @jcum,(@currentunits*@jcumconv), --(@origunits*@jcumconv))
					0,0)
				END
					
			--update SLIB ! JCCmtdTax column
			--DC #132527
			IF @itemtranstype = 'C' 
				BEGIN				
				UPDATE SLIB
				SET JCCmtdTax = @currenttax,
					JCRemCmtdTax = @remtax  --DC #130175
				WHERE Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq=@seq and SLItem = @slitem
				END
														
			END
   
   		goto item_loop	-- get next Item
   
   	item_end:	-- all items processed
   		close bcSLIB
   		deallocate bcSLIB
        select @opencursorSLIB = 0
   
   		goto header_loop	-- get next Subcontract
   
   header_end:	-- all Subcontracts processed
   	close bcSLHB
   	deallocate bcSLHB
   	select @opencursorSLHB = 0
   
	/* check HQ Batch Errors and update HQ Batch Control status */
	select @status = 3	/* valid - ok to post */
	if exists(select 1 from bHQBE where Co = @co and Mth = @mth and BatchId = @batchid)
		begin
		select @status = 2	/* validation errors */
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
   	if @opencursorSLIB = 1
   		begin
   		close bcSLIB
   		deallocate bcSLIB
   		end
   	if @opencursorSLHB = 1
   		begin
   		close bcSLHB
   		deallocate bcSLHB
   		end
   
   	if @rcode <> 0 select @errmsg = isnull(@errmsg,'') + char(13) + char(10) + '[bspSLHBVal]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspSLHBVal] TO [public]
GO
