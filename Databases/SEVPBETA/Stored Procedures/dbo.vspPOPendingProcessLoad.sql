SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE    procedure [dbo].[vspPOPendingProcessLoad]
/***********************************************************
* Craeted By:	GF 05/11/2012 TK-14878 load pending PO into a PO Entry Batch
* MODIFIED By : 
*
*
* USAGE:
* This procedure is called from the process button click
* in PO Pending Purchase Orders to load the PO and Items
* into the specified batch month and batch id.
* Source will be 'PO Entry'
*
* Checks batch info in bHQBC
* Adds entry to next available Seq# in bPOHB
*
*
* INPUT PARAMETERS
* POCo			PO Company
* PO			Pending PO to process
* Mth			Month of batch for insert
* BatchId		Batch ID to insert transaction into
*
* OUTPUT PARAMETERS
*
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/    
@POCo bCompany = NULL, @PO VARCHAR(30) = NULL
,@Mth bMonth = NULL, @BatchId bBatchID = NULL
,@ErrMsg varchar(255) output
    
AS
SET NOCOUNT ON

declare @rcode INT, @Status TINYINT
		,@Seq int, @errtext varchar(60)
        
SET @rcode = 0
   
---- validate HQ Batch
exec @rcode = bspHQBatchProcessVal @POCo, @Mth, @BatchId, 'PO Entry', 'POHB', @errtext output, @Status output
if @rcode <> 0
	BEGIN
	select @ErrMsg = @errtext, @rcode = 1
	goto vspexit
	END

---- STATUS MUST BE OPEN
if @Status <> 0
	BEGIN
	select @ErrMsg = 'Invalid Batch status -  must be (open)!', @rcode = 1
	goto vspexit
	END
               
               
      
---- get next available sequence # for this batch
SELECT @Seq = ISNULL(MAX(BatchSeq),0) + 1 
FROM dbo.bPOHB
WHERE Co = @POCo 
	AND Mth = @Mth
	AND BatchId = @BatchId
	
---- add Pending PO to POHB batch
INSERT INTO dbo.bPOHB (Co, Mth, BatchId, BatchSeq, BatchTransType, PO, VendorGroup, Vendor,
			Description, OrderDate, OrderedBy, ExpDate, Status, JCCo, Job, INCo, Loc,
			ShipLoc, Address, City, State, Country, Zip, ShipIns, HoldCode, PayTerms,
			CompGroup, Notes, OldVendorGroup, OldVendor, OldDesc, OldOrderDate, OldOrderedBy,
			OldExpDate, OldStatus, OldJCCo, OldJob,OldINCo, OldLoc, OldShipLoc, OldAddress, 
			OldCity, OldState, OldCountry, OldZip, OldShipIns, OldHoldCode, OldPayTerms,
			OldCompGroup, Attention, OldAttention, UniqueAttchID, PayAddressSeq,
			OldPayAddressSeq,POAddressSeq,OldPOAddressSeq, Address2)
Select @POCo, @Mth, @BatchId, @Seq, 'A', PO, VendorGroup, Vendor,
		Description, OrderDate, OrderedBy, ExpDate, 0, JCCo, Job,INCo, Loc,
		ShipLoc, Address, City, State, Country, Zip, ShipIns, HoldCode, PayTerms,
		CompGroup, Notes, VendorGroup, Vendor, Description, OrderDate, OrderedBy,
		ExpDate, 0, JCCo, Job, INCo, Loc, ShipLoc, Address, City, State, Country,
		Zip, ShipIns, HoldCode, PayTerms, CompGroup, Attention, Attention,
		UniqueAttchID, PayAddressSeq, PayAddressSeq, POAddressSeq, POAddressSeq,
		Address2
FROM dbo.vPOPendingPurchaseOrder
WHERE POCo = @POCo
	AND PO = @PO

IF @@ROWCOUNT <> 1
	BEGIN
	SELECT @ErrMsg = 'Unable to add entry to PO Entry Batch!', @rcode = 1
	GOTO vspexit
	END
    

---- add Pending PO Items to POIB batch
INSERT INTO dbo.bPOIB (Co, Mth, BatchId, BatchSeq, POItem, BatchTransType, ItemType, PostToCo
		,MatlGroup, Material, VendMatId, RecvYN, Description, GLCo, GLAcct, ReqDate
		,PayCategory, PayType, UM, OrigUnits, OrigUnitCost, OrigECM, OrigCost, OrigTax
		,TaxType, TaxGroup, TaxCode, TaxRate, GSTRate, SupplierGroup, Supplier
		,RequisitionNum, JCCo, Job, PhaseGroup, Phase, JCCType, INCo, Loc, EMCo, EMGroup
		,Equip, CompType, Component, CostCode, EMCType, WO, WOItem, SMCo, SMWorkOrder
		,SMScope, SMPhaseGroup, SMPhase, SMJCCostType, Notes)
		
SELECT @POCo, @Mth, @BatchId, @Seq, POItem, 'A', ItemType, PostToCo
		,MatlGroup, Material, VendMatId, RecvYN, Description, GLCo, GLAcct, ReqDate
		,PayCategory, PayType, UM, OrigUnits, OrigUnitCost, OrigECM, OrigCost, OrigTax
		,TaxType, TaxGroup, TaxCode, TaxRate, GSTRate, SupplierGroup, Supplier
		,RequisitionNum, JCCo, Job, PhaseGroup, Phase, JCCType, INCo, Loc, EMCo, EMGroup
		,Equip, CompType, Component, CostCode, EMCType, WO, WOItem, SMCo, SMWorkOrder
		,SMScope, SMPhaseGroup, SMPhase, SMJCCostType, Notes
FROM dbo.vPOPendingPurchaseOrderItem 
WHERE POCo = @POCo
	AND PO = @PO






vspexit:	
	return @rcode






GO
GRANT EXECUTE ON  [dbo].[vspPOPendingProcessLoad] TO [public]
GO
