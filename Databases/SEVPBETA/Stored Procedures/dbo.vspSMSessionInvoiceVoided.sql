SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspSMSessionInvoiceVoided]
	/******************************************************
	* CREATED BY:  Eric Vaterlaus
	*
	* Usage:  Update any voided invoices in the session as voided and remove work completed records
	*         from the voided invoice.
	* Modified: ECV 10/03/12 TK-18080 Changed to correctly remove detail from invoice when the void is processed in a 
	*				different month then the original post month.
	*
	* Input params:
	*	
	*	@SMSessionID	Session ID
	*   @BatchMth       Batch Month
	*
	* Output params:
	*	@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	(
   		@SMSessionID bigint,
   		@BatchMth datetime,
   		@msg varchar(250) OUTPUT
   	)
	AS 
	SET NOCOUNT ON
	
	DECLARE @VoidedInvoices AS TABLE (SMInvoiceID bigint, InvoiceType char(1))
	
	BEGIN TRY
		INSERT @VoidedInvoices
		SELECT SMInvoiceSession.SMInvoiceID, SMInvoice.InvoiceType
		FROM dbo.SMInvoiceSession
		INNER JOIN dbo.SMInvoice ON SMInvoice.SMInvoiceID = SMInvoiceSession.SMInvoiceID
		INNER JOIN dbo.vSMInvoiceSession 
			ON SMInvoiceSession.SMSessionID = vSMInvoiceSession.SMSessionID
			AND SMInvoiceSession.SMInvoiceID = vSMInvoiceSession.SMInvoiceID
		WHERE SMInvoiceSession.SMSessionID = @SMSessionID
			AND SMInvoice.BatchMonth = @BatchMth
			AND vSMInvoiceSession.VoidFlag = 'Y'

		IF (@@ROWCOUNT=0)
			RETURN 0
	END TRY
	BEGIN CATCH
		SET @msg = 'Error creating list of voided invoices: ' + ERROR_MESSAGE();
		RETURN 1
	END CATCH
		
	BEGIN TRY
		-- Remove all SMWorkCompleted records from the invoice.
		UPDATE dbo.SMWorkCompletedDetail
		SET SMInvoiceID = NULL
		WHERE IsSession = 0 AND SMInvoiceID IN (SELECT SMInvoiceID FROM @VoidedInvoices WHERE InvoiceType = 'W')
	END TRY
	BEGIN CATCH
		SET @msg = 'Error removing work completed from voided invoices: ' + ERROR_MESSAGE();
		RETURN 1
	END CATCH
	
	BEGIN TRY
		DECLARE @InvoiceBillingSchedules TABLE (SMAgreementBillingScheduleID bigint)
		
		INSERT @InvoiceBillingSchedules
		SELECT SMAgreementBillingScheduleID
		FROM vSMAgreementBillingSchedule
		WHERE SMInvoiceID IN (SELECT SMInvoiceID FROM @VoidedInvoices WHERE InvoiceType = 'A')
		
		-- Remove all billing schedule records from the invoice.
		UPDATE dbo.vSMAgreementBillingSchedule
		SET SMInvoiceID = NULL
		WHERE SMAgreementBillingScheduleID IN (SELECT SMAgreementBillingScheduleID FROM @InvoiceBillingSchedules)
		
		-- Delete the adjustment billing schedule records.
		DELETE dbo.vSMAgreementBillingSchedule
		WHERE BillingType = 'A' AND SMAgreementBillingScheduleID IN (SELECT SMAgreementBillingScheduleID FROM @InvoiceBillingSchedules)
	END TRY
	BEGIN CATCH
		SET @msg = 'Error removing agreement billing schedule from voided invoices: ' + ERROR_MESSAGE();
		RETURN 1
	END CATCH

	BEGIN TRY
		-- Mark the Invoice as voided.
		UPDATE dbo.SMInvoice
			SET VoidDate = convert(datetime, convert(varchar, Getdate(), 101)),
				VoidedBy = suser_name()
		WHERE SMInvoiceID IN (SELECT SMInvoiceID FROM @VoidedInvoices)
	END TRY
	BEGIN CATCH
		SET @msg = 'Error marking invoices as void: ' + ERROR_MESSAGE();
		RETURN 1
	END CATCH
			
	RETURN 0
GO
GRANT EXECUTE ON  [dbo].[vspSMSessionInvoiceVoided] TO [public]
GO
