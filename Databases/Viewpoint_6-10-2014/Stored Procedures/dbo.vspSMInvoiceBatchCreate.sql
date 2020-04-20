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
	*              Matthew B - 11/27/2012 TK-19569
	*              JVH 5/28/13 - TFS-44858	Modified to support SM Flat Price Billing
	*
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
	
	DECLARE @SMCo bCompany, @Invoice int, @ARTransType char(1), @ApplyMth bMonth, @ApplyTrans bTrans, 
			@NextBatchSeq int, @NextARLine smallint, @RecType tinyint, @VoidFlag bYN

	SELECT @NextBatchSeq = 1

	DECLARE @InvoicesToProcess TABLE (SMCo bCompany NOT NULL, Invoice int NOT NULL, VoidFlag bYN NOT NULL)

	INSERT @InvoicesToProcess
	SELECT DISTINCT SMCo, Invoice, VoidFlag
	FROM dbo.SMInvoiceListDetailLine
	WHERE SMSessionID = @SMSessionID AND ARCo = @ARCo AND BatchMonth = @BatchMth AND ChangesMade = 1
	IF @@rowcount = 0
	BEGIN
		SET @errmsg = 'No invoices to process'
		RETURN 1
	END

	-- Verify the GL Month is open for the invoice detail GLCo using the correct BatchMth
	IF EXISTS
	(
		SELECT 1 
		FROM dbo.SMInvoiceListDetailLine
			INNER JOIN dbo.vfGLClosedMonths('SM Invoice', @BatchMth) ON SMInvoiceListDetailLine.GLCo = vfGLClosedMonths.GLCo OR SMInvoiceListDetailLine.InvoicedGLCo = vfGLClosedMonths.GLCo
		WHERE SMInvoiceListDetailLine.SMSessionID = @SMSessionID AND SMInvoiceListDetailLine.ARCo = @ARCo AND SMInvoiceListDetailLine.BatchMonth = @BatchMth AND SMInvoiceListDetailLine.ChangesMade = 1 AND vfGLClosedMonths.IsMonthOpen = 0)
	BEGIN
		SET @errmsg = 'GL Month is closed for the invoice detail GL Company.'
		RETURN 1
	END

	--If a batch was created and the client was terminated then the previous batch should be cleaned up.
	DECLARE @BatchesToCleanup TABLE (Co bCompany NOT NULL, Mth bMonth NOT NULL, BatchId bBatchID NOT NULL)
	
	INSERT @BatchesToCleanup
	SELECT DISTINCT vSMInvoiceARBH.Co, vSMInvoiceARBH.Mth, vSMInvoiceARBH.BatchId
	FROM @InvoicesToProcess InvoicesToProcess
		INNER JOIN dbo.vSMInvoiceARBH ON InvoicesToProcess.SMCo = vSMInvoiceARBH.SMCo AND InvoicesToProcess.Invoice = vSMInvoiceARBH.Invoice
	
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
			SELECT TOP 1 @SMCo = SMCo, @Invoice = Invoice, @VoidFlag = VoidFlag
			FROM @InvoicesToProcess

			SELECT @errmsg =
				CASE
					WHEN bARCM.[Status] = 'I' THEN 'Bill To Customer # ' + dbo.vfToString(bARCM.Customer) + ' is inactive.'
					WHEN bARCM.[Status] = 'H' THEN 'Bill To Customer # ' + dbo.vfToString(bARCM.Customer) + ' is on hold.'
					WHEN vSMInvoice.DueDate IS NULL THEN 'Due Date is required.'
				END,
				@ApplyMth = ARPostedMth, @ApplyTrans = ARTrans,
				@ARTransType = CASE WHEN ARPostedMth IS NOT NULL AND ARTrans IS NOT NULL THEN 'A'/*Adjustment*/ ELSE 'I'/*Invoice*/ END,
				@RecType = ISNULL(bARCM.RecType, bARCO.RecType)
			FROM dbo.vSMInvoice
				INNER JOIN dbo.bARCO ON vSMInvoice.ARCo = bARCO.ARCo
				INNER JOIN dbo.bARCM ON vSMInvoice.CustGroup = bARCM.CustGroup AND vSMInvoice.BillToARCustomer = bARCM.Customer
			WHERE vSMInvoice.SMCo = @SMCo AND vSMInvoice.Invoice = @Invoice

			IF @errmsg IS NOT NULL
			BEGIN
				ROLLBACK TRAN
				RETURN 1
			END

			--Reset the batch line so that if the taxes were changed and then changed back
			--a new line won't be created
			UPDATE vSMInvoiceLine
			SET BatchLine = LastPostedARLine
			WHERE SMCo = @SMCo AND Invoice = @Invoice

			--Copy the batchline value to the invoiced line so that the invoiced line
			--can be deleted when the reversing batch line is processed.
			UPDATE InvoicedLine
			SET BatchLine = vSMInvoiceLine.BatchLine
			FROM dbo.vSMInvoiceLine
				LEFT JOIN dbo.vSMInvoiceLine InvoicedLine ON vSMInvoiceLine.SMCo = InvoicedLine.SMCo AND vSMInvoiceLine.InvoiceLine = InvoicedLine.InvoiceLine AND InvoicedLine.Invoiced = 1
			WHERE vSMInvoiceLine.SMCo = @SMCo AND vSMInvoiceLine.Invoice = @Invoice

			SET @NextARLine = ISNULL((SELECT MAX(ARLine) FROM dbo.bARTL WHERE ARCo = @ARCo AND Mth = @ApplyMth AND ARTrans = @ApplyTrans), 0)

			--Update the batch line when taxes have changed or when a new line has been added.
			UPDATE vSMInvoiceLine
			SET BatchLine = @NextARLine, @NextARLine = @NextARLine + 1
			FROM dbo.vSMInvoiceLine
				LEFT JOIN dbo.vSMInvoiceLine InvoicedLine ON vSMInvoiceLine.SMCo = InvoicedLine.SMCo AND vSMInvoiceLine.InvoiceLine = InvoicedLine.InvoiceLine AND InvoicedLine.Invoiced = 1
			WHERE vSMInvoiceLine.SMCo = @SMCo AND vSMInvoiceLine.Invoice = @Invoice AND (vSMInvoiceLine.BatchLine IS NULL OR dbo.vfIsEqual(vSMInvoiceLine.TaxGroup, InvoicedLine.TaxGroup) = 0 OR dbo.vfIsEqual(vSMInvoiceLine.TaxCode, InvoicedLine.TaxCode) = 0)

			--Update the discounts
			UPDATE vSMInvoiceLine
			SET DiscountOffered = ISNULL(CASE WHEN bARCO.DiscOpt = 'I' THEN CAST(vSMInvoiceLine.Amount * vSMInvoice.DiscRate AS numeric(12,2)) END, 0),
				TaxDiscount = ISNULL(CASE WHEN bARCO.DiscOpt = 'I' AND bARCO.DiscTax = 'Y' THEN CAST(vSMInvoiceLine.TaxAmount * vSMInvoice.DiscRate AS numeric(12,2)) END, 0)
			FROM dbo.vSMInvoice
				INNER JOIN dbo.bARCO ON vSMInvoice.ARCo = vSMInvoice.ARCo
				INNER JOIN dbo.vSMInvoiceLine ON vSMInvoice.SMCo = vSMInvoiceLine.SMCo AND vSMInvoice.Invoice = vSMInvoiceLine.Invoice
			WHERE vSMInvoice.SMCo = @SMCo AND vSMInvoice.Invoice = @Invoice

			IF @ARTransType = 'I' --New Invoice
			BEGIN
				INSERT dbo.bARBH (Co, Mth, BatchId, BatchSeq, TransType, [Source], ARTransType, CustGroup, Customer, RecType, Invoice, TransDate, DueDate, DiscDate, PayTerms)
				SELECT ARCo, @BatchMth, @BatchId, @NextBatchSeq, 'A', 'SM Invoice', @ARTransType, CustGroup, BillToARCustomer, @RecType, dbo.bfJustifyStringToDatatype(dbo.vfToString(InvoiceNumber), 'bARInvoice'), InvoiceDate, DueDate, DiscDate, PayTerms
				FROM dbo.vSMInvoice
				WHERE SMCo = @SMCo AND Invoice = @Invoice

				INSERT dbo.vSMInvoiceARBH (SMCo, Invoice, IsReversing, VoidInvoice, Co, Mth, BatchId, BatchSeq)
				SELECT @SMCo, @Invoice, 0 IsReversing, 0 VoidInvoice, @ARCo, @BatchMth, @BatchId, @NextBatchSeq

				INSERT dbo.bARBL (Co, Mth, BatchId, BatchSeq, ARLine, TransType, LineType, [Description],
					RecType, GLCo, GLAcct, TaxGroup, TaxCode, Amount, TaxBasis, TaxAmount, DiscOffered, TaxDisc)
				SELECT @ARCo, @BatchMth, @BatchId, @NextBatchSeq, BatchLine, 'A', 'O', CAST([Description] AS varchar(30)),
					@RecType, GLCo, GLAccount, TaxGroup, TaxCode,
					CASE WHEN NoCharge = 'Y' THEN 0 ELSE Amount + TaxAmount END,
					CASE WHEN NoCharge = 'Y' THEN 0 ELSE TaxBasis END, CASE WHEN NoCharge = 'Y' THEN 0 ELSE TaxAmount END,
					CASE WHEN NoCharge = 'Y' THEN 0 ELSE DiscountOffered END, CASE WHEN NoCharge = 'Y' THEN 0 ELSE TaxDiscount END
				FROM dbo.vSMInvoiceLine
				WHERE SMCo = @SMCo AND Invoice = @Invoice

				SET @NextBatchSeq = @NextBatchSeq + 1
			END
			ELSE --Adjustment
			BEGIN
				IF EXISTS
				(
					SELECT 1 
					FROM dbo.SMInvoiceListDetailLine
					WHERE SMCo = @SMCo AND Invoice = @Invoice AND ChangesMade = 1 AND InvoicedAmount IS NOT NULL
				)
				BEGIN
					INSERT dbo.bARBH (Co, Mth, BatchId, BatchSeq, TransType, [Source], ARTransType, CustGroup, Customer, RecType, Invoice, TransDate, AppliedMth, AppliedTrans, PayTerms)
					SELECT ARCo, @BatchMth, @BatchId, @NextBatchSeq, 'A', 'SM Invoice', @ARTransType, CustGroup, Customer, RecType, Invoice, TransDate, AppliedMth, AppliedTrans, PayTerms
					FROM dbo.bARTH
					WHERE ARCo = @ARCo AND Mth = @ApplyMth AND ARTrans = @ApplyTrans
					
					INSERT dbo.vSMInvoiceARBH (SMCo, Invoice, IsReversing, VoidInvoice, Co, Mth, BatchId, BatchSeq)
					SELECT @SMCo, @Invoice, 1 IsReversing, CASE WHEN @VoidFlag = 'Y' THEN 1 ELSE 0 END, @ARCo, @BatchMth, @BatchId, @NextBatchSeq

					INSERT dbo.bARBL (Co, Mth, BatchId, BatchSeq, ARLine, TransType, LineType, [Description],
						RecType, GLCo, GLAcct, TaxGroup, TaxCode, Amount, TaxBasis, TaxAmount, DiscOffered, TaxDisc, ApplyMth, ApplyTrans, ApplyLine)
					SELECT @ARCo, @BatchMth, @BatchId, @NextBatchSeq, InvoicedBatchLine, 'A', 'O', CAST(InvoicedDescription AS varchar(30)),
						@RecType, InvoicedGLCo, InvoicedGLAccount, InvoicedTaxGroup, InvoicedTaxCode,
						CASE WHEN InvoicedNoCharge = 'Y' THEN 0 ELSE -InvoicedAmount + -InvoicedTaxAmount END,
						CASE WHEN InvoicedNoCharge = 'Y' THEN 0 ELSE -InvoicedTaxBasis END, CASE WHEN InvoicedNoCharge = 'Y' THEN 0 ELSE -InvoicedTaxAmount END,
						CASE WHEN InvoicedNoCharge = 'Y' THEN 0 ELSE -InvoicedDiscountOffered END, CASE WHEN InvoicedNoCharge = 'Y' THEN 0 ELSE -InvoicedTaxDiscount END,
						@ApplyMth, @ApplyTrans, InvoicedBatchLine
					FROM dbo.SMInvoiceListDetailLine
					WHERE SMCo = @SMCo AND Invoice = @Invoice AND ChangesMade = 1 AND InvoicedAmount IS NOT NULL

					SET @NextBatchSeq = @NextBatchSeq + 1
				END
			
				IF @VoidFlag = 'N' AND
					EXISTS
					(
						SELECT 1 
						FROM dbo.SMInvoiceListDetailLine
						WHERE SMCo = @SMCo AND Invoice = @Invoice AND ChangesMade = 1 AND IsRemoved = 0
					)
				BEGIN
					INSERT dbo.bARBH (Co, Mth, BatchId, BatchSeq, TransType, [Source], ARTransType, CustGroup, Customer, RecType, Invoice, TransDate, AppliedMth, AppliedTrans, PayTerms)
					SELECT ARCo, @BatchMth, @BatchId, @NextBatchSeq, 'A', 'SM Invoice', @ARTransType, CustGroup, Customer, RecType, Invoice, TransDate, AppliedMth, AppliedTrans, PayTerms
					FROM dbo.bARTH
					WHERE ARCo = @ARCo AND Mth = @ApplyMth AND ARTrans = @ApplyTrans
					
					INSERT dbo.vSMInvoiceARBH (SMCo, Invoice, IsReversing, VoidInvoice, Co, Mth, BatchId, BatchSeq)
					SELECT @SMCo, @Invoice, 0 IsReversing, 0 VoidInvoice, @ARCo, @BatchMth, @BatchId, @NextBatchSeq

					INSERT dbo.bARBL (Co, Mth, BatchId, BatchSeq, ARLine, TransType, LineType, [Description],
						RecType, GLCo, GLAcct, TaxGroup, TaxCode, Amount, TaxBasis, TaxAmount, DiscOffered, TaxDisc, ApplyMth, ApplyTrans, ApplyLine)
					SELECT @ARCo, @BatchMth, @BatchId, @NextBatchSeq, BatchLine, 'A', 'O', CAST([Description] AS varchar(30)),
						@RecType, GLCo, GLAccount, TaxGroup, TaxCode,
						CASE WHEN NoCharge = 'Y' THEN 0 ELSE Amount + TaxAmount END,
						CASE WHEN NoCharge = 'Y' THEN 0 ELSE TaxBasis END, CASE WHEN NoCharge = 'Y' THEN 0 ELSE TaxAmount END,
						CASE WHEN NoCharge = 'Y' THEN 0 ELSE DiscountOffered END, CASE WHEN NoCharge = 'Y' THEN 0 ELSE TaxDiscount END,
						@ApplyMth,
						@ApplyTrans,
						CASE WHEN BatchLine = InvoicedBatchLine THEN BatchLine END
					FROM dbo.SMInvoiceListDetailLine
					WHERE SMCo = @SMCo AND Invoice = @Invoice AND ChangesMade = 1 AND IsRemoved = 0

					SET @NextBatchSeq = @NextBatchSeq + 1
				END
			END

			DELETE @InvoicesToProcess WHERE SMCo = @SMCo AND Invoice = @Invoice
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
