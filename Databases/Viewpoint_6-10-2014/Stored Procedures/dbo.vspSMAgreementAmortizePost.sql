SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 3/14/13
-- Description:	Batch posting for SM Agreement Amortization
-- =============================================
CREATE PROCEDURE [dbo].[vspSMAgreementAmortizePost]
	@SMCo bCompany, @BatchMonth bMonth, @BatchId bBatchID, @DatePosted bDate, @msg varchar(255) = NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @rcode int, @Source bSource, @RowCount int, @SMTrans bTrans, @BatchNotes varchar(MAX)

	SET @Source = 'SMAmortize'

	--Make sure the batch can be posted and set it as posting in progress.
	EXEC @rcode = dbo.vspHQBatchPosting @BatchCo = @SMCo, @BatchMth = @BatchMonth, @BatchId = @BatchId, @Source = @Source, @TableName = 'SMAgreementAmrtBatch', @DatePosted = @DatePosted, @msg = @msg OUTPUT
	IF @rcode <> 0 RETURN @rcode

	SELECT @RowCount = COUNT(1)
	FROM dbo.vSMAgreementAmrtBatch
	WHERE Co = @SMCo AND Mth = @BatchMonth AND BatchId = @BatchId

	IF @RowCount > 0
	BEGIN
		BEGIN TRY
			BEGIN TRAN

			EXEC @SMTrans = dbo.bspHQTCNextTransWithCount @tablename = 'vSMAgreementAmrt', @co = @SMCo, @mth = @BatchMonth, @count = @RowCount, @errmsg = @msg OUTPUT
			IF @SMTrans = 0
			BEGIN
				ROLLBACK TRAN
				RETURN 1
			END

			SET @SMTrans = @SMTrans - @RowCount

			UPDATE dbo.vSMAgreementAmrtBatch
			SET @SMTrans = @SMTrans + 1, SMTrans = @SMTrans
			WHERE Co = @SMCo AND Mth = @BatchMonth AND BatchId = @BatchId

			UPDATE dbo.vGLDistribution
			SET DetailDescriptionTrans = SMTrans
			FROM dbo.vSMAgreementAmrtBatch
				INNER JOIN dbo.vGLDistribution ON vSMAgreementAmrtBatch.Co = vGLDistribution.Co AND vSMAgreementAmrtBatch.Mth = vGLDistribution.Mth AND vSMAgreementAmrtBatch.BatchId = vGLDistribution.BatchId AND vSMAgreementAmrtBatch.Seq = vGLDistribution.BatchSeq
			WHERE vSMAgreementAmrtBatch.Co = @SMCo AND vSMAgreementAmrtBatch.Mth = @BatchMonth AND vSMAgreementAmrtBatch.BatchId = @BatchId

			INSERT dbo.vSMAgreementAmrt (SMCo, Mth, SMTrans, Agreement, Revision, [Service], Amount, GLCo, AgreementRevDefGLAcct, AgreementRevGLAcct)
			SELECT Co, Mth, SMTrans, Agreement, Revision, [Service], Amount, GLCo, AgreementRevDefGLAcct, AgreementRevGLAcct
			FROM dbo.vSMAgreementAmrtBatch
			WHERE Co = @SMCo AND Mth = @BatchMonth AND BatchId = @BatchId

			DELETE dbo.vSMAgreementAmrtBatch
			WHERE Co = @SMCo AND Mth = @BatchMonth AND BatchId = @BatchId

			COMMIT TRAN
		END TRY
		BEGIN CATCH
			ROLLBACK TRAN
			SET @msg = ERROR_MESSAGE()
			RETURN 1
		END CATCH
	END

	EXEC @rcode = dbo.vspGLDistributionPost @Source = @Source, @BatchCo = @SMCo, @BatchMonth = @BatchMonth, @BatchId = @BatchId, @DatePosted = @DatePosted, @msg = @msg OUTPUT
	IF @rcode <> 0 RETURN @rcode

	--Set the transactions as posted
	BEGIN TRY
		UPDATE vSMDetailTransaction
		SET Posted = 1, HQBatchDistributionID = NULL, GLInterfaceLevel = vGLDistributionInterface.InterfaceLevel
		FROM dbo.vHQBatchDistribution
			INNER JOIN dbo.vSMDetailTransaction ON vHQBatchDistribution.HQBatchDistributionID = vSMDetailTransaction.HQBatchDistributionID
			INNER JOIN dbo.vGLDistributionInterface ON vGLDistributionInterface.Co = vHQBatchDistribution.Co AND vGLDistributionInterface.Mth = vHQBatchDistribution.Mth AND vGLDistributionInterface.BatchId = vHQBatchDistribution.BatchId
		WHERE vHQBatchDistribution.Co = @SMCo AND vHQBatchDistribution.Mth = @BatchMonth AND vHQBatchDistribution.BatchId = @BatchId
				AND vGLDistributionInterface.[Source] = @Source
	END TRY
	BEGIN CATCH
		SET @msg = ERROR_MESSAGE()
		RETURN 1
	END CATCH

	SELECT @BatchNotes = 'GL Revenue Interface Level set at: ' + dbo.vfToString(vGLDistributionInterface.InterfaceLevel) + dbo.vfLineBreak()
	FROM dbo.vGLDistributionInterface
	WHERE [Source] = @Source AND Co = @SMCo AND Mth = @BatchMonth AND BatchId = @BatchId

	--Until changes are made to make vHQDistribution unique by co, mth, batchid and
	--a cascade delete fk is added to vGLDistributionInterface the records need to be deleted manually
	DELETE dbo.vGLDistributionInterface
	WHERE [Source] = @Source AND Co = @SMCo AND Mth = @BatchMonth AND BatchId = @BatchId

	--Capture notes, set Status to posted and cleanup HQCC records
	EXEC @rcode = dbo.vspHQBatchPosted @BatchCo = @SMCo, @BatchMth = @BatchMonth, @BatchId = @BatchId, @Notes = @BatchNotes, @msg = @msg OUTPUT
	IF @rcode <> 0 RETURN @rcode

	SET @msg = NULL
	
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMAgreementAmortizePost] TO [public]
GO
