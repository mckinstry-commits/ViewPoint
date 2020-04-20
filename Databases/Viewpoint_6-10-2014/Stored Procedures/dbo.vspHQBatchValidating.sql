SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 9/4/2012
-- Description:	Verifies that the batch can be validated and clears generic batch distributions. Also creates a batch
--				distribution that can be used within the batch for distributions.
-- =============================================
CREATE PROCEDURE [dbo].[vspHQBatchValidating]
	@BatchCo bCompany, @BatchMth bMonth, @BatchId bBatchID, @Source bSource, @TableName varchar(20), @HQBatchDistributionID bigint = NULL OUTPUT, @msg varchar(255) = NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @rcode int, @Status tinyint

	---- validate HQ Batch
	EXEC @rcode = dbo.bspHQBatchProcessVal @hqco = @BatchCo, @mth = @BatchMth, @batchid = @BatchId, @source = @Source, @table = @TableName, @status = @Status OUTPUT, @msg = @msg OUTPUT
	IF @rcode <> 0 RETURN @rcode

    IF @Status < 0 OR @Status > 3
	BEGIN
		SET @msg = 'Invalid Batch status!'
		RETURN 1
	END

	/* set HQ Batch status to 1 (validation in progress) */
	UPDATE dbo.bHQBC 
	SET [Status] = 1
	WHERE Co = @BatchCo AND Mth = @BatchMth AND BatchId = @BatchId
	IF @@rowcount = 0
	BEGIN
		SET @msg = 'Unable to update HQ Batch Control status!'
		RETURN 1
	END
	
	--Clear batch errors
	DELETE dbo.bHQBE
	WHERE Co = @BatchCo AND Mth = @BatchMth AND BatchId = @BatchId
	
	-- Clear HQ Close Control entries
	DELETE dbo.bHQCC
	WHERE Co = @BatchCo AND Mth = @BatchMth AND BatchId = @BatchId
	
	--Delete the distributions so that they can be rebuilt. This should cascade delete
	--any distributions tied to the batch
	DELETE dbo.vHQBatchDistribution
	WHERE Co = @BatchCo AND Mth = @BatchMth AND BatchId = @BatchId
	
	--A new distribution is created so that any number of records can be tied
	--to the batch as a distribution and can easily be deleted through cascade deletes.
	INSERT dbo.vHQBatchDistribution (Co, Mth, BatchId, InterfacingCo)
	VALUES (@BatchCo, @BatchMth, @BatchId, @BatchCo)
	
	SET @HQBatchDistributionID = SCOPE_IDENTITY()
	
	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[vspHQBatchValidating] TO [public]
GO
