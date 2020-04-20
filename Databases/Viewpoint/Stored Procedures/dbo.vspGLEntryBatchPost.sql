SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 6/13/2012
-- Description:	Generic posting routine for posting to GLDT from vGLEntrys associated with the batch through vHQBatchDistribution
-- =============================================
CREATE PROCEDURE [dbo].[vspGLEntryBatchPost]
	@GLEntrySource bSource, @BatchCo bCompany, @BatchMonth bMonth, @BatchId bBatchID, @DatePosted bDate, @msg varchar(255) = NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @GLRef bGLRef, @GLCo bCompany, @GLTrans bTrans, @GLEntryID bigint, @HQBatchDistributionID bigint, @IsReversing bit
	
	--Set GL Reference using Batch Id - right justified 10 chars
    SET @GLRef = SPACE(10 - LEN(@BatchId)) + dbo.vfToString(@BatchId)

	DECLARE @GLEntriesToProcess TABLE (HQBatchDistributionID bigint NOT NULL, GLEntryID bigint NOT NULL, IsReversing bit NOT NULL, InterfaceLevel tinyint NOT NULL, Journal bJrnl NULL, SummaryDescription bTransDesc NULL)

	--Ensure before posting GL that the interface data needed to post has been supplied.
	IF EXISTS(SELECT 1 FROM dbo.vfGLEntryBatch(@GLEntrySource, @BatchCo, @BatchMonth, @BatchId) WHERE InterfaceLevel IS NULL)
	BEGIN
		SET @msg = 'GL Entry missing interface level from vGLEntryBatchInterfacing'
		RETURN 1
	END

	INSERT @GLEntriesToProcess
	SELECT HQBatchDistributionID, GLEntryID, IsReversing, InterfaceLevel, Journal, SummaryDescription
	FROM dbo.vfGLEntryBatch(@GLEntrySource, @BatchCo, @BatchMonth, @BatchId)

	--For all the GLEntrys not being posted cleanup their relationships to the PRLedgerUpdateMonth
	--and vHQBatchDistribution.
	BEGIN TRY
		--A transaction is used to ensure everything was committed.
		BEGIN TRAN
		
		DELETE vPRLedgerUpdateMonth
		FROM @GLEntriesToProcess GLEntriesToProcess
			INNER JOIN dbo.vGLEntry ON GLEntriesToProcess.GLEntryID = vGLEntry.GLEntryID
			INNER JOIN dbo.vPRLedgerUpdateMonth ON vGLEntry.PRLedgerUpdateMonthID = vPRLedgerUpdateMonth.PRLedgerUpdateMonthID
		WHERE GLEntriesToProcess.InterfaceLevel = 0 AND GLEntriesToProcess.IsReversing = 1

		UPDATE vPRLedgerUpdateMonth
		SET Posted = 1
		FROM @GLEntriesToProcess GLEntriesToProcess
			INNER JOIN dbo.vGLEntry ON GLEntriesToProcess.GLEntryID = vGLEntry.GLEntryID
			INNER JOIN dbo.vPRLedgerUpdateMonth ON vGLEntry.PRLedgerUpdateMonthID = vPRLedgerUpdateMonth.PRLedgerUpdateMonthID
		WHERE GLEntriesToProcess.InterfaceLevel = 0

		DELETE vGLEntry
		FROM @GLEntriesToProcess GLEntriesToProcess
			INNER JOIN dbo.vGLEntry ON GLEntriesToProcess.GLEntryID = vGLEntry.GLEntryID
		WHERE GLEntriesToProcess.InterfaceLevel = 0 AND GLEntriesToProcess.IsReversing = 1

		UPDATE vGLEntry
		SET HQBatchDistributionID = NULL
		FROM @GLEntriesToProcess GLEntriesToProcess
			INNER JOIN dbo.vGLEntry ON GLEntriesToProcess.GLEntryID = vGLEntry.GLEntryID
		WHERE GLEntriesToProcess.InterfaceLevel = 0
		
		DELETE @GLEntriesToProcess WHERE InterfaceLevel = 0
		
		COMMIT TRAN
	END TRY
	BEGIN CATCH
		SET @msg = ERROR_MESSAGE()
		ROLLBACK TRAN
		RETURN 1
	END CATCH
	
	--An account can be set to be posted in detail which overrides posting in summary. For any GLEntry
	--that has an account set that way the GLEntry needs to be posted in detail.
	UPDATE GLEntriesToProcess
	SET InterfaceLevel = 2
	FROM @GLEntriesToProcess GLEntriesToProcess
		INNER JOIN dbo.vGLEntryTransaction ON GLEntriesToProcess.GLEntryID = vGLEntryTransaction.GLEntryID
		INNER JOIN dbo.bGLAC ON vGLEntryTransaction.GLCo = bGLAC.GLCo AND vGLEntryTransaction.GLAccount = bGLAC.GLAcct
	WHERE bGLAC.InterfaceDetail = 'Y'

	DECLARE @GLEntryTransaction TABLE (
		GLCo bCompany NOT NULL, GLTrans bTrans NULL, GLAcct bGLAcct NOT NULL, Journal bJrnl NOT NULL, 
		[Source] bSource NOT NULL, ActDate bDate NOT NULL, [Description] bTransDesc NULL, Amount bDollar NOT NULL)

	--Load up all the GL Entry Transactions that need to be processed
	INSERT @GLEntryTransaction (GLCo, GLAcct, Journal, [Source], ActDate, [Description], Amount)
	SELECT vGLEntryTransaction.GLCo, vGLEntryTransaction.GLAccount, GLEntriesToProcess.Journal, vGLEntryTransaction.[Source], @DatePosted, GLEntriesToProcess.SummaryDescription, SUM(vGLEntryTransaction.Amount)
	FROM @GLEntriesToProcess GLEntriesToProcess
		INNER JOIN dbo.vGLEntryTransaction ON GLEntriesToProcess.GLEntryID = vGLEntryTransaction.GLEntryID
	WHERE GLEntriesToProcess.InterfaceLevel = 1
	GROUP BY vGLEntryTransaction.GLCo, vGLEntryTransaction.GLAccount, GLEntriesToProcess.Journal, vGLEntryTransaction.[Source], GLEntriesToProcess.SummaryDescription
	
	--Post the GLEntrys that should be posted in summary.
	BEGIN TRY
		BEGIN TRAN

		WHILE EXISTS(SELECT 1 FROM @GLEntryTransaction WHERE GLTrans IS NULL)
		BEGIN
			SELECT TOP 1 @GLCo = GLCo
			FROM @GLEntryTransaction
			WHERE GLTrans IS NULL
			
			EXEC @GLTrans = dbo.bspHQTCNextTrans @tablename = 'bGLDT', @co = @GLCo, @mth = @BatchMonth, @errmsg = @msg OUTPUT
			IF @GLTrans = 0
			BEGIN
				ROLLBACK TRAN
				RETURN 1
			END
			
			UPDATE TOP (1) @GLEntryTransaction
			SET GLTrans = @GLTrans
			WHERE GLCo = @GLCo AND GLTrans IS NULL
		END

		INSERT dbo.bGLDT (GLCo, Mth, GLTrans, GLAcct, Jrnl, GLRef, SourceCo, [Source], ActDate, DatePosted,
			[Description], BatchId, Amount, RevStatus, Adjust, InUseBatchId, Purge)
		SELECT GLCo, @BatchMonth, GLTrans, GLAcct, Journal, @GLRef, @BatchCo, [Source], ActDate, @DatePosted,
			[Description], @BatchId, Amount, 0 RevStatus, 'N' Adjust, NULL InUseBatchId, 'N' Purge
		FROM @GLEntryTransaction

		--For all the GLEntrys that were posted cleanup their relationships to the PRLedgerUpdateMonth
		--and vHQBatchDistribution.
		DELETE vPRLedgerUpdateMonth
		FROM @GLEntriesToProcess GLEntriesToProcess
			INNER JOIN dbo.vGLEntry ON GLEntriesToProcess.GLEntryID = vGLEntry.GLEntryID
			INNER JOIN dbo.vPRLedgerUpdateMonth ON vGLEntry.PRLedgerUpdateMonthID = vPRLedgerUpdateMonth.PRLedgerUpdateMonthID
		WHERE GLEntriesToProcess.InterfaceLevel = 1 AND GLEntriesToProcess.IsReversing = 1

		UPDATE vPRLedgerUpdateMonth
		SET Posted = 1
		FROM @GLEntriesToProcess GLEntriesToProcess
			INNER JOIN dbo.vGLEntry ON GLEntriesToProcess.GLEntryID = vGLEntry.GLEntryID
			INNER JOIN dbo.vPRLedgerUpdateMonth ON vGLEntry.PRLedgerUpdateMonthID = vPRLedgerUpdateMonth.PRLedgerUpdateMonthID
		WHERE GLEntriesToProcess.InterfaceLevel = 1

		DELETE vGLEntry
		FROM @GLEntriesToProcess GLEntriesToProcess
			INNER JOIN dbo.vGLEntry ON GLEntriesToProcess.GLEntryID = vGLEntry.GLEntryID
		WHERE GLEntriesToProcess.InterfaceLevel = 1 AND GLEntriesToProcess.IsReversing = 1

		UPDATE vGLEntry
		SET HQBatchDistributionID = NULL
		FROM @GLEntriesToProcess GLEntriesToProcess
			INNER JOIN dbo.vGLEntry ON GLEntriesToProcess.GLEntryID = vGLEntry.GLEntryID
		WHERE GLEntriesToProcess.InterfaceLevel = 1

		DELETE @GLEntriesToProcess WHERE InterfaceLevel = 1

		COMMIT TRAN
	END TRY
	BEGIN CATCH
		SET @msg = ERROR_MESSAGE()
		ROLLBACK TRAN
		RETURN 1
	END CATCH
	
	--Post the remaing GLEntrys in detail.
	WHILE EXISTS(SELECT 1 FROM @GLEntriesToProcess)
	BEGIN
		SELECT TOP 1 @GLEntryID = GLEntryID, @HQBatchDistributionID = HQBatchDistributionID, @IsReversing = IsReversing
		FROM @GLEntriesToProcess
		
		DELETE @GLEntryTransaction
		
		INSERT @GLEntryTransaction (GLCo, GLAcct, Journal, [Source], ActDate, [Description], Amount)
		SELECT vGLEntryTransaction.GLCo, vGLEntryTransaction.GLAccount, GLEntriesToProcess.Journal, vGLEntryTransaction.[Source], vGLEntryTransaction.ActDate, vGLEntryTransaction.[Description], vGLEntryTransaction.Amount
		FROM @GLEntriesToProcess GLEntriesToProcess
			INNER JOIN dbo.vGLEntryTransaction ON GLEntriesToProcess.GLEntryID = vGLEntryTransaction.GLEntryID
		WHERE GLEntriesToProcess.GLEntryID = @GLEntryID
		
		DELETE @GLEntriesToProcess
		WHERE GLEntryID = @GLEntryID
		
		BEGIN TRY
			BEGIN TRAN
			
			WHILE EXISTS(SELECT 1 FROM @GLEntryTransaction WHERE GLTrans IS NULL)
			BEGIN
				SELECT TOP 1 @GLCo = GLCo
				FROM @GLEntryTransaction
				WHERE GLTrans IS NULL
				
				EXEC @GLTrans = dbo.bspHQTCNextTrans @tablename = 'bGLDT', @co = @GLCo, @mth = @BatchMonth, @errmsg = @msg OUTPUT
				IF @GLTrans = 0
				BEGIN
					ROLLBACK TRAN
					RETURN 1
				END
				
				UPDATE TOP (1) @GLEntryTransaction
				SET GLTrans = @GLTrans
				WHERE GLCo = @GLCo AND GLTrans IS NULL
			END
			
			INSERT dbo.bGLDT (GLCo, Mth, GLTrans, GLAcct, Jrnl, GLRef, SourceCo, [Source], ActDate, DatePosted,
				[Description], BatchId, Amount, RevStatus, Adjust, InUseBatchId, Purge)
			SELECT GLCo, @BatchMonth, GLTrans, GLAcct, Journal, @GLRef, @BatchCo, [Source], ActDate, @DatePosted,
				[Description], @BatchId, Amount, 0 RevStatus, 'N' Adjust, NULL InUseBatchId, 'N' Purge
			FROM @GLEntryTransaction
			
			--For all the GLEntrys that were posted cleanup their relationships to the PRLedgerUpdateMonth
			--and vHQBatchDistribution.
			IF @IsReversing = 1
			BEGIN
				DELETE vPRLedgerUpdateMonth
				FROM dbo.vGLEntry
					INNER JOIN dbo.vPRLedgerUpdateMonth ON vGLEntry.PRLedgerUpdateMonthID = vPRLedgerUpdateMonth.PRLedgerUpdateMonthID
				WHERE vGLEntry.GLEntryID = @GLEntryID
				
				DELETE dbo.vGLEntry
				WHERE GLEntryID = @GLEntryID
			END
			ELSE
			BEGIN
				UPDATE vPRLedgerUpdateMonth
				SET Posted = 1
				FROM dbo.vGLEntry
					INNER JOIN dbo.vPRLedgerUpdateMonth ON vGLEntry.PRLedgerUpdateMonthID = vPRLedgerUpdateMonth.PRLedgerUpdateMonthID
				WHERE vGLEntry.GLEntryID = @GLEntryID
			
				UPDATE vGLEntry
				SET HQBatchDistributionID = NULL
				WHERE GLEntryID = @GLEntryID
			END
			
			COMMIT TRAN
		END TRY
		BEGIN CATCH
			SET @msg = ERROR_MESSAGE()
			ROLLBACK TRAN
			RETURN 1
		END CATCH
	END

	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspGLEntryBatchPost] TO [public]
GO
