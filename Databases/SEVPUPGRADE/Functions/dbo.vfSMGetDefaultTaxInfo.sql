SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 2/6/12
-- Description:	Returns the tax group and default tax code if available for a work order scope
-- =============================================
CREATE FUNCTION [dbo].[vfSMGetDefaultTaxInfo]
(	
	@SMCo bCompany, @WorkOrder int, @Scope int
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT TaxInfo.*
	FROM dbo.vSMWorkOrderScope	
			INNER JOIN dbo.vSMCO ON vSMWorkOrderScope.SMCo = vSMCO.SMCo
			INNER JOIN dbo.bHQCO ON vSMCO.ARCo = bHQCO.HQCo
			INNER JOIN dbo.vSMWorkOrder ON vSMWorkOrderScope.SMCo = vSMWorkOrder.SMCo AND vSMWorkOrderScope.WorkOrder = vSMWorkOrder.WorkOrder
			OUTER APPLY (
				SELECT TOP 1
					DefaultTaxCode.TaxGroup,
					CASE WHEN DefaultTaxCode.TaxCode IS NULL THEN NULL WHEN bHQCO.DefaultCountry IN ('AU','CA') THEN 3 ELSE 1 END TaxType,
					DefaultTaxCode.TaxCode
				FROM
				(
					SELECT vSMServiceCenter.TaxGroup, vSMServiceCenter.TaxCode, 1 Ranking
					FROM dbo.vSMServiceCenter
					WHERE vSMWorkOrderScope.SaleLocation = 0 AND vSMWorkOrder.SMCo = vSMServiceCenter.SMCo AND vSMWorkOrder.ServiceCenter = vSMServiceCenter.ServiceCenter AND vSMServiceCenter.TaxCode IS NOT NULL
					UNION ALL
					SELECT vSMServiceSite.TaxGroup, vSMServiceSite.TaxCode, 2 Ranking
					FROM dbo.vSMServiceSite
					WHERE vSMWorkOrderScope.SaleLocation = 1 AND vSMWorkOrder.SMCo = vSMServiceSite.SMCo AND vSMWorkOrder.ServiceSite = vSMServiceSite.ServiceSite AND vSMServiceSite.TaxCode IS NOT NULL
					UNION ALL
					SELECT bHQCO.TaxGroup, NULL TaxCode, 3 Ranking
				) DefaultTaxCode
				WHERE vSMWorkOrder.Job IS NULL
				ORDER BY DefaultTaxCode.Ranking
			) TaxInfo
	WHERE vSMWorkOrderScope.SMCo = @SMCo AND vSMWorkOrderScope.WorkOrder = @WorkOrder AND vSMWorkOrderScope.Scope = @Scope 
)
GO
GRANT SELECT ON  [dbo].[vfSMGetDefaultTaxInfo] TO [public]
GO
