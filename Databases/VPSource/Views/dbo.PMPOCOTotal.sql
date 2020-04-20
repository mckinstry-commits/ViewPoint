SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




/****************************/
CREATE view [dbo].[PMPOCOTotal] as
/*****************************
* Created By:	TRL 04/07/2011 TK-03970
* Modified By:	GF 04/15/2011 TK-04281
*				DH 04/18/2011 TK-04088 --Changed comparison of prior amounts to POCD.POCONum from ChangeOrder
*										  in PO Prior Change Amounts section
*				GF 11/23/2011 TK-10291 exclude VAT tax type
*				GF 02/04/2012 TK-12292 change to use POCD.ChgTotCost
*				GF 04/09/2012 TK-13886 #145504 get PMMF original amount and tax for inclusion on totals
*
*
* Displays POCO Totals (PMPOCO), Original (POIT), Current (POCD, POIT, PMMF),
* and Tax PO amounts in PMPOCO 
*
********************************/

SELECT TOP 100 PERCENT
		b.KeyID AS POCOKeyID,
		a.KeyID AS POKeyID,
		b.POCo,
		b.PO,
		b.POCONum,
        
        ----TK-13886
		CAST(ISNULL(SUM(POTOTAL.POTotalOrig), 0) + ISNULL(SUM(POTOTAL.POTotalOrigTax), 0) + ISNULL(SUM(PMMF.PMMFOriginalAmt),0) + ISNULL(SUM(PMMF.PMMFOriginalTaxAmt),0) AS NUMERIC(18,2)) AS POTotalOriginal,
		CAST(ISNULL(SUM(POTOTAL.POTotalOrigTax), 0) + ISNULL(SUM(PMMF.PMMFOriginalTaxAmt),0) 	AS NUMERIC(18,2)) AS POTotalOrigTax,
		
		CAST(ISNULL(SUM(POPRIOR.POPriorAmt), 0) + ISNULL(SUM(POPRIOR.POPriorTaxAmt), 0)		AS NUMERIC(18,2)) AS POAmtPrior,
		CAST(ISNULL(SUM(POPRIOR.POPriorTaxAmt), 0)	AS NUMERIC(18,2))	AS POTaxPrior,
		
		---- THE pm VALUES ARE RETRIEVED FROM A TABLE FUNCTION THAT RETURNS CURRENT POCO,
		---- PREVIOUS APPROVED CHANGE ORDERS, AND PENDING CHANGE ORDERS
		CAST(ISNULL(SUM(PMMF.PMMFCurrentAmt), 0)	AS NUMERIC(18,2))	AS PMMFAmtCurrent,
		CAST(ISNULL(SUM(PMMF.PMMFCurrentTaxAmt), 0)	AS NUMERIC(18,2))	AS PMMFTaxCurrent,
		CAST(ISNULL(SUM(PMMF.PMMFPrevApprAmt), 0)		AS NUMERIC(18,2)) AS PMMFAmtPrior,
		CAST(ISNULL(SUM(PMMF.PMMFPrevApprTaxAmt), 0)	AS NUMERIC(18,2)) AS PMMFTaxPrior,
		CAST(ISNULL(SUM(PMMF.PMMFPendingAmt), 0)		AS NUMERIC(18,2)) AS PMMFAmtPriorPending,
		CAST(ISNULL(SUM(PMMF.PMMFPendingTaxAmt),0)		AS NUMERIC(18,2)) AS PMMFTaxPriorPending,
		
		CAST(ISNULL(SUM(POPRIOR.POPriorAmt), 0) + ISNULL(SUM(POPRIOR.POPriorTaxAmt), 0) + ISNULL(SUM(PMMF.PMMFPrevApprAmt), 0) AS NUMERIC(18,2)) AS POCONumPrevious
				
FROM dbo.PMPOCO b
JOIN dbo.bPOHD a ON a.POCo=b.POCo AND a.PO=b.PO
				
	---- PO PO AMOUNTS
    OUTER APPLY (SELECT  POTotalOrig    = ISNULL(SUM(CASE WHEN e.ItemType = 1 THEN e.OrigCost ELSE 0 END), 0),
						 ----TK-10291
                         POTotalOrigTax = ISNULL(SUM(CASE WHEN e.ItemType = 1 AND e.TaxType = 1 THEN e.OrigTax ELSE 0 END) , 0)
                  FROM   dbo.bPOIT e
                  WHERE  e.POCo = a.POCo
                         AND e.PO = a.PO
                         AND e.ItemType = 1
                  GROUP BY  e.POCo,
                            e.PO
                ) POTOTAL

	---- PO PRIOR CHANGE AMOUNTS
	---- TK-12292
    OUTER APPLY ( SELECT POPriorAmt    = ISNULL(SUM(f.ChgTotCost), 0),
						 ----TK-10291
						 POPriorTaxAmt = ISNULL(SUM(CASE WHEN g.TaxType = 1 THEN f.ChgToTax ELSE 0 END), 0)
                  FROM   dbo.bPOCD f
                  INNER JOIN dbo.bPOIT g ON g.POCo=f.POCo AND g.PO=f.PO AND g.POItem=f.POItem
                  WHERE  f.POCo = a.POCo
                         AND f.PO = a.PO
                         AND f.POCONum IS NOT NULL
                         AND f.POCONum < b.POCONum
                  GROUP BY  f.POCo,
                            f.PO
                ) POPRIOR


	----- TABLE FUNCTION APPLIED FOR PM PO CHANGE AMOUNTS
	CROSS APPLY dbo.vfPMMFPOCOAmounts(b.POCo, b.PO, b.POCONum) PMMF


GROUP BY  b.POCo,
          b.PO,
          b.POCONum,
          b.KeyID,
          a.KeyID
          
ORDER BY  b.POCo, b.PO, b.POCONum

































GO
GRANT SELECT ON  [dbo].[PMPOCOTotal] TO [public]
GRANT INSERT ON  [dbo].[PMPOCOTotal] TO [public]
GRANT DELETE ON  [dbo].[PMPOCOTotal] TO [public]
GRANT UPDATE ON  [dbo].[PMPOCOTotal] TO [public]
GO
