USE Viewpoint
go

if exists ( select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='FUNCTION' and ROUTINE_NAME='mfnUnionRateAddOns')
begin
	print 'DROP FUNCTION dbo.mfnUnionRateAddOns'
	DROP FUNCTION dbo.mfnUnionRateAddOns
end
go

print 'CREATE FUNCTION dbo.mfnUnionRateAddOns'
go

CREATE function mfnUnionRateAddOns
(
	@Company	bCompany	= null
,	@Craft		bCraft		= null
,	@Class		bClass		= NULL
,	@Shift		INT			= null
)
RETURNS TABLE 
AS
RETURN 
(
SELECT 
	'AddOns' AS Type
,	pvt.*
FROM
(
SELECT
	prcf.PRCo
,	prcm.Craft
,	prcc.Class
,	prcp.Shift
--,	prcc.udShopYN
,	prcf.EarnCode
,	prec.Description AS EarnCodeDesc
,	prcf.Factor
,	prec.Method 
,	case prec.Method
		WHEN 'A' THEN 'Amount'		-- Amount
		WHEN 'D' THEN 'Day'			-- Rate per day
		WHEN 'DN' THEN 'Decuction'	-- Rate of a deduction
		WHEN 'G' THEN 'Factored'	-- Factored Rate per Hour	
		WHEN 'G' THEN 'Gross'		-- Rate of Gross
		WHEN 'H' THEN 'Hourly'		-- Rate per hour
		WHEN 'N' THEN 'Net'			-- Rate of net
		WHEN 'R' THEN 'Routine'			-- Routine
		WHEN 'S' THEN 'Straight'	-- Straight Time Equivelant
		WHEN 'V' THEN 'Variable'	-- Variable Factored Rate
		ELSE 'Unknown'
	END AS MethodName
--,	prcp.NewRate AS RegularRate
--,	CAST(prcp.NewRate * ( SELECT Factor FROM PREC WHERE EarnCode=prco.CrewOTEC AND PRCo=prcf.PRCo) AS NUMERIC(16,5)) AS OverTimeRate
--,	CAST(prcp.NewRate * ( SELECT Factor FROM PREC WHERE EarnCode=prco.CrewDblEC AND PRCo=prcf.PRCo) AS NUMERIC(16,5)) AS DoubleTimeRate
,	COALESCE(SUM(prcd.NewRate),0) AS Rate
FROM 
	HQCO hqco JOIN
    PRCO prco ON
		hqco.HQCo=prco.PRCo join
	PRCM prcm ON
		prcm.PRCo=hqco.HQCo
	AND hqco.udTESTCo <> 'Y' LEFT OUTER JOIN
	PRCC prcc ON 
		prcm.PRCo=prcc.PRCo
	AND prcm.Craft=prcc.Craft LEFT OUTER JOIN
	PRCP prcp ON	
		prcp.PRCo=prcc.PRCo
	AND prcp.Craft=prcc.Craft
	AND prcp.Class=prcc.Class 
	AND prcp.Shift IN (1,2,3) LEFT OUTER JOIN
	PRCD prcd ON
		prcd.PRCo=prcc.PRCo
	AND prcd.Craft=prcc.Craft
	AND prcd.Class=prcc.Class LEFT OUTER JOIN
	PRCF prcf ON 
		prcf.PRCo=prcc.PRCo
	AND prcf.Craft=prcc.Craft
	AND prcf.Class=prcc.Class JOIN 
	PREC prec ON 
		prcf.PRCo=prec.PRCo 
	AND prcf.EarnCode=prec.EarnCode	
	WHERE 
		prcm.Craft <> '0000'
	AND ( prcf.PRCo = @Company OR @Company IS NULL )
	AND ( prcm.Craft = @Craft OR @Craft IS NULL )
	AND ( prcc.Class = @Class OR @Class IS NULL )
	AND ( prcp.Shift = @Shift OR @Shift IS NULL )
	--	AND prdl.Method='G'
	--	AND prdl.DLType='L'
	--	--AND prcd.DLCode=305
	--	AND prcc.udShopYN='Y'	
GROUP BY
	prcf.PRCo
,	prcm.Craft
,	prcc.Class
,	prcp.Shift
,	prcc.udShopYN
,	prcf.EarnCode
,	prec.Description
,	prcf.Factor
,	prec.Method  
,	prcp.NewRate --AS RegularRate
,	prco.CrewOTEC 
,	prco.CrewDblEC 
HAVING
	COALESCE(SUM(prcd.NewRate),0) <> 0
--ORDER BY
--	prdl.PRCo
--,	prcm.Craft
--,	prcc.Class
--,	prdl.LiabType
--,	prdl.DLCode
) base
PIVOT
(
	sum(Rate) FOR MethodName in ([Amount],[Day],[Decuction],[Factored],[Gross],[Hourly],[Net],[Routine],[Straight],[Variable],[Unknown])
) pvt
--ORDER BY
--	PRCo
--,	Craft
--,	Class
--,	Shift
--,	EarnCode
)
go

GRANT SELECT ON mfnUnionRateAddOns TO PUBLIC
go


SELECT 
	*
FROM 
	dbo.mfnUnionRateAddOns(1, '0016.00',NULL, null)
ORDER BY
	PRCo
,	Craft
,	Class
,	Shift
,	EarnCode

--SELECT DISTINCT Method FROM PRDL WHERE DLType='L' AND PRCo < 100 ORDER BY 1

