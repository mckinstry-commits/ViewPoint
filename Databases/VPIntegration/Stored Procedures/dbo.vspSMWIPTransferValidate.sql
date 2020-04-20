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

CREATE PROCEDURE [dbo].[vspSMWIPTransferValidate]
	@SMCo bCompany, @BatchMonth bMonth, @BatchId bBatchID, @Source bSource, @msg varchar(255) = NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    
    DECLARE @rcode int, @ErrorText varchar(255), @GLJournal bJrnl, @GLLvl varchar(50),
		@SMWorkCompletedID bigint, @CurrentGLCo bCompany, 
		@TransferType char(1), @NewGLCo bCompany, @NewGLAccount bGLAcct, @RequiresInterCompany bit, @InterCompanyAvailable bit,
		@GLCo bCompany, @GLAccount bGLAcct,
		@SMGLEntryID bigint, @SMGLDetailTransactionID bigint, @ActualDate bDate, @HQBatchDistributionID bigint

	--Verify that the batch can be validated, set the batch status to validating and delete generic distributions
	EXEC @rcode = dbo.vspHQBatchValidating @BatchCo = @SMCo, @BatchMth = @BatchMonth, @BatchId = @BatchId, @Source = @Source, @TableName = 'SMWIPTransferBatch', @HQBatchDistributionID = @HQBatchDistributionID OUTPUT, @msg = @msg OUTPUT
	IF @rcode <> 0 RETURN @rcode

	DELETE vSMGLEntry
	FROM dbo.vSMGLDistribution
		INNER JOIN dbo.vSMGLEntry ON vSMGLDistribution.SMGLEntryID = vSMGLEntry.SMGLEntryID
	WHERE SMCo = @SMCo AND BatchMonth = @BatchMonth AND BatchId = @BatchId
	
	SET @ActualDate = dbo.vfDateOnly()
	
	SELECT @GLJournal = GLJrnl, @GLLvl = GLLvl
	FROM dbo.SMCO
	WHERE SMCo = @SMCo

	IF @GLLvl IN ('Detail', 'Summary') AND @GLJournal IS NULL
	BEGIN
		SET @msg = 'When posting in detail or summary a journal must be supplied.'
		RETURN 1
	END

	DECLARE @SMWIPTransferToProcess TABLE (SMWorkCompletedID bigint, TransferType char(1), NewGLCo bCompany, NewGLAccount bGLAcct, Processed bit DEFAULT(0))
	
	INSERT @SMWIPTransferToProcess (SMWorkCompletedID, TransferType, NewGLCo, NewGLAccount)
	SELECT SMWorkCompletedID, TransferType, NewGLCo, NewGLAcct
	FROM dbo.vSMWIPTransferBatch
	WHERE Co = @SMCo AND Mth = @BatchMonth AND BatchId = @BatchId

	DECLARE @GLTransactions TABLE (GLTransaction int, GLCo bCompany, GLAccount bGLAcct, Amount bDollar, [Description] bTransDesc, Validated bit DEFAULT(0))

	WIPTransferValidationLoop:
	BEGIN
		UPDATE TOP (1) @SMWIPTransferToProcess
		SET Processed = 1, @SMWorkCompletedID = SMWorkCompletedID, @TransferType = TransferType, @NewGLCo = NewGLCo, @NewGLAccount = NewGLAccount
		WHERE Processed = 0
		IF @@rowcount = 1
		BEGIN
			SELECT @CurrentGLCo = CurrentGLCo, @RequiresInterCompany = RequiresInterCompany, @InterCompanyAvailable = InterCompanyAvailable
			FROM dbo.vfSMWorkCompletedBuildTransferringEntries(@SMWorkCompletedID, @TransferType, @NewGLCo, @NewGLAccount, 0)

			EXEC @rcode = dbo.bspHQBatchMonthVal @glco = @CurrentGLCo, @mth = @BatchMonth, @source = @Source, @msg = @msg OUTPUT
			
			IF @rcode <> 0
			BEGIN
				SET @ErrorText = @msg
				EXEC @rcode = dbo.bspHQBEInsert @co = @SMCo, @mth = @BatchMonth, @batchid = @BatchId, @errortext = @ErrorText, @errmsg = @msg OUTPUT
				IF @rcode <> 0 GOTO ErrorsFound
				GOTO WIPTransferValidationLoop
			END
			
			IF @GLJournal IS NULL --If the use is not posting to GL then the Journal may be null
			BEGIN
				EXEC @rcode = dbo.bspGLJrnlVal @glco = @CurrentGLCo, @jrnl = @GLJournal, @msg = @msg OUTPUT
				
				IF @rcode <> 0
				BEGIN
					SET @ErrorText = @msg
					EXEC @rcode = dbo.bspHQBEInsert @co = @SMCo, @mth = @BatchMonth, @batchid = @BatchId, @errortext = @ErrorText, @errmsg = @msg OUTPUT
					IF @rcode <> 0 GOTO ErrorsFound
					GOTO WIPTransferValidationLoop
				END
			END

			IF @RequiresInterCompany = 1
			BEGIN
				IF @InterCompanyAvailable = 0
				BEGIN
					SET @ErrorText = 'Missing cross company gl account(s)! Please setup in GL Intercompany accounts for Receivable GL Company ' + dbo.vfToString(@CurrentGLCo) + ' and Payable GL Company ' + dbo.vfToString(@NewGLCo)
					EXEC @rcode = dbo.bspHQBEInsert @co = @SMCo, @mth = @BatchMonth, @batchid = @BatchId, @errortext = @ErrorText, @errmsg = @msg OUTPUT
					IF @rcode <> 0 GOTO ErrorsFound
					GOTO WIPTransferValidationLoop
				END
				
				EXEC @rcode = dbo.bspHQBatchMonthVal @glco = @NewGLCo, @mth = @BatchMonth, @source = @Source, @msg = @msg OUTPUT
			
				IF @rcode <> 0
				BEGIN
					SET @ErrorText = @msg
					EXEC @rcode = dbo.bspHQBEInsert @co = @SMCo, @mth = @BatchMonth, @batchid = @BatchId, @errortext = @ErrorText, @errmsg = @msg OUTPUT
					IF @rcode <> 0 GOTO ErrorsFound
					GOTO WIPTransferValidationLoop
				END
			
				IF @GLJournal IS NULL --If the use is not posting to GL then the Journal may be null
				BEGIN
					EXEC @rcode = dbo.bspGLJrnlVal @glco = @NewGLCo, @jrnl = @GLJournal, @msg = @msg OUTPUT
					
					IF @rcode <> 0
					BEGIN
						SET @ErrorText = @msg
						EXEC @rcode = dbo.bspHQBEInsert @co = @SMCo, @mth = @BatchMonth, @batchid = @BatchId, @errortext = @ErrorText, @errmsg = @msg OUTPUT
						IF @rcode <> 0 GOTO ErrorsFound
						GOTO WIPTransferValidationLoop
					END
				END
			END

			DELETE @GLTransactions
			
			INSERT @GLTransactions (GLTransaction, GLCo, GLAccount, Amount, [Description])
			SELECT GLTransaction, GLCo, GLAccount, Amount, [Description]
			FROM dbo.vfSMWorkCompletedBuildTransferringEntries(@SMWorkCompletedID, @TransferType, @NewGLCo, @NewGLAccount, 1)
			
			GLAccountValidationLoop:
			BEGIN
				UPDATE TOP (1) @GLTransactions
				SET Validated = 1, @GLCo = GLCo, @GLAccount = GLAccount
				WHERE Validated = 0
				IF @@rowcount = 1
				BEGIN
					EXEC @rcode = dbo.bspGLACfPostable @glco = @GLCo, @glacct = @GLAccount, @chksubtype = NULL, @msg = @msg OUTPUT
					IF @rcode <> 0
					BEGIN
						SET @ErrorText = @msg
						EXEC @rcode = dbo.bspHQBEInsert @co = @SMCo, @mth = @BatchMonth, @batchid = @BatchId, @errortext = @ErrorText, @errmsg = @msg OUTPUT
						IF @rcode <> 0 GOTO ErrorsFound
						GOTO WIPTransferValidationLoop
					END
					
					GOTO GLAccountValidationLoop
				END
			END
			
			-------------------------------------------------------
			--BEGIN CREATING TRANSFERRING GL ENTRIES
			-------------------------------------------------------
			BEGIN TRY
				INSERT dbo.vSMGLEntry (SMWorkCompletedID, Journal)
				VALUES (@SMWorkCompletedID, @GLJournal)
				
				SET @SMGLEntryID = SCOPE_IDENTITY()

				INSERT dbo.vSMGLDetailTransaction (SMGLEntryID, IsTransactionForSMDerivedAccount, GLCo, GLAccount, Amount, ActDate, [Description])
				SELECT @SMGLEntryID, 1 AS IsTransactionForSMDerivedAccount, GLCo, GLAccount, Amount, @ActualDate, [Description]
				FROM @GLTransactions
				ORDER BY GLTransaction DESC

				SET @SMGLDetailTransactionID = SCOPE_IDENTITY()

				INSERT dbo.vSMGLDistribution (SMWorkCompletedID, SMCo, BatchMonth, BatchId, CostOrRevenue, IsAccountTransfer, SMGLEntryID, SMGLDetailTransactionID)
				VALUES (@SMWorkCompletedID, @SMCo, @BatchMonth, @BatchId, @TransferType, 1, @SMGLEntryID, @SMGLDetailTransactionID)
			END TRY
			BEGIN CATCH
				SET @ErrorText = ERROR_MESSAGE()
				EXEC @rcode = dbo.bspHQBEInsert @co = @SMCo, @mth = @BatchMonth, @batchid = @BatchId, @errortext = @ErrorText, @errmsg = @msg OUTPUT
				IF @rcode <> 0 GOTO ErrorsFound
				GOTO WIPTransferValidationLoop
			END CATCH

			GOTO WIPTransferValidationLoop
		END
	END
	
	--Capture all the reconciliation records for the WIP transfer
	INSERT dbo.vSMDetailTransaction (IsReversing, Posted, HQBatchDistributionID, HQDetailID, SMWorkCompletedID, SMWorkOrderScopeID, SMWorkOrderID, LineType, TransactionType, SourceCo, Mth, BatchId, GLCo, GLAccount, Amount)
	SELECT 0 IsReversing, 0 Posted, @HQBatchDistributionID, SMWorkCompleted.CostDetailID, vSMGLDistribution.SMWorkCompletedID, vSMWorkOrderScope.SMWorkOrderScopeID, vSMWorkOrder.SMWorkOrderID,
		SMWorkCompleted.[Type], vSMGLDistribution.CostOrRevenue, @SMCo, @BatchMonth, @BatchId,
		vSMGLDetailTransaction.GLCo, vSMGLDetailTransaction.GLAccount, vSMGLDetailTransaction.Amount
	FROM dbo.vSMGLDistribution
		INNER JOIN dbo.vSMGLDetailTransaction ON vSMGLDistribution.SMGLEntryID = vSMGLDetailTransaction.SMGLEntryID
		INNER JOIN dbo.SMWorkCompleted ON vSMGLDistribution.SMWorkCompletedID = SMWorkCompleted.SMWorkCompletedID
		INNER JOIN dbo.vSMWorkOrderScope ON SMWorkCompleted.SMCo = vSMWorkOrderScope.SMCo AND SMWorkCompleted.WorkOrder = vSMWorkOrderScope.WorkOrder AND SMWorkCompleted.Scope = vSMWorkOrderScope.Scope
		INNER JOIN dbo.vSMWorkOrder ON SMWorkCompleted.SMCo = vSMWorkOrder.SMCo AND SMWorkCompleted.WorkOrder = vSMWorkOrder.WorkOrder
	WHERE vSMGLDistribution.SMCo = @SMCo AND vSMGLDistribution.BatchMonth = @BatchMonth AND vSMGLDistribution.BatchId = @BatchId
	
	--Update the PR related fields for costs so that when ledger update is run reconciliaton correctly captures that changes
	UPDATE vSMDetailTransaction
	SET PRMth = vPRLedgerUpdateMonth.Mth
	FROM dbo.vSMDetailTransaction
		INNER JOIN dbo.vSMWorkCompleted ON vSMDetailTransaction.SMWorkCompletedID = vSMWorkCompleted.SMWorkCompletedID
		INNER JOIN dbo.vPRLedgerUpdateMonth ON vSMWorkCompleted.PRLedgerUpdateMonthID = vPRLedgerUpdateMonth.PRLedgerUpdateMonthID
		INNER JOIN dbo.vSMWorkOrder ON vSMWorkCompleted.SMCo = vSMWorkOrder.SMCo AND vSMWorkCompleted.WorkOrder = vSMWorkOrder.WorkOrder
	WHERE vSMDetailTransaction.HQBatchDistributionID = @HQBatchDistributionID AND vSMWorkCompleted.[Type] = 2 AND vSMDetailTransaction.TransactionType = 'C'
	
	--If any errors were logged we want to display the first one found
	SELECT TOP 1 @msg = ErrorText
	FROM dbo.bHQBE 
	WHERE Co = @SMCo AND Mth = @BatchMonth AND BatchId = @BatchId
	ORDER BY Seq
	IF @@rowcount > 0 GOTO ErrorsFound

	INSERT dbo.bHQCC (Co, Mth, BatchId, GLCo)
	SELECT DISTINCT vSMGLDistribution.SMCo, vSMGLDistribution.BatchMonth, vSMGLDistribution.BatchId, vSMGLDetailTransaction.GLCo
	FROM dbo.vSMGLDistribution
		INNER JOIN dbo.vSMGLDetailTransaction ON vSMGLDistribution.SMGLEntryID = vSMGLDetailTransaction.SMGLEntryID
	WHERE vSMGLDistribution.SMCo = @SMCo AND vSMGLDistribution.BatchMonth = @BatchMonth AND vSMGLDistribution.BatchId = @BatchId

	/* set HQ Batch status to 3 (validated) */
	UPDATE dbo.bHQBC 
	SET [Status] = 3
	WHERE Co = @SMCo AND Mth = @BatchMonth AND BatchId = @BatchId
	IF @@rowcount = 0
	BEGIN
		SET @msg = 'Unable to update HQ Batch Control status!'
		RETURN 1
	END

    RETURN 0
ErrorsFound:
	/* set HQ Batch status to 2 (errors found) */
	UPDATE dbo.bHQBC 
	SET [Status] = 2
	WHERE Co = @SMCo AND Mth = @BatchMonth AND BatchId = @BatchId

	RETURN 1
END
GO
GRANT EXECUTE ON  [dbo].[vspSMWIPTransferValidate] TO [public]
GO
