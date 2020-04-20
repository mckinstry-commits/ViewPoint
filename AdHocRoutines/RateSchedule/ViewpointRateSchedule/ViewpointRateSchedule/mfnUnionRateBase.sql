USE Viewpoint
go

if exists ( select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='FUNCTION' and ROUTINE_NAME='mfnUnionRateBase')
begin
	print 'DROP FUNCTION dbo.mfnUnionRateBase'
	DROP FUNCTION dbo.mfnUnionRateBase
end
go

print 'CREATE FUNCTION dbo.mfnUnionRateBase'
go

CREATE function mfnUnionRateBase
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
	prcc.PRCo
,	prcm.Craft
,	prcm.Description AS CraftDesc
,	prcm.Notes AS CraftNote
,	prcc.Class
,	prcc.Description AS ClassDesc
,	prcc.udShopYN AS ShopClassYN
,	prcp.Shift
,	CAST(prcp.NewRate AS DECIMAL(20,5)) AS RegularRate
,	CAST(prcp.NewRate * precot.Factor AS DECIMAL(20,5)) AS OvertimeRate
,	CAST(prcp.NewRate * precdt.Factor AS DECIMAL(20,5)) AS DoubletimeRate
,	CAST(prcp.NewRate / (1 + jctl.LiabilityRate) AS DECIMAL(20,5)) AS RegularStandardRate
,	CAST(( prcp.NewRate * precot.Factor)  / (1 + jctl.LiabilityRate) AS DECIMAL(20,5)) AS OvertimeStandardRate
,	CAST(( prcp.NewRate * precdt.Factor)  / (1 + jctl.LiabilityRate) AS DECIMAL(20,5)) AS DoubletimeStandardRate
,	'Union Burden' AS BurdenDesc
,	jctl.LiabilityRate AS BurdenRate
--,	liab.*
FROM 
	HQCO hqco JOIN
	PRCO prco ON
		hqco.HQCo = prco.PRCo
	AND hqco.udTESTCo<>'Y' JOIN
	PREC precot ON
		prco.PRCo=precot.PRCo
	AND prco.CrewOTEC=precot.EarnCode JOIN
	PREC precdt ON
		prco.PRCo=precdt.PRCo
	AND prco.CrewDblEC=precdt.EarnCode JOIN
    PRCM prcm ON
		prco.PRCo=prcm.PRCo JOIN
	PRCC prcc ON
		prcc.PRCo=prcm.PRCo 
	AND prcc.Craft=prcm.Craft JOIN
	--dbo.mfnUnionRateLiabilities(1, '0016.00',null) liab ON
	--	prcc.PRCo=liab.PRCo
	--AND prcc.Craft=liab.Craft
	--AND prcc.Class=liab.Class JOIN
	PRCP prcp ON
		prcp.PRCo=prcc.PRCo
	AND prcp.Craft=prcc.Craft
	AND prcp.Class=prcc.Class 
	AND prcp.Shift IN (1,2,3) JOIN
	JCTL jctl ON
		jctl.JCCo=prco.PRCo
	AND jctl.LiabTemplate=1 
	AND jctl.LiabType=5
WHERE
	prcm.Craft <> '0000'
AND ( prco.PRCo = @Company OR @Company IS NULL )
AND ( prcm.Craft = @Craft OR @Craft IS NULL )
AND ( prcc.Class = @Class OR @Class IS NULL )
AND ( prcp.Shift = @Shift OR @Shift IS NULL )
)

go

GRANT SELECT ON mfnUnionRateBase TO PUBLIC
go 

SELECT 
	* 
FROM 
	dbo.mfnUnionRateBase(20, null,NULL,null)
ORDER BY
	PRCo
,	Craft
,	Class
,	Shift

--dbo.mfnUnionRateAddOns(1, '0016.00',null)
--dbo.mfnUnionRateVariableEarnings(1, '0016.00',null)
