SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspSMAgreementInvoiceBatchCreate] 
	/******************************************************
	* CREATED BY: 
	* MODIFIED BY: Matthew B - 11/27/2012 TK-19569
	*			   Eric V - 01/17/2013 D-06216 Added BatchMonth to where clause when selecting Invoices
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
	*******************************************************/
	@SMSessionID int, @ARCo bCompany, @BatchMth bMonth, @BatchId bBatchID = NULL OUTPUT, @errmsg varchar(100) OUTPUT
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @rcode int, @SMInvoiceID int, @ARTransType char(1), @ApplyMth bMonth, @ApplyTrans bTrans, @NextBatchSeq int,
		@NextARLine smallint, @RecType tinyint, @DiscRate bPct

	SELECT @rcode = 0, @NextBatchSeq = 1

	DECLARE @InvoicesToProcess TABLE (SMInvoiceID bigint)
	
	INSERT @InvoicesToProcess
	SELECT SMInvoiceID
	FROM dbo.SMInvoiceSession 
	WHERE SMSessionID = @SMSessionID
	AND BatchMonth = @BatchMth

	IF @@rowcount = 0
	BEGIN
		SET @errmsg = 'No invoices to process'
		RETURN 1
	END

	EXEC @BatchId = dbo.bspHQBCInsert @co = @ARCo, @month = @BatchMth, @source = 'SM Invoice', @batchtable = 'ARBH', @restrict = 'Y', @adjust = 'N', @prgroup = NULL, @prenddate = NULL, @errmsg = @errmsg OUTPUT
	IF @BatchId = 0 RETURN 1

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
			@RecType = ISNULL(ARCM.RecType, ARCO.RecType),
			@DiscRate = SMInvoice.DiscRate
		FROM dbo.SMInvoice
			INNER JOIN dbo.ARCO ON SMInvoice.ARCo = ARCO.ARCo
			INNER JOIN dbo.ARCM ON SMInvoice.CustGroup = ARCM.CustGroup AND SMInvoice.BillToARCustomer = ARCM.Customer
		WHERE SMInvoiceID = @SMInvoiceID
		
		IF @errmsg IS NOT NULL
		BEGIN
			SET @rcode = 1
			BREAK
		END
		
		IF @ARTransType = 'I' --New Invoice
		BEGIN
			INSERT dbo.bARBH (Co, Mth, BatchId, BatchSeq, TransType, [Source], ARTransType, CustGroup, Customer, RecType, Invoice, TransDate, DueDate, DiscDate, PayTerms)
			SELECT ARCo, @BatchMth, @BatchId, @NextBatchSeq, 'A', 'SM Invoice', @ARTransType, CustGroup, BillToARCustomer, @RecType, dbo.bfJustifyStringToDatatype(dbo.vfToString(Invoice), 'bARInvoice'), InvoiceDate, DueDate, DiscDate, PayTerms
			FROM dbo.vSMInvoice
			WHERE SMInvoiceID = @SMInvoiceID
			
			INSERT dbo.vSMInvoiceARBH (SMInvoiceID, Co, Mth, BatchId, BatchSeq)
			SELECT @SMInvoiceID, @ARCo, @BatchMth, @BatchId, @NextBatchSeq
			
			INSERT dbo.bARBL (Co, Mth, BatchId, 
				BatchSeq, ARLine, TransType, LineType, 
				[Description],
				RecType, 
				GLCo, GLAcct, 
				TaxGroup, TaxCode, 
				Amount, 
				TaxBasis, 
				TaxAmount, 
				DiscOffered, 
				TaxDisc,
				SMAgreementBillingScheduleID)

			SELECT @ARCo, @BatchMth, @BatchId,
				@NextBatchSeq, 1 ARLine, 'A' TransType, 'O' LineType,
				LEFT(dbo.vfSMAgreementBillingFormat(SMAgreement.Agreement, SMAgreementBillingSchedule.Service, SMAgreementBillingSchedule.Date),30) CurrentDescription,
				@RecType RecType,
				SMDepartment.GLCo, SMDepartment.AgreementRevGLAcct,
				TaxGroup, 
				TaxCode,
				BillingAmount + ISNULL(TaxAmount, 0),
				TaxBasis, 
				TaxAmount, 
				BillingAmount*@DiscRate DiscOffered,
				0 TaxDisc,
				SMAgreementBillingScheduleID
			FROM dbo.SMAgreementBillingSchedule
			INNER JOIN dbo.SMAgreement 
				ON SMAgreement.SMCo = SMAgreementBillingSchedule.SMCo
				AND SMAgreement.Agreement = SMAgreementBillingSchedule.Agreement
				AND SMAgreement.Revision = SMAgreementBillingSchedule.Revision
			INNER JOIN dbo.vSMAgreementType
				ON vSMAgreementType.SMCo=SMAgreement.SMCo
				AND vSMAgreementType.AgreementType=SMAgreement.AgreementType
			INNER JOIN dbo.SMDepartment
				ON vSMAgreementType.SMCo = SMDepartment.SMCo
				AND vSMAgreementType.Department = SMDepartment.Department 
			WHERE SMAgreementBillingSchedule.SMInvoiceID = @SMInvoiceID
			
		END
		ELSE
		BEGIN
			/* Create reversing entries for Voided invoices */
			INSERT dbo.bARBH (Co, Mth, BatchId, BatchSeq, TransType, [Source], ARTransType, CustGroup, Customer, RecType, Invoice, TransDate, AppliedMth, AppliedTrans, PayTerms)
			SELECT ARCo, Mth, @BatchId, @NextBatchSeq, 'A', 'SM Invoice', @ARTransType, CustGroup, Customer, RecType, Invoice, TransDate, Mth, ARTrans, PayTerms
			FROM dbo.bARTH
			WHERE ARCo = @ARCo AND Mth = @ApplyMth AND ARTrans = @ApplyTrans
			
			INSERT dbo.vSMInvoiceARBH (SMInvoiceID, Co, Mth, BatchId, BatchSeq)
			SELECT @SMInvoiceID, @ARCo, @BatchMth, @BatchId, @NextBatchSeq

			INSERT dbo.bARBL (Co, Mth, BatchId, BatchSeq, ARLine, TransType, LineType, [Description],
				RecType, GLCo, GLAcct, TaxGroup, TaxCode, Amount, TaxBasis, TaxAmount, DiscOffered, TaxDisc,
				ApplyMth, ApplyTrans, ApplyLine, SMAgreementBillingScheduleID)
			SELECT @ARCo, @BatchMth, @BatchId,
				@NextBatchSeq, 
				ARLine, 
				'A' TransType,
				LineType,
				Description,
				RecType,
				GLCo,
				GLAcct,
				TaxGroup, 
				TaxCode,
				-Amount, 
				-TaxBasis, 
				-TaxAmount, 
				-DiscOffered, 
				-TaxDisc,
				Mth, 
				ARTrans, 
				ARLine,
				SMAgreementBillingScheduleID
			FROM ARTL
			WHERE ARCo = @ARCo AND Mth = @ApplyMth AND ARTrans = @ApplyTrans

		END	
		SET @NextBatchSeq = @NextBatchSeq + 1

		DELETE @InvoicesToProcess WHERE SMInvoiceID = @SMInvoiceID
	END

	IF (@rcode <> 0)
	BEGIN
		/* Delete the batch and SMBC records */
		DELETE dbo.ARBL WHERE Co = @ARCo AND Mth = @BatchMth AND BatchId = @BatchId
		
		DELETE dbo.ARBH WHERE Co = @ARCo AND Mth = @BatchMth AND BatchId = @BatchId
		
		/* Cancel the batch */
		UPDATE dbo.bHQBC
		SET InUseBy = SUSER_SNAME() 
		WHERE Co = @ARCo AND Mth = @BatchMth AND BatchId = @BatchId
		
		EXEC dbo.bspHQBCExitCheck @ARCo, @BatchMth, @BatchId, 'SM Invoice', 'ARBH', NULL
	END

	RETURN @rcode
END
GO
GRANT EXECUTE ON  [dbo].[vspSMAgreementInvoiceBatchCreate] TO [public]
GO
