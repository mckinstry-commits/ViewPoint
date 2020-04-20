SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspSMSessionInvoiceItemRemove]
	/******************************************************
	* CREATED BY:  Jeremiah Barkley
	* MODIFIED By: ECV 04/14/11 Changed to commit changes for pending invoices
	*                           begore the line is removed.  Delete the session record
	*                           for pending invoices but just set InvoiceID to null for
	*                           lines removed from posted invoices.
	*
	* Usage:  Removes an item from the invoice session.
	*	
	*
	* Input params:
	*	
	*	@SMWorkCompletedID
	*
	* Output params:
	*	@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	(
   		@SMWorkCompletedID bigint, 
   		@msg varchar(250) OUTPUT
   	)
	AS 
	SET NOCOUNT ON
	DECLARE @SMInvoiceID bigint, @IsPartOfPendingInvoice bit
	
	/* Is this WC record part of a posted invoice? */
	/*IF EXISTS(SELECT 1 FROM vSMWorkCompletedDetail
		WHERE SMWorkCompletedID = @SMWorkCompletedID
		  AND IsSession = 0
		  AND SMInvoiceID IS NOT NULL)
	BEGIN*/

	SELECT @SMInvoiceID = SMInvoiceID, @IsPartOfPendingInvoice = CASE WHEN SMWorkCompletedARTLID IS NULL THEN 1 ELSE 0 END
	FROM dbo.SMWorkCompleted
	WHERE SMWorkCompletedID = @SMWorkCompletedID

	--If the invoice has not been billed yet then we get rid of the backup record
	--so that the line can be added to another invoice right away. This also prevents
	--a revert for a pending invoice from pulling an item that has been removed back in.
	IF @IsPartOfPendingInvoice = 1
	BEGIN
		DELETE dbo.SMWorkCompletedDetail
		WHERE SMWorkCompletedID = @SMWorkCompletedID AND IsSession = 1
	END

	-- Posted Invoice
	UPDATE dbo.SMWorkCompletedDetail
	SET SMInvoiceID = NULL
	WHERE SMWorkCompletedID = @SMWorkCompletedID AND IsSession = 0
	IF (@@ROWCOUNT <> 1)
	BEGIN
		SET @msg = 'Session item was not removed.'
		RETURN 1
	END

	--If we don't find any more work completed records tied to this invoice
	--and the invoice is a pending invoice then we will get rid of the pending invoice altogether
	--We can't rely on the cancel session to take care of this because we will have already removed
	--the link that relates the invoice to the session.
	IF NOT EXISTS(SELECT 1 FROM dbo.SMWorkCompleted WHERE SMInvoiceID = @SMInvoiceID)
		AND NOT EXISTS(SELECT 1 FROM dbo.SMInvoice WHERE SMInvoiceID = @SMInvoiceID AND ARTrans IS NOT NULL)
	BEGIN
		--Get rid of the backup records
		DELETE dbo.SMWorkCompletedDetail
		WHERE SMInvoiceID = @SMInvoiceID
	
		--Must use the table because the view has an instead of trigger
		DELETE dbo.vSMInvoiceSession
		WHERE SMInvoiceID = @SMInvoiceID
		
		DELETE dbo.SMInvoice
		WHERE SMInvoiceID = @SMInvoiceID
	END

	/*END
	ELSE
	BEGIN
		-- Pending Invoice
		--Copy over the session record to the original records
		UPDATE SMWorkCompleted SET IsSession = 0 FROM dbo.SMWorkCompleted
		WHERE SMWorkCompletedID = @SMWorkCompletedID

		--Now DELETE the session copy
		DELETE dbo.SMWorkCompletedDetail
		FROM dbo.SMWorkCompletedDetail
		WHERE SMWorkCompletedID = @SMWorkCompletedID
		AND IsSession = 1
	END*/
		
	RETURN 0

GO
GRANT EXECUTE ON  [dbo].[vspSMSessionInvoiceItemRemove] TO [public]
GO
