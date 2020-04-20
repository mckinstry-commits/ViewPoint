SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO











/****************************/
CREATE view [dbo].[PMPOCO_DetailLine_Total] as
/*****************************
* Created By:	GF 04/09/2011 TK-04046 TK-04281
* Modified By:	GF 11/23/2011 TK-10291
*
* Displays the PMPOCO Amount + Calculated Tax Amount for use in
* PM Purchase Change Order Templates.
*
********************************/

SELECT	a.KeyID,
		CAST(ISNULL(a.Amount,0) + 
			CASE WHEN a.TaxCode IS NULL THEN 0
				 ----TK-10291
				 WHEN a.TaxType IN (2,3) THEN 0
			ELSE ISNULL(ROUND(ISNULL(SUM(a.Amount), 0) * ISNULL(dbo.vfHQTaxRate(a.TaxGroup, a.TaxCode, GetDate()),0),2),0)
			END AS NUMERIC(18,2)) AS TotalAmount,
			
		CAST(CASE WHEN a.TaxCode IS NULL THEN 0
				  ----TK-10291
				  WHEN a.TaxType IN (2,3) THEN 0
			ELSE ISNULL(ROUND(ISNULL(SUM(a.Amount), 0) * ISNULL(dbo.vfHQTaxRate(a.TaxGroup, a.TaxCode, GetDate()),0),2),0)
			END AS NUMERIC(18,2)) AS TaxAmount	
FROM dbo.PMMF a

GROUP BY a.KeyID,
		 a.Amount,
		 a.TaxGroup,
		 a.TaxCode,
		 a.TaxType		
          









GO
GRANT SELECT ON  [dbo].[PMPOCO_DetailLine_Total] TO [public]
GRANT INSERT ON  [dbo].[PMPOCO_DetailLine_Total] TO [public]
GRANT DELETE ON  [dbo].[PMPOCO_DetailLine_Total] TO [public]
GRANT UPDATE ON  [dbo].[PMPOCO_DetailLine_Total] TO [public]
GRANT SELECT ON  [dbo].[PMPOCO_DetailLine_Total] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMPOCO_DetailLine_Total] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMPOCO_DetailLine_Total] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMPOCO_DetailLine_Total] TO [Viewpoint]
GO
