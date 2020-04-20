SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 10/13/11
-- Description:	Returns the price rate for an equipment line.
-- Modified:    Jacob VH	2/6/13 TFS-39301 Modified to work with changes made to support company copy on rate overrides
--				EricV  05/31/13 TFS-4171 Replaced Work Completed Coverage field with NonBillable and UseAgreementRates fields
-- =============================================
CREATE FUNCTION [dbo].[vfSMRateEquipment]
(	
	@SMCo bCompany, 
	@WorkOrder int, 
	@Scope int, 
	@Date bDate,
	@Agreement varchar(15),
	@Revision int,
	@NonBillable bYN,
	@UseAgreementRates bYN,
	@EMCo bCompany, 
	@Equipment bEquip, 
	@RevCode bRevCode, 
	@CostRate bUnitCost
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT vfSMGetBillableRateSetup.RateTemplate, vfSMGetBillableRateSetup.EffectiveDate,
		DeriveBillableRate.*,
		CASE
			WHEN vfSMGetBillableRateSetup.IsCoveredUnderAgreement = 1 THEN 0
			WHEN vfSMGetBillableRateSetup.IsActualCostJobWorkOrder = 1 THEN @CostRate
			WHEN DeriveBillableRate.MarkupOrFlatRate = 'F' THEN DeriveBillableRate.FlatRateAmount
			WHEN DeriveBillableRate.MarkupOrFlatRate = 'M' THEN @CostRate * (DeriveBillableRate.MarkupAmount / 100 + 1) -- Divide by 100 to convert to decimal
		END PriceRate
	FROM dbo.vfSMGetBillableRateSetup(@SMCo, @WorkOrder, @Scope, @Date, @Agreement, @Revision, @NonBillable, @UseAgreementRates)
	OUTER APPLY
		(
			SELECT TOP 1 *
			FROM
			(	
				--Quote Advanced Rate
				SELECT 8 RateSource, MarkupOrFlatRate, MarkupAmount, FlatRateAmount
				FROM dbo.vSMRateOverrideEquipment
				WHERE SMCo = @SMCo AND EntitySeq = vfSMGetBillableRateSetup.SMWOQuoteScopeEntitySeq AND EMCo = @EMCo AND Equipment = @Equipment AND RevCode = @RevCode

				UNION ALL

				--Quote Basic Rate
				SELECT 7 RateSource, 'M' MarkupOrFlatRate, EquipmentMarkup, NULL FlatRateAmount
				FROM dbo.vSMRateOverrideBaseRate
				WHERE SMCo = @SMCo AND EntitySeq = vfSMGetBillableRateSetup.SMWOQuoteScopeEntitySeq AND EquipmentMarkup IS NOT NULL

				UNION ALL

				--Service Site Advanced Rate
				SELECT 6 RateSource, MarkupOrFlatRate, MarkupAmount, FlatRateAmount
				FROM dbo.vSMRateOverrideEquipment
				WHERE SMCo = @SMCo AND EntitySeq = vfSMGetBillableRateSetup.SMServiceSiteEntitySeq AND EMCo = @EMCo AND Equipment = @Equipment AND RevCode = @RevCode

				UNION ALL

				--Service Site Basic Rate
				SELECT 5 RateSource, 'M' MarkupOrFlatRate, EquipmentMarkup, NULL FlatRateAmount
				FROM dbo.vSMRateOverrideBaseRate
				WHERE SMCo = @SMCo AND EntitySeq = vfSMGetBillableRateSetup.SMServiceSiteEntitySeq AND EquipmentMarkup IS NOT NULL

				UNION ALL

				--Customer Advanced Rate
				SELECT 4 RateSource, MarkupOrFlatRate, MarkupAmount, FlatRateAmount
				FROM dbo.vSMRateOverrideEquipment
				WHERE SMCo = @SMCo AND EntitySeq = vfSMGetBillableRateSetup.SMCustomerEntitySeq AND EMCo = @EMCo AND Equipment = @Equipment AND RevCode = @RevCode

				UNION ALL

				--Customer Basic Rate
				SELECT 3 RateSource, 'M' MarkupOrFlatRate, EquipmentMarkup, NULL FlatRateAmount
				FROM dbo.vSMRateOverrideBaseRate
				WHERE SMCo = @SMCo AND EntitySeq = vfSMGetBillableRateSetup.SMCustomerEntitySeq AND EquipmentMarkup IS NOT NULL

				UNION ALL
				
				--Rate Template or Rate Template Effective Date Advance Rate
				SELECT 2 RateSource, MarkupOrFlatRate, MarkupAmount, FlatRateAmount
				FROM dbo.vSMRateOverrideEquipment
				WHERE SMCo = @SMCo AND EntitySeq = vfSMGetBillableRateSetup.SMRateTemplateEntitySeq AND EMCo = @EMCo AND Equipment = @Equipment AND RevCode = @RevCode

				UNION ALL
				
				-- RateTemplate or RateTemplate EffectiveDate Rate
				SELECT 1 RateSource, 'M' MarkupOrFlatRate, EquipmentMarkup, NULL FlatRateAmount
			) GetRates
			ORDER BY GetRates.RateSource DESC
		) DeriveBillableRate
)
GO
GRANT SELECT ON  [dbo].[vfSMRateEquipment] TO [public]
GO
