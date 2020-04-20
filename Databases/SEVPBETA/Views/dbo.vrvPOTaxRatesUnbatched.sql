SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE View   
  
[dbo].[vrvPOTaxRatesUnbatched]  
  
/***  
 Created:  huyh 7/27/2010 
 Modified: 
   
 Reports:  PO Purchase Order Form by Batch 
   
 View returns POIB (unbatched PO Items) linked to HQTaxCodes.  Multiply the CurCost by the tax rates to calculate   
 tax amounts for both multilevel and non-multilevel tax codes  
   
 ****/  
--  
AS  
  
WITH GST   
  
AS  
  
(SELECT	  m.TaxGroup AS TaxGroup   
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
  
(SELECT   m.TaxGroup as TaxGroup   
		, m.TaxCode as MainTaxCode  
	  , m.Description as MainTaxCodeDesc  
	  , m.MultiLevel 
	  , l.TaxLink as SubTaxCode  
	  , lx.Description SubTaxCodeDesc  
	  , m.OldRate as MainTaxOldRate  
	  , m.NewRate as MainTaxNewRate  
	  , m.EffectiveDate as MainTaxEffectiveDate  
	  , lx.OldRate as SubCodeTaxOldRate  
	  , lx.NewRate as SubCodeTaxNewRate  
	  , lx.EffectiveDate as SubCodeEffectiveDate  
	  , lx.GST  
	  , lx.InclGSTinPST  
FROM HQTX m  
	LEFT JOIN HQTL l on  l.TaxGroup = m.TaxGroup AND l.TaxCode = m.TaxCode  
	LEFT JOIN HQTX lx on lx.TaxGroup = m.TaxGroup AND l.TaxLink = lx.TaxCode  
)  
  
SELECT	  POIB.Co AS POCo
		, POHB.PO  
		, POIB.POItem  
		, POIB.OrigCost AS CurCost
		, POIB.TaxCode 
		, POIB.TaxType 
		, POIB.OrigCost AS TotalCost
		, POIB.OrigTax AS TotalTax
		, POHB.OrderDate
		, t.MultiLevel
		, isnull(t.MainTaxEffectiveDate, t.SubCodeEffectiveDate) AS TaxEffectiveDate  
		, t.SubTaxCode  
		, isnull(t.MainTaxOldRate,t.SubCodeTaxOldRate) AS TaxOldRate  
		, isnull(t.MainTaxNewRate,t.SubCodeTaxNewRate) AS TaxNewRate  
		, t.GST  
		, t.InclGSTinPST  
		, g.GSTTaxOldRate   
		, g.GSTTaxNewRate  
		, g.GSTEffectiveDate
             
    
FROM POIB

INNER JOIN POHB  
      on  POHB.Co = POIB.Co
      AND POHB.Mth = POIB.Mth
      AND POHB.BatchId = POIB.BatchId
      AND POHB.BatchSeq = POIB.BatchSeq 

LEFT JOIN GST g  
  on  g.TaxGroup = POIB.TaxGroup  
  AND g.MainTaxCode = POIB.TaxCode  
   
JOIN TaxCode t  
 on  t.TaxGroup = POIB.TaxGroup  
 and t.MainTaxCode = POIB.TaxCode




GO
GRANT SELECT ON  [dbo].[vrvPOTaxRatesUnbatched] TO [public]
GRANT INSERT ON  [dbo].[vrvPOTaxRatesUnbatched] TO [public]
GRANT DELETE ON  [dbo].[vrvPOTaxRatesUnbatched] TO [public]
GRANT UPDATE ON  [dbo].[vrvPOTaxRatesUnbatched] TO [public]
GO
