SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 12/17/12
-- Description:	Retrieves material rate setup for a given work order scope.
-- Modified:    Jacob VH	2/6/13 TFS-39301 Modified to work with changes made to support company copy on rate overrides
--				EricV  05/31/13 TFS-4171 Replaced Work Completed Coverage field with NonBillable and UseAgreementRates fields
-- =============================================
CREATE FUNCTION [dbo].[vfSMRateMaterial]
(	
	@SMCo bCompany, @WorkOrder int, @Scope int, @Date bDate, @Agreement varchar(15), @Revision int, @NonBillable bYN, @UseAgreementRates bYN, @MaterialGroup bGroup, @Material bMatl
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT vfSMGetBillableRateSetup.RateTemplate, vfSMGetBillableRateSetup.EffectiveDate, vfSMGetBillableRateSetup.IsCoveredUnderAgreement, vfSMGetBillableRateSetup.IsActualCostJobWorkOrder, DeriveBillableRate.*, bHQMT.StdUM, bHQMT.Cost StdCost, bHQMT.CostECM StdCostECM
	FROM dbo.vfSMGetBillableRateSetup(@SMCo, @WorkOrder, @Scope, @Date, @Agreement, @Revision, @NonBillable, @UseAgreementRates)
		LEFT JOIN dbo.bHQMT ON bHQMT.MatlGroup = @MaterialGroup AND bHQMT.Material = @Material
		OUTER APPLY
		(
			SELECT TOP 1 *
			FROM
			(
				--Quote Advanced Rate
				SELECT 8 RateSource, vfSMRateMaterialAdvanced.MarkupOrDiscount, vfSMRateMaterialAdvanced.Basis, vfSMRateMaterialAdvanced.[Percent], vSMRateOverrideBaseRate.EntitySeq, vfSMRateMaterialAdvanced.RateOverrideMaterialSeq
				FROM dbo.vSMRateOverrideBaseRate
					CROSS APPLY dbo.vfSMRateMaterialAdvanced(@SMCo, vSMRateOverrideBaseRate.EntitySeq, @MaterialGroup, bHQMT.Category, @Material)
				WHERE vSMRateOverrideBaseRate.SMCo = @SMCo AND vSMRateOverrideBaseRate.EntitySeq = vfSMGetBillableRateSetup.SMWOQuoteScopeEntitySeq AND vSMRateOverrideBaseRate.MaterialBasis <> 'N'

				UNION ALL

				--Quote Basic Rate
				SELECT 7 RateSource, vSMRateOverrideBaseRate.MaterialMarkupOrDiscount, vSMRateOverrideBaseRate.MaterialBasis, vSMRateOverrideBaseRate.MaterialPercent, vSMRateOverrideBaseRate.EntitySeq, NULL RateOverrideMaterialSeq
				FROM dbo.vSMRateOverrideBaseRate
				WHERE vSMRateOverrideBaseRate.SMCo = @SMCo AND vSMRateOverrideBaseRate.EntitySeq = vfSMGetBillableRateSetup.SMWOQuoteScopeEntitySeq AND vSMRateOverrideBaseRate.MaterialBasis <> 'N'

				UNION ALL

				--Service Site Advanced Rate
				SELECT 6 RateSource, vfSMRateMaterialAdvanced.MarkupOrDiscount, vfSMRateMaterialAdvanced.Basis, vfSMRateMaterialAdvanced.[Percent], vSMRateOverrideBaseRate.EntitySeq, vfSMRateMaterialAdvanced.RateOverrideMaterialSeq
				FROM dbo.vSMRateOverrideBaseRate
					CROSS APPLY dbo.vfSMRateMaterialAdvanced(@SMCo, vSMRateOverrideBaseRate.EntitySeq, @MaterialGroup, bHQMT.Category, @Material)
				WHERE vSMRateOverrideBaseRate.SMCo = @SMCo AND vSMRateOverrideBaseRate.EntitySeq = vfSMGetBillableRateSetup.SMServiceSiteEntitySeq AND vSMRateOverrideBaseRate.MaterialBasis <> 'N'

				UNION ALL

				--Service Site Basic Rate
				SELECT 5 RateSource, vSMRateOverrideBaseRate.MaterialMarkupOrDiscount, vSMRateOverrideBaseRate.MaterialBasis, vSMRateOverrideBaseRate.MaterialPercent, vSMRateOverrideBaseRate.EntitySeq, NULL RateOverrideMaterialSeq
				FROM dbo.vSMRateOverrideBaseRate
				WHERE vSMRateOverrideBaseRate.SMCo = @SMCo AND vSMRateOverrideBaseRate.EntitySeq = vfSMGetBillableRateSetup.SMServiceSiteEntitySeq AND vSMRateOverrideBaseRate.MaterialBasis <> 'N'

				UNION ALL

				--Customer Advanced Rate
				SELECT 4 RateSource, vfSMRateMaterialAdvanced.MarkupOrDiscount, vfSMRateMaterialAdvanced.Basis, vfSMRateMaterialAdvanced.[Percent], vSMRateOverrideBaseRate.EntitySeq, vfSMRateMaterialAdvanced.RateOverrideMaterialSeq
				FROM dbo.vSMRateOverrideBaseRate
					CROSS APPLY dbo.vfSMRateMaterialAdvanced(@SMCo, vSMRateOverrideBaseRate.EntitySeq, @MaterialGroup, bHQMT.Category, @Material)
				WHERE vSMRateOverrideBaseRate.SMCo = @SMCo AND vSMRateOverrideBaseRate.EntitySeq = vfSMGetBillableRateSetup.SMCustomerEntitySeq AND vSMRateOverrideBaseRate.MaterialBasis <> 'N'

				UNION ALL

				--Customer Basic Rate
				SELECT 3 RateSource, vSMRateOverrideBaseRate.MaterialMarkupOrDiscount, vSMRateOverrideBaseRate.MaterialBasis, vSMRateOverrideBaseRate.MaterialPercent, vSMRateOverrideBaseRate.EntitySeq, NULL RateOverrideMaterialSeq
				FROM dbo.vSMRateOverrideBaseRate
				WHERE vSMRateOverrideBaseRate.SMCo = @SMCo AND vSMRateOverrideBaseRate.EntitySeq = vfSMGetBillableRateSetup.SMCustomerEntitySeq AND vSMRateOverrideBaseRate.MaterialBasis <> 'N'
				
				UNION ALL
				
				--Rate Template or Rate Template Effective Date Advance Rate
				SELECT 2 RateSource, vfSMRateMaterialAdvanced.MarkupOrDiscount, vfSMRateMaterialAdvanced.Basis, vfSMRateMaterialAdvanced.[Percent], vfSMGetBillableRateSetup.SMRateTemplateEntitySeq EntitySeq, vfSMRateMaterialAdvanced.RateOverrideMaterialSeq
				FROM dbo.vfSMRateMaterialAdvanced(@SMCo, vfSMGetBillableRateSetup.SMRateTemplateEntitySeq, @MaterialGroup, bHQMT.Category, @Material)

				UNION ALL
				
				--RateTemplate or RateTemplate EffectiveDate Rate
				SELECT 1 RateSource, vfSMGetBillableRateSetup.MaterialMarkupOrDiscount, vfSMGetBillableRateSetup.MaterialBasis, vfSMGetBillableRateSetup.MaterialPercent, vfSMGetBillableRateSetup.SMRateTemplateEntitySeq EntitySeq, NULL RateOverrideMaterialSeq
			) GetRates
			ORDER BY GetRates.RateSource DESC
		) DeriveBillableRate
)
GO
GRANT SELECT ON  [dbo].[vfSMRateMaterial] TO [public]
GO
