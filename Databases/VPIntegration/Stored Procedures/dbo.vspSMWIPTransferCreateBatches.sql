SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 7/25/11
-- Description:	Transfers money into and out of WIP
-- Modified:
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
	WHERE SMCo = @SMCo AND WorkOrder = @WorkOrder AND Scope = @Scope

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

	SELECT TOP 1 @msg = 'AR transaction is currently being edited in batch co: ' + dbo.vfToString(bARTH.ARCo) + ', month: ' + dbo.vfToMonthString(bARTH.Mth) + ', batch id: ' + dbo.vfToString(bARTH.InUseBatchID) + '. Please post the batch before transferring WIP.'
	FROM @WorkCompletedForScope WorkCompletedForScope
		INNER JOIN dbo.vSMWorkCompleted ON WorkCompletedForScope.SMWorkCompletedID = vSMWorkCompleted.SMWorkCompletedID
		INNER JOIN dbo.vSMWorkCompletedARTL ON vSMWorkCompleted.SMWorkCompletedARTLID = vSMWorkCompletedARTL.SMWorkCompletedARTLID
		INNER JOIN dbo.bARTH ON vSMWorkCompletedARTL.ARCo = bARTH.ARCo AND vSMWorkCompletedARTL.ApplyMth = bARTH.Mth AND vSMWorkCompletedARTL.ApplyTrans = bARTH.ARTrans
	WHERE bARTH.InUseBatchID IS NOT NULL
	IF @@rowcount > 0 GOTO ErrorsFound

	---------------------------------------------------
	--END VALIDATION THAT NO OTHER BATCHES NEED PROCESSING FIRST
	---------------------------------------------------

	--Load up all the work completed that has costs that needs to be moved
	INSERT dbo.vSMWIPTransferBatch (Co, Mth, BatchId, SMWorkCompletedID, TransferType, NewGLCo, NewGLAcct)
	SELECT DISTINCT @SMCo, @BatchMonth, @BatchId, vSMWorkCompletedDetail.SMWorkCompletedID, 'C', NewGL.GLCo, NewGL.GLAccount
	FROM dbo.vSMWorkCompletedDetail
		CROSS APPLY dbo.vfSMGetWorkCompletedAccount(vSMWorkCompletedDetail.SMWorkCompletedID, 'C', @UseWIP) NewGL
		CROSS APPLY dbo.vfSMWorkCompletedBuildTransferringEntries(vSMWorkCompletedDetail.SMWorkCompletedID, 'C', NewGL.GLCo, NewGL.GLAccount, 0)
	WHERE vSMWorkCompletedDetail.SMCo = @SMCo AND vSMWorkCompletedDetail.WorkOrder = @WorkOrder AND vSMWorkCompletedDetail.IsSession = 0 AND vSMWorkCompletedDetail.Scope = @Scope

	--Load up all the work completed that has revenue that needs to be moved
	INSERT dbo.vSMWIPTransferBatch (Co, Mth, BatchId, SMWorkCompletedID, TransferType, NewGLCo, NewGLAcct)
	SELECT DISTINCT @SMCo, @BatchMonth, @BatchId, vSMWorkCompletedDetail.SMWorkCompletedID, 'R', NewGL.GLCo, NewGL.GLAccount
	FROM dbo.vSMWorkCompletedDetail
		CROSS APPLY dbo.vfSMGetWorkCompletedAccount(vSMWorkCompletedDetail.SMWorkCompletedID, 'R', @UseWIP) NewGL
		CROSS APPLY dbo.vfSMWorkCompletedBuildTransferringEntries(vSMWorkCompletedDetail.SMWorkCompletedID, 'R', NewGL.GLCo, NewGL.GLAccount, 0)
	WHERE vSMWorkCompletedDetail.SMCo = @SMCo AND vSMWorkCompletedDetail.WorkOrder = @WorkOrder AND vSMWorkCompletedDetail.IsSession = 0 AND vSMWorkCompletedDetail.Scope = @Scope

	EXEC @rcode = dbo.vspSMWIPTransferValidate @SMCo = @SMCo, @BatchMonth = @BatchMonth, @BatchId = @BatchId, @Source = @Source, @msg = @msg OUTPUT
    
	IF @rcode <> 0
	BEGIN
		--If we have errors we copy the errors into a table variable so we can return the errors to the client
		INSERT @BatchErrors
		SELECT ErrorText
		FROM dbo.HQBE
		WHERE Co = @SMCo AND Mth = @BatchMonth AND BatchId = @BatchId

		GOTO BatchErrorsFound
	END

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
