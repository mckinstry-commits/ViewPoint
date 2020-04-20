SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/****************************/
CREATE view [dbo].[vrvPMSCOTotal] as
/*****************************
* Created By:	HH 06/28/2011 TK-05764
*				
*
* Modificated dbo.PMSCOTotal that displays CurrentAmt and CurrentTaxAmt 
* only in PMSubcontractCO (PMSL)
*
********************************/

SELECT TOP 100 PERCENT
		b.KeyID AS SCOKeyID,
		a.KeyID AS SLKeyID,
		b.SLCo,
		b.SL,
		b.SubCO,
        
		---- THE pm VALUES ARE RETRIEVED FROM A TABLE FUNCTION THAT RETURNS CURRENT SCO,
		CAST(ISNULL(SUM(PMSL.PMSLCurrentAmt), 0)	AS NUMERIC(18,2))	AS PMSLAmtCurrent,
		CAST(ISNULL(SUM(PMSL.PMSLCurrentTaxAmt), 0)	AS NUMERIC(18,2))	AS PMSLTaxCurrent

FROM dbo.PMSubcontractCO b
JOIN dbo.bSLHD a ON a.SLCo=b.SLCo AND a.SL=b.SL

----- TABLE FUNCTION APPLIED FOR PM SUCONTRACT CHANGE AMOUNTS
CROSS APPLY dbo.vf_rptPMSLSubcontractCOAmounts(b.SLCo, b.SL, b.SubCO) PMSL

GROUP BY  b.SLCo,
          b.SL,
          b.SubCO,
          b.KeyID,
          a.KeyID
          
ORDER BY  b.SLCo, b.SL, b.SubCO





















GO
GRANT SELECT ON  [dbo].[vrvPMSCOTotal] TO [public]
GRANT INSERT ON  [dbo].[vrvPMSCOTotal] TO [public]
GRANT DELETE ON  [dbo].[vrvPMSCOTotal] TO [public]
GRANT UPDATE ON  [dbo].[vrvPMSCOTotal] TO [public]
GRANT SELECT ON  [dbo].[vrvPMSCOTotal] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvPMSCOTotal] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvPMSCOTotal] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvPMSCOTotal] TO [Viewpoint]
GO
