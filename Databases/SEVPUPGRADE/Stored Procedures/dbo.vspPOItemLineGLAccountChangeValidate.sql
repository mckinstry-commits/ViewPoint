SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 8/24/2011
-- Description:	Validation and distributions for updating a GL account on a POItemLine
-- =============================================
CREATE PROCEDURE [dbo].[vspPOItemLineGLAccountChangeValidate]
	@POCo bCompany, @BatchMonth bMonth, @BatchId bBatchID, @Source bSource, @msg varchar(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @rcode int, @HQBatchDistributionID bigint, @GLJournal bJrnl,
		@PO varchar(30), @POItem bItem, @POItemLine int,
		@NewGLCo bCompany, @NewGLAccount bGLAcct,
		@GLCo bCompany, @GLAccount bGLAcct,
		@GLEntryID bigint, @PORDGLID bigint, @APTLGLID bigint,
		@ErrorText varchar(255)
	
	--Verify that the batch can be validated, set the batch status to validating and delete generic distributions
	EXEC @rcode = dbo.vspHQBatchValidating @BatchCo = @POCo, @BatchMth = @BatchMonth, @BatchId = @BatchId, @Source = @Source, @TableName = 'POILAcctChangeBatch', @HQBatchDistributionID = @HQBatchDistributionID OUTPUT, @msg = @msg OUTPUT
	IF @rcode <> 0 RETURN @rcode
	
	DELETE vGLEntry
	FROM dbo.vGLEntryBatch
		INNER JOIN dbo.vGLEntry ON vGLEntryBatch.GLEntryID = vGLEntry.GLEntryID
	WHERE vGLEntryBatch.Co = @POCo AND vGLEntryBatch.Mth = @BatchMonth AND vGLEntryBatch.BatchId = @BatchId

	EXEC @rcode = dbo.vspPOItemLineGLAccountChangeRecordLock @POCo = @POCo, @BatchMonth = @BatchMonth, @BatchId = @BatchId, @msg = @msg OUTPUT
	IF @rcode <> 0
	BEGIN
		GOTO ErrorsFound
	END

	SELECT @GLJournal = ExpJrnl
	FROM dbo.APCO
	WHERE APCo = @POCo
	
	DECLARE @POItemLineToUpdate TABLE (PO varchar(30), POItem bItem, POItemLine int, NewGLCo bCompany, NewGLAccount bGLAcct, Processed bit)
	
	INSERT @POItemLineToUpdate
	SELECT PO, POItem, POItemLine, NewGLCo, NewGLAcct, 0 AS Processed
	FROM dbo.vPOILAcctChangeBatch
	WHERE Co = @POCo AND Mth = @BatchMonth AND BatchId = @BatchId
	
	DECLARE @POItemLineReceipt TABLE (PORDGLID bigint, GLTransaction int, GLCo bCompany, GLAccount bGLAcct, Amount bDollar, [Description] bTransDesc)

	DECLARE @APItemLineInvoice TABLE (APTLGLID bigint, IsPOReceiptGLEntry bit, GLTransaction int, GLCo bCompany, GLAccount bGLAcct, Amount bDollar, [Description] bTransDesc)
	
	DECLARE @GLAccountsToValidate TABLE (GLCo bCompany, GLAccount bGLAcct)

	UpdatePOItemLineGLAccountLoop:
	BEGIN
		UPDATE TOP (1) @POItemLineToUpdate
		SET Processed = 1, @PO = PO, @POItem = POItem, @POItemLine = POItemLine, @NewGLCo = NewGLCo, @NewGLAccount = NewGLAccount
		WHERE Processed = 0
		IF @@rowcount = 1
		BEGIN
			SELECT @GLCo = GLCo
			FROM dbo.vPOItemLine
			WHERE POCo = @POCo AND PO = @PO AND POItem = @POItem AND POItemLine = @POItemLine
			IF @@rowcount = 0
			BEGIN
				SET @ErrorText = 'PO Item Line doesn''t exist.'
				EXEC @rcode = dbo.bspHQBEInsert @co = @POCo, @mth = @BatchMonth, @batchid = @BatchId, @errortext = @ErrorText, @errmsg = @msg OUTPUT
				IF @rcode <> 0 GOTO ErrorsFound
				GOTO UpdatePOItemLineGLAccountLoop
			END

			SELECT TOP 1 @GLCo = CurrentGLCo
			FROM (
				SELECT CurrentGLCo
				FROM dbo.vfPOReceiptBuildTransferringEntries(@POCo, @PO, @POItem, @POItemLine, @NewGLCo, @NewGLAccount, 0)
				WHERE RequiresInterCompany = 1 AND InterCompanyAvailable = 0
				UNION
				SELECT CurrentGLCo
				FROM dbo.vfAPTransactionBuildTransferringEntries(@POCo, @PO, @POItem, @POItemLine, @NewGLCo, @NewGLAccount, 0)
				WHERE RequiresInterCompany = 1 AND InterCompanyAvailable = 0) IntercompanyNotAvailable
			IF @@rowcount > 0
			BEGIN
				SET @ErrorText = 'Missing cross company gl account(s)! Please setup in GL Intercompany accounts for Receivable GL Company ' + dbo.vfToString(@GLCo) + ' and Payable GL Company ' + dbo.vfToString(@NewGLCo)
				EXEC @rcode = dbo.bspHQBEInsert @co = @POCo, @mth = @BatchMonth, @batchid = @BatchId, @errortext = @ErrorText, @errmsg = @msg OUTPUT
				IF @rcode <> 0 GOTO ErrorsFound
				GOTO UpdatePOItemLineGLAccountLoop
			END

			DELETE @POItemLineReceipt
			
			INSERT @POItemLineReceipt
			SELECT PORDGLID, GLTransaction, GLCo, GLAccount, Amount, [Description]
			FROM dbo.vfPOReceiptBuildTransferringEntries(@POCo, @PO, @POItem, @POItemLine, @NewGLCo, @NewGLAccount, 1)

			DELETE @APItemLineInvoice

			INSERT @APItemLineInvoice
			SELECT APTLGLID, IsPOReceiptGLEntry, GLTransaction, GLCo, GLAccount, Amount, [Description]
			FROM dbo.vfAPTransactionBuildTransferringEntries(@POCo, @PO, @POItem, @POItemLine, @NewGLCo, @NewGLAccount, 1)

			-----
			--VALIDATE GL COMPANY, MONTH, JOURNAL AND ACCOUNT
			-----
			DELETE @GLAccountsToValidate
			
			INSERT @GLAccountsToValidate
			SELECT GLCo, GLAccount
			FROM @POItemLineReceipt
			UNION
			SELECT GLCo, GLAccount
			FROM @APItemLineInvoice
			
			SET @GLCo = NULL
			
			GLCoValidationLoop:
			BEGIN
				SELECT TOP 1 @GLCo = GLCo 
				FROM @GLAccountsToValidate
				WHERE @GLCo IS NULL OR GLCo > @GLCo
				ORDER BY GLCo
				IF @@rowcount = 1
				BEGIN
					--------------------
					--Subledger Month Close Validation
					--------------------
					EXEC @rcode = dbo.bspHQBatchMonthVal @glco = @GLCo, @mth = @BatchMonth, @source = @Source, @msg = @msg OUTPUT
					IF @rcode <> 0
					BEGIN
						SET @ErrorText = @msg
						EXEC @rcode = dbo.bspHQBEInsert @co = @POCo, @mth = @BatchMonth, @batchid = @BatchId, @errortext = @ErrorText, @errmsg = @msg OUTPUT
						IF @rcode <> 0 GOTO ErrorsFound
						GOTO UpdatePOItemLineGLAccountLoop
					END
					
					--------------------
					--Journal Validation
					--------------------
					IF @GLJournal IS NULL --If the use is not posting to GL then the Journal may be null
					BEGIN
						EXEC @rcode = dbo.bspGLJrnlVal @glco = @GLCo, @jrnl = @GLJournal, @msg = @msg OUTPUT
						IF @rcode <> 0
						BEGIN
							SET @ErrorText = @msg
							EXEC @rcode = dbo.bspHQBEInsert @co = @POCo, @mth = @BatchMonth, @batchid = @BatchId, @errortext = @ErrorText, @errmsg = @msg OUTPUT
							IF @rcode <> 0 GOTO ErrorsFound
							GOTO UpdatePOItemLineGLAccountLoop
						END
					END
					
					--------------------
					--Account Validation
					--------------------
					SET @GLAccount = NULL
				
					GLAccountValidationLoop:
					BEGIN
						SELECT TOP 1 @GLAccount = GLAccount
						FROM @GLAccountsToValidate
						WHERE GLCo = @GLCo AND (@GLAccount IS NULL OR GLAccount > @GLAccount)
						ORDER BY GLAccount
						IF @@rowcount = 1
						BEGIN
							EXEC @rcode = dbo.bspGLACfPostable @glco = @GLCo, @glacct = @GLAccount, @chksubtype = NULL, @msg = @msg OUTPUT
							IF @rcode <> 0
							BEGIN
								SET @ErrorText = @msg
								EXEC @rcode = dbo.bspHQBEInsert @co = @POCo, @mth = @BatchMonth, @batchid = @BatchId, @errortext = @ErrorText, @errmsg = @msg OUTPUT
								IF @rcode <> 0 GOTO ErrorsFound
								GOTO UpdatePOItemLineGLAccountLoop
							END

							GOTO GLAccountValidationLoop
						END
					END

					GOTO GLCoValidationLoop
				END
			END
			
			------------------------
			--Begin Receipt Processing
			------------------------
			POReceiptDistributionsLoop:
			BEGIN
				SELECT TOP 1 @PORDGLID = PORDGLID
				FROM @POItemLineReceipt
				IF @@rowcount = 1
				BEGIN
					EXEC @GLEntryID = dbo.vspGLCreateEntry @Source = 'PO AcctChg', @TransactionsShouldBalance = 1, @msg = @msg OUTPUT
					
					IF @GLEntryID = -1
					BEGIN
						SET @ErrorText = @msg
						EXEC @rcode = dbo.bspHQBEInsert @co = @POCo, @mth = @BatchMonth, @batchid = @BatchId, @errortext = @ErrorText, @errmsg = @msg OUTPUT
						IF @rcode <> 0 GOTO ErrorsFound
						GOTO UpdatePOItemLineGLAccountLoop
					END

					INSERT dbo.vGLEntryBatch (GLEntryID, Co, Mth, BatchId, InterfacingCo)
					VALUES (@GLEntryID, @POCo, @BatchMonth, @BatchId, @POCo)

					INSERT dbo.vGLEntryTransaction (GLEntryID, GLTransaction, GLCo, GLAccount, Amount, ActDate, [Description])
					SELECT @GLEntryID, GLTransaction, GLCo, GLAccount, Amount, dbo.vfDateOnly(), [Description]
					FROM @POItemLineReceipt
					WHERE PORDGLID = @PORDGLID

					INSERT dbo.vPORDGLEntry (GLEntryID, GLTransactionForPOItemLineAccount, PORDGLID)
					VALUES (@GLEntryID, 1, @PORDGLID)

					DELETE @POItemLineReceipt
					WHERE PORDGLID = @PORDGLID

					GOTO POReceiptDistributionsLoop
				END
			END
			
			------------------------
			--Begin Invoice Processing
			------------------------
			APInvoiceDistributionsLoop:
			BEGIN
				SELECT TOP 1 @APTLGLID = APTLGLID
				FROM @APItemLineInvoice
				IF @@rowcount = 1
				BEGIN
					IF EXISTS(SELECT 1 FROM @APItemLineInvoice WHERE APTLGLID = @APTLGLID AND IsPOReceiptGLEntry = 0)
					BEGIN
						EXEC @GLEntryID = dbo.vspGLCreateEntry @Source = 'PO AcctChg', @TransactionsShouldBalance = 1, @msg = @msg OUTPUT
					
						IF @GLEntryID = -1
						BEGIN
							SET @ErrorText = @msg
							EXEC @rcode = dbo.bspHQBEInsert @co = @POCo, @mth = @BatchMonth, @batchid = @BatchId, @errortext = @ErrorText, @errmsg = @msg OUTPUT
							IF @rcode <> 0 GOTO ErrorsFound
							GOTO UpdatePOItemLineGLAccountLoop
						END
						
						INSERT dbo.vGLEntryBatch (GLEntryID, Co, Mth, BatchId, InterfacingCo)
						VALUES (@GLEntryID, @POCo, @BatchMonth, @BatchId, @POCo)

						INSERT dbo.vGLEntryTransaction (GLEntryID, GLTransaction, GLCo, GLAccount, Amount, ActDate, [Description])
						SELECT @GLEntryID, GLTransaction, GLCo, GLAccount, Amount, dbo.vfDateOnly(), [Description]
						FROM @APItemLineInvoice
						WHERE APTLGLID = @APTLGLID AND IsPOReceiptGLEntry = 0

						INSERT dbo.vAPTLGLEntry (GLEntryID, GLTransactionForAPTransactionLineAccount, APTLGLID)
						VALUES (@GLEntryID, 1, @APTLGLID)
					END
					
					IF EXISTS(SELECT 1 FROM @APItemLineInvoice WHERE APTLGLID = @APTLGLID AND IsPOReceiptGLEntry = 1)
					BEGIN
						EXEC @GLEntryID = dbo.vspGLCreateEntry @Source = 'PO AcctChg', @TransactionsShouldBalance = 1, @msg = @msg OUTPUT
					
						IF @GLEntryID = -1
						BEGIN
							SET @ErrorText = @msg
							EXEC @rcode = dbo.bspHQBEInsert @co = @POCo, @mth = @BatchMonth, @batchid = @BatchId, @errortext = @ErrorText, @errmsg = @msg OUTPUT
							IF @rcode <> 0 GOTO ErrorsFound
							GOTO UpdatePOItemLineGLAccountLoop
						END
						
						INSERT dbo.vGLEntryBatch (GLEntryID, Co, Mth, BatchId, InterfacingCo)
						VALUES (@GLEntryID, @POCo, @BatchMonth, @BatchId, @POCo)
						
						INSERT dbo.vGLEntryTransaction (GLEntryID, GLTransaction, GLCo, GLAccount, Amount, ActDate, [Description])
						SELECT @GLEntryID, GLTransaction, GLCo, GLAccount, Amount, dbo.vfDateOnly(), [Description]
						FROM @APItemLineInvoice
						WHERE APTLGLID = @APTLGLID AND IsPOReceiptGLEntry = 1

						INSERT dbo.vPORDGLEntry (GLEntryID, GLTransactionForPOItemLineAccount, APTLGLID)
						VALUES (@GLEntryID, 1, @APTLGLID)
					END

					DELETE @APItemLineInvoice
					WHERE APTLGLID = @APTLGLID
					
					GOTO APInvoiceDistributionsLoop
				END
			END

			GOTO UpdatePOItemLineGLAccountLoop
		END
	END

	INSERT dbo.vSMDetailTransaction (IsReversing, Posted, HQBatchDistributionID, SMWorkCompletedID, SMWorkOrderScopeID, SMWorkOrderID, LineType, TransactionType, SourceCo, Mth, BatchId, GLCo, GLAccount, Amount)
	SELECT 0 IsReversing, 0 Posted, @HQBatchDistributionID, vSMWorkCompletedPurchase.SMWorkCompletedID, vSMWorkOrderScope.SMWorkOrderScopeID, vSMWorkOrder.SMWorkOrderID, 5 LineType, 'C' TransactionType, @POCo, @BatchMonth, @BatchId, vGLEntryTransaction.GLCo, vGLEntryTransaction.GLAccount, vGLEntryTransaction.Amount
	FROM dbo.vGLEntryBatch
		INNER JOIN dbo.vGLEntryTransaction ON vGLEntryBatch.GLEntryID = vGLEntryTransaction.GLEntryID
		LEFT JOIN dbo.vPORDGLEntry ON vGLEntryTransaction.GLEntryID = vPORDGLEntry.GLEntryID
		LEFT JOIN dbo.vPORDGL ON vPORDGLEntry.PORDGLID = vPORDGL.PORDGLID
		LEFT JOIN dbo.bPORD ON vPORDGL.POCo = bPORD.POCo AND vPORDGL.Mth = bPORD.Mth AND vPORDGL.POTrans = bPORD.POTrans
		
		LEFT JOIN dbo.vAPTLGLEntry ON vGLEntryTransaction.GLEntryID = vAPTLGLEntry.GLEntryID
		LEFT JOIN dbo.vAPTLGL ON vPORDGLEntry.APTLGLID = vAPTLGL.APTLGLID OR vAPTLGLEntry.APTLGLID = vAPTLGL.APTLGLID
		LEFT JOIN dbo.bAPTL ON vAPTLGL.APCo = bAPTL.APCo AND vAPTLGL.Mth = bAPTL.Mth AND vAPTLGL.APTrans = bAPTL.APTrans AND vAPTLGL.APLine = bAPTL.APLine
		
		LEFT JOIN dbo.vPOItemLine ON (bPORD.POCo = vPOItemLine.POCo AND bPORD.PO = vPOItemLine.PO AND bPORD.POItem = vPOItemLine.POItem AND bPORD.POItemLine = vPOItemLine.POItemLine) OR (bAPTL.APCo = vPOItemLine.POCo AND bAPTL.PO = vPOItemLine.PO AND bAPTL.POItem = vPOItemLine.POItem AND bAPTL.POItemLine = vPOItemLine.POItemLine)
		INNER JOIN dbo.vSMWorkOrderScope ON vPOItemLine.SMCo = vSMWorkOrderScope.SMCo AND vPOItemLine.SMWorkOrder = vSMWorkOrderScope.WorkOrder AND vPOItemLine.SMScope = vSMWorkOrderScope.Scope
		INNER JOIN dbo.vSMWorkOrder ON vPOItemLine.SMCo = vSMWorkOrder.SMCo AND vPOItemLine.SMWorkOrder = vSMWorkOrder.WorkOrder
		LEFT JOIN dbo.vSMWorkCompletedPurchase ON vPOItemLine.SMCo = vSMWorkCompletedPurchase.SMCo AND vPOItemLine.SMWorkOrder = vSMWorkCompletedPurchase.WorkOrder AND vPOItemLine.SMWorkCompleted = vSMWorkCompletedPurchase.WorkCompleted AND vSMWorkCompletedPurchase.IsSession = 0
	WHERE vGLEntryBatch.Co = @POCo AND vGLEntryBatch.Mth = @BatchMonth AND vGLEntryBatch.BatchId = @BatchId AND vPOItemLine.ItemType = 6

	--If any errors were logged we want to display the first one found
	SELECT TOP 1 @msg = ErrorText
	FROM dbo.bHQBE 
	WHERE Co = @POCo AND Mth = @BatchMonth AND BatchId = @BatchId
	ORDER BY Seq
	IF @@rowcount > 0 GOTO ErrorsFound

	INSERT dbo.bHQCC (Co, Mth, BatchId, GLCo)
	SELECT DISTINCT vGLEntryBatch.Co, vGLEntryBatch.Mth, vGLEntryBatch.BatchId, vGLEntryTransaction.GLCo
	FROM dbo.vGLEntryBatch
		INNER JOIN dbo.vGLEntryTransaction ON vGLEntryBatch.GLEntryID = vGLEntryTransaction.GLEntryID
	WHERE vGLEntryBatch.Co = @POCo AND vGLEntryBatch.Mth = @BatchMonth AND vGLEntryBatch.BatchId = @BatchId

	/* set HQ Batch status to 3 (validated) */
	UPDATE dbo.bHQBC 
	SET [Status] = 3
	WHERE Co = @POCo AND Mth = @BatchMonth AND BatchId = @BatchId
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
	WHERE Co = @POCo AND Mth = @BatchMonth AND BatchId = @BatchId
	
	RETURN 1
END

GO
GRANT EXECUTE ON  [dbo].[vspPOItemLineGLAccountChangeValidate] TO [public]
GO
