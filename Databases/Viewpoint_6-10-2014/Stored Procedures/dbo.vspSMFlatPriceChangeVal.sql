SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*********************************************************************
*	Created By	: DanK 05/14/13
*	
*	Purpose		: Validate that the new Flat Price Billing amount does 
*				not exceed the total amount that can potentially be billed. 
*	MODIFIED	: JVH 9/18/13 - TFS-61959
*					Fixed a situation in which multiple records could be returned from the query.
*********************************************************************/ 


CREATE PROCEDURE [dbo].[vspSMFlatPriceChangeVal]	@SMCo					AS bCompany,
													@Invoice				AS INT, 
													@InvoiceDetail			AS INT,	
													@NewBillingAmount		AS bDollar,
													@PreviousBillingAmount	AS bDollar,
													@msg					AS VARCHAR(255) = NULL OUTPUT

AS 
BEGIN 

	IF @NewBillingAmount > ((SELECT		Price WS
							FROM		SMWorkOrderScope WS
							INNER JOIN	SMInvoiceDetail ID
									ON	ID.SMCo = WS.SMCo
									AND ID.WorkOrder = WS.WorkOrder
									AND ID.Scope = WS.Scope
							WHERE		ID.SMCo = @SMCo
									AND	ID.Invoice = @Invoice
									AND ID.InvoiceDetail = @InvoiceDetail) - @PreviousBillingAmount)
	BEGIN 
		SET @msg = 'The new billing amount may not exceed the remaining billable amount'
		RETURN 1 
	END 

	RETURN 0 

END
GO
GRANT EXECUTE ON  [dbo].[vspSMFlatPriceChangeVal] TO [public]
GO
