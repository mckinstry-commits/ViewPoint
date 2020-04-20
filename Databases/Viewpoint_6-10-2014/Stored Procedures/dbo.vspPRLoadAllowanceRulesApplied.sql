SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspPRLoadAllowanceRulesApplied]
AS
/**************************************************************************************
* CREATED BY: 		AR	 12/2012
* COMMITTED BY:		JR	 12/2012
* MODIFIED BY: KK/JR/AR	02/04/13 - 8166  Modified to account for Weekly Threshold + Hrly Award + Daily Max
*										 Added comments to code
*
* USAGE: Called from PRProcessAllowances to actually compute the allowances per each eligible rule
*		 based on the threshold exceeded on the timecard. The rate that is used to calculate
*		 the allowance award is not necessarily the rate on the timecard ne
*  
* OUTPUT: Fills and returns temp table #tmpRulesApplied for processing allowances 
*
***************************************************************************************/
DECLARE @debug BIT;
SET @debug = 1;
IF OBJECT_ID('tempdb..#tmpRulesApplied') IS NULL
OR OBJECT_ID('tempdb..#tmpEmpThresHours') IS NULL
BEGIN 
	RAISERROR('ERROR: This stored procedure is meant to be called from vspPRProcessAllowances.  vspPRProcessAllowances has the temp table definition',-11,1);
END;

/*************************************************************************
Process the rules
*************************************************************************/
-- Rate is determined based on the standard rate the employee recieves. The function that is used
-- (vfPRRateDefault) to determine this rate is based on bspPRRateDefault

INSERT INTO #tmpRulesApplied (-- First 3 rows of inputs come from #tmpEmpThresHours (eth.)
							  Employee,				PRCo,				ThresholdPeriod,	Threshold, 
							  TCGroupId,			PeriodDate,			PeriodHours,		AllowanceRuleName,
							  AllowanceRulesetName, AllowanceTypeName,	PREndDate,			PayPerWeek, 
							  
							  -- AllowanceAmount from vPRAllowanceRules: A=>Amt p/p, H=>Amt p/hr, or R=>CalcRate * Factored payrate
							  AllowanceAmount, 	
							  
							  -- AllowanceRate from vPRAllowanceRules: A=>0, H=>Amt p/hr, or R=>Factored payrate
							  AllowanceRate, 		
							  
							  -- Following 3 from vPRAllowanceRules
							  MaxAmountPeriod,	MaxAmount,	CalcMethod,			
							  -- From #tmpEmpThresHours (eth.)
							  PayRate, 
							  -- From vPRAllowanceRules
							  Factor,	RateAmount) 
SELECT	eth.Employee,
		eth.PRCo,
		eth.ThresholdPeriod,
		eth.Threshold,
		eth.TCGroupId,
		eth.PeriodDate,
		eth.PeriodHours,
		eth.AllowanceRuleName,
		eth.AllowanceRulesetName,
		eth.AllowanceTypeName,
		eth.PREndDate,
		eth.PayPerWeek,
		CASE vpar.CalcMethod
			WHEN 'A' THEN vpar.RateAmount --Amount per period
			WHEN 'H' THEN eth.PeriodHours * vpar.RateAmount --Amount per hour
			WHEN 'R' THEN ROUND(vpar.RateAmount * ISNULL(vpar.Factor,1.00) * eth.PayRate,2) -- Payrate * Calcrate * Factor, round
		END AS AllowanceAmount,
		CASE vpar.CalcMethod
			WHEN 'A' THEN 0 --No rate, amount is a flat amount
			WHEN 'H' THEN vpar.RateAmount --Rate is the amount per hour
			WHEN 'R' THEN ROUND(ISNULL(vpar.Factor,1.00) * eth.PayRate,2) -- Payrate * Factor, round
		END AS AllowanceRate,
		-- Noise for feed back so I can check data
		vpar.MaxAmountPeriod,
		vpar.MaxAmount,
		vpar.CalcMethod,
		eth.PayRate,
		vpar.Factor,
		vpar.RateAmount
		
FROM #tmpEmpThresHours eth
JOIN dbo.vPRAllowanceRules AS vpar 
	ON vpar.AllowanceRuleName = eth.AllowanceRuleName
	AND vpar.AllowanceRulesetName = eth.AllowanceRulesetName
	AND vpar.PRCo = eth.PRCo

IF @debug = 1
BEGIN
	SELECT 'RulesCalculated' AS TableName, * FROM #tmpRulesApplied AS tra ORDER BY AllowanceRuleName,PeriodDate
END

/*************** MAX Amounts **********************************/
-- First handle: Weekly(4)threshold with a Weekly Max(4), and Daily(2)threshold with a Daily Max(2)
UPDATE #tmpRulesApplied
SET AllowanceAmount = MaxAmount -- If the allowance amt (for each record) is more than the max amount, set the amt = max amt
WHERE ISNULL(MaxAmountPeriod,ThresholdPeriod) = ThresholdPeriod  
	AND AllowanceAmount > MaxAmount -- nulls removed automatically, fixed this because we were always applying
	AND MaxAmount IS NOT NULL

-- Second handle: Daily(2)threshold with a Weekly Max(4): Allowance is awarded daily until the max has been reached for the week (7 days).
UPDATE ra
SET AllowanceAmount = CASE  WHEN ISNULL(raRunTot.RunningTot,0) >= MaxAmount -- we passed the maxamount previously
								THEN 0
							WHEN (ISNULL(raRunTot.RunningTot,0) + AllowanceAmount) >= MaxAmount -- max amount met today
								THEN MaxAmount - ISNULL(raRunTot.RunningTot,0)  -- remainder to meet max amount shoved into last day
							ELSE AllowanceAmount -- keep the existing allowance amount
						END
FROM -- Get a running total to know when we excede the Max amount (@AR: "oh scott a where are you now")
	#tmpRulesApplied ra -- Filtered to a small set
	OUTER APPLY ( -- Running total of amount until previous period
					SELECT SUM(AllowanceAmount) AS RunningTot
					FROM #tmpRulesApplied raTot
					WHERE raTot.Employee = ra.Employee
						  AND raTot.PRCo = ra.PRCo
						  AND raTot.PREndDate = ra.PREndDate
						  AND raTot.AllowanceRuleName = ra.AllowanceRuleName
						  AND raTot.AllowanceRulesetName = ra.AllowanceRulesetName
						  AND raTot.AllowanceTypeName = ra.AllowanceTypeName
						  AND raTot.PeriodDate < ra.PeriodDate
						  AND raTot.PayPerWeek = ra.PayPerWeek
				) raRunTot
WHERE ra.MaxAmountPeriod = 4 -- Weekly max period
	AND ra.ThresholdPeriod = 2  -- Daily threshold rule
	AND ra.MaxAmount IS NOT NULL

-- Third handle: Weekly(4)threshold with a Daily Max(2) and Hrly Amt('H'): Amount is awarded each hr worked in the week the 
--				 threshold was met (7 days). The Daily Max is observed each day that hours were worked. Finally the amount is
--				 re-summed as AllowanceAmount.
UPDATE ra
SET AllowanceAmount = MaxAmount.MaxAmount
FROM #tmpRulesApplied ra -- Filtered to a small set
	OUTER APPLY( -- We only set Amount to the Max when the amount is greater than the max
		SELECT SUM(CASE WHEN SumDaily.Amount > SumDaily.MaxAmount THEN MaxAmount ELSE SumDaily.Amount END) AS MaxAmount
		FROM(
			SELECT hrs.PostDate
				, SUM(hrs.Hours * ra2.AllowanceRate) AS Amount
				, ra2.MaxAmount
			FROM #TCAllowEmp hrs -- To quantify by day the amount earned when comparing to max daily limit
			JOIN #tmpRulesApplied ra2 -- To get the max amount to compare within the subset table created above
				ON hrs.Employee = ra2.Employee
				AND hrs.PRCo = ra2.PRCo
				AND hrs.PREndDate = ra2.PREndDate
				AND hrs.AllowanceRuleName = ra2.AllowanceRuleName
				AND hrs.AllowanceRulesetName = ra2.AllowanceRulesetName
			JOIN dbo.bPRPC bPRPC -- Need to get Pay Period Control information to get specific week in question
			ON hrs.PRCo = bPRPC.PRCo
				AND hrs.PREndDate = bPRPC.PREndDate
				AND hrs.PRGroup = bPRPC.PRGroup
			WHERE   ra2.Employee = ra.Employee
				AND ra2.PRCo = ra.PRCo
				AND ra2.PREndDate = ra.PREndDate
				AND ra2.AllowanceRuleName = ra.AllowanceRuleName
				AND ra2.AllowanceRulesetName = ra.AllowanceRulesetName
				-- Get the specific week (0, 1, 2...etc.) in the pay period that the allowance was awarded
				AND ra2.PayPerWeek = FLOOR(DATEDIFF(day,bPRPC.BeginDate, hrs.PostDate)/7)
			GROUP BY hrs.PostDate, MaxAmount
		)SumDaily
	)MaxAmount
WHERE ra.MaxAmountPeriod = 2 -- Daily max period
	AND ra.ThresholdPeriod = 4  -- Weekly threshold rule
	AND ra.CalcMethod = 'H' -- Hourly calculation method is the only logical place this should apply ('R' and 'A' are flat amts)
	AND ra.MaxAmount IS NOT NULL;

GO
GRANT EXECUTE ON  [dbo].[vspPRLoadAllowanceRulesApplied] TO [public]
GO
