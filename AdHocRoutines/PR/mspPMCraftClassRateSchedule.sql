USE Viewpoint
go

/*
TODO:
LWO - DONE - 2014.11.28 - Create UD Fields on JC Fixed Rate Templates to record Standard Rate and/or Burden Percentage
Alter query to run for a single craft/class/shift/etc. and return a row only if the resulting rates have changed
Create a UD Table to store historical list of rates by craft/class/shift with effect dates
Create triggers on JC Fixed Rate and Craft/Class Master to trigger recording of changes (e.g. if rates change, expire the old rate and add a new rate (with new effective date) to above UD table.
Create Form as child table/tab on Craft/Class Master to show historical rates.
Create Report/Export of rates for a given date for pulication to company as a "standard rate sheet" based on Craft/Class
Create Report/Export of rates for a given date for pulication to company as a "standard rate sheet" based on an Employee (or list of Employees ) using Employees assigned Craft Class.

*/
-- Select from JCTL for Company Wise Liability Templates
--SELECT * FROM JCTL

IF EXISTS (SELECT 1 FROM sysobjects WHERE name='mvwPMCraftClassRateDetails' AND type='V')
BEGIN
	PRINT 'DROP VIEW mvwPMCraftClassRateDetails'
	DROP VIEW mvwPMCraftClassRateDetails
END

PRINT 'CREATE VIEW mvwPMCraftClassRateDetails'
go

/*
Union - Need Liability Broken out
        Record to table for point in time historical reference.

Staff - Need UD Fields on JC Fixed Rate for "Standard Rate" and "Burden Percent".  Burden Percent is entered and Standard rate is calculated based on match between Fixed Rate and Percentage.
		Need UD Table for point in time historical reference.
		May need to tap into other tables (maybe Company Rates or other UD) to provide details for calculating breakout values (e.g. 401K, Medical, etc.)

All calculated Hourly rates need to be rounded to #.##### (5 digits of precision).

*/
CREATE VIEW mvwPMCraftClassRateDetails
AS
SELECT
	prcm.PRCo
,	prcm.Craft
,	prcm.Description AS CraftDesc
,	CASE WHEN CHARINDEX('.',prcc.Craft) > 0 then LEFT(prcm.Craft,CHARINDEX('.',prcc.Class)-1) ELSE null END AS CraftSeg1
,	CASE WHEN CHARINDEX('.',prcc.Craft) > 0 then SUBSTRING(prcm.Craft,CHARINDEX('.',prcc.Class)+1, LEN(prcm.Craft)) ELSE NULL END AS CraftSeg2
,	prcc.Class
,	prcc.Description AS ClassDesc
,	CASE WHEN CHARINDEX('.',prcc.Class) > 0 then LEFT(prcc.Class,CHARINDEX('.',prcc.Class)-1) ELSE NULL END AS ClassSeg1
,	CASE WHEN CHARINDEX('.',prcc.Class) > 0 then SUBSTRING(prcc.Class,CHARINDEX('.',prcc.Class)+1,3) ELSE NULL END AS ClassSeg2
,	CASE WHEN CHARINDEX('.',prcc.Class) > 0 then RIGHT(prcc.Class,2) ELSE NULL END AS ClassSeg3
,	prcc.Notes AS ClassNotes
,	prcp.Shift
,	prcp.NewRate AS RegularRate
,	CAST(prcp.NewRate * ( SELECT Factor FROM PREC WHERE EarnCode=prco.CrewOTEC AND PRCo=prcc.PRCo) AS NUMERIC(16,5)) AS OverTimeRate
,	CAST(prcp.NewRate * ( SELECT Factor FROM PREC WHERE EarnCode=prco.CrewDblEC AND PRCo=prcc.PRCo) AS NUMERIC(16,5)) AS DoubleTimeRate
,	COALESCE((
		SELECT 
			SUM(prcf.NewRate)
		FROM 
			PRCF prcf JOIN 
			PREC prec ON 
				prcf.PRCo=prec.PRCo 
			AND prcf.EarnCode=prec.EarnCode	
		WHERE
			prcf.PRCo=prcc.PRCo
		AND prcf.Craft=prcc.Craft
		AND prcf.Class=prcc.Class
		AND prec.Method='H'
	),0) AS TotalHourAddOnAmount
,	COALESCE((
		SELECT 
			SUM(prcf.NewRate)
		FROM 
			PRCF prcf JOIN 
			PREC prec ON 
				prcf.PRCo=prec.PRCo 
			AND prcf.EarnCode=prec.EarnCode	
		WHERE
			prcf.PRCo=prcc.PRCo
		AND prcf.Craft=prcc.Craft
		AND prcf.Class=prcc.Class
		AND prec.Method='G'
	),0) AS TotalGrossAddOnPercent	
-- AS PER JOSEPH/HOWARD, Deductions are not included
--,	COALESCE((
--		SELECT 
--			SUM(prcd.NewRate)
--		FROM
--		PRCD prcd LEFT OUTER JOIN 
--		PRDL prdl ON 
--			prcd.PRCo=prdl.PRCo 
--		AND prcd.DLCode=prdl.DLCode
--		WHERE 
--			prcd.PRCo=prcc.PRCo
--		AND prcd.Craft=prcc.Craft
--		AND prcd.Class=prcc.Class
--		AND prdl.Method='H'
--		AND prdl.DLType='D'
--	),0) AS TotalHourlyDeductionAmount
--,	COALESCE((
--		SELECT 
--			SUM(prcd.NewRate)
--		FROM
--		PRCD prcd LEFT OUTER JOIN
--		PRDL prdl ON 
--			prcd.PRCo=prdl.PRCo 
--		AND prcd.DLCode=prdl.DLCode
--		WHERE 
--			prcd.PRCo=prcc.PRCo
--		AND prcd.Craft=prcc.Craft
--		AND prcd.Class=prcc.Class
--		AND prdl.Method='G'
--		AND prdl.DLType='D'
--	),0) AS TotalGrossDeductionPercent
,	COALESCE((
		SELECT 
			SUM(prdl.RateAmt1)
		FROM
		PRCD prcd LEFT OUTER JOIN 
		PRDL prdl ON 
			prcd.PRCo=prdl.PRCo 
		AND prcd.DLCode=prdl.DLCode
		WHERE 
			prcd.PRCo=prcc.PRCo
		AND prcd.Craft=prcc.Craft
		AND prcd.Class=prcc.Class
		AND prdl.Method='H'
		AND prdl.DLType='L'
		--AND prcd.DLCode=305
		AND prcc.udShopYN='Y'
	),0) AS TotalHourlyShopLiabilityAmount
,	COALESCE((
		SELECT 
			SUM(prdl.RateAmt1)
		FROM
		PRCD prcd LEFT OUTER JOIN
		PRDL prdl ON 
			prcd.PRCo=prdl.PRCo 
		AND prcd.DLCode=prdl.DLCode
		WHERE 
			prcd.PRCo=prcc.PRCo
		AND prcd.Craft=prcc.Craft
		AND prcd.Class=prcc.Class
		AND prdl.Method='G'
		AND prdl.DLType='L'
		--AND prcd.DLCode=305
		AND prcc.udShopYN='Y'
	),0) AS TotalGrossShopLiabilityPercent	
,	COALESCE((
		SELECT 
			SUM(prcd.NewRate)
		FROM
		PRCD prcd LEFT OUTER JOIN
		PRDL prdl ON 
			prcd.PRCo=prdl.PRCo 
		AND prcd.DLCode=prdl.DLCode
		WHERE 
			prcd.PRCo=prcc.PRCo
		AND prcd.Craft=prcc.Craft
		AND prcd.Class=prcc.Class
		AND prdl.Method='H'
		AND prdl.DLType='L'
		--AND prcd.DLCode=305
		AND prcc.udShopYN<>'Y'
	),0) AS TotalHourlyLiabilityAmount
,	COALESCE((
		SELECT 
			SUM(prcd.NewRate)
		FROM
		PRCD prcd LEFT OUTER JOIN
		PRDL prdl ON 
			prcd.PRCo=prdl.PRCo 
		AND prcd.DLCode=prdl.DLCode
		WHERE 
			prcd.PRCo=prcc.PRCo
		AND prcd.Craft=prcc.Craft
		AND prcd.Class=prcc.Class
		AND prdl.Method='G'
		AND prdl.DLType='L'
		--AND prcd.DLCode=305
		AND prcc.udShopYN='Y'
	),0) AS TotalGrossLiabilityPercent	
,	(SELECT LiabilityRate from JCTL WHERE JCCo=prcc.PRCo AND LiabTemplate=1 AND LiabType=5) AS BurdenRate
FROM 
	HQCO hqco JOIN
    PRCO prco ON
		hqco.HQCo=prco.PRCo join
	PRCM prcm ON
		prcm.PRCo=hqco.HQCo
	AND hqco.udTESTCo <> 'Y' JOIN
	PRCC prcc ON 
		prcm.PRCo=prcc.PRCo
	AND prcm.Craft=prcc.Craft JOIN
	PRCP prcp ON	
		prcp.PRCo=prcc.PRCo
	AND prcp.Craft=prcc.Craft
	AND prcp.Class=prcc.Class
go



IF EXISTS (SELECT 1 FROM sysobjects WHERE name='mspPMCraftClassRateSchedule' AND type='P')
BEGIN
	PRINT 'DROP PROCEDURE mspPMCraftClassRateSchedule'
	DROP PROCEDURE mspPMCraftClassRateSchedule
END

PRINT 'CREATE PROCEDURE mspPMCraftClassRateSchedule'
go

CREATE PROCEDURE mspPMCraftClassRateSchedule
(
	@Hours int = 1
,	@Craft bCraft = null
,	@Class bClass = null
)
as
SELECT 
	PRCo	
,	Craft	
,	CraftDesc	
,	CraftSeg1	
,	CraftSeg2	
,	Class	
,	ClassDesc	
,	ClassSeg1	
,	ClassSeg2	
,	ClassSeg3	
,	ClassNotes	
,	Shift	
,		CAST((( RegularRate * @Hours ) 
	+	( TotalHourAddOnAmount * @Hours ) 
	+	( (RegularRate * @Hours ) * TotalGrossAddOnPercent ) 
	+	( TotalHourlyLiabilityAmount * @Hours )
	+   ( (RegularRate * @Hours ) * TotalGrossLiabilityPercent )
	+	(TotalHourlyShopLiabilityAmount * @Hours )
	+	( ( RegularRate * @Hours ) * TotalGrossShopLiabilityPercent )) * (1 + BurdenRate) AS decimal(18,2)) AS FullRegularRate
,		CAST((( OverTimeRate  * @Hours ) 
	+	( TotalHourAddOnAmount * @Hours ) 
	+	( ( OverTimeRate * @Hours ) * TotalGrossAddOnPercent ) 
	+	( TotalHourlyLiabilityAmount * @Hours )
	+   ( ( OverTimeRate * @Hours ) * TotalGrossLiabilityPercent )
	+	( TotalHourlyShopLiabilityAmount * @Hours )
	+	( ( OverTimeRate * @Hours ) * TotalGrossShopLiabilityPercent )) * (1 + BurdenRate) AS decimal(18,2)) AS FullOvertimeRate
,		CAST((( DoubleTimeRate  * @Hours )
	+	( TotalHourAddOnAmount * @Hours ) 
	+	( ( DoubleTimeRate * @Hours ) * TotalGrossAddOnPercent ) 
	+	( TotalHourlyLiabilityAmount * @Hours )
	+   ( ( DoubleTimeRate * @Hours ) * TotalGrossLiabilityPercent )
	+	( TotalHourlyShopLiabilityAmount * @Hours )
	+	( ( DoubleTimeRate * @Hours ) * TotalGrossShopLiabilityPercent )) * (1 + BurdenRate) AS decimal(18,2)) AS FullDoubleTimeRate
,	@Hours AS [Hours]	
,	RegularRate	
,	OverTimeRate	
,	DoubleTimeRate	
,	TotalHourAddOnAmount	
,	TotalGrossAddOnPercent	
--,	TotalHourlyDeductionAmount	
--,	TotalGrossDeductionPercent	
,	TotalHourlyShopLiabilityAmount	
,	TotalGrossShopLiabilityPercent	
,	TotalHourlyLiabilityAmount	
,	TotalGrossLiabilityPercent
,	BurdenRate
FROM 
	mvwPMCraftClassRateDetails
WHERE
	(Craft=@Craft OR @Craft IS NULL)
AND (Class=@Class OR @Class IS NULL)
ORDER BY
	PRCo
,	Craft
,	Class
go

--IF EXISTS (SELECT 1 FROM sysobjects WHERE name='mspPMCraftClassRateSchedule' AND type='P')
--BEGIN
--	PRINT 'DROP PROCEDURE mspPMCraftClassRateSchedule'
--	DROP PROCEDURE mspPMCraftClassRateSchedule
--END

--PRINT 'CREATE PROCEDURE mspPMCraftClassRateSchedule'
--go

--CREATE PROCEDURE mspPMCraftClassRateSchedule
--(
--	@Craft bCraft = null
--,	@Class bClass = null
--)
--as
--SELECT
--	prcm.PRCo
--,	prcm.Craft
--,	prcm.Description AS CraftDesc
--,	LEFT(prcm.Craft,CHARINDEX('.',prcc.Class)-1) AS CraftSeg1
--,	SUBSTRING(prcm.Craft,CHARINDEX('.',prcc.Class)+1, LEN(prcm.Craft)) AS CraftSeg2
--,	prcc.Class
--,	prcc.Description AS ClassDesc
--,	LEFT(prcc.Class,CHARINDEX('.',prcc.Class)-1) AS ClassSeg1
--,	SUBSTRING(prcc.Class,CHARINDEX('.',prcc.Class)+1,3) AS ClassSeg2
--,	RIGHT(prcc.Class,2) AS ClassSeg3
--,	prcc.Notes AS ClassNotes
--,	prcp.Shift
--,	prcp.NewRate AS RegularRate
--,	CAST(prcp.NewRate * ( SELECT Factor FROM PREC WHERE EarnCode=2 AND PRCo=prcc.PRCo) AS NUMERIC(16,5)) AS OverTimeRate
--,	CAST(prcp.NewRate * ( SELECT Factor FROM PREC WHERE EarnCode=3 AND PRCo=prcc.PRCo) AS NUMERIC(16,5)) AS DoubleTimeRate
--,	COALESCE((
--		SELECT 
--			SUM(prcf.NewRate)
--		FROM 
--			PRCF prcf JOIN 
--			PREC prec ON 
--				prcf.PRCo=prec.PRCo 
--			AND prcf.EarnCode=prec.EarnCode	
--		WHERE
--			prcf.PRCo=prcc.PRCo
--		AND prcf.Craft=prcc.Craft
--		AND prcf.Class=prcc.Class
--		AND prec.Method='H'
--	),0) AS TotalHourAddOnAmount
--,	COALESCE((
--		SELECT 
--			SUM(prcf.NewRate)
--		FROM 
--			PRCF prcf JOIN 
--			PREC prec ON 
--				prcf.PRCo=prec.PRCo 
--			AND prcf.EarnCode=prec.EarnCode	
--		WHERE
--			prcf.PRCo=prcc.PRCo
--		AND prcf.Craft=prcc.Craft
--		AND prcf.Class=prcc.Class
--		AND prec.Method='G'
--	),0) AS TotalGrossAddOnPercent	
--,	COALESCE((
--		SELECT 
--			SUM(prcd.NewRate)
--		FROM
--		PRCD prcd LEFT OUTER JOIN 
--		PRDL prdl ON 
--			prcd.PRCo=prdl.PRCo 
--		AND prcd.DLCode=prdl.DLCode
--		WHERE 
--			prcd.PRCo=prcc.PRCo
--		AND prcd.Craft=prcc.Craft
--		AND prcd.Class=prcc.Class
--		AND prdl.Method='H'
--		AND prdl.DLType='D'
--	),0) AS TotalHourlyDeductionAmount
--,	COALESCE((
--		SELECT 
--			SUM(prcd.NewRate)
--		FROM
--		PRCD prcd LEFT OUTER JOIN
--		PRDL prdl ON 
--			prcd.PRCo=prdl.PRCo 
--		AND prcd.DLCode=prdl.DLCode
--		WHERE 
--			prcd.PRCo=prcc.PRCo
--		AND prcd.Craft=prcc.Craft
--		AND prcd.Class=prcc.Class
--		AND prdl.Method='G'
--		AND prdl.DLType='D'

--	),0) AS TotalGrossDeductionPercent
--,	COALESCE((
--		SELECT 
--			SUM(prdl.RateAmt1)
--		FROM
--		PRCD prcd LEFT OUTER JOIN 
--		PRDL prdl ON 
--			prcd.PRCo=prdl.PRCo 
--		AND prcd.DLCode=prdl.DLCode
--		WHERE 
--			prcd.PRCo=prcc.PRCo
--		AND prcd.Craft=prcc.Craft
--		AND prcd.Class=prcc.Class
--		AND prdl.Method='H'
--		AND prdl.DLType='L'
--		--AND prcd.DLCode=305
--		AND prcc.udShopYN='Y'
--	),0) AS TotalHourlyShopLiabilityAmount
--,	COALESCE((
--		SELECT 
--			SUM(prdl.RateAmt1)
--		FROM
--		PRCD prcd LEFT OUTER JOIN
--		PRDL prdl ON 
--			prcd.PRCo=prdl.PRCo 
--		AND prcd.DLCode=prdl.DLCode
--		WHERE 
--			prcd.PRCo=prcc.PRCo
--		AND prcd.Craft=prcc.Craft
--		AND prcd.Class=prcc.Class
--		AND prdl.Method='G'
--		AND prdl.DLType='L'
--		--AND prcd.DLCode=305
--		AND prcc.udShopYN='Y'
--	),0) AS TotalGrossShopLiabilityPercent	
--,	COALESCE((
--		SELECT 
--			SUM(prcd.NewRate)
--		FROM
--		PRCD prcd LEFT OUTER JOIN
--		PRDL prdl ON 
--			prcd.PRCo=prdl.PRCo 
--		AND prcd.DLCode=prdl.DLCode
--		WHERE 
--			prcd.PRCo=prcc.PRCo
--		AND prcd.Craft=prcc.Craft
--		AND prcd.Class=prcc.Class
--		AND prdl.Method='H'
--		AND prdl.DLType='L'
--		--AND prcd.DLCode=305
--		AND prcc.udShopYN<>'Y'
--	),0) AS TotalHourlyLiabilityAmount
--,	COALESCE((
--		SELECT 
--			SUM(prcd.NewRate)
--		FROM
--		PRCD prcd LEFT OUTER JOIN
--		PRDL prdl ON 
--			prcd.PRCo=prdl.PRCo 
--		AND prcd.DLCode=prdl.DLCode
--		WHERE 
--			prcd.PRCo=prcc.PRCo
--		AND prcd.Craft=prcc.Craft
--		AND prcd.Class=prcc.Class
--		AND prdl.Method='G'
--		AND prdl.DLType='L'
--		--AND prcd.DLCode=305
--		AND prcc.udShopYN='Y'
--	),0) AS TotalGrossLiabilityPercent	
--,	(SELECT LiabilityRate from JCTL WHERE JCCo=prcc.PRCo AND LiabTemplate=1 AND LiabType=5) AS BurdenRate
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
--	AND prcp.Class=prcc.Class
--WHERE
--	(prcc.Craft=@Craft OR @Craft IS NULL)
--AND (prcc.Class=@Class OR @Class IS NULL)

--GO


--SELECT TOP 10 * FROM CMS.S1017192.CMSFIL.APPOPC WHERE FSTAT='A' AND FPYSN=??

GRANT SELECT ON mvwPMCraftClassRateDetails TO PUBLIC
go

GRANT EXEC ON mspPMCraftClassRateSchedule TO PUBLIC
go



EXEC mspPMCraftClassRateSchedule 
	@Hours=1
,	@Craft=null
--	@Craft='0016.00'
,	@Class=null
--,	@Class='501PC'
--,	@Class='3500.000JR'

