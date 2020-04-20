SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 3/15/13
-- Description:	Generic GL Distribution posting routine
-- =============================================
CREATE PROCEDURE [dbo].[vspGLDistributionPost]
	@Source bSource, @BatchCo bCompany, @BatchMonth bMonth, @BatchId bBatchID, @DatePosted bDate, @msg varchar(255) = NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @GLRef bGLRef, @GLCo bCompany, @GLTrans bTrans, @RowCount int
	
	DECLARE @GLDTPosting TABLE
	(
		PostSummary bit NOT NULL,
		GLDistributionID bigint NOT NULL,
		GLAccount bGLAcct NOT NULL,
		Journal bJrnl NOT NULL,
		[Source] bSource NOT NULL,
		ActDate bDate NOT NULL,
		[Description] bTransDesc NOT NULL,
		Amount bDollar NOT NULL,
		GLTrans bTrans NULL
	)

	--Set GL Reference using Batch Id - right justified 10 chars
    SET @GLRef = SPACE(10 - LEN(@BatchId)) + dbo.vfToString(@BatchId)

	--Update the trans in the description for the distribution
	UPDATE dbo.vGLDistribution
	SET [Description] = REPLACE([Description], 'Trans #', dbo.vfToString(DetailDescriptionTrans))
	WHERE [Source] = @Source AND Co = @BatchCo AND Mth = @BatchMonth AND BatchId = @BatchId

	--Once distributions can be tied to GL Entry transactions then the description should be update on the description too.
	--UPDATE vGLEntryTransaction
	--SET [Description] = vGLDistribution.[Description]
	--FROM dbo.vGLDistribution
	--	INNER JOIN dbo.vGLEntryTransaction ON vGLDistribution.Co = vGLEntryTransaction.Co AND vGLDistribution.GLEntry = vGLEntryTransaction.GLEntry AND vGLDistribution.GLEntryTransaction = vGLEntryTransaction.GLEntryTransaction
	--WHERE vGLDistribution.[Source] = @Source AND vGLDistribution.Co = @BatchCo AND vGLDistribution.Mth = @BatchMonth AND vGLDistribution.BatchId = @BatchId

	--Processing is done in a transaction by GLCo so that a specific GLCo should never be out of balance
	WHILE EXISTS(SELECT 1 FROM dbo.vGLDistribution WHERE [Source] = @Source AND Co = @BatchCo AND Mth = @BatchMonth AND BatchId = @BatchId)
	BEGIN
		SELECT TOP 1 @GLCo = GLCo
		FROM dbo.vGLDistribution
		WHERE [Source] = @Source AND Co = @BatchCo AND Mth = @BatchMonth AND BatchId = @BatchId

		BEGIN TRY
			BEGIN TRAN

			--Delete all distributions that have an interface level of no posting
			DELETE vGLDistribution
			FROM dbo.vGLDistribution
				INNER JOIN dbo.vGLDistributionInterface ON vGLDistribution.[Source] = vGLDistributionInterface.[Source] AND vGLDistribution.Co = vGLDistributionInterface.Co AND vGLDistribution.Mth = vGLDistributionInterface.Mth AND vGLDistribution.BatchId = vGLDistributionInterface.BatchId
			WHERE vGLDistribution.[Source] = @Source AND vGLDistribution.Co = @BatchCo AND vGLDistribution.Mth = @BatchMonth AND vGLDistribution.BatchId = @BatchId AND vGLDistribution.GLCo = @GLCo AND vGLDistributionInterface.InterfaceLevel = 0

			--Populate the table variable with the GL postings that need to be posted
			;WITH UpdateGLDTCTE
			AS
			(
				SELECT vGLDistribution.GLDistributionID, vGLDistribution.[Source], vGLDistribution.GLAccount, vGLDistribution.Amount, vGLDistribution.[Description] DetailDescription, vGLDistribution.ActDate,
					vGLDistributionInterface.Journal, vGLDistributionInterface.SummaryDescription,
					CASE WHEN vGLDistributionInterface.InterfaceLevel = 1 AND bGLAC.InterfaceDetail = 'N' THEN 1 ELSE 0 END PostSummary
				FROM dbo.vGLDistribution
					INNER JOIN dbo.vGLDistributionInterface ON vGLDistribution.[Source] = vGLDistributionInterface.[Source] AND vGLDistribution.Co = vGLDistributionInterface.Co AND vGLDistribution.Mth = vGLDistributionInterface.Mth AND vGLDistribution.BatchId = vGLDistributionInterface.BatchId
					INNER JOIN dbo.bGLAC ON vGLDistribution.GLCo = bGLAC.GLCo AND vGLDistribution.GLAccount = bGLAC.GLAcct
				WHERE vGLDistribution.[Source] = @Source AND vGLDistribution.Co = @BatchCo AND vGLDistribution.Mth = @BatchMonth AND vGLDistribution.BatchId = @BatchId AND vGLDistribution.GLCo = @GLCo
			)
			INSERT @GLDTPosting (PostSummary, GLDistributionID, GLAccount, Journal, [Source], ActDate, [Description], Amount)
			--Detail records
			SELECT 0 PostSummary, GLDistributionID, GLAccount, Journal, [Source], ActDate, DetailDescription, Amount
			FROM UpdateGLDTCTE
			WHERE PostSummary = 0
			UNION ALL
			--Summary records
			SELECT 1 PostSummary, NULL GLDistributionID, GLAccount, Journal, [Source], @DatePosted ActDate, SummaryDescription, SUM(Amount) Amount
			FROM UpdateGLDTCTE
			WHERE PostSummary = 1
			GROUP BY GLAccount, Journal, [Source], SummaryDescription

			SET @RowCount = @@ROWCOUNT

			IF @RowCount > 0
			BEGIN
				--Update HQTC with the next GL Trans
				EXEC @GLTrans = dbo.bspHQTCNextTransWithCount @tablename = 'bGLDT', @co = @GLCo, @mth = @BatchMonth, @count = @RowCount, @errmsg = @msg OUTPUT

				IF @GLTrans = 0
				BEGIN
					ROLLBACK TRAN
					RETURN 1
				END

				--Set the GLTrans to the starting value for the records
				SET @GLTrans = @GLTrans - @RowCount

				--Update all the GLTrans values for the records
				UPDATE @GLDTPosting
				SET @GLTrans = @GLTrans + 1, GLTrans = @GLTrans

				INSERT dbo.bGLDT (GLCo, Mth, GLTrans, GLAcct, Jrnl, GLRef, SourceCo, [Source], ActDate, DatePosted,
					[Description], BatchId, Amount, RevStatus, Adjust, Purge)
				SELECT @GLCo, @BatchMonth, GLTrans, GLAccount, Journal, @GLRef, @BatchCo, [Source], ActDate, @DatePosted,
					[Description], @BatchId, Amount, 0 RevStatus, 'N' Adjust, 'N' Purge
				FROM @GLDTPosting

				--Update the GLEntryTransaction GLTrans values.
				--UPDATE vGLEntryTransaction
				--SET GLTrans = GLDTPosting.GLTrans
				--FROM @GLDTPosting GLDTPosting
				--	INNER JOIN dbo.vGLDistribution ON GLDTPosting.GLDistributionID = vGLDistribution.GLDistributionID
				--	INNER JOIN dbo.vGLEntryTransaction ON vGLDistribution.Co = vGLEntryTransaction.Co AND vGLDistribution.GLEntry = vGLEntryTransaction.GLEntry AND vGLDistribution.GLEntryTransaction = vGLEntryTransaction.GLEntryTransaction

				--UPDATE vGLEntryTransaction
				--SET GLTrans = GLDTPosting.GLTrans
				--FROM vGLDistribution
				--	INNER JOIN dbo.vGLDistributionInterface ON vGLDistribution.[Source] = vGLDistributionInterface.[Source] AND vGLDistribution.Co = vGLDistributionInterface.Co AND vGLDistribution.Mth = vGLDistributionInterface.Mth AND vGLDistribution.BatchId = vGLDistributionInterface.BatchId
				--	INNER JOIN dbo.vGLEntryTransaction ON vGLDistribution.Co = vGLEntryTransaction.Co AND vGLDistribution.GLEntry = vGLEntryTransaction.GLEntry AND vGLDistribution.GLEntryTransaction = vGLEntryTransaction.GLEntryTransaction
				--	INNER JOIN @GLDTPosting GLDTPosting ON vGLDistribution.GLAccount = GLDTPosting.GLAccount AND vGLDistributionInterface.Journal = GLDTPosting.Journal AND vGLDistributionInterface.[Source] = GLDTPosting.[Source] AND vGLDistributionInterface.SummaryDescription = GLDTPosting.[Description]
				--WHERE vGLDistribution.[Source] = @Source AND vGLDistribution.Co = @BatchCo AND vGLDistribution.Mth = @BatchMonth AND vGLDistribution.BatchId = @BatchId AND vGLDistribution.GLCo = @GLCo AND vGLDistribution.GLTrans IS NULL AND GLDTPosting.PostSummary = 1

				DELETE @GLDTPosting
			END

			DELETE dbo.vGLDistribution
			WHERE [Source] = @Source AND Co = @BatchCo AND Mth = @BatchMonth AND BatchId = @BatchId AND GLCo = @GLCo

			COMMIT TRAN
		END TRY
		BEGIN CATCH
			ROLLBACK TRAN
			SET @msg = ERROR_MESSAGE()
			RETURN 1
		END CATCH
	END

	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspGLDistributionPost] TO [public]
GO
