SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspSLIBInsertExistingTrans    Script Date: 8/28/99 9:36:37 AM ******/
   CREATE     procedure [dbo].[bspSLIBInsertExistingTrans]
   /***********************************************************
    * CREATED BY:   SE   5/13/96
    * MODIFIED By : SE 5/13/96
    *               kb 8/20/1 - issue #14335
    *		 		 MV 1/17/02 - issue 15833 BatchUserMemoInsertExisting
    *				 RT 12/03/03 - issue 23061, use isnulls when concatenating strings.
	*				DC 07/28/08 - #128435, Add SL taxes to transaction
	*				DC 08/27/09 - #134245 Manually add posted item back into batch- not bringing in JCCmtdTax/OldJCCmtdTax
	*				DC 12/31/09 - #130175 - SLIT needs to match POIT
	*				DC 06/25/10 - #135813 - expand subcontract number
    *
    * USAGE:
    * This procedure is used by the SL Entry program to pull existing
    * transactions from bSLIT into bSLIB for editing.
    *
    * Checks batch info in bHQBC, and transaction info in bSLIT.
    * Adds entry to the Item that it is in SLIT for the seq passed in
    *
    * bSLIB insert trigger will update InUseBatchId in bSLIT
    *
   
   
    * INPUT PARAMETERS
    *   Co         JC Co to pull from
    *   Mth        Month of batch
    *   BatchId    Batch ID to insert transaction into
    *   SL         PO pull
    *   Item       Item to pull
    *   Seq        Seq to put item under
    * OUTPUT PARAMETERS
    *
    * RETURN VALUE
    *   0   success
    *   1   fail
    *   3   not found  if no errors but just not available
    *****************************************************/
   
   	@co bCompany, @mth bMonth, @batchid bBatchID, @sl VARCHAR(30), --bSL,  DC #135813
   	@item bItem, @seq int, @errmsg varchar(200) output
   
   as
   set nocount on
   declare @rcode int, @inuseby bVPUserName, @status tinyint,
   	@dtsource bSource, @inusebatchid bBatchID, @inusemth bMonth, @errtext varchar(60),
   	@source bSource
   
   
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
   
   /* all Subcontract's can be pulled into a batch as long as it's InUseFlag is set to null*/
   select @inusemth=InUseMth, @inusebatchid = InUseBatchId from bSLHD where SLCo=@co and SL=@sl
   if @@rowcount = 0
   	begin
   	select @errmsg = 'The Subcontract :' + @sl + ' cannot be found.' , @rcode = 1
   	goto bspexit
   	end
   
   if @inusebatchid <> @batchid or @inusemth<>@mth
   	begin
   	select @source=Source
   	       from HQBC
   	       where Co=@co and BatchId=@inusebatchid and Mth=@inusemth
   	    --if @@rowcount<>0
   	    if @source <> ''
   	       begin
   		select @errmsg = 'SL Transaction already in use by ' +
   		      isnull(convert(varchar(2),DATEPART(month, @inusemth)) + '/' +
   		      substring(convert(varchar(4),DATEPART(year, @inusemth)),3,4),'') +
   			' batch # ' + isnull(convert(varchar(6),@inusebatchid),'') + ' - ' + 'Batch Source: ' + isnull(@source,''), @rcode = 1
   
   		goto bspexit
   	       end
   	    else
   	       begin
   		select @errmsg='SL Transaction already in use by another batch!', @rcode=1
   		goto bspexit
   	       end
   	end
   
   /*Now make sure the Item is not flaged */
   select @inusemth=InUseMth, @inusebatchid = InUseBatchId from bSLIT where SLCo=@co and SL=@sl and SLItem = @item
   if @@rowcount = 0
   	begin
   	select @errmsg = 'The Subcontract item :' + isnull(convert(varchar(5),@item),'') + ' cannot be found.' , @rcode = 3
   	goto bspexit
   	end
   
   if not @inusemth is null
   	begin
   	select @errmsg = 'This Subcontract item is already in use by Batch #' + isnull(convert(varchar(8),@inusebatchid),''), @rcode = 1
   	goto bspexit
   	end
   
   if not @inusebatchid is null
   	begin
   	select @errmsg = 'This Subcontract item is already in use by Batch #' + isnull(convert(varchar(8),@inusebatchid),''), @rcode = 1
   	goto bspexit
   	end
      
	insert into bSLIB(Co, Mth, BatchId, BatchSeq, SLItem, BatchTransType, ItemType,
		Addon, AddonPct, JCCo, Job, PhaseGroup, Phase, JCCType,
		Description, UM, GLCo, GLAcct, WCRetPct, SMRetPct, VendorGroup, Supplier,
		OrigUnits, OrigUnitCost, OrigCost, Notes,
		OldItemType, OldAddon, OldAddonPct, OldJCCo, OldJob,
		OldPhaseGroup, OldPhase, OldJCCType, OldDesc,
		OldUM, OldGLCo, OldGLAcct, OldWCRetPct, OldSMRetPct, OldSupplier,
		OldOrigUnits, OldOrigUnitCost, OldOrigCost,
		TaxType, TaxCode, TaxGroup, OrigTax, --DC #128435
		OldTaxType, OldTaxCode, OldTaxGroup, OldOrigTax,  --DC #128435
		JCCmtdTax, OldJCCmtdTax,  --DC #134245
		TaxRate, GSTRate, OldTaxRate, OldGSTRate,JCRemCmtdTax, OldJCRemCmtdTax)  --DC #130175
	select SLCo, @mth, @batchid, @seq, SLItem,'C', ItemType,
		Addon, AddonPct, JCCo, Job, PhaseGroup, Phase, JCCType,   	      
		Description, UM, GLCo, GLAcct, WCRetPct, SMRetPct, VendorGroup, Supplier,
		OrigUnits, OrigUnitCost, OrigCost, Notes,
		ItemType, Addon, AddonPct, JCCo, Job,
		PhaseGroup, Phase, JCCType, Description,
		UM, GLCo, GLAcct, WCRetPct, SMRetPct, Supplier,
		OrigUnits, OrigUnitCost, OrigCost,
		TaxType, TaxCode, TaxGroup, OrigTax,TaxType, TaxCode, TaxGroup, OrigTax, --DC #128435
		JCCmtdTax, JCCmtdTax,  --DC #134245			
		TaxRate, GSTRate, TaxRate, GSTRate, JCRemCmtdTax, JCRemCmtdTax --DC #130175
	from bSLIT 
	where SLCo=@co and SL=@sl and SLItem = @item
   if @@rowcount > 0
   begin	
   /* update user memo to SLIB batch table- BatchUserMemoInsertExisting */
        exec @rcode = bspBatchUserMemoInsertExisting @co, @mth, @batchid, @seq, 'SL Entry Items',
            @item, @errmsg output
            if @rcode <> 0
            begin
       	 select @errmsg = 'Unable to update user memo to SL Entry Item Batch!', @rcode = 1
       	 goto bspexit
       	 end
       
   end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspSLIBInsertExistingTrans] TO [public]
GO
