SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 9/7/2011
-- Description:	Generic posting routine for posting to GLDT from vGLEntryBatch
-- =============================================
CREATE PROCEDURE [dbo].[vspGLEntryPost]
	@Co bCompany, @BatchMonth bMonth, @BatchId bBatchID, @InterfaceLevel tinyint, @Journal bJrnl, @SummaryDescription varchar(60), @DatePosted bDate, @msg varchar(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF @InterfaceLevel <> 0 AND @Journal IS NULL
	BEGIN
		SET @msg = 'A journal must be supplied when posting to GL.'
		RETURN 1
	END
	
	DECLARE @GLRef bGLRef, @GLCo bCompany, @GLTrans bTrans, @GLEntryID bigint
	
	--Set GL Reference using Batch Id - right justified 10 chars
    SET @GLRef = SPACE(10 - LEN(@BatchId)) + dbo.vfToString(@BatchId)

	DECLARE @GLEntriesToProcess TABLE (GLEntryID bigint, Processing tinyint DEFAULT(0))
	
	--Load up our @GLEntriesToProcess with all the GLEntryIDs
	INSERT @GLEntriesToProcess (GLEntryID)
	SELECT GLEntryID
	FROM dbo.vGLEntryBatch
	WHERE Co = @Co AND Mth = @BatchMonth AND BatchId = @BatchId AND ReadyToProcess = 1 AND PostedToGL = 0

	DECLARE @GLEntryTransactions TABLE (GLEntryID bigint, GLCo bCompany, GLAcct bGLAcct, [Source] bSource, Amount bDollar, ActDate bDate, [Description] bTransDesc, InterfaceLevel tinyint)

	--Load up all the GL Entry Transactions that need to be processed
	INSERT @GLEntryTransactions
	SELECT vGLEntryTransaction.GLEntryID, vGLEntryTransaction.GLCo, vGLEntryTransaction.GLAccount, vGLEntry.[Source], vGLEntryTransaction.Amount, vGLEntryTransaction.ActDate, vGLEntryTransaction.[Description],
		CASE WHEN @InterfaceLevel <> 0 AND bGLAC.InterfaceDetail = 'Y' THEN 2 /*Detail*/ ELSE @InterfaceLevel END
	FROM @GLEntriesToProcess GLEntriesToProcess
		INNER JOIN dbo.vGLEntry ON GLEntriesToProcess.GLEntryID = vGLEntry.GLEntryID
		INNER JOIN dbo.vGLEntryTransaction ON vGLEntry.GLEntryID = vGLEntryTransaction.GLEntryID
		LEFT JOIN dbo.bGLAC ON vGLEntryTransaction.GLCo = bGLAC.GLCo AND vGLEntryTransaction.GLAccount = bGLAC.GLAcct

	DECLARE @ProcessingGLEntryTransactions TABLE (GLCo bCompany, GLAcct bGLAcct, [Source] bSource, Amount bDollar, ActDate bDate, [Description] bTransDesc, GLTrans bTrans NULL)

	/*In order to not have a lot of duplicated code we start off by processing all the gl entries that should be posted in summary
	Then we start our loop to process all remaining entries. We process the summarized gl entries and every loop after that we process 1 gl entry at a time.*/
	IF @InterfaceLevel = 1
	BEGIN
		--Find all the GL Entries that are able to be posted in summary
		--and update Processing to 1 to represent that we are currently processing them
		UPDATE GLEntriesToProcess
		SET Processing = 1
		FROM @GLEntriesToProcess GLEntriesToProcess
		WHERE NOT EXISTS(SELECT 1 FROM @GLEntryTransactions WHERE GLEntriesToProcess.GLEntryID = GLEntryID AND InterfaceLevel <> 1)
	
		INSERT @ProcessingGLEntryTransactions (GLCo, GLAcct, [Source], Amount, ActDate, [Description])
		SELECT GLCo, GLAcct, [Source], SUM(Amount), @DatePosted, @SummaryDescription
		FROM @GLEntriesToProcess GLEntriesToProcess
			INNER JOIN @GLEntryTransactions GLEntryTransactionsToProcess ON GLEntriesToProcess.GLEntryID = GLEntryTransactionsToProcess.GLEntryID
		WHERE GLEntriesToProcess.Processing = 1
		GROUP BY GLCo, GLAcct, [Source]
	END

	WHILE EXISTS(SELECT 1 FROM @GLEntriesToProcess)
	BEGIN
		BEGIN TRAN
		SAVE TRAN GLEntryPost
			IF EXISTS(SELECT 1 FROM @ProcessingGLEntryTransactions)
			BEGIN
				UpdateGLTrans:
				BEGIN
					SELECT TOP 1 @GLCo = GLCo
					FROM @ProcessingGLEntryTransactions
					WHERE GLTrans IS NULL
					IF @@rowcount = 1
					BEGIN
						EXEC @GLTrans = dbo.bspHQTCNextTrans @tablename = 'bGLDT', @co = @GLCo, @mth = @BatchMonth, @errmsg = @msg OUTPUT
						IF @GLTrans = 0
						BEGIN
							ROLLBACK TRAN GLEntryPost
							COMMIT TRAN
							RETURN 1
						END

						UPDATE TOP (1) @ProcessingGLEntryTransactions
						SET GLTrans = @GLTrans
						WHERE GLCo = @GLCo AND GLTrans IS NULL

						GOTO UpdateGLTrans
					END
				END
				
				INSERT dbo.bGLDT (GLCo, Mth, GLTrans, GLAcct, Jrnl, GLRef, SourceCo, [Source], ActDate, DatePosted,
					[Description], BatchId, Amount, RevStatus, Adjust, InUseBatchId, Purge)
				SELECT GLCo, @BatchMonth, GLTrans, GLAcct, @Journal, @GLRef, @Co, [Source], ActDate, @DatePosted,
					[Description], @BatchId, Amount, 0 AS RevStatus, 'N' AS Adjust, NULL AS InUseBatchId, 'N' AS Purge
				FROM @ProcessingGLEntryTransactions
			END
			
			UPDATE vGLEntryBatch
			SET PostedToGL = 1
			FROM dbo.vGLEntryBatch
				INNER JOIN @GLEntriesToProcess GLEntriesToProcess ON vGLEntryBatch.GLEntryID = GLEntriesToProcess.GLEntryID
			WHERE GLEntriesToProcess.Processing = 1
			
			DELETE @GLEntriesToProcess
			WHERE Processing = 1
		COMMIT TRAN

		DELETE @ProcessingGLEntryTransactions

		UPDATE TOP (1) @GLEntriesToProcess
		SET Processing = 1, @GLEntryID = GLEntryID

		--If the module that the GL Entry is for posts in summary, but some of the
		--gl accounts involved have to be posted in detail then we may have a combination
		--of entries that need to be posted in summary and others that have to be posted in detail

		--Add all the gl entries that have to be posted in detail
		INSERT @ProcessingGLEntryTransactions (GLCo, GLAcct, [Source], Amount, ActDate, [Description])
		SELECT GLCo, GLAcct, [Source], Amount, ActDate, [Description]
		FROM @GLEntryTransactions
		WHERE GLEntryID = @GLEntryID AND InterfaceLevel > 1

		--Add the rest of the gl entries that can be posted in summary
		INSERT @ProcessingGLEntryTransactions (GLCo, GLAcct, [Source], Amount, ActDate, [Description])
		SELECT GLCo, GLAcct, [Source], SUM(Amount), @DatePosted, @SummaryDescription
		FROM @GLEntryTransactions
		WHERE GLEntryID = @GLEntryID AND InterfaceLevel = 1
		GROUP BY GLCo, GLAcct, [Source]
	END

	SET @msg = NULL

	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspGLEntryPost] TO [public]
GO
