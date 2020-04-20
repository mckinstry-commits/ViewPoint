SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 8/2/11
-- Description:	Posts the GL Distributions for transfering WIP
-- Modified:    09/22/11 EricV - Update PRGL table for WIP transfer of Work Completed labor records.
--				5/28/13 JVH - TFS-44858	Modified to support SM Flat Price Billing
--				6/24/13 JVH - TFS-53341	Modified to support SM Flat Price Billing
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
		INNER JOIN dbo.vSMInvoiceDetail ON vSMWIPTransferBatch.Co = vSMInvoiceDetail.SMCo AND vSMWIPTransferBatch.WorkOrder = vSMInvoiceDetail.WorkOrder AND vSMWIPTransferBatch.WorkCompleted = vSMInvoiceDetail.WorkCompleted
		INNER JOIN dbo.vSMInvoiceLine ON vSMInvoiceDetail.SMCo = vSMInvoiceLine.SMCo AND vSMInvoiceDetail.Invoice = vSMInvoiceLine.Invoice AND vSMInvoiceDetail.InvoiceDetail = vSMInvoiceLine.InvoiceDetail
		INNER JOIN dbo.bARTL ON vSMInvoiceLine.LastPostedARCo = bARTL.ARCo AND vSMInvoiceLine.LastPostedARMth = bARTL.Mth AND vSMInvoiceLine.LastPostedARTrans = bARTL.ARTrans AND vSMInvoiceLine.LastPostedARLine = bARTL.ARLine
	WHERE vSMWIPTransferBatch.Co = @SMCo AND vSMWIPTransferBatch.Mth = @BatchMonth AND vSMWIPTransferBatch.BatchId = @BatchId AND vSMWIPTransferBatch.TransferType = 'R'

	--Update SM Invoice Line account both the current and backup so no changes are picked up
	UPDATE CurrentAndInvoicedLine
	SET GLCo = vSMWIPTransferBatch.NewGLCo, GLAccount = vSMWIPTransferBatch.NewGLAcct
	FROM dbo.vSMWIPTransferBatch
		INNER JOIN dbo.vSMInvoiceDetail ON vSMWIPTransferBatch.Co = vSMInvoiceDetail.SMCo AND vSMWIPTransferBatch.WorkOrder = vSMInvoiceDetail.WorkOrder AND vSMWIPTransferBatch.WorkCompleted = vSMInvoiceDetail.WorkCompleted
		INNER JOIN dbo.vSMInvoiceLine ON vSMInvoiceDetail.SMCo = vSMInvoiceLine.SMCo AND vSMInvoiceDetail.Invoice = vSMInvoiceLine.Invoice AND vSMInvoiceDetail.InvoiceDetail = vSMInvoiceLine.InvoiceDetail
		INNER JOIN dbo.vSMInvoiceLine CurrentAndInvoicedLine ON vSMInvoiceLine.SMCo = CurrentAndInvoicedLine.SMCo AND vSMInvoiceLine.InvoiceLine = CurrentAndInvoicedLine.InvoiceLine
	WHERE vSMWIPTransferBatch.Co = @SMCo AND vSMWIPTransferBatch.Mth = @BatchMonth AND vSMWIPTransferBatch.BatchId = @BatchId AND vSMWIPTransferBatch.TransferType = 'R'

	--Update AR with the new Revenue GL Info
	UPDATE bARTL
	SET GLCo = vSMWIPTransferBatch.NewGLCo, GLAcct = vSMWIPTransferBatch.NewGLAcct
	FROM dbo.vSMWIPTransferBatch
		INNER JOIN dbo.vSMEntity ON vSMWIPTransferBatch.Co = vSMEntity.SMCo AND vSMWIPTransferBatch.WorkOrder = vSMEntity.WorkOrder AND vSMWIPTransferBatch.Scope = vSMEntity.WorkOrderScope
		INNER JOIN dbo.vSMFlatPriceRevenueSplit ON vSMEntity.SMCo = vSMFlatPriceRevenueSplit.SMCo AND vSMEntity.EntitySeq = vSMFlatPriceRevenueSplit.EntitySeq AND vSMWIPTransferBatch.FlatPriceRevenueSplitSeq = vSMFlatPriceRevenueSplit.Seq
		INNER JOIN dbo.vSMInvoiceDetail ON vSMWIPTransferBatch.Co = vSMInvoiceDetail.SMCo AND vSMWIPTransferBatch.WorkOrder = vSMInvoiceDetail.WorkOrder AND vSMWIPTransferBatch.Scope = vSMInvoiceDetail.Scope
		INNER JOIN dbo.vSMInvoiceLine ON vSMInvoiceDetail.SMCo = vSMInvoiceLine.SMCo AND vSMInvoiceDetail.Invoice = vSMInvoiceLine.Invoice AND vSMInvoiceDetail.InvoiceDetail = vSMInvoiceLine.InvoiceDetail AND vSMFlatPriceRevenueSplit.Seq = vSMInvoiceLine.InvoiceDetailSeq
		INNER JOIN dbo.bARTL ON vSMInvoiceLine.LastPostedARCo = bARTL.ARCo AND vSMInvoiceLine.LastPostedARMth = bARTL.Mth AND vSMInvoiceLine.LastPostedARTrans = bARTL.ARTrans AND vSMInvoiceLine.LastPostedARLine = bARTL.ARLine
	WHERE vSMWIPTransferBatch.Co = @SMCo AND vSMWIPTransferBatch.Mth = @BatchMonth AND vSMWIPTransferBatch.BatchId = @BatchId AND vSMWIPTransferBatch.TransferType = 'R'

	--Update SM Invoice Line account both the current and backup so no changes are picked up
	UPDATE CurrentAndInvoicedLine
	SET GLCo = vSMWIPTransferBatch.NewGLCo, GLAccount = vSMWIPTransferBatch.NewGLAcct
	FROM dbo.vSMWIPTransferBatch
		INNER JOIN dbo.vSMEntity ON vSMWIPTransferBatch.Co = vSMEntity.SMCo AND vSMWIPTransferBatch.WorkOrder = vSMEntity.WorkOrder AND vSMWIPTransferBatch.Scope = vSMEntity.WorkOrderScope
		INNER JOIN dbo.vSMFlatPriceRevenueSplit ON vSMEntity.SMCo = vSMFlatPriceRevenueSplit.SMCo AND vSMEntity.EntitySeq = vSMFlatPriceRevenueSplit.EntitySeq AND vSMWIPTransferBatch.FlatPriceRevenueSplitSeq = vSMFlatPriceRevenueSplit.Seq
		INNER JOIN dbo.vSMInvoiceDetail ON vSMWIPTransferBatch.Co = vSMInvoiceDetail.SMCo AND vSMWIPTransferBatch.WorkOrder = vSMInvoiceDetail.WorkOrder AND vSMWIPTransferBatch.Scope = vSMInvoiceDetail.Scope
		INNER JOIN dbo.vSMInvoiceLine ON vSMInvoiceDetail.SMCo = vSMInvoiceLine.SMCo AND vSMInvoiceDetail.Invoice = vSMInvoiceLine.Invoice AND vSMInvoiceDetail.InvoiceDetail = vSMInvoiceLine.InvoiceDetail AND vSMFlatPriceRevenueSplit.Seq = vSMInvoiceLine.InvoiceDetailSeq
		INNER JOIN dbo.vSMInvoiceLine CurrentAndInvoicedLine ON vSMInvoiceLine.SMCo = CurrentAndInvoicedLine.SMCo AND vSMInvoiceLine.InvoiceLine = CurrentAndInvoicedLine.InvoiceLine
	WHERE vSMWIPTransferBatch.Co = @SMCo AND vSMWIPTransferBatch.Mth = @BatchMonth AND vSMWIPTransferBatch.BatchId = @BatchId AND vSMWIPTransferBatch.TransferType = 'R'
	
	-- Update AP with new Cost GL Info
	UPDATE bAPTL
	SET GLCo = NewGLCo, GLAcct = NewGLAcct
	FROM dbo.vSMWIPTransferBatch
		INNER JOIN dbo.vSMWorkCompleted ON vSMWIPTransferBatch.Co = vSMWorkCompleted.SMCo AND vSMWIPTransferBatch.WorkOrder = vSMWorkCompleted.WorkOrder AND vSMWIPTransferBatch.WorkCompleted = vSMWorkCompleted.WorkCompleted
		INNER JOIN dbo.bAPTL ON vSMWorkCompleted.APTLKeyID = bAPTL.KeyID
	WHERE vSMWIPTransferBatch.Co = @SMCo AND vSMWIPTransferBatch.Mth = @BatchMonth AND vSMWIPTransferBatch.BatchId = @BatchId AND
		vSMWorkCompleted.[Type] = 3 AND vSMWIPTransferBatch.TransferType = 'C'
	
	--Changes to equipment and inventory work completed lines always post add records
	--for reversing entries to EMRD and INDT respectively. Those records can not be pulled back
	--in to a batch therefore the GL Account don't have to be up to date after wip transfer.
	--Instead changes to inventory work completed records look to vSMWorkCompleted GL to know
	--what gl account to reverse from.

	-- Update PRGL for any changes to GLAcct on labor records in the batch
	DECLARE @PRGLtrans TABLE
	(
		PRCo bCompany NOT NULL,
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

		------------------------------------------------------------------------------------------------------
		--THE FOLLOWING CODE IN THIS TRY BLOCK CAN BE REMOVED ONCE vSMDetailTransaction IS USED INSTEAD OF vSMWorkCompletedGL FOR WIP TRANSFERS
		------------------------------------------------------------------------------------------------------
		DECLARE @GLEntries TABLE (SMWorkCompletedID bigint, SMGLEntryID bigint, TransferType char(1), GLEntryID bigint)

		INSERT dbo.vSMGLEntry (SMWorkCompletedID, TransactionsShouldBalance)
			OUTPUT inserted.SMWorkCompletedID, inserted.SMGLEntryID, 'C'
				INTO @GLEntries (SMWorkCompletedID, SMGLEntryID, TransferType)
		SELECT vSMWorkCompleted.SMWorkCompletedID, 0 TransactionsShouldBalance
		FROM dbo.vSMWIPTransferBatch
			INNER JOIN dbo.vSMWorkCompleted ON vSMWIPTransferBatch.Co = vSMWorkCompleted.SMCo AND vSMWIPTransferBatch.WorkOrder = vSMWorkCompleted.WorkOrder AND vSMWIPTransferBatch.WorkCompleted = vSMWorkCompleted.WorkCompleted
		WHERE vSMWIPTransferBatch.Co = @SMCo AND vSMWIPTransferBatch.Mth = @BatchMonth AND vSMWIPTransferBatch.BatchId = @BatchId AND vSMWIPTransferBatch.TransferType = 'C'

		INSERT dbo.vSMGLEntry (SMWorkCompletedID, TransactionsShouldBalance)
			OUTPUT inserted.SMWorkCompletedID, inserted.SMGLEntryID, 'R'
				INTO @GLEntries (SMWorkCompletedID, SMGLEntryID, TransferType)
		SELECT vSMWorkCompleted.SMWorkCompletedID, 0 TransactionsShouldBalance
		FROM dbo.vSMWIPTransferBatch
			INNER JOIN dbo.vSMWorkCompleted ON vSMWIPTransferBatch.Co = vSMWorkCompleted.SMCo AND vSMWIPTransferBatch.WorkOrder = vSMWorkCompleted.WorkOrder AND vSMWIPTransferBatch.WorkCompleted = vSMWorkCompleted.WorkCompleted
		WHERE vSMWIPTransferBatch.Co = @SMCo AND vSMWIPTransferBatch.Mth = @BatchMonth AND vSMWIPTransferBatch.BatchId = @BatchId AND vSMWIPTransferBatch.TransferType = 'R'

		INSERT dbo.vSMGLDetailTransaction (SMGLEntryID, IsTransactionForSMDerivedAccount, GLCo, GLAccount, Amount, ActDate, [Description])
		SELECT GLEntries.SMGLEntryID, 1 IsTransactionForSMDerivedAccount, vGLDistribution.GLCo, vGLDistribution.GLAccount, vGLDistribution.Amount, vGLDistribution.ActDate, vGLDistribution.[Description]
		FROM dbo.vSMWIPTransferBatch
			INNER JOIN dbo.vSMWorkCompleted ON vSMWIPTransferBatch.Co = vSMWorkCompleted.SMCo AND vSMWIPTransferBatch.WorkOrder = vSMWorkCompleted.WorkOrder AND vSMWIPTransferBatch.WorkCompleted = vSMWorkCompleted.WorkCompleted
			INNER JOIN @GLEntries GLEntries ON vSMWorkCompleted.SMWorkCompletedID = GLEntries.SMWorkCompletedID AND vSMWIPTransferBatch.TransferType = GLEntries.TransferType
			INNER JOIN dbo.vGLDistribution ON vSMWIPTransferBatch.Co = vGLDistribution.Co AND vSMWIPTransferBatch.Mth = vGLDistribution.Mth AND vSMWIPTransferBatch.BatchId = vGLDistribution.BatchId AND vSMWIPTransferBatch.BatchSeq = vGLDistribution.BatchSeq AND
				vSMWIPTransferBatch.NewGLCo = vGLDistribution.GLCo AND vSMWIPTransferBatch.NewGLAcct = vGLDistribution.GLAccount AND vGLDistribution.GLAccountSubType = 'S'
		WHERE vSMWIPTransferBatch.Co = @SMCo AND vSMWIPTransferBatch.Mth = @BatchMonth AND vSMWIPTransferBatch.BatchId = @BatchId

		--HACK To make sure misc work completed doesn't show up as needing to be reprocessed the date is updated
		--with the work completed date. This also causes the gl for future adjustments to the work completed
		--to use the correct date(the work completed date).
		UPDATE vSMGLDetailTransaction
		SET ActDate = vSMWorkCompletedDetail.[Date]
		FROM @GLEntries GLEntries
			INNER JOIN dbo.vSMGLDetailTransaction ON GLEntries.SMGLEntryID = vSMGLDetailTransaction.SMGLEntryID
			INNER JOIN dbo.vSMWorkCompleted ON GLEntries.SMWorkCompletedID = vSMWorkCompleted.SMWorkCompletedID
			INNER JOIN dbo.vSMWorkCompletedDetail ON GLEntries.SMWorkCompletedID = vSMWorkCompletedDetail.SMWorkCompletedID AND vSMWorkCompletedDetail.IsSession = 0
		WHERE GLEntries.TransferType = 'C' AND vSMWorkCompleted.[Type] = 3

		DECLARE @GLEntriesToDelete TABLE (GLEntryID bigint)

		UPDATE dbo.vSMWorkCompletedGL
		SET CostGLDetailTransactionEntryID = vSMGLDetailTransaction.SMGLEntryID, CostGLDetailTransactionID = vSMGLDetailTransaction.SMGLDetailTransactionID
			OUTPUT deleted.CostGLDetailTransactionEntryID
				INTO @GLEntriesToDelete
		FROM @GLEntries GLEntries
			INNER JOIN dbo.vSMWorkCompletedGL ON GLEntries.SMWorkCompletedID = vSMWorkCompletedGL.SMWorkCompletedID
			INNER JOIN dbo.vSMGLDetailTransaction ON GLEntries.SMGLEntryID = vSMGLDetailTransaction.SMGLEntryID
		WHERE GLEntries.TransferType = 'C'

		UPDATE dbo.vSMWorkCompletedGL
		SET RevenueGLDetailTransactionEntryID = vSMGLDetailTransaction.SMGLEntryID, RevenueGLDetailTransactionID = vSMGLDetailTransaction.SMGLDetailTransactionID
			OUTPUT deleted.RevenueGLDetailTransactionEntryID
				INTO @GLEntriesToDelete
		FROM @GLEntries GLEntries
			INNER JOIN dbo.vSMWorkCompletedGL ON GLEntries.SMWorkCompletedID = vSMWorkCompletedGL.SMWorkCompletedID
			INNER JOIN dbo.vSMGLDetailTransaction ON GLEntries.SMGLEntryID = vSMGLDetailTransaction.SMGLEntryID
		WHERE GLEntries.TransferType = 'R'

		DELETE vSMGLEntry
		FROM @GLEntriesToDelete GLEntriesToDelete
			INNER JOIN dbo.vSMGLEntry ON GLEntriesToDelete.GLEntryID = vSMGLEntry.SMGLEntryID
			LEFT JOIN dbo.vSMWorkCompletedGL ON vSMGLEntry.SMWorkCompletedID = vSMWorkCompletedGL.SMWorkCompletedID AND (vSMGLEntry.SMGLEntryID = vSMWorkCompletedGL.CostGLEntryID OR vSMGLEntry.SMGLEntryID = vSMWorkCompletedGL.RevenueGLEntryID)
		WHERE vSMWorkCompletedGL.SMWorkCompletedID IS NULL

		DELETE @GLEntriesToDelete

		--JC Revenue is using the GLEntries from the vSMWorkCompleted record so it needs to be updated.
		DECLARE @GLEntryID bigint

		WHILE EXISTS(SELECT 1 FROM @GLEntries WHERE TransferType = 'R' AND GLEntryID IS NULL)
		BEGIN
			EXEC @GLEntryID = dbo.vspGLCreateEntry @Source = 'SM WIP', @TransactionsShouldBalance =  1, @msg = @msg OUTPUT

			UPDATE TOP (1) @GLEntries
			SET GLEntryID = @GLEntryID
			WHERE TransferType = 'R' AND GLEntryID IS NULL
		END

		INSERT dbo.vGLEntryTransaction (GLEntryID, GLTransaction, GLCo, GLAccount, Amount, ActDate, [Description])
		SELECT GLEntries.GLEntryID, ROW_NUMBER() OVER(PARTITION BY GLEntries.GLEntryID ORDER BY GLEntries.GLEntryID),
			vGLDistribution.GLCo, vGLDistribution.GLAccount, vGLDistribution.Amount, vGLDistribution.ActDate, vGLDistribution.[Description]
		FROM dbo.vSMWIPTransferBatch
			INNER JOIN dbo.vSMWorkCompleted ON vSMWIPTransferBatch.Co = vSMWorkCompleted.SMCo AND vSMWIPTransferBatch.WorkOrder = vSMWorkCompleted.WorkOrder AND vSMWIPTransferBatch.WorkCompleted = vSMWorkCompleted.WorkCompleted
			INNER JOIN @GLEntries GLEntries ON vSMWorkCompleted.SMWorkCompletedID = GLEntries.SMWorkCompletedID
			INNER JOIN dbo.vGLDistribution ON vSMWIPTransferBatch.Co = vGLDistribution.Co AND vSMWIPTransferBatch.Mth = vGLDistribution.Mth AND vSMWIPTransferBatch.BatchId = vGLDistribution.BatchId AND vSMWIPTransferBatch.BatchSeq = vGLDistribution.BatchSeq
		WHERE vSMWIPTransferBatch.Co = @SMCo AND vSMWIPTransferBatch.Mth = @BatchMonth AND vSMWIPTransferBatch.BatchId = @BatchId AND vSMWIPTransferBatch.TransferType = 'R' AND GLEntries.TransferType = 'R'

		INSERT dbo.vSMWorkCompletedGLEntry (GLEntryID, GLTransactionForSMDerivedAccount, SMWorkCompletedID)
		SELECT vGLEntryTransaction.GLEntryID, vGLEntryTransaction.GLTransaction, vSMWorkCompleted.SMWorkCompletedID
		FROM dbo.vSMWIPTransferBatch
			INNER JOIN dbo.vSMWorkCompleted ON vSMWIPTransferBatch.Co = vSMWorkCompleted.SMCo AND vSMWIPTransferBatch.WorkOrder = vSMWorkCompleted.WorkOrder AND vSMWIPTransferBatch.WorkCompleted = vSMWorkCompleted.WorkCompleted
			INNER JOIN @GLEntries GLEntries ON vSMWorkCompleted.SMWorkCompletedID = GLEntries.SMWorkCompletedID
			INNER JOIN dbo.vGLEntryTransaction ON GLEntries.GLEntryID = vGLEntryTransaction.GLEntryID AND vSMWIPTransferBatch.NewGLCo = vGLEntryTransaction.GLCo AND vSMWIPTransferBatch.NewGLAcct = vGLEntryTransaction.GLAccount
		WHERE vSMWIPTransferBatch.Co = @SMCo AND vSMWIPTransferBatch.Mth = @BatchMonth AND vSMWIPTransferBatch.BatchId = @BatchId AND vSMWIPTransferBatch.TransferType = 'R' AND GLEntries.TransferType = 'R'

		UPDATE vSMWorkCompleted
		SET RevenueSMWIPGLEntryID = GLEntries.GLEntryID
			OUTPUT deleted.RevenueSMWIPGLEntryID
				INTO @GLEntriesToDelete
		FROM @GLEntries GLEntries
			INNER JOIN dbo.vSMWorkCompleted ON GLEntries.SMWorkCompletedID = vSMWorkCompleted.SMWorkCompletedID

		DELETE vGLEntry
		FROM @GLEntriesToDelete GLEntriesToDelete
			INNER JOIN dbo.vGLEntry ON GLEntriesToDelete.GLEntryID = vGLEntry.GLEntryID
		------------------------------------------------------------------------------------------------------
		--END OF THE CODE THAT CAN BE REMOVED ONCE vSMDetailTransaction IS USED INSTEAD OF vSMWorkCompletedGL FOR WIP TRANSFERS
		------------------------------------------------------------------------------------------------------
		COMMIT TRAN
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN
		SET @msg = ERROR_MESSAGE()
		RETURN 1
	END CATCH

	DELETE dbo.vSMWIPTransferBatch
	WHERE Co = @SMCo AND Mth = @BatchMonth AND BatchId = @BatchId

	EXEC @rcode = dbo.vspGLDistributionPost @Source = @Source, @BatchCo = @SMCo, @BatchMonth = @BatchMonth, @BatchId = @BatchId, @DatePosted = @PostDate, @msg = @msg OUTPUT
	IF @rcode <> 0 RETURN @rcode

	--Set the transaction as posted and remove the batch related values
	UPDATE vSMDetailTransaction
	SET Posted = 1, HQBatchDistributionID = NULL, GLInterfaceLevel = @GLLvl
	FROM dbo.vHQBatchDistribution
		INNER JOIN dbo.vSMDetailTransaction ON vHQBatchDistribution.HQBatchDistributionID = vSMDetailTransaction.HQBatchDistributionID
	WHERE vHQBatchDistribution.Co = @SMCo AND vHQBatchDistribution.Mth = @BatchMonth AND vHQBatchDistribution.BatchId = @BatchId

    SELECT @BatchNotes = 'GL Revenue Interface Level set at: ' + dbo.vfToString(@GLLvl) + dbo.vfLineBreak()
    
	--Capture notes, set Status to posted and cleanup HQCC records
	EXEC @rcode = dbo.vspHQBatchPosted @BatchCo = @SMCo, @BatchMth = @BatchMonth, @BatchId = @BatchId, @Notes = @BatchNotes, @msg = @msg OUTPUT
	IF @rcode <> 0 RETURN @rcode
    
    RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMWIPTransferPost] TO [public]
GO
