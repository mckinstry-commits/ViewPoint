
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 4/28/11
-- Description:	This the GL Distribution posting which is currently used by the EM,IN and Misc GL
--				batch postings.
--	Changes:	6/7/13 TFS-52075 JVH Fixed the issue of having misc work completed show up as needing to be processed after wip transfer
-- =============================================
CREATE PROCEDURE [dbo].[vspSMGLDistributionPost]
	@SMCo bCompany, @BatchMth bMonth, @BatchId bBatchID, @PostDate bDate, @msg varchar(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @GLLvl varchar(50), @GLCo bCompany, @GLTrans bTrans, @GLRef bGLRef, @GLSumDesc varchar(60),
		@SMGLDistributionID bigint, @SMWorkCompletedID bigint, @IsMiscellaneousLineType bit, @CostOrRevenue char(1), @IsAccountTransfer bit,
		@SMGLEntryID bigint, @SMGLDetailTransactionID bigint, @ReversingSMGLEntryID bigint, @GLEntryID bigint, @GLEntryIDToDelete bigint

	SELECT @GLLvl = GLLvl, @GLSumDesc = dbo.vfToString(GLSumDesc)
	FROM dbo.vSMCO
	WHERE SMCo = @SMCo

	IF @GLLvl IS NULL
	BEGIN
		SET @msg = 'GL Interface level may not be null'
		RETURN 1
	END
	
	IF @GLLvl IN ('Detail', 'Summary')
		AND EXISTS(SELECT 1 FROM dbo.vSMGLDistribution INNER JOIN dbo.vSMGLEntry ON vSMGLDistribution.SMGLEntryID = vSMGLEntry.SMGLEntryID OR vSMGLDistribution.ReversingSMGLEntryID = vSMGLEntry.SMGLEntryID WHERE vSMGLDistribution.SMCo = @SMCo AND vSMGLDistribution.BatchMonth = @BatchMth AND vSMGLDistribution.BatchId = @BatchId AND vSMGLEntry.Journal IS NULL)
	BEGIN
		SET @msg = 'GL Journal must be set for all gl entries when posting in detail or summary'
		RETURN 1
	END
	
	--Set GL Reference using Batch Id - right justified 10 chars
    SET @GLRef = SPACE(10 - LEN(@BatchId)) + CAST(@BatchId AS varchar)

	DECLARE @SMGLEntriesToDelete TABLE (SMGLEntryID bigint)
	
	DECLARE @SummarizedGLDistributions TABLE (GLCo bCompany, GLAccount bGLAcct, Journal bJrnl, ActDate bDate, [Description] bTransDesc, Amount bDollar, GLTrans bTrans NULL)
	
	BEGIN TRAN
		IF @GLLvl = 'Summary'
		BEGIN
			--Add all the distributions that must be posted in detail according to the gl account
			INSERT @SummarizedGLDistributions
			SELECT vSMGLDetailTransaction.GLCo, vSMGLDetailTransaction.GLAccount, vSMGLEntry.Journal, vSMGLDetailTransaction.ActDate, vSMGLDetailTransaction.[Description], vSMGLDetailTransaction.Amount, NULL AS GLTrans
			FROM dbo.vSMGLDistribution
				INNER JOIN dbo.vSMGLEntry ON vSMGLDistribution.SMGLEntryID = vSMGLEntry.SMGLEntryID OR vSMGLDistribution.ReversingSMGLEntryID = vSMGLEntry.SMGLEntryID
				INNER JOIN dbo.vSMGLDetailTransaction ON vSMGLEntry.SMGLEntryID = vSMGLDetailTransaction.SMGLEntryID
				INNER JOIN dbo.GLAC ON vSMGLDetailTransaction.GLCo = GLAC.GLCo AND vSMGLDetailTransaction.GLAccount = GLAC.GLAcct
			WHERE vSMGLDistribution.SMCo = @SMCo AND vSMGLDistribution.BatchMonth = @BatchMth AND vSMGLDistribution.BatchId = @BatchId AND GLAC.InterfaceDetail = 'Y'

			--Any distributions that don't have to post in detail are now summed up
			INSERT @SummarizedGLDistributions
			SELECT vSMGLDetailTransaction.GLCo, vSMGLDetailTransaction.GLAccount, vSMGLEntry.Journal, @PostDate, @GLSumDesc, SUM(vSMGLDetailTransaction.Amount), NULL AS GLTrans
			FROM dbo.vSMGLDistribution
				INNER JOIN dbo.vSMGLEntry ON vSMGLDistribution.SMGLEntryID = vSMGLEntry.SMGLEntryID OR vSMGLDistribution.ReversingSMGLEntryID = vSMGLEntry.SMGLEntryID
				INNER JOIN dbo.vSMGLDetailTransaction ON vSMGLEntry.SMGLEntryID = vSMGLDetailTransaction.SMGLEntryID
				LEFT JOIN dbo.GLAC ON vSMGLDetailTransaction.GLCo = GLAC.GLCo AND vSMGLDetailTransaction.GLAccount = GLAC.GLAcct
			WHERE vSMGLDistribution.SMCo = @SMCo AND vSMGLDistribution.BatchMonth = @BatchMth AND vSMGLDistribution.BatchId = @BatchId AND ISNULL(GLAC.InterfaceDetail, 'N') <> 'Y'
			GROUP BY vSMGLDetailTransaction.GLCo, vSMGLDetailTransaction.GLAccount, vSMGLEntry.Journal
		END
		
		WorkCompletedUpdate:
		BEGIN
			SELECT TOP 1 @SMGLDistributionID = SMGLDistributionID, @SMWorkCompletedID = SMWorkCompletedID, @CostOrRevenue = CostOrRevenue, @IsAccountTransfer = IsAccountTransfer, @SMGLEntryID = SMGLEntryID, @SMGLDetailTransactionID = SMGLDetailTransactionID, @ReversingSMGLEntryID = ReversingSMGLEntryID
			FROM dbo.vSMGLDistribution
			WHERE SMCo = @SMCo AND BatchMonth = @BatchMth AND BatchId = @BatchId
			IF @@rowcount = 1
			BEGIN
				IF @GLLvl = 'Detail'
				BEGIN
					DELETE @SummarizedGLDistributions
				
					--Add all the distributions that must be posted in detail according to the gl account
					INSERT @SummarizedGLDistributions
					SELECT GLCo, GLAccount, Journal, ActDate, [Description], Amount, NULL AS GLTrans
					FROM dbo.vSMGLDistribution
						INNER JOIN dbo.vSMGLEntry ON vSMGLDistribution.SMGLEntryID = vSMGLEntry.SMGLEntryID OR vSMGLDistribution.ReversingSMGLEntryID = vSMGLEntry.SMGLEntryID
						INNER JOIN dbo.vSMGLDetailTransaction ON vSMGLEntry.SMGLEntryID = vSMGLDetailTransaction.SMGLEntryID
					WHERE vSMGLDistribution.SMGLDistributionID = @SMGLDistributionID
				END
				
				--If we are processing records in detail we will need to update the records being pushed to GLDT
				--every time we loop. If we are posting in summary the first time we go through the loop
				--we will update all the records with a GLTrans. Every time after that we loop we will have already
				--updated the GLTrans and therefore won't need to update them.
				UpdateGLTrans:
				BEGIN
					SELECT TOP 1 @GLCo = GLCo
					FROM @SummarizedGLDistributions
					WHERE GLTrans IS NULL
					IF @@rowcount = 1
					BEGIN
						EXEC @GLTrans = dbo.bspHQTCNextTrans @tablename = 'bGLDT', @co = @GLCo, @mth = @BatchMth, @errmsg = @msg OUTPUT
 						
						IF @GLTrans = 0
						BEGIN
							GOTO RollbackErrorFound
						END

						UPDATE TOP (1) @SummarizedGLDistributions
						SET GLTrans = @GLTrans
						WHERE GLCo = @GLCo AND GLTrans IS NULL
						
						GOTO UpdateGLTrans
					END
				END

				DELETE @SMGLEntriesToDelete
				
				--Capture all the GLEntries that we need to delete after doing updates.
				INSERT @SMGLEntriesToDelete
				SELECT GLEntryIDs.GLEntryID
				FROM dbo.vSMWorkCompletedGL
					CROSS APPLY	(
						SELECT CASE @CostOrRevenue WHEN 'C' THEN CostGLDetailTransactionEntryID WHEN 'R' THEN RevenueGLDetailTransactionEntryID END AS GLDetailTransactionEntryID,
							CASE @CostOrRevenue WHEN 'C' THEN CostGLEntryID WHEN 'R' THEN RevenueGLEntryID END AS GLEntryID) CostOrRevenueGLEntryIDs
					CROSS APPLY (
						SELECT GLEntryID
						WHERE @IsAccountTransfer = 0
						UNION ALL
						SELECT GLDetailTransactionEntryID
						WHERE @IsAccountTransfer = 0 OR GLDetailTransactionEntryID <> GLEntryID
						UNION ALL
						SELECT @ReversingSMGLEntryID AS GLEntryID) GLEntryIDs
				WHERE SMWorkCompletedID = @SMWorkCompletedID
			
				IF @CostOrRevenue = 'C'
				BEGIN
					--Account transfer only update the column that points to where the cost now lives.
					IF @IsAccountTransfer = 0
					BEGIN
						UPDATE dbo.vSMWorkCompletedGL
						SET CostGLEntryID = @SMGLEntryID, CostGLDetailTransactionEntryID = @SMGLEntryID, CostGLDetailTransactionID = @SMGLDetailTransactionID
						WHERE SMWorkCompletedID = @SMWorkCompletedID
					END
					ELSE
					BEGIN
						UPDATE dbo.vSMWorkCompletedGL
						SET CostGLDetailTransactionEntryID = @SMGLEntryID, CostGLDetailTransactionID = @SMGLDetailTransactionID
						WHERE SMWorkCompletedID = @SMWorkCompletedID

						--HACK To make sure misc work completed doesn't show up as needing to be reprocessed the date is updated
						--with the work completed date. This also causes the gl for future adjustments to the work completed
						--to use the correct date(the work completed date).
						UPDATE vSMGLDetailTransaction
						SET ActDate = (SELECT [Date] FROM dbo.vSMWorkCompletedDetail WHERE SMWorkCompletedID = @SMWorkCompletedID AND IsSession = 0)
						WHERE SMGLDetailTransactionID = @SMGLDetailTransactionID
					END
				END
				
				IF @CostOrRevenue = 'R'
				BEGIN
					--Account transfer only update the column that points to where the revenue now lives.
					IF @IsAccountTransfer = 0
					BEGIN
						UPDATE dbo.vSMWorkCompletedGL
						SET RevenueGLEntryID = @SMGLEntryID, RevenueGLDetailTransactionEntryID = @SMGLEntryID, RevenueGLDetailTransactionID = @SMGLDetailTransactionID
						WHERE SMWorkCompletedID = @SMWorkCompletedID
					END
					ELSE
					BEGIN
						UPDATE dbo.vSMWorkCompletedGL
						SET RevenueGLDetailTransactionEntryID = @SMGLEntryID, RevenueGLDetailTransactionID = @SMGLDetailTransactionID
						WHERE SMWorkCompletedID = @SMWorkCompletedID
						
						--JC Revenue is using the GLEntries from the vSMWorkCompleted record so it needs to be updated.
						EXEC @GLEntryID = dbo.vspGLCreateEntry @Source = 'SM WIP', @TransactionsShouldBalance =  1, @msg = @msg OUTPUT

						IF @GLEntryID = -1 GOTO RollbackErrorFound

						INSERT dbo.vGLEntryTransaction (GLEntryID, GLTransaction, GLCo, GLAccount, Amount, ActDate, [Description])
						SELECT @GLEntryID, 1, GLCo, GLAccount, Amount, ActDate, [Description]
						FROM vSMGLDetailTransaction
						WHERE SMGLDetailTransactionID = @SMGLDetailTransactionID
						UNION ALL
						SELECT @GLEntryID, ROW_NUMBER() OVER(ORDER BY SMGLDetailTransactionID) + 1, GLCo, GLAccount, Amount, ActDate, [Description]
						FROM vSMGLDetailTransaction
						WHERE SMGLEntryID = @SMGLEntryID AND SMGLDetailTransactionID <> @SMGLDetailTransactionID

						INSERT dbo.vSMWorkCompletedGLEntry (GLEntryID, GLTransactionForSMDerivedAccount, SMWorkCompletedID)
						VALUES (@GLEntryID, 1, @SMWorkCompletedID)
						
						UPDATE dbo.vSMWorkCompleted
						SET @GLEntryIDToDelete = RevenueSMWIPGLEntryID, RevenueSMWIPGLEntryID = @GLEntryID
						WHERE SMWorkCompletedID = @SMWorkCompletedID
						
						DELETE dbo.vGLEntry
						WHERE GLEntryID = @GLEntryIDToDelete
					END
				END
				
				DELETE dbo.vSMGLDistribution
				WHERE SMGLDistributionID = @SMGLDistributionID
				
				DELETE dbo.vSMGLEntry
				WHERE SMGLEntryID IN (SELECT SMGLEntryID FROM @SMGLEntriesToDelete)
				
				--Get rid of the work completed's GL entry if the entry is no longer pointing
				--to any gl entries or gl details since it is no longer needed.
				DELETE dbo.vSMWorkCompletedGL
				WHERE SMWorkCompletedID = @SMWorkCompletedID
					AND 1 = (dbo.vfEqualsNull(CostGLEntryID) & dbo.vfEqualsNull(CostGLDetailTransactionEntryID) & dbo.vfEqualsNull(CostGLDetailTransactionID) &
						dbo.vfEqualsNull(RevenueGLEntryID) & dbo.vfEqualsNull(RevenueGLDetailTransactionEntryID) & dbo.vfEqualsNull(RevenueGLDetailTransactionID))

				IF @GLLvl = 'Detail'
				BEGIN
					INSERT dbo.bGLDT (GLCo, Mth, GLTrans, GLAcct, Jrnl, GLRef, SourceCo, Source, ActDate, DatePosted,
						[Description], BatchId, Amount, RevStatus, Adjust, InUseBatchId, Purge)
					SELECT GLCo, @BatchMth, GLTrans, GLAccount, Journal, @GLRef, @SMCo, 'SM WO', ActDate, @PostDate,
						[Description], @BatchId, Amount, 0, 'N', NULL, 'N'
					FROM @SummarizedGLDistributions
--With detail records we want to commit the transaction each time we are done processing a distribution record
--That way we can process as much of a batch as possible and then if we bomb out we pick up from where we left off.
/*TRAN COMMIT*/		COMMIT TRAN
/*TRAN BEGIN*/		BEGIN TRAN
				END

				GOTO WorkCompletedUpdate
			END
		END
		
		IF @GLLvl = 'Summary'
		BEGIN
			INSERT dbo.bGLDT (GLCo, Mth, GLTrans, GLAcct, Jrnl, GLRef, SourceCo, Source, ActDate, DatePosted,
				[Description], BatchId, Amount, RevStatus, Adjust, InUseBatchId, Purge)
			SELECT GLCo, @BatchMth, GLTrans, GLAccount, Journal, @GLRef, @SMCo, 'SM WO', ActDate, @PostDate,
				[Description], @BatchId, Amount, 0, 'N', NULL, 'N'
			FROM @SummarizedGLDistributions
		END
	
	COMMIT TRAN
	
	RETURN 0

RollbackErrorFound:
	--If an error is found then we need to properly handle the rollback
	--The assumption is if the transaction count = 1 then we are not in a nested
	--transaction and we can safely rollback. However, if the transaction count is greater than 1
	--then we are in a nested transaction and we need to make sure that the transaction count
	--when we entered the stored procedure matches the transaction count when we leave the stored procedure.
	--Then by returning 1 the rollback can be done from whatever sql executed this stored procedure.
	IF @@trancount = 1 ROLLBACK TRAN ELSE COMMIT TRAN
	RETURN 1
END
GO

GRANT EXECUTE ON  [dbo].[vspSMGLDistributionPost] TO [public]
GO
