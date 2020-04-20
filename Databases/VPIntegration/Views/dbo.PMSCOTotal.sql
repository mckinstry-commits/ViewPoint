SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






/****************************/
CREATE view [dbo].[PMSCOTotal] as
/*****************************
* Created By:	GF 03/11/2011 TK-02577
* Modified By:	GF 04/15/2011 TK-04281
*				GF 11/23/2011 TK-10291 exclude VAT tax type
*				GPT/NH 09/06/12 TK-17499 Sum the PMSL Original Amount in the SL Total Original Amount.
*
* Displays SCO Totals (PMSubcontractCO), Original (SLIT), Current (SLCD, SLIT, PMSL),
* and Tax SL amounts in PMSubcontractCO (PMSL)
*
********************************/

SELECT TOP 100 PERCENT
		b.KeyID AS SCOKeyID,
		a.KeyID AS SLKeyID,
		b.SLCo,
		b.SL,
		b.SubCO,
        
		CAST(ISNULL(SUM(SLTOTAL.SLTotalOrig), 0) + ISNULL(SUM(SLTOTAL.SLTotalOrigTax), 0) + ISNULL(SUM(PMSL.PMSLOriginalAmt), 0) 	AS NUMERIC(18,2)) AS SLTotalOriginal,
		CAST(ISNULL(SUM(SLTOTAL.SLTotalOrigTax), 0)		AS NUMERIC(18,2)) AS SLTotalOrigTax,
		
		CAST(ISNULL(SUM(SLPRIOR.SLPriorAmt), 0) + ISNULL(SUM(SLPRIOR.SLPriorTaxAmt), 0)		AS NUMERIC(18,2)) AS SLAmtPrior,
		CAST(ISNULL(SUM(SLPRIOR.SLPriorTaxAmt), 0)	AS NUMERIC(18,2))	AS SLTaxPrior,
		
		---- THE pm VALUES ARE RETRIEVED FROM A TABLE FUNCTION THAT RETURNS CURRENT SCO,
		---- PREVIOUS APPROVED CHANGE ORDERS, AND PENDING CHANGE ORDERS
		CAST(ISNULL(SUM(PMSL.PMSLCurrentAmt), 0)	AS NUMERIC(18,2))	AS PMSLAmtCurrent,
		CAST(ISNULL(SUM(PMSL.PMSLCurrentTaxAmt), 0)	AS NUMERIC(18,2))	AS PMSLTaxCurrent,
		CAST(ISNULL(SUM(PMSL.PMSLPrevApprAmt), 0)		AS NUMERIC(18,2)) AS PMSLAmtPrior,
		CAST(ISNULL(SUM(PMSL.PMSLPrevApprTaxAmt), 0)	AS NUMERIC(18,2)) AS PMSLTaxPrior,
		CAST(ISNULL(SUM(PMSL.PMSLPendingAmt), 0)		AS NUMERIC(18,2)) AS PMSLAmtPriorPending,
		CAST(ISNULL(SUM(PMSL.PMSLPendingTaxAmt),0)		AS NUMERIC(18,2)) AS PMSLTaxPriorPending,
		
		CAST(ISNULL(SUM(SLPRIOR.SLPriorAmt), 0) + ISNULL(SUM(SLPRIOR.SLPriorTaxAmt), 0) + ISNULL(SUM(PMSL.PMSLPrevApprAmt), 0) AS NUMERIC(18,2)) AS SubCOPrevious
				
FROM dbo.PMSubcontractCO b
JOIN dbo.bSLHD a ON a.SLCo=b.SLCo AND a.SL=b.SL
				
	---- SL SUBCONTRACT AMOUNTS
    OUTER APPLY (SELECT  SLTotalOrig    = ISNULL(SUM(CASE WHEN e.ItemType IN (1,4) THEN e.OrigCost ELSE 0 END), 0),
						 ----TK-10291
                         SLTotalOrigTax = ISNULL(SUM(CASE WHEN e.ItemType IN (1,4) AND e.TaxType = 1 THEN e.OrigTax ELSE 0 END) , 0)
                  FROM   dbo.bSLIT e
                  WHERE  e.SLCo = a.SLCo
                         AND e.SL = a.SL
                         AND e.ItemType <> 3
                  GROUP BY  e.SLCo,
                            e.SL
                ) SLTOTAL

	---- SL PRIOR CHANGE AMOUNTS
    OUTER APPLY ( SELECT SLPriorAmt    = ISNULL(SUM(f.ChangeCurCost), 0),
						 ----TK-10291
						 SLPriorTaxAmt = ISNULL(SUM(CASE WHEN g.TaxType = 1 THEN f.ChgToTax ELSE 0 END), 0)
                  FROM   dbo.bSLCD f
                  INNER JOIN dbo.bSLIT g ON g.SLCo=f.SLCo AND g.SL=f.SL AND g.SLItem=f.SLItem
                  WHERE  f.SLCo = a.SLCo
                         AND f.SL = a.SL
                         AND f.SLChangeOrder IS NOT NULL
                         AND f.SLChangeOrder < b.SubCO
                  GROUP BY  f.SLCo,
                            f.SL
                ) SLPRIOR


	----- TABLE FUNCTION APPLIED FOR PM SUCONTRACT CHANGE AMOUNTS
	CROSS APPLY dbo.vfPMSLSubcontractCOAmounts(b.SLCo, b.SL, b.SubCO) PMSL



GROUP BY  b.SLCo,
          b.SL,
          b.SubCO,
          b.KeyID,
          a.KeyID
          
ORDER BY  b.SLCo, b.SL, b.SubCO





















GO
GRANT SELECT ON  [dbo].[PMSCOTotal] TO [public]
GRANT INSERT ON  [dbo].[PMSCOTotal] TO [public]
GRANT DELETE ON  [dbo].[PMSCOTotal] TO [public]
GRANT UPDATE ON  [dbo].[PMSCOTotal] TO [public]
GO
