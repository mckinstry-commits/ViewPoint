
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 7/7/11
-- Description:	Retrieves the labor rate for a work completed record
-- Modified:    Jacob VH	2/6/13 TFS-39301 Modified to work with changes made to support company copy on rate overrides
--				EricV  05/31/13 TFS-4171 Replaced Work Completed Coverage field with NonBillable and UseAgreementRates fields
-- =============================================
CREATE FUNCTION [dbo].[vfSMRateLabor]
(	
	@SMCo bCompany,
	@WorkOrder int,
	@Scope int,
	@Date bDate,
	@Agreement varchar(15),
	@Revision int,
	@NonBillable bYN,
	@UseAgreementRates bYN,
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
	FROM dbo.vfSMGetBillableRateSetup(@SMCo, @WorkOrder, @Scope, @Date, @Agreement, @Revision, @NonBillable, @UseAgreementRates)
		OUTER APPLY
		(
			SELECT TOP 1 *
			FROM
			(
				--Quote Advanced Rate
				SELECT 8 RateSource, AdvancedRateSource, Rate
				FROM dbo.vfSMRateLaborAdvanced(@SMCo, vfSMGetBillableRateSetup.SMWOQuoteScopeEntitySeq, @PRCo, @PayType, vfSMGetBillableRateSetup.CallType, @Craft, @Class, @Technician)

				UNION ALL

				--Qoute Basic Rate
				SELECT 7 RateSource, NULL AdvancedRateSource, LaborRate
				FROM dbo.vSMRateOverrideBaseRate
				WHERE SMCo = @SMCo AND EntitySeq = vfSMGetBillableRateSetup.SMWOQuoteScopeEntitySeq AND LaborRate IS NOT NULL

				UNION ALL

				--Service Site Advanced Rate
				SELECT 6 RateSource, AdvancedRateSource, Rate
				FROM dbo.vfSMRateLaborAdvanced(@SMCo, vfSMGetBillableRateSetup.SMServiceSiteEntitySeq, @PRCo, @PayType, vfSMGetBillableRateSetup.CallType, @Craft, @Class, @Technician)

				UNION ALL

				--Service Site Basic Rate
				SELECT 5 RateSource, NULL AdvancedRateSource, LaborRate
				FROM dbo.vSMRateOverrideBaseRate
				WHERE SMCo = @SMCo AND EntitySeq = vfSMGetBillableRateSetup.SMServiceSiteEntitySeq AND LaborRate IS NOT NULL

				UNION ALL

				--Customer Advanced Rate
				SELECT 4 RateSource, AdvancedRateSource, Rate
				FROM dbo.vfSMRateLaborAdvanced(@SMCo, vfSMGetBillableRateSetup.SMCustomerEntitySeq, @PRCo, @PayType, vfSMGetBillableRateSetup.CallType, @Craft, @Class, @Technician)

				UNION ALL

				--Customer Basic Rate
				SELECT 3 RateSource, NULL AdvancedRateSource, LaborRate
				FROM dbo.vSMRateOverrideBaseRate
				WHERE SMCo = @SMCo AND EntitySeq = vfSMGetBillableRateSetup.SMCustomerEntitySeq AND LaborRate IS NOT NULL

				UNION ALL
				
				--Rate Template or Rate Template Effective Date Advance Rate
				SELECT 2 RateSource, AdvancedRateSource, Rate
				FROM dbo.vfSMRateLaborAdvanced(@SMCo, vfSMGetBillableRateSetup.SMRateTemplateEntitySeq, @PRCo, @PayType, vfSMGetBillableRateSetup.CallType, @Craft, @Class, @Technician)

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
