SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/****************************/
CREATE view [dbo].[vrvPMPOCOTotal] as
/*****************************
* Created By:	HH 06/28/2011 TK-03970
* Modified By:	
*				
*
* Modificated PMPOCOTotal displays POCO Current (POCD, POIT, PMMF),
* and Tax PO amounts in PMPOCO 
*
********************************/

SELECT TOP 100 PERCENT
		b.KeyID AS POCOKeyID,
		a.KeyID AS POKeyID,
		b.POCo,
		b.PO,
		b.POCONum,
        
		---- THE pm VALUES ARE RETRIEVED FROM A TABLE FUNCTION THAT RETURNS CURRENT POCO,
		---- PREVIOUS APPROVED CHANGE ORDERS, AND PENDING CHANGE ORDERS
		CAST(ISNULL(SUM(PMMF.PMMFCurrentAmt), 0)	AS NUMERIC(18,2))	AS PMMFAmtCurrent,
		CAST(ISNULL(SUM(PMMF.PMMFCurrentTaxAmt), 0)	AS NUMERIC(18,2))	AS PMMFTaxCurrent
				
FROM dbo.PMPOCO b
JOIN dbo.bPOHD a ON a.POCo=b.POCo AND a.PO=b.PO
				
----- TABLE FUNCTION APPLIED FOR PM PO CHANGE AMOUNTS
CROSS APPLY dbo.vf_rptPMMFPOCOAmounts(b.POCo, b.PO, b.POCONum) PMMF

GROUP BY  b.POCo,
          b.PO,
          b.POCONum,
          b.KeyID,
          a.KeyID
          
ORDER BY  b.POCo, b.PO, b.POCONum

























GO
GRANT SELECT ON  [dbo].[vrvPMPOCOTotal] TO [public]
GRANT INSERT ON  [dbo].[vrvPMPOCOTotal] TO [public]
GRANT DELETE ON  [dbo].[vrvPMPOCOTotal] TO [public]
GRANT UPDATE ON  [dbo].[vrvPMPOCOTotal] TO [public]
GRANT SELECT ON  [dbo].[vrvPMPOCOTotal] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvPMPOCOTotal] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvPMPOCOTotal] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvPMPOCOTotal] TO [Viewpoint]
GO
