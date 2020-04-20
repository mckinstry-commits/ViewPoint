SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspSMWorkCompletedPurchaseUpdate] 
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 11/12/12
-- Description:	Adds/Updates/Deletes the work completed purchase line from the PO 
-- Modification: 
-- =============================================
	@POCo bCompany, @PO varchar(30), @POItem bItem, @POItemLine int, @OldSMCo bCompany, @OldWorkOrder int, @OldScope int, @OldWorkCompleted int, @Quantity bUnits = NULL, @ProjCost bDollar = NULL, @msg varchar(255) = NULL OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @rcode int,
		@MatlGroup bGroup, @Material bMatl, @CostUM bUM, @CostRate bUnitCost, @CostECM bECM,
		@DeleteWorkCompleted bit, @UpdateWorkCompleted bit,
		@SMCo bCompany, @WorkOrder int, @Scope int, @WorkCompleted int,
		@JCCostType bJCCType,
		@IsJobWorkOrder bit, @JobCostingMethod varchar(10),
		@MaterialChanged bit, @Reprice bit,
		@SMInvoiceID bigint,
		@TaxGroup bGroup, @TaxCode bTaxCode, @Date bDate, @TaxType tinyint, @TaxRate bRate,
		@PriceRate bUnitCost, @PriceTotal bDollar

	SELECT @MatlGroup = MatlGroup, @Material = Material, @CostUM = UM, @CostRate = CurUnitCost, @CostECM = CurECM
	FROM dbo.bPOIT
	WHERE POCo = @POCo AND PO = @PO AND POItem = @POItem

	SELECT @DeleteWorkCompleted = CASE WHEN ItemType <> 6 OR (SMCo <> @OldSMCo OR SMWorkOrder <> @OldWorkOrder OR SMScope <> @OldScope) THEN 1 ELSE 0 END,
		@UpdateWorkCompleted = CASE WHEN ItemType = 6 THEN 1 ELSE 0 END,
		@SMCo = SMCo, @WorkOrder = SMWorkOrder, @Scope = SMScope, @WorkCompleted = SMWorkCompleted,
		@JCCostType = SMJCCostType
	FROM dbo.vPOItemLine
	WHERE POCo = @POCo AND PO = @PO AND POItem = @POItem AND POItemLine = @POItemLine
	IF @@rowcount = 0
	BEGIN
		SELECT @DeleteWorkCompleted = 1, @UpdateWorkCompleted = 0
	END
	
	SELECT @IsJobWorkOrder = CASE WHEN Job IS NOT NULL THEN 1 ELSE 0 END,
		@JobCostingMethod = CASE WHEN @IsJobWorkOrder = 1 THEN CostingMethod END
	FROM dbo.vSMWorkOrder
	WHERE SMCo = @SMCo AND WorkOrder = @WorkOrder

	IF @DeleteWorkCompleted = 1
	BEGIN
		--THE CODE RELATED TO DELETING A WORK COMPLETED WILL NEED TO BE MODIFIED ONCE PARTIAL INVOICING IS CODED
		
		--If the work completed is part of an invoice that needs to be processed prevent the changes.
		IF EXISTS
		(
			SELECT 1
			FROM dbo.vSMWorkCompletedDetail
				INNER JOIN dbo.vSMInvoiceSession ON vSMWorkCompletedDetail.SMInvoiceID = vSMInvoiceSession.SMInvoiceID
			WHERE (vSMWorkCompletedDetail.SMCo = @OldSMCo AND vSMWorkCompletedDetail.WorkOrder = @OldWorkOrder AND vSMWorkCompletedDetail.WorkCompleted = @OldWorkCompleted) OR
				vSMWorkCompletedDetail.SMWorkCompletedID IN (SELECT SMWorkCompletedID FROM dbo.vSMWorkCompletedPurchase WHERE POCo = @POCo AND PO = @PO AND POItem = @POItem AND POItemLine = @POItemLine) --Once there can only be 1 work completed line per PO Distribution this check will not be needed
		)
		BEGIN
			SET @msg = 'A customer invoice for work order: SMCo ' + dbo.vfToString(@OldSMCo) + ' - WorkOrder ' + dbo.vfToString(@OldWorkOrder) + ' needs to be processed in order for the po distribution to be modified.'
			RETURN 1
		END

		--Need to use a CTE since views with instead of update trigger cannot have a from clause
		;WITH RelatedPOIT_CTE
		AS
		(
			SELECT *
			FROM dbo.bPOIT
			WHERE POCo = @POCo AND PO = @PO AND POItem = @POItem
		)
		--Clear costs for the work completed if it still part of an invoice
		UPDATE dbo.SMWorkCompleted
		--Keep the cost UM and quantity so if they want to code it to an AP line later they can
		SET CostRate = NULL, CostECM = NULL, ProjCost = NULL, ActualUnits = NULL, ActualCost = NULL, POCo = NULL, PO = NULL, POItem = NULL, POItemLine = NULL, PriceUM  = NULL, PriceRate  = NULL, PriceECM  = NULL,
			-- Copy PO Item material and description to not lose this information
			MatlGroup = (SELECT MatlGroup FROM RelatedPOIT_CTE), Part = (SELECT Material FROM RelatedPOIT_CTE), [Description] = (SELECT [Description] FROM RelatedPOIT_CTE)
		WHERE
			(
				(SMCo = @OldSMCo AND WorkOrder = @OldWorkOrder AND WorkCompleted = @OldWorkCompleted) OR
				SMWorkCompleted.SMWorkCompletedID IN (SELECT SMWorkCompletedID FROM dbo.vSMWorkCompletedPurchase WHERE POCo = @POCo AND PO = @PO AND POItem = @POItem AND POItemLine = @POItemLine) --Once there can only be 1 work completed line per PO Distribution this check will not be needed
			)
			AND EXISTS(SELECT 1 FROM vSMWorkCompletedDetail WHERE SMWorkCompleted.SMWorkCompletedID = SMWorkCompletedID AND SMInvoiceID IS NOT NULL)

		--Delete work completed as long as it is not part of an invoice
		DELETE dbo.vSMWorkCompleted
		WHERE
			(
				(SMCo = @OldSMCo AND WorkOrder = @OldWorkOrder AND WorkCompleted = @OldWorkCompleted) OR
				vSMWorkCompleted.SMWorkCompletedID IN (SELECT SMWorkCompletedID FROM dbo.vSMWorkCompletedPurchase WHERE POCo = @POCo AND PO = @PO AND POItem = @POItem AND POItemLine = @POItemLine) --Once there can only be 1 work completed line per PO Distribution this check will not be needed
			)
			AND NOT EXISTS(SELECT 1 FROM vSMWorkCompletedDetail WHERE vSMWorkCompleted.SMWorkCompletedID = SMWorkCompletedID AND SMInvoiceID IS NOT NULL)

		SET @WorkCompleted = NULL
	END
	
	--TEMPORARY CODE USED UNTIL PARTIAL BILLING IS SUPPORTED FOR WORK COMPLETED
	IF EXISTS
		(
			SELECT * 
			FROM  dbo.SMWorkCompleted
			WHERE POCo = @POCo AND PO = @PO AND POItem = @POItem AND POItemLine = @POItemLine AND NOT (dbo.vfIsEqual(SMCo, @SMCo) & dbo.vfIsEqual(WorkOrder, @WorkOrder) & dbo.vfIsEqual(WorkCompleted, @WorkCompleted) = 1)
		)
	BEGIN
		SET @UpdateWorkCompleted = 0
	END
	
	IF @UpdateWorkCompleted = 1
	BEGIN
		IF NOT EXISTS(SELECT 1 FROM dbo.vSMWorkCompleted WHERE SMCo = @SMCo AND WorkOrder = @WorkOrder AND WorkCompleted = @WorkCompleted)
		BEGIN
			IF EXISTS(
				SELECT 1 
				FROM dbo.vPOItemLine
					CROSS APPLY dbo.vfSMGetAccountingTreatment(vPOItemLine.SMCo, vPOItemLine.SMWorkOrder, vPOItemLine.SMScope, 5/*Purchase Line type*/, NULL)
				WHERE vPOItemLine.POCo = @POCo AND vPOItemLine.PO = @PO AND vPOItemLine.POItem = @POItem AND vPOItemLine.POItemLine = @POItemLine AND (vPOItemLine.GLCo <> vfSMGetAccountingTreatment.GLCo OR vPOItemLine.GLAcct <> vfSMGetAccountingTreatment.CurrentCostGLAcct))
			BEGIN
				SET @msg = 'The gl account assigned to the line doesn''t match the account that will be given the work completed line. Clear the scope field and re-enter the scope to default the correct account.'
				RETURN 1
			END

			--Use tran so that nothing else gets the same WorkCompleted value
			BEGIN TRAN

			SELECT @WorkCompleted = dbo.vfSMGetNextWorkCompletedSeq(@SMCo, @WorkOrder)

			--Insert based on whether it is a customer or job work order
			IF @IsJobWorkOrder = 1
			BEGIN
				--Job work order
				INSERT dbo.SMWorkCompleted (SMCo, WorkOrder, [Type], WorkCompleted, Scope, [Date], ServiceSite, PhaseGroup, POCo, PO, POItem, POItemLine, Quantity, UM, CostRate, CostECM, ProjCost, PriceUM, PriceECM, PriceTotal, GLCo, CostAccount, CostWIPAccount, RevenueAccount, RevenueWIPAccount, NoCharge, Provisional)
				SELECT vSMWorkOrderScope.SMCo, vSMWorkOrderScope.WorkOrder, 5/*Purchase LineType*/, @WorkCompleted, vSMWorkOrderScope.Scope, vPOItemLine.PostedDate,
					vSMWorkOrder.ServiceSite, vPOItemLine.SMPhaseGroup, vPOItemLine.POCo, vPOItemLine.PO, vPOItemLine.POItem, vPOItemLine.POItemLine,
					0 /*Quantity will be updated later*/, bPOIT.UM, bPOIT.CurUnitCost, bPOIT.CurECM, 0 /*ProjCost will be updated later*/,
					bPOIT.UM, bPOIT.CurECM, 0, /*PriceTotal will be updated later*/
					vfSMGetAccountingTreatment.GLCo, vfSMGetAccountingTreatment.CostGLAcct, vfSMGetAccountingTreatment.CostWIPGLAcct, vfSMGetAccountingTreatment.RevenueGLAcct, vfSMGetAccountingTreatment.RevenueWIPGLAcct,
					'N' NoCharge, CASE WHEN vSMWorkOrderScope.CallType IS NULL OR (vSMWorkOrderScope.RateTemplate IS NULL AND @JobCostingMethod = 'Revenue') THEN 1 ELSE 0 END
				FROM dbo.vPOItemLine
					INNER JOIN dbo.bPOIT ON vPOItemLine.POCo = bPOIT.POCo AND vPOItemLine.PO = bPOIT.PO AND vPOItemLine.POItem = bPOIT.POItem
					INNER JOIN dbo.vSMWorkOrderScope ON vPOItemLine.SMCo = vSMWorkOrderScope.SMCo AND vPOItemLine.SMWorkOrder = vSMWorkOrderScope.WorkOrder AND vPOItemLine.SMScope = vSMWorkOrderScope.Scope
					INNER JOIN dbo.vSMWorkOrder ON vPOItemLine.SMCo = vSMWorkOrder.SMCo AND vPOItemLine.SMWorkOrder = vSMWorkOrder.WorkOrder
					CROSS APPLY dbo.vfSMGetAccountingTreatment(vSMWorkOrderScope.SMCo, vSMWorkOrderScope.WorkOrder, vSMWorkOrderScope.Scope, 5/*Purchase LineType*/, NULL/*No Default CostType*/)
				WHERE vPOItemLine.POCo = @POCo AND vPOItemLine.PO = @PO AND vPOItemLine.POItem = @POItem AND vPOItemLine.POItemLine = @POItemLine
			END
			ELSE
			BEGIN
				--Customer work order
				INSERT dbo.SMWorkCompleted (SMCo, WorkOrder, [Type], WorkCompleted, Scope, [Date], Agreement, Revision, Coverage, ServiceSite, POCo, PO, POItem, POItemLine, Quantity, UM, CostRate, CostECM, ProjCost, PriceUM, PriceECM, PriceTotal, TaxType, TaxGroup, TaxCode, GLCo, CostAccount, CostWIPAccount, RevenueAccount, RevenueWIPAccount, NoCharge, Provisional)
				SELECT vSMWorkOrderScope.SMCo, vSMWorkOrderScope.WorkOrder, 5/*Purchase LineType*/, @WorkCompleted, vSMWorkOrderScope.Scope, vPOItemLine.PostedDate,
					vSMWorkOrderScope.Agreement, vSMWorkOrderScope.Revision, CASE WHEN vSMWorkOrderScope.PriceMethod = 'C' THEN 'C' WHEN vSMWorkOrderScope.PriceMethod = 'T' AND vSMWorkOrderScope.UseAgreementRates = 'Y' THEN 'A' ELSE NULL END,
					vSMWorkOrder.ServiceSite, vPOItemLine.POCo, vPOItemLine.PO, vPOItemLine.POItem, vPOItemLine.POItemLine,
					0 /*Quantity will be updated later*/, bPOIT.UM, bPOIT.CurUnitCost, bPOIT.CurECM, 0 /*ProjCost will be updated later*/,
					bPOIT.UM, bPOIT.CurECM, 0, /*PriceTotal will be updated later*/
					TaxDefaults.TaxType, vfSMGetDefaultTaxInfo.TaxGroup, TaxDefaults.TaxCode,
					vfSMGetAccountingTreatment.GLCo, vfSMGetAccountingTreatment.CostGLAcct, vfSMGetAccountingTreatment.CostWIPGLAcct, vfSMGetAccountingTreatment.RevenueGLAcct, vfSMGetAccountingTreatment.RevenueWIPGLAcct,
					'N' NoCharge, CASE WHEN vSMWorkOrderScope.CallType IS NULL OR (vSMWorkOrderScope.RateTemplate IS NULL AND vSMWorkOrderScope.PriceMethod <> 'C') THEN 1 ELSE 0 END
				FROM dbo.vPOItemLine
					INNER JOIN dbo.bPOIT ON vPOItemLine.POCo = bPOIT.POCo AND vPOItemLine.PO = bPOIT.PO AND vPOItemLine.POItem = bPOIT.POItem
					INNER JOIN dbo.vSMWorkOrderScope ON vPOItemLine.SMCo = vSMWorkOrderScope.SMCo AND vPOItemLine.SMWorkOrder = vSMWorkOrderScope.WorkOrder AND vPOItemLine.SMScope = vSMWorkOrderScope.Scope
					INNER JOIN dbo.vSMWorkOrder ON vPOItemLine.SMCo = vSMWorkOrder.SMCo AND vPOItemLine.SMWorkOrder = vSMWorkOrder.WorkOrder
					CROSS APPLY dbo.vfSMGetAccountingTreatment(vSMWorkOrderScope.SMCo, vSMWorkOrderScope.WorkOrder, vSMWorkOrderScope.Scope, 5/*Purchase LineType*/, NULL/*No Default CostType*/)
					CROSS APPLY dbo.vfSMGetDefaultTaxInfo(vSMWorkOrderScope.SMCo, vSMWorkOrderScope.WorkOrder, vSMWorkOrderScope.Scope)
					OUTER APPLY
					(
						--Taxes are defaulted and not changed since the cost type is currently not supplied in po so taxability
						--is currently only determined by whether the material is taxable and the material can never be changed on the PO item.
						SELECT vfSMGetDefaultTaxInfo.TaxCode, vfSMGetDefaultTaxInfo.TaxType
						WHERE EXISTS(SELECT * FROM dbo.bHQMT WHERE bPOIT.MatlGroup = bHQMT.MatlGroup AND bPOIT.Material = bHQMT.Material AND bHQMT.Taxable = 'Y')
					) TaxDefaults
				WHERE vPOItemLine.POCo = @POCo AND vPOItemLine.PO = @PO AND vPOItemLine.POItem = @POItem AND vPOItemLine.POItemLine = @POItemLine
			END
			
			UPDATE dbo.vPOItemLine
			SET SMWorkCompleted = @WorkCompleted
			WHERE POCo = @POCo AND PO = @PO AND POItem = @POItem AND POItemLine = @POItemLine
			
			COMMIT TRAN
		END

		--Update changes that come from updating the PO Item if anything has changed
		UPDATE dbo.SMWorkCompleted
		SET @MaterialChanged = ~(dbo.vfIsEqual(MatlGroup, @MatlGroup) & dbo.vfIsEqual(Part, @Material)),
			@Reprice = @MaterialChanged | ~(dbo.vfIsEqual(Quantity, @Quantity) & dbo.vfIsEqual(ProjCost, @ProjCost)),
			MatlGroup = @MatlGroup,
			Part = @Material,
			UM = @CostUM,
			Quantity = @Quantity,
			CostRate = @CostRate,
			CostECM = @CostECM,
			ProjCost = @ProjCost,
			PriceUM = CASE WHEN @MaterialChanged = 1 THEN @CostUM ELSE PriceUM END,
			PriceECM = CASE WHEN @MaterialChanged = 1 THEN @CostECM ELSE PriceECM END,
			JCCostType = @JCCostType
		WHERE SMCo = @SMCo AND WorkOrder = @WorkOrder AND WorkCompleted = @WorkCompleted

		IF @Reprice = 1
		BEGIN
			SELECT @SMInvoiceID = SMWorkCompleted.SMInvoiceID, @PriceRate = vfSMRatePurchase.PriceRate, @PriceTotal = vfSMRatePurchase.PriceTotal, @TaxGroup = SMWorkCompleted.TaxGroup, @TaxCode = SMWorkCompleted.TaxCode, @Date = SMWorkCompleted.[Date], @TaxType = SMWorkCompleted.TaxType
			FROM dbo.SMWorkCompleted
				CROSS APPLY dbo.vfSMRatePurchase(SMCo, WorkOrder, Scope, [Date], Agreement, Revision, Coverage, MatlGroup, Part, UM, Quantity, ProjCost, PriceUM, PriceECM)
			WHERE SMCo = @SMCo AND WorkOrder = @WorkOrder AND WorkCompleted = @WorkCompleted
	
			--As long as the work completed hasn't been invoiced then it can be re-priced
			IF @SMInvoiceID IS NULL
			BEGIN
				IF @TaxCode IS NOT NULL
				BEGIN
					EXEC @rcode = dbo.vspHQTaxCodeVal @taxgroup = @TaxGroup, @taxcode = @TaxCode, @compdate = @Date, @taxtype = @TaxType, @taxrate = @TaxRate OUTPUT, @msg = @msg OUTPUT
					IF @rcode <> 0 RETURN @rcode
				END

				UPDATE dbo.SMWorkCompleted
				SET PriceRate = @PriceRate,
					PriceTotal = @PriceTotal,
					TaxBasis = CASE WHEN @TaxCode IS NOT NULL THEN @PriceTotal END,
					TaxAmount = CASE WHEN @TaxCode IS NOT NULL THEN @PriceTotal * @TaxRate END
				WHERE SMCo = @SMCo AND WorkOrder = @WorkOrder AND WorkCompleted = @WorkCompleted
			END
			ELSE
			BEGIN
				--If the work completed has been invoiced then all pricing should be cleared execpt the price total
				--since the price total can't be changed as that would cause it to be out of sync with the invoice amount.
				UPDATE dbo.SMWorkCompleted
				SET PriceUM = NULL, PriceRate = NULL, PriceECM = NULL
				WHERE SMCo = @SMCo AND WorkOrder = @WorkOrder AND WorkCompleted = @WorkCompleted
			END
		END
	END

	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMWorkCompletedPurchaseUpdate] TO [public]
GO
