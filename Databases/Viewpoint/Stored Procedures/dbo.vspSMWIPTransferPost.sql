SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 8/2/11
-- Description:	Posts the GL Distributions for transfering WIP
-- Modified:    09/22/11 EricV - Update PRGL table for WIP transfer of Work Completed labor records.
-- =============================================
CREATE PROCEDURE [dbo].[vspSMWIPTransferPost]
	@SMCo bCompany, @BatchMonth bMonth, @BatchId bBatchID, @Source bSource, @PostDate bDate, @msg varchar(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @rcode int,
		@GLLvl tinyint,
		@BatchNotes varchar(max)

	--Make sure the batch can be posted and set it as posting in progress.
	EXEC @rcode = dbo.vspHQBatchPosting @BatchCo = @SMCo, @BatchMth = @BatchMonth, @BatchId = @BatchId, @Source = @Source, @TableName = 'SMWIPTransferBatch', @DatePosted = @PostDate, @msg = @msg OUTPUT
	IF @rcode <> 0 RETURN @rcode

	SELECT @GLLvl = CASE GLLvl WHEN 'NoUpdate' THEN 0 WHEN 'Summary' THEN 1 WHEN 'Detail' THEN 2 END
	FROM dbo.vSMCO
	WHERE SMCo = @SMCo
	
	--Update AR with the new Revenue GL Info
	UPDATE bARTL
	SET GLCo = vSMWIPTransferBatch.NewGLCo, GLAcct = vSMWIPTransferBatch.NewGLAcct
	FROM dbo.vSMWIPTransferBatch
		INNER JOIN dbo.vSMWorkCompleted ON vSMWIPTransferBatch.SMWorkCompletedID = vSMWorkCompleted.SMWorkCompletedID
		INNER JOIN dbo.vSMWorkCompletedARTL ON vSMWorkCompleted.SMWorkCompletedARTLID = vSMWorkCompletedARTL.SMWorkCompletedARTLID
		INNER JOIN dbo.bARTL ON vSMWorkCompletedARTL.ARCo = bARTL.ARCo AND vSMWorkCompletedARTL.Mth = bARTL.Mth AND vSMWorkCompletedARTL.ARTrans = bARTL.ARTrans AND vSMWorkCompletedARTL.ARLine = bARTL.ARLine
	WHERE vSMWIPTransferBatch.Co = @SMCo AND vSMWIPTransferBatch.Mth = @BatchMonth AND vSMWIPTransferBatch.BatchId = @BatchId AND vSMWIPTransferBatch.TransferType = 'R'
	
	-- Update AP with new Cost GL Info
	UPDATE bAPTL
	SET GLCo = NewGLCo, GLAcct = NewGLAcct
	FROM vSMWIPTransferBatch b
	JOIN vSMWorkCompleted w on 
	b.SMWorkCompletedID = w.SMWorkCompletedID 
	JOIN bAPTL a on w.APTLKeyID = a.KeyID	
	WHERE b.Co = @SMCo and b.Mth = @BatchMonth and b.BatchId = @BatchId
	and w.[Type] = 3 and b.TransferType = 'C' and 
	(a.GLCo <> b.NewGLCo or a.GLAcct <> b.NewGLAcct)
	
	--Changes to equipment and inventory work completed lines always post add records
	--for reversing entries to EMRD and INDT respectively. Those records can not be pulled back
	--in to a batch therefore the GL Account don't have to be up to date after wip transfer.
	--Instead changes to inventory work completed records look to vSMWorkCompleted GL to know
	--what gl account to reverse from.

	-- Update PRGL for any changes to GLAcct on labor records in the batch
	DECLARE @PRGLtrans 
		TABLE (	PRCo bCompany NOT NULL,
				PRGroup bGroup NOT NULL,
				PREndDate datetime NOT NULL,
				Mth bMonth NOT NULL,
				Employee bEmployee NOT NULL,
				PaySeq int NOT NULL,
				GLCo bCompany NOT NULL,
				GLAcct bGLAcct NOT NULL,
				Amount bDollar NOT NULL
		)

	--Create PRGL records so that if Ledger Update is run again reversing entries are created for the account costs actually are in instead of the account the cost used to be in.
	INSERT @PRGLtrans
	SELECT vSMWorkCompletedLabor.PRCo, vSMWorkCompletedLabor.PRGroup, vSMWorkCompletedLabor.PREndDate, vSMDetailTransaction.PRMth, vSMWorkCompletedLabor.PREmployee, vSMWorkCompletedLabor.PRPaySeq,
		vSMDetailTransaction.GLCo, vSMDetailTransaction.GLAccount, SUM(vSMDetailTransaction.Amount)
	FROM dbo.vHQBatchDistribution
		INNER JOIN dbo.vSMDetailTransaction ON vHQBatchDistribution.HQBatchDistributionID = vSMDetailTransaction.HQBatchDistributionID
		INNER JOIN dbo.vSMWorkCompletedLabor ON vSMDetailTransaction.SMWorkCompletedID = vSMWorkCompletedLabor.SMWorkCompletedID
	WHERE vHQBatchDistribution.Co = @SMCo AND vHQBatchDistribution.Mth = @BatchMonth AND vHQBatchDistribution.BatchId = @BatchId AND vSMDetailTransaction.TransactionType = 'C' AND vSMDetailTransaction.LineType = 2
	GROUP BY vSMWorkCompletedLabor.PRCo, vSMWorkCompletedLabor.PRGroup, vSMWorkCompletedLabor.PREndDate, vSMDetailTransaction.PRMth, vSMWorkCompletedLabor.PREmployee, vSMWorkCompletedLabor.PRPaySeq,
		vSMDetailTransaction.GLCo, vSMDetailTransaction.GLAccount

	BEGIN TRY
		BEGIN TRANSACTION
			-- Insert the PRGL records for GL accounts that don't already exist.
			INSERT dbo.bPRGL (PRCo, PRGroup, PREndDate, Mth, GLCo, GLAcct, Employee, PaySeq, Amt, OldAmt, [Hours], OldHours)
			SELECT DISTINCT PRGLtrans.PRCo, PRGLtrans.PRGroup, PRGLtrans.PREndDate, PRGLtrans.Mth,
				PRGLtrans.GLCo, PRGLtrans.GLAcct, PRGLtrans.Employee, PRGLtrans.PaySeq, 0, 0, 0, 0
			FROM @PRGLtrans PRGLtrans
				LEFT JOIN dbo.bPRGL ON PRGLtrans.PRCo = bPRGL.PRCo AND PRGLtrans.PRGroup = bPRGL.PRGroup AND PRGLtrans.PREndDate = bPRGL.PREndDate AND PRGLtrans.Mth = bPRGL.Mth AND PRGLtrans.GLCo = bPRGL.GLCo AND PRGLtrans.GLAcct = bPRGL.GLAcct AND PRGLtrans.Employee = bPRGL.Employee AND PRGLtrans.PaySeq = bPRGL.PaySeq
			WHERE bPRGL.GLAcct IS NULL

			-- Now update the OldAmt in the PRGL records for the changes.
			UPDATE dbo.bPRGL
			SET OldAmt = OldAmt + PRGLtrans.Amount
			FROM @PRGLtrans PRGLtrans
				INNER JOIN dbo.bPRGL ON PRGLtrans.PRCo = bPRGL.PRCo AND PRGLtrans.PRGroup = bPRGL.PRGroup AND PRGLtrans.PREndDate = bPRGL.PREndDate AND PRGLtrans.Mth = bPRGL.Mth AND PRGLtrans.GLCo = bPRGL.GLCo AND PRGLtrans.GLAcct = bPRGL.GLAcct AND PRGLtrans.Employee = bPRGL.Employee AND PRGLtrans.PaySeq = bPRGL.PaySeq
		COMMIT TRAN
	END TRY
	BEGIN CATCH
		SET @msg = ERROR_MESSAGE()
		GOTO RollbackErrorFound
	END CATCH

	DELETE dbo.vSMWIPTransferBatch
	WHERE Co = @SMCo AND Mth = @BatchMonth AND BatchId = @BatchId

	-- Post
	EXEC @rcode = dbo.vspSMGLDistributionPost @SMCo = @SMCo, @BatchMth = @BatchMonth, @BatchId = @BatchId, @PostDate = @PostDate, @msg = @msg OUTPUT
	IF @rcode <> 0 RETURN @rcode
    
	--Set the transaction as posted and remove the batch related values
	UPDATE vSMDetailTransaction
	SET Posted = 1, HQBatchDistributionID = NULL
	FROM dbo.vHQBatchDistribution
		INNER JOIN dbo.vSMDetailTransaction ON vHQBatchDistribution.HQBatchDistributionID = vSMDetailTransaction.HQBatchDistributionID
	WHERE vHQBatchDistribution.Co = @SMCo AND vHQBatchDistribution.Mth = @BatchMonth AND vHQBatchDistribution.BatchId = @BatchId

    SELECT @BatchNotes = 'GL Revenue Interface Level set at: ' + dbo.vfToString(@GLLvl) + dbo.vfLineBreak()
    
	--Capture notes, set Status to posted and cleanup HQCC records
	EXEC @rcode = dbo.vspHQBatchPosted @BatchCo = @SMCo, @BatchMth = @BatchMonth, @BatchId = @BatchId, @Notes = @BatchNotes, @msg = @msg OUTPUT
	IF @rcode <> 0 RETURN @rcode
    
    RETURN 0
    
RollbackErrorFound:
	--If an error is found then we need to properly handle the rollback
	--The assumption is if the transaction count = 1 then we are not in a nested
	--transaction and we can safely rollback. However, if the transaction count is greater than 1
	--then we are in a nested transaction and we need to make sure that the transaction count
	--when we entered the stored procedure matches the transaction count when we leave the stored procedure.
	--Then by returning 1 the rollback can be done from whatever sql executed this stored procedure.
	IF @@trancount = 1 ROLLBACK TRAN ELSE COMMIT TRAN
ErrorFound:
	RETURN 1

END
GO
GRANT EXECUTE ON  [dbo].[vspSMWIPTransferPost] TO [public]
GO
