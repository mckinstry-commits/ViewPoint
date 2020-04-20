SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
/****** Object:  Stored Procedure dbo.bspPOIBInsertExistingTrans    Script Date: 8/28/99 9:36:29 AM ******/
CREATE       procedure [dbo].[bspPOIBInsertExistingTrans]
/***********************************************************
* CREATED BY: SE   5/13/96
* MODIFIED By : kb 12/13/99
*               kb 8/20/1 - issue #14335
*               allenn 09/27/01 - Issue 13708 Remmed out code and inserted new code for checking if PO in use by another batch.  Allow current user and same program to add PO's
*               kb 12/19/1 - issue #15568
*		   		MV 1/17/02	- issue 15833 BatchUserMemoInsertExisting
*				SR 06/25/02 - issue 17715 don't allow new item to closed PO
*				SR 06/28/02 - issue 17749 - bJob security should not insert PO Items with jobs that are secured
*									changing select from table bPOIT to view POIT
*				SR 08/08/02 Issue 17715 - added a 'Cannot insert new item' if POHB Status is not 0 (Open)
* 				MV 05/13/03 - #18763 - Specify PayType during POEntry - add PayType to bPOIB
*				MV 05/13/03 - added 'with (nolock)' to selects and 'local fast_forward' to cursors
*				MV 03/03/04 - #18769 Pay Category
*			DC 04/07/08 - #127019 - Co input on grid does not validate, F4 or F5
*			DC 11/7/08 - #130833 - add the 'Supplier' field to the PO Entry form
*			TJL 04/20/09 - Issue #131500 & 133240, Update POIB JCRemCmtdTax and oldJCRemCmtdTax fields
*			DC 09/29/09 - #122288 - Store Tax Rate in PO Item
*			JVH 4/1/11 - #131640 - Added SM related fields
*			GF 7/27/2011 - TK-07144 changed to varchar(30) 
*
* USAGE:
* This procedure is used by the PO Posting program to pull existing
* transactions from bPOIT into bPOIB for editing.
*
* Checks batch info in bHQBC, and transaction info in bPOIT.
* Adds entry to the Item that it is in POIT for the seq passed in
*
* bPOBH insert trigger will update InUseBatchId in bPOHD
*
* INPUT PARAMETERS
*   Co         JC Co to pull from
*   Mth        Month of batch
*   BatchId    Batch ID to insert transaction into
*   PO         PO pull
*   Item       Item to pull
*   Seq        Seq to put item under
* OUTPUT PARAMETERS
*
* RETURN VALUE
*   0   success
*   1   fail
*   3   not found  if no errors but just not available
*****************************************************/
@co bCompany, @mth bMonth, @batchid bBatchID, @po VARCHAR(30), @item bItem, @seq int, @errmsg varchar(200) output

as
set nocount on
declare @rcode int, @inuseby bVPUserName, @status tinyint, @source bSource,
	@dtsource bSource, @inusebatchid bBatchID, @inusemth bMonth, @errtext varchar(60), @valmsg varchar(200)
      
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

	/* all PO's can be pulled into a batch as long as it's InUseFlag is set to null*/
	select @inusemth=InUseMth, @inusebatchid = InUseBatchId
	from POHD with (nolock) where POCo=@co and PO=@po
	if @@rowcount = 0
		BEGIN
		select @errmsg = 'The PO :' + @po + ' cannot be found.' , @rcode = 1
		goto bspexit
		END
	 
	/*Issue 13708*/
	if @inusemth <> @mth or @inusebatchid<>@batchid
		BEGIN
		exec @rcode = bspPOHDInUseValidation @co, @mth,  @po, @inusebatchid output, @inusemth output, @valmsg output
		if @rcode <> 0
			BEGIN
			select @errmsg = @valmsg
			goto bspexit
			END
		END
   
	/*Now make sure the Item is not flaged */
	select @inusemth=InUseMth, @inusebatchid = InUseBatchId 
	from POIT with (nolock) 
	where POCo=@co and PO=@po and POItem = @item
	if @@rowcount = 0
		BEGIN
		--issue 17715
		if exists (select 1 from POHB with (nolock) where Co=@co and BatchId=@batchid and PO=@po and Status=2)
			BEGIN
			select @errmsg = 'Cannot add a new item to a closed PO' , @rcode = 1
			goto bspexit	
			END
		else
			BEGIN
			select @errmsg = 'The PO item :' + convert(varchar(5),@item) + ' cannot be found.' , @rcode = 3
			goto bspexit
			END
		END

	if @inusemth is not null and @inusebatchid is not null
		BEGIN
		select @errmsg = 'This PO item is already in use by Batch #' +
		convert(varchar(8),@inusebatchid) + ' for Month ' + convert(varchar(20),@inusemth), @rcode = 1
		goto bspexit
		END

	if not @inusemth is null
		BEGIN
		select @errmsg = 'This PO item is already in use by Batch #' + convert(varchar(8),@inusebatchid), @rcode = 1
		goto bspexit
		END

	if not @inusebatchid is null
		BEGIN
		select @errmsg = 'This PO item is already in use by Batch #' + convert(varchar(8),@inusebatchid), @rcode = 1
		goto bspexit
		END

	insert into bPOIB(Co, Mth, BatchId, BatchSeq, POItem, BatchTransType, ItemType,
		MatlGroup, Material, VendMatId, Description, UM, RecvYN, PostToCo, Loc,
		Job, PhaseGroup, Phase, JCCType, Equip, EMGroup, CostCode,EMCType,
		CompType, Component, WO,
		WOItem, GLCo, GLAcct, ReqDate, TaxGroup, TaxCode, TaxType, OrigUnits,
		OrigUnitCost, OrigECM, OrigCost, OrigTax, Notes, PayType,PayCategory,
		OldItemType, OldMatlGroup, OldMaterial, OldVendMatId, OldDesc, OldUM,
		OldRecvYN, OldPostToCo, OldLoc, OldJob,OldPhaseGroup, OldPhase,
		OldJCCType, OldEquip, OldEMGroup, OldCostCode, OldEMCType, OldWO,
		OldWOItem, OldGLCo, OldGLAcct, OldReqDate, OldTaxGroup, OldTaxCode,
		OldTaxType, OldOrigUnits, OldOrigUnitCost, OldOrigECM, OldOrigCost, OldOrigTax,
		OldCompType, OldComponent, OldPayType, OldPayCategory,
		INCo, EMCo, JCCo, --DC #127019
		JCCmtdTax, OldJCCmtdTax, JCRemCmtdTax, OldJCRemCmtdTax, Supplier, SupplierGroup,  --DC #130833
		TaxRate, GSTRate, OldTaxRate, OldGSTRate, --DC #122288
		SMCo, SMWorkOrder, SMScope, OldSMCo, OldSMWorkOrder, OldScope,
		SMPhaseGroup,SMPhase,SMJCCostType,OldSMPhaseGroup,OldSMPhase,OldSMJCCostType)
	select POCo, @mth, @batchid, @seq, POItem,'C', ItemType,
		MatlGroup, Material, VendMatId, Description, UM, RecvYN, PostToCo, Loc,
		Job, PhaseGroup, Phase, JCCType, Equip, EMGroup, CostCode,EMCType,
		CompType, Component, WO,
		WOItem, GLCo, GLAcct, ReqDate, TaxGroup, TaxCode, TaxType, OrigUnits,
		OrigUnitCost, OrigECM, OrigCost, OrigTax, Notes, PayType,PayCategory,
		ItemType, MatlGroup, Material, VendMatId, Description, UM, RecvYN,
		PostToCo, Loc, Job, PhaseGroup, Phase, JCCType, Equip, EMGroup,
		CostCode,EMCType, WO, WOItem, GLCo, GLAcct, ReqDate, TaxGroup,
		TaxCode, TaxType, OrigUnits, OrigUnitCost, OrigECM, OrigCost, OrigTax,
		CompType, Component, PayType, PayCategory,
		INCo, EMCo, JCCo,  --DC #127019
		JCCmtdTax, JCCmtdTax, JCRemCmtdTax, JCRemCmtdTax, Supplier, SupplierGroup,  --DC #130833
		TaxRate, GSTRate, TaxRate, GSTRate,  --DC #122288
		SMCo, SMWorkOrder, SMScope, SMCo, SMWorkOrder, SMScope,
		SMPhaseGroup,SMPhase,SMJCCostType,SMPhaseGroup,SMPhase,SMJCCostType
	from bPOIT 
	where POCo=@co and PO=@po and POItem = @item	
	if @@rowcount > 0
		BEGIN
		exec @rcode = bspBatchUserMemoInsertExisting @co, @mth, @batchid, @seq, 'PO Entry Items', @item, @errmsg output
		if @rcode <> 0
			BEGIN
			select @errmsg = 'Unable to update user memo to PO Entry Batch!', @rcode = 1
			goto bspexit
			END
		END

bspexit:
	return @rcode





GO
GRANT EXECUTE ON  [dbo].[bspPOIBInsertExistingTrans] TO [public]
GO
