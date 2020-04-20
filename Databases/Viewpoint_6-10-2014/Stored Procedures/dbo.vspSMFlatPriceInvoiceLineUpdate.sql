SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*********************************************************************
*	Created By	: DanK 05/09/13
*	
*	Purpose		: This proc is intended to distribute Flat Price Adjustments
*				across the corresponding SMInvoiceLine entries
*
*	MODIFIED	: DanK 07/03/13
*					Added a filter to the Tax Group / Code variable query. 
*					This is to ensure that if there is a valid Tax Group / Code
*					for any of the records, we will pick it up. 
*				 JVH 9/18/13 - TFS-61960
					Fixed a situation in which the user could end up causing a divide by 0 error.
*********************************************************************/ 

CREATE PROCEDURE [dbo].[vspSMFlatPriceInvoiceLineUpdate]	@SMCo				bCompany,
															@Invoice			INT,	
															@InvoiceDetail		BIGINT,	
															@NewBillingAmount	bDollar,
															@Description		bDesc,
															@msg VARCHAR(255) = NULL OUTPUT
AS
BEGIN
	BEGIN TRY 
		BEGIN TRAN
			DECLARE @OldBillingAmount	bDollar, 
					@errmsg				VARCHAR(255)
		
			SELECT	@OldBillingAmount = (SELECT		SUM(IL.Amount)
											FROM		SMInvoiceLine IL
											WHERE		IL.SMCo 	= @SMCo
													AND IL.Invoice 	= @Invoice
													AND IL.InvoiceDetail = @InvoiceDetail)

			-- If there has been a change to the scope description, update the description on related Invoice Lines
			IF @Description <> (SELECT		Description 
								FROM		SMWorkOrderScope WS
								INNER JOIN	SMInvoiceDetail ID
										ON	ID.SMCo = WS.SMCo
										AND ID.WorkOrder = WS.WorkOrder
										AND ID.Scope = WS.Scope
								WHERE		ID.SMCo = @SMCo
										AND ID.Invoice = @Invoice
										AND ID.InvoiceDetail = @InvoiceDetail)
			BEGIN 
				UPDATE	SMInvoiceLine
				SET		Description		= @Description
				WHERE	SMCo			= @SMCo
					AND Invoice			= @Invoice
					AND InvoiceDetail	= @InvoiceDetail
			END 

			-- Only proceed when Billing Amount has changed and does not exceed the flat price on the scope
			IF	(@NewBillingAmount <> @OldBillingAmount) 

			BEGIN 
				DECLARE @TaxRate bRate, 
						@TaxGroup bGroup,
						@TaxCode bTaxCode,
						@InvoiceDate bDate, 
						@rcode INT

				SELECT	TOP(1)
						@TaxGroup = IL.TaxGroup, 
						@TaxCode = IL.TaxCode,
						@InvoiceDate = I.InvoiceDate
				FROM	SMInvoiceLine IL

				INNER JOIN SMInvoice I
						ON I.SMCo = IL.SMCo
						AND I.Invoice = IL.Invoice

				WHERE	IL.SMCo = @SMCo
					AND IL.Invoice = @Invoice
					AND IL.InvoiceDetail = @InvoiceDetail
					AND IL.TaxGroup IS NOT NULL 
					AND IL.TaxCode IS NOT NULL 

				-- Only need to worry about getting a Tax Rate if there is a valid
				IF @TaxGroup IS NOT NULL AND @TaxCode IS NOT NULL
				BEGIN 
					-- Most relevant part (what we need) of this is the Tax Rate 
					EXEC @rcode = dbo.vspHQTaxRateGet @taxgroup = @TaxGroup, @taxcode = @TaxCode, @compdate = @InvoiceDate, @taxrate = @TaxRate OUTPUT,
								 @valueadd = NULL , @gstrate = NULL, 
								 @crdGLAcct = NULL, @crdRetgGLAcct = NULL, @dbtGLAcct = NULL, 
								 @dbtRetgGLAcct = NULL, @crdGLAcctPST = NULL, @crdRetgGLAcctPST = NULL, 
								 @msg = @errmsg OUTPUT
	
					IF @rcode <> 0 
					BEGIN 
						ROLLBACK TRAN
						RETURN @rcode 
					END
				END;

				--Distribute the amount amongst the lines
				UPDATE vSMInvoiceLine
				SET Amount = CASE WHEN vSMWorkOrderScope.Price = 0 THEN 0 ELSE @NewBillingAmount * vSMFlatPriceRevenueSplit.Amount / vSMWorkOrderScope.Price END
				FROM dbo.vSMInvoiceDetail					
					INNER JOIN dbo.vSMInvoiceLine ON vSMInvoiceDetail.SMCo = vSMInvoiceLine.SMCo AND vSMInvoiceDetail.Invoice = vSMInvoiceLine.Invoice AND vSMInvoiceDetail.InvoiceDetail = vSMInvoiceLine.InvoiceDetail
					INNER JOIN dbo.vSMWorkOrderScope ON vSMInvoiceDetail.SMCo = vSMWorkOrderScope.SMCo AND vSMInvoiceDetail.WorkOrder = vSMWorkOrderScope.WorkOrder AND vSMInvoiceDetail.Scope = vSMWorkOrderScope.Scope
					INNER JOIN dbo.vSMEntity ON vSMWorkOrderScope.SMCo = vSMEntity.SMCo AND vSMWorkOrderScope.WorkOrder = vSMEntity.WorkOrder AND vSMWorkOrderScope.Scope = vSMEntity.WorkOrderScope
					INNER JOIN dbo.vSMFlatPriceRevenueSplit ON vSMFlatPriceRevenueSplit.SMCo = vSMEntity.SMCo AND vSMEntity.EntitySeq = vSMFlatPriceRevenueSplit.EntitySeq AND vSMFlatPriceRevenueSplit.Seq = vSMInvoiceLine.InvoiceDetailSeq
				WHERE vSMInvoiceDetail.SMCo = @SMCo AND vSMInvoiceDetail.Invoice = @Invoice AND vSMInvoiceDetail.InvoiceDetail = @InvoiceDetail

				-- Use a variable for this so we don't have to wait for the calculation to happen multiple times
				DECLARE @CheckBillingAmount bDollar 
	
				SELECT	@CheckBillingAmount = SUM(Amount) 
				FROM	SMInvoiceLine 
				WHERE	SMCo = @SMCo 
					AND Invoice = @Invoice 
					AND InvoiceDetail = @InvoiceDetail

				-- Now, to ensure the values add up to the Billing Amount initially passed in and deal with rounding Issues 
				IF @NewBillingAmount <> @CheckBillingAmount
				BEGIN 
					UPDATE	SMInvoiceLine
					SET		Amount = Amount + (@NewBillingAmount - @CheckBillingAmount)
					FROM	SMInvoiceLine
					WHERE	SMInvoiceLineID = (SELECT TOP(1) SMInvoiceLineID
												FROM	SMInvoiceLine 
												WHERE	SMCo = @SMCo 
													AND Invoice = @Invoice
													AND InvoiceDetail = @InvoiceDetail)
				END 
	
				-- Last order of business, update the tax amounts if necessary
				IF @TaxRate IS NOT NULL
				BEGIN 
					UPDATE	SMInvoiceLine
					SET		TaxAmount = Amount * @TaxRate, 
							TaxBasis = Amount
					FROM	SMInvoiceLine
					WHERE	SMCo = @SMCo
						AND Invoice = @Invoice
						AND InvoiceDetail = @InvoiceDetail
						AND TaxCode IS NOT NULL
				END 
			
		END		
		COMMIT TRAN
	END TRY 
	BEGIN CATCH 
		SET @msg = ERROR_MESSAGE()
		RETURN 1
	END CATCH 

	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMFlatPriceInvoiceLineUpdate] TO [public]
GO
