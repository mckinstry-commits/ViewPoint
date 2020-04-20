
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 7/25/11
-- Description:	Transfers money into and out of WIP
-- Modified:	JVH 5/28/13 - TFS-44858	Modified to support SM Flat Price Billing
--				JVH 6/24/13 - TFS-53341	Modified to support SM Flat Price Billing
-- =============================================

CREATE PROCEDURE [dbo].[vspSMWIPTransferCreateBatches]
	@SMCo bCompany, @WorkOrder int, @Scope int, @Source bSource, @POILAcctChangeSource bSource, @BatchMonth bMonth, @BatchId bBatchID, @UseWIP bit, @BatchKeyID bigint = NULL OUTPUT, @msg varchar(255) = NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @rcode int, @POCo bCompany, @POItemLineAccountUpdateBatchId bBatchID, @POItemLineAccountUpdateBatchKeyId bigint

	DECLARE @POItemLineGLAccountUpdateBatchesCreated TABLE (POCo bCompany, BatchMonth bMonth, BatchId bBatchID, BatchKeyId bigint)

	DECLARE @BatchErrors TABLE (ErrorText varchar(255))

	---------------------------------------------------
	--BEGIN VALIDATION THAT NO OTHER BATCHES NEED PROCESSING FIRST
	---------------------------------------------------
	
	SELECT TOP 1 @msg = 'AP transaction for SM work order scope exists in batch co: ' + dbo.vfToString(Co) + ', month: ' + dbo.vfToMonthString(Mth) + ', batch id: ' + dbo.vfToString(BatchId) + '. Please post the batch before transferring WIP.'
	FROM dbo.APLB 
	WHERE (LineType = 8 /*8 is the linetype for SM*/
		AND SMCo = @SMCo AND SMWorkOrder = @WorkOrder AND Scope = @Scope)
		OR (OldLineType = 8 /*8 is the linetype for SM*/
		AND OldSMCo = @SMCo AND OldSMWorkOrder = @WorkOrder AND OldScope = @Scope)
	IF @@rowcount > 0 GOTO ErrorsFound
	
	SELECT TOP 1 @msg = 'PR entries exist that need to be processed for payroll period co: ' + dbo.vfToString(PRPC.PRCo) + ', group: ' + dbo.vfToString(PRPC.PRGroup) + ', end date: ' + dbo.vfDateOnlyAsStringUsingStyle(PRPC.PREndDate, PRPC.PRCo, DEFAULT)
	FROM dbo.PRTH
		INNER JOIN dbo.PRPC ON PRTH.PRCo = PRPC.PRCo AND PRTH.PRGroup = PRPC.PRGroup AND PRTH.PREndDate = PRPC.PREndDate
	WHERE PRTH.SMCo = @SMCo AND PRTH.SMWorkOrder = @WorkOrder AND PRTH.SMScope = @Scope AND PRPC.InUseBy IS NOT NULL AND PRPC.[Status] = 1 --Status 1 means the pay period is closed and this is when GL is hit. This is the only case we care about them posting first.
	IF @@rowcount > 0 GOTO ErrorsFound

	--This is a little more conservative but we capture all work completed that is tied to the current scope
	--There is the possibility that the scope was changed in which case the record used to be tied to the scope, but isn't now.
	--However if the user reverts back to the previous state we may have transferred the wip for a record that shouldn't have been.
	DECLARE @WorkCompletedForScope TABLE (SMWorkCompletedID bigint)

	INSERT @WorkCompletedForScope
	SELECT DISTINCT SMWorkCompletedID
	FROM dbo.SMWorkCompletedDetail
	WHERE SMCo = @SMCo AND WorkOrder = @WorkOrder AND Scope = @Scope AND IsSession = 0

	SELECT TOP 1 @msg = 'Miscellaneous work completed exists in batch co: ' + dbo.vfToString(Co) + ', month: ' + dbo.vfToMonthString(Mth) + ', batch id: ' + dbo.vfToString(BatchId) + '. Please post the batch before transferring WIP.'
	FROM dbo.SMMiscellaneousBatch
	WHERE SMWorkCompletedID IN (SELECT SMWorkCompletedID FROM @WorkCompletedForScope)
	IF @@rowcount > 0 GOTO ErrorsFound

	SELECT TOP 1 @msg = 'Equipment work completed exists in batch co: ' + dbo.vfToString(SMEMUsageBatch.SMCo) + ', month: ' + dbo.vfToMonthString(SMEMUsageBatch.BatchMonth) + ', batch id: ' + dbo.vfToString(SMEMUsageBatch.BatchId) + '. Please post the batch before transferring WIP.'
	FROM dbo.SMEMUsageBatch
	WHERE (SMCo = @SMCo AND WorkOrder = @WorkOrder AND (Scope = @Scope OR OldScope = @Scope)) OR (SMWorkCompletedID IN (SELECT SMWorkCompletedID FROM @WorkCompletedForScope))
	IF @@rowcount > 0 GOTO ErrorsFound

	SELECT TOP 1 @msg = 'Material work completed for inventory exists in batch co: ' + dbo.vfToString(SMINBatch.SMCo) + ', month: ' + dbo.vfToMonthString(SMINBatch.Mth) + ', batch id: ' + dbo.vfToString(SMINBatch.BatchId) + '. Please post the batch before transferring WIP.'
	FROM dbo.SMINBatch
	WHERE (SMCo = @SMCo AND WorkOrder = @WorkOrder AND Scope = @Scope) OR (SMWorkCompletedID IN (SELECT SMWorkCompletedID FROM @WorkCompletedForScope))
	IF @@rowcount > 0 GOTO ErrorsFound

	SELECT TOP 1 @msg = 'AR transaction is currently being edited in batch co: ' + dbo.vfToString(vSMInvoiceARBH.Co) + ', month: ' + dbo.vfToMonthString(vSMInvoiceARBH.Mth) + ', batch id: ' + dbo.vfToString(vSMInvoiceARBH.BatchId) + '. Please post the batch before transferring WIP.'
	FROM @WorkCompletedForScope WorkCompletedForScope
		INNER JOIN dbo.vSMWorkCompleted ON WorkCompletedForScope.SMWorkCompletedID = vSMWorkCompleted.SMWorkCompletedID
		INNER JOIN dbo.vSMInvoiceDetail ON vSMWorkCompleted.SMCo = vSMInvoiceDetail.SMCo AND vSMWorkCompleted.WorkOrder = vSMInvoiceDetail.WorkOrder AND vSMWorkCompleted.WorkCompleted = vSMInvoiceDetail.WorkCompleted
		INNER JOIN dbo.vSMInvoiceARBH ON vSMInvoiceDetail.SMCo = vSMInvoiceARBH.SMCo AND vSMInvoiceDetail.Invoice = vSMInvoiceARBH.Invoice
	IF @@rowcount > 0 GOTO ErrorsFound

	---------------------------------------------------
	--END VALIDATION THAT NO OTHER BATCHES NEED PROCESSING FIRST
	---------------------------------------------------

	--For any possible work completed records that don't have an existing vSMWorkCompletedGL record one needs to be created
	INSERT dbo.vSMWorkCompletedGL (SMWorkCompletedID, SMCo, IsMiscellaneousLineType)
	SELECT vSMWorkCompletedDetail.SMWorkCompletedID, vSMWorkCompletedDetail.SMCo, CASE WHEN vSMWorkCompleted.[Type] =  3 AND vSMWorkCompleted.APTLKeyID IS NULL THEN 1 ELSE 0 END
	FROM dbo.vSMWorkCompletedDetail
		INNER JOIN dbo.vSMWorkCompleted ON vSMWorkCompletedDetail.SMWorkCompletedID = vSMWorkCompleted.SMWorkCompletedID
		LEFT JOIN dbo.vSMWorkCompletedGL ON vSMWorkCompletedDetail.SMWorkCompletedID = vSMWorkCompletedGL.SMWorkCompletedID
	WHERE vSMWorkCompletedDetail.SMCo = @SMCo AND vSMWorkCompletedDetail.WorkOrder = @WorkOrder AND vSMWorkCompletedDetail.Scope = @Scope AND vSMWorkCompletedDetail.IsSession = 0 AND vSMWorkCompletedGL.SMWorkCompletedID IS NULL

	--Load up all the work completed that has costs that needs to be moved
	INSERT dbo.vSMWIPTransferBatch (Co, Mth, BatchId, BatchSeq, WorkOrder, WorkCompleted, TransferType, NewGLCo, NewGLAcct)
	SELECT @SMCo, @BatchMonth, @BatchId, ROW_NUMBER() OVER (ORDER BY WorkCompleted) + ISNULL((SELECT MAX(BatchSeq) FROM vSMWIPTransferBatch WHERE Co = @SMCo AND Mth = @BatchMonth AND BatchId = @BatchId), 0),
		WorkOrder, WorkCompleted, 'C', GLCo, TransferToCostAccount
	FROM
	(
		SELECT DISTINCT vSMWorkCompletedDetail.WorkOrder, vSMWorkCompletedDetail.WorkCompleted, vfSMGetWorkCompletedGL.GLCo, vfSMGetWorkCompletedGL.TransferToCostAccount
		FROM dbo.vSMWorkCompletedDetail
			CROSS APPLY dbo.vfSMGetWorkCompletedGL(vSMWorkCompletedDetail.SMWorkCompletedID)
			CROSS APPLY dbo.vfSMWorkCompletedBuildTransferringEntries(vSMWorkCompletedDetail.SMWorkCompletedID, 'C', vfSMGetWorkCompletedGL.GLCo, vfSMGetWorkCompletedGL.TransferToCostAccount, 0)
		WHERE vSMWorkCompletedDetail.SMCo = @SMCo AND vSMWorkCompletedDetail.WorkOrder = @WorkOrder AND vSMWorkCompletedDetail.IsSession = 0 AND vSMWorkCompletedDetail.Scope = @Scope
	) BuildWIPTransferBatchRecords

	--Load up all the work completed that has revenue that needs to be moved
	INSERT dbo.vSMWIPTransferBatch (Co, Mth, BatchId, BatchSeq, WorkOrder, WorkCompleted, TransferType, NewGLCo, NewGLAcct)
	SELECT @SMCo, @BatchMonth, @BatchId, ROW_NUMBER() OVER (ORDER BY WorkCompleted) + ISNULL((SELECT MAX(BatchSeq) FROM vSMWIPTransferBatch WHERE Co = @SMCo AND Mth = @BatchMonth AND BatchId = @BatchId), 0),
		WorkOrder, WorkCompleted, 'R', GLCo, TransferToRevenueAccount
	FROM
	(
		SELECT DISTINCT vSMWorkCompletedDetail.WorkOrder, vSMWorkCompletedDetail.WorkCompleted, vfSMGetWorkCompletedGL.GLCo, vfSMGetWorkCompletedGL.TransferToRevenueAccount
		FROM dbo.vSMWorkCompletedDetail
			INNER JOIN dbo.vSMWorkOrder ON vSMWorkCompletedDetail.SMCo = vSMWorkOrder.SMCo AND vSMWorkCompletedDetail.WorkOrder = vSMWorkOrder.WorkOrder
			CROSS APPLY dbo.vfSMGetWorkCompletedGL(vSMWorkCompletedDetail.SMWorkCompletedID)
			CROSS APPLY dbo.vfSMWorkCompletedBuildTransferringEntries(vSMWorkCompletedDetail.SMWorkCompletedID, 'R', vfSMGetWorkCompletedGL.GLCo, vfSMGetWorkCompletedGL.TransferToRevenueAccount, 0)
		WHERE vSMWorkCompletedDetail.SMCo = @SMCo AND vSMWorkCompletedDetail.WorkOrder = @WorkOrder AND vSMWorkCompletedDetail.IsSession = 0 AND vSMWorkCompletedDetail.Scope = @Scope AND vSMWorkOrder.Job IS NOT NULL
	) BuildWIPTransferBatchRecords

	--Revenue for SM Invoices is now using vSMDetailTransaction which is eventually what we should use for job revenue and costs
	INSERT dbo.vSMWIPTransferBatch (Co, Mth, BatchId, BatchSeq, WorkOrder, WorkCompleted, TransferType, NewGLCo, NewGLAcct)
	SELECT @SMCo, @BatchMonth, @BatchId, ROW_NUMBER() OVER (ORDER BY WorkCompleted) + ISNULL((SELECT MAX(BatchSeq) FROM vSMWIPTransferBatch WHERE Co = @SMCo AND Mth = @BatchMonth AND BatchId = @BatchId), 0),
		WorkOrder, WorkCompleted, 'R', GLCo, TransferToRevenueAccount
	FROM
	(
		SELECT DISTINCT vSMWorkCompletedDetail.WorkOrder, vSMWorkCompletedDetail.WorkCompleted, vfSMGetWorkCompletedGL.GLCo, vfSMGetWorkCompletedGL.TransferToRevenueAccount
		FROM dbo.vSMWorkCompletedDetail
			INNER JOIN dbo.vSMWorkOrder ON vSMWorkCompletedDetail.SMCo = vSMWorkOrder.SMCo AND vSMWorkCompletedDetail.WorkOrder = vSMWorkOrder.WorkOrder
			INNER JOIN dbo.vSMDetailTransaction ON vSMWorkCompletedDetail.SMWorkCompletedID = vSMDetailTransaction.SMWorkCompletedID AND vSMDetailTransaction.Posted = 1 AND vSMDetailTransaction.TransactionType = 'R'
			CROSS APPLY dbo.vfSMGetWorkCompletedGL(vSMWorkCompletedDetail.SMWorkCompletedID)
		WHERE vSMWorkCompletedDetail.SMCo = @SMCo AND vSMWorkCompletedDetail.WorkOrder = @WorkOrder AND vSMWorkCompletedDetail.IsSession = 0 AND vSMWorkCompletedDetail.Scope = @Scope AND vSMWorkOrder.Job IS NULL AND
			(
				vSMDetailTransaction.GLCo <> vfSMGetWorkCompletedGL.GLCo OR
				vSMDetailTransaction.GLAccount <> vfSMGetWorkCompletedGL.TransferToRevenueAccount
			)
		GROUP BY vSMWorkCompletedDetail.WorkOrder, vSMWorkCompletedDetail.WorkCompleted, vSMDetailTransaction.GLCo, vSMDetailTransaction.GLAccount, vfSMGetWorkCompletedGL.GLCo, vfSMGetWorkCompletedGL.TransferToRevenueAccount
		HAVING SUM(vSMDetailTransaction.Amount) <> 0
	) BuildWIPTransferBatchRecords

	--Revenue for SM Invoices is now using vSMDetailTransaction which is eventually what we should use for job revenue and costs
	INSERT dbo.vSMWIPTransferBatch (Co, Mth, BatchId, BatchSeq, WorkOrder, Scope, FlatPriceRevenueSplitSeq, TransferType, NewGLCo, NewGLAcct)
	SELECT @SMCo, @BatchMonth, @BatchId, ROW_NUMBER() OVER (ORDER BY Seq) + ISNULL((SELECT MAX(BatchSeq) FROM vSMWIPTransferBatch WHERE Co = @SMCo AND Mth = @BatchMonth AND BatchId = @BatchId), 0),
		WorkOrder, Scope, Seq, 'R', GLCo, TransferToRevenueAccount
	FROM
	(
		SELECT DISTINCT vSMWorkOrderScope.WorkOrder, vSMWorkOrderScope.Scope, vSMFlatPriceRevenueSplit.Seq, RevenueSplitGL.GLCo, RevenueSplitGL.TransferToRevenueAccount
		FROM dbo.vSMWorkOrderScope
			INNER JOIN dbo.vSMEntity ON vSMWorkOrderScope.SMCo = vSMEntity.SMCo AND vSMWorkOrderScope.WorkOrder = vSMEntity.WorkOrder AND vSMWorkOrderScope.Scope = vSMEntity.WorkOrderScope
			INNER JOIN dbo.vSMFlatPriceRevenueSplit ON vSMEntity.SMCo = vSMFlatPriceRevenueSplit.SMCo AND vSMEntity.EntitySeq = vSMFlatPriceRevenueSplit.EntitySeq
			CROSS APPLY (SELECT vSMFlatPriceRevenueSplit.GLCo, CASE WHEN vSMWorkOrderScope.IsComplete = 'Y' THEN vSMFlatPriceRevenueSplit.RevenueWIPAccount ELSE vSMFlatPriceRevenueSplit.RevenueAccount END TransferToRevenueAccount) RevenueSplitGL
			INNER JOIN dbo.vSMDetailTransaction ON vSMFlatPriceRevenueSplit.SMFlatPriceRevenueSplitID = vSMDetailTransaction.SMFlatPriceRevenueSplitID AND vSMDetailTransaction.Posted = 1 AND vSMDetailTransaction.TransactionType = 'R'
		WHERE vSMWorkOrderScope.SMCo = @SMCo AND vSMWorkOrderScope.WorkOrder = @WorkOrder AND vSMWorkOrderScope.Scope = @Scope AND
			(
				vSMDetailTransaction.GLCo <> RevenueSplitGL.GLCo OR
				vSMDetailTransaction.GLAccount <> RevenueSplitGL.TransferToRevenueAccount
			)
		GROUP BY vSMWorkOrderScope.WorkOrder, vSMWorkOrderScope.Scope, vSMFlatPriceRevenueSplit.Seq, vSMDetailTransaction.GLCo, vSMDetailTransaction.GLAccount, RevenueSplitGL.GLCo, RevenueSplitGL.TransferToRevenueAccount
		HAVING SUM(vSMDetailTransaction.Amount) <> 0
	) BuildWIPTransferBatchRecords

	EXEC @rcode = dbo.vspSMWIPTransferValidate @SMCo = @SMCo, @BatchMonth = @BatchMonth, @BatchId = @BatchId, @Source = @Source, @msg = @msg OUTPUT
    IF @rcode <> 0 GOTO ErrorsFound

	--If we have errors we copy the errors into a table variable so we can return the errors to the client
	INSERT @BatchErrors
	SELECT ErrorText
	FROM dbo.HQBE
	WHERE Co = @SMCo AND Mth = @BatchMonth AND BatchId = @BatchId
	IF @@ROWCOUNT <> 0 GOTO BatchErrorsFound

	DECLARE @POItemLinesToUpdate TABLE (POCo bCompany, PO varchar(30), POItem bItem, POItemLine int, NewGLCo bCompany, NewGLAccount bGLAcct)

	--Load up all the PO Item Lines that need to have invoice or receipt costs transfered
	INSERT @POItemLinesToUpdate	
	SELECT vPOItemLine.POCo, vPOItemLine.PO, vPOItemLine.POItem, vPOItemLine.POItemLine, NewGL.GLCo, NewGL.GLAccount
	FROM dbo.vPOItemLine
		INNER JOIN dbo.vSMPOItemLine ON vPOItemLine.POCo = vSMPOItemLine.POCo AND vPOItemLine.PO = vSMPOItemLine.PO AND vPOItemLine.POItem = vSMPOItemLine.POItem AND vPOItemLine.POItemLine = vSMPOItemLine.POItemLine
		CROSS APPLY (
			SELECT vSMPOItemLine.GLCo, CASE WHEN @UseWIP = 1 THEN vSMPOItemLine.CostWIPAccount ELSE vSMPOItemLine.CostAccount END GLAccount) NewGL
	WHERE vPOItemLine.ItemType = 6 AND vPOItemLine.SMCo = @SMCo AND vPOItemLine.SMWorkOrder = @WorkOrder AND vPOItemLine.SMScope = @Scope AND
		(vPOItemLine.GLCo <> NewGL.GLCo OR vPOItemLine.GLAcct <> NewGL.GLAccount OR
			EXISTS(SELECT 1 FROM dbo.vfAPTransactionBuildTransferringEntries(vPOItemLine.POCo, vPOItemLine.PO, vPOItemLine.POItem, vPOItemLine.POItemLine, NewGL.GLCo, NewGL.GLAccount, 0)) OR
			EXISTS(SELECT 1 FROM dbo.vfPOReceiptBuildTransferringEntries(vPOItemLine.POCo, vPOItemLine.PO, vPOItemLine.POItem, vPOItemLine.POItemLine, NewGL.GLCo, NewGL.GLAccount, 0)))

	--Because we may have PO Items from different PO companys we need to loop through
	--all the companys to create a new batch for each one
	POItemTransferLoop:
	BEGIN
		SELECT TOP 1 @POCo = POCo
		FROM @POItemLinesToUpdate
		IF @@rowcount = 1
		BEGIN
			EXEC @POItemLineAccountUpdateBatchId = dbo.bspHQBCInsert @co = @POCo, @month = @BatchMonth, @source = @POILAcctChangeSource, @batchtable = 'POILAcctChangeBatch', @restrict = 'Y', @adjust = 'N', @errmsg = @msg OUTPUT
			
			IF @POItemLineAccountUpdateBatchId = 0 GOTO ErrorsFound
			
			--Retrieve the batch key id so we can attach the report
			SELECT @POItemLineAccountUpdateBatchKeyId = KeyID
			FROM dbo.HQBC
			WHERE Co = @POCo AND Mth = @BatchMonth AND BatchId = @POItemLineAccountUpdateBatchId
			
			--Keep track of all the batches created so we can post them
			INSERT @POItemLineGLAccountUpdateBatchesCreated
			VALUES (@POCo, @BatchMonth, @POItemLineAccountUpdateBatchId, @POItemLineAccountUpdateBatchKeyId)
			
			--Load up the batch with all the PO Item Lines that need to be updated
			INSERT dbo.vPOILAcctChangeBatch (Co, Mth, BatchId, PO, POItem, POItemLine, NewGLCo, NewGLAcct)
			SELECT POCo, @BatchMonth, @POItemLineAccountUpdateBatchId, PO, POItem, POItemLine, NewGLCo, NewGLAccount
			FROM @POItemLinesToUpdate
			WHERE POCo = @POCo

			DELETE @POItemLinesToUpdate
			WHERE POCo = @POCo
			
			EXEC @rcode = dbo.vspPOItemLineGLAccountChangeValidate @POCo = @POCo, @BatchMonth = @BatchMonth, @BatchId = @POItemLineAccountUpdateBatchId, @Source = @POILAcctChangeSource, @msg = @msg OUTPUT
			
			IF @rcode <> 0
			BEGIN
				--If we have errors we copy the errors into a table variable so we can return the errors to the client
				INSERT @BatchErrors
				SELECT ErrorText
				FROM dbo.HQBE
				WHERE Co = @POCo AND Mth = @BatchMonth AND BatchId = @POItemLineAccountUpdateBatchId

				GOTO BatchErrorsFound
			END
			
			GOTO POItemTransferLoop
		END
	END

	--Retrieve the batch key id so we can attach the report
	SELECT @BatchKeyID = KeyID
    FROM dbo.HQBC
    WHERE Co = @SMCo AND Mth = @BatchMonth AND BatchId = @BatchId
    
    GOTO vspExit

BatchErrorsFound:
	SELECT TOP 1 @msg = ErrorText
	FROM @BatchErrors

ErrorsFound:
	SET @rcode = 1
	
vspExit:
	--Always return the contents of the PO batches created and the batch errors
	--That way the client can always assume they will be returned and can be processed
	SELECT *
	FROM @POItemLineGLAccountUpdateBatchesCreated

	SELECT *
	FROM @BatchErrors

	RETURN @rcode
END
GO

GRANT EXECUTE ON  [dbo].[vspSMWIPTransferCreateBatches] TO [public]
GO
