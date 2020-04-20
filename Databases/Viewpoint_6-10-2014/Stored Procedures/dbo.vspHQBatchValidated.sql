SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 6/20/13
-- Description:	Updates the batch status when validation has completed
-- =============================================
CREATE PROCEDURE [dbo].[vspHQBatchValidated]
	@BatchCo bCompany, @BatchMth bMonth, @BatchId bBatchID, @Status tinyint = NULL OUTPUT, @msg varchar(255) = NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SET @Status = 
		CASE 
			/* set HQ Batch status to 2 (errors found) */
			WHEN EXISTS(SELECT 1 FROM dbo.bHQBE WHERE Co = @BatchCo AND Mth = @BatchMth AND BatchId = @BatchId) THEN 2
			/* set HQ Batch status to 3 (validated) */
			ELSE 3
		END

	UPDATE dbo.bHQBC 
	SET [Status] = @Status
	WHERE Co = @BatchCo AND Mth = @BatchMth AND BatchId = @BatchId
	IF @@rowcount = 0
	BEGIN
		SET @msg = 'Unable to update HQ Batch Control status!'
		RETURN 1
	END

	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspHQBatchValidated] TO [public]
GO
