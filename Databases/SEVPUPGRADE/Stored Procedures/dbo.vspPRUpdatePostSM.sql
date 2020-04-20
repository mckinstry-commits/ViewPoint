SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspPRUpdatePostSM]
/***********************************************************
 * CREATED BY: Eric Vaterlaus 04/11/2011
 * MODIFIED By: 
 *				
 * USAGE:
 * Called from bspPRUpdatePost procedure to perform SM
 * revenue updates.
 *
 * INPUT PARAMETERS
 *   @prco   		PR Company
 *   @prgroup  		PR Group to validate
 *   @prenddate		Pay Period Ending Date
 *   @postdate		Posting Date used for transaction detail
 *   @status		Pay Period status 0 = open, 1 = closed
 *
 * OUTPUT PARAMETERS
 *   @errmsg      error message if error occurs
 *
 * RETURN VALUE
 *   0         success
 *   1         failure
 *****************************************************/
	(@prco bCompany, @prgroup bGroup, @prenddate bDate, @postdate bDate,
	 @status tinyint output, @errmsg varchar(255) output)
    AS
    SET NOCOUNT ON
    
	DECLARE @rcode int, @Mth bMonth, @BatchId bBatchID, @HQBatchDistributionID bigint, @PRLedgerUpdateMonthID bigint, @JCCostEntryID bigint, @OldJCCostEntryID bigint, @InterfacingCo bCompany, @IsReversing bit

	DECLARE @SMJCCostEntryTransactions TABLE (Processed bit NOT NULL DEFAULT(0), PRLedgerUpdateMonthID bigint NOT NULL, Mth bMonth NOT NULL, JCCostEntryID bigint, OldJCCostEntryID bigint, SMWorkCompletedID bigint NULL, IsReversing bit NOT NULL, Interface bit NOT NULL, InterfacingCo bCompany NOT NULL)

	--Retrieve all JCCostEntrys tied to the pay period. If the JCCostEntry was posted then a reversing JCCostEntry will be created.
	--Posting will be done by month.
	INSERT @SMJCCostEntryTransactions (PRLedgerUpdateMonthID, Mth, JCCostEntryID, OldJCCostEntryID, SMWorkCompletedID, IsReversing, Interface, InterfacingCo)
	SELECT vPRLedgerUpdateMonth.PRLedgerUpdateMonthID, vPRLedgerUpdateMonth.Mth, CASE WHEN vPRLedgerUpdateMonth.Posted = 0 THEN vJCCostEntry.JCCostEntryID END, CASE WHEN vPRLedgerUpdateMonth.Posted = 1 THEN vJCCostEntry.JCCostEntryID END, vSMWorkCompleted.SMWorkCompletedID, vPRLedgerUpdateMonth.Posted, dbo.vfIsEqual(vSMCO.UseJCInterface, 'Y'), vSMCO.SMCo
	FROM dbo.vPRLedgerUpdateMonth
		INNER JOIN dbo.vJCCostEntry ON vPRLedgerUpdateMonth.PRLedgerUpdateMonthID = vJCCostEntry.PRLedgerUpdateMonthID
		INNER JOIN dbo.vSMWorkCompletedJCCostEntry ON vJCCostEntry.JCCostEntryID = vSMWorkCompletedJCCostEntry.JCCostEntryID
		INNER JOIN dbo.vSMWorkCompleted ON vSMWorkCompletedJCCostEntry.SMWorkCompletedID = vSMWorkCompleted.SMWorkCompletedID
		INNER JOIN dbo.vSMCO ON vSMWorkCompleted.SMCo = vSMCO.SMCo
	WHERE vPRLedgerUpdateMonth.PRCo = @prco AND vPRLedgerUpdateMonth.PRGroup = @prgroup AND vPRLedgerUpdateMonth.PREndDate = @prenddate AND vJCCostEntry.[Source] = 'SM'

	WHILE EXISTS(SELECT 1 FROM @SMJCCostEntryTransactions)
	BEGIN
		BEGIN TRY
			--Batches are posted within a transaction to guarantee that everything is committed or nothing is committed.
			BEGIN TRAN

			--For each month in the table a batch will be created.
			SELECT TOP 1 @Mth = Mth
			FROM @SMJCCostEntryTransactions

			--The vfJCCostEntryTransactionSummary function summarizes the new and reversing transaction and filters
			--out the summarized lines that net to 0. If all line net to 0 then there is no reason to post to JCCD.
			IF EXISTS(SELECT 1 FROM dbo.vfJCCostEntryTransactionSummary(@prco, @Mth, NULL, @prgroup, @prenddate, 'SM'))
			BEGIN
				-- add a Batch for each month updated in JC - created as 'open', and 'in use'
				EXEC @BatchId = dbo.bspHQBCInsert @co = @prco, @month = @Mth, @source = 'PR Update', @batchtable = 'SMWorkCompletedBatch', @restrict = 'N', @adjust = 'N', @prgroup = @prgroup, @prenddate = @prenddate, @errmsg = @errmsg OUTPUT
				IF @BatchId = 0
				BEGIN
					ROLLBACK TRAN
					RETURN 1
				END
				
				--For each JCCostEntry that needs to be posted for the current processing month a vHQBatchDistribution
				--record is created to relate the JCCostEntry to the batch. If the JCCostEntry was already posted a reversing
				--entry is created. For new JCCostEntrys the DistributionXML is updated to capture what GLEntryTransactions were related
				--to each JCCostEntryTransaction. This way when the batch is posted the GLEntryTransaction description can be with the JCCD trans#.
				WHILE EXISTS(SELECT 1 FROM @SMJCCostEntryTransactions WHERE Mth = @Mth AND Interface = 1 AND Processed = 0)
				BEGIN
					UPDATE TOP (1) @SMJCCostEntryTransactions
					SET Processed = 1, @PRLedgerUpdateMonthID = PRLedgerUpdateMonthID, @JCCostEntryID = JCCostEntryID, @OldJCCostEntryID = OldJCCostEntryID, @IsReversing = IsReversing, @InterfacingCo = InterfacingCo
					WHERE Mth = @Mth AND Interface = 1 AND Processed = 0
				
					INSERT dbo.vHQBatchDistribution (Co, Mth, BatchId, InterfacingCo, IsReversing)
					VALUES (@prco, @Mth, @BatchId, @InterfacingCo, @IsReversing)

					SET @HQBatchDistributionID = SCOPE_IDENTITY()

					IF @IsReversing = 1
					BEGIN
						EXEC @JCCostEntryID = dbo.vspJCCostEntryCreate @Source = 'SM', @HQBatchDistributionID = @HQBatchDistributionID, @msg = @errmsg OUTPUT
						IF @JCCostEntryID = 0
						BEGIN
							ROLLBACK TRAN
							RETURN 1
						END
						
						UPDATE @SMJCCostEntryTransactions
						SET JCCostEntryID = @JCCostEntryID
						WHERE PRLedgerUpdateMonthID = @PRLedgerUpdateMonthID
						
						INSERT dbo.vJCCostEntryTransaction (
							JCCostEntryID, JCCostTransaction,
							JCCo, Job, PhaseGroup, Phase, CostType,
							ActualDate, Description, UM, ActualUnitCost, PerECM,
							ActualHours, ActualUnits, ActualCost,
							PostedUM, PostedUnits, PostedUnitCost, PostedECM, PostRemCmUnits,
							RemainCmtdCost, RemCmtdTax,
							PRCo, Employee, Craft, Class, Crew, EarnFactor, EarnType, Shift, LiabilityType,
							VendorGroup, Vendor, APCo, PO, POItem, POItemLine, MatlGroup, Material,
							INCo, Loc, INStdUnitCost, INStdECM, INStdUM,
							EMCo, Equipment, EMGroup, RevCode,
							TaxType, TaxGroup, TaxCode, TaxBasis, TaxAmt
						)
						SELECT @JCCostEntryID, vJCCostEntryTransaction.JCCostTransaction, 
							vJCCostEntryTransaction.JCCo, vJCCostEntryTransaction.Job, vJCCostEntryTransaction.PhaseGroup, vJCCostEntryTransaction.Phase, vJCCostEntryTransaction.CostType, 
							vJCCostEntryTransaction.ActualDate, vJCCostEntryTransaction.[Description], vJCCostEntryTransaction.UM, vJCCostEntryTransaction.ActualUnitCost, vJCCostEntryTransaction.PerECM, 
							-vJCCostEntryTransaction.ActualHours, -vJCCostEntryTransaction.ActualUnits, -vJCCostEntryTransaction.ActualCost, 
							vJCCostEntryTransaction.PostedUM, -vJCCostEntryTransaction.PostedUnits, vJCCostEntryTransaction.PostedUnitCost, vJCCostEntryTransaction.PostedECM, -vJCCostEntryTransaction.PostRemCmUnits, 
							-vJCCostEntryTransaction.RemainCmtdCost, -vJCCostEntryTransaction.RemCmtdTax, 
							vJCCostEntryTransaction.PRCo, vJCCostEntryTransaction.Employee, vJCCostEntryTransaction.Craft, vJCCostEntryTransaction.Class, vJCCostEntryTransaction.Crew, vJCCostEntryTransaction.EarnFactor, vJCCostEntryTransaction.EarnType, vJCCostEntryTransaction.Shift, vJCCostEntryTransaction.LiabilityType, 
							vJCCostEntryTransaction.VendorGroup, vJCCostEntryTransaction.Vendor, vJCCostEntryTransaction.APCo, vJCCostEntryTransaction.PO, vJCCostEntryTransaction.POItem, vJCCostEntryTransaction.POItemLine, vJCCostEntryTransaction.MatlGroup, vJCCostEntryTransaction.Material, 
							vJCCostEntryTransaction.INCo, vJCCostEntryTransaction.Loc, vJCCostEntryTransaction.INStdUnitCost, vJCCostEntryTransaction.INStdECM, vJCCostEntryTransaction.INStdUM, 
							vJCCostEntryTransaction.EMCo, vJCCostEntryTransaction.Equipment, vJCCostEntryTransaction.EMGroup, vJCCostEntryTransaction.RevCode, 
							vJCCostEntryTransaction.TaxType, vJCCostEntryTransaction.TaxGroup, vJCCostEntryTransaction.TaxCode, -vJCCostEntryTransaction.TaxBasis, -vJCCostEntryTransaction.TaxAmt
						FROM  dbo.vJCCostEntryTransaction
						WHERE JCCostEntryID = @OldJCCostEntryID
					END
					ELSE
					BEGIN
						UPDATE vJCCostEntry
						SET HQBatchDistributionID = @HQBatchDistributionID
						WHERE JCCostEntryID = @JCCostEntryID
					
						UPDATE dbo.vHQBatchDistribution
						SET DistributionXML = (
							SELECT *
							FROM
								(SELECT PRLedgerUpdateJCCostEntryTransaction.JCCostTransaction, PRLedgerUpdateGLEntryTransaction.GLEntryID, PRLedgerUpdateGLEntryTransaction.GLTransaction
								FROM PRLedgerUpdateJCCostEntryTransaction
									INNER JOIN PRLedgerUpdateGLEntryTransaction ON 
									CHECKSUM(PRLedgerUpdateJCCostEntryTransaction.PRCo, PRLedgerUpdateJCCostEntryTransaction.PRGroup, PRLedgerUpdateJCCostEntryTransaction.PREndDate, PRLedgerUpdateJCCostEntryTransaction.Employee, PRLedgerUpdateJCCostEntryTransaction.PaySeq, PRLedgerUpdateJCCostEntryTransaction.PostSeq, PRLedgerUpdateJCCostEntryTransaction.[Type], PRLedgerUpdateJCCostEntryTransaction.EarnCode, PRLedgerUpdateJCCostEntryTransaction.LiabilityType)
									= CHECKSUM(PRLedgerUpdateGLEntryTransaction.PRCo, PRLedgerUpdateGLEntryTransaction.PRGroup, PRLedgerUpdateGLEntryTransaction.PREndDate, PRLedgerUpdateGLEntryTransaction.Employee, PRLedgerUpdateGLEntryTransaction.PaySeq, PRLedgerUpdateGLEntryTransaction.PostSeq, PRLedgerUpdateGLEntryTransaction.[Type], PRLedgerUpdateGLEntryTransaction.EarnCode, PRLedgerUpdateGLEntryTransaction.LiabilityType)
								WHERE PRLedgerUpdateJCCostEntryTransaction.JCCostEntryID = @JCCostEntryID AND PRLedgerUpdateJCCostEntryTransaction.Posted = 0 AND PRLedgerUpdateGLEntryTransaction.Posted = 0) JCCostEntryTransaction
							FOR XML AUTO, TYPE)
						WHERE HQBatchDistributionID = @HQBatchDistributionID
					END
				END

				EXEC @rcode = dbo.vspJobCostEntryTransactionPost @BatchCo = @prco, @BatchMth = @Mth, @BatchId = @BatchId, @JCTransType = 'PR', @PostedDate = @postdate, @msg = @errmsg OUTPUT
    			IF @rcode <> 0
				BEGIN
					ROLLBACK TRAN
					RETURN 1
				END

				--For all the reversing entries that were created we need to get rid of them now since they are no longer needed.
				DELETE vJCCostEntry
				FROM @SMJCCostEntryTransactions SMJCCostEntryTransactions
					INNER JOIN dbo.vJCCostEntry ON SMJCCostEntryTransactions.JCCostEntryID = vJCCostEntry.JCCostEntryID
				WHERE SMJCCostEntryTransactions.Mth = @Mth AND SMJCCostEntryTransactions.IsReversing = 1

				EXEC @rcode = dbo.vspHQBatchPosted @BatchCo = @prco, @BatchMth = @Mth, @BatchId = @BatchId, @msg = @errmsg OUTPUT
				IF @rcode <> 0
				BEGIN
					ROLLBACK TRAN
					RETURN 1
				END
			END

			--The JCCostEntryID needs to be nulled out when it was reversed out so that closing the job doesn't cause
			--JC WIP GL Entry to be captured that isn't valid
			UPDATE vSMWorkCompleted
			SET JCCostEntryID = NULL
			FROM @SMJCCostEntryTransactions SMJCCostEntryTransactions
				INNER JOIN dbo.vSMWorkCompleted ON SMJCCostEntryTransactions.SMWorkCompletedID = vSMWorkCompleted.SMWorkCompletedID
			WHERE SMJCCostEntryTransactions.Mth = @Mth AND SMJCCostEntryTransactions.IsReversing = 1 AND SMJCCostEntryTransactions.OldJCCostEntryID = vSMWorkCompleted.JCCostEntryID

			--The current JCCostEntryID needs to be captured so that closing the job will capture the JC WIP GL.
			UPDATE vSMWorkCompleted
			SET JCCostEntryID = SMJCCostEntryTransactions.JCCostEntryID
			FROM @SMJCCostEntryTransactions SMJCCostEntryTransactions
				INNER JOIN dbo.vSMWorkCompleted ON SMJCCostEntryTransactions.SMWorkCompletedID = vSMWorkCompleted.SMWorkCompletedID
			WHERE SMJCCostEntryTransactions.Mth = @Mth AND SMJCCostEntryTransactions.IsReversing = 0

			--Since the posted records have been processed they can be purged now.
			DELETE vPRLedgerUpdateMonth
			FROM @SMJCCostEntryTransactions SMJCCostEntryTransactions
				INNER JOIN vPRLedgerUpdateMonth ON SMJCCostEntryTransactions.PRLedgerUpdateMonthID = vPRLedgerUpdateMonth.PRLedgerUpdateMonthID
			WHERE SMJCCostEntryTransactions.Mth = @Mth AND SMJCCostEntryTransactions.IsReversing = 1

			--Update the existing vPRLedgerUpdateMonth records related to JC to be posted so they can be reversed out
			--if ledger update is run again.
			UPDATE vPRLedgerUpdateMonth
			SET Posted = 1
			FROM @SMJCCostEntryTransactions SMJCCostEntryTransactions
				INNER JOIN vPRLedgerUpdateMonth ON SMJCCostEntryTransactions.PRLedgerUpdateMonthID = vPRLedgerUpdateMonth.PRLedgerUpdateMonthID
			WHERE SMJCCostEntryTransactions.Mth = @Mth

			DELETE @SMJCCostEntryTransactions
			WHERE Mth = @Mth

			COMMIT TRAN
		END TRY
		BEGIN CATCH
	    	--If the error is due to a transaction count mismatch in vspJobCostEntryTransactionPost
			--then it is more helpful to keep the error message from vspJobCostEntryTransactionPost.
			IF ERROR_NUMBER() <> 266 SET @errmsg = ERROR_MESSAGE()
			IF @@TRANCOUNT > 0 ROLLBACK TRAN
			
			RETURN 1
		END CATCH
	END

	RETURN 0
GO
GRANT EXECUTE ON  [dbo].[vspPRUpdatePostSM] TO [public]
GO
