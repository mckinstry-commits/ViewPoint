SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 10/13/11
-- Description:	Returns the price rate for an equipment line.
-- =============================================
CREATE FUNCTION [dbo].[vfSMRateEquipment]
(	
	@SMCo bCompany, 
	@WorkOrder int, 
	@Scope int, 
	@Date bDate,
	@Agreement varchar(15),
	@Revision int,
	@Coverage varchar(1),
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
	FROM dbo.vfSMGetBillableRateSetup(@SMCo, @WorkOrder, @Scope, @Date, @Agreement, @Revision, @Coverage)
	OUTER APPLY
		(
			SELECT TOP 1 *
			FROM
			(
				--Service Site Advanced Rate
				SELECT 6 RateSource, MarkupOrFlatRate, MarkupAmount, FlatRateAmount
				FROM dbo.vSMRateOverrideEquipment
				WHERE SMRateOverrideID = vfSMGetBillableRateSetup.SMServiceSiteRateOverrideID AND EMCo = @EMCo AND Equipment = @Equipment AND RevCode = @RevCode

				UNION ALL

				--Service Site Basic Rate
				SELECT 5 RateSource, 'M' MarkupOrFlatRate, EquipmentMarkup, NULL FlatRateAmount
				FROM dbo.vSMRateOverrideBaseRate
				WHERE SMRateOverrideID = vfSMGetBillableRateSetup.SMServiceSiteRateOverrideID AND EquipmentMarkup IS NOT NULL

				UNION ALL

				--Customer Advanced Rate
				SELECT 4 RateSource, MarkupOrFlatRate, MarkupAmount, FlatRateAmount
				FROM dbo.vSMRateOverrideEquipment
				WHERE SMRateOverrideID = vfSMGetBillableRateSetup.SMCustomerRateOverrideID AND EMCo = @EMCo AND Equipment = @Equipment AND RevCode = @RevCode

				UNION ALL

				--Customer Basic Rate
				SELECT 3 RateSource, 'M' MarkupOrFlatRate, EquipmentMarkup, NULL FlatRateAmount
				FROM dbo.vSMRateOverrideBaseRate
				WHERE SMRateOverrideID = vfSMGetBillableRateSetup.SMCustomerRateOverrideID AND EquipmentMarkup IS NOT NULL

				UNION ALL
				
				--Rate Template or Rate Template Effective Date Advance Rate
				SELECT 2 RateSource, MarkupOrFlatRate, MarkupAmount, FlatRateAmount
				FROM dbo.vSMRateOverrideEquipment
				WHERE SMRateOverrideID = vfSMGetBillableRateSetup.SMRateTemplateRateOverrideID AND EMCo = @EMCo AND Equipment = @Equipment AND RevCode = @RevCode

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
