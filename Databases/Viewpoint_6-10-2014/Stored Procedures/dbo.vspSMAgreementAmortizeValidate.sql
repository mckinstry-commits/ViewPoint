SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 3/14/13
-- Description:	Batch validtion for SM Agreement Amortization
-- Modified:	JVH 6/24/13 - TFS-53342	Modified to support SM Flat Price Billing
-- =============================================
CREATE PROCEDURE [dbo].[vspSMAgreementAmortizeValidate]
	@SMCo bCompany, @BatchMonth bMonth, @BatchId bBatchID, @msg varchar(255) = NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @rcode int, @Source bSource, @BatchCreateDate bDate, @HQBatchDistributionID bigint, @DetailDescription varchar(max), @TransactionDescription varchar(max)

	SET @Source = 'SMAmortize'

	EXEC @rcode = dbo.vspHQBatchValidating @BatchCo = @SMCo, @BatchMth = @BatchMonth, @BatchId = @BatchId, @Source = @Source, @TableName = 'SMAgreementAmrtBatch', @HQBatchDistributionID = @HQBatchDistributionID OUTPUT, @msg = @msg OUTPUT
	IF @rcode <> 0 RETURN @rcode

	--Deleting the distributions won't be needed once changes are made to vHQBatchDistribution
	DELETE dbo.vGLDistributionInterface
	WHERE Co = @SMCo AND Mth = @BatchMonth AND BatchId = @BatchId

	DELETE dbo.vGLDistribution
	WHERE Co = @SMCo AND Mth = @BatchMonth AND BatchId = @BatchId

	--Currently there are no settings for posting the GL specifically for Revenue Recognition so the work order is being used for now
	INSERT dbo.vGLDistributionInterface ([Source], Co, Mth, BatchId, InterfaceLevel, Journal, SummaryDescription)
	SELECT @Source, @SMCo, @BatchMonth, @BatchId, 
		CASE GLLvl
			WHEN 'NoUpdate' THEN 0
			WHEN 'Summary' THEN 1
			WHEN 'Detail' THEN 2
		END, GLJrnl, GLSumDesc
	FROM dbo.vSMCO
	WHERE SMCo = @SMCo

	SET @DetailDescription = 'SM Company/Agreement/Revision/Service/Trans #'

	SELECT @BatchCreateDate = DateCreated
	FROM dbo.bHQBC
	WHERE Co = @SMCo AND Mth = @BatchMonth AND BatchId = @BatchId

	--The detail description will need to be changed once changes have been made to the SMCO.
	INSERT dbo.vGLDistribution ([Source], Co, Mth, BatchId, BatchSeq, GLCo, GLAccount, GLAccountSubType, Amount, ActDate)
	SELECT @Source, Co, Mth, BatchId, Seq, GLCo, DeriveGL.GLAcct, 'S', DeriveGL.Amount, @BatchCreateDate
	FROM dbo.vSMAgreementAmrtBatch
		CROSS APPLY
		(
			SELECT AgreementRevDefGLAcct GLAcct, Amount
			UNION ALL
			SELECT AgreementRevGLAcct, -Amount
		) DeriveGL
	WHERE Co = @SMCo AND Mth = @BatchMonth AND BatchId = @BatchId

	UPDATE vGLDistribution
	SET @TransactionDescription = @DetailDescription,
		@TransactionDescription = REPLACE(@TransactionDescription, 'SM Company', dbo.vfToString(vSMAgreementAmrtBatch.Co)),
		@TransactionDescription = REPLACE(@TransactionDescription, 'Agreement', dbo.vfToString(vSMAgreementAmrtBatch.Agreement)),
		@TransactionDescription = REPLACE(@TransactionDescription, 'Revision', dbo.vfToString(vSMAgreementAmrtBatch.Revision)),
		@TransactionDescription = REPLACE(@TransactionDescription, 'Service', dbo.vfToString(vSMAgreementAmrtBatch.[Service])),
		[Description] = @TransactionDescription
	FROM dbo.vGLDistribution
		INNER JOIN dbo.vSMAgreementAmrtBatch ON vGLDistribution.Co = vSMAgreementAmrtBatch.Co AND vGLDistribution.Mth = vSMAgreementAmrtBatch.Mth AND vGLDistribution.BatchId = vSMAgreementAmrtBatch.BatchId AND vGLDistribution.BatchSeq = vSMAgreementAmrtBatch.Seq
	WHERE vGLDistribution.Co = @SMCo AND vGLDistribution.Mth = @BatchMonth AND vGLDistribution.BatchId = @BatchId

	EXEC @rcode = dbo.vspGLDistributionValidate @Source = @Source, @BatchCo = @SMCo, @BatchMonth = @BatchMonth, @BatchId = @BatchId
	IF @rcode <> 0 GOTO EndValidation

	--Capture revenue reconciliation records for SM.
	INSERT dbo.vSMDetailTransaction (IsReversing, Posted, HQBatchDistributionID, SMAgreementID, TransactionType, SourceCo, Mth, BatchId, GLCo, GLAccount, Amount)
	SELECT 0 IsReversing, 0 Posted, @HQBatchDistributionID, vSMAgreement.SMAgreementID, 'R', @SMCo, @BatchMonth, @BatchId, vSMAgreementAmrtBatch.GLCo, DeriveGL.GLAccount, DeriveGL.PostAmount
	FROM dbo.vSMAgreementAmrtBatch
		INNER JOIN dbo.vSMAgreement ON vSMAgreementAmrtBatch.Co = vSMAgreement.SMCo AND vSMAgreementAmrtBatch.Agreement = vSMAgreement.Agreement AND vSMAgreementAmrtBatch.Revision = vSMAgreement.Revision
		CROSS APPLY
		(
			SELECT vSMAgreementAmrtBatch.AgreementRevDefGLAcct GLAccount, vSMAgreementAmrtBatch.Amount PostAmount
			UNION ALL
			SELECT vSMAgreementAmrtBatch.AgreementRevGLAcct, -vSMAgreementAmrtBatch.Amount
		) DeriveGL
	WHERE vSMAgreementAmrtBatch.Co = @SMCo AND vSMAgreementAmrtBatch.Mth = @BatchMonth AND vSMAgreementAmrtBatch.BatchId = @BatchId

EndValidation:
	EXEC @rcode = dbo.vspHQBatchValidated @BatchCo = @SMCo, @BatchMth = @BatchMonth, @BatchId = @BatchId, @msg = @msg OUTPUT
	IF @rcode <> 0 RETURN @rcode

	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMAgreementAmortizeValidate] TO [public]
GO
