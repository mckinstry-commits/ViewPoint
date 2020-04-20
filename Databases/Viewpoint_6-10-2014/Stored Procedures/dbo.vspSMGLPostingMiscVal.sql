SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspSMGLPostingMiscVal]
   /***********************************************************
    * Created:  ECV 03/30/11
    * Modified: TRL TK-13744 04/04/14 add to insert into SMJobCostDistribution
	*				TRL TK - 15053 removed @JCTransType Parameter for vspSMJobCostDetailInsert
	*				JVH 4/3/13 TFS-38853 Updated to handle changes to vSMJobCostDistribution
    *
    *
    * Validates a batch of GL records for Work Completed 
    * Miscellaneous records located in the vSMMiscellaneousBatch
    * table.
    *
    * GL Interface Levels:
    *	0      No update
    *	1      Summarize entries by GLCo#/GL Account
    *   2      Full detail
    *
    * INPUT PARAMETERS
    *   @SMCo           SM Co#
    *   @BatchMth            Posting Month
    *
    * OUTPUT PARAMETERS
    *   @BatchId		Batch ID used
    *   @msg            error message if something went wrong
    *
    * RETURN VALUE
    *   0               success
    *   1               fail
    *****************************************************/
(@SMCo bCompany, @BatchMth bMonth, @BatchId bBatchID, @Source bSource, @TableName varchar(20), @msg varchar(255) = NULL OUTPUT)
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @rcode int, @HQBatchDistributionID bigint, @GLLvl varchar(50), @GLJournal bJrnl, @GLDetlDesc varchar(60), @SMCoOffsetGLCo bCompany, @SMCoOffsetGLAcct bGLAcct 
	
	--Verify that the batch can be validated, set the batch status to validating and delete generic distributions
	EXEC @rcode = dbo.vspHQBatchValidating @BatchCo = @SMCo, @BatchMth = @BatchMth, @BatchId = @BatchId, @Source = @Source, @TableName = @TableName,@HQBatchDistributionID = @HQBatchDistributionID OUTPUT, @msg = @msg OUTPUT
	IF @rcode <> 0 RETURN @rcode
	
	SELECT @GLJournal = GLJrnl, @GLLvl = GLLvl, @GLDetlDesc = RTRIM(dbo.vfToString(GLDetlDesc)), @SMCoOffsetGLCo = MiscCostOffsetGLCo, @SMCoOffsetGLAcct = MiscCostOffsetGLAcct
	FROM dbo.vSMCO
	WHERE SMCo = @SMCo
	
	IF @GLJournal IS NULL AND @GLLvl <> 'NoUpdate'
	BEGIN
		SET @msg = 'GLJrnl may not be null in vSMCO for a Usage transaction'
		RETURN 1
	END

	/*Clear records from SMJostCostDistribution*/
	DELETE dbo.vSMJobCostDistribution
	WHERE BatchCo = @SMCo AND BatchMth = @BatchMth AND BatchID = @BatchId	
	
	/*Clear records currently being created by job related work orders*/
	EXEC @rcode = dbo.vspSMWorkCompletedBatchClear @BatchCo = @SMCo, @BatchMonth = @BatchMth, @BatchId = @BatchId, @msg = @msg OUTPUT
	IF @rcode <> 0 RETURN @rcode
	
	--Capture all the GL Entries to delete before we delete the distribution records
	DECLARE @SMGLEntriesToDelete TABLE (SMGLEntryID bigint)
	
	INSERT @SMGLEntriesToDelete
	SELECT SMGLEntriesToDelete.SMGLEntryID
	FROM dbo.vSMGLDistribution
		CROSS APPLY (
			SELECT SMGLEntryID
			UNION
			SELECT ReversingSMGLEntryID
		) SMGLEntriesToDelete
	WHERE SMCo = @SMCo AND BatchMonth = @BatchMth AND BatchId = @BatchId AND SMGLEntriesToDelete.SMGLEntryID IS NOT NULL
	
	--Clear GL distributions
	DELETE dbo.vSMGLDistribution
	WHERE SMCo = @SMCo AND BatchMonth = @BatchMth AND BatchId = @BatchId
	
	--Clear GL Entries
	DELETE dbo.vSMGLEntry
	WHERE SMGLEntryID IN (SELECT SMGLEntryID FROM @SMGLEntriesToDelete)
	
	DECLARE 
		@BatchSeq int, @SMWorkCompletedID bigint,
		@Amount bDollar, @ActDate bDate,
		@GLCo bCompany, @GLAcct bGLAcct,
		@OffsetGLCo bCompany, @OffsetGLAcct bGLAcct,
		@ARGLAcct bGLAcct, @APGLAcct bGLAcct,
		@TransDesc bTransDesc,
		@SMGLDistributionID bigint,
		@SMGLEntryID bigint, @SMGLDetailTransactionID bigint,
		@ReversingSMGLEntryID bigint,
		@ErrorText varchar(255)
	
	--Build the vSMDetailTransaction records and tie them to this batch
	EXEC @rcode = dbo.vspSMWorkCompletedValidate @BatchCo = @SMCo, @BatchMth = @BatchMth, @BatchId = @BatchId, @HQBatchDistributionID = @HQBatchDistributionID, @msg = @msg OUTPUT
	IF @rcode <> 0 RETURN @rcode
	
	DECLARE cBatch CURSOR LOCAL FAST_FORWARD FOR
	SELECT BatchSeq, SMWorkCompletedID
	FROM dbo.SMMiscellaneousBatch 
	WHERE Co = @SMCo AND Mth = @BatchMth AND BatchId = @BatchId

	OPEN cBatch
	
FetchNext:
	FETCH NEXT FROM cBatch
	INTO @BatchSeq, @SMWorkCompletedID

	IF @@FETCH_STATUS <> -1
	BEGIN
		SELECT @SMGLDistributionID = NULL, @SMGLEntryID = NULL, @SMGLDetailTransactionID = NULL, @ReversingSMGLEntryID = NULL
		
		SET @ErrorText = 'Seq#' + dbo.vfToString(@BatchSeq)
		
		IF NOT EXISTS(SELECT 1 FROM dbo.vSMWorkCompletedGL WHERE SMWorkCompletedID = @SMWorkCompletedID)
		BEGIN
			INSERT dbo.vSMWorkCompletedGL (SMWorkCompletedID, SMCo, IsMiscellaneousLineType)
			VALUES (@SMWorkCompletedID, @SMCo, 1)
		END

		INSERT dbo.vSMGLDistribution (SMWorkCompletedID, SMCo, BatchMonth, BatchId, CostOrRevenue, IsAccountTransfer)
		VALUES (@SMWorkCompletedID, @SMCo, @BatchMth, @BatchId, 'C', 0)
		
		SET @SMGLDistributionID = SCOPE_IDENTITY()
		
		SELECT @Amount = ISNULL(ActualCost, 0), @ActDate = [Date]
		FROM dbo.SMWorkCompleted
		WHERE SMWorkCompletedID = @SMWorkCompletedID
		IF @@rowcount <> 0
		BEGIN			
			SELECT @GLCo = GLCo, @GLAcct = CASE WHEN SMWorkOrderScope.IsTrackingWIP = 'Y' AND SMWorkOrderScope.IsComplete = 'N' THEN SMWorkCompleted.CostWIPAccount ELSE SMWorkCompleted.CostAccount END --If the scope is tracking wip and hasn't been completed then we use the wip account
			FROM dbo.SMWorkCompleted
				INNER JOIN dbo.SMWorkOrderScope ON SMWorkCompleted.SMCo = SMWorkOrderScope.SMCo AND SMWorkCompleted.WorkOrder = SMWorkOrderScope.WorkOrder AND SMWorkCompleted.Scope = SMWorkOrderScope.Scope
			WHERE SMWorkCompletedID = @SMWorkCompletedID
			
			/* validate the work completed glco */
			EXEC @rcode = dbo.bspGLCompanyVal @glco = @GLCo, @msg = @msg OUTPUT
			IF @rcode <> 0
			BEGIN
				SET @ErrorText = @ErrorText + ' ' + dbo.vfToString(@msg)
				EXEC @rcode = dbo.bspHQBEInsert @co = @SMCo, @mth = @BatchMth, @batchid = @BatchId, @errortext = @ErrorText, @errmsg = @msg OUTPUT
				IF @rcode <> 0 GOTO CursorCleanup
				GOTO FetchNext
			END
			
			-- Validate GL Company and Month
			IF EXISTS (SELECT 1 FROM dbo.vfGLClosedMonths(@Source, @BatchMth) WHERE GLCo = @GLCo AND IsMonthOpen = 0)		
			BEGIN
				SET @ErrorText = @ErrorText + ' Post Month not an open month'
				EXEC @rcode = dbo.bspHQBEInsert @co = @SMCo, @mth = @BatchMth, @batchid = @BatchId, @errortext = @ErrorText, @errmsg = @msg OUTPUT
				IF @rcode <> 0 GOTO CursorCleanup
				GOTO FetchNext
			END

			-- validate Fiscal Year 
			IF NOT EXISTS(SELECT 1 FROM dbo.bGLFY WHERE GLCo = @GLCo AND @BatchMth >= BeginMth AND @BatchMth <= FYEMO)
			BEGIN
				SET @ErrorText = @ErrorText + ' Must first add Fiscal Year'
				EXEC @rcode = dbo.bspHQBEInsert @co = @SMCo, @mth = @BatchMth, @batchid = @BatchId, @errortext = @ErrorText, @errmsg = @msg OUTPUT
				IF @rcode <> 0 GOTO CursorCleanup
				GOTO FetchNext
			END
			
			/* Validate GLCo and GLAcct */
			EXEC @rcode = dbo.bspGLACfPostable @GLCo, @GLAcct, 'S', @msg OUTPUT
			IF @rcode <> 0
			BEGIN
				SET @ErrorText = @ErrorText + ' GL Account ' + dbo.vfToString(@msg)
				EXEC @rcode = dbo.bspHQBEInsert @co = @SMCo, @mth = @BatchMth, @batchid = @BatchId, @errortext = @ErrorText, @errmsg = @msg OUTPUT
				IF @rcode <> 0 GOTO CursorCleanup
				GOTO FetchNext
			END
			
			IF @GLJournal IS NOT NULL
			BEGIN
				EXEC @rcode = dbo.bspGLJrnlVal @glco = @GLCo, @jrnl = @GLJournal, @msg = @msg OUTPUT
				IF @rcode <> 0
				BEGIN
					SET @ErrorText = @ErrorText + ' ' + dbo.vfToString(@msg)
   					EXEC @rcode = dbo.bspHQBEInsert @co = @SMCo, @mth = @BatchMth, @batchid = @BatchId, @errortext = @ErrorText, @errmsg = @msg OUTPUT
   					IF @rcode <> 0 GOTO CursorCleanup
					GOTO FetchNext
				END
			END
			
			/* Sets the Offset GL Acct from the Standard Item if available otherwise set it to the SM Company Offset GL Acct */
			SELECT @OffsetGLCo = SMStandardItem.MiscCostOffsetGLCo,
				   @OffsetGLAcct = SMStandardItem.MiscCostOffsetGLAcct
			FROM dbo.SMWorkCompleted 
				INNER JOIN SMStandardItem ON SMWorkCompleted.SMCo = SMStandardItem.SMCo AND 
											 SMWorkCompleted.StandardItem = SMStandardItem.StandardItem
			WHERE SMWorkCompleted.SMWorkCompletedID = @SMWorkCompletedID AND
				  SMStandardItem.MiscCostOffsetGLCo IS NOT NULL AND
				  SMStandardItem.MiscCostOffsetGLAcct IS NOT NULL
			IF @@rowcount <> 1
			BEGIN 
				SELECT @OffsetGLCo = @SMCoOffsetGLCo, @OffsetGLAcct = @SMCoOffsetGLAcct
			END
			
			/* Validate OffsetGLCo / OffsetGLAcct */
			EXEC @rcode = dbo.bspGLACfPostable @OffsetGLCo, @OffsetGLAcct, 'S', @msg OUTPUT
			IF @rcode <> 0
			BEGIN
				SET @ErrorText = @ErrorText + ' Offset GL Account ' + @msg
				EXEC @rcode = dbo.bspHQBEInsert @co = @SMCo, @mth = @BatchMth, @batchid = @BatchId, @errortext = @ErrorText, @errmsg = @msg OUTPUT
				IF @rcode <> 0 GOTO CursorCleanup
				GOTO FetchNext
			END

			IF (@GLCo <> @OffsetGLCo)
			BEGIN
				/* validate the form company glco */
				EXEC @rcode = dbo.bspGLCompanyVal @glco = @OffsetGLCo, @msg = @msg OUTPUT
				IF @rcode <> 0
				BEGIN
					SET @ErrorText = @ErrorText + ' ' + dbo.vfToString(@msg)
   					EXEC @rcode = dbo.bspHQBEInsert @co = @SMCo, @mth = @BatchMth, @batchid = @BatchId, @errortext = @ErrorText, @errmsg = @msg OUTPUT
   					IF @rcode <> 0 GOTO CursorCleanup
					GOTO FetchNext
				END
				
				-- Validate offset GL Company and Month
				IF EXISTS (SELECT 1 FROM dbo.vfGLClosedMonths(@Source, @BatchMth) WHERE GLCo = @OffsetGLCo AND IsMonthOpen = 0)		
				BEGIN
					SET @ErrorText = @ErrorText + ' Post Month not an open month'
   					EXEC @rcode = dbo.bspHQBEInsert @co = @SMCo, @mth = @BatchMth, @batchid = @BatchId, @errortext = @ErrorText, @errmsg = @msg OUTPUT
   					IF @rcode <> 0 GOTO CursorCleanup
					GOTO FetchNext
				END

				-- validate offset Fiscal Year 
				IF NOT EXISTS(SELECT 1 FROM dbo.bGLFY WHERE GLCo = @OffsetGLCo AND @BatchMth >= BeginMth AND @BatchMth <= FYEMO)
				BEGIN
					SET @ErrorText = @ErrorText + ' Must first add Fiscal Year'
   					EXEC @rcode = dbo.bspHQBEInsert @co = @SMCo, @mth = @BatchMth, @batchid = @BatchId, @errortext = @ErrorText, @errmsg = @msg OUTPUT
   					IF @rcode <> 0 GOTO CursorCleanup
					GOTO FetchNext
				END
				
				IF @GLJournal IS NOT NULL
				BEGIN
					EXEC @rcode = dbo.bspGLJrnlVal @glco = @GLCo, @jrnl = @GLJournal, @msg = @msg OUTPUT
					IF @rcode <> 0
					BEGIN
						SET @ErrorText = @ErrorText + ' ' + dbo.vfToString(@msg)
   						EXEC @rcode = dbo.bspHQBEInsert @co = @SMCo, @mth = @BatchMth, @batchid = @BatchId, @errortext = @ErrorText, @errmsg = @msg OUTPUT
   						IF @rcode <> 0 GOTO CursorCleanup
						GOTO FetchNext
					END
				END
			
				/* Check to see if intercompany accounts are setup */
				EXEC @rcode = dbo.bspGLDBInterCoVal @GLCo, @BatchMth, NULL, NULL, @OffsetGLCo, @msg OUTPUT
				IF @rcode = 1
				BEGIN
					SET @ErrorText = @ErrorText + ' ' + dbo.vfToString(@msg)
   					EXEC @rcode = dbo.bspHQBEInsert @co = @SMCo, @mth = @BatchMth, @batchid = @BatchId, @errortext = @ErrorText, @errmsg = @msg OUTPUT
   					IF @rcode <> 0 GOTO CursorCleanup
					GOTO FetchNext
				END

   				-- get interco GL Accounts
   				SELECT @ARGLAcct = ARGLAcct, @APGLAcct = APGLAcct
   				FROM dbo.bGLIA
   				WHERE ARGLCo = @GLCo AND APGLCo = @OffsetGLCo
   				IF @@rowcount = 0
   				BEGIN
   					SET @ErrorText = @ErrorText + ' Intercompany Accounts not setup in GL for these companies!'
   					EXEC @rcode = dbo.bspHQBEInsert @co = @SMCo, @mth = @BatchMth, @batchid = @BatchId, @errortext = @ErrorText, @errmsg = @msg OUTPUT
   					IF @rcode <> 0 GOTO CursorCleanup
					GOTO FetchNext
   				END
			   
   				-- validate Intercompany AR GL Account
   				EXEC @rcode = dbo.bspGLACfPostable @GLCo, @ARGLAcct, NULL, @msg OUTPUT
   				IF @rcode <> 0
   				BEGIN
   					SET @ErrorText = @ErrorText + ' Intercompany Account ' + dbo.vfToString(@msg)
   					EXEC @rcode = dbo.bspHQBEInsert @co = @SMCo, @mth = @BatchMth, @batchid = @BatchId, @errortext = @ErrorText, @errmsg = @msg OUTPUT
   					IF @rcode <> 0 GOTO CursorCleanup
					GOTO FetchNext
   				END
			   
   				-- validate Intercompany AP GL Account
   				EXEC @rcode = dbo.bspGLACfPostable @OffsetGLCo, @APGLAcct, NULL, @msg OUTPUT
   				IF @rcode <> 0
   				BEGIN
   					SET @ErrorText = @ErrorText + ' Intercompany Account ' + dbo.vfToString(@msg)
   					EXEC @rcode = dbo.bspHQBEInsert @co = @SMCo, @mth = @BatchMth, @batchid = @BatchId, @errortext = @ErrorText, @errmsg = @msg OUTPUT
   					IF @rcode <> 0 GOTO CursorCleanup
					GOTO FetchNext
   				END
   			END

			SELECT @TransDesc = @GLDetlDesc,
					@TransDesc = REPLACE(@TransDesc, 'SM Company', dbo.vfToString(@SMCo)),
					@TransDesc = REPLACE(@TransDesc, 'Work Order', dbo.vfToString((SELECT WorkOrder FROM dbo.SMWorkCompleted WHERE SMWorkCompletedID = @SMWorkCompletedID))),
					@TransDesc = REPLACE(@TransDesc, 'Scope', dbo.vfToString((SELECT Scope FROM dbo.SMWorkCompleted WHERE SMWorkCompletedID = @SMWorkCompletedID))),
					@TransDesc = REPLACE(@TransDesc, 'Line Type', '3'),  --1 is the Miscellaneous Line type
					@TransDesc = REPLACE(@TransDesc, 'Line Sequence', dbo.vfToString((SELECT WorkCompleted FROM dbo.SMWorkCompleted WHERE SMWorkCompletedID = @SMWorkCompletedID)))
					
			INSERT dbo.vSMGLEntry (SMWorkCompletedID, Journal)
			VALUES (@SMWorkCompletedID, @GLJournal)
			
			SET @SMGLEntryID = SCOPE_IDENTITY()
			
			UPDATE dbo.vSMGLDistribution
			SET SMGLEntryID = @SMGLEntryID
			WHERE SMGLDistributionID = @SMGLDistributionID

			IF (@GLCo <> @OffsetGLCo)
			BEGIN
				--We need to insert the distributions so they balance
				INSERT INTO dbo.vSMGLDetailTransaction (SMGLEntryID, IsTransactionForSMDerivedAccount, GLCo, GLAccount, Amount, ActDate, [Description])
				SELECT @SMGLEntryID, 0, @OffsetGLCo, @APGLAcct, @Amount, @ActDate, @TransDesc			
				UNION ALL
				SELECT @SMGLEntryID, 0, @GLCo, @ARGLAcct, -@Amount, @ActDate, @TransDesc
				UNION ALL
				SELECT @SMGLEntryID, 0, @OffsetGLCo, @OffsetGLAcct, -@Amount, @ActDate, @TransDesc			
				UNION ALL
				SELECT @SMGLEntryID, 1, @GLCo, @GLAcct, @Amount, @ActDate, @TransDesc
			END
			ELSE
			BEGIN
				--We need to insert the distributions so they balance
				INSERT INTO dbo.vSMGLDetailTransaction (SMGLEntryID, IsTransactionForSMDerivedAccount, GLCo, GLAccount, Amount, ActDate, [Description])
				SELECT @SMGLEntryID, 0, @OffsetGLCo, @OffsetGLAcct, -@Amount, @ActDate, @TransDesc			
				UNION ALL
				SELECT @SMGLEntryID, 1, @GLCo, @GLAcct, @Amount, @ActDate, @TransDesc
			END
			
			--The last record entered should be the work completed record's entry
			SET @SMGLDetailTransactionID = SCOPE_IDENTITY()
			
			UPDATE dbo.vSMGLDistribution
			SET SMGLDetailTransactionID = @SMGLDetailTransactionID
			WHERE SMGLDistributionID = @SMGLDistributionID
		END

		IF EXISTS(SELECT 1 FROM dbo.vSMWorkCompletedGL WHERE SMWorkCompletedID = @SMWorkCompletedID AND CostGLEntryID IS NOT NULL)
		BEGIN
			INSERT dbo.vSMGLEntry (SMWorkCompletedID, Journal)
			SELECT @SMWorkCompletedID, ISNULL((SELECT Journal FROM dbo.vSMWorkCompletedGL INNER JOIN dbo.vSMGLEntry ON vSMWorkCompletedGL.CostGLEntryID = vSMGLEntry.SMGLEntryID WHERE vSMWorkCompletedGL.SMWorkCompletedID = @SMWorkCompletedID), @GLJournal)
			
			SET @ReversingSMGLEntryID = SCOPE_IDENTITY()
		
			UPDATE dbo.vSMGLDistribution
			SET ReversingSMGLEntryID = @ReversingSMGLEntryID
			WHERE SMGLDistributionID = @SMGLDistributionID
			
			--Reversing data comes from vfSMBuildReversingTransactions
			INSERT INTO dbo.vSMGLDetailTransaction (SMGLEntryID, IsTransactionForSMDerivedAccount, GLCo, GLAccount, Amount, ActDate, [Description])
			SELECT @ReversingSMGLEntryID, IsTransactionForSMDerivedAccount, GLCo, GLAccount, Amount, ActDate, [Description]
			FROM dbo.vfSMBuildReversingTransactions(@SMWorkCompletedID)
		END
		
		/*START JOB DISTRIBUTION INSERT*/
		EXEC @rcode = dbo.vspSMJobCostDistributionInsert @SMWorkCompletedID=@SMWorkCompletedID, @BatchCo=@SMCo,@BatchMth=@BatchMth,@BatchId = @BatchId, @BatchSeq = @BatchSeq, @JCTransType='MI',@errmsg = @msg OUTPUT
		IF @rcode <> 0 
		BEGIN
				SET @ErrorText = @ErrorText + ' - ' + dbo.vfToString(@msg)
				EXEC @rcode = dbo.bspHQBEInsert @co = @SMCo, @mth = @BatchMth, @batchid = @BatchId, @errortext = @ErrorText, @errmsg = @msg OUTPUT
				IF @rcode <> 0 GOTO CursorCleanup
				GOTO FetchNext
		ENd
		/*END JOB DISTRIBUTION INSERT*/
		GOTO FetchNext
	END

	--We didn't have any critical errors if we hit this point so we will
	--continue validating
	SET @rcode = 0

CursorCleanup:
	CLOSE cBatch
	DEALLOCATE cBatch
	
	--We jumped out because we were unable to log errors
	IF @rcode = 1 GOTO ErrorFound
	
	--If we logged any errors we need to indicate that the batch failed
	IF EXISTS(SELECT 1 FROM dbo.bHQBE WHERE Co = @SMCo AND Mth = @BatchMth AND BatchId = @BatchId) GOTO ErrorFound

	UPDATE dbo.bHQBC 
	SET [Status] = 3
	WHERE Co = @SMCo AND Mth = @BatchMth AND BatchId = @BatchId

	RETURN 0

ErrorFound:
	UPDATE dbo.bHQBC 
	SET [Status] = 2
	WHERE Co = @SMCo AND Mth = @BatchMth AND BatchId = @BatchId
		
	RETURN 1
END
GO
GRANT EXECUTE ON  [dbo].[vspSMGLPostingMiscVal] TO [public]
GO
