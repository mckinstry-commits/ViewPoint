SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 12/17/12
-- Description:	Retrieves material rate setup for a given work order scope.
CREATE FUNCTION [dbo].[vfSMRateMaterial]
(	
	@SMCo bCompany, @WorkOrder int, @Scope int, @Date bDate, @Agreement varchar(15), @Revision int, @Coverage varchar(1), @MaterialGroup bGroup, @Material bMatl
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT vfSMGetBillableRateSetup.RateTemplate, vfSMGetBillableRateSetup.EffectiveDate, vfSMGetBillableRateSetup.IsCoveredUnderAgreement, vfSMGetBillableRateSetup.IsActualCostJobWorkOrder, DeriveBillableRate.*, bHQMT.StdUM, bHQMT.Cost StdCost, bHQMT.CostECM StdCostECM
	FROM dbo.vfSMGetBillableRateSetup(@SMCo, @WorkOrder, @Scope, @Date, @Agreement, @Revision, @Coverage)
		LEFT JOIN dbo.bHQMT ON bHQMT.MatlGroup = @MaterialGroup AND bHQMT.Material = @Material
		OUTER APPLY
		(
			SELECT TOP 1 *
			FROM
			(
				--Service Site Advanced Rate
				SELECT 6 RateSource, vfSMRateMaterialAdvanced.MarkupOrDiscount, vfSMRateMaterialAdvanced.Basis, vfSMRateMaterialAdvanced.[Percent], vSMRateOverrideBaseRate.SMRateOverrideID, vfSMRateMaterialAdvanced.RateOverrideMaterialSeq
				FROM dbo.vSMRateOverrideBaseRate
					CROSS APPLY dbo.vfSMRateMaterialAdvanced(vSMRateOverrideBaseRate.SMRateOverrideID, @MaterialGroup, bHQMT.Category, @Material)
				WHERE vSMRateOverrideBaseRate.SMRateOverrideID = vfSMGetBillableRateSetup.SMServiceSiteRateOverrideID AND vSMRateOverrideBaseRate.MaterialBasis <> 'N'

				UNION ALL

				--Service Site Basic Rate
				SELECT 5 RateSource, vSMRateOverrideBaseRate.MaterialMarkupOrDiscount, vSMRateOverrideBaseRate.MaterialBasis, vSMRateOverrideBaseRate.MaterialPercent, vSMRateOverrideBaseRate.SMRateOverrideID, NULL RateOverrideMaterialSeq
				FROM dbo.vSMRateOverrideBaseRate
				WHERE vSMRateOverrideBaseRate.SMRateOverrideID = vfSMGetBillableRateSetup.SMServiceSiteRateOverrideID AND vSMRateOverrideBaseRate.MaterialBasis <> 'N'

				UNION ALL

				--Customer Advanced Rate
				SELECT 4 RateSource, vfSMRateMaterialAdvanced.MarkupOrDiscount, vfSMRateMaterialAdvanced.Basis, vfSMRateMaterialAdvanced.[Percent], vSMRateOverrideBaseRate.SMRateOverrideID, vfSMRateMaterialAdvanced.RateOverrideMaterialSeq
				FROM dbo.vSMRateOverrideBaseRate
					CROSS APPLY dbo.vfSMRateMaterialAdvanced(vSMRateOverrideBaseRate.SMRateOverrideID, @MaterialGroup, bHQMT.Category, @Material)
				WHERE vSMRateOverrideBaseRate.SMRateOverrideID = vfSMGetBillableRateSetup.SMCustomerRateOverrideID AND vSMRateOverrideBaseRate.MaterialBasis <> 'N'

				UNION ALL

				--Customer Basic Rate
				SELECT 3 RateSource, vSMRateOverrideBaseRate.MaterialMarkupOrDiscount, vSMRateOverrideBaseRate.MaterialBasis, vSMRateOverrideBaseRate.MaterialPercent, vSMRateOverrideBaseRate.SMRateOverrideID, NULL RateOverrideMaterialSeq
				FROM dbo.vSMRateOverrideBaseRate
				WHERE vSMRateOverrideBaseRate.SMRateOverrideID = vfSMGetBillableRateSetup.SMCustomerRateOverrideID AND vSMRateOverrideBaseRate.MaterialBasis <> 'N'
				
				UNION ALL
				
				--Rate Template or Rate Template Effective Date Advance Rate
				SELECT 2 RateSource, vfSMRateMaterialAdvanced.MarkupOrDiscount, vfSMRateMaterialAdvanced.Basis, vfSMRateMaterialAdvanced.[Percent], vfSMGetBillableRateSetup.SMRateTemplateRateOverrideID SMRateOverrideID, vfSMRateMaterialAdvanced.RateOverrideMaterialSeq
				FROM dbo.vfSMRateMaterialAdvanced(vfSMGetBillableRateSetup.SMRateTemplateRateOverrideID, @MaterialGroup, bHQMT.Category, @Material)

				UNION ALL
				
				--RateTemplate or RateTemplate EffectiveDate Rate
				SELECT 1 RateSource, vfSMGetBillableRateSetup.MaterialMarkupOrDiscount, vfSMGetBillableRateSetup.MaterialBasis, vfSMGetBillableRateSetup.MaterialPercent, vfSMGetBillableRateSetup.SMRateTemplateRateOverrideID SMRateOverrideID, NULL RateOverrideMaterialSeq
			) GetRates
			ORDER BY GetRates.RateSource DESC
		) DeriveBillableRate
)
GO
GRANT SELECT ON  [dbo].[vfSMRateMaterial] TO [public]
GO
