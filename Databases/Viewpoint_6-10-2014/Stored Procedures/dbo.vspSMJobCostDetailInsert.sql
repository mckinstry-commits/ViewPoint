SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:	TRL		
-- Create date:  02/2012
-- Description:	TK-12747 Used to create a Job Cost Detail transaction for SM Work Orders associated with Job.
--called from vspSMEMUsageBatchPosting and vspSMINBatchPost
-- Modifications: 03/19/2012 TL TK - 13408 fixed code for SM/JC TaxCode Phase/Cost Redirect
--						04/12/2012 TL TK - 14136 Added code to sort  JC Cost Distributions and remove JC Trans infor for deleted transactions
--						04/30/2012 TL  TK - 14603	Added code to incorporated committed cost columns
--						TL 05/01/2012 - TK-14606 Added code to create records in JCJP and JCCH 
--						TL 05/21/2012 TK-15003 Added column ActualUnitCost to update and added Column RemainCmtdUnits
--						LG 01/03/2013 TK-20303 Added JC Interface Flag check so that it doesnt post to GLDT when interface Flag is turned off.
--						JVH 4/3/13 TFS-38853 Updated to handle changes to vSMJobCostDistribution
-- =============================================
CREATE PROCEDURE [dbo].[vspSMJobCostDetailInsert]
	@BatchCo bCompany, @BatchMth bMonth, @BatchId bBatchID, @errmsg varchar(255) = NULL OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	--This should probaly be a paramter
	DECLARE @DatePosted bDate
	SET @DatePosted = dbo.vfDateOnly()

	DECLARE @rcode int, @JCCo bCompany, @Job bJob, @PhaseGroup bGroup, @Phase bPhase, @UM bUM, @Description bItemDesc,
		@Contract bContract, @ContractItem bContractItem, @ProjMinPct bPct, @JCCostType bJCCType,
		@RowCount int, @CostTrans bTrans

	AddPhases:
	BEGIN
		SELECT TOP 1 @JCCo = vSMJobCostDistribution.JCCo, @Job = vSMJobCostDistribution.Job, @PhaseGroup = vSMJobCostDistribution.PhaseGroup, @Phase = vSMJobCostDistribution.Phase,
			@UM = vSMJobCostDistribution.PostedUM
		FROM dbo.vSMJobCostDistribution
			LEFT JOIN dbo.bJCJP ON vSMJobCostDistribution.JCCo = bJCJP.JCCo AND vSMJobCostDistribution.Job = bJCJP.Job AND vSMJobCostDistribution.PhaseGroup = bJCJP.PhaseGroup AND vSMJobCostDistribution.Phase = bJCJP.Phase
		WHERE vSMJobCostDistribution.BatchCo = @BatchCo AND vSMJobCostDistribution.BatchMth = @BatchMth AND vSMJobCostDistribution.BatchID = @BatchId AND bJCJP.KeyID IS NULL

		IF @@rowcount <> 0
		BEGIN
			--Get Required fields for JC Job Phase Insert
			--Get Job Contract and default Phase Projection Min% from Job Master
			SELECT @Contract = [Contract], @ProjMinPct=ProjMinPct FROM dbo.JCJM WHERE JCCo = @JCCo AND Job = @Job
			--Get min Contract Item for Job and assign it to Phase
			SELECT @ContractItem = MIN(Item) FROM dbo.JCCI WHERE JCCo = @JCCo AND [Contract] = @Contract
			--Get JC Phase Master phase description for insert
			SELECT @Description = [Description] FROM dbo.JCPM where PhaseGroup = @PhaseGroup and Phase = @Phase

			--Create JC Job Phase in JCJP
			EXEC @rcode = dbo.vspJCJPAdd @JCCo = @JCCo, @Job = @Job, @PhaseGroup = @PhaseGroup, @Phase = @Phase, @Desc = @Description, @Contract = @Contract, @Item = @ContractItem, @ProjMinPct = @ProjMinPct, @ActiveYN = 'Y', @msg = @errmsg OUTPUT
			IF @rcode <> 0
			BEGIN
				RETURN 1
			END

			GOTO AddPhases
		END
	END

	AddCostTypes:
	BEGIN
		SELECT TOP 1 @JCCo = vSMJobCostDistribution.JCCo, @Job = vSMJobCostDistribution.Job, @PhaseGroup = vSMJobCostDistribution.PhaseGroup, @Phase = vSMJobCostDistribution.Phase,
			 @JCCostType = vSMJobCostDistribution.CostType, @UM = vSMJobCostDistribution.PostedUM
		FROM dbo.vSMJobCostDistribution
			LEFT JOIN dbo.bJCCH ON vSMJobCostDistribution.JCCo = bJCCH.JCCo AND vSMJobCostDistribution.Job = bJCCH.Job AND vSMJobCostDistribution.PhaseGroup = bJCCH.PhaseGroup AND vSMJobCostDistribution.Phase = bJCCH.Phase AND vSMJobCostDistribution.CostType = bJCCH.CostType
		WHERE vSMJobCostDistribution.BatchCo = @BatchCo AND vSMJobCostDistribution.BatchMth = @BatchMth AND vSMJobCostDistribution.BatchID = @BatchId AND bJCCH.KeyID IS NULL

		IF @@rowcount <> 0
		BEGIN
			EXEC @rcode = dbo.bspJCADDCOSTTYPE @jcco = @JCCo, @job = @Job, @phasegroup = @PhaseGroup, @phase = @Phase, @costtype = @JCCostType,
				@um = @UM, @billflag = 'Y', @itemunitflag = 'N', @phaseunitflag = 'N', @buyoutyn = 'N', @activeyn = 'Y', @override = 'N', @msg = @errmsg OUTPUT
			IF @rcode <> 0
			BEGIN
				RETURN 1
			END	

			GOTO AddCostTypes
		END
	END

	DELETE vSMJobCostDistribution
	FROM dbo.vSMJobCostDistribution
		INNER JOIN dbo.vSMCO ON vSMJobCostDistribution.SMCo = vSMCO.SMCo
	WHERE vSMJobCostDistribution.BatchCo = @BatchCo AND vSMJobCostDistribution.BatchMth = @BatchMth AND vSMJobCostDistribution.BatchID = @BatchId AND vSMCO.UseJCInterface = 'N'

	WHILE EXISTS(SELECT 1 FROM dbo.vSMJobCostDistribution WHERE BatchCo = @BatchCo AND BatchMth = @BatchMth AND BatchID = @BatchId)
	BEGIN
		SELECT TOP 1 @JCCo = JCCo
		FROM dbo.vSMJobCostDistribution
		WHERE BatchCo = @BatchCo AND BatchMth = @BatchMth AND BatchID = @BatchId

		SELECT @RowCount = COUNT(1)
		FROM dbo.vSMJobCostDistribution
		WHERE BatchCo = @BatchCo AND BatchMth = @BatchMth AND BatchID = @BatchId AND JCCo = @JCCo

		BEGIN TRY
			BEGIN TRAN

			--Update HQTC with the next JCCD Trans
			EXEC @CostTrans = dbo.bspHQTCNextTransWithCount @tablename = 'bJCCD', @co = @JCCo, @mth = @BatchMth, @count = @RowCount, @errmsg = @errmsg OUTPUT

			IF @CostTrans = 0
			BEGIN
				ROLLBACK TRAN
				RETURN 1
			END

			--Set the Trans to the starting value for the records
			SET @CostTrans = @CostTrans - @RowCount

			--Update all the Trans values for the records
			UPDATE dbo.vSMJobCostDistribution
			SET @CostTrans = @CostTrans + 1, CostTrans = @CostTrans
			FROM dbo.vSMJobCostDistribution
			WHERE BatchCo = @BatchCo AND BatchMth = @BatchMth AND BatchID = @BatchId AND JCCo = @JCCo

			--Update the trans in the gl transactions
			UPDATE vGLEntryTransaction
			SET [Description] = REPLACE(vGLEntryTransaction.[Description], 'Trans #', dbo.vfToString(vSMJobCostDistribution.CostTrans))
			FROM dbo.vSMJobCostDistribution
				LEFT JOIN dbo.vSMWorkCompletedBatch ON vSMJobCostDistribution.BatchCo = vSMWorkCompletedBatch.BatchCo AND vSMJobCostDistribution.BatchMth = vSMWorkCompletedBatch.BatchMonth AND vSMJobCostDistribution.BatchID = vSMWorkCompletedBatch.BatchId AND
					vSMJobCostDistribution.SMWorkCompletedID = vSMWorkCompletedBatch.SMWorkCompletedID
				LEFT JOIN dbo.vGLEntryTransaction ON (vSMWorkCompletedBatch.CurrentRevenueGLEntryID = vGLEntryTransaction.GLEntryID OR vSMWorkCompletedBatch.ReversingRevenueGLEntryID = vGLEntryTransaction.GLEntryID) AND
					vSMJobCostDistribution.IsReversingEntry = CASE vGLEntryTransaction.DetailTransGroup WHEN 1 THEN 0 WHEN 2 THEN 0 WHEN 3 THEN 1 WHEN 4 THEN 1 END AND 
					vSMJobCostDistribution.IsTaxRedirect = CASE vGLEntryTransaction.DetailTransGroup WHEN 1 THEN 0 WHEN 2 THEN 1 WHEN 3 THEN 0 WHEN 4 THEN 1 END
			WHERE vSMJobCostDistribution.BatchCo = @BatchCo AND vSMJobCostDistribution.BatchMth = @BatchMth AND vSMJobCostDistribution.BatchID = @BatchId AND vSMJobCostDistribution.JCCo = @JCCo

			INSERT dbo.JCCD (JCCo,	Mth, CostTrans,Job,Phase,	PhaseGroup,	CostType, UM, 
			JCTransType,Source,JBBillStatus,[Description],PostedDate,ActualDate,
			EMCo,EMEquip,EMGroup,EMRevCode,	
			PRCo,Employee,
			APCo,PO,POItem,POItemLine,VendorGroup,Vendor,
			INCo,MatlGroup,Loc,Material, PostedUM,PerECM,
			ActualUnitCost,ActualHours, ActualUnits,ActualCost,
			PostedUnits,PostedUnitCost,	PostedECM,		
			INStdUnitCost,INStdECM,INStdUM,
			TaxType,TaxGroup,TaxCode,TaxBasis,TaxAmt,
			SMWorkCompletedID,SMCo,SMWorkOrder,SMScope,
			PostRemCmUnits,RemainCmtdUnits,RemainCmtdCost,RemCmtdTax) 

			SELECT JCCo,BatchMth,CostTrans,Job,Phase,PhaseGroup,CostType,JobPhaseCostTypeUM,
				JCTransType,'SM WorkOrd',0,[Description],PostedDate, dbo.vfDateOnly(), 
			EMCo,Equipment,EMGroup,RevCode,	
			PRCo,Employee,
			POCo,PO,POItem,POItemLine,VendorGroup,Vendor,
			INCo,MatlGroup,Loc,Material,PostedUM,PECM,
			IsNULL(ActualUnitCost,0),IsNull(ActualHours,0),IsNull(ActualUnits,0),IsNull(ActualCost,0),
			IsNull(PostedUnits,0),IsNull(PostedUnitCost,0),PostedECM,
			IsNull(INStkUnitCost,0),INStkECM,INStkUM,
			TaxType,TaxGroup,TaxCode,IsNull(TaxBasis,0),IsNull(TaxAmt,0),
			SMWorkCompletedID,SMCo,SMWorkOrder,SMScope,
			ISNULL(PostRemCmUnits,0),ISNULL(RemainCmtdUnits,0),ISNULL(RemainCmtdCost,0),ISNULL(RemCmtdTax,0)
			FROM dbo.vSMJobCostDistribution
			WHERE BatchCo = @BatchCo AND BatchMth = @BatchMth AND BatchID = @BatchId AND JCCo = @JCCo

			UPDATE dbo.vSMWorkCompleted
			SET JCCo = NULL, JCMth = NULL, JCCostTrans = NULL, JCCostTaxTrans = NULL
			FROM dbo.vSMJobCostDistribution
				INNER JOIN dbo.vSMWorkCompleted ON vSMJobCostDistribution.SMWorkCompletedID = vSMWorkCompleted.SMWorkCompletedID
			WHERE vSMJobCostDistribution.BatchCo = @BatchCo AND vSMJobCostDistribution.BatchMth = @BatchMth AND vSMJobCostDistribution.BatchID = @BatchId AND vSMJobCostDistribution.JCCo = @JCCo AND vSMJobCostDistribution.IsReversingEntry = 1

			UPDATE dbo.vSMWorkCompleted
			SET JCCo = vSMJobCostDistribution.JCCo, JCMth = vSMJobCostDistribution.BatchMth, JCCostTrans = vSMJobCostDistribution.CostTrans
			FROM dbo.vSMJobCostDistribution
				INNER JOIN dbo.vSMWorkCompleted ON vSMJobCostDistribution.SMWorkCompletedID = vSMWorkCompleted.SMWorkCompletedID
			WHERE vSMJobCostDistribution.BatchCo = @BatchCo AND vSMJobCostDistribution.BatchMth = @BatchMth AND vSMJobCostDistribution.BatchID = @BatchId AND vSMJobCostDistribution.JCCo = @JCCo AND
				vSMJobCostDistribution.IsReversingEntry = 0 AND vSMJobCostDistribution.IsTaxRedirect = 0

			UPDATE dbo.vSMWorkCompleted
			SET JCCostTaxTrans = vSMJobCostDistribution.CostTrans
			FROM dbo.vSMJobCostDistribution
				INNER JOIN dbo.vSMWorkCompleted ON vSMJobCostDistribution.SMWorkCompletedID = vSMWorkCompleted.SMWorkCompletedID
			WHERE vSMJobCostDistribution.BatchCo = @BatchCo AND vSMJobCostDistribution.BatchMth = @BatchMth AND vSMJobCostDistribution.BatchID = @BatchId AND vSMJobCostDistribution.JCCo = @JCCo AND
				vSMJobCostDistribution.IsReversingEntry = 0  AND vSMJobCostDistribution.IsTaxRedirect = 1

			DELETE dbo.vSMJobCostDistribution
			WHERE BatchCo = @BatchCo AND BatchMth = @BatchMth AND BatchID = @BatchId AND JCCo = @JCCo

			COMMIT TRAN
		END TRY
		BEGIN CATCH
			SET @errmsg = ERROR_MESSAGE()
			ROLLBACK TRAN
			RETURN 1
		END CATCH
	END

	--Update the work completed to capture the JCCostEntry and get rid of the old and reversing cost entries.
	DECLARE @JCCostEntriesToDelete TABLE (JCCostEntryID bigint)

	INSERT @JCCostEntriesToDelete
	SELECT vSMWorkCompletedBatch.ReversingJCCostEntryID
	FROM dbo.vSMWorkCompletedBatch
	WHERE vSMWorkCompletedBatch.BatchCo = @BatchCo AND vSMWorkCompletedBatch.BatchMonth = @BatchMth AND vSMWorkCompletedBatch.BatchId = @BatchId

	UPDATE vSMWorkCompleted
	SET JCCostEntryID = vSMWorkCompletedBatch.CurrentJCCostEntryID
		OUTPUT DELETED.JCCostEntryID
			INTO @JCCostEntriesToDelete
	FROM dbo.vSMWorkCompletedBatch
		INNER JOIN dbo.vSMWorkCompleted ON vSMWorkCompletedBatch.SMWorkCompletedID = vSMWorkCompleted.SMWorkCompletedID
	WHERE vSMWorkCompletedBatch.BatchCo = @BatchCo AND vSMWorkCompletedBatch.BatchMonth = @BatchMth AND vSMWorkCompletedBatch.BatchId = @BatchId

	DELETE vJCCostEntry
	WHERE JCCostEntryID IN (SELECT JCCostEntryID FROM @JCCostEntriesToDelete)

	--Post the GL distributions to GLDT
	DECLARE @GLEntriesToProcess TABLE (GLEntryID bigint, JCCo bCompany)

	DECLARE @GLCostLevel tinyint, @GLCostJournal bJrnl, @GLCostSummaryDesc varchar(60)

	INSERT @GLEntriesToProcess (GLEntryID, JCCo)
	SELECT vGLEntryBatch.GLEntryID, vGLEntryBatch.InterfacingCo
	FROM dbo.vGLEntryBatch
		INNER JOIN dbo.vGLEntry ON vGLEntryBatch.GLEntryID = vGLEntry.GLEntryID
		INNER JOIN dbo.vSMWorkCompletedBatch ON (vGLEntryBatch.GLEntryID = vSMWorkCompletedBatch.CurrentRevenueGLEntryID OR vGLEntryBatch.GLEntryID = vSMWorkCompletedBatch.ReversingRevenueGLEntryID) AND vGLEntryBatch.Co = vSMWorkCompletedBatch.BatchCo AND vGLEntryBatch.Mth = vSMWorkCompletedBatch.BatchMonth AND vGLEntryBatch.BatchId = vSMWorkCompletedBatch.BatchId
		INNER JOIN dbo.vSMWorkCompleted ON vSMWorkCompletedBatch.SMWorkCompletedID = vSMWorkCompleted.SMWorkCompletedID
		INNER JOIN dbo.vSMCO ON vSMWorkCompleted.SMCo = vSMCO.SMCo
	WHERE vGLEntryBatch.Co = @BatchCo AND vGLEntryBatch.Mth = @BatchMth AND vGLEntryBatch.BatchId = @BatchId AND vGLEntry.[Source] = 'SM Job' AND vGLEntryBatch.PostedToGL = 0 AND vSMCO.UseJCInterface = 'Y'

	--The batch may have records for multiple JC companies so the gl is posted by JC company.
	WHILE EXISTS(SELECT 1 FROM @GLEntriesToProcess)
	BEGIN
		SELECT TOP 1 @JCCo = JCCo
		FROM @GLEntriesToProcess
		
		SELECT @GLCostLevel = GLCostLevel, @GLCostJournal = GLCostJournal, @GLCostSummaryDesc = dbo.vfToString(GLCostSummaryDesc)
		FROM dbo.bJCCO
		WHERE JCCo = @JCCo
		
		UPDATE vGLEntryBatch
		SET ReadyToProcess = 1
		FROM dbo.vGLEntryBatch
			INNER JOIN @GLEntriesToProcess GLEntriesToProcess ON vGLEntryBatch.GLEntryID = GLEntriesToProcess.GLEntryID
		WHERE GLEntriesToProcess.JCCo = @JCCo

		EXEC @rcode = dbo.vspGLEntryPost @Co = @BatchCo, @BatchMonth = @BatchMth, @BatchId = @BatchId, @InterfaceLevel = @GLCostLevel, @Journal = @GLCostJournal, @SummaryDescription = @GLCostSummaryDesc, @DatePosted = @DatePosted, @msg = @errmsg OUTPUT

		IF @rcode <> 0 RETURN @rcode
		
		DELETE @GLEntriesToProcess WHERE JCCo = @JCCo
	END

	DELETE vGLEntryBatch
	FROM dbo.vGLEntryBatch
		INNER JOIN dbo.vGLEntry ON vGLEntryBatch.GLEntryID = vGLEntry.GLEntryID
		INNER JOIN dbo.vSMWorkCompletedBatch ON (vGLEntryBatch.GLEntryID = vSMWorkCompletedBatch.CurrentRevenueGLEntryID OR vGLEntryBatch.GLEntryID = vSMWorkCompletedBatch.ReversingRevenueGLEntryID) AND vGLEntryBatch.Co = vSMWorkCompletedBatch.BatchCo AND vGLEntryBatch.Mth = vSMWorkCompletedBatch.BatchMonth AND vGLEntryBatch.BatchId = vSMWorkCompletedBatch.BatchId
		INNER JOIN dbo.vSMWorkCompleted ON vSMWorkCompletedBatch.SMWorkCompletedID = vSMWorkCompleted.SMWorkCompletedID
		INNER JOIN dbo.vSMCO ON vSMWorkCompleted.SMCo = vSMCO.SMCo
	WHERE vGLEntryBatch.Co = @BatchCo AND vGLEntryBatch.Mth = @BatchMth AND vGLEntryBatch.BatchId = @BatchId AND vGLEntry.[Source] = 'SM Job' AND vSMCO.UseJCInterface = 'N'

	IF EXISTS (SELECT 1 FROM dbo.vGLEntryBatch INNER JOIN dbo.vGLEntry ON vGLEntryBatch.GLEntryID = vGLEntry.GLEntryID WHERE vGLEntryBatch.Co = @BatchCo AND vGLEntryBatch.Mth = @BatchMth AND vGLEntryBatch.BatchId = @BatchId AND vGLEntry.[Source] = 'SM Job' AND vGLEntryBatch.PostedToGL = 0)
	BEGIN
		SET @errmsg = 'Not all GL entries posted correctly.'
		RETURN 1
	END
	
	DELETE vGLEntryBatch
	FROM dbo.vGLEntryBatch
		INNER JOIN dbo.vGLEntry ON vGLEntryBatch.GLEntryID = vGLEntry.GLEntryID
	WHERE vGLEntryBatch.Co = @BatchCo AND vGLEntryBatch.Mth = @BatchMth AND vGLEntryBatch.BatchId = @BatchId AND vGLEntry.[Source] = 'SM Job'

	--Update the work completed with the GL entries so that changes in the future will know how to send reversing entries
	DECLARE @SMWorkCompletedID bigint, @CurrentRevenueGLEntryID bigint, @GLTransactionForSMDerivedAccount int, @SMGLEntryID bigint, @SMGLDetailTransactionID bigint, 
		@RevenueSMWIPGLEntryIDToDelete bigint, @RevenueJCWIPGLEntryIDToDelete bigint,
		@ReversingRevenueGLEntryID bigint, @RevenueGLEntryIDToDelete bigint, @RevenueGLDetailTransactionEntryIDToDelete bigint

	WHILE EXISTS(SELECT 1 FROM dbo.vSMWorkCompletedBatch WHERE BatchCo = @BatchCo AND BatchMonth = @BatchMth AND BatchId = @BatchId AND (CurrentRevenueGLEntryID IS NOT NULL OR ReversingRevenueGLEntryID IS NOT NULL))
	BEGIN
		BEGIN TRAN
			UPDATE TOP (1) dbo.vSMWorkCompletedBatch
			SET @SMWorkCompletedID = SMWorkCompletedID, @CurrentRevenueGLEntryID = CurrentRevenueGLEntryID, CurrentRevenueGLEntryID = NULL, @ReversingRevenueGLEntryID = ReversingRevenueGLEntryID, ReversingRevenueGLEntryID = NULL
			WHERE BatchCo = @BatchCo AND BatchMonth = @BatchMth AND BatchId = @BatchId AND (CurrentRevenueGLEntryID IS NOT NULL OR ReversingRevenueGLEntryID IS NOT NULL)
			
			SELECT @SMGLEntryID = NULL, @SMGLDetailTransactionID = NULL
			
			--Currently vSMWorkCompletedGL is still being used for tracking GL for revenue WIP transfer purposes.
			--Once AR is refactored to use the revenue columns on vSMWorkCompleted and the revenue WIP transfer process is refactored
			--there will be no need for the code related to updating vSMGL.
			IF @CurrentRevenueGLEntryID IS NOT NULL
			BEGIN
				IF NOT EXISTS(SELECT 1 FROM dbo.vSMWorkCompletedGL WHERE SMWorkCompletedID = @SMWorkCompletedID)
				BEGIN
					INSERT dbo.vSMWorkCompletedGL (SMWorkCompletedID, SMCo, IsMiscellaneousLineType)
					SELECT SMWorkCompletedID, SMCo, CASE WHEN [Type] = 3 AND APTLKeyID IS NULL THEN 1 ELSE 0 END
					FROM dbo.vSMWorkCompleted
					WHERE SMWorkCompletedID = @SMWorkCompletedID
				END

				INSERT dbo.vSMGLEntry (SMWorkCompletedID, Journal, TransactionsShouldBalance)
				VALUES (@SMWorkCompletedID, @GLCostJournal, 0)
				
				SET @SMGLEntryID = SCOPE_IDENTITY()
				
				SELECT @GLTransactionForSMDerivedAccount = GLTransactionForSMDerivedAccount
				FROM dbo.vSMWorkCompletedGLEntry
				WHERE GLEntryID = @CurrentRevenueGLEntryID
				
				INSERT dbo.vSMGLDetailTransaction (SMGLEntryID, IsTransactionForSMDerivedAccount, GLCo, GLAccount, Amount, ActDate, [Description])
				SELECT @SMGLEntryID, 0, GLCo, GLAccount, Amount, ActDate, [Description]
				FROM dbo.vGLEntryTransaction
				WHERE GLEntryID = @CurrentRevenueGLEntryID AND GLTransaction <> @GLTransactionForSMDerivedAccount
				UNION ALL
				SELECT @SMGLEntryID, 1, GLCo, GLAccount, Amount, ActDate, [Description]
				FROM dbo.vGLEntryTransaction
				WHERE GLEntryID = @CurrentRevenueGLEntryID AND GLTransaction = @GLTransactionForSMDerivedAccount
				
				--The last record inserted should be the sm account since it was inserted in the second query
				SET @SMGLDetailTransactionID = SCOPE_IDENTITY()
			END
			
			UPDATE dbo.vSMWorkCompletedGL
			SET @RevenueGLEntryIDToDelete = RevenueGLEntryID, RevenueGLEntryID = @SMGLEntryID, 
				@RevenueGLDetailTransactionEntryIDToDelete = RevenueGLDetailTransactionEntryID, RevenueGLDetailTransactionEntryID = @SMGLEntryID, RevenueGLDetailTransactionID = @SMGLDetailTransactionID
			WHERE SMWorkCompletedID = @SMWorkCompletedID
			IF @@rowcount = 1
			BEGIN
				--If the vSMWorkCompletedGL record doesn't exist then there is nothing to delete.
				DELETE dbo.vSMGLEntry
				WHERE SMGLEntryID = @RevenueGLEntryIDToDelete OR SMGLEntryID = @RevenueGLDetailTransactionEntryIDToDelete
			END
			
			UPDATE dbo.vSMWorkCompleted
			SET @RevenueGLEntryIDToDelete = RevenueGLEntryID, RevenueGLEntryID = @CurrentRevenueGLEntryID,
				@RevenueSMWIPGLEntryIDToDelete = RevenueSMWIPGLEntryID , RevenueSMWIPGLEntryID = NULL,
				@RevenueJCWIPGLEntryIDToDelete = RevenueJCWIPGLEntryID, RevenueJCWIPGLEntryID = NULL
			WHERE SMWorkCompletedID = @SMWorkCompletedID
			
			DELETE dbo.vGLEntry
			WHERE GLEntryID = @ReversingRevenueGLEntryID OR GLEntryID = @RevenueGLEntryIDToDelete OR GLEntryID = @RevenueSMWIPGLEntryIDToDelete OR GLEntryID = @RevenueJCWIPGLEntryIDToDelete
		COMMIT TRAN
	END
	
	--Currently the only batch that doesn't lazily create vSMWorkCompletedBatch records is the equipment usage batch. For these batches the
	--vSMWorkCompletedBatch records should be deleted. Once other batches start using the vSMWorkCompletedBatch 
	DELETE vSMWorkCompletedBatch
	FROM dbo.vSMWorkCompletedBatch
		INNER JOIN dbo.bHQBC ON vSMWorkCompletedBatch.BatchCo = bHQBC.Co AND vSMWorkCompletedBatch.BatchMonth = bHQBC.Mth AND vSMWorkCompletedBatch.BatchId = bHQBC.BatchId
	WHERE vSMWorkCompletedBatch.BatchCo = @BatchCo AND vSMWorkCompletedBatch.BatchMonth = @BatchMth AND vSMWorkCompletedBatch.BatchId = @BatchId AND bHQBC.Source <> 'SMEquipUse'
	
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMJobCostDetailInsert] TO [public]
GO
