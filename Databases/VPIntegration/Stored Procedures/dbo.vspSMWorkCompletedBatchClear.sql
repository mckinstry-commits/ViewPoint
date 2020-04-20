SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 5/2/2012
-- Description:	Clears all the entries created for SMWorkCompletedBatch records
-- =============================================
CREATE PROCEDURE [dbo].[vspSMWorkCompletedBatchClear]
	@BatchCo bCompany, @BatchMonth bMonth, @BatchId bBatchID, @msg varchar(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @EntriesToDelete TABLE (CurrentRevenueGLEntryID bigint, ReversingRevenueGLEntryID bigint, CurrentJCCostEntryID bigint, ReversingJCCostEntryID bigint)

	BEGIN TRY
		DELETE dbo.vSMJobCostDistribution
		WHERE BatchCo = @BatchCo AND BatchMth = @BatchMonth AND BatchID = @BatchId

		UPDATE dbo.vSMWorkCompletedBatch
		SET CurrentRevenueGLEntryID = NULL, ReversingRevenueGLEntryID = NULL, CurrentJCCostEntryID = NULL, ReversingJCCostEntryID = NULL
			OUTPUT DELETED.CurrentRevenueGLEntryID, DELETED.ReversingRevenueGLEntryID, DELETED.CurrentJCCostEntryID, DELETED.ReversingJCCostEntryID
				INTO @EntriesToDelete
		WHERE BatchCo = @BatchCo AND BatchMonth = @BatchMonth AND BatchId = @BatchId

		DELETE dbo.vJCCostEntry
		WHERE JCCostEntryID IN (SELECT CurrentJCCostEntryID FROM @EntriesToDelete UNION SELECT ReversingJCCostEntryID FROM @EntriesToDelete)

		DELETE dbo.vGLEntry
		WHERE GLEntryID IN (SELECT CurrentRevenueGLEntryID FROM @EntriesToDelete UNION SELECT ReversingRevenueGLEntryID FROM @EntriesToDelete)
	END TRY
	BEGIN CATCH
		SET @msg = ERROR_MESSAGE()
		RETURN 1
	END CATCH

	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMWorkCompletedBatchClear] TO [public]
GO
