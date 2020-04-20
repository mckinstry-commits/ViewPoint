USE Viewpoint
go

if exists ( select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='FUNCTION' and ROUTINE_NAME='mfnUnionRateVariableEarnings')
begin
	print 'DROP FUNCTION dbo.mfnUnionRateVariableEarnings'
	DROP FUNCTION dbo.mfnUnionRateVariableEarnings
end
go

print 'CREATE FUNCTION dbo.mfnUnionRateVariableEarnings'
go

CREATE function mfnUnionRateVariableEarnings
(
	@Company	bCompany	= null
,	@Craft		bCraft		= null
,	@Class		bClass		= null
,	@Shift		INT			= null
)
RETURNS TABLE 
AS
RETURN 
(
SELECT 
	'VariableEarnings' AS Type
,	pvt.*
FROM
(
SELECT
	prce.PRCo
,	prcm.Craft
,	prcc.Class
,	prcp.Shift
,	prcc.udShopYN
,	prce.EarnCode
,	prec.Description AS EarnCodeDesc
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
--,	CAST(prcp.NewRate * ( SELECT Factor FROM PREC WHERE EarnCode=prco.CrewOTEC AND PRCo=prce.PRCo) AS NUMERIC(16,5)) AS OverTimeRate
--,	CAST(prcp.NewRate * ( SELECT Factor FROM PREC WHERE EarnCode=prco.CrewDblEC AND PRCo=prce.PRCo) AS NUMERIC(16,5)) AS DoubleTimeRate
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
	PRCE prce ON 
		prce.PRCo=prcc.PRCo
	AND prce.Craft=prcc.Craft
	AND prce.Class=prcc.Class JOIN 
	PREC prec ON 
		prce.PRCo=prec.PRCo 
	AND prce.EarnCode=prec.EarnCode	
	WHERE 
		prcm.Craft <> '0000'
	AND ( prce.PRCo = @Company OR @Company IS NULL )
	AND ( prcm.Craft = @Craft OR @Craft IS NULL )
	AND ( prcc.Class = @Class OR @Class IS NULL )
	AND ( prcp.Shift = @Shift OR @Shift IS NULL )
	--	AND prdl.Method='G'
	--	AND prdl.DLType='L'
	--	--AND prcd.DLCode=305
	--	AND prcc.udShopYN='Y'	
GROUP BY
	prce.PRCo
,	prcm.Craft
,	prcc.Class
,	prcp.Shift
,	prcc.udShopYN
,	prce.EarnCode
,	prec.Description
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

GRANT SELECT ON mfnUnionRateVariableEarnings TO PUBLIC
go

SELECT 
	*
FROM 
	dbo.mfnUnionRateVariableEarnings(1, '0016.00',NULL, null)
ORDER BY
	PRCo
,	Craft
,	Class
,	Shift

--SELECT DISTINCT Method FROM PRDL WHERE DLType='L' AND PRCo < 100 ORDER BY 1

