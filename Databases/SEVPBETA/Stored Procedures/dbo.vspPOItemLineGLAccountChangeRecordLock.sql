SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 9/7/11
-- Description:	Locks and unlocks all records that will be affected by updating the GL Account on a PO Item Line
-- =============================================
CREATE PROCEDURE [dbo].[vspPOItemLineGLAccountChangeRecordLock]
	@POCo bCompany, @BatchMonth bMonth, @BatchId bBatchID, @msg varchar(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	BEGIN TRAN
		DECLARE @rcode int
		
		DECLARE @LockedRecordsPreviousInUse TABLE (InUseMth bMonth NULL, InUseBatchId bBatchID NULL);
		
		--lock existing PO Headers
		WITH POThatShouldBeLockedCTE AS
		(
			SELECT DISTINCT Co, PO 
			FROM dbo.vPOILAcctChangeBatch 
			WHERE Co = @POCo AND Mth = @BatchMonth AND BatchId = @BatchId
		)
		UPDATE bPOHD
		SET InUseMth = CASE WHEN POThatShouldBeLockedCTE.PO IS NOT NULL THEN @BatchMonth END,
			InUseBatchId = CASE WHEN POThatShouldBeLockedCTE.PO IS NOT NULL THEN @BatchId END
			OUTPUT DELETED.InUseMth, DELETED.InUseBatchId
				INTO @LockedRecordsPreviousInUse
		FROM dbo.bPOHD
			LEFT JOIN POThatShouldBeLockedCTE ON bPOHD.POCo = POThatShouldBeLockedCTE.Co AND bPOHD.PO = POThatShouldBeLockedCTE.PO
		WHERE bPOHD.POCo = @POCo AND
			1 = ~dbo.vfEqualsNull(POThatShouldBeLockedCTE.PO) | (dbo.vfIsEqual(InUseMth, @BatchMonth) & dbo.vfIsEqual(InUseBatchId, @BatchId) & dbo.vfEqualsNull(POThatShouldBeLockedCTE.PO))

		IF EXISTS(SELECT 1 FROM @LockedRecordsPreviousInUse 
			WHERE (dbo.vfIsEqual(InUseMth, @BatchMonth) & dbo.vfIsEqual(InUseBatchId, @BatchId)) | (dbo.vfEqualsNull(InUseMth) & dbo.vfEqualsNull(InUseBatchId)) = 0)
		BEGIN
			SET @msg = 'Unable to lock PO Header'
			GOTO Error
		END

		DELETE @LockedRecordsPreviousInUse;

		-- lock existing PO Items
		WITH POItemsThatShouldBeLockedCTE AS
		(
			SELECT DISTINCT Co, PO, POItem
			FROM dbo.vPOILAcctChangeBatch 
			WHERE Co = @POCo AND Mth = @BatchMonth AND BatchId = @BatchId
		)
		UPDATE bPOIT
		SET InUseMth = CASE WHEN POItemsThatShouldBeLockedCTE.PO IS NOT NULL THEN @BatchMonth END,
			InUseBatchId = CASE WHEN POItemsThatShouldBeLockedCTE.PO IS NOT NULL THEN @BatchId END
			OUTPUT DELETED.InUseMth, DELETED.InUseBatchId
				INTO @LockedRecordsPreviousInUse
		FROM dbo.bPOIT
			LEFT JOIN POItemsThatShouldBeLockedCTE ON bPOIT.POCo = POItemsThatShouldBeLockedCTE.Co AND bPOIT.PO = POItemsThatShouldBeLockedCTE.PO AND bPOIT.POItem = POItemsThatShouldBeLockedCTE.POItem
		WHERE bPOIT.POCo = @POCo AND
			1 = ~dbo.vfEqualsNull(POItemsThatShouldBeLockedCTE.PO) | (dbo.vfIsEqual(InUseMth, @BatchMonth) & dbo.vfIsEqual(InUseBatchId, @BatchId) & dbo.vfEqualsNull(POItemsThatShouldBeLockedCTE.PO))

		IF EXISTS(SELECT 1 FROM @LockedRecordsPreviousInUse 
			WHERE (dbo.vfIsEqual(InUseMth, @BatchMonth) & dbo.vfIsEqual(InUseBatchId, @BatchId)) | (dbo.vfEqualsNull(InUseMth) & dbo.vfEqualsNull(InUseBatchId)) = 0)
		BEGIN
			SET @msg = 'Unable to lock PO Item'
			GOTO Error
		END

		DELETE @LockedRecordsPreviousInUse;
		
		---- lock existing PO Item Line
		WITH POItemLinesThatShouldBeLockedCTE AS
		(
			SELECT Co, PO, POItem, POItemLine
			FROM dbo.vPOILAcctChangeBatch 
			WHERE Co = @POCo AND Mth = @BatchMonth AND BatchId = @BatchId
		)
		UPDATE vPOItemLine
		SET InUseMth = CASE WHEN POItemLinesThatShouldBeLockedCTE.PO IS NOT NULL THEN @BatchMonth END,
			InUseBatchId = CASE WHEN POItemLinesThatShouldBeLockedCTE.PO IS NOT NULL THEN @BatchId END
			OUTPUT DELETED.InUseMth, DELETED.InUseBatchId
				INTO @LockedRecordsPreviousInUse
		FROM dbo.vPOItemLine
			LEFT JOIN POItemLinesThatShouldBeLockedCTE ON vPOItemLine.POCo = POItemLinesThatShouldBeLockedCTE.Co AND vPOItemLine.PO = POItemLinesThatShouldBeLockedCTE.PO AND vPOItemLine.POItem = POItemLinesThatShouldBeLockedCTE.POItem AND vPOItemLine.POItemLine = POItemLinesThatShouldBeLockedCTE.POItemLine
		WHERE vPOItemLine.POCo = @POCo AND
			1 = ~dbo.vfEqualsNull(POItemLinesThatShouldBeLockedCTE.PO) | (dbo.vfIsEqual(InUseMth, @BatchMonth) & dbo.vfIsEqual(InUseBatchId, @BatchId) & dbo.vfEqualsNull(POItemLinesThatShouldBeLockedCTE.PO))

		IF EXISTS(SELECT 1 FROM @LockedRecordsPreviousInUse 
			WHERE (dbo.vfIsEqual(InUseMth, @BatchMonth) & dbo.vfIsEqual(InUseBatchId, @BatchId)) | (dbo.vfEqualsNull(InUseMth) & dbo.vfEqualsNull(InUseBatchId)) = 0)
		BEGIN
			SET @msg = 'Unable to lock PO Item Line'
			GOTO Error
		END

		DELETE @LockedRecordsPreviousInUse;

		--lock existing bPORD Receipt Detail entries pulled into batch
		WITH POReceiptsThatShouldBeLockedCTE AS
		(
			SELECT vPORDGL.POCo, vPORDGL.Mth, vPORDGL.POTrans
			FROM dbo.vPOILAcctChangeBatch
				CROSS APPLY dbo.vfPOReceiptBuildTransferringEntries(Co, PO, POItem, POItemLine, NewGLCo, NewGLAcct, 0) TransferringEntries
				INNER JOIN vPORDGL ON TransferringEntries.PORDGLID = vPORDGL.PORDGLID
			WHERE vPOILAcctChangeBatch.Co = @POCo AND vPOILAcctChangeBatch.Mth = @BatchMonth AND vPOILAcctChangeBatch.BatchId = @BatchId
		)
		UPDATE bPORD
		SET InUseBatchId = CASE WHEN POReceiptsThatShouldBeLockedCTE.POTrans IS NOT NULL THEN @BatchId END
			OUTPUT CASE WHEN DELETED.InUseBatchId IS NOT NULL THEN @BatchMonth END, DELETED.InUseBatchId
				INTO @LockedRecordsPreviousInUse
		FROM dbo.bPORD
			LEFT JOIN POReceiptsThatShouldBeLockedCTE ON bPORD.POCo = POReceiptsThatShouldBeLockedCTE.POCo AND bPORD.Mth = POReceiptsThatShouldBeLockedCTE.Mth AND bPORD.POTrans = POReceiptsThatShouldBeLockedCTE.POTrans
		WHERE bPORD.POCo = @POCo AND
			1 = ~dbo.vfEqualsNull(POReceiptsThatShouldBeLockedCTE.POTrans) | (dbo.vfIsEqual(InUseBatchId, @BatchId) & dbo.vfEqualsNull(POReceiptsThatShouldBeLockedCTE.POTrans))

		IF EXISTS(SELECT 1 FROM @LockedRecordsPreviousInUse 
			WHERE (dbo.vfIsEqual(InUseMth, @BatchMonth) & dbo.vfIsEqual(InUseBatchId, @BatchId)) | (dbo.vfEqualsNull(InUseMth) & dbo.vfEqualsNull(InUseBatchId)) = 0)
		BEGIN
			SET @msg = 'Unable to lock PO Header'
			GOTO Error
		END

		DELETE @LockedRecordsPreviousInUse;

		--lock existing AP Transaction Header entries pulled into batch
		WITH APTHThatShouldBeLockedCTE AS
		(
			SELECT DISTINCT vAPTLGL.APCo, vAPTLGL.Mth, vAPTLGL.APTrans
			FROM dbo.vPOILAcctChangeBatch
				CROSS APPLY dbo.vfAPTransactionBuildTransferringEntries(Co, PO, POItem, POItemLine, NewGLCo, NewGLAcct, 0) TransferringEntries
				INNER JOIN vAPTLGL ON TransferringEntries.APTLGLID = vAPTLGL.APTLGLID
			WHERE vPOILAcctChangeBatch.Co = @POCo AND vPOILAcctChangeBatch.Mth = @BatchMonth AND vPOILAcctChangeBatch.BatchId = @BatchId
		)
		UPDATE bAPTH
		SET InUseMth = CASE WHEN APTHThatShouldBeLockedCTE.APTrans IS NOT NULL THEN @BatchMonth END,
			InUseBatchId = CASE WHEN APTHThatShouldBeLockedCTE.APTrans IS NOT NULL THEN @BatchId END
			OUTPUT DELETED.InUseMth, DELETED.InUseBatchId
				INTO @LockedRecordsPreviousInUse
		FROM dbo.bAPTH
			LEFT JOIN APTHThatShouldBeLockedCTE ON bAPTH.APCo = APTHThatShouldBeLockedCTE.APCo AND bAPTH.Mth = APTHThatShouldBeLockedCTE.Mth AND bAPTH.APTrans = APTHThatShouldBeLockedCTE.APTrans
		WHERE bAPTH.APCo = @POCo AND
			1 = ~dbo.vfEqualsNull(APTHThatShouldBeLockedCTE.APTrans) | (dbo.vfIsEqual(InUseMth, @BatchMonth) & dbo.vfIsEqual(InUseBatchId, @BatchId) & dbo.vfEqualsNull(APTHThatShouldBeLockedCTE.APTrans))

		IF EXISTS(SELECT 1 FROM @LockedRecordsPreviousInUse 
			WHERE (dbo.vfIsEqual(InUseMth, @BatchMonth) & dbo.vfIsEqual(InUseBatchId, @BatchId)) | (dbo.vfEqualsNull(InUseMth) & dbo.vfEqualsNull(InUseBatchId)) = 0)
		BEGIN
			SET @msg = 'Unable to lock AP Transaction Header'
			GOTO Error
		END
	COMMIT TRAN
	
	RETURN 0
	
Error:
	--If an error is found then we need to properly handle the rollback
	--The assumption is if the transaction count = 1 then we are not in a nested
	--transaction and we can safely rollback. However, if the transaction count is greater than 1
	--then we are in a nested transaction and we need to make sure that the transaction count
	--when we entered the stored procedure matches the transaction count when we leave the stored procedure.
	--Then by returning 1 the rollback can be done from whatever sql executed this stored procedure.
	IF @@trancount = 1 ROLLBACK TRAN ELSE COMMIT TRAN

	RETURN 1
END

GO
GRANT EXECUTE ON  [dbo].[vspPOItemLineGLAccountChangeRecordLock] TO [public]
GO
