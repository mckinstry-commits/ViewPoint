SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO








/****************************/
CREATE view [dbo].[PMSCO_DetailLine_Total] as
/*****************************
* Created By:	GF 03/18/2011 TK-02604 TK-04281
*				added tax amount like the POCO view has.
*				GF 11/23/2011 TK-10291
* Modified By:
*
* Displays the PMSL Amount + Calculated Tax Amount for use in
* PM Subcontract Change Order Templates.
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
			
FROM dbo.PMSL a

GROUP BY a.KeyID,
		 a.Amount,
		 a.TaxGroup,
		 a.TaxCode,
		 a.TaxType		
          






GO
GRANT SELECT ON  [dbo].[PMSCO_DetailLine_Total] TO [public]
GRANT INSERT ON  [dbo].[PMSCO_DetailLine_Total] TO [public]
GRANT DELETE ON  [dbo].[PMSCO_DetailLine_Total] TO [public]
GRANT UPDATE ON  [dbo].[PMSCO_DetailLine_Total] TO [public]
GO
