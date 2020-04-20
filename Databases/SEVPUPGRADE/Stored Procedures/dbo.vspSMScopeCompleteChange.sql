SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 7/25/11
-- Description:	Transfers money into and out of WIP
-- Modified:
-- =============================================

CREATE PROCEDURE [dbo].[vspSMScopeCompleteChange]
	@SMCo bCompany, @WorkOrder int, @Scope int, @WIPHasBeenTransferred bit, 
	@CurrentlyComplete bit, @BatchMonth bMonth, @IsTrackingWIP bYN = NULL OUTPUT, 
	@ClosestOpenMonth bMonth = NULL OUTPUT, @UseWIP bit = NULL OUTPUT, 
	@msg varchar(255) = NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    
    DECLARE @rcode int, @IsComplete bYN, @MissingCallType bit, @MissingRateTemplate bit, @MissingPhaseCode bit, @CostAsCost bit
    
    SELECT @IsComplete = SMWorkOrderScope.IsComplete, 
		@IsTrackingWIP = SMWorkOrderScope.IsTrackingWIP, 
		@UseWIP = CASE WHEN SMWorkOrderScope.IsComplete = 'Y' THEN 1 ELSE 0 END,
		@CostAsCost = CASE WHEN SMWorkOrder.CostingMethod = 'Cost' THEN 1 ELSE 0 END,
		@MissingCallType = dbo.vfEqualsNull(SMWorkOrderScope.CallType),
		@MissingRateTemplate = dbo.vfEqualsNull(SMWorkOrderScope.RateTemplate),
		@MissingPhaseCode = CASE WHEN SMWorkOrder.Job IS NULL THEN 0 ELSE dbo.vfEqualsNull(SMWorkOrderScope.Phase) END
    FROM dbo.SMWorkOrderScope
    INNER JOIN dbo.SMWorkOrder
		ON SMWorkOrderScope.SMCo = SMWorkOrder.SMCo AND SMWorkOrderScope.WorkOrder = SMWorkOrder.WorkOrder
    WHERE SMWorkOrderScope.SMCo = @SMCo AND SMWorkOrderScope.WorkOrder = @WorkOrder AND SMWorkOrderScope.Scope = @Scope
    
	IF(@IsComplete <> CASE @CurrentlyComplete WHEN 1 THEN 'Y' ELSE 'N' END)
	BEGIN
		SET @msg = 'Work Order: '+dbo.vfToString(@WorkOrder)+' Scope: '+dbo.vfToString(@Scope)+' is already '+CASE WHEN @CurrentlyComplete=1 THEN 'open' ELSE 'complete' END+'.'
		RETURN 1
	END
	-- Only looking for missing fields when making scope complete.
	IF(NOT @IsComplete='Y')
	BEGIN
		SELECT @msg = ''	
		IF @MissingCallType=1
			SELECT @msg = 'The Call Type '
		IF @MissingRateTemplate=1 AND @CostAsCost=0
			IF NOT @msg='' 
				SET @msg=@msg + 'and Rate Template '
			ELSE
				SET @msg = 'The Rate Template '
		IF @MissingPhaseCode=1
			IF NOT @msg='' 
				SET @msg=@msg + 'and Phase Code '
			ELSE
				SET @msg = 'The Phase Code '
		IF NOT @msg=''
			SET @msg=@msg + 'must be set.'
		ELSE IF EXISTS(SELECT 1 FROM SMWorkCompleted WHERE SMCo = @SMCo AND WorkOrder = @WorkOrder AND Scope = @Scope AND Provisional=1)
			SELECT @msg = 'Provisional Work Completed exists.'

		IF (NOT @msg = '')
		BEGIN
			SELECT @msg = 'Cannot complete this scope: ' + @msg
			RETURN 1
		END
	END
	
	IF @IsTrackingWIP = 'Y'
	BEGIN
		IF @WIPHasBeenTransferred = 0
		BEGIN
			DECLARE @GLCompaniesToFindOpenMonthFor TABLE (GLCo bCompany)
			
			INSERT @GLCompaniesToFindOpenMonthFor
			--GL Companies involved in cost WIP
			SELECT TransferringEntries.GLCo
			FROM dbo.vSMWorkCompletedDetail
				INNER JOIN dbo.vSMWorkCompletedGL ON vSMWorkCompletedDetail.SMWorkCompletedID = vSMWorkCompletedGL.SMWorkCompletedID
				CROSS APPLY dbo.vfSMGetWorkCompletedAccount(vSMWorkCompletedDetail.SMWorkCompletedID, 'C', @UseWIP) NewGL
				CROSS APPLY dbo.vfSMWorkCompletedBuildTransferringEntries(vSMWorkCompletedDetail.SMWorkCompletedID, 'C', NewGL.GLCo, NewGL.GLAccount, 1) TransferringEntries
			WHERE vSMWorkCompletedDetail.SMCo = @SMCo AND vSMWorkCompletedDetail.WorkOrder = @WorkOrder AND vSMWorkCompletedDetail.IsSession = 0 AND vSMWorkCompletedDetail.Scope = @Scope
			UNION
			SELECT GLCompanysInvolved.GLCo
			FROM dbo.vPOItemLine
				INNER JOIN dbo.vSMPOItemLine ON vPOItemLine.POCo = vSMPOItemLine.POCo AND vPOItemLine.PO = vSMPOItemLine.PO AND vPOItemLine.POItem = vSMPOItemLine.POItem AND vPOItemLine.POItemLine = vSMPOItemLine.POItemLine
				CROSS APPLY (
					SELECT vSMPOItemLine.GLCo, CASE WHEN @UseWIP = 1 THEN vSMPOItemLine.CostWIPAccount ELSE vSMPOItemLine.CostAccount END GLAccount) NewGL
				CROSS APPLY (
					SELECT vPOItemLine.GLCo
					WHERE vPOItemLine.GLCo <> NewGL.GLCo OR vPOItemLine.GLAcct <> NewGL.GLAccount
					UNION
					SELECT NewGL.GLCo
					WHERE vPOItemLine.GLCo <> NewGL.GLCo OR vPOItemLine.GLAcct <> NewGL.GLAccount
					UNION
					SELECT GLCo
					FROM dbo.vfAPTransactionBuildTransferringEntries(vPOItemLine.POCo, vPOItemLine.PO, vPOItemLine.POItem, vPOItemLine.POItemLine, NewGL.GLCo, NewGL.GLAccount, 1)
					UNION
					SELECT GLCo
					FROM dbo.vfPOReceiptBuildTransferringEntries(vPOItemLine.POCo, vPOItemLine.PO, vPOItemLine.POItem, vPOItemLine.POItemLine, NewGL.GLCo, NewGL.GLAccount, 1)) GLCompanysInvolved
			WHERE vPOItemLine.ItemType = 6 AND vPOItemLine.SMCo = @SMCo AND vPOItemLine.SMWorkOrder = @WorkOrder AND vPOItemLine.SMScope = @Scope
			UNION
			--GL Companies involved in revenue WIP
			SELECT TransferringEntries.GLCo
			FROM dbo.vSMWorkCompletedDetail
				INNER JOIN dbo.vSMWorkCompletedGL ON vSMWorkCompletedDetail.SMWorkCompletedID = vSMWorkCompletedGL.SMWorkCompletedID
				CROSS APPLY dbo.vfSMGetWorkCompletedAccount(vSMWorkCompletedDetail.SMWorkCompletedID, 'R', @UseWIP) NewGL
				CROSS APPLY dbo.vfSMWorkCompletedBuildTransferringEntries(vSMWorkCompletedDetail.SMWorkCompletedID, 'R', NewGL.GLCo, NewGL.GLAccount, 1) TransferringEntries
			WHERE vSMWorkCompletedDetail.SMCo = @SMCo AND vSMWorkCompletedDetail.WorkOrder = @WorkOrder AND vSMWorkCompletedDetail.IsSession = 0 AND vSMWorkCompletedDetail.Scope = @Scope
			
			--If we don't have any gl companies involved in transferring WIP then we don't need to worry
			--about doing any transferring WIP and we can go ahead and update the IsComplete flag.
			IF EXISTS(SELECT 1 FROM @GLCompaniesToFindOpenMonthFor)
			BEGIN
				SELECT @ClosestOpenMonth = CASE WHEN BeginMonth > EndMonth THEN NULL WHEN BeginMonth > @BatchMonth THEN BeginMonth WHEN EndMonth < @BatchMonth THEN EndMonth ELSE @BatchMonth END
				FROM (
					SELECT MAX(BeginMonth) BeginMonth, MIN(EndMonth) EndMonth
					FROM dbo.vfGLClosedMonths('SM WIP', NULL) GLClosedMonths
						INNER JOIN @GLCompaniesToFindOpenMonthFor GLCompaniesToFindOpenMonthFor ON GLClosedMonths.GLCo = GLCompaniesToFindOpenMonthFor.GLCo) OpenMonthRange
						
				RETURN 0 --Exit out if they are not tracking WIP since nothing needs to be moved.
			END
			
			--If this code is hit then we have no WIP to transfer even though they are tracking WIP
			SET @IsTrackingWIP = 'N'
		END
	END

	UPDATE dbo.SMWorkOrderScope
	SET IsComplete = CASE IsComplete WHEN 'Y' THEN 'N' ELSE 'Y' END
	WHERE SMCo = @SMCo AND WorkOrder = @WorkOrder AND Scope = @Scope
	
	RETURN 0
END



GO
GRANT EXECUTE ON  [dbo].[vspSMScopeCompleteChange] TO [public]
GO
