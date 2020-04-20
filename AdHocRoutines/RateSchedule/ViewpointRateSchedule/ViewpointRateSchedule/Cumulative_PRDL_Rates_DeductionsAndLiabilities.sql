USE Viewpoint
go

if exists ( select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='FUNCTION' and ROUTINE_NAME='mfnUnionRateLiabilities')
begin
	print 'DROP FUNCTION dbo.mfnUnionRateLiabilities'
	DROP FUNCTION dbo.mfnUnionRateLiabilities
end
go

print 'CREATE FUNCTION dbo.mfnUnionRateLiabilities'
go

CREATE function mfnUnionRateLiabilities
(
	@Company	bCompany	= null
,	@Craft		bCraft		= null
,	@Class		bClass		= NULL
,	@Shift		INT			= 1
)
RETURNS TABLE 
AS
RETURN 
(
SELECT 
	'Liabilities' AS Type
,	pvt.*
FROM
(
SELECT
	prdl.PRCo
,	prcm.Craft
,	prcc.Class
,	prcp.Shift
,	prdl.DLType
,	prdl.DLCode
,	prdl.DednCode
,	prdl.Description
,	prdl.LiabType
,	hqlt.Description AS LiabilityTypeDesc
,	prdl.Method 
,	case prdl.Method
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
	PRDL prdl ON 
		prcd.PRCo=prdl.PRCo 
	AND prcd.DLCode=prdl.DLCode LEFT OUTER JOIN
	HQLT hqlt ON
		prdl.LiabType=hqlt.LiabType
	WHERE 
		prdl.DLType='L'
	AND prcm.Craft <> '0000'
	AND ( prdl.PRCo = @Company OR @Company IS NULL )
	AND ( prcm.Craft = @Craft OR @Craft IS NULL )
	AND ( prcc.Class = @Class OR @Class IS NULL )
	AND ( prcp.Shift = @Shift OR @Shift IS NULL )
GROUP BY
	prdl.PRCo
,	prcm.Craft
,	prcc.Class
,	prcp.Shift
,	prcc.udShopYN
,	prdl.DLType
,	prdl.DLCode
,	prdl.DednCode
,	prdl.Description
,	prdl.LiabType
,	hqlt.Description
,	prdl.Method 
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
)
go


GRANT SELECT ON mfnUnionRateLiabilities TO PUBLIC
go


SELECT 
	* 
FROM 
	dbo.mfnUnionRateLiabilities(1, '0016.00',NULL,null)
ORDER BY
	PRCo
,	Craft
,	Class
,	Shift
,	LiabType
,	DLCode


--SELECT DISTINCT Method FROM PRDL WHERE DLType='L' AND PRCo < 100 ORDER BY 1

