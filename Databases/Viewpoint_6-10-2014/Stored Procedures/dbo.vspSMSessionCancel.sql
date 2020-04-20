SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
	CREATE  procedure [dbo].[vspSMSessionCancel]
	/******************************************************
	* CREATED BY:  MarkH 
	*
	* Usage:  Remove values from vSMSession table
	* Modified: 5/30/13 - TFS - 44858 - Modified to support changes for SM Invoice	
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
BEGIN
	SET NOCOUNT ON

	--If a batch was created and the client was terminated then the previous batch should be cleaned up.
	DECLARE @BatchesToCleanup TABLE (Co bCompany NOT NULL, Mth bMonth NOT NULL, BatchId bBatchID NOT NULL)
	
	INSERT @BatchesToCleanup
	SELECT DISTINCT vSMInvoiceARBH.Co, vSMInvoiceARBH.Mth, vSMInvoiceARBH.BatchId
	FROM dbo.vSMInvoiceSession
		INNER JOIN dbo.vSMInvoice ON vSMInvoiceSession.SMInvoiceID = vSMInvoice.SMInvoiceID
		INNER JOIN dbo.vSMInvoiceARBH ON vSMInvoice.SMCo = vSMInvoiceARBH.SMCo AND vSMInvoice.Invoice = vSMInvoiceARBH.Invoice
	WHERE vSMInvoiceSession.SMSessionID = @SMSessionID

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

		--Retrieve all work completed records that have backups for the given session.
		--If we are only reverting records that are part of actual invoices then we narrow the list down.
		DECLARE @WorkCompletedToRevert TABLE (SMWorkCompletedID bigint)

		--Grab all the wc records currently part of the existing invoice
		INSERT @WorkCompletedToRevert
		SELECT vSMWorkCompleted.SMWorkCompletedID
		FROM dbo.vSMInvoiceSession
			INNER JOIN dbo.vSMInvoice ON vSMInvoiceSession.SMInvoiceID = vSMInvoice.SMInvoiceID
			INNER JOIN dbo.vSMInvoiceDetail ON vSMInvoice.SMCo = vSMInvoiceDetail.SMCo AND vSMInvoice.Invoice = vSMInvoiceDetail.Invoice
			INNER JOIN dbo.vSMWorkCompleted ON vSMInvoiceDetail.SMCo = vSMWorkCompleted.SMCo AND vSMInvoiceDetail.WorkOrder = vSMWorkCompleted.WorkOrder AND vSMInvoiceDetail.WorkCompleted = vSMWorkCompleted.WorkCompleted
		WHERE vSMInvoiceSession.SMSessionID = @SMSessionID AND vSMInvoice.Invoiced = 1

		IF EXISTS
		(
			SELECT 1
			FROM @WorkCompletedToRevert WorkCompletedToRevert
				INNER JOIN dbo.vSMWorkCompletedDetail ON WorkCompletedToRevert.SMWorkCompletedID = vSMWorkCompletedDetail.SMWorkCompletedID AND vSMWorkCompletedDetail.IsSession = 1
			WHERE vSMWorkCompletedDetail.SMWorkCompletedID IS NULL
		)
		BEGIN
			ROLLBACK TRAN
			SET @msg = 'Reverting can''t be done because backups don''t exist.'
			RETURN 1
		END

		--Set the update in progress to true for the Payroll related records	
		UPDATE SMMyTimesheetLink
		SET UpdateInProgress = 1
		FROM dbo.SMMyTimesheetLink
			INNER JOIN @WorkCompletedToRevert WorkCompletedToRevert ON SMMyTimesheetLink.SMWorkCompletedID = WorkCompletedToRevert.SMWorkCompletedID

		UPDATE vSMBC
		SET UpdateInProgress = 1
		FROM dbo.vSMBC
			INNER JOIN @WorkCompletedToRevert WorkCompletedToRevert ON vSMBC.SMWorkCompletedID = WorkCompletedToRevert.SMWorkCompletedID

		-- Find the labor records that have already been posted.
		DECLARE @ProcessedLaborRecords TABLE (SMWorkCompletedID bigint)

		INSERT @ProcessedLaborRecords
		SELECT SMWorkCompleted.SMWorkCompletedID
		FROM SMWorkCompleted
		INNER JOIN SMWorkCompletedLabor ON SMWorkCompletedLabor.SMWorkCompletedID=SMWorkCompleted.SMWorkCompletedID
		INNER JOIN @WorkCompletedToRevert WorkCompletedToRevert ON SMWorkCompleted.SMWorkCompletedID = WorkCompletedToRevert.SMWorkCompletedID
		LEFT JOIN vSMMyTimesheetLink ON vSMMyTimesheetLink.SMWorkCompletedID = SMWorkCompleted.SMWorkCompletedID
		LEFT JOIN vSMBC ON vSMBC.SMWorkCompletedID = SMWorkCompleted.SMWorkCompletedID
		WHERE SMWorkCompleted.Type=2 
		AND vSMMyTimesheetLink.SMWorkCompletedID IS NULL
		AND vSMBC.SMWorkCompletedID IS NULL
	
		-- Create a temporary link with UpdateInProcess set to 1 so the update trigger will allow them to be updated.
		INSERT vSMMyTimesheetLink (SMCo, PRCo, WorkOrder, Scope, WorkCompleted, SMWorkCompletedID, EntryEmployee, Employee, StartDate, DayNumber, Sheet, Seq, UpdateInProgress)
		SELECT SMWorkCompleted.SMCo, SMTechnician.PRCo, SMWorkCompleted.WorkOrder, SMWorkCompleted.Scope, SMWorkCompleted.WorkCompleted, SMWorkCompleted.SMWorkCompletedID, 
				SMTechnician.Employee, SMTechnician.Employee, SMWorkCompleted.Date, 1, 1, 1, 1
		FROM SMWorkCompleted
		INNER JOIN SMTechnician ON SMTechnician.SMCo=SMWorkCompleted.SMCo AND SMTechnician.Technician=SMWorkCompleted.Technician
		INNER JOIN SMWorkCompletedLabor ON SMWorkCompletedLabor.SMWorkCompletedID=SMWorkCompleted.SMWorkCompletedID
		INNER JOIN @ProcessedLaborRecords ProcessedLaborRecords ON SMWorkCompleted.SMWorkCompletedID = ProcessedLaborRecords.SMWorkCompletedID
	
		--Get rid of the current records
		DELETE vSMWorkCompletedDetail
		FROM dbo.vSMWorkCompletedDetail
			INNER JOIN @WorkCompletedToRevert WorkCompletedToRevert ON vSMWorkCompletedDetail.SMWorkCompletedID = WorkCompletedToRevert.SMWorkCompletedID
		WHERE IsSession = 0

		--Do the actual revert
		UPDATE vSMWorkCompletedDetail
		SET IsSession = 0
		FROM dbo.vSMWorkCompletedDetail
			INNER JOIN @WorkCompletedToRevert WorkCompletedToRevert ON vSMWorkCompletedDetail.SMWorkCompletedID = WorkCompletedToRevert.SMWorkCompletedID
	
		--Set the update in progress to false for the Payroll related records
		UPDATE SMMyTimesheetLink
		SET UpdateInProgress = 0
		FROM dbo.SMMyTimesheetLink
			INNER JOIN @WorkCompletedToRevert WorkCompletedToRevert ON SMMyTimesheetLink.SMWorkCompletedID = WorkCompletedToRevert.SMWorkCompletedID
		
		UPDATE vSMBC
		SET UpdateInProgress = 0
		FROM dbo.vSMBC
			INNER JOIN @WorkCompletedToRevert WorkCompletedToRevert ON vSMBC.SMWorkCompletedID = WorkCompletedToRevert.SMWorkCompletedID

		-- Delete the temporary link.		
		DELETE SMMyTimesheetLink
		FROM SMMyTimesheetLink
		INNER JOIN @ProcessedLaborRecords ProcessedLaborRecords ON SMMyTimesheetLink.SMWorkCompletedID = ProcessedLaborRecords.SMWorkCompletedID

		--Revert the invoice detail
		UPDATE vSMInvoiceLine
		SET NoCharge = InvoicedLine.NoCharge, [Description] = InvoicedLine.[Description],
			GLCo = InvoicedLine.GLCo, GLAccount = InvoicedLine.GLAccount, Amount = InvoicedLine.Amount,
			TaxGroup = InvoicedLine.TaxGroup, TaxCode = InvoicedLine.TaxCode, TaxBasis = InvoicedLine.TaxBasis, TaxAmount = InvoicedLine.TaxAmount,
			DiscountOffered = InvoicedLine.DiscountOffered, TaxDiscount = InvoicedLine.TaxDiscount
		FROM dbo.vSMInvoiceSession
			INNER JOIN dbo.vSMInvoice ON vSMInvoiceSession.SMInvoiceID = vSMInvoice.SMInvoiceID
			INNER JOIN dbo.vSMInvoiceLine ON vSMInvoice.SMCo = vSMInvoiceLine.SMCo AND vSMInvoice.Invoice = vSMInvoiceLine.Invoice
			INNER JOIN dbo.vSMInvoiceLine InvoicedLine ON vSMInvoiceLine.SMCo = InvoicedLine.SMCo AND vSMInvoiceLine.InvoiceLine = InvoicedLine.InvoiceLine AND InvoicedLine.Invoiced = 1
		WHERE vSMInvoiceSession.SMSessionID = @SMSessionID

		--Revert lines that were removed
		UPDATE vSMInvoiceDetail
		SET IsRemoved = 0
		FROM dbo.vSMInvoiceSession
			INNER JOIN dbo.vSMInvoice ON vSMInvoiceSession.SMInvoiceID = vSMInvoice.SMInvoiceID
			INNER JOIN dbo.vSMInvoiceDetail ON vSMInvoice.SMCo = vSMInvoiceDetail.SMCo AND vSMInvoice.Invoice = vSMInvoiceDetail.Invoice
		WHERE vSMInvoiceSession.SMSessionID = @SMSessionID
		
		--Delete invoice lines if the invoice was never processed
		DELETE CurrentAndBackupInvoiceLines
		FROM dbo.vSMInvoiceSession
			INNER JOIN dbo.vSMInvoice ON vSMInvoiceSession.SMInvoiceID = vSMInvoice.SMInvoiceID
			INNER JOIN dbo.vSMInvoiceLine ON vSMInvoice.SMCo = vSMInvoiceLine.SMCo AND vSMInvoice.Invoice = vSMInvoiceLine.Invoice
			INNER JOIN dbo.vSMInvoiceLine CurrentAndBackupInvoiceLines ON vSMInvoiceLine.SMCo = CurrentAndBackupInvoiceLines.SMCo AND vSMInvoiceLine.InvoiceLine = CurrentAndBackupInvoiceLines.InvoiceLine
		WHERE vSMInvoiceSession.SMSessionID = @SMSessionID AND vSMInvoiceLine.LastPostedARLine IS NULL

		--Delete invoice details that no longer have invoice lines
		DELETE vSMInvoiceDetail
		FROM dbo.vSMInvoiceSession
			INNER JOIN dbo.vSMInvoice ON vSMInvoiceSession.SMInvoiceID = vSMInvoice.SMInvoiceID
			INNER JOIN dbo.vSMInvoiceDetail ON vSMInvoice.SMCo = vSMInvoiceDetail.SMCo AND vSMInvoice.Invoice = vSMInvoiceDetail.Invoice
			LEFT JOIN dbo.vSMInvoiceLine ON vSMInvoiceDetail.SMCo = vSMInvoiceLine.SMCo AND vSMInvoiceDetail.Invoice = vSMInvoiceLine.Invoice AND vSMInvoiceDetail.InvoiceDetail = vSMInvoiceLine.InvoiceDetail
		WHERE vSMInvoiceSession.SMSessionID = @SMSessionID AND vSMInvoiceLine.SMInvoiceLineID IS NULL
		
		DECLARE @InvoiceBillingSchedules TABLE (SMAgreementBillingScheduleID bigint)
		
		INSERT @InvoiceBillingSchedules 
		SELECT vSMAgreementBillingSchedule.SMAgreementBillingScheduleID
		FROM dbo.vSMInvoiceSession
			INNER JOIN dbo.vSMInvoice ON vSMInvoiceSession.SMInvoiceID = vSMInvoice.SMInvoiceID
			INNER JOIN dbo.vSMAgreementBillingSchedule ON vSMAgreementBillingSchedule.SMInvoiceID = vSMInvoice.SMInvoiceID
		WHERE vSMInvoiceSession.SMSessionID = @SMSessionID AND vSMInvoice.Invoiced = 0 AND vSMInvoice.InvoiceType = 'A'
		
		--Remove all the billing schedule records that were part of a pending invoice.
		UPDATE dbo.vSMAgreementBillingSchedule
		SET SMInvoiceID = NULL
		WHERE SMAgreementBillingScheduleID IN (SELECT SMAgreementBillingScheduleID FROM @InvoiceBillingSchedules)

		--Delete the BillingSchedules that are adjustments.
		DELETE dbo.vSMAgreementBillingSchedule
		WHERE BillingType = 'A' AND SMAgreementBillingScheduleID IN (SELECT SMAgreementBillingScheduleID FROM @InvoiceBillingSchedules)

		DECLARE @InvoicesToDelete TABLE (SMInvoiceID bigint)

		--Get rid of the invoice session records first so we don't get any foreign key exceptions
		--Must use the table because the view does a join
		DELETE dbo.vSMInvoiceSession
			OUTPUT deleted.SMInvoiceID
				INTO @InvoicesToDelete
		WHERE SMSessionID = @SMSessionID

		--Get rid all the pending invoices
		DELETE vSMInvoice
		FROM dbo.vSMInvoice
			INNER JOIN @InvoicesToDelete InvoicesToDelete ON vSMInvoice.SMInvoiceID = InvoicesToDelete.SMInvoiceID
		WHERE vSMInvoice.Invoiced = 0

		--Get rid of the actual session
		DELETE dbo.vSMSession WHERE SMSessionID = @SMSessionID

		COMMIT TRAN
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN
		SET @msg = ERROR_MESSAGE()
		RETURN 1
	END CATCH

	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMSessionCancel] TO [public]
GO
