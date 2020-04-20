SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 12/17/12
-- Description:	Calculates the PriceRate and PriceTotal for an inventory line.
-- Modified:    Jacob VH	2/6/13 TFS-39301 Modified to work with changes made to support company copy on rate overrides
--				EricV  05/31/13 TFS-4171 Replaced Work Completed Coverage field with NonBillable and UseAgreementRates fields
-- =============================================
CREATE FUNCTION [dbo].[vfSMRateInventory]
(
	@SMCo bCompany, @WorkOrder int, @Scope int, @Date bDate, @Agreement varchar(15), @Revision int, @NonBillable bYN, @UseAgreementRates bYN, @INCo bCompany, @INLocation bLoc, @MaterialGroup bGroup, @Material bMatl, @CostUM bUM, @CostQuantity bUnits, @CostTotal bDollar, @PriceUM bUM, @PriceECM bECM
)
RETURNS TABLE
AS
RETURN
(
	WITH InventoryCostSetup
	AS
	(
		SELECT LastCost, LastECM, AvgCost, AvgECM, StdCost, StdECM
		FROM dbo.bINMT
		WHERE INCo = @INCo AND Loc = @INLocation AND MatlGroup = @MaterialGroup AND Material = @Material
	),
	InventoryAdditionalUMCostSetup
	AS
	(
		SELECT Conversion, StdCost, StdCostECM, LastCost, LastECM
		FROM dbo.bINMU
		WHERE INCo = @INCo AND Loc = @INLocation AND MatlGroup = @MaterialGroup AND Material = @Material AND UM = @CostUM
	),
	InventoryAdditionalUMPriceSetup
	AS
	(
		SELECT Conversion
		FROM dbo.bINMU
		WHERE INCo = @INCo AND Loc = @INLocation AND MatlGroup = @MaterialGroup AND Material = @Material AND UM = @PriceUM
	)
	SELECT vfSMRateMaterial.RateTemplate, vfSMRateMaterial.EffectiveDate, vfSMRateMaterial.RateSource, vfSMRateMaterial.MarkupOrDiscount, vfSMRateMaterial.Basis,
		GetCostBasis.CostBasisTotal, GetBreakPointPercent.BreakPointPercent, GetMarkupPercent.MarkupPercent,
		CAST(GetCostBasis.PriceQuantity AS NUMERIC(12,3)) PriceQuantity,
		CAST(
		CASE
			WHEN vfSMRateMaterial.IsCoveredUnderAgreement = 1 THEN 0
			WHEN vfSMRateMaterial.IsActualCostJobWorkOrder = 1 AND @CostQuantity = 0 THEN 0
			WHEN vfSMRateMaterial.IsActualCostJobWorkOrder = 1 THEN @CostTotal * dbo.vpfECMFactor(@PriceECM) / @CostQuantity
			WHEN GetCostBasis.PriceQuantity = 0 THEN 0
			ELSE (GetPriceTotal.PriceTotal * dbo.vpfECMFactor(@PriceECM) / GetCostBasis.PriceQuantity) 
		END AS NUMERIC(16,5)) PriceRate,
		CAST(
		CASE
			WHEN vfSMRateMaterial.IsCoveredUnderAgreement = 1 THEN 0
			WHEN vfSMRateMaterial.IsActualCostJobWorkOrder = 1 THEN @CostTotal
			ELSE GetPriceTotal.PriceTotal
		END AS NUMERIC(12,2)) PriceTotal
	FROM dbo.vfSMRateMaterial(@SMCo, @WorkOrder, @Scope, @Date, @Agreement, @Revision, @NonBillable, @UseAgreementRates, @MaterialGroup, @Material)
		CROSS APPLY
		(
			SELECT
				CASE vfSMRateMaterial.Basis
					WHEN 'A' THEN @CostTotal
					WHEN 'S' THEN
						CASE 
							WHEN @CostUM = vfSMRateMaterial.StdUM THEN (SELECT @CostQuantity * StdCost / dbo.vpfECMFactor(StdECM) FROM InventoryCostSetup)
							ELSE (SELECT @CostQuantity * StdCost / dbo.vpfECMFactor(StdCostECM) FROM InventoryAdditionalUMCostSetup)
						END
					WHEN 'V' THEN
						CASE 
							WHEN @CostUM = vfSMRateMaterial.StdUM THEN (SELECT @CostQuantity * AvgCost / dbo.vpfECMFactor(AvgECM) FROM InventoryCostSetup)
							ELSE (SELECT @CostQuantity * AvgCost / dbo.vpfECMFactor(AvgECM) FROM InventoryCostSetup) * (SELECT Conversion FROM InventoryAdditionalUMCostSetup)
						END
					WHEN 'L' THEN
						CASE 
							WHEN @CostUM = vfSMRateMaterial.StdUM THEN (SELECT @CostQuantity * LastCost / dbo.vpfECMFactor(LastECM) FROM InventoryCostSetup)
							ELSE (SELECT @CostQuantity * LastCost / dbo.vpfECMFactor(LastECM) FROM InventoryAdditionalUMCostSetup)
						END
				END CostBasisTotal,
				CASE
					WHEN @CostUM = @PriceUM THEN @CostQuantity
					ELSE @CostQuantity *
						CASE WHEN @CostUM = vfSMRateMaterial.StdUM THEN 1 ELSE (SELECT Conversion FROM InventoryAdditionalUMCostSetup) END /
						CASE WHEN @PriceUM = vfSMRateMaterial.StdUM THEN 1 ELSE (SELECT Conversion FROM InventoryAdditionalUMPriceSetup) END
				END PriceQuantity
		) GetCostBasis
		
		CROSS APPLY
		(
			SELECT
			(
				SELECT TOP 1 [Percent] 
				FROM dbo.vSMRateOverrideMatlBP 
				WHERE SMCo = @SMCo AND EntitySeq = vfSMRateMaterial.EntitySeq AND
					(RateOverrideMaterialSeq = vfSMRateMaterial.RateOverrideMaterialSeq OR RateOverrideMaterialSeq IS NULL AND vfSMRateMaterial.RateOverrideMaterialSeq IS NULL) AND
					BreakPoint <= GetCostBasis.CostBasisTotal 
				ORDER BY BreakPoint DESC
			) BreakPointPercent
		) GetBreakPointPercent
		
		CROSS APPLY
		(
			SELECT 
			(
				CASE vfSMRateMaterial.MarkupOrDiscount 
					WHEN 'M' THEN 1
					WHEN 'D' THEN -1
				END
				* ISNULL(GetBreakPointPercent.BreakPointPercent, vfSMRateMaterial.[Percent])
			) MarkupPercent
		) GetMarkupPercent
		
		CROSS APPLY
		(
			SELECT GetCostBasis.CostBasisTotal * (GetMarkupPercent.MarkupPercent / 100 + 1) PriceTotal
		) GetPriceTotal
)
GO
GRANT SELECT ON  [dbo].[vfSMRateInventory] TO [public]
GO
