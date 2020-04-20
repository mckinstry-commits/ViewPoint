SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jeremiah Barkley
-- Create date: 11/1/12
-- Description:	
--	  Modifide: Lane G - Added purchase linetype
-- =============================================
CREATE PROCEDURE [dbo].[vspSMWorkOrderScopeAgreementUpdate]
	@SMCo bCompany, 
	@WorkOrder int, 
	@Scope int, 
	@Agreement varchar(15), 
	@Revision int, 
	@PriceMethod char(1),
	@UseAgreementRates bYN,
	@msg varchar(255) = NULL OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	
	-- Validation
	IF ((@Agreement IS NULL OR @Revision IS NULL) AND (@Agreement IS NOT NULL OR @Revision IS NOT NULL))
	BEGIN	-- If one of these are provided, then they must all be provided.
		SET @msg = 'Invalid Agreement/Revision.'
		RETURN 1
	END
	
	-- Do not allow change if a line has already been billed.
	IF EXISTS(SELECT 1 FROM SMWorkCompleted
		LEFT JOIN SMInvoice ON SMInvoice.SMInvoiceID = SMWorkCompleted.SMInvoiceID
		WHERE SMWorkCompleted.SMCo = @SMCo AND SMWorkCompleted.WorkOrder = @WorkOrder AND Scope = @Scope AND SMInvoice.Invoiced = 1)
	BEGIN
		SET @msg = 'The Agreement change could not be made because a work completed line item for this scope seq has already been billed.'
		RETURN 1
	END
	
	-- Start transaction
	BEGIN TRY
		BEGIN TRAN
			DECLARE @CurrentWorkCompletedID bigint, @Date bDate, @Coverage char(1),
				@TaxGroup bGroup, @TaxType tinyint, @TaxCode bTaxCode, @TaxRate bRate,
				@msgOut varchar(255), @returnCode int
			
			DECLARE @WorkCompletedToUpdate TABLE (SMWorkCompletedID bigint, [Date] bDate, TaxGroup bGroup NULL, TaxType tinyint NULL, TaxCode bTaxCode NULL)
			
			-- Determine the new coverage for the work completed lines
			SET @Coverage = CASE WHEN @Agreement IS NOT NULL AND @PriceMethod = 'C' THEN 'C' 
				WHEN @Agreement IS NOT NULL AND @PriceMethod = 'T' AND @UseAgreementRates = 'Y' THEN 'A' 
				ELSE NULL END
			
			-- Update Equipment line items
			UPDATE vSMWorkCompletedDetail
			SET
				vSMWorkCompletedDetail.PriceRate = Rates.PriceRate,
				vSMWorkCompletedDetail.PriceTotal = Rates.PriceRate * CASE WHEN RevCodeInfo.Basis = 'H' THEN SMWorkCompleted.TimeUnits ELSE SMWorkCompleted.WorkUnits END,
				vSMWorkCompletedDetail.Agreement = @Agreement,
				vSMWorkCompletedDetail.Revision = @Revision,
				vSMWorkCompletedDetail.Coverage = @Coverage
			FROM dbo.SMWorkCompleted
				CROSS APPLY dbo.vfSMRateEquipment(SMCo, WorkOrder, Scope, [Date], @Agreement, @Revision, @Coverage, EMCo, Equipment, RevCode, CostRate) Rates 
				CROSS APPLY dbo.vfEMEquipmentRevCodeSetup(EMCo, Equipment, EMGroup, RevCode) RevCodeInfo
				INNER JOIN dbo.vSMWorkCompletedDetail ON vSMWorkCompletedDetail.SMWorkCompletedID = SMWorkCompleted.SMWorkCompletedID
			WHERE SMWorkCompleted.SMCo = @SMCo AND SMWorkCompleted.WorkOrder = @WorkOrder AND SMWorkCompleted.Scope = @Scope AND SMWorkCompleted.[Type] = 1
			
			-- Update Labor line items
			UPDATE vSMWorkCompletedDetail
			SET
				vSMWorkCompletedDetail.PriceRate = Rates.Rate,
				vSMWorkCompletedDetail.PriceTotal = Rates.Rate * SMWorkCompleted.PriceQuantity,
				vSMWorkCompletedDetail.Agreement = @Agreement,
				vSMWorkCompletedDetail.Revision = @Revision,
				vSMWorkCompletedDetail.Coverage = @Coverage
			FROM dbo.SMWorkCompleted
				CROSS APPLY dbo.vfSMRateLabor(SMCo, WorkOrder, Scope, [Date], @Agreement, @Revision, @Coverage, PRCo, PayType, Craft, Class, Technician) Rates 
				INNER JOIN dbo.vSMWorkCompletedDetail ON vSMWorkCompletedDetail.SMWorkCompletedID = SMWorkCompleted.SMWorkCompletedID
			WHERE SMWorkCompleted.SMCo = @SMCo AND SMWorkCompleted.WorkOrder = @WorkOrder AND SMWorkCompleted.Scope = @Scope AND SMWorkCompleted.[Type] = 2
			
			-- Update Misc line items
			UPDATE vSMWorkCompletedDetail
			SET
				vSMWorkCompletedDetail.PriceRate = CASE WHEN @Coverage = 'C' THEN 0 ELSE ISNULL(Rates.BillableRate, SMWorkCompleted.PriceRate) END,
				vSMWorkCompletedDetail.PriceTotal = CASE WHEN @Coverage = 'C' THEN 0 ELSE ISNULL(Rates.BillableRate * SMWorkCompleted.PriceQuantity, SMWorkCompleted.PriceTotal) END,
				vSMWorkCompletedDetail.Agreement = @Agreement,
				vSMWorkCompletedDetail.Revision = @Revision,
				vSMWorkCompletedDetail.Coverage = @Coverage
			FROM dbo.SMWorkCompleted
				OUTER APPLY dbo.vfSMGetStandardItemRate (SMCo, WorkOrder, Scope, [Date], StandardItem, @Agreement, @Revision, @Coverage) Rates 
				INNER JOIN dbo.vSMWorkCompletedDetail ON vSMWorkCompletedDetail.SMWorkCompletedID = SMWorkCompleted.SMWorkCompletedID
			WHERE SMWorkCompleted.SMCo = @SMCo AND SMWorkCompleted.WorkOrder = @WorkOrder AND SMWorkCompleted.Scope = @Scope AND SMWorkCompleted.[Type] = 3

			-- Update Inventory line items
			UPDATE vSMWorkCompletedDetail
			SET
				vSMWorkCompletedDetail.PriceRate = vfSMRateInventory.PriceRate,
				vSMWorkCompletedDetail.PriceTotal = vfSMRateInventory.PriceTotal,
				vSMWorkCompletedDetail.Agreement = @Agreement,
				vSMWorkCompletedDetail.Revision = @Revision,
				vSMWorkCompletedDetail.Coverage = @Coverage
			FROM dbo.SMWorkCompleted
				CROSS APPLY dbo.vfSMRateInventory(SMCo, WorkOrder, Scope, [Date], @Agreement, @Revision, @Coverage, INCo, INLocation, MatlGroup, Part, UM, Quantity, ActualCost, PriceUM, PriceECM) 
				INNER JOIN dbo.vSMWorkCompletedDetail ON vSMWorkCompletedDetail.SMWorkCompletedID = SMWorkCompleted.SMWorkCompletedID
			WHERE SMWorkCompleted.SMCo = @SMCo AND SMWorkCompleted.WorkOrder = @WorkOrder AND SMWorkCompleted.Scope = @Scope AND SMWorkCompleted.[Type] = 4

			-- Update Purchase line items
			UPDATE vSMWorkCompletedDetail
			SET
				vSMWorkCompletedDetail.PriceRate = vfSMRatePurchase.PriceRate,
				vSMWorkCompletedDetail.PriceTotal = vfSMRatePurchase.PriceTotal,
				vSMWorkCompletedDetail.Agreement = @Agreement,
				vSMWorkCompletedDetail.Revision = @Revision,
				vSMWorkCompletedDetail.Coverage = @Coverage
			FROM dbo.SMWorkCompleted
				CROSS APPLY dbo.vfSMRatePurchase(SMCo, WorkOrder, Scope, [Date], @Agreement, @Revision, @Coverage, MatlGroup, Part, UM, Quantity, ProjCost, PriceUM, PriceECM) 
				INNER JOIN dbo.vSMWorkCompletedDetail ON vSMWorkCompletedDetail.SMWorkCompletedID = SMWorkCompleted.SMWorkCompletedID
			WHERE SMWorkCompleted.SMCo = @SMCo AND SMWorkCompleted.WorkOrder = @WorkOrder AND SMWorkCompleted.Scope = @Scope AND SMWorkCompleted.[Type] = 5

			-- Populate table variable - This is used to update taxes for all line types
			INSERT INTO @WorkCompletedToUpdate
			SELECT SMWorkCompletedID, [Date], TaxGroup, TaxType, TaxCode
			FROM dbo.SMWorkCompleted 
			WHERE SMCo = @SMCo AND WorkOrder = @WorkOrder AND Scope = @Scope AND TaxGroup IS NOT NULL AND TaxCode IS NOT NULL AND TaxType IS NOT NULL
			
			-- Loop through all line items to update taxes
			WHILE EXISTS (SELECT 1 FROM @WorkCompletedToUpdate)
			BEGIN
				SELECT TOP 1 @CurrentWorkCompletedID = SMWorkCompletedID, @Date = [Date], 
					@TaxGroup = TaxGroup, @TaxType = TaxType, @TaxCode = TaxCode
				FROM @WorkCompletedToUpdate

				EXEC @returnCode = dbo.vspHQTaxCodeVal @taxgroup = @TaxGroup, @taxcode = @TaxCode, @compdate = @Date, @taxtype = @TaxType, @taxrate = @TaxRate OUTPUT, @msg = @msgOut OUTPUT
				
				IF (@returnCode <> 0)
				BEGIN
					SET @msg = @msgOut
					ROLLBACK TRAN
					RETURN 1
				END
				
				-- Update Tax Amounts
				UPDATE dbo.vSMWorkCompletedDetail 
				SET TaxBasis = PriceTotal,
					TaxAmount = PriceTotal * @TaxRate
				WHERE SMWorkCompletedID = @CurrentWorkCompletedID

				DELETE FROM @WorkCompletedToUpdate WHERE SMWorkCompletedID = @CurrentWorkCompletedID
			END
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
GRANT EXECUTE ON  [dbo].[vspSMWorkOrderScopeAgreementUpdate] TO [public]
GO
