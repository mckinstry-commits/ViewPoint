SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 2/9/2012
-- Description:	
-- =============================================
CREATE PROCEDURE [dbo].[vspSMGetCurrentUsersBatches]
(
	@Source bSource
)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	--#UsersCurrentBatches DEFINITION
	--SHOULD HAVE ALREADY BEEN CREATED AT THIS POINT
	--CREATE TABLE #UsersCurrentBatches
	--( 
	--	Co tinyint,
	--	Mth smalldatetime,
	--	BatchId int
	--)
	
	DECLARE @BatchCo bCompany, @BatchMth bMonth, @BatchId bBatchID, @KeyID int
	
	--Find all the batches that no longer have associated records with them and cancel them.
	DECLARE @BatchesToCancel TABLE (Co bCompany, Mth bMonth, BatchId bBatchID, KeyID int IDENTITY(1,1))
	
	INSERT @BatchesToCancel
	SELECT UsersCurrentBatches.Co, UsersCurrentBatches.Mth, UsersCurrentBatches.BatchId
	FROM #UsersCurrentBatches UsersCurrentBatches
		INNER JOIN dbo.bHQBC ON UsersCurrentBatches.Co = bHQBC.Co AND UsersCurrentBatches.Mth = bHQBC.Mth AND UsersCurrentBatches.BatchId = bHQBC.BatchId
		LEFT JOIN dbo.vSMWorkCompletedBatch ON bHQBC.Co = vSMWorkCompletedBatch.BatchCo AND UsersCurrentBatches.Mth = vSMWorkCompletedBatch.BatchMonth AND UsersCurrentBatches.BatchId = vSMWorkCompletedBatch.BatchId
	WHERE bHQBC.[Status] < 4 AND bHQBC.InUseBy = SUSER_NAME() AND vSMWorkCompletedBatch.SMWorkCompletedID IS NULL

	WHILE EXISTS(SELECT 1 FROM @BatchesToCancel)
	BEGIN
		SELECT TOP 1 @BatchCo = Co, @BatchMth = Mth, @BatchId = BatchId, @KeyID = KeyID
		FROM @BatchesToCancel
		
		EXEC dbo.vspSMCancelBatch @BatchCo = @BatchCo, @BatchMth = @BatchMth, @BatchId = @BatchId
		
		DELETE @BatchesToCancel WHERE KeyID = @KeyID
	END

	--Get rid of the batches that have been processed or are no longer locked by the current user.
	DELETE UsersCurrentBatches
	FROM #UsersCurrentBatches UsersCurrentBatches
		INNER JOIN dbo.bHQBC ON UsersCurrentBatches.Co = bHQBC.Co AND UsersCurrentBatches.Mth = bHQBC.Mth AND UsersCurrentBatches.BatchId = bHQBC.BatchId
	WHERE bHQBC.[Status] >= 4 OR dbo.vfIsEqual(bHQBC.InUseBy, SUSER_NAME()) = 0
	
	SELECT UsersCurrentBatches.Co, UsersCurrentBatches.Mth, UsersCurrentBatches.BatchId, bHQBC.KeyID
	FROM #UsersCurrentBatches UsersCurrentBatches
		INNER JOIN dbo.bHQBC ON UsersCurrentBatches.Co = bHQBC.Co AND UsersCurrentBatches.Mth = bHQBC.Mth AND UsersCurrentBatches.BatchId = bHQBC.BatchId
	WHERE bHQBC.[Source] = @Source
	
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMGetCurrentUsersBatches] TO [public]
GO
