SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 7/7/11
-- Description:	Retrieves the labor rate for a work completed record
-- =============================================
CREATE FUNCTION [dbo].[vfSMRateLabor]
(	
	@SMCo bCompany,
	@WorkOrder int,
	@Scope int,
	@Date bDate,
	@Agreement varchar(15),
	@Revision int,
	@Coverage varchar(1),
	@PRCo bCompany,
	@PayType varchar(10),
	@Craft bCraft,
	@Class bClass,
	@Technician varchar(20)
)
RETURNS TABLE
AS
RETURN
(
	SELECT vfSMGetBillableRateSetup.RateTemplate, vfSMGetBillableRateSetup.EffectiveDate,
		DeriveBillableRate.RateSource, DeriveBillableRate.AdvancedRateSource,
		CASE
			WHEN vfSMGetBillableRateSetup.IsCoveredUnderAgreement = 1 THEN 0
			ELSE DeriveBillableRate.Rate
		END Rate
	FROM dbo.vfSMGetBillableRateSetup(@SMCo, @WorkOrder, @Scope, @Date, @Agreement, @Revision, @Coverage)
		OUTER APPLY
		(
			SELECT TOP 1 *
			FROM
			(
				--Service Site Advanced Rate
				SELECT 6 RateSource, AdvancedRateSource, Rate
				FROM dbo.vfSMRateLaborAdvanced(vfSMGetBillableRateSetup.SMServiceSiteRateOverrideID, @SMCo, @PRCo, @PayType, vfSMGetBillableRateSetup.CallType, @Craft, @Class, @Technician)

				UNION ALL

				--Service Site Basic Rate
				SELECT 5 RateSource, NULL AdvancedRateSource, LaborRate
				FROM dbo.vSMRateOverrideBaseRate
				WHERE SMRateOverrideID = vfSMGetBillableRateSetup.SMServiceSiteRateOverrideID AND LaborRate IS NOT NULL

				UNION ALL

				--Customer Advanced Rate
				SELECT 4 RateSource, AdvancedRateSource, Rate
				FROM dbo.vfSMRateLaborAdvanced(vfSMGetBillableRateSetup.SMCustomerRateOverrideID, @SMCo, @PRCo, @PayType, vfSMGetBillableRateSetup.CallType, @Craft, @Class, @Technician)

				UNION ALL

				--Customer Basic Rate
				SELECT 3 RateSource, NULL AdvancedRateSource, LaborRate
				FROM dbo.vSMRateOverrideBaseRate
				WHERE SMRateOverrideID = vfSMGetBillableRateSetup.SMCustomerRateOverrideID AND LaborRate IS NOT NULL

				UNION ALL
				
				--Rate Template or Rate Template Effective Date Advance Rate
				SELECT 2 RateSource, AdvancedRateSource, Rate
				FROM dbo.vfSMRateLaborAdvanced(vfSMGetBillableRateSetup.SMRateTemplateRateOverrideID, @SMCo, @PRCo, @PayType, vfSMGetBillableRateSetup.CallType, @Craft, @Class, @Technician)

				UNION ALL
				
				--RateTemplate or RateTemplate EffectiveDate Rate
				SELECT 1 RateSource, NULL AdvancedRateSource, vfSMGetBillableRateSetup.LaborRate
			) GetRates
			ORDER BY GetRates.RateSource DESC
		) DeriveBillableRate
)
GO
GRANT SELECT ON  [dbo].[vfSMRateLabor] TO [public]
GO
