SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspSMSessionInvoiceVoidFlag]
	/******************************************************
	* CREATED BY:  Eric Vaterlaus
	*
	* Usage:  Update the void flag for an invoice in a session.
	*	
	*
	* Input params:
	*	
	*	@SMSessionID	Session ID
	*	@SMInvoiceID	Invoice ID
	*   @VoidFlag       Void Flag
	*
	* Output params:
	*	@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	(
   		@SMSessionID bigint,
   		@SMInvoiceID bigint,
   		@VoidFlag bYN,
   		@msg varchar(250) OUTPUT
   	)
	AS 
	SET NOCOUNT ON
	
	BEGIN TRY
		
		UPDATE vSMInvoiceSession SET VoidFlag = @VoidFlag
		FROM dbo.vSMInvoiceSession
		WHERE vSMInvoiceSession.SMSessionID = @SMSessionID
			AND vSMInvoiceSession.SMInvoiceID = @SMInvoiceID

	END TRY
	BEGIN CATCH
		SET @msg = 'Error creating list of voided invoices: ' + ERROR_MESSAGE();
		RETURN 1
	END CATCH
		
	RETURN 0
GO
GRANT EXECUTE ON  [dbo].[vspSMSessionInvoiceVoidFlag] TO [public]
GO
