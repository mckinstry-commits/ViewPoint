SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 9/27/2012
-- Description:	Validates SM WorkCompleted changes.
-- =============================================
CREATE PROCEDURE [dbo].[vspSMWorkCompletedValidate]
	@BatchCo bCompany, @BatchMth bMonth, @BatchId bBatchID, @HQBatchDistributionID bigint, @msg varchar(255) = NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	--Build out the work completed transactions. This should include the reversing and correcting transactions.
	WITH BuildSMDetailTransactions
	AS
	(
		SELECT vfSMWorkCompletedDetailTransaction.*, vHQBatchLine.HQBatchLineID
		FROM dbo.vHQBatchLine
			CROSS APPLY dbo.vfSMWorkCompletedDetailTransaction(vHQBatchLine.HQDetailID)
		WHERE vHQBatchLine.Co = @BatchCo AND vHQBatchLine.Mth = @BatchMth AND vHQBatchLine.BatchId = @BatchId
	)
	INSERT dbo.vSMDetailTransaction (IsReversing, Posted, HQBatchLineID, HQBatchDistributionID, SMWorkCompletedID, SMWorkOrderScopeID, SMWorkOrderID, LineType, TransactionType, SourceCo, Mth, BatchId, GLCo, GLAccount, Amount)
	SELECT IsReversing, 0 Posted, HQBatchLineID, @HQBatchDistributionID, SMWorkCompletedID, SMWorkOrderScopeID, SMWorkOrderID, LineType, TransactionType, @BatchCo, @BatchMth, @BatchId, GLCo, GLAccount, Amount
	FROM BuildSMDetailTransactions

	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMWorkCompletedValidate] TO [public]
GO
