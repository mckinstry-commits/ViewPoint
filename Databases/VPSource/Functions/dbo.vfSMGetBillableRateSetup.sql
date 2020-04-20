
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 11/27/12
-- Description:	Returns the setup for a given work order scope. Takes into account the rate template effective date setup too.
--				In order for deriving the functions returning the billable rates to always return a value this function should always return 1 record.
-- Modified:    Jacob VH	2/6/13 TFS-39301 Modified to work with changes made to support company copy on rate overrides
--				EricV  05/31/13 TFS-4171 Replaced Work Completed Coverage field with NonBillable and UseAgreementRates fields
-- =============================================
CREATE FUNCTION [dbo].[vfSMGetBillableRateSetup]
(	
	@SMCo bCompany,
	@WorkOrder int,
	@Scope int,
	@Date bDate,
	@Agreement varchar(15), 
	@Revision int, 
	@NonBillable bYN,
	@UseAgreementRates bYN
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT BillableRateSetup.*, DeriveWorkOrderType.*
	FROM dbo.vSMWorkOrderScope
		INNER JOIN dbo.vSMWorkOrder ON vSMWorkOrderScope.SMCo = vSMWorkOrder.SMCo AND vSMWorkOrderScope.WorkOrder = vSMWorkOrder.WorkOrder
		CROSS APPLY
		(
			SELECT 
				CASE WHEN vSMWorkOrder.Job IS NOT NULL AND vSMWorkOrder.CostingMethod = 'Cost' THEN 1 ELSE 0 END IsActualCostJobWorkOrder,
				CASE WHEN vSMWorkOrderScope.[Service] IS NOT NULL THEN 1 ELSE 0 END IsPreventiveMaintenance,
				CASE WHEN @Agreement IS NOT NULL AND @NonBillable = 'Y' THEN 1 ELSE 0 END IsCoveredUnderAgreement,
				CASE WHEN @UseAgreementRates = 'Y' THEN 1 ELSE 0 END UseAgreementRates,
				CASE WHEN vSMWorkOrderScope.WorkOrderQuote IS NOT NULL THEN 1 ELSE 0 END IsQuoteGenerated
			WHERE 
				--Verify the parameters supplied for agreements are all supplied
				((@Agreement IS NOT NULL AND @Revision IS NOT NULL) OR (@Agreement IS NULL AND @Revision IS NULL)) AND
				--Verify for PM work orders the correct agreement and revision are supplied
				((vSMWorkOrderScope.Agreement = @Agreement AND vSMWorkOrderScope.Revision = @Revision) OR vSMWorkOrderScope.[Service] IS NULL)
		) DeriveWorkOrderType
		LEFT JOIN dbo.vSMServiceSite ON vSMWorkOrder.SMCo = vSMServiceSite.SMCo AND vSMWorkOrder.ServiceSite = vSMServiceSite.ServiceSite
		LEFT JOIN dbo.vSMEntity SMServiceSiteEntity ON vSMServiceSite.SMCo = SMServiceSiteEntity.SMCo AND vSMServiceSite.ServiceSite = SMServiceSiteEntity.ServiceSite

		LEFT JOIN dbo.vSMCustomer ON vSMWorkOrder.SMCo = vSMCustomer.SMCo AND vSMWorkOrder.CustGroup = vSMCustomer.CustGroup AND vSMWorkOrder.Customer = vSMCustomer.Customer
		LEFT JOIN dbo.vSMEntity SMCustomerEntity ON vSMServiceSite.SMCo = SMCustomerEntity.SMCo AND vSMServiceSite.CustGroup = SMCustomerEntity.CustGroup AND vSMServiceSite.Customer = SMCustomerEntity.Customer

		LEFT JOIN dbo.vSMWorkOrderQuoteScope ON vSMWorkOrderScope.SMCo = vSMWorkOrderQuoteScope.SMCo AND vSMWorkOrderScope.WorkOrderQuote = vSMWorkOrderQuoteScope.WorkOrderQuote AND vSMWorkOrderScope.Scope = vSMWorkOrderQuoteScope.WorkOrderQuoteScope AND vSMWorkOrderScope.PriceMethod = 'T'
		LEFT JOIN dbo.vSMEntity SMWOQuoteScopeEntity ON vSMWorkOrderQuoteScope.SMCo = SMWOQuoteScopeEntity.SMCo AND vSMWorkOrderQuoteScope.WorkOrderQuote = SMWOQuoteScopeEntity.WorkOrderQuote AND vSMWorkOrderQuoteScope.WorkOrderQuoteScope = SMWOQuoteScopeEntity.WorkOrderQuoteScope

		LEFT JOIN dbo.vSMRateTemplate ON vSMWorkOrderScope.SMCo = vSMRateTemplate.SMCo AND 
			vSMRateTemplate.RateTemplate = 
				CASE
					WHEN DeriveWorkOrderType.IsPreventiveMaintenance = 1 THEN (SELECT PricingRateTemplate FROM dbo.vSMAgreementService WHERE vSMWorkOrderScope.SMCo = vSMAgreementService.SMCo AND vSMWorkOrderScope.Agreement = vSMAgreementService.Agreement AND vSMWorkOrderScope.Revision = vSMAgreementService.Revision AND vSMWorkOrderScope.[Service] = vSMAgreementService.[Service])
					WHEN DeriveWorkOrderType.UseAgreementRates = 1 THEN ISNULL((SELECT RateTemplate FROM dbo.vSMAgreement WHERE SMCo = @SMCo AND Agreement = @Agreement AND Revision = @Revision), vSMWorkOrderScope.RateTemplate) --Currently if the agreement doesn't have a rate template it falls back to the scope template, but this may need to changes.
					WHEN DeriveWorkOrderType.IsQuoteGenerated = 1 THEN vSMWorkOrderQuoteScope.RateTemplate
					ELSE vSMWorkOrderScope.RateTemplate
				END
		LEFT JOIN dbo.vSMEntity SMRateTemplateEntity ON vSMRateTemplate.SMCo = SMRateTemplateEntity.SMCo AND vSMRateTemplate.RateTemplate = SMRateTemplateEntity.RateTemplate AND SMRateTemplateEntity.EffectiveDate IS NULL
		OUTER APPLY
		(
			SELECT TOP 1 vSMWorkOrderScope.CallType, vSMRateTemplate.RateTemplate,
				--When a work order is preventive maintenance or is using agreement rates or is sending actual costs to a job then the rate overrides for the customer and service site are ignored.
				CASE WHEN NOT (DeriveWorkOrderType.IsPreventiveMaintenance = 1 OR DeriveWorkOrderType.UseAgreementRates = 1 OR IsQuoteGenerated = 1) THEN SMServiceSiteEntity.EntitySeq END SMServiceSiteEntitySeq,
				CASE WHEN NOT (DeriveWorkOrderType.IsPreventiveMaintenance = 1 OR DeriveWorkOrderType.UseAgreementRates = 1 OR IsQuoteGenerated = 1) THEN SMCustomerEntity.EntitySeq END SMCustomerEntitySeq,
				SMWOQuoteScopeEntity.EntitySeq SMWOQuoteScopeEntitySeq,
				RateTemplateSetup.*
			FROM
			(
				SELECT vSMRateTemplateEffectiveDate.EffectiveDate, vSMRateTemplateEffectiveDate.LaborRate, vSMRateTemplateEffectiveDate.EquipmentMarkup, vSMRateTemplateEffectiveDate.MaterialMarkupOrDiscount, vSMRateTemplateEffectiveDate.MaterialBasis, vSMRateTemplateEffectiveDate.MaterialPercent, SMRateTemplateEffectiveDateEntity.EntitySeq SMRateTemplateEntitySeq, 2 RateSource
				FROM dbo.vSMRateTemplateEffectiveDate
					LEFT JOIN dbo.vSMEntity SMRateTemplateEffectiveDateEntity ON vSMRateTemplateEffectiveDate.SMCo = SMRateTemplateEffectiveDateEntity.SMCo AND vSMRateTemplateEffectiveDate.RateTemplate = SMRateTemplateEffectiveDateEntity.RateTemplate AND vSMRateTemplateEffectiveDate.EffectiveDate = SMRateTemplateEffectiveDateEntity.EffectiveDate
				WHERE vSMRateTemplate.SMCo = vSMRateTemplateEffectiveDate.SMCo AND vSMRateTemplate.RateTemplate = vSMRateTemplateEffectiveDate.RateTemplate AND vSMRateTemplateEffectiveDate.EffectiveDate <= @Date
				
				UNION ALL
				
				--A record should always be returned here so that even if there is no rate template the service site and customer RateOverrideIDs are returned.
				SELECT NULL AS EffectiveDate, vSMRateTemplate.LaborRate, vSMRateTemplate.EquipmentMarkup, vSMRateTemplate.MaterialMarkupOrDiscount, vSMRateTemplate.MaterialBasis, vSMRateTemplate.MaterialPercent, SMRateTemplateEntity.EntitySeq, 1 RateSource
			) RateTemplateSetup
			--If the work completed is covered under an agreement then the billable rate should be 0 so null values areturned that way the functions using this function
			--don't accidently return a rate other than 0. For job work orders the billable rate should be the same as the cost rate(except for standard charges).
			WHERE DeriveWorkOrderType.IsCoveredUnderAgreement = 0 AND DeriveWorkOrderType.IsActualCostJobWorkOrder = 0
			ORDER BY EffectiveDate DESC
		) BillableRateSetup
	WHERE vSMWorkOrderScope.SMCo = @SMCo AND vSMWorkOrderScope.WorkOrder = @WorkOrder AND vSMWorkOrderScope.Scope = @Scope

)
GO

GRANT SELECT ON  [dbo].[vfSMGetBillableRateSetup] TO [public]
GO
