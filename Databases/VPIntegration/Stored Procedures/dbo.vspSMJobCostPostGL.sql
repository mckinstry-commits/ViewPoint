SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 5/4/12
-- Description:	Post the GL distributions created for SM Job Cost integration
-- =============================================
CREATE PROCEDURE [dbo].[vspSMJobCostPostGL]
	@GLEntrySource bSource, @BatchCo bCompany, @BatchMth bMonth, @BatchId bBatchID, @PostedDate bDate, @msg varchar(255) = NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @rcode int, @SMWorkCompletedID bigint, @WorkCompletedGLUpdateID smallint, @GLEntryID bigint, @SMGLEntryID bigint, @SMGLDetailTransactionID bigint

	DECLARE @WorkCompletedGLUpdates TABLE (WorkCompletedGLUpdateID smallint NOT NULL IDENTITY(1,1), SMWorkCompletedID bigint NOT NULL, GLEntryID bigint NOT NULL, IsReversing bit NOT NULL)

	DECLARE @GLEntryIDToDelete TABLE (RevenueGLEntryID bigint NULL, RevenueSMWIPGLEntryID bigint NULL, RevenueJCWIPGLEntryID bigint NULL)

	--The GLEntrys for the given batch are added to a table variable so that the work completed can be
	--updated with the new GLEntrys.
	INSERT @WorkCompletedGLUpdates (SMWorkCompletedID, GLEntryID, IsReversing)
	SELECT vSMWorkCompletedGLEntry.SMWorkCompletedID, vSMWorkCompletedGLEntry.GLEntryID, GLEntryBatch.IsReversing
	FROM dbo.vfGLEntryBatch(@GLEntrySource, @BatchCo, @BatchMth, @BatchId) GLEntryBatch
		INNER JOIN dbo.vSMWorkCompletedGLEntry ON GLEntryBatch.GLEntryID = vSMWorkCompletedGLEntry.GLEntryID
	
	BEGIN TRY
		--A transaction is used to ensure that everything is committed or nothing is so if something fails
		--mid-way re-posting can be done.
		BEGIN TRAN

		UPDATE vSMWorkCompleted
		SET RevenueGLEntryID = NULL, RevenueSMWIPGLEntryID = NULL, RevenueJCWIPGLEntryID = NULL
			OUTPUT DELETED.RevenueGLEntryID, DELETED.RevenueSMWIPGLEntryID, DELETED.RevenueJCWIPGLEntryID
				INTO @GLEntryIDToDelete
		FROM @WorkCompletedGLUpdates WorkCompletedGLUpdates
			INNER JOIN vSMWorkCompleted ON WorkCompletedGLUpdates.SMWorkCompletedID = vSMWorkCompleted.SMWorkCompletedID
		WHERE WorkCompletedGLUpdates.IsReversing = 1
		
		UPDATE vSMWorkCompleted
		SET RevenueGLEntryID = GLEntryID, RevenueSMWIPGLEntryID = NULL, RevenueJCWIPGLEntryID = NULL
			OUTPUT DELETED.RevenueGLEntryID, DELETED.RevenueSMWIPGLEntryID, DELETED.RevenueJCWIPGLEntryID
				INTO @GLEntryIDToDelete
		FROM @WorkCompletedGLUpdates WorkCompletedGLUpdates
			INNER JOIN vSMWorkCompleted ON WorkCompletedGLUpdates.SMWorkCompletedID = vSMWorkCompleted.SMWorkCompletedID
		WHERE WorkCompletedGLUpdates.IsReversing = 0
		
		DELETE vPRLedgerUpdateMonth
		FROM @GLEntryIDToDelete GLEntryIDToDelete
			INNER JOIN dbo.vGLEntry ON vGLEntry.GLEntryID IN (GLEntryIDToDelete.RevenueGLEntryID, GLEntryIDToDelete.RevenueSMWIPGLEntryID, GLEntryIDToDelete.RevenueJCWIPGLEntryID)
			INNER JOIN dbo.vPRLedgerUpdateMonth ON vGLEntry.PRLedgerUpdateMonthID = vPRLedgerUpdateMonth.PRLedgerUpdateMonthID
		
		DELETE vGLEntry
		FROM @GLEntryIDToDelete GLEntryIDToDelete
			INNER JOIN dbo.vGLEntry ON vGLEntry.GLEntryID IN (GLEntryIDToDelete.RevenueGLEntryID, GLEntryIDToDelete.RevenueSMWIPGLEntryID, GLEntryIDToDelete.RevenueJCWIPGLEntryID)

		--Currently vSMWorkCompletedGL is still being used for tracking GL for revenue WIP transfer purposes.
		--Once AR is refactored to use the revenue columns on vSMWorkCompleted and the revenue WIP transfer process is refactored
		--there will be no need for the code related to updating vSMGL for revenue.
		DELETE @GLEntryIDToDelete

		UPDATE vSMWorkCompletedGL
		SET RevenueGLEntryID = NULL, RevenueGLDetailTransactionEntryID = NULL, RevenueGLDetailTransactionID = NULL
			OUTPUT DELETED.RevenueGLEntryID, DELETED.RevenueGLDetailTransactionEntryID
				INTO @GLEntryIDToDelete (RevenueGLEntryID, RevenueSMWIPGLEntryID)
		FROM @WorkCompletedGLUpdates WorkCompletedGLUpdates
			INNER JOIN dbo.vSMWorkCompletedGL ON WorkCompletedGLUpdates.SMWorkCompletedID = vSMWorkCompletedGL.SMWorkCompletedID
		WHERE WorkCompletedGLUpdates.IsReversing = 1
		
		DELETE @WorkCompletedGLUpdates
		WHERE IsReversing = 1
		
		WHILE EXISTS(SELECT 1 FROM @WorkCompletedGLUpdates)
		BEGIN
			SELECT TOP 1 @WorkCompletedGLUpdateID = WorkCompletedGLUpdateID, @SMWorkCompletedID = SMWorkCompletedID, @GLEntryID = GLEntryID
			FROM @WorkCompletedGLUpdates
			
			IF NOT EXISTS(SELECT 1 FROM dbo.vSMWorkCompletedGL WHERE SMWorkCompletedID = @SMWorkCompletedID)
			BEGIN
				INSERT dbo.vSMWorkCompletedGL (SMWorkCompletedID, SMCo, IsMiscellaneousLineType)
				SELECT SMWorkCompletedID, SMCo, 0
				FROM dbo.vSMWorkCompleted
				WHERE SMWorkCompletedID = @SMWorkCompletedID
			END

			INSERT dbo.vSMGLEntry (SMWorkCompletedID, TransactionsShouldBalance)
			VALUES (@SMWorkCompletedID, 0)
			
			SET @SMGLEntryID = SCOPE_IDENTITY()
			
			INSERT dbo.vSMGLDetailTransaction (SMGLEntryID, IsTransactionForSMDerivedAccount, GLCo, GLAccount, Amount, ActDate, [Description])
			SELECT @SMGLEntryID, 1, vGLEntryTransaction.GLCo, vGLEntryTransaction.GLAccount, vGLEntryTransaction.Amount, vGLEntryTransaction.ActDate, vGLEntryTransaction.[Description]
			FROM dbo.vSMWorkCompletedGLEntry
				INNER JOIN dbo.vGLEntryTransaction ON vSMWorkCompletedGLEntry.GLEntryID = vGLEntryTransaction.GLEntryID AND vSMWorkCompletedGLEntry.GLTransactionForSMDerivedAccount = vGLEntryTransaction.GLTransaction
			WHERE vSMWorkCompletedGLEntry.GLEntryID = @GLEntryID
			
			SET @SMGLDetailTransactionID = SCOPE_IDENTITY()
			
			UPDATE dbo.vSMWorkCompletedGL
			SET RevenueGLEntryID = @SMGLEntryID, RevenueGLDetailTransactionEntryID = NULL, RevenueGLDetailTransactionID = @SMGLDetailTransactionID
				OUTPUT DELETED.RevenueGLEntryID, DELETED.RevenueGLDetailTransactionEntryID
					INTO @GLEntryIDToDelete (RevenueGLEntryID, RevenueSMWIPGLEntryID)
			WHERE SMWorkCompletedID = @SMWorkCompletedID
			
			DELETE @WorkCompletedGLUpdates
			WHERE WorkCompletedGLUpdateID = @WorkCompletedGLUpdateID
		END

		DELETE dbo.vSMGLEntry
		FROM @GLEntryIDToDelete GLEntryIDToDelete
			INNER JOIN vSMGLEntry ON vSMGLEntry.SMGLEntryID IN (GLEntryIDToDelete.RevenueGLEntryID, GLEntryIDToDelete.RevenueSMWIPGLEntryID)

		COMMIT TRAN
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN
		SET @msg = ERROR_MESSAGE()
		RETURN 1
	END CATCH
	
	--Post the records to GLDT
	DELETE dbo.vGLEntryBatchInterfacing
	WHERE GLEntrySource = @GLEntrySource AND BatchCo = @BatchCo AND BatchMth = @BatchMth AND BatchId = @BatchId

	--Build out the table for relating the GLEntrys to how they should be posted.
	INSERT dbo.vGLEntryBatchInterfacing (GLEntrySource, BatchCo, BatchMth, BatchId, InterfacingCo, InterfaceLevel, Journal, SummaryDescription)
	SELECT DISTINCT @GLEntrySource, @BatchCo, @BatchMth, @BatchId, bJCCO.JCCo, CASE WHEN vSMCO.UseJCInterface = 'N' THEN 0 ELSE bJCCO.GLCostLevel END, bJCCO.GLCostJournal, bJCCO.GLCostSummaryDesc
	FROM dbo.vfGLEntryBatch(@GLEntrySource, @BatchCo, @BatchMth, @BatchId)
		INNER JOIN dbo.bJCCO ON vfGLEntryBatch.InterfacingCo = bJCCO.JCCo
		LEFT JOIN dbo.vSMWorkCompletedGLEntry ON vfGLEntryBatch.GLEntryID = vSMWorkCompletedGLEntry.GLEntryID
		LEFT JOIN dbo.vSMWorkCompleted ON vSMWorkCompletedGLEntry.SMWorkCompletedID = vSMWorkCompleted.SMWorkCompletedID
		LEFT JOIN dbo.vSMCO ON vSMWorkCompleted.SMCo = vSMCO.SMCo

	EXEC @rcode = dbo.vspGLEntryBatchPost @GLEntrySource = @GLEntrySource, @BatchCo = @BatchCo, @BatchMonth = @BatchMth, @BatchId = @BatchId, @DatePosted = @PostedDate, @msg = @msg OUTPUT
	IF @rcode <> 0 RETURN @rcode
	
	DELETE dbo.vGLEntryBatchInterfacing
	WHERE GLEntrySource = @GLEntrySource AND BatchCo = @BatchCo AND BatchMth = @BatchMth AND BatchId = @BatchId
END
GO
GRANT EXECUTE ON  [dbo].[vspSMJobCostPostGL] TO [public]
GO
