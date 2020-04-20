SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE    procedure [dbo].[bspPOHBInsertExistingTrans]
/***********************************************************
* CREATED BY: SE   12/04/96
* MODIFIED By : SE 12/04/96
*               LM 5/7/98  Added check for po status of pending - can only edit a pending po from PM
*               kb 12/13/99
*               MV 07/06/01 Issue 12769 BatchUserMemoInsertExisting
*               AllenN 07/12/01 Issue 13495 (do not allow posting PO with status 2, closed)
*               kb 8/9/1 - issue #14296 to rem out stuff from 13495
*               allenn 09/27/01 - Issue 13708 Remmed out code and inserted new code for checking if PO in use by another batch.  Allow current user and same program to add PO's
*               kb 1/15/2 - Issue #
*               TV 06/04/02 insert UniqueAttchID into batch header.
*				  SR 06/28/02 - issue 17749 - bJob security should not insert PO Items with jobs that are secured
*									changing select from table bPOIT to view POIT
*				  GF 07/30/2002 - issue #17354 - Added Attention, OldAttention column update to POHB.
*			  	  MV 11/07/02 - 18037 insert PayAddressSeq, POAddressSeq in bPOHB from bPOHD
*				  MV 05/13/03 - #18763 - Specify PayType during POEntry - add PayType to bPOIB.			
*				  RT 08/21/03 - #21582 - New column 'Address2'.
*				  MV 03/03/04 - #18769 - Pay Category - add Pay Category to bPOIB.
*				  MV 01/27/05 - #26905 - insert INCo, Loc from POHD into POHB.
*				DC 03/24/08 - #127571 - Modify POEntry  for International addresses
*		DC 04/07/08 - #127019 - Co input on grid does not validate, F4 or F5
*		DC 09/29/08 - #120803 - JCCD committed cost not updated w/ tax rate change
*		DC 11/07/08 - #130833 - add the 'Supplier' field to the PO Entry form
*		TJL 04/06/09 - Issue #131500, When trans added back for Change, JC Committed not recognizing GST when reversing old value
*		DC 09/29/09 - #122288 - Store Tax Rate in PO Item
*		MH 12/09/10 - #131640 - SM Changes
*		MH 05/16/11 - TK-05175 - Add "Old" SM fields.
*		GF 7/27/2011 - TK-07144 changed to varchar(30)
*
*
* USAGE:
* This procedure is used by the PO Posting program to pull existing
* transactions from bPOHD into bPOHB for editing.
*
* Checks batch info in bHQBC, and transaction info in bPOHD.
* Adds entry to next available Seq# in bPOHB
*
* bPOBH insert trigger will update InUseBatchId in bPOHD
*
* INPUT PARAMETERS
*   Co         JC Co to pull from
*   Mth        Month of batch
*   BatchId    Batch ID to insert transaction into
*   PO         PO pull
*   IncludeItems  Y will pull all items also
* OUTPUT PARAMETERS
*
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/    
@co bCompany, @mth bMonth, @batchid bBatchID, @po VARCHAR(30), @includeitems bYN, @errmsg varchar(200) output
    
as
set nocount on

declare @rcode int, @inuseby bVPUserName, @status tinyint, @postatus tinyint,
	@dtsource bSource, @inusebatchid bBatchID, @seq int, @errtext varchar(60),
	@source bSource, @inusemth bMonth, @openpoib int, @poitem int, @valmsg varchar(200),
	@inuseflag tinyint
        
	select @rcode = 0
    
	/* validate HQ Batch */
	exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, 'PO Entry', 'POHB', @errtext output, @status output
	if @rcode <> 0
		BEGIN
		select @errmsg = @errtext, @rcode = 1
		goto bspexit
		END

	if @status <> 0
		BEGIN
		select @errmsg = 'Invalid Batch status -  must be (open)!', @rcode = 1
		goto bspexit
		END
    
        /* all PO's can be pulled into a batch as long as it's */
        /* InUseFlag is set to null and its status is not pending */
        
	select @inusebatchid = InUseBatchId, @inusemth = InUseMth, @postatus = Status 
	from POHD with (nolock) 
	where POCo=@co and PO=@po
	if @@rowcount = 0
		BEGIN
		select @errmsg = 'The PO :' + @po + ' cannot be found.' , @rcode = 1
		goto bspexit
		END            
    
    /*Issue 13708*/
    if @inusebatchid is not null or @inusemth is not null
		BEGIN
		exec @rcode = bspPOHDInUseValidation @co, @mth,  @po, @inusebatchid output, @inusemth output, @valmsg output
		if @rcode <> 0
			BEGIN
			select @errmsg = @valmsg
			goto bspexit
			END
		END                
    
	if @postatus = 3
		BEGIN
		select @errmsg = 'The PO :' + @po + ' status is pending.' , @rcode = 1
		goto bspexit
		END
          
	/* get next available sequence # for this batch */
	select @seq = isnull(max(BatchSeq),0)+1 
	from bPOHB with (nolock)
	where Co = @co and Mth = @mth and BatchId = @batchid
	/* add PO to batch */
	insert into bPOHB (Co, Mth, BatchId, BatchSeq, BatchTransType, PO, VendorGroup, Vendor,
		Description, OrderDate, OrderedBy, ExpDate, Status, JCCo, Job, INCo,Loc, ShipLoc, Address,
		City, State, Country, --DC #127571
		Zip, ShipIns, HoldCode, PayTerms, CompGroup, Notes,
		OldVendorGroup, OldVendor, OldDesc, OldOrderDate, OldOrderedBy, OldExpDate,
		OldStatus, OldJCCo, OldJob,OldINCo, OldLoc, OldShipLoc, OldAddress, 
		OldCity, OldState, OldCountry, --DC #127571
		OldZip, OldShipIns, OldHoldCode, OldPayTerms, OldCompGroup, Attention, OldAttention,
		UniqueAttchID,PayAddressSeq, OldPayAddressSeq,POAddressSeq,OldPOAddressSeq, Address2)
	Select POCo, @mth, @batchid, @seq, 'C', PO, VendorGroup, Vendor,
		Description, OrderDate, OrderedBy, ExpDate, Status, JCCo, Job,INCo, Loc, ShipLoc, Address,
		City, State, Country, --DC #127571
		Zip, ShipIns, HoldCode, PayTerms, CompGroup, Notes,VendorGroup, Vendor,
		Description, OrderDate, OrderedBy, ExpDate,Status, JCCo, Job,INCo, Loc, ShipLoc, Address,
		City, State, Country, --DC #127571
		Zip, ShipIns, HoldCode, PayTerms,CompGroup, Attention, Attention,
		UniqueAttchID,PayAddressSeq,PayAddressSeq,POAddressSeq,POAddressSeq, Address2
	from bPOHD where POCo=@co and PO=@po
    
	if @@rowcount <> 1
		BEGIN
		select @errmsg = 'Unable to add entry to PO Entry Batch!', @rcode = 1
		goto bspexit
		END
    
	/*update user memos*/
	exec bspBatchUserMemoInsertExisting @co , @mth , @batchid , @seq, 'PO Entry', 0, @errmsg output
    
	if @includeitems = 'Y'
		BEGIN
		if exists(select 1 from bPOIT with (nolock) where POCo = @co and PO = @po and (InUseMth is not null or InUseBatchId is not null)) select @inuseflag  = 1
		insert into bPOIB(Co, Mth, BatchId, BatchSeq, POItem, BatchTransType, ItemType,
			MatlGroup, Material, VendMatId, Description, UM, RecvYN, PostToCo, Loc,
			Job, PhaseGroup, Phase, JCCType, Equip, EMGroup, CostCode,EMCType,
			Component, CompType, WO,
			WOItem, GLCo, GLAcct, ReqDate, TaxGroup, TaxCode,TaxType, OrigUnits,
			OrigUnitCost, OrigECM, OrigCost, OrigTax, Notes, PayType,PayCategory,
			OldItemType, OldMatlGroup, OldMaterial, OldVendMatId, OldDesc, OldUM,
			OldRecvYN, OldPostToCo, OldLoc, OldJob,OldPhaseGroup, OldPhase,
			OldJCCType, OldEquip, OldEMGroup, OldCostCode, OldEMCType,
			OldComponent, OldCompType, OldWO,
			OldWOItem, OldGLCo, OldGLAcct, OldReqDate, OldTaxGroup, OldTaxCode,
			OldTaxType, OldOrigUnits, OldOrigUnitCost, OldOrigECM, OldOrigCost, OldOrigTax,
			RequisitionNum, OldRequisitionNum, OldPayType, OldPayCategory,
			INCo, EMCo, JCCo,  --DC #127019
			OldJCCmtdTax, JCCmtdTax, OldJCRemCmtdTax, JCRemCmtdTax, --DC #120803, TJL #131500
			Supplier, SupplierGroup,   --DC #130833				
			TaxRate, GSTRate, OldTaxRate, OldGSTRate,  --DC #122288
			SMCo, SMWorkOrder, SMScope, OldSMCo, OldSMWorkOrder, OldScope,
			SMPhaseGroup,SMPhase,SMJCCostType,OldSMPhaseGroup,OldSMPhase,OldSMJCCostType)
		select POCo, @mth, @batchid, @seq, POItem,'C', ItemType,
			MatlGroup, Material, VendMatId, Description, UM, RecvYN, PostToCo, Loc,
			Job, PhaseGroup, Phase, JCCType, Equip, EMGroup, CostCode,EMCType,
			Component, CompType, WO,
			WOItem, GLCo, GLAcct, ReqDate, TaxGroup, TaxCode, TaxType, OrigUnits,
			OrigUnitCost, OrigECM, OrigCost, OrigTax, Notes,PayType,PayCategory,
			ItemType, MatlGroup, Material, VendMatId, Description, UM, RecvYN,
			PostToCo, Loc, Job, PhaseGroup, Phase, JCCType, Equip, EMGroup,
			CostCode,EMCType, Component, CompType, WO, WOItem, GLCo, GLAcct, ReqDate, TaxGroup,
			TaxCode, TaxType, OrigUnits, OrigUnitCost, OrigECM, OrigCost, OrigTax,
			RequisitionNum, RequisitionNum, PayType, PayCategory,
			INCo, EMCo, JCCo,  --DC #127019
			JCCmtdTax, JCCmtdTax, JCRemCmtdTax, JCRemCmtdTax, --DC #120803, TJL #131500
			Supplier, SupplierGroup,  --DC #130833
			TaxRate, GSTRate, TaxRate, GSTRate,  --DC #122288
			SMCo, SMWorkOrder, SMScope, SMCo, SMWorkOrder, SMScope,
			SMPhaseGroup,SMPhase,SMJCCostType,SMPhaseGroup,SMPhase,SMJCCostType
		from POIT 
		where POCo=@co and PO=@po and InUseMth is null and InUseBatchId is null
		END
		
	/* Declare cursor on POIB to update user memos in line items - BatchUserMemoInsertExisting */
	declare POIB_cursor cursor for select Co,Mth, BatchId,BatchSeq, POItem 
	from bPOIB with (nolock)
	where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq for update
	
     /* open cursor */
     open POIB_cursor
     /* set open cursor flag to true */
     select @openpoib = 1
     /* loop through all rows in this batch */
     POIB_cursor_loop:
     fetch next from POIB_cursor into @co,@mth, @batchid, @seq, @poitem
         if @@fetch_status = -1 goto in_posting_end
         if @@fetch_status <> 0 goto POIB_cursor_loop
         if @@fetch_status = 0
			BEGIN
            exec @rcode = bspBatchUserMemoInsertExisting @co, @mth, @batchid, @seq, 'PO Entry Items',
                 @poitem, @errmsg output
                 if @rcode <> 0
					 BEGIN
            		 select @errmsg = 'Unable to update user memo to PO Entry Batch!', @rcode = 1
            		 goto bspexit
            		 END
            goto POIB_cursor_loop   --get the next seq
			END
    
	in_posting_end:
	if @openpoib = 1
		BEGIN
		close POIB_cursor
		deallocate POIB_cursor
		select @openpoib = 0
		END
    
	bspexit:
	if @openpoib = 1
		BEGIN
		close POIB_cursor
		deallocate POIB_cursor
		select @openpoib = 0
		END
	if @inuseflag  = 1
		BEGIN
		select @poitem = min(POItem) 
		from bPOIT with (nolock) 
		where POCo = @co and PO = @po and (InUseMth is not null or InUseBatchId is not null)
		select @inusemth = InUseMth, @inusebatchid = InUseBatchId 
		from bPOIT with (nolock) 
		where POCo = @co and PO = @po
		select @rcode =1, @errmsg = 'PO Item #' + convert(varchar(10),@poitem) +
			' could not be added because it is in use in batch id#'
			+ convert(varchar(10),@inusebatchid) + ' for ' +
			convert(varchar(20),@inusemth)
		END
	return @rcode





GO
GRANT EXECUTE ON  [dbo].[bspPOHBInsertExistingTrans] TO [public]
GO
