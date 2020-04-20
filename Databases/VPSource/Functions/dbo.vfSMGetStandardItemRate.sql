
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Lane Gresham
-- Create date: 07/12/11
-- Description:	Get Standard Item Rate for Rate Override.
-- Modified:	TL 04/04/2012 TK-13744  Added Code to override Billable Rate based on WorkOrder CostMethod
--				Jacob VH	2/6/13 TFS-39301 Modified to work with changes made to support company copy on rate overrides
--				EricV  05/31/13 TFS-4171 Replaced Work Completed Coverage field with NonBillable and UseAgreementRates fields
-- =============================================
CREATE FUNCTION [dbo].[vfSMGetStandardItemRate]
(	
	@SMCo bCompany, @WorkOrder int, @Scope int, @Date bDate, @StandardItem varchar(20), @Agreement varchar(15), @Revision int, @NonBillable bYN, @UseAgreementRates bYN
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT
		CASE
			--Work Completed covered under the agreement should always return an empty billable rate
			WHEN vfSMGetBillableRateSetup.IsCoveredUnderAgreement = 1 THEN NULL
			--If the work order is sending actual cost to the job then
			WHEN vfSMGetBillableRateSetup.IsActualCostJobWorkOrder = 1 THEN
				CASE
					--the billable rate should be returned for standard charges
					WHEN ISNULL(vSMStandardItem.CostRate, 0) = 0
						THEN ISNULL(
							(
								SELECT vSMRateOverrideStandardItem.BillableRate
								FROM dbo.vSMWorkOrder 
									INNER JOIN dbo.vSMServiceSite ON vSMWorkOrder.SMCo = vSMServiceSite.SMCo AND vSMWorkOrder.ServiceSite = vSMServiceSite.ServiceSite
									INNER JOIN dbo.vSMEntity ON vSMServiceSite.SMCo = vSMEntity.SMCo AND vSMServiceSite.ServiceSite = vSMEntity.ServiceSite
									INNER JOIN dbo.vSMRateOverrideStandardItem ON vSMEntity.SMCo = vSMRateOverrideStandardItem.SMCo AND vSMEntity.EntitySeq = vSMRateOverrideStandardItem.EntitySeq AND vSMRateOverrideStandardItem.StandardItem = @StandardItem
								WHERE vSMWorkOrder.SMCo = @SMCo AND vSMWorkOrder.WorkOrder = @WorkOrder
							),
							vSMStandardItem.BillableRate)
					--the billable rate should be nothing for standard costs
					WHEN ISNULL(vSMStandardItem.BillableRate, 0) = 0 THEN NULL
					--the billable rate should be the cost rate for standard items
					ELSE vSMStandardItem.CostRate
				END
			ELSE DeriveBillableRate.BillableRate
		END BillableRate,
		DeriveBillableRate.RateSource,
		vfSMGetBillableRateSetup.RateTemplate,
		vfSMGetBillableRateSetup.RateSource RateTemplateSource
	--vfSMGetBillableRateSetup should always return record as long as the scope exits
	FROM dbo.vfSMGetBillableRateSetup(@SMCo, @WorkOrder, @Scope, @Date, @Agreement, @Revision, @NonBillable, @UseAgreementRates)
		LEFT JOIN dbo.vSMStandardItem ON SMCo = @SMCo AND StandardItem = @StandardItem
		OUTER APPLY
		(
			SELECT TOP 1 *
			FROM
			(
				--Quote Override Rate
				SELECT 5 RateSource, BillableRate
				FROM dbo.vSMRateOverrideStandardItem
				--vfSMGetBillableRateSetup.SMServiceSiteEntitySeq will be null if the work order was generated from an agreement
				WHERE SMCo = @SMCo AND EntitySeq = vfSMGetBillableRateSetup.SMWOQuoteScopeEntitySeq AND StandardItem = @StandardItem
				
				UNION ALL

				--Service Site Override Rate
				SELECT 4 RateSource, BillableRate
				FROM dbo.vSMRateOverrideStandardItem
				--vfSMGetBillableRateSetup.SMServiceSiteEntitySeq will be null if the work order was generated from an agreement
				WHERE SMCo = @SMCo AND EntitySeq = vfSMGetBillableRateSetup.SMServiceSiteEntitySeq AND StandardItem = @StandardItem
				
				UNION ALL
				
				--Customer Override Rate
				SELECT 3 RateSource, BillableRate
				FROM dbo.vSMRateOverrideStandardItem
				--vfSMGetBillableRateSetup.SMCustomerEntitySeq will be null if the work order was generated from an agreement
				WHERE SMCo = @SMCo AND EntitySeq = vfSMGetBillableRateSetup.SMCustomerEntitySeq AND StandardItem = @StandardItem
				
				UNION ALL

				--RateTemplate or RateTemplate Effective Dates Override Rate
				SELECT 2 RateSource, BillableRate
				FROM dbo.vSMRateOverrideStandardItem
				WHERE SMCo = @SMCo AND EntitySeq = vfSMGetBillableRateSetup.SMRateTemplateEntitySeq AND StandardItem = @StandardItem
				
				UNION ALL

				--StandardItem fallback rate
				SELECT 1 RateSource, ISNULL(vSMStandardItem.BillableRate, 0) BillableRate
			) GetRates
			WHERE GetRates.BillableRate IS NOT NULL
			ORDER BY GetRates.RateSource DESC
		) DeriveBillableRate
)
GO

GRANT SELECT ON  [dbo].[vfSMGetStandardItemRate] TO [public]
GO
