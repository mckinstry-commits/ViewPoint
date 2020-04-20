SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 5/16/11
-- Description:	Cancels a given batch and clears out distribution tables
-- Modified:	JB 12/6/12 Update related to removing PO Receipts posting.
-- =============================================
CREATE PROCEDURE [dbo].[vspSMCancelBatch]
	@BatchCo bCompany, @BatchMth bMonth, @BatchId bBatchID
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    UPDATE dbo.HQBC
    SET [Status] = 6
    WHERE Co = @BatchCo AND Mth = @BatchMth AND BatchId = @BatchId
    
    DELETE dbo.vHQBatchDistribution
	WHERE Co = @BatchCo AND Mth = @BatchMth AND BatchId = @BatchId
    
    DELETE dbo.vHQBatchLine
	WHERE Co = @BatchCo AND Mth = @BatchMth AND BatchId = @BatchId

    DELETE dbo.vSMWorkCompletedBatch
    WHERE BatchCo = @BatchCo AND BatchMonth = @BatchMth AND BatchId = @BatchId
    
    DELETE dbo.vSMEMUsageBreakdownDistribution
    WHERE SMCo = @BatchCo AND Mth = @BatchMth AND BatchId = @BatchId
    
    DELETE dbo.SMINBatch
    WHERE SMCo = @BatchCo AND Mth = @BatchMth AND BatchId = @BatchId
    
    DELETE dbo.SMGLDistribution
    WHERE SMCo = @BatchCo AND BatchMonth = @BatchMth AND BatchId = @BatchId
    
    DELETE dbo.PORB
    WHERE Co = @BatchCo AND Mth = @BatchMth AND BatchId = @BatchId
    
    DELETE dbo.PORG
    WHERE POCo = @BatchCo AND Mth = @BatchMth AND BatchId = @BatchId

    RETURN 0    
END


GO
GRANT EXECUTE ON  [dbo].[vspSMCancelBatch] TO [public]
GO
