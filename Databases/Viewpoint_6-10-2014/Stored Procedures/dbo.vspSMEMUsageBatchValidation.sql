SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 2/15/2011
-- Description:	Validation for the EM usage batches created by SM
-- Modified:   TRL 2/17/2012 Added code to insert SM Job Cost Distributions
--				  TRL TK-15053 added @JCTransType Parameter for vspSMJobCostDistributionInsert
--				JVH 4/3/13 TFS-38853 Updated to handle changes to vSMJobCostDistribution
-- =============================================
CREATE PROCEDURE [dbo].[vspSMEMUsageBatchValidation]
	@SMCo bCompany, @BatchMth bMonth, @BatchId bBatchID, @Source bSource, @TableName varchar(20), @msg varchar(255) = NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @rcode int, @HQBatchDistributionID bigint, @GLLvl varchar(50), @GLJournal bJrnl, @GLDetlDesc varchar(60)

	--Verify that the batch can be validated, set the batch status to validating and delete generic distributions
	EXEC @rcode = dbo.vspHQBatchValidating @BatchCo = @SMCo, @BatchMth = @BatchMth, @BatchId = @BatchId, @Source = @Source, @TableName = @TableName, @HQBatchDistributionID = @HQBatchDistributionID OUTPUT, @msg = @msg OUTPUT
	IF @rcode <> 0 RETURN @rcode
	
	SELECT @GLJournal = GLJrnl, @GLLvl = GLLvl, @GLDetlDesc = RTRIM(dbo.vfToString(GLDetlDesc))
	FROM dbo.vSMCO
	WHERE SMCo = @SMCo
	
	IF @GLJournal IS NULL AND @GLLvl <> 'NoUpdate'
	BEGIN
		SET @msg = 'GLJrnl may not be null in vSMCO for a Usage transaction'
		RETURN 1
	END
	
	--Clear revenue breakdown distributions
	DELETE dbo.vSMEMUsageBreakdownDistribution
	WHERE SMCo = @SMCo AND Mth = @BatchMth AND BatchId = @BatchId
	
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
		--Cursor variables
		@SMWorkCompletedID bigint, @WorkOrder int,
		@BatchSeq int, @IsReversingEntry bit, @BatchTransType char(1),
		@EMCo bCompany, @EMTrans bTrans, @EMGroup bGroup, @Equipment bEquip,
		@RevCode bRevCode,
		@GLCo bCompany, @GLAcct bGLAcct,
		@OffsetGLCo bCompany, @OffsetGLAcct bGLAcct,
		@Category bCat, @RevBasis char(1), @TimeUM bUM, @TimeUnits bUnits, @WorkUM bUM, @WorkUnits bUnits, @Dollars bDollar, @RevRate bDollar, @ActualDate bDate,
		--Variables used in sproc
		@Department bDept,
		@TransDesc bTransDesc,
		@ARGLAcct bGLAcct, @APGLAcct bGLAcct,
		@BaseRate bDollar,
		@RevBdownCode varchar(10), @RevBdownRate bDollar, @BDownGLCo bCompany, @BDownGLAcct bGLAcct,
		@CurrentKeyID int,
		@BreakdownTotal bDollar,
		@SMGLDistributionID bigint, @SMGLEntryID bigint, @ValidationGLCo bCompany, @ValidationGLAcct bGLAcct, @SubType char(1), @SMGLDetailTransactionID bigint,
		@ErrorText varchar(255)
		        
	--CREATE TABLE VARIABLES USED FOR BUILDING GL DISTRIBUTIONS AND REVENUE BREAKDOWNS
	DECLARE @RevBreakDowns TABLE (RevBdownCode varchar(10), Rate bDollar, GLCo bCompany NULL, GLAcct bGLAcct NULL, Total bDollar NULL, KeyID int identity(1,1))
	
	DECLARE @BatchRevenueBreakdowns TABLE (BatchSeq int, EMCo bCompany, EMGroup bGroup, RevBdownCode varchar(10), Equipment bEquip, RevCode bRevCode, Total bDollar)
	
	DECLARE @GLDistributions TABLE (SMGLEntryID bigint, IsTransactionForSMDerivedAccount bit, GLCo bCompany, GLAccount bGLAcct, Amount bDollar, ActDate bDate, [Description] bTransDesc, SubType char(1) NULL)

	--Check to make sure all the work completed associated with the batch is in the SMEMUsageBatch
	--If it is not then that would indicate an issue with the view definition 
	--or not associating work completed to the correct batch or bad data.
	IF EXISTS(
		SELECT 1 
		FROM dbo.vSMWorkCompletedBatch 
			LEFT JOIN dbo.SMEMUsageBatch ON vSMWorkCompletedBatch.SMWorkCompletedID = SMEMUsageBatch.SMWorkCompletedID
		WHERE vSMWorkCompletedBatch.BatchCo = @SMCo AND vSMWorkCompletedBatch.BatchMonth = @BatchMth AND vSMWorkCompletedBatch.BatchId = @BatchId AND SMEMUsageBatch.SMWorkCompletedID IS NULL)
	BEGIN
		SET @msg = 'There is an issue with your batch''s data. Please contact support.'
		RETURN 1
	END

	--Build the vSMDetailTransaction records and tie them to this batch
	EXEC @rcode = dbo.vspSMWorkCompletedValidate @BatchCo = @SMCo, @BatchMth = @BatchMth, @BatchId = @BatchId, @HQBatchDistributionID = @HQBatchDistributionID, @msg = @msg OUTPUT
	IF @rcode <> 0 RETURN @rcode

	DECLARE vcSMEMUsageBatch CURSOR LOCAL FAST_FORWARD FOR
	WITH SMEMUsageCTE 
	AS
	(
		SELECT *
		FROM dbo.SMEMUsageBatch
		WHERE Co = @SMCo AND BatchMonth = @BatchMth AND BatchId = @BatchId
	)
	SELECT
		SMWorkCompletedID, WorkOrder, BatchSeq, 0 AS ReversingEntry, BatchTransType,
		EMCo, EMGroup, Equipment,
		RevCode,
		GLCo, GLAcct, 
		OffsetGLCo, OffsetGLAcct,
		Category, RevBasis, TimeUM, TimeUnits, WorkUM, WorkUnits, Dollars, RevRate, ActualDate
	FROM SMEMUsageCTE
	WHERE BatchTransType IN ('A','C')
	UNION ALL
	SELECT
		SMWorkCompletedID, WorkOrder, BatchSeq, 1 AS ReversingEntry, BatchTransType,
		OldEMCo, OldEMGroup, OldEquipment,
		OldRevCode,
		OldGLCo, OldGLAcct, 
		OldOffsetGLCo, OldOffsetGLAcct,
		OldCategory, OldRevBasis, OldTimeUM, OldTimeUnits, OldWorkUM, OldWorkUnits, OldDollars, OldRevRate, OldActualDate
	FROM SMEMUsageCTE
	WHERE BatchTransType IN ('C','D')

	OPEN vcSMEMUsageBatch
	
FetchNext:
	FETCH NEXT FROM vcSMEMUsageBatch
	INTO @SMWorkCompletedID, @WorkOrder, @BatchSeq, @IsReversingEntry, @BatchTransType,
		@EMCo, @EMGroup, @Equipment,
		@RevCode,
		@GLCo, @GLAcct,
		@OffsetGLCo, @OffsetGLAcct,
		@Category, @RevBasis, @TimeUM, @TimeUnits, @WorkUM, @WorkUnits, @Dollars, @RevRate, @ActualDate
		
	IF @@FETCH_STATUS <> -1
	BEGIN
		SET @ErrorText = 'Seq#' + dbo.vfToString(@BatchSeq)

		IF @IsReversingEntry = 0
		BEGIN
			/* validate the equipment and retrieve other important info while we are there */
			SELECT @Department = Department
			FROM dbo.bEMEM 
			WHERE EMCo = @EMCo and Equipment = @Equipment AND [Status] IN ('A', 'D')
			IF @@rowcount = 0
			BEGIN
				SET @ErrorText = @ErrorText + ' - invalid equipment!'
				EXEC @rcode = dbo.bspHQBEInsert @co = @SMCo, @mth = @BatchMth, @batchid = @BatchId, @errortext = @ErrorText, @errmsg = @msg OUTPUT
				IF @rcode <> 0 GOTO CursorCleanup
				GOTO FetchNext
			END
			
			/* validate the department */
			IF @Department IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.EMDM WHERE EMCo = @EMCo AND Department = @Department)
			IF @rcode <> 0
			BEGIN
				SET @ErrorText = @ErrorText + ' Department ' + dbo.vfToString(@Department) + ' is invalid on equipment ' + dbo.vfToString(@Equipment)
				EXEC @rcode = dbo.bspHQBEInsert @co = @SMCo, @mth = @BatchMth, @batchid = @BatchId, @errortext = @ErrorText, @errmsg = @msg OUTPUT
				IF @rcode <> 0 GOTO CursorCleanup
				GOTO FetchNext
			END

			/* validate Units of Measure */
			/* unit based requirements */
			IF @RevBasis = 'U'
			BEGIN
				IF @WorkUM IS NULL
				BEGIN
					SET @ErrorText = @ErrorText + ' - Work unit of measure required!'
					EXEC @rcode = dbo.bspHQBEInsert @co = @SMCo, @mth = @BatchMth, @batchid = @BatchId, @errortext = @ErrorText, @errmsg = @msg OUTPUT
					IF @rcode <> 0 GOTO CursorCleanup
					GOTO FetchNext
				END
			END
			ELSE IF @RevBasis = 'H'
			BEGIN
				IF @TimeUM IS NULL
				BEGIN
					SET @ErrorText = @ErrorText + ' - Time unit of measure required!'
					EXEC @rcode = dbo.bspHQBEInsert @co = @SMCo, @mth = @BatchMth, @batchid = @BatchId, @errortext = @ErrorText, @errmsg = @msg OUTPUT
					IF @rcode <> 0 GOTO CursorCleanup
					GOTO FetchNext
				END
			END
		END
		
		/* validate the category */
		EXEC @rcode = dbo.bspEMCategoryVal @emco = @EMCo, @Category = @Category, @msg = @msg OUTPUT
		IF @rcode <> 0
		BEGIN
			SET @ErrorText = @ErrorText + ' ' + dbo.vfToString(@msg)
			EXEC @rcode = dbo.bspHQBEInsert @co = @SMCo, @mth = @BatchMth, @batchid = @BatchId, @errortext = @ErrorText, @errmsg = @msg OUTPUT
			IF @rcode <> 0 GOTO CursorCleanup
			GOTO FetchNext
		END
		
		---- Validate RevCode in EMRR based upon Category of Used/Usage Equipment #128555
		IF NOT EXISTS(SELECT 1 FROM dbo.EMRR WHERE EMCo = @EMCo AND RevCode = @RevCode AND EMGroup = @EMGroup AND Category = @Category)
		BEGIN
			SET @ErrorText = @ErrorText + ' Revenue code: ' + dbo.vfToString(@RevCode) + ' must be setup in Revenue Rates by Category.'			
			EXEC @rcode = dbo.bspHQBEInsert @co = @SMCo, @mth = @BatchMth, @batchid = @BatchId, @errortext = @ErrorText, @errmsg = @msg OUTPUT
			IF @rcode <> 0 GOTO CursorCleanup
			GOTO FetchNext
		END

		/* validate the form company glco */
		EXEC @rcode = dbo.bspGLCompanyVal @glco = @GLCo, @msg = @msg OUTPUT
		IF @rcode <> 0
		BEGIN
			SET @ErrorText = @ErrorText + ' ' + dbo.vfToString(@msg)
			EXEC @rcode = dbo.bspHQBEInsert @co = @SMCo, @mth = @BatchMth, @batchid = @BatchId, @errortext = @ErrorText, @errmsg = @msg OUTPUT
			IF @rcode <> 0 GOTO CursorCleanup
			GOTO FetchNext
		END
		
		--Make sure the month hasn't been closed yet
		IF EXISTS(SELECT 1 FROM dbo.bGLCO WHERE GLCo = @GLCo AND @BatchMth <= LastMthSubClsd)
		BEGIN
			SET @ErrorText = @ErrorText + ' Month is closed in GL Company ' + dbo.vfToString(@GLCo)
			EXEC @rcode = dbo.bspHQBEInsert @co = @SMCo, @mth = @BatchMth, @batchid = @BatchId, @errortext = @ErrorText, @errmsg = @msg OUTPUT
			IF @rcode <> 0 GOTO CursorCleanup
			GOTO FetchNext
		END
		
		IF @GLJournal IS NOT NULL
		BEGIN
			EXEC @rcode = dbo.bspGLJrnlVal @glco = @GLCo, @jrnl = @GLJournal, @msg = @msg OUTPUT
			IF @rcode <> 0
			BEGIN
				SET @ErrorText = @ErrorText + ' ' + @msg
				EXEC @rcode = dbo.bspHQBEInsert @co = @SMCo, @mth = @BatchMth, @batchid = @BatchId, @errortext = @ErrorText, @errmsg = @msg OUTPUT
				IF @rcode <> 0 GOTO CursorCleanup
				GOTO FetchNext
			END
		END

		--Inter company accounting needs to be handled
		IF @GLCo <> @OffsetGLCo
		BEGIN
			--Make sure the month hasn't been closed yet
			IF EXISTS(SELECT 1 FROM dbo.bGLCO WHERE GLCo = @OffsetGLCo AND @BatchMth <= LastMthSubClsd)
			BEGIN
				SET @ErrorText = @ErrorText + ' Month is closed in GL Company ' + dbo.vfToString(@OffsetGLCo)
				EXEC @rcode = dbo.bspHQBEInsert @co = @SMCo, @mth = @BatchMth, @batchid = @BatchId, @errortext = @ErrorText, @errmsg = @msg OUTPUT
				IF @rcode <> 0 GOTO CursorCleanup
				GOTO FetchNext
			END
			
			IF @GLJournal IS NOT NULL
			BEGIN
				EXEC @rcode = dbo.bspGLJrnlVal @glco = @OffsetGLCo, @jrnl = @GLJournal, @msg = @msg OUTPUT
				IF @rcode <> 0
				BEGIN
					SET @ErrorText = @ErrorText + ' ' + @msg
					EXEC @rcode = dbo.bspHQBEInsert @co = @SMCo, @mth = @BatchMth, @batchid = @BatchId, @errortext = @ErrorText, @errmsg = @msg OUTPUT
					IF @rcode <> 0 GOTO CursorCleanup
					GOTO FetchNext
				END
			END
		
			SELECT @ARGLAcct = ARGLAcct, @APGLAcct = APGLAcct
			FROM dbo.bGLIA
			WHERE ARGLCo = @GLCo AND APGLCo = @OffsetGLCo
			
			IF @ARGLAcct IS NULL OR @APGLAcct IS NULL
			BEGIN
				SET @ErrorText = @ErrorText + '- Missing cross company gl account(s)! Please setup in GL Intercompany accounts for Receivable GL Company ' + dbo.vfToString(@GLCo) + ' and Payable GL Company ' + dbo.vfToString(@OffsetGLCo)
				EXEC @rcode = dbo.bspHQBEInsert @co = @SMCo, @mth = @BatchMth, @batchid = @BatchId, @errortext = @ErrorText, @errmsg = @msg OUTPUT
				IF @rcode <> 0 GOTO CursorCleanup
				GOTO FetchNext
			END
		END

		IF @WorkUM IS NOT NULL
		BEGIN
			EXEC @rcode = dbo.bspHQUMVal @um = @WorkUM, @msg = @msg OUTPUT
			IF @rcode <> 0
			BEGIN
				SET @ErrorText = @ErrorText + ' ' + dbo.vfToString(@msg)
				EXEC @rcode = dbo.bspHQBEInsert @co = @SMCo, @mth = @BatchMth, @batchid = @BatchId, @errortext = @ErrorText, @errmsg = @msg OUTPUT
				IF @rcode <> 0 GOTO CursorCleanup
				GOTO FetchNext
			END
		END

		IF @TimeUM IS NOT NULL
		BEGIN
			EXEC @rcode = dbo.bspHQUMVal @um = @TimeUM, @msg = @msg OUTPUT
			IF @rcode <> 0
			BEGIN
				SET @ErrorText = @ErrorText + ' ' + dbo.vfToString(@msg)
				EXEC @rcode = dbo.bspHQBEInsert @co = @SMCo, @mth = @BatchMth, @batchid = @BatchId, @errortext = @ErrorText, @errmsg = @msg OUTPUT
				IF @rcode <> 0 GOTO CursorCleanup
				GOTO FetchNext
			END
		END

		/*BEGIN REVENUE BREAKDOWN PROCESSING*/
		/* build the EMBC table for EMRB distirbutions and, potentially, GLDT distirbution */
		/* if a problem occurs in this bsp it will be written to the hqbe table within */
		IF @IsReversingEntry = 0
		BEGIN
			--Clear the records from the previous batch record
			DELETE @RevBreakDowns
		
			SELECT @BaseRate = Rate
			FROM dbo.bEMRH
			WHERE EMCo = @EMCo AND EMGroup = @EMGroup AND Equipment = @Equipment AND RevCode = @RevCode AND ORideRate = 'Y'
			IF @@rowcount = 1
			BEGIN
				--The RevCode is defined at the equipment level and overrides the rates therefore we grab the breakdown for the equipment
				INSERT INTO @RevBreakDowns (RevBdownCode, Rate)
				SELECT RevBdownCode, Rate
				FROM dbo.bEMBE
				WHERE EMCo = @EMCo AND EMGroup = @EMGroup AND Equipment = @Equipment AND RevCode = @RevCode
			END
			ELSE
			BEGIN
				SELECT @BaseRate = Rate
				FROM dbo.bEMRR
				WHERE EMCo = @EMCo AND EMGroup = @EMGroup AND Category = @Category AND RevCode = @RevCode
				IF @@rowcount = 1
				BEGIN
					--The RevCode was not defined at the equipment level but was at the category level so we use the category breakdown
					INSERT INTO @RevBreakDowns (RevBdownCode, Rate)
					SELECT RevBdownCode, Rate
					FROM dbo.bEMBG
					WHERE EMCo = @EMCo AND EMGroup = @EMGroup AND Category = @Category AND RevCode = @RevCode
				END
				ELSE
				BEGIN
					--The RevCode was not defined at the equipment or category level so we don't have enough setup to continue
					SET @ErrorText = 'There are no revenue breakdown code rates set up by equipment or category for equipment ' + dbo.vfToString(@Equipment)
					EXEC @rcode = dbo.bspHQBEInsert @co = @SMCo, @mth = @BatchMth, @batchid = @BatchId, @errortext = @ErrorText, @errmsg = @msg OUTPUT
					IF @rcode <> 0 GOTO CursorCleanup
					GOTO FetchNext
				END
			END
			
			--Update the GL accounts for each of the revenue break down codes
			UPDATE RevBreakDowns
			SET RevBreakDowns.GLCo = bEMDB.GLCo, RevBreakDowns.GLAcct = bEMDB.GLAcct
			FROM @RevBreakDowns RevBreakDowns
				INNER JOIN dbo.bEMDB ON RevBreakDowns.RevBdownCode = bEMDB.RevBdownCode
			WHERE EMCo = @EMCo AND Department = @Department AND EMGroup = @EMGroup

			SET @CurrentKeyID = 0

			RevBreakDownLoop:
			BEGIN
				SELECT TOP 1 @RevBdownCode = RevBdownCode, @RevBdownRate = Rate, @BDownGLCo = GLCo, @BDownGLAcct = GLAcct, @CurrentKeyID = KeyID
				FROM @RevBreakDowns
				WHERE KeyID > @CurrentKeyID
				ORDER BY KeyID
				IF @@rowcount = 1
				BEGIN
					--Ensure that if we are planning on posting to GL that have an account to use for the breakdown code
					IF @GLAcct IS NULL
					BEGIN
						IF @BDownGLCo IS NULL OR @BDownGLAcct IS NULL
						BEGIN
							SET @ErrorText = @ErrorText + ' - RevBdownCode ' + dbo.vfToString(@RevBdownCode) + ' for revenue code ' + dbo.vfToString(@RevCode) + ' is not set up in department ' + dbo.vfToString(@Department) + ' for equipment ' + dbo.vfToString(@Equipment) + '. Please add an entry to the Revenue Breakdown Code in the EM Department form.'
							EXEC @rcode = dbo.bspHQBEInsert @co = @SMCo, @mth = @BatchMth, @batchid = @BatchId, @errortext = @ErrorText, @errmsg = @msg OUTPUT
							IF @rcode <> 0 GOTO CursorCleanup
							GOTO FetchNext
						END
						
						--Since inter-company depends on the GLCo provided we make sure that the GL accounts have matching GL companies
						IF @GLCo <> @BDownGLCo
						BEGIN
							SET @ErrorText = @ErrorText + ' - RevBdownCode ' + dbo.vfToString(@RevBdownCode) + ' GL company doesn''t match the EM company''s GL company.'
							EXEC @rcode = dbo.bspHQBEInsert @co = @SMCo, @mth = @BatchMth, @batchid = @BatchId, @errortext = @ErrorText, @errmsg = @msg OUTPUT
							IF @rcode <> 0 GOTO CursorCleanup
							GOTO FetchNext
						END
					END

					UPDATE @RevBreakDowns
					SET Total = ISNULL(CASE WHEN @BaseRate = 0 THEN 0 ELSE @RevBdownRate / @BaseRate * @Dollars END, 0)
					WHERE KeyID = @CurrentKeyID

					GOTO RevBreakDownLoop
				END
			END

			--Check to see when we do that the breakdown totals add up to the supplied total
			--We sum by the GL accounts first just in case any precision is lost
			SELECT @BreakdownTotal = SUM(Total)
			FROM
				(SELECT SUM(Total) AS Total
				FROM @RevBreakDowns
				GROUP BY GLCo, GLAcct) GLDistributions

			--If the totals don't match put the variance in the last breakdown
			--Hopefully we don't get another precision issue in this case
			IF @BreakdownTotal <> @Dollars
			BEGIN
				UPDATE @RevBreakDowns
				SET Total = Total + (@Dollars - @BreakdownTotal)
				WHERE RevBdownCode = (SELECT MAX(RevBdownCode) FROM @RevBreakDowns)
			END

			/*Populate our batch revenue breakdown table variable to later populate the distribution table*/
			INSERT INTO @BatchRevenueBreakdowns
			SELECT @BatchSeq, @EMCo, @EMGroup, RevBdownCode, @Equipment, @RevCode, Total
			FROM @RevBreakDowns
		END
		/*END REVENUE BREAKDOWN PROCESSING*/

		/*GL DISTRIBUTIONS*/
		SELECT @SMGLDistributionID = SMGLDistributionID
		FROM dbo.vSMGLDistribution
		WHERE SMCo = @SMCo AND BatchMonth = @BatchMth AND BatchId = @BatchId AND SMWorkCompletedID = @SMWorkCompletedID
		
		IF @@rowcount = 0
		BEGIN
			IF NOT EXISTS(SELECT 1 FROM dbo.vSMWorkCompletedGL WHERE SMWorkCompletedID = @SMWorkCompletedID)
			BEGIN
				INSERT dbo.vSMWorkCompletedGL (SMWorkCompletedID, SMCo, IsMiscellaneousLineType)
				VALUES (@SMWorkCompletedID, @SMCo, 0)
			END

			INSERT dbo.vSMGLDistribution (SMWorkCompletedID, SMCo, BatchMonth, BatchId, CostOrRevenue, IsAccountTransfer)
			VALUES (@SMWorkCompletedID, @SMCo, @BatchMth, @BatchId, 'C', 0)
			
			SET @SMGLDistributionID = SCOPE_IDENTITY()
		END

		IF @IsReversingEntry = 0
		BEGIN
			SELECT @TransDesc = @GLDetlDesc,
				@TransDesc = REPLACE(@TransDesc, 'SM Company', dbo.vfToString(@SMCo)),
				@TransDesc = REPLACE(@TransDesc, 'Work Order', dbo.vfToString(@WorkOrder)),
				@TransDesc = REPLACE(@TransDesc, 'Scope', dbo.vfToString((SELECT Scope FROM dbo.SMWorkCompleted WHERE SMWorkCompletedID = @SMWorkCompletedID))),
				@TransDesc = REPLACE(@TransDesc, 'Line Type', '1'),  --1 is the Equipment Line type
				@TransDesc = REPLACE(@TransDesc, 'Line Sequence', dbo.vfToString((SELECT WorkCompleted FROM dbo.SMWorkCompleted WHERE SMWorkCompletedID = @SMWorkCompletedID)))

			INSERT dbo.vSMGLEntry (SMWorkCompletedID, Journal)
			VALUES (@SMWorkCompletedID, @GLJournal)
			
			SET @SMGLEntryID = SCOPE_IDENTITY()
			
			UPDATE dbo.vSMGLDistribution
			SET SMGLEntryID = @SMGLEntryID
			WHERE SMGLDistributionID = @SMGLDistributionID

			DELETE @GLDistributions

			--Do cross accounting entries
			IF @GLCo <> @OffsetGLCo 
			BEGIN
				--Credit cross company AP Account
				INSERT INTO @GLDistributions
				VALUES (@SMGLEntryID, 0, @OffsetGLCo, @APGLAcct, -(@Dollars), @ActualDate, @TransDesc, NULL)

				--Debit cross company AR Account
				INSERT INTO @GLDistributions
				VALUES (@SMGLEntryID, 0, @GLCo, @ARGLAcct, @Dollars, @ActualDate, @TransDesc, NULL)
			END
		
			--Debit the revenue account
			IF @GLAcct IS NULL 
			BEGIN
				--If the transacct is null then the revenue code wasn't defined for the equipment's department
				--therefore we use the breakdown accounts.
				INSERT INTO @GLDistributions
				SELECT @SMGLEntryID, 0, GLCo, GLAcct, -(SUM(Total)), @ActualDate, @TransDesc, 'E'
				FROM @RevBreakDowns
				GROUP BY GLCo, GLAcct
			END
			ELSE
			BEGIN
				INSERT INTO @GLDistributions
				VALUES (@SMGLEntryID, 0, @GLCo, @GLAcct, -(@Dollars), @ActualDate, @TransDesc, 'E')
			END
			
			--Credit the offset account
			INSERT INTO @GLDistributions
			VALUES (@SMGLEntryID, 1, @OffsetGLCo, @OffsetGLAcct, @Dollars, @ActualDate, @TransDesc, 'S')

			SELECT @ValidationGLCo = @GLCo, @ValidationGLAcct = NULL

			GLAccountValidationLoop:
			BEGIN
				SELECT TOP 1 @ValidationGLAcct = GLAccount, @SubType = SubType
				FROM @GLDistributions
				WHERE GLCo = @ValidationGLCo AND (@ValidationGLAcct IS NULL OR GLAccount > @ValidationGLAcct)
				ORDER BY GLAccount
				IF @@rowcount = 1
				BEGIN
					EXEC @rcode = dbo.bspGLACfPostable @glco = @ValidationGLCo, @glacct = @ValidationGLAcct, @chksubtype = @SubType, @msg = @msg OUTPUT
					IF @rcode <> 0
					BEGIN
						SET @ErrorText = @ErrorText + ' ' + dbo.vfToString(@msg)
						EXEC @rcode = dbo.bspHQBEInsert @co = @SMCo, @mth = @BatchMth, @batchid = @BatchId, @errortext = @ErrorText, @errmsg = @msg OUTPUT
						IF @rcode <> 0 GOTO CursorCleanup
						GOTO FetchNext
					END
					
					GOTO GLAccountValidationLoop
				END
				
				IF @ValidationGLCo <> @OffsetGLCo
				BEGIN
					SELECT @ValidationGLCo = @OffsetGLCo, @ValidationGLAcct = NULL
					GOTO GLAccountValidationLoop
				END
			END

			-- make sure debits and credits balance
			IF EXISTS(SELECT 1 
						FROM @GLDistributions
						GROUP BY GLCo
						HAVING ISNULL(SUM(Amount), 0) <> 0)
			BEGIN
				SET @ErrorText = @ErrorText + '- GL entries dont balance!'
				EXEC @rcode = dbo.bspHQBEInsert @co = @SMCo, @mth = @BatchMth, @batchid = @BatchId, @errortext = @ErrorText, @errmsg = @msg OUTPUT
				IF @rcode <> 0 GOTO CursorCleanup
				GOTO FetchNext
			END
			
			INSERT INTO dbo.vSMGLDetailTransaction (SMGLEntryID, IsTransactionForSMDerivedAccount, GLCo, GLAccount, Amount, ActDate, [Description])
			SELECT @SMGLEntryID, IsTransactionForSMDerivedAccount, GLCo, GLAccount, Amount, ActDate, [Description]
			FROM @GLDistributions
			ORDER BY IsTransactionForSMDerivedAccount
			
			--The last record entered should be the offset account since it was the only record that has IsTransactionForSMDerivedAccount = 1 and
			--we ordered by IsTransactionForSMDerivedAccount
			SET @SMGLDetailTransactionID = SCOPE_IDENTITY()
			
			UPDATE dbo.vSMGLDistribution
			SET SMGLDetailTransactionID = @SMGLDetailTransactionID
			WHERE SMGLDistributionID = @SMGLDistributionID
		END
		ELSE
		BEGIN
			INSERT dbo.vSMGLEntry (SMWorkCompletedID, Journal)
			SELECT @SMWorkCompletedID, ISNULL((SELECT Journal FROM dbo.vSMWorkCompletedGL INNER JOIN dbo.vSMGLEntry ON vSMWorkCompletedGL.CostGLEntryID = vSMGLEntry.SMGLEntryID WHERE vSMWorkCompletedGL.SMWorkCompletedID = @SMWorkCompletedID), @GLJournal)
			
			SET @SMGLEntryID = SCOPE_IDENTITY()
			
			UPDATE dbo.vSMGLDistribution
			SET ReversingSMGLEntryID = @SMGLEntryID
			WHERE SMGLDistributionID = @SMGLDistributionID
		
			--Reversing data comes from vfSMBuildReversingTransactions
			INSERT INTO dbo.vSMGLDetailTransaction (SMGLEntryID, IsTransactionForSMDerivedAccount, GLCo, GLAccount, Amount, ActDate, [Description])
			SELECT @SMGLEntryID, IsTransactionForSMDerivedAccount, GLCo, GLAccount, Amount, ActDate, [Description]
			FROM dbo.vfSMBuildReversingTransactions(@SMWorkCompletedID)
			WHERE IsTransactionForSMDerivedAccount IS NOT NULL
		END
		/*END GL DISTRIBUTIONS*/

		/*START SM JOB COST DISTRIBUTIONS*/
		IF @IsReversingEntry = 0 or @BatchTransType = 'D'
		BEGIN
				EXEC @rcode = dbo.vspSMJobCostDistributionInsert @SMWorkCompletedID=@SMWorkCompletedID, @BatchCo=@SMCo,@BatchMth=@BatchMth,@BatchId = @BatchId, @BatchSeq = @BatchSeq, @JCTransType='EM',@errmsg = @msg OUTPUT
				IF @rcode <> 0 
				BEGIN
					SET @ErrorText = @ErrorText + ' - ' + dbo.vfToString(@msg)
					EXEC @rcode = dbo.bspHQBEInsert @co = @SMCo, @mth = @BatchMth, @batchid = @BatchId, @errortext = @ErrorText, @errmsg = @msg OUTPUT
					IF @rcode <> 0 GOTO CursorCleanup
					GOTO FetchNext
				ENd
		END
		/*END SM JOB COST DISTRIBUTIONS*/
		GOTO FetchNext
	END
	
	--We didn't have any critical errors if we hit this point so we will
	--continue validating
	SET @rcode = 0
	
CursorCleanup:
	CLOSE vcSMEMUsageBatch
	DEALLOCATE vcSMEMUsageBatch

	--We jumped out because we were unable to log errors
	IF @rcode = 1 GOTO ErrorFound

	--If any errors were logged we want to display the first one found
	SELECT TOP 1 @msg = ErrorText
	FROM dbo.bHQBE 
	WHERE Co = @SMCo AND Mth = @BatchMth AND BatchId = @BatchId
	ORDER BY Seq
	IF @@rowcount > 0 GOTO ErrorFound

	/*Populate distribution tables from table variables*/
	INSERT INTO dbo.vSMEMUsageBreakdownDistribution (SMCo, Mth, BatchId, BatchSeq, EMCo, EMGroup, RevBdownCode, Equipment, RevCode, Total)
	SELECT @SMCo, @BatchMth, @BatchId, BatchSeq, EMCo, EMGroup, RevBdownCode, Equipment, RevCode, Total
	FROM @BatchRevenueBreakdowns

	--Insert our control records so that the months cannot be closed
	INSERT INTO dbo.bHQCC (Co, Mth, BatchId, GLCo)
	SELECT @SMCo, @BatchMth, @BatchId, GLCo
	FROM dbo.vSMGLDistribution
		INNER JOIN dbo.vSMGLDetailTransaction ON vSMGLDistribution.SMGLEntryID = vSMGLDetailTransaction.SMGLEntryID OR vSMGLDistribution.ReversingSMGLEntryID = vSMGLDetailTransaction.SMGLEntryID
	WHERE vSMGLDistribution.SMCo = @SMCo AND vSMGLDistribution.BatchMonth = @BatchMth AND vSMGLDistribution.BatchId = @BatchId
	GROUP BY GLCo
	
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
GRANT EXECUTE ON  [dbo].[vspSMEMUsageBatchValidation] TO [public]
GO
