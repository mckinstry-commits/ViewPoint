SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 8/24/2011
-- Description:	Posting for updating a GL account on a POItemLine
--				6/6/13 TFS-44858 Fixed capturing the interface level
-- =============================================
CREATE PROCEDURE [dbo].[vspPOItemLineGLAccountChangePost]
	@POCo bCompany, @BatchMonth bMonth, @BatchId bBatchID, @DatePosted bDate, @msg varchar(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @rcode int, @Journal bJrnl, @POInterfaceLevel tinyint, @APInterfaceLevel tinyint, @POSummaryDescription varchar(60), @APSummaryDescription varchar(60), @BatchNotes varchar(max)
	
	--Make sure the batch can be posted and set it as posting in progress.
	EXEC @rcode = dbo.vspHQBatchPosting @BatchCo = @POCo, @BatchMth = @BatchMonth, @BatchId = @BatchId, @Source = 'PO AcctChg', @TableName = 'POILAcctChangeBatch', @DatePosted = @DatePosted, @msg = @msg OUTPUT
	IF @rcode <> 0 RETURN @rcode
	
	--Update accounts on the PO Item, PO Item Line and AP Transaction Entry
	BEGIN TRY
		BEGIN TRAN
		
		UPDATE bPOIT
		SET GLCo = vPOILAcctChangeBatch.NewGLCo, GLAcct = vPOILAcctChangeBatch.NewGLAcct
		FROM dbo.bPOIT
			INNER JOIN dbo.vPOILAcctChangeBatch ON bPOIT.POCo = vPOILAcctChangeBatch.Co AND bPOIT.PO = vPOILAcctChangeBatch.PO AND bPOIT.POItem = vPOILAcctChangeBatch.POItem
		WHERE vPOILAcctChangeBatch.Co = @POCo AND vPOILAcctChangeBatch.Mth = @BatchMonth AND vPOILAcctChangeBatch.BatchId = @BatchId AND vPOILAcctChangeBatch.POItemLine = 1
	
		UPDATE vPOItemLine
		SET GLCo = vPOILAcctChangeBatch.NewGLCo, GLAcct = vPOILAcctChangeBatch.NewGLAcct
		FROM dbo.vPOItemLine
			INNER JOIN dbo.vPOILAcctChangeBatch ON vPOItemLine.POCo = vPOILAcctChangeBatch.Co AND vPOItemLine.PO = vPOILAcctChangeBatch.PO AND vPOItemLine.POItem = vPOILAcctChangeBatch.POItem AND vPOItemLine.POItemLine = vPOILAcctChangeBatch.POItemLine		
		WHERE vPOILAcctChangeBatch.Co = @POCo AND vPOILAcctChangeBatch.Mth = @BatchMonth AND vPOILAcctChangeBatch.BatchId = @BatchId
		
		UPDATE bAPTL
		SET GLCo = vPOILAcctChangeBatch.NewGLCo, GLAcct = vPOILAcctChangeBatch.NewGLAcct
		FROM dbo.bAPTL
			INNER JOIN dbo.vPOILAcctChangeBatch ON bAPTL.APCo = vPOILAcctChangeBatch.Co AND bAPTL.PO = vPOILAcctChangeBatch.PO AND bAPTL.POItem = vPOILAcctChangeBatch.POItem AND bAPTL.POItemLine = vPOILAcctChangeBatch.POItemLine
		WHERE vPOILAcctChangeBatch.Co = @POCo AND vPOILAcctChangeBatch.Mth = @BatchMonth AND vPOILAcctChangeBatch.BatchId = @BatchId
		
		DELETE dbo.vPOILAcctChangeBatch
		WHERE Co = @POCo AND Mth = @BatchMonth AND BatchId = @BatchId
			
		COMMIT TRAN
	END TRY
	BEGIN CATCH
		SET @msg = ERROR_MESSAGE()
		IF @@TRANCOUNT > 0 ROLLBACK TRAN
		RETURN 1
	END CATCH

	SELECT @Journal = bAPCO.ExpJrnl, @POInterfaceLevel = ISNULL(bPOCO.GLRecExpInterfacelvl, 0), @APInterfaceLevel = ISNULL(bAPCO.GLExpInterfaceLvl, 0), @POSummaryDescription = dbo.vfToString(bPOCO.GLRecExpSummaryDesc), @APSummaryDescription = dbo.vfToString(bAPCO.GLExpSummaryDesc)
	FROM dbo.bPOCO
		LEFT JOIN dbo.bAPCO ON bPOCO.POCo = bAPCO.APCo
	WHERE bPOCO.POCo = @POCo
	
	--Set all the entries for PO as ready to process so that vspGLEntryPost will post to GL
	UPDATE vGLEntryBatch
	SET ReadyToProcess = 1
	FROM dbo.vGLEntryBatch
		INNER JOIN dbo.vPORDGLEntry ON vGLEntryBatch.GLEntryID = vPORDGLEntry.GLEntryID
	WHERE vGLEntryBatch.Co = @POCo AND vGLEntryBatch.Mth = @BatchMonth AND vGLEntryBatch.BatchId = @BatchId
	
	EXEC @rcode = dbo.vspGLEntryPost @Co = @POCo, @BatchMonth = @BatchMonth, @BatchId = @BatchId, @InterfaceLevel = @POInterfaceLevel, @Journal = @Journal, @SummaryDescription = @POSummaryDescription, @DatePosted = @DatePosted, @msg = @msg OUTPUT
	IF @rcode <> 0 RETURN @rcode

	DECLARE @GLEntriesToDelete TABLE (GLEntryID bigint)

	--Update PORDGL and APTLGL to point to the new sets of GLEntries posted to GL. These are the entries that move the cost for the PO entries done from PO Receipts and AP Transaction Entry.
	BEGIN TRY
		BEGIN TRAN
		
		UPDATE vPORDGL
		SET CurrentCostGLEntryID = vPORDGLEntry.GLEntryID
			OUTPUT DELETED.CurrentCostGLEntryID
				INTO @GLEntriesToDelete
		FROM dbo.vGLEntryBatch
			INNER JOIN dbo.vPORDGLEntry ON vGLEntryBatch.GLEntryID = vPORDGLEntry.GLEntryID
			INNER JOIN dbo.vPORDGL ON vPORDGLEntry.PORDGLID = vPORDGL.PORDGLID
		WHERE vGLEntryBatch.Co = @POCo AND vGLEntryBatch.Mth = @BatchMonth AND vGLEntryBatch.BatchId = @BatchId

		UPDATE vAPTLGL
		SET CurrentPOReceiptGLEntryID = vPORDGLEntry.GLEntryID
			OUTPUT DELETED.CurrentPOReceiptGLEntryID
				INTO @GLEntriesToDelete
		FROM dbo.vGLEntryBatch
			INNER JOIN dbo.vPORDGLEntry ON vGLEntryBatch.GLEntryID = vPORDGLEntry.GLEntryID
			INNER JOIN dbo.vAPTLGL ON vPORDGLEntry.APTLGLID = vAPTLGL.APTLGLID
		WHERE vGLEntryBatch.Co = @POCo AND vGLEntryBatch.Mth = @BatchMonth AND vGLEntryBatch.BatchId = @BatchId
		
		DELETE dbo.vGLEntryBatch
		WHERE Co = @POCo AND Mth = @BatchMonth AND BatchId = @BatchId AND PostedToGL = 1
		
		DELETE dbo.vGLEntry WHERE GLEntryID IN (SELECT GLEntryID FROM @GLEntriesToDelete)
			
		COMMIT TRAN
	END TRY
	BEGIN CATCH
		SET @msg = ERROR_MESSAGE()
		IF @@TRANCOUNT > 0 ROLLBACK TRAN
		RETURN 1
	END CATCH
	
	--Set all the entries for AP as ready to process so that vspGLEntryPost will post to GL
	UPDATE vGLEntryBatch
	SET ReadyToProcess = 1
	FROM dbo.vGLEntryBatch
		INNER JOIN dbo.vAPTLGLEntry ON vGLEntryBatch.GLEntryID = vAPTLGLEntry.GLEntryID
	WHERE vGLEntryBatch.Co = @POCo AND vGLEntryBatch.Mth = @BatchMonth AND vGLEntryBatch.BatchId = @BatchId
	
	EXEC @rcode = dbo.vspGLEntryPost @Co = @POCo, @BatchMonth = @BatchMonth, @BatchId = @BatchId, @InterfaceLevel = @APInterfaceLevel, @Journal = @Journal, @SummaryDescription = @APSummaryDescription, @DatePosted = @DatePosted, @msg = @msg OUTPUT
	IF @rcode <> 0 RETURN @rcode

	--Update APTLGL to point to the new sets of GLEntries posted to GL. These are the entries that move the cost for the AP entries done from AP Transaction Entry.
	BEGIN TRY
		BEGIN TRAN
		
		UPDATE vAPTLGL
		SET CurrentAPInvoiceCostGLEntryID = vAPTLGLEntry.GLEntryID
			OUTPUT DELETED.CurrentAPInvoiceCostGLEntryID
				INTO @GLEntriesToDelete
		FROM dbo.vGLEntryBatch
			INNER JOIN dbo.vAPTLGLEntry ON vGLEntryBatch.GLEntryID = vAPTLGLEntry.GLEntryID
			INNER JOIN dbo.vAPTLGL ON vAPTLGLEntry.APTLGLID = vAPTLGL.APTLGLID
		WHERE vGLEntryBatch.Co = @POCo AND vGLEntryBatch.Mth = @BatchMonth AND vGLEntryBatch.BatchId = @BatchId
		
		DELETE dbo.vGLEntryBatch
		WHERE Co = @POCo AND Mth = @BatchMonth AND BatchId = @BatchId AND PostedToGL = 1
		
		DELETE dbo.vGLEntry WHERE GLEntryID IN (SELECT GLEntryID FROM @GLEntriesToDelete)
			
		COMMIT TRAN
	END TRY
	BEGIN CATCH
		SET @msg = ERROR_MESSAGE()
		IF @@TRANCOUNT > 0 ROLLBACK TRAN
		RETURN 1
	END CATCH

	--Set the transaction as posted and remove the batch related values
	UPDATE vSMDetailTransaction
	SET Posted = 1, HQBatchDistributionID = NULL, GLInterfaceLevel = @POInterfaceLevel
	FROM dbo.vHQBatchDistribution
		INNER JOIN dbo.vSMDetailTransaction ON vHQBatchDistribution.HQBatchDistributionID = vSMDetailTransaction.HQBatchDistributionID
	WHERE vHQBatchDistribution.Co = @POCo AND vHQBatchDistribution.Mth = @BatchMonth AND vHQBatchDistribution.BatchId = @BatchId

	SET @msg = NULL
	
	SELECT @BatchNotes = 'PO GL Revenue Interface Level set at: ' + dbo.vfToString(@POInterfaceLevel) + dbo.vfLineBreak() +
		'AP GL Revenue Interface Level set at: ' + dbo.vfToString(@APInterfaceLevel) + dbo.vfLineBreak()

	--Capture notes, set Status to posted and cleanup HQCC records
	EXEC @rcode = dbo.vspHQBatchPosted @BatchCo = @POCo, @BatchMth = @BatchMonth, @BatchId = @BatchId, @Notes = @BatchNotes, @msg = @msg OUTPUT
	IF @rcode <> 0 RETURN @rcode

	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspPOItemLineGLAccountChangePost] TO [public]
GO
