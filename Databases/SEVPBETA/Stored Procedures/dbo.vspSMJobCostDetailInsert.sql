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
-- =============================================
CREATE PROCEDURE [dbo].[vspSMJobCostDetailInsert]
	  @BatchCo bCompany, @BatchMth bMonth, @BatchId bBatchID, @errmsg varchar(255)=NULL output
AS
	
SET NOCOUNT ON;

--This should probaly be a paramter
DECLARE @DatePosted bDate
SET @DatePosted = dbo.vfDateOnly()

DECLARE @rcode int, @UseJCInterface char(1), @NextJCCostTrans bTrans, @SMWorkCompletedID bigint, @IsReversingEntry bit, @IsTaxRedirect bit,
@JCCo bCompany, @SMCo bCompany, @Contract bContract, @ContractItem bContractItem, 
@Job bJob, @PhaseGroup bGroup, @Phase bPhase, @JCCostType bJCCType, @ProjMinPct bPct, @UM bUM,
@Description bItemDesc

DECLARE @BatchRecordsToProcess TABLE (SMWorkCompletedID bigint, IsReversingEntry bit, IsTaxRedirect bit, JCCo bCompany, SMCo bCompany)

INSERT @BatchRecordsToProcess
SELECT SMWorkCompletedID,IsReversingEntry,IsTaxRedirect,JCCo,SMCo
FROM dbo.vSMJobCostDistribution
WHERE BatchCo = @BatchCo AND BatchMth = @BatchMth AND BatchID = @BatchId
ORDER BY SMWorkCompletedID,IsReversingEntry DESC,IsTaxRedirect DESC,JCCo,SMCo
WHILE EXISTS(SELECT 1 FROM @BatchRecordsToProcess)
BEGIN
		BEGIN TRAN

		SELECT TOP 1 @SMWorkCompletedID = SMWorkCompletedID, @IsReversingEntry=IsReversingEntry,@IsTaxRedirect=IsTaxRedirect,@JCCo=JCCo, @SMCo=SMCo
		FROM @BatchRecordsToProcess
		ORDER BY SMWorkCompletedID, IsReversingEntry DESC, IsTaxRedirect DESC
			
		--Get Job Cost Information Is SMCo company posting to JobCost YN
		SELECT  @UseJCInterface= UseJCInterface FROM dbo.SMCO  WHERE SMCo=@SMCo
			
		/*Exit procedure when SM Company is not posting to job cost*/
		IF @UseJCInterface = 'Y' 
		BEGIN
 			--Get Next JC Cost Transactions  need to create records here so we don't get trigger errors in JCCD and mess up batch posting.
			--JCCD records can always be reversed out.
			EXEC @NextJCCostTrans = dbo.bspHQTCNextTrans @tablename = 'bJCCD', @co = @JCCo, @mth = @BatchMth, @errmsg = @errmsg OUTPUT
			IF  @NextJCCostTrans = 0
			BEGIN
				SET @errmsg = 'Failed to get next JC Cost Detial Trans ' + @errmsg
				ROLLBACK TRAN
				RETURN 1
			END

			--Get Job info for creating JC Job Phase (JCJP) and JC Job Phase Cost Type records		
			SELECT @JCCo=JCCo,@Job=Job,@Phase=Phase,@PhaseGroup=PhaseGroup,@JCCostType=CostType,@Description=[Description],@UM=PostedUM
			FROM dbo.vSMJobCostDistribution 
			WHERE SMWorkCompletedID=@SMWorkCompletedID AND IsReversingEntry=@IsReversingEntry AND IsTaxRedirect=@IsTaxRedirect
			--Create JC Job Phase Cost Type (JCCH) record if it doesn't exist
			IF NOT EXISTS (SELECT TOP 1 1 FROM dbo.JCJP WHERE JCCo=@JCCo AND Job=@Job AND PhaseGroup=@PhaseGroup AND Phase=@Phase )
			BEGIN
				--Get Required fields for JC Job Phase Insert
				--Get Job Contract and default Phase Projection Min% from Job Master
				SELECT @Contract = [Contract], @ProjMinPct=ProjMinPct FROM dbo.JCJM WHERE JCCo=@JCCo AND Job=@Job
				--Get min Contract Item for Job and assign it to Phase
				SELECT @ContractItem = min(Item) FROM dbo.JCCI WHERE JCCo=@JCCo AND [Contract] = @Contract
				--Craate JC Job Phase in JCJP
				EXEC  @rcode= dbo.vspJCJPAdd @JCCo, @Job, @PhaseGroup, @Phase, @Description, @Contract, @ContractItem, @ProjMinPct ,'Y',@msg=@errmsg  output
				IF @rcode <> 0
				BEGIN
					RETURN 1
				END
			END
			--Create JC Job Phase Cost Type (JCCH) record if it doesn't exist
			IF NOT EXISTS (SELECT TOP 1 1 FROM dbo.JCCH 	WHERE JCCo=@JCCo AND Job=@Job AND PhaseGroup=@PhaseGroup AND Phase=@Phase AND CostType= @JCCostType )
			BEGIN
					 /*Set;
					 PostedUM has JCCH UM 
					 BillItem flag to yes so it shows up on Job Billing invoices
					 Always set Active flag to Yes
					*/
					 EXEC @rcode = dbo.bspJCADDCOSTTYPE @jcco= @JCCo, @job=@Job,  @phasegroup=@PhaseGroup, @phase= @Phase,@costtype=@JCCostType, 
					@um=@UM , @billflag='Y',   @itemunitflag='N',  @phaseunitflag='N',  @buyoutyn= 'N', @activeyn='Y', @override= 'N', @msg=@errmsg output
					IF @rcode <> 0
					BEGIN
						RETURN 1
					END	
			END
			--Create SM Job Cost Distribution Record
			BEGIN TRY
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

				SELECT JCCo,BatchMth,@NextJCCostTrans,Job,Phase,PhaseGroup,CostType,JobPhaseCostTypeUM,
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
				WHERE SMWorkCompletedID=@SMWorkCompletedID AND IsReversingEntry=@IsReversingEntry AND IsTaxRedirect=@IsTaxRedirect
			END TRY
			BEGIN CATCH
				SET @errmsg = 'Failed to create Job Cost Detail record ' + ERROR_MESSAGE()
				ROLLBACK TRAN
				RETURN 1
			END CATCH

			--Create Link to Job Cost Detail record
			IF IsNull(@IsReversingEntry,0) = 0  AND IsNull(@IsTaxRedirect,0) = 0
			BEGIN
				BEGIN TRY
					UPDATE dbo.vSMWorkCompleted
					SET JCCo=@JCCo,JCMth=@BatchMth,JCCostTrans=@NextJCCostTrans
					WHERE SMWorkCompletedID=@SMWorkCompletedID
				END TRY
				BEGIN CATCH
					SET @errmsg = 'Failed to create SM Work Completed record with Job Cost Detail transaction info ' + ERROR_MESSAGE()
					ROLLBACK TRAN
					RETURN 1
				END CATCH
			END

			IF IsNull(@IsReversingEntry,0) = 0  AND IsNull(@IsTaxRedirect,0) = 1
			BEGIN
				BEGIN TRY
					UPDATE dbo.vSMWorkCompleted
					SET JCCo=@JCCo,JCMth=@BatchMth,JCCostTaxTrans=@NextJCCostTrans
					WHERE SMWorkCompletedID=@SMWorkCompletedID
				END TRY
				BEGIN CATCH
					SET @errmsg = 'Failed to create SM Work Completed record with Job Cost Detail Tax Phase redirect transaction info ' + ERROR_MESSAGE()
					ROLLBACK TRAN
					RETURN 1
				END CATCH
			END

			IF IsNull(@IsReversingEntry,0) = 1 
			BEGIN
				BEGIN TRY
					UPDATE dbo.vSMWorkCompleted
					SET JCCo=NULL,JCMth=NULL,JCCostTrans=NULL,JCCostTaxTrans=NULL
					WHERE SMWorkCompletedID=@SMWorkCompletedID
				END TRY
				BEGIN CATCH
					SET @errmsg = 'Failed to SM Work Completed JC Trans Fields  ' + ERROR_MESSAGE()
					ROLLBACK TRAN
					RETURN 1
				END CATCH
			END
		END
	
		--Delete Distribution record has processed
		DELETE  FROM vSMJobCostDistribution WHERE SMWorkCompletedID=@SMWorkCompletedID AND IsReversingEntry=@IsReversingEntry AND IsTaxRedirect=@IsTaxRedirect
		
		--Delete Distribution record has processed
		DELETE  FROM @BatchRecordsToProcess WHERE SMWorkCompletedID=@SMWorkCompletedID AND IsReversingEntry=@IsReversingEntry AND IsTaxRedirect=@IsTaxRedirect

		COMMIT TRAN
END

	DECLARE @CurrentJCCostEntryID bigint, @ReversingJCCostEntryID bigint, @JCCostEntryIDToDelete bigint, @JCCDCostTrans bTrans, @CurrentRevenueGLEntryID bigint

	DECLARE @ProcessingJCCostEntryTransaction TABLE (JCCostEntryID bigint, JCCostTransaction int, JCCDCostTrans bTrans NULL)

	--Loop through the cost entries in the batch and update the work completed
	WHILE EXISTS(SELECT 1 FROM dbo.vSMWorkCompletedBatch WHERE BatchCo = @BatchCo AND BatchMonth = @BatchMth AND BatchId = @BatchId AND (CurrentJCCostEntryID IS NOT NULL OR ReversingJCCostEntryID IS NOT NULL))
	BEGIN
		BEGIN TRAN
			UPDATE TOP (1) dbo.vSMWorkCompletedBatch
			SET @SMWorkCompletedID = SMWorkCompletedID, @CurrentJCCostEntryID = CurrentJCCostEntryID, CurrentJCCostEntryID = NULL, @ReversingJCCostEntryID = ReversingJCCostEntryID, ReversingJCCostEntryID = NULL, @CurrentRevenueGLEntryID = CurrentRevenueGLEntryID
			WHERE BatchCo = @BatchCo AND BatchMonth = @BatchMth AND BatchId = @BatchId AND (CurrentJCCostEntryID IS NOT NULL OR ReversingJCCostEntryID IS NOT NULL)

			DELETE @ProcessingJCCostEntryTransaction

			INSERT @ProcessingJCCostEntryTransaction (JCCostEntryID, JCCostTransaction)
			SELECT JCCostEntryID, JCCostTransaction
			FROM dbo.vJCCostEntryTransaction
			WHERE JCCostEntryID = @CurrentJCCostEntryID OR JCCostEntryID = @ReversingJCCostEntryID
			
			--Currently since the JCCD records are not being created from the JCCostTransactions yet
			--the trans for the GL transactions is unknown. When this code is refactored then
			--the JCCDCostTrans should be knowable while creating the JCCD records.
			SET @JCCDCostTrans = 0
			
			WHILE EXISTS(SELECT 1 FROM @ProcessingJCCostEntryTransaction WHERE JCCDCostTrans IS NULL)
			BEGIN
				SET @JCCDCostTrans = @JCCDCostTrans + 1
				
				UPDATE TOP (1) @ProcessingJCCostEntryTransaction
				SET JCCDCostTrans = @JCCDCostTrans
				WHERE JCCDCostTrans IS NULL
			END
			
			--INSERT JCCD FROM @JCCostEntryTransaction JOIN JCCostEntryTransaction

			UPDATE vGLEntryTransaction
			SET [Description] = REPLACE([Description], 'Trans #', dbo.vfToString(JCCDCostTrans))
			FROM dbo.vGLEntryTransaction
				INNER JOIN @ProcessingJCCostEntryTransaction ProcessingJCCostEntryTransaction ON vGLEntryTransaction.DetailTransGroup = ProcessingJCCostEntryTransaction.JCCostTransaction
			WHERE vGLEntryTransaction.GLEntryID = @CurrentRevenueGLEntryID AND ProcessingJCCostEntryTransaction.JCCostEntryID = @CurrentJCCostEntryID

			UPDATE dbo.vSMWorkCompleted
			SET @JCCostEntryIDToDelete = JCCostEntryID, JCCostEntryID = @CurrentJCCostEntryID
			WHERE SMWorkCompletedID = @SMWorkCompletedID
			
			DELETE dbo.vJCCostEntry
			FROM dbo.vJCCostEntry
			WHERE JCCostEntryID = @JCCostEntryIDToDelete OR JCCostEntryID = @ReversingJCCostEntryID
		COMMIT TRAN
	END

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
	DECLARE @GLTransactionForSMDerivedAccount int, @SMGLEntryID bigint, @SMGLDetailTransactionID bigint, 
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
GO
GRANT EXECUTE ON  [dbo].[vspSMJobCostDetailInsert] TO [public]
GO
