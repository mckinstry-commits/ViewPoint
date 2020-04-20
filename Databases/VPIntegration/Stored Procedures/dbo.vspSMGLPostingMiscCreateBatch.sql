SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspSMGLPostingMiscCreateBatch]
   /***********************************************************
    * Created:  ECV 03/28/11
    * Modified: 
    *
    *
    * Creates a batch of GL records for Work Completed 
    * Miscellaneous records.
    *
    * GL Interface Levels:
    *	0      No update
    *	1      Summarize entries by GLCo#/GL Account
    *   2      Full detail
    *
    * INPUT PARAMETERS
    *   @SMCo            SM Co#
    *   @mth             Posting Month
    *   @ServiceCenterID SM Service Center ID
    *   @DivisionID      SM Division
    *   @MinDate         Minimum Transaction Date
    *   @MaxDate         Maximum Transaction Date
    *
    * OUTPUT PARAMETERS
    *   @msg             error message if something went wrong
    *
    * RETURN VALUE
    *   0                success
    *   1                fail
    *****************************************************/

(@SMCo bCompany, @Mth bMonth, @ServiceCenter varchar(10), @Division varchar(10), 
 @MinDate smalldatetime, @MaxDate smalldatetime, @Source varchar(10), @msg varchar(255) = NULL OUTPUT)
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @rcode int, @CurrentUser bVPUserName, @SMWorkCompletedID bigint, @MonthToPostCost bDate, @ChangesMade bit, @BatchId bBatchID, @BatchSeq int, @StringBuilder varchar(255), @errortext varchar(255),
		@CostDetailID bigint, @BatchTransType char(1)
	SET @CurrentUser = suser_name()

	DECLARE @WorkCompletedToUpdate TABLE (SMWorkCompletedID bigint PRIMARY KEY, MonthToPostCost bDate, ChangesMade bit)
	
	DECLARE @BatchesUpdated TABLE (BatchId bBatchID, WasCreated bit)

	INSERT @WorkCompletedToUpdate
	SELECT WorkCompletedToUpdate.SMWorkCompletedID, COALESCE(SMWorkCompleted.MonthToPostCost, @Mth, dbo.vfDateOnlyMonth()), ChangesMade
	FROM dbo.vfSMGetWorkCompletedMiscellaneousToBeProcessed(@SMCo, @Mth, @ServiceCenter, @Division, @MinDate, @MaxDate) WorkCompletedToUpdate
		LEFT JOIN SMWorkCompleted ON WorkCompletedToUpdate.SMWorkCompletedID = SMWorkCompleted.SMWorkCompletedID

	WorkCompletedToProcessLoop:
	BEGIN
		SELECT TOP 1 @SMWorkCompletedID = SMWorkCompletedID, @MonthToPostCost = MonthToPostCost, @ChangesMade = ChangesMade
		FROM @WorkCompletedToUpdate
		WHERE @SMWorkCompletedID IS NULL OR SMWorkCompletedID > @SMWorkCompletedID
		ORDER BY SMWorkCompletedID
		IF @@rowcount = 1
		BEGIN
			SET @BatchId = NULL
		
			BEGIN TRANSACTION
				
				--Find out if the work completed is already in a batch.
				SELECT @BatchId = BatchId
				FROM dbo.vSMMiscellaneousBatch 
				WHERE SMWorkCompletedID = @SMWorkCompletedID
				
				--If the work completed is already a part of a batch we always try to remove it because it may be in the wrong batch month or 
				--it may not need to be in a batch at all anymore.
				IF @@rowcount = 1
				BEGIN
					IF EXISTS(SELECT 1 FROM dbo.HQBC INNER JOIN dbo.vSMMiscellaneousBatch ON HQBC.Co = vSMMiscellaneousBatch.Co AND HQBC.Mth = vSMMiscellaneousBatch.Mth AND HQBC.BatchId = vSMMiscellaneousBatch.BatchId WHERE InUseBy IS NULL AND Source = @Source AND [Status] = 0)
					BEGIN
						DELETE dbo.vSMMiscellaneousBatch WHERE SMWorkCompletedID = @SMWorkCompletedID
							
						IF NOT EXISTS(SELECT 1 FROM @BatchesUpdated WHERE BatchId = @BatchId)
						BEGIN
							INSERT @BatchesUpdated
							VALUES (@BatchId, 0)
						END
					END
					ELSE
					BEGIN
						SET @msg = 'Work Completed was unable to be removed from another batch.'
						GOTO RollbackErrorFound
					END
				END

				IF @ChangesMade = 1
				BEGIN
					--If the work completed is already a part of a batch but the batch doesn't match the post month then we try to remove it.
					IF EXISTS(SELECT 1 FROM dbo.vSMMiscellaneousBatch WHERE SMWorkCompletedID = @SMWorkCompletedID AND Mth <> @MonthToPostCost)
					BEGIN
						IF EXISTS(SELECT 1 FROM dbo.HQBC INNER JOIN dbo.vSMMiscellaneousBatch ON HQBC.Co = vSMMiscellaneousBatch.Co AND HQBC.Mth = vSMMiscellaneousBatch.Mth AND HQBC.BatchId = vSMMiscellaneousBatch.BatchId WHERE InUseBy IS NULL AND Source = @Source AND [Status] = 0)
						BEGIN
							DELETE dbo.vSMMiscellaneousBatch WHERE SMWorkCompletedID = @SMWorkCompletedID
						END
						ELSE
						BEGIN
							SET @msg = 'Work Completed was unable to be removed from another batch.'
							GOTO RollbackErrorFound
						END
					END
			
					SELECT @BatchId = BatchId FROM dbo.HQBC WHERE Co = @SMCo AND Mth = @MonthToPostCost AND Source = @Source AND TableName = 'SMMiscellaneousBatch' AND InUseBy IS NULL AND Status = 0 AND CreatedBy = @CurrentUser
					IF @@rowcount = 0
					BEGIN
						EXEC @BatchId = dbo.bspHQBCInsert @co = @SMCo, @month = @MonthToPostCost, @source = @Source, @batchtable = 'SMMiscellaneousBatch', @restrict = 'Y', @adjust = 'N', @errmsg = @errortext output
						IF (@BatchId = 0)
						BEGIN
							SET @msg = 'Error creating batch: ' + dbo.vfToString(@errortext)
							GOTO RollbackErrorFound
						END
						
						INSERT @BatchesUpdated
						VALUES (@BatchId, 1)
					END
					ELSE
					BEGIN
						EXEC @rcode = dbo.vspSMGLPostingMiscSetInUse @Co = @SMCo, @mth = @MonthToPostCost, @BatchId = @BatchId, @InUse = 'Y', @InUseBy = @CurrentUser, @Source = @Source, @msg = @errortext
						IF (@rcode <> 0)
						BEGIN
							SET @msg = 'Unable to lock batch: ' + dbo.vfToString(@errortext)
							GOTO RollbackErrorFound
						END
	   					
						IF NOT EXISTS(SELECT 1 FROM @BatchesUpdated WHERE BatchId = @BatchId)
						BEGIN
							INSERT @BatchesUpdated
							VALUES (@BatchId, 0)
						END
					END

					/* Get the next BatchSeq number */
					SELECT @BatchSeq = ISNULL(MAX(BatchSeq), 0) + 1 FROM dbo.vSMMiscellaneousBatch WHERE Co = @SMCo AND Mth = @MonthToPostCost AND BatchId = @BatchId

					INSERT dbo.vSMMiscellaneousBatch (Co, Mth, BatchId, BatchSeq, SMWorkCompletedID)
					VALUES (@SMCo, @MonthToPostCost, @BatchId, @BatchSeq, @SMWorkCompletedID)
					
					SELECT @CostDetailID = CostDetailID, @BatchTransType = CASE WHEN IsDeleted = 1 THEN 'D' WHEN InitialCostsCaptured = 0 THEN 'A' ELSE 'C' END
					FROM dbo.vSMWorkCompleted
					WHERE SMWorkCompletedID = @SMWorkCompletedID
		
					IF @CostDetailID IS NULL
					BEGIN
						EXEC @rcode = dbo.vspHQDetailCreate @Source, @HQDetailID = @CostDetailID OUTPUT, @msg = @msg OUTPUT
						IF @rcode <> 0 RETURN 1
						
						UPDATE dbo.vSMWorkCompleted
						SET CostDetailID = @CostDetailID
						WHERE SMWorkCompletedID = @SMWorkCompletedID
					END
					
					--Always make sure the trans type is up to date because the user may have first modified
					--the work completed and it got added to the batch but then decided to delete the record.
					UPDATE dbo.vHQBatchLine
					SET BatchTransType = @BatchTransType
					WHERE Co = @SMCo AND Mth = @Mth AND BatchId = @BatchId AND HQDetailID = @CostDetailID
					IF @@rowcount = 0
					BEGIN
						INSERT dbo.vHQBatchLine (Co, Mth, BatchId, HQDetailID, BatchTransType)
						VALUES (@SMCo, @Mth, @BatchId, @CostDetailID, @BatchTransType)
					END
					
					EXEC @rcode = dbo.vspSMGLPostingMiscSetInUse @Co = @SMCo, @mth = @MonthToPostCost, @BatchId = @BatchId, @InUse = 'N', @InUseBy = @CurrentUser, @Source = @Source, @msg = @errortext
					IF (@rcode <> 0)
					BEGIN
						SET @msg = 'Unable to release batch: ' + dbo.vfToString(@errortext)
						GOTO RollbackErrorFound
					END
				END
			COMMIT TRANSACTION

			GOTO WorkCompletedToProcessLoop
		END
	END
	
	SET @msg = NULL
	
	SELECT @StringBuilder = dbo.vfSMBuildString(@StringBuilder, BatchId, ', ')
	FROM @BatchesUpdated 
	WHERE WasCreated = 1
	
	IF @@rowcount <> 0
	BEGIN
		SET @msg = 'SM Batch #' + @StringBuilder + ' created.'
	END

	SET @StringBuilder = NULL
	
	SELECT @StringBuilder = dbo.vfSMBuildString(@StringBuilder, BatchId, ', ')
	FROM @BatchesUpdated 
	WHERE WasCreated = 0
	
	IF @@rowcount <> 0
	BEGIN
		SET @msg = dbo.vfSMBuildString(@msg, 'SM Batch #' + @StringBuilder + ' updated.', CHAR(13) + CHAR(10))
	END
	
	IF @msg IS NULL SET @msg = 'No SM Batches created.'

	RETURN 0
	
RollbackErrorFound:
	--If an error is found then we need to properly handle the rollback
	--The assumption is if the transaction count = 1 then we are not in a nested
	--transaction and we can safely rollback. However, if the transaction count is greater than 1
	--then we are in a nested transaction and we need to make sure that the transaction count
	--when we entered the stored procedure matches the transaction count when we leave the stored procedure.
	--Then by returning 1 the rollback can be done from whatever sql executed this stored procedure.
	IF @@trancount = 1 ROLLBACK TRAN ELSE COMMIT TRAN
ErrorFound:
	RETURN 1
END
GO
GRANT EXECUTE ON  [dbo].[vspSMGLPostingMiscCreateBatch] TO [public]
GO
