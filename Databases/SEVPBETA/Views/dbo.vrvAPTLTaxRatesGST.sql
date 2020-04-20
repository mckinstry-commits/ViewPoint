SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE View   
  
[dbo].[vrvAPTLTaxRatesGST]  
  
/**********************************************************
* Copyright © 2013 Viewpoint Construction Software. All rights reserved.
* Created:  HH 2/16/2011 #142603
* Modified: 
* 
* Reports:  PO DrillDown
* 
* Purpose:  
* View returns AP/PO Items linked to GST-HQTaxCodes.  Multiply the CurCost by the tax rates to calculate   
* tax amounts for both multilevel and non-multilevel tax codes  
* 
*******************************************************************/
--  
AS  
  
With GST   
  
AS  
  
(SELECT   m.TaxGroup AS TaxGroup   
  , m.TaxCode AS MainTaxCode  
  , l.TaxLink AS GSTTaxCode  
  , lx.OldRate AS GSTTaxOldRate  
  , lx.NewRate AS GSTTaxNewRate  
  , lx.EffectiveDate AS GSTEffectiveDate  
FROM HQTX m  
JOIN HQTL l ON  l.TaxGroup = m.TaxGroup AND l.TaxCode = m.TaxCode  
JOIN HQTX lx ON lx.TaxGroup = m.TaxGroup AND l.TaxLink = lx.TaxCode  
WHERE lx.GST = 'Y')  
  
,TaxCode  
  
AS  
  
(SELECT   m.TaxGroup AS TaxGroup   
  , m.TaxCode AS MainTaxCode  
  , m.Description AS MainTaxCodeDesc  
  , m.MultiLevel 
  , l.TaxLink AS SubTaxCode  
  , lx.Description SubTaxCodeDesc  
  , m.OldRate AS MainTaxOldRate  
  , m.NewRate AS MainTaxNewRate  
  , m.EffectiveDate AS MainTaxEffectiveDate  
  , lx.OldRate AS SubCodeTaxOldRate  
  , lx.NewRate AS SubCodeTaxNewRate  
  , lx.EffectiveDate AS SubCodeEffectiveDate  
  , lx.GST  
  , lx.InclGSTinPST  
FROM HQTX m  
LEFT JOIN HQTL l ON l.TaxGroup = m.TaxGroup AND l.TaxCode = m.TaxCode  
LEFT JOIN HQTX lx ON lx.TaxGroup = m.TaxGroup AND l.TaxLink = lx.TaxCode  
)  
  
SELECT
  	A.APCo
  , APTH.Mth AS OrderDate
  , A.APTrans
  , A.APLine
  , A.PO
  , A.GrossAmt
  , g.GSTTaxCode
  , g.GSTTaxOldRate   
  , g.GSTTaxNewRate  
  , g.GSTEffectiveDate
             
FROM APTL AS A
INNER JOIN GST g  
ON  g.TaxGroup = A.TaxGroup  
AND g.MainTaxCode = A.TaxCode  
   
INNER JOIN APTH
ON A.APCo = APTH.APCo
AND A.Mth = APTH.Mth
AND A.APTrans = APTH.APTrans



GO
GRANT SELECT ON  [dbo].[vrvAPTLTaxRatesGST] TO [public]
GRANT INSERT ON  [dbo].[vrvAPTLTaxRatesGST] TO [public]
GRANT DELETE ON  [dbo].[vrvAPTLTaxRatesGST] TO [public]
GRANT UPDATE ON  [dbo].[vrvAPTLTaxRatesGST] TO [public]
GO
