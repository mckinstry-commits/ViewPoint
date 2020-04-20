SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 12/17/12
-- Description:	Calculates the PriceRate and PriceTotal for a purchase line.
CREATE FUNCTION [dbo].[vfSMRatePurchase]
(
	@SMCo bCompany, @WorkOrder int, @Scope int, @Date bDate, @Agreement varchar(15), @Revision int, @Coverage varchar(1), @MaterialGroup bGroup, @Material bMatl, @CostUM bUM, @CostQuantity bUnits, @CostTotal bDollar, @PriceUM bUM, @PriceECM bECM
)
RETURNS TABLE
AS
RETURN
(
	WITH MaterialCostSetup
	AS
	(
		SELECT Cost, CostECM, Conversion
		FROM dbo.bHQMU
		WHERE MatlGroup = @MaterialGroup AND Material = @Material AND UM = @CostUM
	),
	MaterialPriceSetup
	AS
	(
		SELECT Conversion
		FROM dbo.bHQMU
		WHERE MatlGroup = @MaterialGroup AND Material = @Material AND UM = @PriceUM
	)
	SELECT vfSMRateMaterial.RateTemplate, vfSMRateMaterial.EffectiveDate, vfSMRateMaterial.RateSource, vfSMRateMaterial.MarkupOrDiscount, GetBasis.Basis,
		GetCostBasis.CostBasisTotal, GetBreakPointPercent.BreakPointPercent, GetMarkupPercent.MarkupPercent,
		GetPriceQuantity.PriceQuantity,
		CAST(
		CASE
			WHEN GetPriceQuantity.PriceQuantity = 0 THEN 0
			ELSE (GetPriceTotal.PriceTotal * dbo.vpfECMFactor(@PriceECM) / GetPriceQuantity.PriceQuantity) 
		END AS NUMERIC(16,5)) PriceRate,
		GetPriceTotal.PriceTotal
	FROM dbo.vfSMRateMaterial(@SMCo, @WorkOrder, @Scope, @Date, @Agreement, @Revision, @Coverage, @MaterialGroup, @Material)
		CROSS APPLY
		(
			SELECT 
				CASE
					--When the PO is using a lump sum then a standard cost cannot be calcluated so actual cost is used instead
					WHEN vfSMRateMaterial.Basis = 'S' AND (@CostUM = 'LS' OR vfSMRateMaterial.StdCost IS NULL) THEN 'A'
					--Currently there is no setup to be able to calculate average and last costs for POs
					WHEN vfSMRateMaterial.Basis = 'V' THEN 'A'
					WHEN vfSMRateMaterial.Basis = 'L' THEN 'A'
					ELSE vfSMRateMaterial.Basis
				END Basis
		) GetBasis
		
		CROSS APPLY
		(
			SELECT
				CASE GetBasis.Basis
					WHEN 'A' THEN @CostTotal
					--Calculate standard costs
					WHEN 'S' THEN
						CASE 
							WHEN @CostUM = vfSMRateMaterial.StdUM THEN @CostQuantity * vfSMRateMaterial.StdCost / dbo.vpfECMFactor(vfSMRateMaterial.StdCostECM)
							ELSE (SELECT @CostQuantity * Cost / dbo.vpfECMFactor(CostECM) FROM MaterialCostSetup)
						END
				END CostBasisTotal
		) GetCostBasis
		
		CROSS APPLY
		(
			SELECT
			(
				SELECT TOP 1 [Percent]
				FROM dbo.vSMRateOverrideMatlBP 
				WHERE SMRateOverrideID = vfSMRateMaterial.SMRateOverrideID AND
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
			SELECT
				CAST(
				CASE
					WHEN @CostUM = 'LS' THEN NULL
					WHEN @CostUM = @PriceUM THEN @CostQuantity
					ELSE @CostQuantity *
						CASE WHEN @CostUM = vfSMRateMaterial.StdUM THEN 1 ELSE (SELECT Conversion FROM MaterialCostSetup) END /
						CASE WHEN @PriceUM = vfSMRateMaterial.StdUM THEN 1 ELSE (SELECT Conversion FROM MaterialPriceSetup) END
				END AS NUMERIC(12,3)) PriceQuantity
		) GetPriceQuantity
		
		CROSS APPLY
		(
			SELECT 
				CAST(
				CASE
					WHEN vfSMRateMaterial.IsCoveredUnderAgreement = 1 THEN 0
					WHEN vfSMRateMaterial.IsActualCostJobWorkOrder = 1 THEN @CostTotal
					ELSE GetCostBasis.CostBasisTotal * (GetMarkupPercent.MarkupPercent / 100 + 1)
				END AS NUMERIC(12,2)) PriceTotal
		) GetPriceTotal
)
GO
GRANT SELECT ON  [dbo].[vfSMRatePurchase] TO [public]
GO
