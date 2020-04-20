
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspPRLoadAllowanceHoursAggregated] 
AS
/**************************************************************************************
* CREATED BY: 	AR 12/2012
* COMMITTED BY: JR 12/2012
* MODIFIED BY:  KK 12/2012  - TK-20693  Craft will never be null when checking for PRHD is holiday checked
*				KK 01/30/13 - TFS-8166  Added comments to code
*				KK 04/28/13 - TFS-46570 Modified such that the max pay rate is taken when multiple timecard lines are used to evaluate a threshold
*				KK 05/08/13 - TFS-46570 Changed the period of the partition to get the max rate value for Weekly
*
* USAGE: Called from PRProcessAllowances to filter the allowance
*		 Based on threshold 1. Hourly - not in use, 2. Daily - with a holiday type, 3. Not in use  4. Weekly
*
* OUTPUT: Fills and returns temp table #tmpEmpHoursAggregated for processing allowances 
*
***************************************************************************************/
IF OBJECT_ID('tempdb..#tmpEmpHoursAggregated') IS NULL
OR OBJECT_ID('tempdb..#TCAllowEmp') IS NULL 
BEGIN 
	RAISERROR('ERROR: This stored procedure is meant to be called from vspPRProcessAllowances.  vspPRProcessAllowances has the temp table definition',-11,1);
END

/*************************************************************
Sum up the Time Cards by rule and elminate non-threshold rules
**************************************************************/

/************ Daily (2) - Holiday as an attribute **************/
INSERT INTO #tmpEmpHoursAggregated
			 (TCGroupId,
			  Employee,
			  PRCo,
			  ThresholdPeriod,
			  Threshold,
			  PeriodDate,
			  PeriodHours,
			  AllowanceRuleName,
			  AllowanceRulesetName,
			  AllowanceTypeName,
			  PREndDate,
			  PayPerWeek,
			  PayRate,
			  IsHoliday,
			  KeyID,
			  AllowanceEarnCode)
-- Unpivot time cards detail and verify hours per day against threshold
-- The following query = total hours per day for any days that are part of a rule
SELECT 
	-- Build a group Id to identify consoldiated time cards
		MAX(tae.Id)
		OVER(PARTITION BY 
			 tae.PRCo
			,tae.Threshold
			,tae.ThresholdPeriod
			,tae.AllowanceRuleName
			,tae.AllowanceRulesetName
			,tae.AllowanceTypeName
			,tae.PostDate
			,tae.Employee
			,tae.PREndDate
	)AS TimecardGroupID,
	tae.Employee,
	tae.PRCo,
	tae.ThresholdPeriod,
	tae.Threshold,
	tae.PostDate,
	-- Sum up timecards already broken out by rule
		SUM(tae.Hours) 
		OVER(PARTITION BY 
			 tae.PRCo
			,tae.Threshold
			,tae.ThresholdPeriod
			,tae.AllowanceRuleName
			,tae.AllowanceRulesetName
			,tae.AllowanceTypeName
			,tae.PostDate
			,tae.Employee
			,tae.PREndDate
	)AS PeriodHours,
	tae.AllowanceRuleName,
	tae.AllowanceRulesetName,
	tae.AllowanceTypeName,
	tae.PREndDate,
	-- Get the Pay Period Week
	FLOOR(DATEDIFF(day,PayPer.BeginDate, tae.PostDate)/7),
	-- Get the max payrate for each group of timecards being evaluated together against a threshold
		(MAX (tae.PayRate)
		 OVER(PARTITION BY 
			  tae.PRCo
			 ,tae.Threshold
			 ,tae.ThresholdPeriod
			 ,tae.AllowanceRuleName
			 ,tae.AllowanceRulesetName
			 ,tae.AllowanceTypeName
			 ,tae.PostDate
			 ,tae.Employee
			 ,tae.PREndDate)
	)AS MaxPayRate,
	-- Set the holiday flag for evaluation when the rule is applied
	CASE WHEN HolidayCheck.Holiday IS NOT NULL AND tae.IsHoliday = 'Y' THEN 'Y' ELSE 'N' END, -- Is Holiday
	tae.KeyID,
	tae.AllowanceEarnCode
FROM #TCAllowEmp tae
	-- Join in pay period to get an offset for figuring out the week
	JOIN dbo.bPRPC AS PayPer ON PayPer.PRCo = tae.PRCo
							AND PayPer.PREndDate = tae.PREndDate
							AND PayPer.PRGroup = tae.PRGroup
	-- Sub query (OUTER APPLY): One to pivot the dates, the other joins PRTH temp table to them...
	OUTER APPLY 
	(	SELECT 
			dw.AllowanceRuleName,
			dw.DayOfWeekValue,
			dw.Threshold,
			dw.DayOfWeek
		FROM dbo.vPRAllowanceRules AS vpar
			-- Unflatten the days
			UNPIVOT (DayOfWeekValue FOR DayOfWeek IN (DayOfWeekMonday
													 ,DayOfWeekTuesday
													 ,DayOfWeekWednesday
													 ,DayOfWeekThursday
													 ,DayOfWeekFriday
													 ,DayOfWeekSaturday
													 ,DayOfWeekSunday)) AS dw
		WHERE dw.DayOfWeekValue = 'Y' -- Only care where the rule is active for that day
			AND dw.AllowanceRuleName = tae.AllowanceRuleName
			AND dw.AllowanceRulesetName = tae.AllowanceRulesetName
			AND dw.PRCo = tae.PRCo
	) AS a 
	-- Is this day a holiday?
	OUTER APPLY 
	(   -- Holiday from Pay Period Control ONLY where "Apply to craft" is checked
		SELECT CONVERT(INT,1) AS Holiday
		FROM dbo.bPRHD AS CntHol 
		WHERE tae.PRCo = CntHol.PRCo
				AND tae.PREndDate = CntHol.PREndDate
				AND tae.PRGroup = CntHol.PRGroup
				AND tae.PostDate = CntHol.Holiday
				AND CntHol.ApplyToCraft = 'Y' 
		UNION
		-- Holiday from Craft Master (ALL emps that qualify for allowances will have a Craft Master entry)
		SELECT CONVERT(INT,1)
		FROM dbo.bPRCH AS CntHol 
		WHERE CntHol.PRCo = tae.PRCo
				AND CntHol.Craft = tae.Craft
				AND CntHol.Holiday = tae.PostDate

	) AS HolidayCheck
WHERE	tae.ThresholdPeriod = 2 -- Threshold period is "Daily"
		AND
		(	-- Line up days that were unpivoted above and/or check for holiday
			RIGHT(a.DayOfWeek, LEN(a.DayOfWeek)-9) = dbo.vfDayOfWeekAsString(tae.PostDate)
			OR (HolidayCheck.Holiday IS NOT NULL AND tae.IsHoliday = 'Y')
		)
			
/************ Weekly (4) **************/
INSERT INTO #tmpEmpHoursAggregated
			 (TCGroupId, 
			  Employee,
			  PRCo,
			  ThresholdPeriod,
			  Threshold,
			  PeriodDate,
			  PeriodHours,
			  AllowanceRuleName,
			  AllowanceRulesetName,
			  AllowanceTypeName,
			  PREndDate,
			  PayPerWeek,
			  PayRate,
			  IsHoliday,
			  KeyID,
			  AllowanceEarnCode)
SELECT	
	-- Build a group Id to identify consoldiated time cards
		MAX(tae.Id)
		OVER(PARTITION BY 
			 tae.PRCo
			,tae.Threshold
			,tae.ThresholdPeriod
			,tae.AllowanceRuleName
			,tae.AllowanceRulesetName
			,tae.AllowanceTypeName
			,FLOOR(DATEDIFF(day,PayPer.BeginDate, tae.PostDate)/7)
			,tae.Employee
			,tae.PREndDate
	)AS TimecardGroupID,
	tae.Employee,
	tae.PRCo,
	tae.ThresholdPeriod,
	tae.Threshold,
	-- Group by pay week: Difference in weeks + begin date
	-- Then convert to date and put it in Period Date
	DATEADD(week,FLOOR(DATEDIFF(day,PayPer.BeginDate, tae.PostDate)/7),PayPer.BeginDate) AS WeekInPayPer,
	-- Sum up timecards already broken out by rule
		SUM(tae.Hours) 
		OVER(PARTITION BY 
			 tae.PRCo
			,tae.Threshold
			,tae.ThresholdPeriod
			,tae.AllowanceRuleName
			,tae.AllowanceRulesetName
			,tae.AllowanceTypeName
			,FLOOR(DATEDIFF(day,PayPer.BeginDate, tae.PostDate)/7)
			,tae.Employee
			,tae.PREndDate
	)AS PeriodHours,
	tae.AllowanceRuleName,
	tae.AllowanceRulesetName,
	tae.AllowanceTypeName,
	tae.PREndDate,
	FLOOR(DATEDIFF(day,PayPer.BeginDate, tae.PostDate)/7),
	-- Get the max payrate for each group of timecards being evaluated together against a threshold
		(MAX (tae.PayRate)
		 OVER(PARTITION BY 
			  tae.PRCo
			 ,tae.Threshold
			 ,tae.ThresholdPeriod
			 ,tae.AllowanceRuleName
			 ,tae.AllowanceRulesetName
			 ,tae.AllowanceTypeName
			 ,FLOOR(DATEDIFF(day,PayPer.BeginDate, tae.PostDate)/7)
			 ,tae.Employee
			 ,tae.PREndDate)
	)AS MaxPayRate,
	'N', -- NOTE: Weekly has no holidays
	tae.KeyID,
	tae.AllowanceEarnCode
FROM #TCAllowEmp tae
	-- Join in the pay period to get an offset when figuring out weeks
	JOIN dbo.bPRPC AS PayPer ON PayPer.PRCo = tae.PRCo
								AND PayPer.PREndDate = tae.PREndDate
								AND PayPer.PRGroup = tae.PRGroup
WHERE tae.ThresholdPeriod = 4; -- Threshold period 4 is "Weekly"
GO


GRANT EXECUTE ON  [dbo].[vspPRLoadAllowanceHoursAggregated] TO [public]
GO
