SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****************************/
CREATE view [dbo].[vrvPMPOCO_DetailLine_Total] as
/*****************************
* Created By:	HH 07/15/2013 TFS 54592
* Modified By:	
*
* Displays the PMPOCO Amount + Calculated Tax Amount for use in PM Purchase Order Change Order report 
* just like PMPOCO_DetailLine_Total but without TaxCode 2,3 distinction
*
********************************/

SELECT	a.KeyID,
		CAST(ISNULL(a.Amount,0) + 
			CASE 
				WHEN a.TaxCode IS NULL THEN 0
				ELSE ISNULL(ROUND(ISNULL(SUM(a.Amount), 0) * ISNULL(dbo.vfHQTaxRate(a.TaxGroup, a.TaxCode, GetDate()),0),2),0)
			END AS NUMERIC(18,2)) AS TotalAmount,
			
		CAST(CASE 
				WHEN a.TaxCode IS NULL THEN 0
				ELSE ISNULL(ROUND(ISNULL(SUM(a.Amount), 0) * ISNULL(dbo.vfHQTaxRate(a.TaxGroup, a.TaxCode, GetDate()),0),2),0)
			END AS NUMERIC(18,2)) AS TaxAmount	
FROM dbo.PMMF a

GROUP BY a.KeyID,
		 a.Amount,
		 a.TaxGroup,
		 a.TaxCode,
		 a.TaxType		

GO
GRANT SELECT ON  [dbo].[vrvPMPOCO_DetailLine_Total] TO [public]
GRANT INSERT ON  [dbo].[vrvPMPOCO_DetailLine_Total] TO [public]
GRANT DELETE ON  [dbo].[vrvPMPOCO_DetailLine_Total] TO [public]
GRANT UPDATE ON  [dbo].[vrvPMPOCO_DetailLine_Total] TO [public]
GRANT SELECT ON  [dbo].[vrvPMPOCO_DetailLine_Total] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvPMPOCO_DetailLine_Total] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvPMPOCO_DetailLine_Total] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvPMPOCO_DetailLine_Total] TO [Viewpoint]
GO
