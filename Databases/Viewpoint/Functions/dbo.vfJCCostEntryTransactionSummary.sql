SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 5/11/12
-- Description:	Builds the entries that will be used for posting Job Cost records
-- =============================================
CREATE FUNCTION [dbo].[vfJCCostEntryTransactionSummary]
(	
	@Co bCompany, @Mth bMonth, @BatchId bBatchID, @PRGroup bGroup, @PREndDate bDate, @Source bSource
)
RETURNS TABLE 
AS
RETURN 
(
	WITH BatchJCCostEntry
	AS
	(
		SELECT Mth, 1 AmountSign, JCCostEntryID
		FROM dbo.vHQBatchDistribution
			INNER JOIN dbo.vJCCostEntry ON vHQBatchDistribution.HQBatchDistributionID = vJCCostEntry.HQBatchDistributionID
		WHERE Co = @Co AND Mth = @Mth AND BatchId = @BatchId
	),
	PayPeriodJCCostEntry
	AS
	(
		SELECT vPRLedgerUpdateMonth.Mth, CASE WHEN vPRLedgerUpdateMonth.Posted = 1 THEN -1 ELSE 1 END AmountSign, vJCCostEntry.JCCostEntryID
		FROM dbo.vPRLedgerUpdateMonth
			INNER JOIN dbo.vJCCostEntry ON vPRLedgerUpdateMonth.PRLedgerUpdateMonthID = vJCCostEntry.PRLedgerUpdateMonthID
		WHERE vPRLedgerUpdateMonth.PRCo = @Co AND vPRLedgerUpdateMonth.PRGroup = @PRGroup AND vPRLedgerUpdateMonth.PREndDate = @PREndDate AND vJCCostEntry.[Source] = @Source AND (@Mth IS NULL OR vPRLedgerUpdateMonth.Mth = @Mth)
	),
	JCCostEntries
	AS
	(
		SELECT Mth, AmountSign, JCCostEntryID
		FROM BatchJCCostEntry
		UNION
		SELECT Mth, AmountSign, JCCostEntryID
		FROM PayPeriodJCCostEntry
	),
	SummaryJCCostEntry
	AS
	(
		SELECT
			JCCo, Job, PhaseGroup, Phase, CostType, ActualDate, [Description],
			UM, ActualUnitCost, PerECM, SUM(AmountSign * ActualHours) ActualHours, SUM(AmountSign * ActualUnits) ActualUnits, SUM(AmountSign * ActualCost) ActualCost,
			PostedUM, SUM(AmountSign * PostedUnits) PostedUnits, PostedUnitCost, PostedECM, SUM(AmountSign * PostRemCmUnits) PostRemCmUnits,
			SUM(AmountSign * RemainCmtdCost) RemainCmtdCost, SUM(AmountSign * RemCmtdTax) RemCmtdTax,
			PRCo, Employee, Craft, Class, Crew, EarnFactor, EarnType, Shift, LiabilityType,
			VendorGroup, Vendor, APCo, PO, POItem, POItemLine, MatlGroup, Material,
			INCo, Loc, INStdUnitCost, INStdECM, INStdUM,
			EMCo, Equipment, EMGroup, RevCode,
			TaxType, TaxGroup, TaxCode, SUM(AmountSign * TaxBasis) TaxBasis, SUM(AmountSign * TaxAmt) TaxAmt
		FROM JCCostEntries
			INNER JOIN dbo.vJCCostEntryTransaction ON JCCostEntries.JCCostEntryID = vJCCostEntryTransaction.JCCostEntryID
		GROUP BY
			JCCo, Job, PhaseGroup, Phase, CostType,
			ActualDate, [Description], UM, ActualUnitCost, PerECM,
			PostedUM, PostedUnitCost, PostedECM,
			PRCo, Employee, Craft, Class, Crew, EarnFactor, EarnType, Shift, LiabilityType,
			VendorGroup, Vendor, APCo, PO, POItem, POItemLine, MatlGroup, Material,
			INCo, Loc, INStdUnitCost, INStdECM, INStdUM,
			EMCo, Equipment, EMGroup, RevCode,
			TaxType, TaxGroup, TaxCode
	)
	SELECT *
	FROM SummaryJCCostEntry
	WHERE ActualHours <> 0 OR ActualUnits <> 0 OR ActualCost <> 0 OR PostedUnits <> 0 OR PostRemCmUnits <> 0 OR RemainCmtdCost <> 0 OR RemCmtdTax <> 0 OR TaxBasis <> 0 OR TaxAmt <> 0
)
GO
GRANT SELECT ON  [dbo].[vfJCCostEntryTransactionSummary] TO [public]
GO
