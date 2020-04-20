SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 9/27/2012
-- Description:	Posts SM WorkCompleted changes.
-- Modifications: EricV 05/14/13 - TFS-50101 Added the @GLInterfaceLevel parameter to update the GLInterfaceLevel value on the vSMDetailTransaction record.
-- =============================================
CREATE PROCEDURE [dbo].[vspSMWorkCompletedPost]
	@BatchCo bCompany, @BatchMth bMonth, @BatchId bBatchID, @GLInterfaceLevel tinyint, @msg varchar(255) = NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	--Update the DetailID
	UPDATE vSMDetailTransaction
	SET HQBatchLineID = NULL, HQDetailID = vHQBatchLine.HQDetailID
	FROM dbo.vHQBatchLine
		INNER JOIN dbo.vSMDetailTransaction ON vHQBatchLine.HQBatchLineID = vSMDetailTransaction.HQBatchLineID
	WHERE vHQBatchLine.Co = @BatchCo AND vHQBatchLine.Mth = @BatchMth AND vHQBatchLine.BatchId = @BatchId
	
	--Set the transaction as posted
	UPDATE vSMDetailTransaction
	SET Posted = 1, GLInterfaceLevel = @GLInterfaceLevel, HQBatchDistributionID = NULL
	FROM dbo.vHQBatchDistribution
		INNER JOIN dbo.vSMDetailTransaction ON vHQBatchDistribution.HQBatchDistributionID = vSMDetailTransaction.HQBatchDistributionID
	WHERE vHQBatchDistribution.Co = @BatchCo AND vHQBatchDistribution.Mth = @BatchMth AND vHQBatchDistribution.BatchId = @BatchId

	BEGIN TRY
		--Delete the work completed that has been marked for deletion.
		DELETE vSMWorkCompleted
		FROM dbo.vHQBatchLine
			INNER JOIN dbo.vSMWorkCompleted ON vHQBatchLine.HQDetailID = vSMWorkCompleted.CostDetailID
		WHERE vHQBatchLine.Co = @BatchCo AND vHQBatchLine.Mth = @BatchMth AND vHQBatchLine.BatchId = @BatchId AND vSMWorkCompleted.IsDeleted = 1
		
		--Update the work completed to indicate it has had the costs captured.
		UPDATE vSMWorkCompleted
		SET InitialCostsCaptured = 1, CostsCaptured = 1
		FROM dbo.vHQBatchLine
			INNER JOIN dbo.vSMWorkCompleted ON vHQBatchLine.HQDetailID = vSMWorkCompleted.CostDetailID
		WHERE vHQBatchLine.Co = @BatchCo AND vHQBatchLine.Mth = @BatchMth AND vHQBatchLine.BatchId = @BatchId
	END TRY
	BEGIN CATCH
		SET @msg = 'Error updating/deleting work completed. - ' + ERROR_MESSAGE()
		RETURN 1
	END CATCH

	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[vspSMWorkCompletedPost] TO [public]
GO
