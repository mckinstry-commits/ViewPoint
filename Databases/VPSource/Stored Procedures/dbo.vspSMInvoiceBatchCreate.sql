SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[vspSMInvoiceBatchCreate] 
	/******************************************************
	* CREATED BY: 
	* MODIFIED By: Nels H. - 07/03/12 - added truncation to CurrentDescription to prevent error msg
	*              Chris G (7/12/12 D-05009) - Added validation of BatchMth
	*              ECV 10/02/12 TK-18080 - Removed check of ApplyMth for open month. Doesn't need to be open. 
	*							Modified to allow invoices in closed months to be adjusted.
	* MODIFIED BY: Matthew B - 11/27/2012 TK-19569
	* Usage:
	*	
	*
	* Input params:
	*	SMSessionID		SM Session ID
	*	BatchMth		Batch month
	*   BatchId			Batch Id
	*
	* Output params:
	*	@errmsg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*					5/31/12		JB	Modified how the receivable type was being set so that the line is always the same as the header.
	*******************************************************/
	@SMSessionID int, @ARCo bCompany, @BatchMth bMonth, @BatchId bBatchID = NULL OUTPUT, @errmsg varchar(255) OUTPUT
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @SMInvoiceID int, @ARTransType char(1), @ApplyMth bMonth, @ApplyTrans bTrans, 
			@NextBatchSeq int, @NextARLine smallint, @RecType tinyint

	SELECT @NextBatchSeq = 1

	DECLARE @InvoicesToProcess TABLE (SMInvoiceID bigint NOT NULL)
	
	DECLARE @ARBL TABLE (SMWorkCompletedID bigint, IsReversing bit, BatchSeq int, ARLine smallint NULL, ApplyLine smallint NULL, TransType char(1),
		RecType tinyint, [Description] bDesc NULL,
		GLCo bCompany, GLAcct bGLAcct, TaxGroup bGroup NULL, TaxCode bTaxCode NULL,
		Amount bDollar, TaxBasis bDollar, TaxAmount bDollar, DiscOffered bDollar, TaxDisc bDollar)

	INSERT @InvoicesToProcess
	SELECT vSMInvoice.SMInvoiceID
	FROM dbo.vSMInvoiceSession
		INNER JOIN dbo.vSMInvoice ON vSMInvoiceSession.SMInvoiceID = vSMInvoice.SMInvoiceID
	WHERE vSMInvoiceSession.SMSessionID = @SMSessionID AND vSMInvoice.ARCo = @ARCo AND vSMInvoice.BatchMonth = @BatchMth
	IF @@rowcount = 0
	BEGIN
		SET @errmsg = 'No invoices to process'
		RETURN 1
	END

	--If a batch was created and the client was terminated then the previous batch should be cleaned up.
	DECLARE @BatchesToCleanup TABLE (Co bCompany NOT NULL, Mth bMonth NOT NULL, BatchId bBatchID NOT NULL)
	
	INSERT @BatchesToCleanup
	SELECT DISTINCT vSMWorkCompletedARBL.Co, vSMWorkCompletedARBL.Mth, vSMWorkCompletedARBL.BatchId
	FROM @InvoicesToProcess InvoicesToProcess
		INNER JOIN dbo.SMInvoiceDetailChanges ON InvoicesToProcess.SMInvoiceID = SMInvoiceDetailChanges.SMInvoiceID
		INNER JOIN dbo.vSMWorkCompletedARBL ON SMInvoiceDetailChanges.SMWorkCompletedID = vSMWorkCompletedARBL.SMWorkCompletedID
	WHERE SMInvoiceDetailChanges.TransType IN ('A', 'C', 'D')
	
	SELECT @errmsg = 'Previous SM Invoice batch co: ' + dbo.vfToString(BatchesToCleanup.Co) + ', month: ' + dbo.vfToMonthString(BatchesToCleanup.Mth) + ', batch id: ' + dbo.vfToString(BatchesToCleanup.BatchId) + ' must be posted through SM Batches.'
	FROM @BatchesToCleanup BatchesToCleanup
		INNER JOIN dbo.bHQBC ON BatchesToCleanup.Co = bHQBC.Co AND BatchesToCleanup.Mth = bHQBC.Mth AND BatchesToCleanup.BatchId = bHQBC.BatchId
	WHERE [Status] = 4 --Posting in progress
	IF @@rowcount <> 0 RETURN 1
	
	BEGIN TRY
		--Use a transaction so that if anything fails we don't have a half created batch.
		BEGIN TRAN

		--Delete ARBL and ARBH records should cascade delete the SM related records.
		DELETE bARBL
		FROM dbo.bARBL
			INNER JOIN @BatchesToCleanup BatchesToCleanup ON bARBL.Co = BatchesToCleanup.Co AND bARBL.Mth = BatchesToCleanup.Mth AND bARBL.BatchId = BatchesToCleanup.BatchId
		
		DELETE bARBH
		FROM dbo.bARBH
			INNER JOIN @BatchesToCleanup BatchesToCleanup ON bARBH.Co = BatchesToCleanup.Co AND bARBH.Mth = BatchesToCleanup.Mth AND bARBH.BatchId = BatchesToCleanup.BatchId

		--Cancel batches if they were never posted. If they were posted then keep them as having been posted.
		UPDATE bHQBC
		SET [Status] = CASE WHEN [Status] = 5 THEN 5 ELSE 6 END, InUseBy = NULL
		FROM dbo.bHQBC
			INNER JOIN @BatchesToCleanup BatchesToCleanup ON bHQBC.Co = BatchesToCleanup.Co AND bHQBC.Mth = BatchesToCleanup.Mth AND bHQBC.BatchId = BatchesToCleanup.BatchId
		
		EXEC @BatchId = dbo.bspHQBCInsert @co = @ARCo, @month = @BatchMth, @source = 'SM Invoice', @batchtable = 'ARBH', @restrict = 'Y', @adjust = 'N', @prgroup = NULL, @prenddate = NULL, @errmsg = @errmsg OUTPUT
		IF @BatchId = 0
		BEGIN
			ROLLBACK TRAN
			RETURN 1
		END

		WHILE EXISTS(SELECT 1 FROM @InvoicesToProcess)
		BEGIN
			SELECT TOP 1 @SMInvoiceID = SMInvoiceID
			FROM @InvoicesToProcess

			SELECT @errmsg = 
				CASE					
					WHEN ARCM.[Status] = 'I' THEN 'Bill To Customer # ' + dbo.vfToString(ARCM.Customer) + ' is inactive.'
					WHEN ARCM.[Status] = 'H' THEN 'Bill To Customer # ' + dbo.vfToString(ARCM.Customer) + ' is on hold.'
					WHEN SMInvoice.DueDate IS NULL THEN 'Due Date is required.'
				END,
				@ApplyMth = ARPostedMth, @ApplyTrans = ARTrans,
				@ARTransType = CASE WHEN ARPostedMth IS NOT NULL AND ARTrans IS NOT NULL THEN 'A'/*Adjustment*/ ELSE 'I'/*Invoice*/ END,
				@RecType = ISNULL(ARCM.RecType, ARCO.RecType)
			FROM dbo.SMInvoice
				INNER JOIN dbo.ARCO ON SMInvoice.ARCo = ARCO.ARCo
				INNER JOIN dbo.ARCM ON SMInvoice.CustGroup = ARCM.CustGroup AND SMInvoice.BillToARCustomer = ARCM.Customer
			WHERE SMInvoiceID = @SMInvoiceID
			
			IF @errmsg IS NOT NULL
			BEGIN
				ROLLBACK TRAN
				RETURN 1
			END
			
			-- Verify the GL Month is open for the WorkCompleted GLCo using the correct BatchMth
			IF EXISTS( SELECT 1 FROM dbo.vfGLClosedMonths('SM Invoice', @BatchMth) 
					   WHERE GLCo IN (SELECT GLCo FROM dbo.SMWorkCompleted WHERE SMInvoiceID = @SMInvoiceID) AND IsMonthOpen = 0)
			BEGIN
				SET @errmsg = 'GL Month is closed for the Work Completed GL Company.'
				ROLLBACK TRAN
				RETURN 1
			END

			DELETE @ARBL
			
			IF @ARTransType = 'I' --New Invoice
			BEGIN
				INSERT @ARBL
				SELECT SMWorkCompletedID, 0, @NextBatchSeq, NULL, NULL, TransType,
					@RecType, convert(varchar(30), CurrentDescription),
					CurrentGLCo, CurrentGLAcct, CurrentTaxGroup, CurrentTaxCode,
					CurrentAmount, CurrentTaxBasis, CurrentTaxAmount, 
					CurrentDiscOffered, CurrentTaxDisc
				FROM dbo.SMInvoiceDetailChanges
				WHERE SMInvoiceID = @SMInvoiceID AND TransType = 'A'
				
				IF @@rowcount <> 0
				BEGIN
					INSERT dbo.bARBH (Co, Mth, BatchId, BatchSeq, TransType, [Source], ARTransType, CustGroup, Customer, RecType, Invoice, TransDate, DueDate, DiscDate, PayTerms)
					SELECT ARCo, @BatchMth, @BatchId, @NextBatchSeq, 'A', 'SM Invoice', @ARTransType, CustGroup, BillToARCustomer, @RecType, dbo.bfJustifyStringToDatatype(dbo.vfToString(Invoice), 'bARInvoice'), InvoiceDate, DueDate, DiscDate, PayTerms
					FROM dbo.vSMInvoice
					WHERE SMInvoiceID = @SMInvoiceID

					INSERT dbo.vSMInvoiceARBH (SMInvoiceID, Co, Mth, BatchId, BatchSeq)
					SELECT @SMInvoiceID, @ARCo, @BatchMth, @BatchId, @NextBatchSeq
					
					SET @NextBatchSeq = @NextBatchSeq + 1
				END
			END
			ELSE --Adjustment
			BEGIN
				INSERT @ARBL
				SELECT SMWorkCompletedID, 1, @NextBatchSeq, ApplyLine, ApplyLine, TransType,
					InvoicedRecType, InvoicedDescription,
					InvoicedGLCo, InvoicedGLAcct, InvoicedTaxGroup, InvoicedTaxCode,
					-InvoicedAmount, -InvoicedTaxBasis, -InvoicedTaxAmount, -InvoicedDiscOffered, -InvoicedTaxDisc
				FROM dbo.SMInvoiceDetailChanges
				WHERE SMInvoiceID = @SMInvoiceID AND TransType IN ('C','D')
				
				IF @@rowcount <> 0
				BEGIN
					INSERT dbo.bARBH (Co, Mth, BatchId, BatchSeq, TransType, [Source], ARTransType, CustGroup, Customer, RecType, Invoice, TransDate, AppliedMth, AppliedTrans, PayTerms)
					SELECT ARCo, @BatchMth, @BatchId, @NextBatchSeq, 'A', 'SM Invoice', @ARTransType, CustGroup, Customer, RecType, Invoice, TransDate, AppliedMth, AppliedTrans, PayTerms
					FROM dbo.bARTH
					WHERE ARCo = @ARCo AND Mth = @ApplyMth AND ARTrans = @ApplyTrans
					
					INSERT dbo.vSMInvoiceARBH (SMInvoiceID, Co, Mth, BatchId, BatchSeq)
					SELECT @SMInvoiceID, @ARCo, @BatchMth, @BatchId, @NextBatchSeq

					SET @NextBatchSeq = @NextBatchSeq + 1
				END
				
				;WITH SMInvoiceDetailChanges_CTE
				AS
				(
					SELECT SMWorkCompletedID, CASE WHEN TransType = 'C' AND TaxGroupEqual = 1 AND TaxCodeEqual = 1 THEN ApplyLine END ApplyLine, TransType,
						CurrentDescription,
						CurrentGLCo, CurrentGLAcct, CurrentTaxGroup, CurrentTaxCode,
						CurrentAmount, CurrentTaxBasis, CurrentTaxAmount, CurrentDiscOffered, CurrentTaxDisc
					FROM dbo.SMInvoiceDetailChanges
					WHERE SMInvoiceID = @SMInvoiceID AND TransType IN ('A', 'C')
				)
				INSERT @ARBL
				SELECT SMWorkCompletedID, 0, @NextBatchSeq, ApplyLine, ApplyLine, TransType,
					@RecType, convert(varchar(30), CurrentDescription),
					CurrentGLCo, CurrentGLAcct, CurrentTaxGroup, CurrentTaxCode,
					CurrentAmount, CurrentTaxBasis, CurrentTaxAmount, 
					CurrentDiscOffered, CurrentTaxDisc
				FROM SMInvoiceDetailChanges_CTE
				
				IF @@rowcount <> 0
				BEGIN
					INSERT dbo.bARBH (Co, Mth, BatchId, BatchSeq, TransType, [Source], ARTransType, CustGroup, Customer, RecType, Invoice, TransDate, AppliedMth, AppliedTrans, PayTerms)
					SELECT ARCo, @BatchMth, @BatchId, @NextBatchSeq, 'A', 'SM Invoice', @ARTransType, CustGroup, Customer, @RecType, Invoice, TransDate, AppliedMth, AppliedTrans, PayTerms
					FROM dbo.bARTH
					WHERE ARCo = @ARCo AND Mth = @ApplyMth AND ARTrans = @ApplyTrans
					
					INSERT dbo.vSMInvoiceARBH (SMInvoiceID, Co, Mth, BatchId, BatchSeq)
					SELECT @SMInvoiceID, @ARCo, @BatchMth, @BatchId, @NextBatchSeq
					
					SET @NextBatchSeq = @NextBatchSeq + 1
				END
			END

			SELECT @NextARLine = MAX(ARLine)
			FROM dbo.bARTL
			WHERE ARCo = @ARCo AND Mth = @ApplyMth AND ARTrans = @ApplyTrans

			WHILE EXISTS(SELECT 1 FROM @ARBL WHERE ARLine IS NULL)
			BEGIN
				UPDATE TOP (1) @ARBL
				SET @NextARLine = ISNULL(@NextARLine, 0) + 1, ARLine = @NextARLine
				WHERE ARLine IS NULL
			END
			
			--Add the change records for work completed that didn't have the tax info change.
			INSERT dbo.bARBL (Co, Mth, BatchId, BatchSeq, ARLine, TransType, LineType, [Description],
				RecType, GLCo, GLAcct, TaxGroup, TaxCode, Amount, TaxBasis, TaxAmount, DiscOffered, TaxDisc,
				ApplyMth, ApplyTrans, ApplyLine, SMWorkCompletedID)
			SELECT @ARCo, @BatchMth, @BatchId, BatchSeq, ARLine, 'A', 'O', [Description],
				RecType, GLCo, GLAcct, TaxGroup, TaxCode, Amount, TaxBasis, TaxAmount, DiscOffered, TaxDisc,
				@ApplyMth, @ApplyTrans, ApplyLine, SMWorkCompletedID
			FROM @ARBL
			
			INSERT dbo.vSMWorkCompletedARBL (Co, Mth, BatchId, BatchSeq, ARLine, SMInvoiceID, SMWorkCompletedID, IsReversing)
			SELECT @ARCo, @BatchMth, @BatchId, BatchSeq, ARLine, @SMInvoiceID, SMWorkCompletedID, IsReversing
			FROM @ARBL
			
			--For delete records we insert one more record so that the work completed is updated to no longer point to an ARTL record
			INSERT dbo.vSMWorkCompletedARBL (Co, Mth, BatchId, BatchSeq, ARLine, SMInvoiceID, SMWorkCompletedID, IsReversing)
			SELECT @ARCo, @BatchMth, @BatchId, BatchSeq, NULL, @SMInvoiceID, SMWorkCompletedID, 0
			FROM @ARBL
			WHERE TransType = 'D'

			DELETE @InvoicesToProcess WHERE SMInvoiceID = @SMInvoiceID
		END
		
		COMMIT TRAN
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN
		SET @errmsg = ERROR_MESSAGE()
		RETURN 1
	END CATCH

	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMInvoiceBatchCreate] TO [public]
GO
