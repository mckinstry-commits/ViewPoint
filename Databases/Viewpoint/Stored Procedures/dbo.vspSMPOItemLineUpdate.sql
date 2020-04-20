SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jacob Van Houten
--
--
-- Create date: 9/27/2011
-- Description:	Updates the PO Item Line with the correct GL Company and Account prior to receiving
--              a SM Part.
--	Modify:		12/7/2011 JVH TK-19989 - Modified to allow for updating the purchase line's gl accounts when allowed.
-- =============================================
CREATE PROCEDURE [dbo].[vspSMPOItemLineUpdate]
	(@SMCo bCompany, @WorkOrder int, @WorkCompleted int, @CostType int,
		@GLCo bCompany, @CostAccount bGLAcct, @CostWIPAccount bGLAcct, @RevenueWIPAccount bGLAcct, @RevenueAccount bGLAcct,
   		@msg varchar(255) = NULL OUTPUT)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	--Grab the current values from the PO Item Line
	DECLARE @POCo bCompany, @PO varchar(30), @POItem bItem, @POItemLine int,
		@CurrentSMCo bCompany, @CurrentSMCostType int, @CurrentGLCo bCompany, @CurrentCostWIPAccount bGLAcct, @CurrentCostAccount bGLAcct, @CurrentRevenueWIPAccount bGLAcct, @CurrentRevenueAccount bGLAcct,
		@Scope int, @IsJobWorkOrder bit

	SELECT @POCo = POCo, @PO = PO, @POItem = POItem, @POItemLine = POItemLine,
		@CurrentSMCo = SMCo, @CurrentSMCostType = SMCostType, @CurrentGLCo = GLCo, @CurrentCostWIPAccount = CostWIPAccount, @CurrentCostAccount = CostAccount, @CurrentRevenueWIPAccount = RevenueWIPAccount, @CurrentRevenueAccount = RevenueAccount, @Scope = Scope
	FROM dbo.SMWorkCompleted
	WHERE SMCo = @SMCo AND WorkOrder = @WorkOrder AND WorkCompleted = @WorkCompleted
	
	SELECT @IsJobWorkOrder = CASE WHEN Job IS NULL THEN 0 ELSE 1 END
	FROM dbo.vSMWorkOrder
	WHERE SMCo = @SMCo AND WorkOrder = @WorkOrder
	
	--Do a comparison on the current values and the values we want to update to
	IF @POItemLine IS NOT NULL AND ~dbo.vfIsEqual(@CurrentSMCo, @SMCo) | ~dbo.vfIsEqual(@CurrentSMCostType, @CostType) | ~dbo.vfIsEqual(@CurrentGLCo, @GLCo) | ~dbo.vfIsEqual(@CurrentCostWIPAccount, @CostWIPAccount) | ~dbo.vfIsEqual(@CurrentCostAccount, @CostAccount) | (dbo.vfIsEqual(@IsJobWorkOrder, 1) & (~dbo.vfIsEqual(@CurrentRevenueWIPAccount, @RevenueWIPAccount) | ~dbo.vfIsEqual(@CurrentRevenueAccount, @RevenueAccount))) = 1
	BEGIN
		IF EXISTS(SELECT 1 FROM dbo.bPORB WHERE Co = @POCo AND PO = @PO AND POItem = @POItem AND POItemLine = @POItemLine)
			OR EXISTS(SELECT 1 FROM dbo.bAPTL WHERE APCo = @POCo AND PO = @PO AND POItem = @POItem AND POItemLine = @POItemLine)
		BEGIN
			--Return the given batch so we can try to post it and then retry to update the gl accounts
			SET @msg = 'Batches exist that need to be processed or canceled first.'
			RETURN 1
		END
		ELSE IF EXISTS(SELECT 1
			FROM dbo.vPOItemLine
			WHERE POCo = @POCo AND PO = @PO AND POItem = @POItem AND POItemLine = @POItemLine 
				AND NOT (InvUnits = 0 AND InvCost = 0))
		BEGIN
			--We don't allow updating if the PO Item Line has been invoiced against
			SET @msg = 'The PO Item Line has been invoiced in AP. To save the current record you must either delete the invoice or use the following values - Cost Type: ' + dbo.vfToString(@CurrentSMCostType) + ', Cost WIP Account: ' + dbo.vfToString(@CurrentCostWIPAccount) + ', Cost Account: ' + dbo.vfToString(@CurrentCostAccount)
			RETURN 1
		END
		ELSE IF EXISTS(SELECT 1
			FROM dbo.vPOItemLine
			WHERE POCo = @POCo AND PO = @PO AND POItem = @POItem AND POItemLine = @POItemLine 
				AND NOT (RecvdUnits = 0 AND RecvdCost = 0))
		BEGIN
			--We don't allow updating if the PO Item Line has been received against
			SET @msg = 'The PO Item Line has been received. To save the current record you must either delete the receipts or use the following values - Cost Type: ' + dbo.vfToString(@CurrentSMCostType) + ', Cost WIP Account: ' + dbo.vfToString(@CurrentCostWIPAccount) + ', Cost Account: ' + dbo.vfToString(@CurrentCostAccount)
			RETURN 1
		END
		--Once the purchase lines are changed to allow only 1 work completed to be tied to a PO Item Line this check will no longer be needed
		ELSE IF ~dbo.vfIsEqual(@CurrentSMCo, @SMCo) | ~dbo.vfIsEqual(@CurrentSMCostType, @CostType) | ~dbo.vfIsEqual(@CurrentGLCo, @GLCo) | ~dbo.vfIsEqual(@CurrentCostWIPAccount, @CostWIPAccount) | ~dbo.vfIsEqual(@CurrentCostAccount, @CostAccount) = 1
			AND EXISTS(SELECT 1
			FROM dbo.SMWorkCompleted
			WHERE NOT (SMCo = @SMCo AND WorkOrder = @WorkOrder AND WorkCompleted = @WorkCompleted) AND POCo = @POCo AND PONumber = @PO AND POItem = @POItem AND POItemLine = @POItemLine)
		BEGIN
			--If other work completed has been captured against the PO Item Line then the same cost type and gl accounts need to be used.
			SET @msg = 'Work Completed has been captured against this PO Item Line. Either delete the other work completed lines or save the current record with the following values - Cost Type: ' + dbo.vfToString(@CurrentSMCostType) + ', Cost WIP Account: ' + dbo.vfToString(@CurrentCostWIPAccount) + ', Cost Account: ' + dbo.vfToString(@CurrentCostAccount)
			RETURN 1
		END
		ELSE
		BEGIN
			DECLARE @UseWIP bit
			
			SET @UseWIP = CASE WHEN EXISTS(SELECT 1 FROM dbo.vSMWorkOrderScope WHERE SMCo = @SMCo AND WorkOrder = @WorkOrder AND Scope = @Scope AND IsTrackingWIP = 'Y' AND IsComplete = 'N') THEN 1 ELSE 0 END
			
			BEGIN TRY
				BEGIN TRAN
				
				IF @POItemLine = 1
				BEGIN
					--Allow the bPOIT update trigger update the vPOItemLine
					UPDATE dbo.bPOIT
					SET GLCo = @GLCo, GLAcct = CASE WHEN @UseWIP = 1 THEN @CostWIPAccount ELSE @CostAccount END
					WHERE POCo = @POCo AND PO = @PO AND POItem = @POItem
				END
				ELSE
				BEGIN
					UPDATE dbo.vPOItemLine
					SET GLCo = @GLCo, GLAcct = CASE WHEN @UseWIP = 1 THEN @CostWIPAccount ELSE @CostAccount END
					WHERE POCo = @POCo AND PO = @PO AND POItem = @POItem AND POItemLine = @POItemLine
				END
				
				--Once the purchase lines are changed to allow only 1 work completed to be tied to a PO Item Line vSMPOItemLine will no longer be needed.
				UPDATE dbo.vSMPOItemLine
				SET SMCo = @SMCo, SMCostType = @CostType, GLCo = @GLCo, CostWIPAccount = @CostWIPAccount, CostAccount = @CostAccount
				WHERE POCo = @POCo AND PO = @PO AND POItem = @POItem AND POItemLine = @POItemLine
				
				COMMIT TRAN
			END TRY
			BEGIN CATCH
				ROLLBACK TRAN
				SET @msg = ERROR_MESSAGE()
				RETURN 1
			END CATCH
		END
	END

	RETURN 0
END


GO
GRANT EXECUTE ON  [dbo].[vspSMPOItemLineUpdate] TO [public]
GO
