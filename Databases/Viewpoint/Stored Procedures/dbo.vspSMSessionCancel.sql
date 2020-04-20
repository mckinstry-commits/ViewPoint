SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
	CREATE  procedure [dbo].[vspSMSessionCancel]
	/******************************************************
	* CREATED BY:  MarkH 
	*
	* Usage:  Remove values from vSMSession table
	*	
	*
	* Input params:
	*	
	*	@SMSessionID - SM Session ID
	*
	* Output params:
	*	@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	@SMSessionID int, @msg varchar(255) = NULL OUTPUT
   	
	AS 
	SET NOCOUNT ON

	DECLARE @InvoicesToDelete TABLE
	(
		SMInvoiceID bigint,
		InvoiceType char(1)
	)

	--This list should be the list of pending invoices in this session
	INSERT @InvoicesToDelete
	SELECT SMInvoice.SMInvoiceID, SMInvoice.InvoiceType
	FROM dbo.SMInvoice
		INNER JOIN dbo.vSMInvoiceSession ON SMInvoice.SMInvoiceID = vSMInvoiceSession.SMInvoiceID
	WHERE SMInvoice.Invoiced = 0 AND vSMInvoiceSession.SMSessionID = @SMSessionID

	--If a batch was created and the client was terminated then the previous batch should be cleaned up.
	DECLARE @BatchesToCleanup TABLE (Co bCompany NOT NULL, Mth bMonth NOT NULL, BatchId bBatchID NOT NULL)
	
	INSERT @BatchesToCleanup
	SELECT DISTINCT vSMInvoiceARBH.Co, vSMInvoiceARBH.Mth, vSMInvoiceARBH.BatchId
		FROM @InvoicesToDelete InvoicesToDelete
			INNER JOIN dbo.vSMInvoiceARBH ON InvoicesToDelete.SMInvoiceID = vSMInvoiceARBH.SMInvoiceID

	SELECT @msg = 'Previous SM Invoice batch co: ' + dbo.vfToString(BatchesToCleanup.Co) + ', month: ' + dbo.vfToMonthString(BatchesToCleanup.Mth) + ', batch id: ' + dbo.vfToString(BatchesToCleanup.BatchId) + ' must be posted through SM Batches.'
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

		--Get rid of the invoice session records first so we don't get any foreign key exceptions
		--Must use the table because the view does a join
		DELETE dbo.vSMInvoiceSession
		WHERE SMSessionID = @SMSessionID
		
		--Get rid of the actual session
		DELETE dbo.SMSession WHERE SMSessionID = @SMSessionID
		
		--Remove all the work completed records that were part of a pending invoice
		UPDATE SMWorkCompletedDetail
		SET SMInvoiceID = NULL
		FROM dbo.SMWorkCompletedDetail 
			INNER JOIN @InvoicesToDelete InvoicesToDelete ON SMWorkCompletedDetail.SMInvoiceID = InvoicesToDelete.SMInvoiceID
		WHERE InvoicesToDelete.InvoiceType = 'W'
		
		DECLARE @InvoiceBillingSchedules TABLE (SMAgreementBillingScheduleID bigint)
		
		INSERT @InvoiceBillingSchedules 
		SELECT SMAgreementBillingSchedule.SMAgreementBillingScheduleID
		FROM dbo.SMAgreementBillingSchedule
			INNER JOIN @InvoicesToDelete InvoicesToDelete ON SMAgreementBillingSchedule.SMInvoiceID = InvoicesToDelete.SMInvoiceID
		WHERE InvoicesToDelete.InvoiceType = 'A'
		
		--Remove all the billing schedule records that were part of a pending invoice.
		UPDATE dbo.vSMAgreementBillingSchedule
		SET SMInvoiceID = NULL
		WHERE SMAgreementBillingScheduleID IN (SELECT SMAgreementBillingScheduleID FROM @InvoiceBillingSchedules)

		--Delete the BillingSchedules that are adjustments.
		DELETE dbo.vSMAgreementBillingSchedule
		WHERE BillingType = 'A' AND SMAgreementBillingScheduleID IN (SELECT SMAgreementBillingScheduleID FROM @InvoiceBillingSchedules)

		--Get rid all the pending invoices
		DELETE dbo.SMInvoice
		FROM dbo.SMInvoice 
			INNER JOIN @InvoicesToDelete InvoicesToDelete ON SMInvoice.SMInvoiceID = InvoicesToDelete.SMInvoiceID

		COMMIT TRAN
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN
		SET @msg = ERROR_MESSAGE()
		RETURN 1
	END CATCH

	RETURN 0
GO
GRANT EXECUTE ON  [dbo].[vspSMSessionCancel] TO [public]
GO
