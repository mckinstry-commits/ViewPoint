
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 7/25/11
-- Description:	Transfers money into and out of WIP
-- Modified:	JVH 5/28/13 - TFS-44858	Modified to support SM Flat Price Billing
--				6/24/13 JVH - TFS-53341	Modified to support SM Flat Price Billing
-- =============================================

CREATE PROCEDURE [dbo].[vspSMWIPTransferValidate]
	@SMCo bCompany, @BatchMonth bMonth, @BatchId bBatchID, @Source bSource, @msg varchar(255) = NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    
    DECLARE @rcode int, @GLDetlDesc bTransDesc, @TransDesc varchar(max),
		@ActualDate bDate, @HQBatchDistributionID bigint

	--Verify that the batch can be validated, set the batch status to validating and delete generic distributions
	EXEC @rcode = dbo.vspHQBatchValidating @BatchCo = @SMCo, @BatchMth = @BatchMonth, @BatchId = @BatchId, @Source = @Source, @TableName = 'SMWIPTransferBatch', @HQBatchDistributionID = @HQBatchDistributionID OUTPUT, @msg = @msg OUTPUT
	IF @rcode <> 0 RETURN @rcode

	--Deleting the distributions won't be needed once changes are made to vHQBatchDistribution
	DELETE dbo.vGLDistributionInterface
	WHERE Co = @SMCo AND Mth = @BatchMonth AND BatchId = @BatchId

	DELETE dbo.vGLDistribution
	WHERE Co = @SMCo AND Mth = @BatchMonth AND BatchId = @BatchId

	INSERT dbo.vGLDistributionInterface ([Source], Co, Mth, BatchId, InterfaceLevel, Journal, SummaryDescription)
	SELECT @Source, @SMCo, @BatchMonth, @BatchId, 
		CASE GLLvl
			WHEN 'NoUpdate' THEN 0
			WHEN 'Summary' THEN 1
			WHEN 'Detail' THEN 2
		END, GLJrnl, RTRIM(GLSumDesc)
	FROM dbo.vSMCO
	WHERE SMCo = @SMCo

	SET @ActualDate = dbo.vfDateOnly()

	INSERT dbo.vGLDistribution ([Source], Co, Mth, BatchId, BatchSeq, GLCo, GLAccount, GLAccountSubType, Amount, ActDate)
	SELECT @Source, vSMWIPTransferBatch.Co, vSMWIPTransferBatch.Mth, vSMWIPTransferBatch.BatchId, vSMWIPTransferBatch.BatchSeq, vfSMWorkCompletedBuildTransferringEntries.GLCo, vfSMWorkCompletedBuildTransferringEntries.GLAccount, vfSMWorkCompletedBuildTransferringEntries.GLAccountSubType, vfSMWorkCompletedBuildTransferringEntries.Amount, @ActualDate
	FROM dbo.vSMWIPTransferBatch
		INNER JOIN dbo.vSMWorkCompleted ON vSMWIPTransferBatch.Co = vSMWorkCompleted.SMCo AND vSMWIPTransferBatch.WorkOrder = vSMWorkCompleted.WorkOrder AND vSMWIPTransferBatch.WorkCompleted = vSMWorkCompleted.WorkCompleted
		CROSS APPLY dbo.vfSMWorkCompletedBuildTransferringEntries(vSMWorkCompleted.SMWorkCompletedID, vSMWIPTransferBatch.TransferType, vSMWIPTransferBatch.NewGLCo, vSMWIPTransferBatch.NewGLAcct, 1)
	WHERE vSMWIPTransferBatch.Co = @SMCo AND vSMWIPTransferBatch.Mth = @BatchMonth AND vSMWIPTransferBatch.BatchId = @BatchId AND vSMWIPTransferBatch.TransferType = 'C'

	INSERT dbo.vGLDistribution ([Source], Co, Mth, BatchId, BatchSeq, GLCo, GLAccount, GLAccountSubType, Amount, ActDate)
	SELECT @Source, vSMWIPTransferBatch.Co, vSMWIPTransferBatch.Mth, vSMWIPTransferBatch.BatchId, vSMWIPTransferBatch.BatchSeq, vfSMWorkCompletedBuildTransferringEntries.GLCo, vfSMWorkCompletedBuildTransferringEntries.GLAccount, vfSMWorkCompletedBuildTransferringEntries.GLAccountSubType, vfSMWorkCompletedBuildTransferringEntries.Amount, @ActualDate
	FROM dbo.vSMWIPTransferBatch
		INNER JOIN dbo.vSMWorkCompleted ON vSMWIPTransferBatch.Co = vSMWorkCompleted.SMCo AND vSMWIPTransferBatch.WorkOrder = vSMWorkCompleted.WorkOrder AND vSMWIPTransferBatch.WorkCompleted = vSMWorkCompleted.WorkCompleted
		INNER JOIN dbo.vSMWorkOrder ON vSMWorkCompleted.SMCo = vSMWorkOrder.SMCo AND vSMWorkCompleted.WorkOrder = vSMWorkOrder.WorkOrder
		CROSS APPLY dbo.vfSMWorkCompletedBuildTransferringEntries(vSMWorkCompleted.SMWorkCompletedID, vSMWIPTransferBatch.TransferType, vSMWIPTransferBatch.NewGLCo, vSMWIPTransferBatch.NewGLAcct, 1)
	WHERE vSMWIPTransferBatch.Co = @SMCo AND vSMWIPTransferBatch.Mth = @BatchMonth AND vSMWIPTransferBatch.BatchId = @BatchId AND vSMWIPTransferBatch.TransferType = 'R' AND vSMWorkOrder.Job IS NOT NULL

	;WITH BuildTransferringEntriesCTE
	AS
	(
		SELECT vSMWIPTransferBatch.Co, vSMWIPTransferBatch.Mth, vSMWIPTransferBatch.BatchId, vSMWIPTransferBatch.BatchSeq, vSMWIPTransferBatch.NewGLCo, vSMWIPTransferBatch.NewGLAcct, vSMDetailTransaction.GLCo, vSMDetailTransaction.GLAccount, SUM(vSMDetailTransaction.Amount) AmountTotal
		FROM dbo.vSMWIPTransferBatch
			INNER JOIN dbo.vSMWorkCompleted ON vSMWIPTransferBatch.Co = vSMWorkCompleted.SMCo AND vSMWIPTransferBatch.WorkOrder = vSMWorkCompleted.WorkOrder AND vSMWIPTransferBatch.WorkCompleted = vSMWorkCompleted.WorkCompleted
			INNER JOIN dbo.vSMDetailTransaction ON vSMWorkCompleted.SMWorkCompletedID = vSMDetailTransaction.SMWorkCompletedID
			INNER JOIN dbo.vSMWorkOrder ON vSMWorkCompleted.SMCo = vSMWorkOrder.SMCo AND vSMWorkCompleted.WorkOrder = vSMWorkOrder.WorkOrder
		WHERE vSMWIPTransferBatch.Co = @SMCo AND vSMWIPTransferBatch.Mth = @BatchMonth AND vSMWIPTransferBatch.BatchId = @BatchId AND
			vSMWIPTransferBatch.TransferType = 'R' AND vSMDetailTransaction.Posted = 1 AND vSMDetailTransaction.TransactionType = 'R' AND vSMWorkOrder.Job IS NULL AND
			(
				vSMDetailTransaction.GLCo <> vSMWIPTransferBatch.NewGLCo OR
				vSMDetailTransaction.GLAccount <> vSMWIPTransferBatch.NewGLAcct
			)
		GROUP BY vSMWIPTransferBatch.Co, vSMWIPTransferBatch.Mth, vSMWIPTransferBatch.BatchId, vSMWIPTransferBatch.BatchSeq, vSMWIPTransferBatch.NewGLCo, vSMWIPTransferBatch.NewGLAcct, vSMDetailTransaction.GLCo, vSMDetailTransaction.GLAccount
	)
	INSERT dbo.vGLDistribution ([Source], Co, Mth, BatchId, BatchSeq, GLCo, GLAccount, GLAccountSubType, Amount, ActDate)
	SELECT @Source, BuildTransferringEntriesCTE.Co, BuildTransferringEntriesCTE.Mth, BuildTransferringEntriesCTE.BatchId, BuildTransferringEntriesCTE.BatchSeq, GeneratedEntries.GLCo, GeneratedEntries.GLAccount, GeneratedEntries.GLAccountSubType, GeneratedEntries.Amount, @ActualDate
	FROM BuildTransferringEntriesCTE
		LEFT JOIN dbo.bGLIA ON BuildTransferringEntriesCTE.GLCo = bGLIA.ARGLCo AND BuildTransferringEntriesCTE.NewGLCo = bGLIA.APGLCo
		CROSS APPLY
		(
			SELECT BuildTransferringEntriesCTE.GLCo, BuildTransferringEntriesCTE.GLAccount, 'S' GLAccountSubType, -(BuildTransferringEntriesCTE.AmountTotal) Amount
			UNION ALL 
			SELECT BuildTransferringEntriesCTE.NewGLCo, BuildTransferringEntriesCTE.NewGLAcct, 'S', BuildTransferringEntriesCTE.AmountTotal
			UNION ALL
			SELECT BuildTransferringEntriesCTE.GLCo, bGLIA.ARGLAcct, 'R', BuildTransferringEntriesCTE.AmountTotal
			WHERE BuildTransferringEntriesCTE.GLCo <> BuildTransferringEntriesCTE.NewGLCo
			UNION ALL 
			SELECT BuildTransferringEntriesCTE.NewGLCo, bGLIA.APGLAcct, 'P', -(BuildTransferringEntriesCTE.AmountTotal)
			WHERE BuildTransferringEntriesCTE.GLCo <> BuildTransferringEntriesCTE.NewGLCo
		) GeneratedEntries
	WHERE BuildTransferringEntriesCTE.AmountTotal <> 0

	;WITH BuildTransferringEntriesCTE
	AS
	(
		SELECT vSMWIPTransferBatch.Co, vSMWIPTransferBatch.Mth, vSMWIPTransferBatch.BatchId, vSMWIPTransferBatch.BatchSeq, vSMWIPTransferBatch.NewGLCo, vSMWIPTransferBatch.NewGLAcct, vSMDetailTransaction.GLCo, vSMDetailTransaction.GLAccount, SUM(vSMDetailTransaction.Amount) AmountTotal
		FROM dbo.vSMWIPTransferBatch
			INNER JOIN dbo.vSMWorkOrderScope ON vSMWIPTransferBatch.Co = vSMWorkOrderScope.SMCo AND vSMWIPTransferBatch.WorkOrder = vSMWorkOrderScope.WorkOrder AND vSMWIPTransferBatch.Scope = vSMWorkOrderScope.Scope
			INNER JOIN dbo.vSMEntity ON vSMWorkOrderScope.SMCo = vSMEntity.SMCo AND vSMWorkOrderScope.WorkOrder = vSMEntity.WorkOrder AND vSMWorkOrderScope.Scope = vSMEntity.WorkOrderScope
			INNER JOIN dbo.vSMFlatPriceRevenueSplit ON vSMEntity.SMCo = vSMFlatPriceRevenueSplit.SMCo AND vSMEntity.EntitySeq = vSMFlatPriceRevenueSplit.EntitySeq AND vSMWIPTransferBatch.FlatPriceRevenueSplitSeq = vSMFlatPriceRevenueSplit.Seq
			INNER JOIN dbo.vSMDetailTransaction ON vSMFlatPriceRevenueSplit.SMFlatPriceRevenueSplitID = vSMDetailTransaction.SMFlatPriceRevenueSplitID
		WHERE vSMWIPTransferBatch.Co = @SMCo AND vSMWIPTransferBatch.Mth = @BatchMonth AND vSMWIPTransferBatch.BatchId = @BatchId AND
			vSMWIPTransferBatch.TransferType = 'R' AND vSMDetailTransaction.Posted = 1 AND vSMDetailTransaction.TransactionType = 'R' AND
			(
				vSMDetailTransaction.GLCo <> vSMWIPTransferBatch.NewGLCo OR
				vSMDetailTransaction.GLAccount <> vSMWIPTransferBatch.NewGLAcct
			)
		GROUP BY vSMWIPTransferBatch.Co, vSMWIPTransferBatch.Mth, vSMWIPTransferBatch.BatchId, vSMWIPTransferBatch.BatchSeq, vSMWIPTransferBatch.NewGLCo, vSMWIPTransferBatch.NewGLAcct, vSMDetailTransaction.GLCo, vSMDetailTransaction.GLAccount
	)
	INSERT dbo.vGLDistribution ([Source], Co, Mth, BatchId, BatchSeq, GLCo, GLAccount, GLAccountSubType, Amount, ActDate)
	SELECT @Source, BuildTransferringEntriesCTE.Co, BuildTransferringEntriesCTE.Mth, BuildTransferringEntriesCTE.BatchId, BuildTransferringEntriesCTE.BatchSeq, GeneratedEntries.GLCo, GeneratedEntries.GLAccount, GeneratedEntries.GLAccountSubType, GeneratedEntries.Amount, @ActualDate
	FROM BuildTransferringEntriesCTE
		LEFT JOIN dbo.bGLIA ON BuildTransferringEntriesCTE.GLCo = bGLIA.ARGLCo AND BuildTransferringEntriesCTE.NewGLCo = bGLIA.APGLCo
		CROSS APPLY
		(
			SELECT BuildTransferringEntriesCTE.GLCo, BuildTransferringEntriesCTE.GLAccount, 'S' GLAccountSubType, -(BuildTransferringEntriesCTE.AmountTotal) Amount
			UNION ALL 
			SELECT BuildTransferringEntriesCTE.NewGLCo, BuildTransferringEntriesCTE.NewGLAcct, 'S', BuildTransferringEntriesCTE.AmountTotal
			UNION ALL
			SELECT BuildTransferringEntriesCTE.GLCo, bGLIA.ARGLAcct, 'R', BuildTransferringEntriesCTE.AmountTotal
			WHERE BuildTransferringEntriesCTE.GLCo <> BuildTransferringEntriesCTE.NewGLCo
			UNION ALL 
			SELECT BuildTransferringEntriesCTE.NewGLCo, bGLIA.APGLAcct, 'P', -(BuildTransferringEntriesCTE.AmountTotal)
			WHERE BuildTransferringEntriesCTE.GLCo <> BuildTransferringEntriesCTE.NewGLCo
		) GeneratedEntries
	WHERE BuildTransferringEntriesCTE.AmountTotal <> 0

	SELECT @GLDetlDesc = RTRIM(dbo.vfToString(GLDetlDesc))
	FROM dbo.SMCO
	WHERE SMCo = @SMCo

	UPDATE vGLDistribution
	SET @TransDesc = @GLDetlDesc,
		@TransDesc = REPLACE(@TransDesc, 'SM Company', dbo.vfToString(vSMWorkCompleted.SMCo)),
		@TransDesc = REPLACE(@TransDesc, 'Work Order', dbo.vfToString(vSMWorkCompleted.WorkOrder)),
		@TransDesc = REPLACE(@TransDesc, 'Scope', dbo.vfToString(vSMWorkCompletedDetail.Scope)),
		@TransDesc = REPLACE(@TransDesc, 'Line Type', dbo.vfToString(vSMWorkCompleted.[Type])),
		@TransDesc = REPLACE(@TransDesc, 'Line Sequence', dbo.vfToString(vSMWorkCompleted.WorkCompleted)),
		vGLDistribution.[Description] = @TransDesc
	FROM dbo.vSMWIPTransferBatch
		INNER JOIN dbo.vGLDistribution ON vSMWIPTransferBatch.Co = vGLDistribution.Co AND vSMWIPTransferBatch.Mth = vGLDistribution.Mth AND vSMWIPTransferBatch.BatchId = vGLDistribution.BatchId AND vSMWIPTransferBatch.BatchSeq = vGLDistribution.BatchSeq
		INNER JOIN dbo.vSMWorkCompleted ON vSMWIPTransferBatch.Co = vSMWorkCompleted.SMCo AND vSMWIPTransferBatch.WorkOrder = vSMWorkCompleted.WorkOrder AND vSMWIPTransferBatch.WorkCompleted = vSMWorkCompleted.WorkCompleted
		INNER JOIN dbo.vSMWorkCompletedDetail ON vSMWorkCompleted.SMWorkCompletedID = vSMWorkCompletedDetail.SMWorkCompletedID AND vSMWorkCompletedDetail.IsSession = 0
	WHERE vSMWIPTransferBatch.Co = @SMCo AND vSMWIPTransferBatch.Mth = @BatchMonth AND vSMWIPTransferBatch.BatchId = @BatchId

	UPDATE vGLDistribution
	SET @TransDesc = @GLDetlDesc,
		@TransDesc = REPLACE(@TransDesc, 'SM Company', dbo.vfToString(vSMWorkOrderScope.SMCo)),
		@TransDesc = REPLACE(@TransDesc, 'Work Order', dbo.vfToString(vSMWorkOrderScope.WorkOrder)),
		@TransDesc = REPLACE(@TransDesc, 'Scope', dbo.vfToString(vSMWorkOrderScope.Scope)),
		@TransDesc = REPLACE(@TransDesc, 'Line Type', ''),
		@TransDesc = REPLACE(@TransDesc, 'Line Sequence', ''),
		vGLDistribution.[Description] = @TransDesc
	FROM dbo.vSMWIPTransferBatch
		INNER JOIN dbo.vGLDistribution ON vSMWIPTransferBatch.Co = vGLDistribution.Co AND vSMWIPTransferBatch.Mth = vGLDistribution.Mth AND vSMWIPTransferBatch.BatchId = vGLDistribution.BatchId AND vSMWIPTransferBatch.BatchSeq = vGLDistribution.BatchSeq
		INNER JOIN dbo.vSMWorkOrderScope ON vSMWIPTransferBatch.Co = vSMWorkOrderScope.SMCo AND vSMWIPTransferBatch.WorkOrder = vSMWorkOrderScope.WorkOrder AND vSMWIPTransferBatch.Scope = vSMWorkOrderScope.Scope
	WHERE vSMWIPTransferBatch.Co = @SMCo AND vSMWIPTransferBatch.Mth = @BatchMonth AND vSMWIPTransferBatch.BatchId = @BatchId

	EXEC @rcode = dbo.vspGLDistributionValidate @Source = @Source, @BatchCo = @SMCo, @BatchMonth = @BatchMonth, @BatchId = @BatchId
	IF @rcode <> 0 GOTO EndValidation

	--Capture all the reconciliation records for the WIP transfer for work completed
	INSERT dbo.vSMDetailTransaction (IsReversing, Posted, HQBatchDistributionID, HQDetailID, SMWorkCompletedID, SMWorkOrderScopeID, SMWorkOrderID, LineType, TransactionType, SourceCo, Mth, BatchId, GLCo, GLAccount, Amount, [Description])
	SELECT 0 IsReversing, 0 Posted, @HQBatchDistributionID, SMWorkCompleted.CostDetailID, SMWorkCompleted.SMWorkCompletedID, vSMWorkOrderScope.SMWorkOrderScopeID, vSMWorkOrder.SMWorkOrderID,
		SMWorkCompleted.[Type], vSMWIPTransferBatch.TransferType, @SMCo, @BatchMonth, @BatchId,
		vGLDistribution.GLCo, vGLDistribution.GLAccount, vGLDistribution.Amount, vGLDistribution.[Description]
	FROM dbo.vSMWIPTransferBatch
		INNER JOIN dbo.SMWorkCompleted ON vSMWIPTransferBatch.Co = SMWorkCompleted.SMCo AND vSMWIPTransferBatch.WorkOrder = SMWorkCompleted.WorkOrder AND vSMWIPTransferBatch.WorkCompleted = SMWorkCompleted.WorkCompleted
		INNER JOIN dbo.vSMWorkOrderScope ON SMWorkCompleted.SMCo = vSMWorkOrderScope.SMCo AND SMWorkCompleted.WorkOrder = vSMWorkOrderScope.WorkOrder AND SMWorkCompleted.Scope = vSMWorkOrderScope.Scope
		INNER JOIN dbo.vSMWorkOrder ON vSMWIPTransferBatch.Co = vSMWorkOrder.SMCo AND vSMWIPTransferBatch.WorkOrder = vSMWorkOrder.WorkOrder
		INNER JOIN dbo.vGLDistribution ON vSMWIPTransferBatch.Co = vGLDistribution.Co AND vSMWIPTransferBatch.Mth = vGLDistribution.Mth AND vSMWIPTransferBatch.BatchId = vGLDistribution.BatchId AND vSMWIPTransferBatch.BatchSeq = vGLDistribution.BatchSeq
	WHERE vSMWIPTransferBatch.Co = @SMCo AND vSMWIPTransferBatch.Mth = @BatchMonth AND vSMWIPTransferBatch.BatchId = @BatchId AND vGLDistribution.GLAccountSubType = 'S'
	
	--Update the PR related fields for costs so that when ledger update is run reconciliaton correctly captures that changes
	UPDATE vSMDetailTransaction
	SET PRMth = vPRLedgerUpdateMonth.Mth
	FROM dbo.vSMDetailTransaction
		INNER JOIN dbo.vSMWorkCompleted ON vSMDetailTransaction.SMWorkCompletedID = vSMWorkCompleted.SMWorkCompletedID
		INNER JOIN dbo.vPRLedgerUpdateMonth ON vSMWorkCompleted.PRLedgerUpdateMonthID = vPRLedgerUpdateMonth.PRLedgerUpdateMonthID
		INNER JOIN dbo.vSMWorkOrder ON vSMWorkCompleted.SMCo = vSMWorkOrder.SMCo AND vSMWorkCompleted.WorkOrder = vSMWorkOrder.WorkOrder
	WHERE vSMDetailTransaction.HQBatchDistributionID = @HQBatchDistributionID AND vSMWorkCompleted.[Type] = 2 AND vSMDetailTransaction.TransactionType = 'C'

	--Capture all the reconciliation records for the WIP transfer for flat price revenue
	INSERT dbo.vSMDetailTransaction (IsReversing, Posted, HQBatchDistributionID, SMWorkOrderScopeID, SMWorkOrderID, SMFlatPriceRevenueSplitID, TransactionType, SourceCo, Mth, BatchId, GLCo, GLAccount, Amount, [Description])
	SELECT 0 IsReversing, 0 Posted, @HQBatchDistributionID, vSMWorkOrderScope.SMWorkOrderScopeID, vSMWorkOrder.SMWorkOrderID, vSMFlatPriceRevenueSplit.SMFlatPriceRevenueSplitID,
		vSMWIPTransferBatch.TransferType, @SMCo, @BatchMonth, @BatchId,
		vGLDistribution.GLCo, vGLDistribution.GLAccount, vGLDistribution.Amount, vGLDistribution.[Description]
	FROM dbo.vSMWIPTransferBatch
		INNER JOIN dbo.vSMWorkOrderScope ON vSMWIPTransferBatch.Co = vSMWorkOrderScope.SMCo AND vSMWIPTransferBatch.WorkOrder = vSMWorkOrderScope.WorkOrder AND vSMWIPTransferBatch.Scope = vSMWorkOrderScope.Scope
		INNER JOIN dbo.vSMEntity ON vSMWorkOrderScope.SMCo = vSMEntity.SMCo AND vSMWorkOrderScope.WorkOrder = vSMEntity.WorkOrder AND vSMWorkOrderScope.Scope = vSMEntity.WorkOrderScope
		INNER JOIN dbo.vSMFlatPriceRevenueSplit ON vSMEntity.SMCo = vSMFlatPriceRevenueSplit.SMCo AND vSMEntity.EntitySeq = vSMFlatPriceRevenueSplit.EntitySeq AND vSMWIPTransferBatch.FlatPriceRevenueSplitSeq = vSMFlatPriceRevenueSplit.Seq
		INNER JOIN dbo.vSMWorkOrder ON vSMWIPTransferBatch.Co = vSMWorkOrder.SMCo AND vSMWIPTransferBatch.WorkOrder = vSMWorkOrder.WorkOrder
		INNER JOIN dbo.vGLDistribution ON vSMWIPTransferBatch.Co = vGLDistribution.Co AND vSMWIPTransferBatch.Mth = vGLDistribution.Mth AND vSMWIPTransferBatch.BatchId = vGLDistribution.BatchId AND vSMWIPTransferBatch.BatchSeq = vGLDistribution.BatchSeq
	WHERE vSMWIPTransferBatch.Co = @SMCo AND vSMWIPTransferBatch.Mth = @BatchMonth AND vSMWIPTransferBatch.BatchId = @BatchId AND vGLDistribution.GLAccountSubType = 'S'

EndValidation:
	EXEC @rcode = dbo.vspHQBatchValidated @BatchCo = @SMCo, @BatchMth = @BatchMonth, @BatchId = @BatchId, @msg = @msg OUTPUT
	IF @rcode <> 0 RETURN @rcode

	RETURN 0
END
GO

GRANT EXECUTE ON  [dbo].[vspSMWIPTransferValidate] TO [public]
GO
