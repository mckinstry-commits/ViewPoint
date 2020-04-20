SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  procedure [dbo].[vspSMWorkCompletedAPUpdate]
/******************************************************
* CREATED BY:	EricV  
* MODIFIED By:	TRL 04/20/2012 TK-14136 added code to created JCCD distributions
*				TRL 04/30/2012 TK-14135 added code to updated deleted SM Work Completed Distributions
*				TRL 05/25/2012 TK-15053 added @JCTransType Parameter for vspSMJobCostDistributionInsert/ removed @JCTransType Parameter for vspSMJobCostDetailInsert
				JB	07/12/2012 TK-16361 Fixed divide by 0 errors.
				MB  01/18/2013 TK-20840 Fixed issue with Billable Rate being Null after posting from AP Transaction Entry
* Usage:
*	
*
* Input params:
*	@poco
*	@mth
*	@batchid
*	@po
*	@poitem
*	@poitemline
*	
*
* Output params:
*	@errmsg		Code description or error message
*
* Return code:
*	0 = success, 1 = failure
*******************************************************/
   
   	(@poco bCompany, @mth bMonth, @batchid int, @po varchar(30), @poitem smallint, @poitemline int, @errmsg varchar(255) OUTPUT)
   	
	AS 
	SET NOCOUNT ON
	
	DECLARE @rcode int, @SMWorkCompletedID bigint, @GrossAmount bDollar, @TaxBasis bDollar, @TaxAmount bDollar,
	@IsJobWorkOrder bit, @JobCostingMethod varchar(10), @JCInterfaceFlag char(1)
		
	SELECT @IsJobWorkOrder = CASE WHEN vSMWorkOrder.Job IS NULL THEN 0 ELSE 1 END, @JobCostingMethod = vSMWorkOrder.CostingMethod, @JCInterfaceFlag = vSMCO.UseJCInterface 
	FROM dbo.vPOItemLine
		INNER JOIN dbo.vSMCO ON vPOItemLine.SMCo = vSMCO.SMCo
		INNER JOIN dbo.vSMWorkOrder ON vPOItemLine.SMCo = vSMWorkOrder.SMCo AND vPOItemLine.SMWorkOrder = vSMWorkOrder.WorkOrder
	WHERE vPOItemLine.POCo = @poco AND vPOItemLine.PO = @po AND vPOItemLine.POItem = @poitem AND vPOItemLine.POItemLine = @poitemline

	DECLARE @AssociatedWork TABLE
	(
		SMWorkCompletedID bigint,
		ActualUnits bUnits,
		UnitsToDistribute bUnits,
		ActualCost bDollar,
		ActualCostToDistribute bDollar,
		GrossAmount bDollar,
		GrossAmountToDistribute bDollar,
		TaxBasis bDollar,
		TaxBasisToDistribute bDollar,
		TaxAmount bDollar,
		TaxAmountToDistribute bDollar
	)
	
	-- Build a list of all existing SM Work Completed lines that are linked to the vPOItemLineineItem and the Old and New Acutal Costs
	INSERT @AssociatedWork (SMWorkCompletedID, ActualUnits, UnitsToDistribute, ActualCost, ActualCostToDistribute, GrossAmount, GrossAmountToDistribute, TaxBasis, TaxBasisToDistribute, TaxAmount, TaxAmountToDistribute)
	SELECT SMWorkCompleted.SMWorkCompletedID, 
		vPOItemLine.InvUnits * ISNULL(Totals.PercentOfWorkCompletedQuantity, 0) ActualUnits,
		
		vPOItemLine.InvUnits,
		
		--If PO is not LS then units are used to figure out what percent of the actual cost is applied,
		--otherwise the projected cost is used.
		vSMPOItemLine.InvTotalCost * COALESCE(Totals.PercentOfWorkCompletedQuantity, Totals.PercentOfWorkCompletedProjCost, 0) ActualCost,
			 
		vSMPOItemLine.InvTotalCost,
		
		--If PO is not LS then units are used to figure out what percent of the gross amount is applied,
		--otherwise the projected cost is used.
		vPOItemLine.InvCost * COALESCE(Totals.PercentOfWorkCompletedQuantity, Totals.PercentOfWorkCompletedProjCost, 0) GrossAmount,
		
		vPOItemLine.InvCost,
		
		--If PO is not LS then units are used to figure out what percent of the actual cost is applied,
		--otherwise the projected cost is used.
		vSMPOItemLine.InvTaxBasis * COALESCE(Totals.PercentOfWorkCompletedQuantity, Totals.PercentOfWorkCompletedProjCost, 0) TaxBasis,
		
		vSMPOItemLine.InvTaxBasis,
		
		--If PO is not LS then units are used to figure out what percent of the actual cost is applied,
		--otherwise the projected cost is used.
		vSMPOItemLine.InvDirectExpenseTax * COALESCE(Totals.PercentOfWorkCompletedQuantity, Totals.PercentOfWorkCompletedProjCost, 0) TaxAmount,
		
		vSMPOItemLine.InvDirectExpenseTax
	FROM dbo.SMWorkCompleted
		INNER JOIN dbo.vPOItemLine ON SMWorkCompleted.POCo = vPOItemLine.POCo AND SMWorkCompleted.PONumber = vPOItemLine.PO AND SMWorkCompleted.POItem = vPOItemLine.POItem AND SMWorkCompleted.POItemLine = vPOItemLine.POItemLine
		INNER JOIN dbo.vSMPOItemLine ON vPOItemLine.POCo = vSMPOItemLine.POCo AND vPOItemLine.PO = vSMPOItemLine.PO AND vPOItemLine.POItem = vSMPOItemLine.POItem AND vPOItemLine.POItemLine = vSMPOItemLine.POItemLine
	CROSS APPLY (SELECT SUM(Quantity) Quantity, SUM(ProjCost) ProjCost 
				FROM SMWorkCompleted WHERE Type = 5 AND POCo = vPOItemLine.POCo AND PONumber = vPOItemLine.PO AND POItem = vPOItemLine.POItem AND POItemLine = vPOItemLine.POItemLine) SMWorkCompletedTotal
	CROSS APPLY
	(
		SELECT 
			CASE WHEN SMWorkCompletedTotal.Quantity <> 0 THEN SMWorkCompleted.Quantity / SMWorkCompletedTotal.Quantity END PercentOfWorkCompletedQuantity,
			CASE WHEN SMWorkCompletedTotal.ProjCost <> 0 THEN SMWorkCompleted.ProjCost / SMWorkCompletedTotal.ProjCost END PercentOfWorkCompletedProjCost
	) Totals
	WHERE SMWorkCompleted.POCo = @poco AND
		SMWorkCompleted.PONumber = @po AND
		SMWorkCompleted.POItem = @poitem AND
		SMWorkCompleted.POItemLine = @poitemline

	--Check for rounding issues.
	;WITH HandleRoundingCTE
	AS
	(
		SELECT *,
			SUM(ActualUnits) OVER (PARTITION BY NULL) ActualUnitsTotal,
			SUM(ActualCost) OVER (PARTITION BY NULL) ActualCostTotal,
			SUM(GrossAmount) OVER (PARTITION BY NULL) GrossAmountTotal,
			SUM(TaxBasis) OVER (PARTITION BY NULL) TaxBasisTotal,
			SUM(TaxAmount) OVER (PARTITION BY NULL) TaxAmountTotal
		FROM @AssociatedWork
	)
	UPDATE TOP (1) HandleRoundingCTE
	SET 
		ActualUnits = ActualUnits + UnitsToDistribute - ActualUnitsTotal,
		ActualCost = ActualCost + ActualCostToDistribute - ActualCostTotal,
		GrossAmount = GrossAmount + GrossAmountToDistribute - GrossAmountTotal,
		TaxBasis = TaxBasis + TaxBasisToDistribute - TaxBasisTotal,
		TaxAmount = TaxAmount + TaxAmountToDistribute - TaxAmountTotal

	BEGIN TRY
		BEGIN TRAN
	
		UPDATE vSMWorkCompletedPurchase
		SET ActualUnits = AssociatedWork.ActualUnits, ActualCost = AssociatedWork.ActualCost
		FROM dbo.vSMWorkCompletedPurchase
			INNER JOIN @AssociatedWork AssociatedWork ON vSMWorkCompletedPurchase.SMWorkCompletedID = AssociatedWork.SMWorkCompletedID


		--Updated to use Cost Quanitity instead of price Quantity because price Quantity is always null for job actual cost at this point
		--and the cost quantity cannot be changed to a different UM at this point for the job work order.
		IF @IsJobWorkOrder = 1
		BEGIN
			IF @JobCostingMethod = 'Cost'
			BEGIN
				UPDATE SMWorkCompleted
				SET PriceTotal = ActualCost, PriceRate = CASE WHEN Quantity = 0 THEN 0 ELSE ActualCost / Quantity END
				FROM dbo.SMWorkCompleted
				WHERE SMWorkCompletedID IN (SELECT SMWorkCompletedID FROM @AssociatedWork)
			END

			IF @JCInterfaceFlag='Y'
			BEGIN
				WHILE EXISTS(SELECT 1 FROM @AssociatedWork)
				BEGIN
					SELECT TOP 1 @SMWorkCompletedID = SMWorkCompletedID, @GrossAmount = GrossAmount, @TaxBasis = TaxBasis, @TaxAmount = TaxAmount
					FROM @AssociatedWork
				
					/*START SM JOB COST DISTRIBUTIONS*/
					EXEC @rcode = dbo.vspSMJobCostPurchaseDistribution @SMWorkCompletedID = @SMWorkCompletedID, @BatchCo = @poco, @BatchMth = @mth, @BatchId = @batchid, @GrossAmount = @GrossAmount, @TaxBasis = @TaxBasis, @TaxAmount = @TaxAmount, @msg = @errmsg OUTPUT
					IF @rcode <> 0 
					BEGIN
						SET @errmsg =  @errmsg + ' - Unable to update Job Cost Distribution.'
						RETURN @rcode
					END
					/*END SM JOB COST DISTRIBUTIONS*/
					
					DELETE @AssociatedWork
					WHERE SMWorkCompletedID = @SMWorkCompletedID
				END
			END
		END
		
		COMMIT TRAN
	END TRY
	BEGIN CATCH
		--If the error is due to a transaction count mismatch in vspSMJobCostDistributionInsert
		--then it is more helpful to keep the error message from vspSMJobCostDistributionInsert.
		IF ERROR_NUMBER() <> 266 SET @errmsg = ERROR_MESSAGE()
		IF @@TRANCOUNT > 0 ROLLBACK TRAN

		RETURN 1
	END CATCH

	RETURN 0
GO
GRANT EXECUTE ON  [dbo].[vspSMWorkCompletedAPUpdate] TO [public]
GO
