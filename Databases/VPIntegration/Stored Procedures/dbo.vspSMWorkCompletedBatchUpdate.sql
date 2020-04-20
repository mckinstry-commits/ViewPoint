SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 2/14/2011
-- Description:	Handles updating usage on equipment for SM Work Completed records
-- =============================================
CREATE PROCEDURE [dbo].[vspSMWorkCompletedBatchUpdate]
(
	@SMCo bCompany, @WorkOrder int, @WorkCompleted int, @IsTrialRun bit, @msg varchar(255) = NULL OUTPUT
)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @rcode int, @SMWorkCompletedID bigint, @BatchStatus tinyint, @InUseBy bVPUserName, @BatchCo bCompany, @BatchMonth bMonth, @BatchId bBatchID,
		@CostDetailID bigint, @BatchTransType char(1)

	SET @BatchCo = @SMCo

	SELECT @SMWorkCompletedID = SMWorkCompletedID, @BatchMonth = MonthToPostCost,
		@CostDetailID = CostDetailID, @BatchTransType = CASE WHEN IsDeleted = 1 THEN 'D' WHEN InitialCostsCaptured = 0 THEN 'A' ELSE 'C' END
	FROM dbo.SMWorkCompletedAllCurrent
	WHERE SMCo = @SMCo AND WorkOrder = @WorkOrder AND WorkCompleted = @WorkCompleted
	IF @@rowcount = 0
	BEGIN
		--If the work completed was deleted before any costs were captured then no processing is needed.
		RETURN 0
	END
	
	--First check to see if the work completed is already part of a batch and use that batch in that case
	SELECT @BatchStatus = bHQBC.[Status], @InUseBy = bHQBC.InUseBy, @BatchCo = bHQBC.Co, @BatchMonth = bHQBC.Mth, @BatchId = bHQBC.BatchId
	FROM dbo.vSMWorkCompletedBatch
		INNER JOIN dbo.bHQBC ON vSMWorkCompletedBatch.BatchCo = bHQBC.Co AND vSMWorkCompletedBatch.BatchMonth = bHQBC.Mth AND vSMWorkCompletedBatch.BatchId = bHQBC.BatchId
	WHERE vSMWorkCompletedBatch.SMWorkCompletedID = @SMWorkCompletedID
	IF @@rowcount <> 0
	BEGIN
		IF @BatchStatus > 3
		BEGIN
			SET @msg = 'Work Completed batch posting in progress'
			RETURN 1
		END
		
		IF @InUseBy <> SUSER_NAME()
		BEGIN
			SET @msg = 'Work Completed batch is currently in use by ' + @InUseBy
			RETURN 1
		END
		
		IF @InUseBy IS NULL
		BEGIN
			UPDATE dbo.bHQBC SET InUseBy = SUSER_NAME() WHERE Co = @BatchCo AND Mth = @BatchMonth AND BatchId = @BatchId
		END
		
		IF NOT EXISTS(SELECT 1 FROM #UsersCurrentBatches WHERE Co = @BatchCo AND Mth = @BatchMonth AND BatchId = @BatchId)
		BEGIN
			INSERT #UsersCurrentBatches
			VALUES (@BatchCo, @BatchMonth, @BatchId)
		END
	END
	ELSE --In this case the work completed has not been associated with a batch therefore we find one that will work or create a new one.
	BEGIN
		DECLARE @RestrictedBatches bYN
		DECLARE @PossibleBatchesToAddTo TABLE (BatchId bBatchID)
		
		INSERT @PossibleBatchesToAddTo
		SELECT bHQBC.BatchId 
		FROM #UsersCurrentBatches UsersCurrentBatches
			INNER JOIN dbo.bHQBC ON UsersCurrentBatches.Co = bHQBC.Co AND UsersCurrentBatches.Mth = bHQBC.Mth AND UsersCurrentBatches.BatchId = bHQBC.BatchId
		WHERE UsersCurrentBatches.Co = @BatchCo AND UsersCurrentBatches.Mth = @BatchMonth AND bHQBC.[Source] = 'SMEquipUse' AND bHQBC.[Status] < 4 AND bHQBC.InUseBy = SUSER_NAME()
		
		--Loop through the batches we are currently working with and as long as it is valid we can add to it.
		WHILE EXISTS(SELECT 1 FROM @PossibleBatchesToAddTo)
		BEGIN
			SELECT TOP 1 @BatchId = BatchId
			FROM @PossibleBatchesToAddTo
			
			DELETE @PossibleBatchesToAddTo WHERE BatchId = @BatchId
			
			--Make sure the batch is still valid before we start adding more records to it.
			--The batch validation is done in a transaction so that it can be rolled back to a status of 0
			--This is done because SM Batches doesn't lock batches unless they are a status 0
			BEGIN TRAN
				--A save point is used to rollback to because this stored procedure is called from within a transaction
				--and we don't want to mess up the sprocs trans count.
				SAVE TRAN ValidateBatch
			
				EXEC @rcode = dbo.vspSMEMUsageBatchValidation @SMCo = @BatchCo, @BatchMth = @BatchMonth, @BatchId = @BatchId, @Source = 'SMEquipUse', @TableName = 'SMEMUsageBatch'
			
				ROLLBACK TRAN ValidateBatch
			COMMIT TRAN
			
			IF @rcode = 0 BREAK

			SET @BatchId = NULL
		END

		IF @BatchId IS NULL
		BEGIN
			SELECT @RestrictedBatches = RestrictedBatches
			FROM dbo.vDDUP
			WHERE VPUserName = SUSER_NAME()

			EXEC @BatchId = dbo.bspHQBCInsert @co = @BatchCo, @month = @BatchMonth, @source = 'SMEquipUse', @batchtable = 'SMEMUsageBatch', @restrict = @RestrictedBatches, @adjust = 'N', @errmsg = @msg OUTPUT

			IF @BatchId = 0 RETURN 1
			
			INSERT #UsersCurrentBatches
			VALUES (@BatchCo, @BatchMonth, @BatchId)
		END
		
		INSERT dbo.vSMWorkCompletedBatch (SMWorkCompletedID, BatchCo, BatchMonth, BatchId, BatchSeq)
		SELECT @SMWorkCompletedID, @BatchCo, @BatchMonth, @BatchId, (SELECT ISNULL(MAX(BatchSeq), 0) + 1 FROM dbo.vSMWorkCompletedBatch WHERE BatchCo = @BatchCo AND BatchMonth = @BatchMonth AND BatchId = @BatchId)
	END
	
	IF @CostDetailID IS NULL
	BEGIN
		EXEC @rcode = dbo.vspHQDetailCreate @Source = 'SMEquipUse', @HQDetailID = @CostDetailID OUTPUT, @msg = @msg OUTPUT
		IF @rcode <> 0 RETURN 1
		
		UPDATE dbo.vSMWorkCompleted
		SET CostDetailID = @CostDetailID
		WHERE SMWorkCompletedID = @SMWorkCompletedID
	END
	
	--Always make sure the trans type is up to date because the user may have first modified
	--the work completed and it got added to the batch but then decided to delete the record.
	UPDATE dbo.vHQBatchLine
	SET BatchTransType = @BatchTransType
	WHERE Co = @BatchCo AND Mth = @BatchMonth AND BatchId = @BatchId AND HQDetailID = @CostDetailID
	IF @@rowcount = 0
	BEGIN
		INSERT dbo.vHQBatchLine (Co, Mth, BatchId, HQDetailID, BatchTransType)
		VALUES (@BatchCo, @BatchMonth, @BatchId, @CostDetailID, @BatchTransType)
	END
	
	EXEC @rcode = dbo.vspSMEMUsageBatchValidation @SMCo = @BatchCo, @BatchMth = @BatchMonth, @BatchId = @BatchId, @Source = 'SMEquipUse', @TableName = 'SMEMUsageBatch', @msg = @msg OUTPUT
	IF @rcode <> 0 RETURN @rcode
	
	--When checking if we will allow the changes to work completed we do a trial run of validating and posting the batch
	--That way we prevent the changes to work completed because the costs won't be able to be captured.
	IF @IsTrialRun = 1
	BEGIN
		DECLARE @PostDate bDate
		SET @PostDate = dbo.vfDateOnly()

		EXEC @rcode = dbo.vspSMEMUsageBatchPosting @SMCo = @BatchCo, @BatchMth = @BatchMonth, @BatchId = @BatchId, @Source = 'SMEquipUse', @TableName = 'SMEMUsageBatch', @PostDate = @PostDate, @msg = @msg OUTPUT

		IF @rcode <> 0 RETURN @rcode
	END
	ELSE
	BEGIN
		UPDATE dbo.bHQBC
		SET [Status] = 0
		WHERE Co = @BatchCo AND Mth = @BatchMonth AND BatchId = @BatchId
	END

	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[vspSMWorkCompletedBatchUpdate] TO [public]
GO
