SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 9/4/2012
-- Description:	Updates the batch to posted and captures the date it was closed. Also verifies that all distributions were posted
--				and cleans up the vHQBatchLine, vHQBatchDistribution and HQCC records.
-- =============================================
CREATE PROCEDURE [dbo].[vspHQBatchPosted]
	@BatchCo bCompany, @BatchMth bMonth, @BatchId bBatchID, @Notes varchar(max) = '', @msg varchar(255) = NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	--If any generic HQBatchLine records were created they should be deleted at this point.
	BEGIN TRY
		--Any detail records should be deleted at this point if they were marked as delete within the batch			
		DELETE vHQDetail
		FROM dbo.vHQBatchLine
			INNER JOIN dbo.vHQDetail ON vHQBatchLine.HQDetailID = vHQDetail.HQDetailID
		WHERE vHQBatchLine.Co = @BatchCo AND vHQBatchLine.Mth = @BatchMth AND vHQBatchLine.BatchId = @BatchId AND vHQBatchLine.BatchTransType = 'D'
		
		DELETE dbo.vHQBatchLine
		WHERE Co = @BatchCo AND Mth = @BatchMth AND BatchId = @BatchId
	END TRY
	BEGIN CATCH
		SET @msg = 'Not all detail was able to be cleaned up - unable to close the batch. ' + ERROR_MESSAGE()
		RETURN 1
	END CATCH

	BEGIN TRY
		--Updating the vHQBatchDistributions to posted should cause a fk exception
		--if any distribution records are still pointing to the vHQBatchDistribution.
		--This allows for cascade deleting when clearing batches during validation and
		--validating  that all distributions were processed as expected.
		UPDATE dbo.vHQBatchDistribution
		SET Posted = 1
		WHERE Co = @BatchCo AND Mth = @BatchMth AND BatchId = @BatchId
		
		-- Delete vHQBatchDistribution entries
		DELETE dbo.vHQBatchDistribution
		WHERE Co = @BatchCo AND Mth = @BatchMth AND BatchId = @BatchId
	END TRY
	BEGIN CATCH
		SET @msg = 'Not all updates were posted - unable to close the batch. ' + ERROR_MESSAGE()
		RETURN 1
	END CATCH

	-- Delete HQ Close Control entries
	DELETE dbo.bHQCC
	WHERE Co = @BatchCo AND Mth = @BatchMth AND BatchId = @BatchId
	
	-- Set HQ Batch status to 5 (posted)
	UPDATE dbo.bHQBC
	SET [Status] = 5, DateClosed = GETDATE(), Notes = dbo.vfToString(Notes) + dbo.vfToString(@Notes)
	WHERE Co = @BatchCo AND Mth = @BatchMth AND BatchId = @BatchId	
	IF @@rowcount = 0
	BEGIN
		SET @msg = 'Unable to update HQ Batch Control information!'
		RETURN 1
	END
	
	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[vspHQBatchPosted] TO [public]
GO
