SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 9/27/2012
-- Description:	Verifies that the batch is able to be posted and updates the batch to posting in progress.
--				Also creates new detail records for any batch record that aren't assigned one yet.
-- =============================================
CREATE PROCEDURE [dbo].[vspHQBatchPosting]
	@BatchCo bCompany, @BatchMth bMonth, @BatchId bBatchID, @Source bSource, @TableName varchar(20), @DatePosted bDate, @msg varchar(255) = NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @rcode int, @Status tinyint

	-- Validate HQ Batch
	EXEC @rcode = dbo.bspHQBatchProcessVal @hqco = @BatchCo, @mth = @BatchMth, @batchid = @BatchId, @source = @Source, @table = @TableName, @status = @Status OUTPUT, @msg = @msg OUTPUT
	IF @rcode <> 0 RETURN @rcode
	
	IF @Status NOT IN (3,4) -- valid - OK to post, or posting in progress
	BEGIN
		SET @msg = 'Invalid Batch status -  must be ''valid - OK to post'' or ''posting in progress''!'
		RETURN 1
	END
	
	--check for Posting Date
	IF @DatePosted IS NULL
	BEGIN
		SET @msg = 'Missing posting date!'
		RETURN 1
	END
	
	--Set HQ Batch status to 4 (posting in progress)
	UPDATE dbo.bHQBC
	SET [Status] = 4, DatePosted = @DatePosted
	WHERE Co = @BatchCo AND Mth = @BatchMth AND BatchId = @BatchId
	IF @@rowcount = 0
	BEGIN
		SET @msg = 'Unable to update HQ Batch Control information!'
		RETURN 1
	END
	
	DECLARE @HQDetailID bigint
	
	WHILE EXISTS(SELECT 1 FROM dbo.vHQBatchLine WHERE Co = @BatchCo AND Mth = @BatchMth AND BatchId = @BatchId AND HQDetailID IS NULL)
	BEGIN
		EXEC @rcode = dbo.vspHQDetailCreate @Source = @Source, @HQDetailID = @HQDetailID OUTPUT
		IF @rcode <> 0 RETURN 1
		
		UPDATE TOP (1) dbo.vHQBatchLine
		SET HQDetailID = @HQDetailID
		WHERE Co = @BatchCo AND Mth = @BatchMth AND BatchId = @BatchId AND HQDetailID IS NULL
	END

	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[vspHQBatchPosting] TO [public]
GO
