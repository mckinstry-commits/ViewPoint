SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 9/5/2012
-- Description:	Similar to a lazy loader a HQBatchDistributionID is returned if a record matching the batch values exists and if not a new distribution record is created.
-- =============================================
CREATE PROCEDURE [dbo].[vspHQBatchDistributionGet]
	@BatchCo bCompany, @BatchMth bMonth, @BatchId bBatchID, @BatchSeq int = NULL, @Line smallint = NULL, @HQBatchDistributionID bigint = NULL OUTPUT, @msg varchar(255) = NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT @HQBatchDistributionID = HQBatchDistributionID
	FROM dbo.vHQBatchDistribution
	--Use vfIsEqual so that NULL = NULL is true
	WHERE dbo.vfIsEqual(Co, @BatchCo) & dbo.vfIsEqual(Mth, @BatchMth) & dbo.vfIsEqual(BatchId, @BatchId) & dbo.vfIsEqual(BatchSeq, @BatchSeq) & dbo.vfIsEqual(Line, @Line) = 1

	--If a distribution doesn't already exist a new one is created.
	IF @@rowcount = 0
	BEGIN
		INSERT dbo.vHQBatchDistribution (Co, Mth, BatchId, BatchSeq, Line, InterfacingCo)
		VALUES (@BatchCo, @BatchMth, @BatchId, @BatchSeq, @Line, @BatchCo)
		
		SET @HQBatchDistributionID = SCOPE_IDENTITY()
	END
	
	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[vspHQBatchDistributionGet] TO [public]
GO
