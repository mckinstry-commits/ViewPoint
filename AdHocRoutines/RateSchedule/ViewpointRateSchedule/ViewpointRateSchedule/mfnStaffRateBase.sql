USE Viewpoint
go

if exists ( select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='FUNCTION' and ROUTINE_NAME='mfnStaffRateBase')
begin
	print 'DROP FUNCTION dbo.mfnStaffRateBase'
	DROP FUNCTION dbo.mfnStaffRateBase
end
go

print 'CREATE FUNCTION dbo.mfnStaffRateBase'
go

CREATE function mfnStaffRateBase
(
	@Company	bCompany	= NULL	
,	@Craft		bCraft		= null
,	@Class		bClass		= NULL
,	@Shift		int			= NULL
)
RETURNS TABLE 
AS
RETURN 
(
SELECT DISTINCT 
	prcc.PRCo
,	prcm.Craft
,	prcm.Description AS CraftDesc
,	prcm.Notes AS CraftNote
,	prcc.Class
,	prcc.Description AS ClassDesc
,	prcc.udShopYN AS ShopClassYN
,	COALESCE(jcrdrg.Shift,jcrdot.Shift,jcrddt.Shift) AS Shift
--,	jcrd.EarnFactor
--,	precrg.Factor
,	CAST(jcrdrg.NewRate AS DECIMAL(20,5)) AS RegularRate
,	CAST(jcrdrg.NewRate * precot.Factor AS DECIMAL(20,5)) AS OvertimeRate
,	CAST(jcrdrg.NewRate * precdt.Factor AS DECIMAL(20,5)) AS DoubletimeRate
,	CAST(jcrdrg.udStandardRate AS DECIMAL(20,5)) AS RegularStandardRate
,	CAST(jcrdrg.udStandardRate * precot.Factor AS DECIMAL(20,5)) AS OvertimeStandardRate
,	CAST(jcrdrg.udStandardRate * precdt.Factor AS DECIMAL(20,5)) AS DoubletimeStandardRate
,	'Staff Burden' AS BurdenDesc
,	COALESCE(jcrdrg.udBurdenPercent,jcrdot.udBurdenPercent,jcrddt.udBurdenPercent) AS BurdenRate
--,	jcrdrg.udBurdenPercent AS RegularBurdenRate
--,	jcrdot.udBurdenPercent AS OvertimeBurdenRate
--,	jcrdov.udBurdenPercent AS DoubletimeBurdenRate
--,	liab.*
FROM 
	HQCO hqco JOIN
	PRCO prco ON
		hqco.HQCo = prco.PRCo
	AND hqco.udTESTCo<>'Y' LEFT OUTER JOIN
	PREC precrg ON
		prco.PRCo=precrg.PRCo
	AND prco.CrewRegEC=precrg.EarnCode LEFT OUTER JOIN
	PREC precot ON
		prco.PRCo=precot.PRCo
	AND prco.CrewOTEC=precot.EarnCode LEFT OUTER JOIN
	PREC precdt ON
		prco.PRCo=precdt.PRCo
	AND prco.CrewDblEC=precdt.EarnCode LEFT OUTER JOIN
    PRCM prcm ON
		prco.PRCo=prcm.PRCo LEFT OUTER JOIN
	PRCC prcc ON
		prcc.PRCo=prcm.PRCo 
	AND prcc.Craft=prcm.Craft JOIN
	--dbo.mfnUnionRateLiabilities(1, '0016.00',null) liab ON
	--	prcc.PRCo=liab.PRCo
	--AND prcc.Craft=liab.Craft
	--AND prcc.Class=liab.Class JOIN
	JCRD jcrdrg ON
		jcrdrg.PRCo=prcc.PRCo
	AND jcrdrg.JCCo=prcc.PRCo
	AND jcrdrg.Craft=prcc.Craft
	AND jcrdrg.Class=prcc.Class 
	AND precrg.Factor=jcrdrg.EarnFactor LEFT OUTER JOIN
	JCRD jcrdot ON
		jcrdot.PRCo=prcc.PRCo
	AND jcrdot.JCCo=prcc.PRCo
	AND jcrdot.Craft=prcc.Craft
	AND jcrdot.Class=prcc.Class 
	AND precot.Factor=jcrdot.EarnFactor LEFT OUTER JOIN
	JCRD jcrddt ON
		jcrddt.PRCo=prcc.PRCo
	AND jcrddt.JCCo=prcc.PRCo
	AND jcrddt.Craft=prcc.Craft
	AND jcrddt.Class=prcc.Class 
	AND precdt.Factor=jcrddt.EarnFactor 
	--AND jcrd.Shift IN (1,2,3) 
	--JCRT jcrt ON
	--	jcrd.JCCo=jcrt.JCCo
	--AND jcrd.RateTemplate=jcrt.RateTemplate
	--AND jcrt.RateTemplate=1
WHERE
	prcm.Craft <> '0000'
AND ( prcc.PRCo = @Company OR @Company IS NULL )
AND ( prcm.Craft = @Craft OR @Craft IS NULL )
AND ( prcc.Class = @Class OR @Class IS NULL )
AND ( (	jcrdrg.Shift = @Shift OR 
		jcrdot.Shift = @Shift OR 
	    jcrddt.Shift = @Shift  ) OR  @Shift IS NULL )
)
go


GRANT SELECT ON mfnStaffRateBase TO PUBLIC
go 

SELECT 
	* 
FROM 
	dbo.mfnStaffRateBase(20, null,NULL,null)
ORDER BY
	PRCo
,	Craft
,	Class
,	Shift



--dbo.mfnUnionRateAddOns(1, '0016.00',null)
--dbo.mfnUnionRateVariableEarnings(1, '0016.00',null)
