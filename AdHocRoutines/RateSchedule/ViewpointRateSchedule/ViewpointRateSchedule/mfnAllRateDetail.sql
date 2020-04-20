if exists ( select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='FUNCTION' and ROUTINE_NAME='mfnAllRateDetail')
begin
	print 'DROP FUNCTION dbo.mfnAllRateDetail'
	DROP FUNCTION dbo.mfnAllRateDetail
end
go

print 'CREATE FUNCTION dbo.mfnAllRateDetail'
go

CREATE function mfnAllRateDetail
(
	@Company	bCompany	= null
,	@Craft		bCraft		= null
,	@Class		bClass		= NULL
,	@Shift		INT			= NULL 
)
RETURNS TABLE 
AS
RETURN 
(
SELECT 
	br.PRCo
,	br.Craft
,	br.CraftDesc
,	br.CraftNote
,	br.Class
,	br.ClassDesc
,	br.ShopClassYN
,	br.Shift
,	br.RegularRate
,	br.OvertimeRate
,	br.DoubletimeRate
,	br.RegularStandardRate
,	br.OvertimeStandardRate
,	br.DoubletimeStandardRate
,	br.BurdenDesc
,	br.BurdenRate
--,	addon.*
--,	addon.Type	
--,	addon.PRCo	
--,	addon.Craft	
--,	addon.Class	
--,	addon.Shift	
,	addon.EarnCode AS AddOnEarnCode
,	addon.EarnCodeDesc AS AddOnEarnCodeDesc
,	addon.Factor AS AddOnFactor
,	addon.Method AS AddOnMethod	
,	addon.Amount AS AddOnAmount	
,	addon.Day AS AddOnDay	
,	addon.Decuction AS AddOnDecuction	
,	addon.Factored AS AddOnFactored	
,	addon.Gross AS AddOnGross	
,	addon.Hourly AS AddOnHourly	
,	addon.Net AS AddOn	
,	addon.Routine AS AddOnRoutine	
,	addon.Straight AS AddOnStraight	
,	addon.Variable AS AddOnVariable	
,	addon.Unknown AS AddOnUnknown
--,	liab.*
--,	liab.Type AS LiabilityType
--,	liab.PRCo AS LiabilityPRCo	
--,	liab.Craft AS LiabilityCraft	
--,	liab.Class AS LiabilityClass	
--,	liab.Shift AS LiabilityShift	
,	liab.DLType AS LiabilityDLType	
,	liab.DLCode AS LiabilityDLCode	
,	liab.DednCode AS LiabilityDednCode	
,	liab.Description AS LiabilityDescription	
,	liab.LiabType AS LiabilityLiabType	
,	liab.LiabilityTypeDesc AS LiabilityLiabilityTypeDesc	
,	liab.Method AS LiabilityMethod	
,	liab.Amount AS LiabilityAmount	
,	liab.Day AS LiabilityDay	
,	liab.Decuction AS LiabilityDecuction	
,	liab.Factored AS LiabilityFactored	
,	liab.Gross AS LiabilityGross	
,	liab.Hourly AS LiabilityHourly	
,	liab.Net AS LiabilityNet	
,	liab.Routine AS LiabilityRoutine	
,	liab.Straight AS LiabilityStraight	
,	liab.Variable AS LiabilityVariable	
,	liab.Unknown AS LiabilityUnknown
--  ADD VariableEarnings
FROM 
	dbo.mfnAllRateBase(@Company, @Craft,@Class,@Shift) br LEFT OUTER JOIN
	dbo.mfnUnionRateAddOns(@Company, @Craft,@Class,@Shift) addon ON
		br.PRCo=addon.PRCo
	AND br.Craft=addon.Craft
	AND br.Class=addon.Class
	AND br.Shift=addon.Shift	LEFT OUTER JOIN
	dbo.mfnUnionRateLiabilities(@Company, @Craft,@Class,@Shift) liab ON
		br.PRCo=liab.PRCo
	AND br.Craft=liab.Craft
	AND br.Class=liab.Class
	AND br.Shift=liab.Shift LEFT OUTER JOIN 
	dbo.mfnUnionRateVariableEarnings(@Company, @Craft,@Class,@Shift) vari ON
		br.PRCo=vari.PRCo
	AND br.Craft=vari.Craft
	AND br.Class=vari.Class
	AND br.Shift=vari.Shift
--ORDER BY
--	br.PRCo
--,	br.Craft
--,	br.Class
--,	br.Shift
)
GO

GRANT SELECT ON mfnAllRateDetail TO PUBLIC
go

SELECT 
	PRCo	
,	Craft	
,	CraftDesc	
,	CraftNote	
,	Class	
,	ClassDesc	
,	ShopClassYN	
,	Shift	
,	RegularRate	
,	OvertimeRate	
,	DoubletimeRate	
,	RegularStandardRate	
,	OvertimeStandardRate	
,	DoubletimeStandardRate	
,	BurdenDesc	
,	BurdenRate	
,	AddOnEarnCode	
,	AddOnEarnCodeDesc	
,	AddOnFactor	
,	AddOnMethod	
,	AddOnAmount	
,	AddOnDay	
,	AddOnDecuction	
,	AddOnFactored	
,	AddOnGross	
,	AddOnHourly	
,	AddOn	
,	AddOnRoutine	
,	AddOnStraight	
,	AddOnVariable	
,	AddOnUnknown	
,	LiabilityDLType	
,	LiabilityDLCode	
,	LiabilityDednCode	
,	LiabilityDescription	
,	LiabilityLiabType	
,	LiabilityLiabilityTypeDesc	
,	LiabilityMethod	
,	LiabilityAmount	
,	LiabilityDay	
,	LiabilityDecuction	
,	LiabilityFactored	
,	LiabilityGross	
,	LiabilityHourly	
,	LiabilityNet	
,	LiabilityRoutine	
,	LiabilityStraight	
,	LiabilityVariable	
,	LiabilityUnknown
FROM 
	dbo.mfnAllRateDetail(20, null,NULL,null)
ORDER BY
	PRCo
,	Craft
,	Class
,	Shift