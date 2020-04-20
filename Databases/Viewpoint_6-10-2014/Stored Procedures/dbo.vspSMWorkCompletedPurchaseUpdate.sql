SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspSMWorkCompletedPurchaseUpdate] 
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 11/12/12
-- Description:	Adds/Updates/Deletes the work completed purchase line from the PO 
-- Modification: 3/29/13 JVH - TFS-44846 - Updated to handle deriving sm gl accounts
--				 4/29/13  JVH TFS-44860 Updated check to see if work completed is part of an invoice
--               05/21/13 EricV - TFS-50951 - Check for PriceMethod value of 'N' instead of 'C'
--				 05/31/13 EricV  TFS-4171 Replaced Work Completed Coverage field with NonBillable and UseAgreementRates fields.
--				 6/9/13 JVH TFS-54796 Fixed when to reprice for non-billable work completed records.
-- =============================================
	@POCo bCompany, @PO varchar(30), @POItem bItem, @POItemLine int, @OldSMCo bCompany, @OldWorkOrder int, @OldScope int, @OldWorkCompleted int, @Quantity bUnits = NULL, @ProjCost bDollar = NULL, @msg varchar(255) = NULL OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @rcode int,
		@MatlGroup bGroup, @Material bMatl, @CostUM bUM, @CostRate bUnitCost, @CostECM bECM, @POITDescription bItemDesc,
		@DeleteWorkCompleted bit, @UpdateWorkCompleted bit,
		@SMCo bCompany, @WorkOrder int, @Scope int, @WorkCompleted int, @Provisional bit,
		@JCCostType bJCCType,
		@IsJobWorkOrder bit, @JobCostingMethod varchar(10),
		@MaterialChanged bit, @Reprice bit,
		@TaxGroup bGroup, @TaxCode bTaxCode, @Date bDate, @TaxType tinyint, @TaxRate bRate,
		@PriceRate bUnitCost, @PriceTotal bDollar, @WOStatus tinyint, @ScopePriceMethod char(1)

	SELECT @MatlGroup = MatlGroup, @Material = Material, @CostUM = UM, @CostRate = CurUnitCost, @CostECM = CurECM, @POITDescription = [Description]
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
	
	EXEC dbo.vspSMWorkCompletedScopeVal @SMCo=@SMCo, @WorkOrder=@WorkOrder, @Scope = @Scope, @LineType = 5, @AllowProvisional='Y', @Provisional=@Provisional OUTPUT, @ScopePriceMethod=@ScopePriceMethod OUTPUT, @msg = @msg OUTPUT

	--The SMPOItemLine table was used to prevent multiple work completed for the same PO Item Line from having different
	--cost accounts. The code no longer allows for multiple work completed for the same PO Item Line, but until the existing
	--records are consolidated and AP is updated to use the work completed instead of SMPOItemLine to keep track of invoiced amounts
	--for job work orders the SMPOItemLine is still needed.
	IF EXISTS(SELECT 1 FROM dbo.vSMPOItemLine WHERE POCo = @POCo AND PO = @PO AND POItem = @POItem AND POItemLine = @POItemLine)
	BEGIN
		--When the PO Item Line's type changes to something other than 6 then the SMPOItemLine can be dropped.
		IF @UpdateWorkCompleted = 0
		BEGIN
			DELETE dbo.vSMPOItemLine
			WHERE POCo = @POCo AND PO = @PO AND POItem = @POItem AND POItemLine = @POItemLine
		END
		ELSE
		BEGIN
			IF @DeleteWorkCompleted = 1
			BEGIN
				--If something like the scope changes then the work completed is deleted and recreated and therefore the SMPOItemLine needs
				--to be updated with the values the work completed will have.
				UPDATE vSMPOItemLine
				SET GLCo = vfSMGetAccountingTreatment.GLCo, CostWIPAccount = vfSMGetAccountingTreatment.CostWIPGLAcct, CostAccount = vfSMGetAccountingTreatment.CostGLAcct,
					SMCostType = NULL
				FROM dbo.vSMPOItemLine
					CROSS APPLY dbo.vfSMGetAccountingTreatment(@SMCo, @WorkOrder, @Scope, 'M', NULL)
				WHERE vSMPOItemLine.POCo = @POCo AND vSMPOItemLine.PO = @PO AND vSMPOItemLine.POItem = @POItem AND vSMPOItemLine.POItemLine = @POItemLine
			END
		END
	END
	ELSE
	BEGIN
		IF @UpdateWorkCompleted = 1
		BEGIN
			--The SMPOItemLine needs to exist when the PO Item Line has an ItemType of SM
			INSERT dbo.vSMPOItemLine (POCo, PO, POItem, POItemLine, SMCo, GLCo, CostWIPAccount, CostAccount)
			SELECT @POCo, @PO, @POItem, @POItemLine, @SMCo, GLCo, CostWIPGLAcct, CostGLAcct
			FROM dbo.vfSMGetAccountingTreatment(@SMCo, @WorkOrder, @Scope, 'M', NULL)
		END
	END

	SELECT @IsJobWorkOrder = CASE WHEN Job IS NOT NULL THEN 1 ELSE 0 END,
		@JobCostingMethod = CASE WHEN @IsJobWorkOrder = 1 THEN CostingMethod END,
		@WOStatus = WOStatus
	FROM dbo.vSMWorkOrder
	WHERE SMCo = @SMCo AND WorkOrder = @WorkOrder

	IF @DeleteWorkCompleted = 1
	BEGIN
		--If the work completed is part of an invoice that needs to be processed prevent the changes.
		IF EXISTS
		(
			SELECT 1
			FROM dbo.vSMWorkCompletedDetail
				INNER JOIN dbo.vSMInvoiceDetail ON vSMWorkCompletedDetail.SMCo = vSMInvoiceDetail.SMCo AND vSMWorkCompletedDetail.WorkOrder = vSMInvoiceDetail.WorkOrder AND vSMWorkCompletedDetail.WorkCompleted = vSMInvoiceDetail.WorkCompleted
				INNER JOIN dbo.vSMInvoice ON vSMInvoiceDetail.SMCo = vSMInvoice.SMCo AND vSMInvoiceDetail.Invoice = vSMInvoice.Invoice
				INNER JOIN dbo.vSMInvoiceSession ON vSMInvoice.SMInvoiceID = vSMInvoiceSession.SMInvoiceID
			WHERE (vSMWorkCompletedDetail.SMCo = @OldSMCo AND vSMWorkCompletedDetail.WorkOrder = @OldWorkOrder AND vSMWorkCompletedDetail.WorkCompleted = @OldWorkCompleted) OR
				vSMWorkCompletedDetail.SMWorkCompletedID IN (SELECT SMWorkCompletedID FROM dbo.vSMWorkCompletedPurchase WHERE POCo = @POCo AND PO = @PO AND POItem = @POItem AND POItemLine = @POItemLine) --Once there can only be 1 work completed line per PO Distribution this check will not be needed
		)
		BEGIN
			SET @msg = 'A customer invoice for work order: SMCo ' + dbo.vfToString(@OldSMCo) + ' - WorkOrder ' + dbo.vfToString(@OldWorkOrder) + ' needs to be processed in order for the po distribution to be modified.'
			RETURN 1
		END

		--Clear costs for the work completed if it still part of an invoice
		UPDATE dbo.SMWorkCompleted
		--Keep the cost UM and quantity so if they want to code it to an AP line later they can
		SET CostRate = NULL, CostECM = NULL, ProjCost = NULL, ActualUnits = NULL, ActualCost = NULL, POCo = NULL, PO = NULL, POItem = NULL, POItemLine = NULL, PriceUM  = NULL, PriceRate  = NULL, PriceECM  = NULL,
			-- Copy PO Item material and description to not lose this information
			MatlGroup = @MatlGroup, Part = @Material, [Description] = @POITDescription
		WHERE
			(
				(SMCo = @OldSMCo AND WorkOrder = @OldWorkOrder AND WorkCompleted = @OldWorkCompleted) OR
				SMWorkCompleted.SMWorkCompletedID IN (SELECT SMWorkCompletedID FROM dbo.vSMWorkCompletedPurchase WHERE POCo = @POCo AND PO = @PO AND POItem = @POItem AND POItemLine = @POItemLine) --Once there can only be 1 work completed line per PO Distribution this check will not be needed
			) AND 
			EXISTS
			(
				SELECT 1
				FROM dbo.vSMInvoiceDetail
				WHERE SMWorkCompleted.SMCo = vSMInvoiceDetail.SMCo AND SMWorkCompleted.WorkOrder = vSMInvoiceDetail.WorkOrder AND SMWorkCompleted.WorkCompleted = vSMInvoiceDetail.WorkCompleted
			)

		--Delete work completed as long as it is not part of an invoice
		DELETE dbo.vSMWorkCompleted
		WHERE
			(
				(SMCo = @OldSMCo AND WorkOrder = @OldWorkOrder AND WorkCompleted = @OldWorkCompleted) OR
				vSMWorkCompleted.SMWorkCompletedID IN (SELECT SMWorkCompletedID FROM dbo.vSMWorkCompletedPurchase WHERE POCo = @POCo AND PO = @PO AND POItem = @POItem AND POItemLine = @POItemLine) --Once there can only be 1 work completed line per PO Distribution this check will not be needed
			) AND 
			NOT EXISTS
			(
				SELECT 1
				FROM dbo.vSMInvoiceDetail
				WHERE vSMWorkCompleted.SMCo = vSMInvoiceDetail.SMCo AND vSMWorkCompleted.WorkOrder = vSMInvoiceDetail.WorkOrder AND vSMWorkCompleted.WorkCompleted = vSMInvoiceDetail.WorkCompleted
			)

		SET @WorkCompleted = NULL
	END

	--TEMPORARY CODE USED UNTIL PURCHASE WORK COMPLETED IS CONSOLIDATED TO HAVE ONLY 1 WORK COMPLETED PER PO ITEM LINE
	IF EXISTS
	(
		SELECT 1
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
					CROSS APPLY dbo.vfSMGetAccountingTreatment(vPOItemLine.SMCo, vPOItemLine.SMWorkOrder, vPOItemLine.SMScope, 'M', NULL)
				WHERE vPOItemLine.POCo = @POCo AND vPOItemLine.PO = @PO AND vPOItemLine.POItem = @POItem AND vPOItemLine.POItemLine = @POItemLine AND (vPOItemLine.GLCo <> vfSMGetAccountingTreatment.GLCo OR vPOItemLine.GLAcct <> vfSMGetAccountingTreatment.CurrentCostGLAcct))
			BEGIN
				SET @msg = 'The gl account assigned to the line doesn''t match the account that will be given the work completed line. Clear the scope field and re-enter the scope to default the correct account.'
				RETURN 1
			END
			
			IF (@WOStatus <> 0)
			BEGIN
				SET @msg = 'The Work Order is closed.'
				RETURN 1
			END
			
			--Use tran so that nothing else gets the same WorkCompleted value
			BEGIN TRAN

			SELECT @WorkCompleted = dbo.vfSMGetNextWorkCompletedSeq(@SMCo, @WorkOrder)

			--Insert based on whether it is a customer or job work order
			IF @IsJobWorkOrder = 1
			BEGIN
				--Job work order
				INSERT dbo.SMWorkCompleted (SMCo, WorkOrder, [Type], WorkCompleted, Scope, [Date], NonBillable, ServiceSite, PhaseGroup, POCo, PO, POItem, POItemLine, Quantity, UM, CostRate, CostECM, ProjCost, PriceUM, PriceECM, PriceTotal, GLCo, CostAccount, CostWIPAccount, RevenueAccount, RevenueWIPAccount, NoCharge, Provisional)
				SELECT vSMWorkOrderScope.SMCo, vSMWorkOrderScope.WorkOrder, 5/*Purchase LineType*/, @WorkCompleted, vSMWorkOrderScope.Scope, vPOItemLine.PostedDate, 'N' NonBillable,
					vSMWorkOrder.ServiceSite, vPOItemLine.SMPhaseGroup, vPOItemLine.POCo, vPOItemLine.PO, vPOItemLine.POItem, vPOItemLine.POItemLine,
					0 /*Quantity will be updated later*/, bPOIT.UM, bPOIT.CurUnitCost, bPOIT.CurECM, 0 /*ProjCost will be updated later*/,
					bPOIT.UM, bPOIT.CurECM, 0, /*PriceTotal will be updated later*/
					vfSMGetAccountingTreatment.GLCo, vfSMGetAccountingTreatment.CostGLAcct, vfSMGetAccountingTreatment.CostWIPGLAcct, vfSMGetAccountingTreatment.RevenueGLAcct, vfSMGetAccountingTreatment.RevenueWIPGLAcct,
					'N' NoCharge, @Provisional
				FROM dbo.vPOItemLine
					INNER JOIN dbo.bPOIT ON vPOItemLine.POCo = bPOIT.POCo AND vPOItemLine.PO = bPOIT.PO AND vPOItemLine.POItem = bPOIT.POItem
					INNER JOIN dbo.vSMWorkOrderScope ON vPOItemLine.SMCo = vSMWorkOrderScope.SMCo AND vPOItemLine.SMWorkOrder = vSMWorkOrderScope.WorkOrder AND vPOItemLine.SMScope = vSMWorkOrderScope.Scope
					INNER JOIN dbo.vSMWorkOrder ON vPOItemLine.SMCo = vSMWorkOrder.SMCo AND vPOItemLine.SMWorkOrder = vSMWorkOrder.WorkOrder
					CROSS APPLY dbo.vfSMGetAccountingTreatment(vSMWorkOrderScope.SMCo, vSMWorkOrderScope.WorkOrder, vSMWorkOrderScope.Scope, 'M', NULL/*No Default CostType*/)
				WHERE vPOItemLine.POCo = @POCo AND vPOItemLine.PO = @PO AND vPOItemLine.POItem = @POItem AND vPOItemLine.POItemLine = @POItemLine
			END
			ELSE
			BEGIN
				--Customer work order
				INSERT dbo.SMWorkCompleted (SMCo, WorkOrder, [Type], WorkCompleted, Scope, [Date], Agreement, Revision, NonBillable, UseAgreementRates, ServiceSite, POCo, PO, POItem, POItemLine, Quantity, UM, CostRate, CostECM, ProjCost, TaxType, TaxGroup, TaxCode, GLCo, CostAccount, CostWIPAccount, RevenueAccount, RevenueWIPAccount, NoCharge, Provisional)
				SELECT vSMWorkOrderScope.SMCo, vSMWorkOrderScope.WorkOrder, 5/*Purchase LineType*/, @WorkCompleted, vSMWorkOrderScope.Scope, vPOItemLine.PostedDate,
					vSMWorkOrderScope.Agreement, vSMWorkOrderScope.Revision,
					CASE WHEN vSMWorkOrderScope.PriceMethod = 'T' THEN 'N' ELSE 'Y' END NonBillable,
					vSMWorkOrderScope.UseAgreementRates,
					vSMWorkOrder.ServiceSite, vPOItemLine.POCo, vPOItemLine.PO, vPOItemLine.POItem, vPOItemLine.POItemLine,
					0 /*Quantity will be updated later*/, bPOIT.UM, bPOIT.CurUnitCost, bPOIT.CurECM, 0 /*ProjCost will be updated later*/,
					TaxDefaults.TaxType, vfSMGetDefaultTaxInfo.TaxGroup, TaxDefaults.TaxCode,
					vfSMGetAccountingTreatment.GLCo, vfSMGetAccountingTreatment.CostGLAcct, vfSMGetAccountingTreatment.CostWIPGLAcct, vfSMGetAccountingTreatment.RevenueGLAcct, vfSMGetAccountingTreatment.RevenueWIPGLAcct,
					'N' NoCharge, @Provisional
				FROM dbo.vPOItemLine
					INNER JOIN dbo.bPOIT ON vPOItemLine.POCo = bPOIT.POCo AND vPOItemLine.PO = bPOIT.PO AND vPOItemLine.POItem = bPOIT.POItem
					INNER JOIN dbo.vSMWorkOrderScope ON vPOItemLine.SMCo = vSMWorkOrderScope.SMCo AND vPOItemLine.SMWorkOrder = vSMWorkOrderScope.WorkOrder AND vPOItemLine.SMScope = vSMWorkOrderScope.Scope
					INNER JOIN dbo.vSMWorkOrder ON vPOItemLine.SMCo = vSMWorkOrder.SMCo AND vPOItemLine.SMWorkOrder = vSMWorkOrder.WorkOrder
					CROSS APPLY dbo.vfSMGetAccountingTreatment(vSMWorkOrderScope.SMCo, vSMWorkOrderScope.WorkOrder, vSMWorkOrderScope.Scope, 'M', NULL/*No Default CostType*/)
					CROSS APPLY dbo.vfSMGetDefaultTaxInfo(vSMWorkOrderScope.SMCo, vSMWorkOrderScope.WorkOrder, vSMWorkOrderScope.Scope)
					OUTER APPLY
					(
						--Taxes are defaulted and not changed since the cost type is currently not supplied in po so taxability
						--is currently only determined by whether the material is taxable and the material can never be changed on the PO item.
						SELECT vfSMGetDefaultTaxInfo.TaxCode, vfSMGetDefaultTaxInfo.TaxType
						WHERE vSMWorkOrderScope.PriceMethod = 'T' AND EXISTS(SELECT * FROM dbo.bHQMT WHERE bPOIT.MatlGroup = bHQMT.MatlGroup AND bPOIT.Material = bHQMT.Material AND bHQMT.Taxable = 'Y')
					) TaxDefaults
				WHERE vPOItemLine.POCo = @POCo AND vPOItemLine.PO = @PO AND vPOItemLine.POItem = @POItem AND vPOItemLine.POItemLine = @POItemLine
			END
			
			UPDATE dbo.vPOItemLine
			SET SMWorkCompleted = @WorkCompleted
			WHERE POCo = @POCo AND PO = @PO AND POItem = @POItem AND POItemLine = @POItemLine
			
			COMMIT TRAN
		END

		--To determine if the material changed the purchase table needs to be checked because the SMWorkCompleted's view outputs
		--the POIT's material, which will always match itself.
		SELECT @MaterialChanged = ~(dbo.vfIsEqual(MatlGroup, @MatlGroup) & dbo.vfIsEqual(Part, @Material))
		FROM dbo.SMWorkCompletedPurchase
		WHERE SMCo = @SMCo AND WorkOrder = @WorkOrder AND WorkCompleted = @WorkCompleted AND IsSession = 0

		--Update changes that come from updating the PO Item if anything has changed
		UPDATE dbo.SMWorkCompleted
		SET @Reprice = dbo.vfIsEqual(SMWorkCompleted.NonBillable, 'N') & (@MaterialChanged | ~(dbo.vfIsEqual(Quantity, @Quantity) & dbo.vfIsEqual(ProjCost, @ProjCost))),
			MatlGroup = @MatlGroup,
			Part = @Material,
			UM = @CostUM,
			Quantity = @Quantity,
			CostRate = @CostRate,
			CostECM = @CostECM,
			ProjCost = @ProjCost,
			PriceUM = CASE WHEN SMWorkCompleted.NonBillable = 'N' AND (@MaterialChanged = 1 OR PriceUM IS NULL) THEN @CostUM ELSE PriceUM END,
			PriceECM = CASE WHEN SMWorkCompleted.NonBillable = 'N' AND (@MaterialChanged = 1 OR PriceECM IS NULL) THEN @CostECM ELSE PriceECM END,
			JCCostType = @JCCostType
		WHERE SMCo = @SMCo AND WorkOrder = @WorkOrder AND WorkCompleted = @WorkCompleted

		IF @Reprice = 1
		BEGIN
			SELECT @PriceRate = vfSMRatePurchase.PriceRate, @PriceTotal = vfSMRatePurchase.PriceTotal, @TaxGroup = SMWorkCompleted.TaxGroup, @TaxCode = SMWorkCompleted.TaxCode, @Date = SMWorkCompleted.[Date], @TaxType = SMWorkCompleted.TaxType
			FROM dbo.SMWorkCompleted
				CROSS APPLY dbo.vfSMRatePurchase(SMCo, WorkOrder, Scope, [Date], Agreement, Revision, NonBillable, UseAgreementRates, MatlGroup, Part, UM, Quantity, ProjCost, PriceUM, PriceECM)
			WHERE SMWorkCompleted.SMCo = @SMCo AND SMWorkCompleted.WorkOrder = @WorkOrder AND WorkCompleted = @WorkCompleted
	
			--As long as the work completed hasn't been invoiced then it can be re-priced
			IF NOT EXISTS
			(
				SELECT 1
				FROM dbo.SMInvoiceDetail
				WHERE SMCo = @SMCo AND WorkOrder = @WorkOrder AND WorkCompleted = @WorkCompleted
			)
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
