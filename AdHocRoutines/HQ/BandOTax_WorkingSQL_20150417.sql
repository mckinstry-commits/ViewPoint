--SELECT ARTL.ARCo, HQCO.Name, TaxCode, ARTL.ARTrans, ARTL.Mth, sum(TaxBasis), sum(TaxAmount), sum(DiscOffered), sum(TaxDisc), sum(Amount), ARTL.Contract, ARTL.TaxGroup, ARTL.Item
--      		FROM ARTL  WITH (NOLOCK) 
--      		JOIN ARTH  WITH (NOLOCK) on ARTH.ARCo=ARTL.ARCo and ARTH.Mth=ARTL.Mth and ARTH.ARTrans=ARTL.ARTrans
--      		JOIN bHQCO HQCO WITH (NOLOCK) on HQCO.HQCo=ARTL.ARCo
--      	  WHERE ARTL.ARCo <= 100
--			and ARTL.Mth between '1950-01-01 00:00:00' and '2050-12-01 12:00:00'
--   			and ARTH.ARTransType IN ('A','C','I','M','W')
--			AND TaxCode IS NOT NULL --??
--      	  GROUP BY ARTL.ARCo, Name, TaxCode, ARTL.ARTrans, ARTL.Mth, ARTL.Contract, ARTL.TaxGroup, ARTL.Item

--		  --WA1280

DECLARE @TaxGroup bGroup
DECLARE @TaxCode bTaxCode

SET @TaxGroup=1
SET @TaxCode='WA1187'

SELECT * FROM HQTX t with (nolock) where t.TaxGroup=@TaxGroup and t.TaxCode=@TaxCode

SELECT * FROM HQTL WHERE TaxGroup=@TaxGroup AND TaxCode=@TaxCode

SELECT * FROM HQTX t1 JOIN HQTL t2 ON t1.TaxGroup = t2.TaxGroup AND t1.TaxCode=t2.TaxLink AND t2.TaxGroup=@TaxGroup AND t2.TaxCode=@TaxCode

SELECT * FROM budGeographicLookup WHERE McKCityId=@TaxCode