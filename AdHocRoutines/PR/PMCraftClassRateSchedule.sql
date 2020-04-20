-- Determine RG, OV, DT Multiplier Factors

DECLARE @Craft bCraft
DECLARE @Class bClass

SELECT 
	@Craft='0016.00'
,	@Class='3500.000JR'



--SELECT
--	prcm.PRCo
--,	prcm.Craft
--,	prcm.Description AS CraftDesc
--,	prcc.Class
--,	prcc.Description AS ClassDesc
--,	prcc.Notes AS ClassNotes
--,	prcp.Shift
--,	prcp.OldRate
--,	prcp.NewRate
--,	prcf.EarnCode AS AddOnEarnCode
--,	prcf.Factor AS AddOnFactor
--,	prcf.OldRate AS AddOnOldRate
--,	prcf.NewRate AS AddOnNewRate
--,	prec.Description AS AddOnDesc
--,	prec.Method AS AddOnDesc
--,	prcd.DLCode
--,	prcd.Factor
--,	prcd.OldRate
--,	prcd.NewRate
--,	prdl.Description
--,	prdl.DLType
--,	prdl.Method
--,	prdl.Routine
--FROM 
--	HQCO hqco join
--	PRCM prcm ON
--		prcm.PRCo=hqco.HQCo
--	AND hqco.udTESTCo <> 'Y' JOIN
--	PRCC prcc ON 
--		prcm.PRCo=prcc.PRCo
--	AND prcm.Craft=prcc.Craft JOIN
--	PRCP prcp ON	
--		prcp.PRCo=prcc.PRCo
--	AND prcp.Craft=prcc.Craft
--	AND prcp.Class=prcc.Class /* LEFT OUTER JOIN 
--	PRCE prce ON
--		prce.PRCo=prcc.PRCo
--	AND prce.Craft=prcc.Craft
--	AND prce.Class=prcc.Class LEFT OUTER JOIN
--	PREC prec ON 
--		prce.PRCo=prec.PRCo 
--	AND prce.EarnCode=prec.EarnCode */ LEFT OUTER JOIN 
--	PRCF prcf ON
--		prcf.PRCo=prcc.PRCo
--	AND prcf.Craft=prcc.Craft
--	AND prcf.Class=prcc.Class LEFT OUTER JOIN
--	PREC prec ON 
--		prcf.PRCo=prec.PRCo 
--	AND prcf.EarnCode=prec.EarnCode /* LEFT OUTER JOIN
--	PRCD prcd ON
--		prcd.PRCo=prcc.PRCo
--	AND prcd.Craft=prcc.Craft
--	AND prcd.Class=prcc.Class LEFT OUTER JOIN 
--	PRDL prdl ON 
--		prcd.PRCo=prdl.PRCo 
--	AND prcd.DLCode=prdl.DLCode */
--WHERE
--	prcc.Craft=@Craft
--AND prcc.Class=@Class
	
	
	

--SELECT * FROM PRCM WHERE PRCo<100 AND Craft=@Craft
SELECT udShopYN,* FROM PRCC WHERE PRCo<100 AND Craft=@Craft AND Class=@Class

-- SELECT "PRCP"."PRCo", "PRCP"."Craft", "PRCP"."Class", "PRCP"."Shift", "PRCP"."OldRate", "PRCP"."NewRate"
-- FROM   "PRCP" "PRCP"
-- WHERE  "PRCP"."PRCo" < 100 AND Craft=@Craft AND Class=@Class
-- ORDER BY "PRCP"."PRCo", "PRCP"."Craft", "PRCP"."Class"
 
 -- SELECT "PRCE"."PRCo", "PRCE"."Craft", "PRCE"."Class", "PRCE"."Shift", "PRCE"."EarnCode", "PRCE"."OldRate", "PRCE"."NewRate", "PREC"."Description", "PREC"."Method"
 --FROM   "PRCE" "PRCE" LEFT OUTER JOIN "PREC" "PREC" ON ("PRCE"."PRCo"="PREC"."PRCo") AND ("PRCE"."EarnCode"="PREC"."EarnCode")
 --WHERE  "PRCE"."PRCo" < 100  AND Craft=@Craft AND Class=@Class
 --ORDER BY "PRCE"."PRCo", "PRCE"."Craft", "PRCE"."Class"
 
  SELECT "PRCF"."PRCo", "PRCF"."Craft", "PRCF"."Class", "PRCF"."EarnCode", "PRCF"."Factor", "PRCF"."OldRate", "PRCF"."NewRate", "PREC"."Description", "PREC"."Method"
 FROM   "PRCF" "PRCF" LEFT OUTER JOIN "PREC" "PREC" ON ("PRCF"."PRCo"="PREC"."PRCo") AND ("PRCF"."EarnCode"="PREC"."EarnCode")
 WHERE  "PRCF"."PRCo" < 100  AND Craft=@Craft AND Class=@Class
 ORDER BY "PRCF"."PRCo", "PRCF"."Craft", "PRCF"."Class"

 SELECT "PRCD"."PRCo", "PRCD"."Craft", "PRCD"."Class", "PRCD"."DLCode", "PRCD"."Factor", "PRCD"."OldRate", "PRCD"."NewRate", "PRDL"."Description", "PRDL"."DLType", "PRDL"."Method", "PRDL"."Routine"
 FROM   "PRCD" "PRCD" LEFT OUTER JOIN "PRDL" "PRDL" ON ("PRCD"."PRCo"="PRDL"."PRCo") AND ("PRCD"."DLCode"="PRDL"."DLCode")
 WHERE  "PRCD"."PRCo" < 100  AND Craft=@Craft AND Class=@Class
 ORDER BY "PRCD"."PRCo", "PRCD"."Craft", "PRCD"."Class"
 
 
SELECT prec.PRCo, prec.EarnType, hqet.Description AS EarnTypeDesc, prec.EarnCode, prec.Description AS EarnCodeDesc, prec.Frequency, prec.JCCostType, prec.Factor 
FROM 
	PREC prec JOIN
	HQET hqet ON
		prec.EarnType=hqet.EarnType
	AND prec.EarnCode IN (5,6,7)
WHERE PRCo < 100 
ORDER BY
	prec.PRCo, prec.EarnType,prec.EarnCode

--  SELECT DISTINCT Craft,Class FROM dbo.PREHName WHERE PRCo < 100 ORDER BY Craft,Class
 SELECT * FROM dbo.PREHName WHERE Craft=@Craft AND Class=@Class AND PRCo < 100







