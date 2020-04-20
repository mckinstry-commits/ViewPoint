SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:	JVH
-- Create date:  5/21/12
-- Description:	Handles posting to JCCD from a batch with JCCostEntryTransactions
-- =============================================
CREATE PROCEDURE [dbo].[vspJobCostEntryTransactionPost]
	@BatchCo bCompany, @BatchMth bMonth, @BatchId bBatchID, @JCTransType varchar(2), @PostedDate bDate, @msg varchar(255) = NULL OUTPUT
AS
	
	SET NOCOUNT ON;

	DECLARE @JobPhasesToAdd TABLE (JCCo bCompany, Job bJob, PhaseGroup bGroup, Phase bPhase, Processed bit)
	
	DECLARE @rcode int, @SMWorkCompletedID bigint, @SMCo bCompany, @UseJCInterface bYN,
		@JCCo bCompany, @Job bJob, @PhaseGroup bGroup, @Phase bPhase, @JCCostType bJCCType,
		@UM bUM
	
	INSERT @JobPhasesToAdd
	SELECT DISTINCT vJCCostEntryTransaction.JCCo, vJCCostEntryTransaction.Job, vJCCostEntryTransaction.PhaseGroup, vJCCostEntryTransaction.Phase, 0
	FROM dbo.vHQBatchDistribution
		INNER JOIN dbo.vJCCostEntry ON vHQBatchDistribution.HQBatchDistributionID = vJCCostEntry.HQBatchDistributionID
		INNER JOIN dbo.vJCCostEntryTransaction ON vJCCostEntry.JCCostEntryID = vJCCostEntryTransaction.JCCostEntryID
		LEFT JOIN dbo.bJCJP ON vJCCostEntryTransaction.JCCo = bJCJP.JCCo AND vJCCostEntryTransaction.Job = bJCJP.Job AND vJCCostEntryTransaction.PhaseGroup = bJCJP.PhaseGroup AND vJCCostEntryTransaction.Phase = bJCJP.Phase
	WHERE vHQBatchDistribution.Co = @BatchCo AND vHQBatchDistribution.Mth = @BatchMth AND vHQBatchDistribution.BatchId = @BatchId AND bJCJP.KeyID IS NULL

	WHILE EXISTS(SELECT 1 FROM @JobPhasesToAdd WHERE Processed = 0)
	BEGIN
		UPDATE TOP (1) @JobPhasesToAdd
		SET Processed = 1, @JCCo = JCCo, @Job = Job, @PhaseGroup = PhaseGroup, @Phase = Phase
		WHERE Processed = 0
	
		--Create JC Job Phase in JCJP
		EXEC @rcode = dbo.bspJCADDPHASE @jcco = @JCCo, @job = @Job, @PhaseGroup = @PhaseGroup, @phase = @Phase, @override = 'Y', @msg = @msg OUTPUT
		IF @rcode <> 0
		BEGIN
			RETURN 1
		END
	END
	
	DECLARE @JobCostTypesToAdd TABLE (JCCo bCompany, Job bJob, PhaseGroup bGroup, Phase bPhase, CostType bJCCType, Processed bit)
	
	INSERT @JobCostTypesToAdd
	SELECT DISTINCT vJCCostEntryTransaction.JCCo, vJCCostEntryTransaction.Job, vJCCostEntryTransaction.PhaseGroup, vJCCostEntryTransaction.Phase, vJCCostEntryTransaction.CostType, 0
	FROM dbo.vHQBatchDistribution
		INNER JOIN dbo.vJCCostEntry ON vHQBatchDistribution.HQBatchDistributionID = vJCCostEntry.HQBatchDistributionID
		INNER JOIN dbo.vJCCostEntryTransaction ON vJCCostEntry.JCCostEntryID = vJCCostEntryTransaction.JCCostEntryID
		LEFT JOIN dbo.bJCCH ON vJCCostEntryTransaction.JCCo = bJCCH.JCCo AND vJCCostEntryTransaction.Job = bJCCH.Job AND vJCCostEntryTransaction.PhaseGroup = bJCCH.PhaseGroup AND vJCCostEntryTransaction.Phase = bJCCH.Phase AND vJCCostEntryTransaction.CostType = bJCCH.CostType
	WHERE vHQBatchDistribution.Co = @BatchCo AND vHQBatchDistribution.Mth = @BatchMth AND vHQBatchDistribution.BatchId = @BatchId AND bJCCH.KeyID IS NULL

	WHILE EXISTS(SELECT 1 FROM @JobCostTypesToAdd WHERE Processed = 0)
	BEGIN
		UPDATE TOP (1) @JobCostTypesToAdd
		SET Processed = 1, @JCCo = JCCo, @Job = Job, @PhaseGroup = PhaseGroup, @Phase = Phase, @JCCostType = CostType
		WHERE Processed = 0
		
		--Find the first um from this batch that matches JCCo, Job, PhaseGroup, Phase and CostType
		SELECT TOP 1 @UM = vJCCostEntryTransaction.PostedUM
		FROM dbo.vHQBatchDistribution
			INNER JOIN dbo.vJCCostEntry ON vHQBatchDistribution.HQBatchDistributionID = vJCCostEntry.HQBatchDistributionID
			INNER JOIN dbo.vJCCostEntryTransaction ON vJCCostEntry.JCCostEntryID = vJCCostEntryTransaction.JCCostEntryID
		WHERE vHQBatchDistribution.Co = @BatchCo AND vHQBatchDistribution.Mth = @BatchMth AND vHQBatchDistribution.BatchId = @BatchId AND
			vJCCostEntryTransaction.JCCo = @JCCo AND vJCCostEntryTransaction.Job = @Job AND vJCCostEntryTransaction.PhaseGroup = @PhaseGroup AND vJCCostEntryTransaction.Phase = @Phase AND vJCCostEntryTransaction.CostType = @JCCostType
			
		/*Set;
		PostedUM has JCCH UM 
		BillItem flag to yes so it shows up on Job Billing invoices
		*/
		EXEC @rcode = dbo.bspJCADDCOSTTYPE @jcco= @JCCo, @job = @Job, @phasegroup = @PhaseGroup, @phase = @Phase, @costtype = @JCCostType,
			@um = @UM, @billflag = 'Y', @itemunitflag = 'N', @phaseunitflag = 'N', @msg = @msg OUTPUT
		IF @rcode <> 0
		BEGIN
			RETURN 1
		END
	END

	DECLARE @JCCDCostTrans bTrans

	--What gets sent to JCCD should be summarized so that the net affect of posting the batch is seen in JCCD instead of a lot
	--reversing and correct entries being posted.
	DECLARE @SummarizedJobCostDistributions TABLE (
		JCCDCostTrans bTrans NULL, JCCo bCompany NOT NULL, Job bJob NOT NULL, PhaseGroup bGroup NOT NULL, Phase bPhase NOT NULL, CostType bJCCType NOT NULL,
		ActualDate bDate NULL, [Description] bItemDesc NULL,
		UM bUM NULL, ActualUnitCost bUnitCost NOT NULL, PerECM bECM NULL, ActualHours bHrs NOT NULL, ActualUnits bUnits NOT NULL, ActualCost bDollar NOT NULL,
		PostedUM bUM NULL, PostedUnits bUnits NOT NULL, PostedUnitCost bDollar NOT NULL, PostedECM bECM NULL,
		PostRemCmUnits bUnits NOT NULL, RemainCmtdCost bDollar NOT NULL, RemCmtdTax bDollar NOT NULL,
		PRCo bCompany NULL, Employee bEmployee NULL, Craft bCraft NULL, Class bClass NULL, Crew varchar(10) NULL, EarnFactor bRate NULL, EarnType bEarnType NULL, Shift tinyint NULL, LiabilityType bLiabilityType NULL,
		VendorGroup bGroup NULL, Vendor bVendor NULL, APCo bCompany NULL, PO varchar(30) NULL, POItem bItem NULL, POItemLine int NULL, MatlGroup bGroup NULL, Material bMatl NULL,
		INCo bCompany NULL, Loc bLoc NULL, INStdUnitCost bUnitCost NOT NULL, INStdECM bECM NULL, INStdUM bUM NULL,
		EMCo bCompany NULL, Equipment bEquip NULL, EMGroup bGroup NULL, RevCode bRevCode NULL,
		TaxType tinyint NULL, TaxGroup bGroup NULL, TaxCode bTaxCode NULL, TaxBasis bDollar NOT NULL, TaxAmt bDollar NOT NULL)
	
	INSERT @SummarizedJobCostDistributions (
		JCCo, Job, PhaseGroup, Phase, CostType, 
		ActualDate, [Description],
		UM, ActualUnitCost, PerECM, ActualHours, ActualUnits, ActualCost,
		PostedUM, PostedUnits, PostedUnitCost, PostedECM,
		PostRemCmUnits, RemainCmtdCost, RemCmtdTax,
		PRCo, Employee, Craft, Class, Crew, EarnFactor, EarnType, Shift, LiabilityType,
		VendorGroup, Vendor, APCo, PO, POItem, POItemLine,
		MatlGroup, Material, INCo, Loc, INStdUnitCost, INStdECM, INStdUM,
		EMCo, Equipment, RevCode, EMGroup,
		TaxType, TaxGroup, TaxCode, TaxBasis, TaxAmt)
	SELECT 
		JCCo, Job, PhaseGroup, Phase, CostType, 
		ActualDate, [Description],
		UM, ActualUnitCost, PerECM, ActualHours, ActualUnits, ActualCost,
		PostedUM, PostedUnits, PostedUnitCost, PostedECM,
		PostRemCmUnits, RemainCmtdCost, RemCmtdTax,
		PRCo, Employee, Craft, Class, Crew, EarnFactor, EarnType, Shift, LiabilityType,
		VendorGroup, Vendor, APCo, PO, POItem, POItemLine,
		MatlGroup, Material, INCo, Loc, INStdUnitCost, INStdECM, INStdUM,
		EMCo, Equipment, RevCode, EMGroup,
		TaxType, TaxGroup, TaxCode, TaxBasis, TaxAmt
	FROM dbo.vfJCCostEntryTransactionSummary(@BatchCo, @BatchMth, @BatchId, NULL, NULL, NULL)

	BEGIN TRY
		--Posting is done within a transaction to ensure everything is posted or nothing is posted.
		BEGIN TRAN

		--Each record being posted to JCCD needs a trans#.
		WHILE EXISTS(SELECT 1 FROM @SummarizedJobCostDistributions WHERE JCCDCostTrans IS NULL)
		BEGIN
			SELECT TOP 1 @JCCo = JCCo
			FROM @SummarizedJobCostDistributions
			WHERE JCCDCostTrans IS NULL
		
			--Get Next JC Cost Transactions  need to create records here so we don't get trigger errors in JCCD and mess up batch posting.
			--JCCD records can always be reversed out.
			EXEC @JCCDCostTrans = dbo.bspHQTCNextTrans @tablename = 'bJCCD', @co = @JCCo, @mth = @BatchMth, @errmsg = @msg OUTPUT
			IF  @JCCDCostTrans = 0
			BEGIN
				SET @msg = 'Failed to get next JC Cost Detial Trans ' + @msg
				ROLLBACK TRAN
				RETURN 1
			END

			UPDATE TOP (1) @SummarizedJobCostDistributions
			SET JCCDCostTrans = @JCCDCostTrans
			WHERE JCCo = @JCCo AND JCCDCostTrans IS NULL
		END

		INSERT dbo.bJCCD (JCCo, Mth, CostTrans, Job, PhaseGroup, Phase, CostType, 
			PostedDate, ActualDate, JCTransType, [Source], [Description],
			UM, ActualUnitCost, PerECM, ActualHours, ActualUnits, ActualCost,
			PostedUM, PostedUnits, PostedUnitCost, PostedECM,
			PostRemCmUnits, RemainCmtdCost, RemCmtdTax,
			PRCo, Employee, Craft, Class, Crew, EarnFactor, EarnType, Shift, LiabilityType,
			VendorGroup, Vendor, APCo, PO, POItem, POItemLine,
			MatlGroup, Material, INCo, Loc, INStdUnitCost, INStdECM, INStdUM,
			EMCo, EMEquip, EMRevCode, EMGroup,
			TaxType, TaxGroup, TaxCode, TaxBasis, TaxAmt
		)
		SELECT JCCo, @BatchMth, JCCDCostTrans, Job, PhaseGroup, Phase, CostType, 
			@PostedDate, ActualDate, @JCTransType, 'SM WorkOrd', [Description],
			UM, ActualUnitCost, PerECM, ActualHours, ActualUnits, ActualCost,
			PostedUM, PostedUnits, PostedUnitCost, PostedECM,
			PostRemCmUnits, RemainCmtdCost, RemCmtdTax,
			PRCo, Employee, Craft, Class, Crew, EarnFactor, EarnType, Shift, LiabilityType,
			VendorGroup, Vendor, APCo, PO, POItem, POItemLine,
			MatlGroup, Material, INCo, Loc, INStdUnitCost, INStdECM, INStdUM,
			EMCo, Equipment, RevCode, EMGroup,
			TaxType, TaxGroup, TaxCode, TaxBasis, TaxAmt
		FROM @SummarizedJobCostDistributions

		--If GL was posted along with JC then the JCCD trans# needs to be updated in the GLEntryTransaction description.
		UPDATE vGLEntryTransaction
		SET [Description] = REPLACE(vGLEntryTransaction.[Description], 'Trans #', ISNULL(CAST(SummarizedJobCostDistributions.JCCDCostTrans AS varchar), 'N/A'))
		FROM HQBatchDistributionGLEntryTransaction
			INNER JOIN dbo.vGLEntryTransaction ON HQBatchDistributionGLEntryTransaction.GLEntryID = vGLEntryTransaction.GLEntryID AND HQBatchDistributionGLEntryTransaction.GLTransaction = vGLEntryTransaction.GLTransaction
			INNER JOIN dbo.vJCCostEntryTransaction ON HQBatchDistributionGLEntryTransaction.JCCostEntryID = vJCCostEntryTransaction.JCCostEntryID AND HQBatchDistributionGLEntryTransaction.JCCostTransaction = vJCCostEntryTransaction.JCCostTransaction
			INNER JOIN @SummarizedJobCostDistributions SummarizedJobCostDistributions ON
				CHECKSUM(vJCCostEntryTransaction.JCCo, vJCCostEntryTransaction.Job, vJCCostEntryTransaction.PhaseGroup, vJCCostEntryTransaction.Phase, vJCCostEntryTransaction.CostType,
					vJCCostEntryTransaction.ActualDate, vJCCostEntryTransaction.[Description], vJCCostEntryTransaction.UM, vJCCostEntryTransaction.ActualUnitCost, vJCCostEntryTransaction.PerECM,
					vJCCostEntryTransaction.PostedUM, vJCCostEntryTransaction.PostedUnitCost, vJCCostEntryTransaction.PostedECM,
					vJCCostEntryTransaction.PRCo, vJCCostEntryTransaction.Employee, vJCCostEntryTransaction.Craft, vJCCostEntryTransaction.Class, vJCCostEntryTransaction.Crew, vJCCostEntryTransaction.EarnFactor, vJCCostEntryTransaction.EarnType, vJCCostEntryTransaction.Shift, vJCCostEntryTransaction.LiabilityType,
					vJCCostEntryTransaction.VendorGroup, vJCCostEntryTransaction.Vendor, vJCCostEntryTransaction.APCo, vJCCostEntryTransaction.PO, vJCCostEntryTransaction.POItem, vJCCostEntryTransaction.POItemLine, vJCCostEntryTransaction.MatlGroup, vJCCostEntryTransaction.Material,
					vJCCostEntryTransaction.INCo, vJCCostEntryTransaction.Loc, vJCCostEntryTransaction.INStdUnitCost, vJCCostEntryTransaction.INStdECM, vJCCostEntryTransaction.INStdUM,
					vJCCostEntryTransaction.EMCo, vJCCostEntryTransaction.Equipment, vJCCostEntryTransaction.EMGroup, vJCCostEntryTransaction.RevCode,
					vJCCostEntryTransaction.TaxType, vJCCostEntryTransaction.TaxGroup, vJCCostEntryTransaction.TaxCode) =
				CHECKSUM(SummarizedJobCostDistributions.JCCo, SummarizedJobCostDistributions.Job, SummarizedJobCostDistributions.PhaseGroup, SummarizedJobCostDistributions.Phase, SummarizedJobCostDistributions.CostType,
					SummarizedJobCostDistributions.ActualDate, SummarizedJobCostDistributions.[Description], SummarizedJobCostDistributions.UM, SummarizedJobCostDistributions.ActualUnitCost, SummarizedJobCostDistributions.PerECM,
					SummarizedJobCostDistributions.PostedUM, SummarizedJobCostDistributions.PostedUnitCost, SummarizedJobCostDistributions.PostedECM,
					SummarizedJobCostDistributions.PRCo, SummarizedJobCostDistributions.Employee, SummarizedJobCostDistributions.Craft, SummarizedJobCostDistributions.Class, SummarizedJobCostDistributions.Crew, SummarizedJobCostDistributions.EarnFactor, SummarizedJobCostDistributions.EarnType, SummarizedJobCostDistributions.Shift, SummarizedJobCostDistributions.LiabilityType,
					SummarizedJobCostDistributions.VendorGroup, SummarizedJobCostDistributions.Vendor, SummarizedJobCostDistributions.APCo, SummarizedJobCostDistributions.PO, SummarizedJobCostDistributions.POItem, SummarizedJobCostDistributions.POItemLine, SummarizedJobCostDistributions.MatlGroup, SummarizedJobCostDistributions.Material,
					SummarizedJobCostDistributions.INCo, SummarizedJobCostDistributions.Loc, SummarizedJobCostDistributions.INStdUnitCost, SummarizedJobCostDistributions.INStdECM, SummarizedJobCostDistributions.INStdUM,
					SummarizedJobCostDistributions.EMCo, SummarizedJobCostDistributions.Equipment, SummarizedJobCostDistributions.EMGroup, SummarizedJobCostDistributions.RevCode,
					SummarizedJobCostDistributions.TaxType, SummarizedJobCostDistributions.TaxGroup, SummarizedJobCostDistributions.TaxCode)
		WHERE HQBatchDistributionGLEntryTransaction.Co = @BatchCo AND HQBatchDistributionGLEntryTransaction.Mth = @BatchMth AND HQBatchDistributionGLEntryTransaction.BatchId = @BatchId

		--Once the JCCostEntrys are posted then we don't want them to be associated with the batch anymore.
		--The JCCostEntrys are not deleted as they may be used for reversing entrys later.
		UPDATE vJCCostEntry
		SET HQBatchDistributionID = NULL
		FROM dbo.vHQBatchDistribution
			INNER JOIN dbo.vJCCostEntry ON vHQBatchDistribution.HQBatchDistributionID = vHQBatchDistribution.HQBatchDistributionID
		WHERE vHQBatchDistribution.Co = @BatchCo AND vHQBatchDistribution.Mth = @BatchMth AND vHQBatchDistribution.BatchId = @BatchId
		
		COMMIT TRAN
	END TRY
	BEGIN CATCH
		SET @msg = ERROR_MESSAGE()
		ROLLBACK TRAN
		RETURN 1
	END CATCH
	
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[vspJobCostEntryTransactionPost] TO [public]
GO
