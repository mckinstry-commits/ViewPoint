SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 3/21/11
-- Description:	This stored procedure should be called whenever all the neccessary information
--				has been supplied for a PO batch record to be posted. This means the vendor has to have
--				been supplied.
-- Mofication:  EricV 07/09/13 TFS-55412  Delete the POIB and POHB records from the SM PO batch where nothing has been changed before validating and posting the batch.
-- =============================================
CREATE PROCEDURE [dbo].[vspSMPOEntyValidate] 
	@POCo bCompany, @SMCo bCompany, @WorkOrder int, @BatchMth bMonth, @BatchId bBatchID, @Source char(10), @ReadyToPost bit = 0 OUTPUT, @AttachBatchReportsYN bYN = NULL OUTPUT, @BatchKeyID bigint = NULL OUTPUT, @msg varchar(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @rcode int, @todaysDate smalldatetime

	-- Delete any records from the Batch where nothing has changed.
	DELETE POIB
	FROM POIB WHERE  Co = @POCo AND Mth = @BatchMth AND BatchId = @BatchId
	AND BatchTransType = 'C'
	AND dbo.vfIsEqual(OldComponent,Component)&dbo.vfIsEqual(OldCompType, CompType)&dbo.vfIsEqual(OldCostCode,CostCode)&dbo.vfIsEqual(OldDesc,Description)
	&dbo.vfIsEqual(OldEMCType,EMCType)&dbo.vfIsEqual(OldEMGroup,EMGroup)&dbo.vfIsEqual(OldEquip,Equip)&dbo.vfIsEqual(OldGLAcct,GLAcct)&dbo.vfIsEqual(OldGLCo,GLCo)
	&dbo.vfIsEqual(OldGSTRate,GSTRate)&dbo.vfIsEqual(OldItemType,ItemType)&dbo.vfIsEqual(OldJCCmtdTax,JCCmtdTax)&dbo.vfIsEqual(OldJCCType,JCCType)
	&dbo.vfIsEqual(OldJCRemCmtdTax,JCRemCmtdTax)&dbo.vfIsEqual(OldJob,Job)&dbo.vfIsEqual(OldLoc,Loc)&dbo.vfIsEqual(OldMaterial,Material)
	&dbo.vfIsEqual(OldMatlGroup,MatlGroup)&dbo.vfIsEqual(OldOrigCost,OrigCost)&dbo.vfIsEqual(OldOrigECM,OrigECM)&dbo.vfIsEqual(OldOrigTax,OrigTax)
	&dbo.vfIsEqual(OldOrigUnitCost,OrigUnitCost)&dbo.vfIsEqual(OldOrigTax,OrigTax)&dbo.vfIsEqual(OldOrigUnitCost,OrigUnitCost)&dbo.vfIsEqual(OldOrigUnits,OrigUnits)
	&dbo.vfIsEqual(OldPayCategory,PayCategory)&dbo.vfIsEqual(OldPayType,PayType)&dbo.vfIsEqual(OldPhase,Phase)&dbo.vfIsEqual(OldPhaseGroup,PhaseGroup)
	&dbo.vfIsEqual(OldPostToCo,PostToCo)&dbo.vfIsEqual(OldRecvYN,RecvYN)&dbo.vfIsEqual(OldReqDate,ReqDate)&dbo.vfIsEqual(OldRequisitionNum,RequisitionNum)
	&dbo.vfIsEqual(OldScope,SMScope)&dbo.vfIsEqual(OldSMCo,SMCo)&dbo.vfIsEqual(OldSMJCCostType,SMJCCostType)&dbo.vfIsEqual(OldSMPhase,SMPhase)
	&dbo.vfIsEqual(OldSMPhaseGroup,SMPhaseGroup)&dbo.vfIsEqual(OldSMWorkOrder,SMWorkOrder)&dbo.vfIsEqual(OldTaxCode,TaxCode)
	&dbo.vfIsEqual(OldTaxGroup,TaxGroup)&dbo.vfIsEqual(OldTaxRate,TaxRate)&dbo.vfIsEqual(OldUM,UM)&dbo.vfIsEqual(OldVendMatId,VendMatId)
	&dbo.vfIsEqual(OldWO,WO)&dbo.vfIsEqual(OldWOItem,WOItem)=1

	DELETE POHB WHERE Co = @POCo AND Mth = @BatchMth AND BatchId = @BatchId
	AND BatchTransType = 'C'
	AND dbo.vfIsEqual(OldAddress,Address)&dbo.vfIsEqual(OldAddress2,Address2)&dbo.vfIsEqual(OldAttention,Attention)&dbo.vfIsEqual(OldCity,City)
	&dbo.vfIsEqual(OldCompGroup,CompGroup)&dbo.vfIsEqual(OldCountry,Country)&dbo.vfIsEqual(OldDesc,Description)&dbo.vfIsEqual(OldExpDate,ExpDate)
	&dbo.vfIsEqual(OldHoldCode,HoldCode)&dbo.vfIsEqual(OldINCo,INCo)&dbo.vfIsEqual(OldJCCo,JCCo)&dbo.vfIsEqual(OldJob,Job)&dbo.vfIsEqual(OldLoc,Loc)
	&dbo.vfIsEqual(OldOrderDate,OrderDate)&dbo.vfIsEqual(OldOrderedBy,OrderedBy)&dbo.vfIsEqual(OldPayAddressSeq,PayAddressSeq)&
	dbo.vfIsEqual(OldPayTerms,PayTerms)&dbo.vfIsEqual(OldPOAddressSeq,POAddressSeq)&dbo.vfIsEqual(OldShipIns,ShipIns)&dbo.vfIsEqual(OldShipLoc,ShipLoc)
	&dbo.vfIsEqual(OldState,State)&dbo.vfIsEqual(OldStatus,Status)&dbo.vfIsEqual(OldVendor,Vendor)&dbo.vfIsEqual(OldVendorGroup,VendorGroup)
	&dbo.vfIsEqual(OldZip,Zip)=1
	AND NOT EXISTS(Select 1 FROM POIB Where POHB.Co = POIB.Co AND POHB.Mth = POIB.Mth AND POHB.BatchId = POIB.BatchId AND POHB.BatchSeq = POIB.BatchSeq)

	--Verify that the batch actually exists
	--Then verify that we don't have any batch records that are missing the vendor.
	IF EXISTS(SELECT 1 FROM dbo.HQBC WHERE Co = @POCo AND Mth = @BatchMth AND BatchId = @BatchId) 
		AND NOT EXISTS(SELECT 1 FROM dbo.POHB WHERE Co = @POCo AND Mth = @BatchMth AND BatchId = @BatchId AND Vendor IS NULL)
		AND NOT EXISTS(SELECT 1 FROM dbo.POIB WHERE Co = @POCo AND Mth = @BatchMth AND BatchId = @BatchId AND CASE WHEN SMCo = @SMCo AND SMWorkOrder = @WorkOrder THEN 1 ELSE 0 END = 0)
	BEGIN
		EXEC @rcode = dbo.bspPOHBVal @co = @POCo, @mth = @BatchMth, @batchid = @BatchId, @source = @Source, @errmsg = @msg OUTPUT
	    
	    --There was an error in the validation proc. Return now.
	    IF @rcode = 1 RETURN 1
	    
	    --A record failed validation. Return now.
	    IF EXISTS(SELECT 1 FROM dbo.HQBE WHERE Co = @POCo AND Mth = @BatchMth AND BatchId = @BatchId) RETURN 1
	    
	    SET @ReadyToPost = 1
	    
	    --Get whether we should attach the report
	    SELECT @AttachBatchReportsYN = AttachBatchReportsYN
	    FROM dbo.POCO
	    WHERE POCo = @POCo
	    
	    --Get the batch keyid so that we can attach the report
	    SELECT @BatchKeyID = KeyID
	    FROM dbo.HQBC
		WHERE Co = @POCo AND Mth = @BatchMth AND BatchId = @BatchId
    END
    ELSE
    BEGIN
		--Unlock the batch so others can jump in from the PO batch form
		EXEC dbo.bspHQBCExitCheck @co=@POCo, @mth=@BatchMth, @batchid = @BatchId, @source = @Source, @tablename = 'POHB', @errmsg = NULL
    END
    
    RETURN 0
END


GO
GRANT EXECUTE ON  [dbo].[vspSMPOEntyValidate] TO [public]
GO
