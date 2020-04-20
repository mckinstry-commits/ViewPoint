SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspPRLoadAllowanceDistrib] 
AS
/**************************************************************************************
* CREATED BY: 	AR 12/2012
* COMMITTED BY: JR 12/2012
* MODIFIED BY: TJL 12/2012  - #130067 Tied to the EarnCode on vPRCraft......Allowances
*				KK 01/30/13 - Added comments to code 
*
* USAGE: Called from PRProcessAllowances to distribute the computed allowances to PRTA
*		 These distributed values are based on the timecard line that the threshold was achieved.
*  
* OUTPUT: Fills and returns temp table #tmpDistribution for processing allowances 
*
***************************************************************************************/
DECLARE @debug BIT;
SET @debug = 1;

IF OBJECT_ID('tempdb..#tmpEmpHoursAggregated') IS NULL
OR OBJECT_ID('tempdb..#tmpEmpThresHours') IS NULL
OR OBJECT_ID('tempdb..#tmpDistribution') IS NULL
BEGIN 
	RAISERROR('ERROR: This stored procedure is meant to be called from vspPRProcessAllowances.  vspPRProcessAllowances has the temp table definition',16,1);
END;

/*****************************************************************
Distribution - Determine and show various distribution amounts 
******************************************************************/

INSERT INTO #tmpDistribution (PRCo, Employee, PREndDate, PostSeq, PaySeq, PRGroup, PostDate, Amt, AllowanceTypeName, AllowanceRulesetName, AllowanceRuleName, AllowanceTotal, TCSumAmt, DistAmt, LastDayRank, TCGroupId, AllowanceEarnCode, AllowanceRate)
SELECT 	h.PRCo,
		h.Employee,
		h.PREndDate,
		h.PostSeq,
        h.PaySeq,
        h.PRGroup,
        h.PostDate,
        h.Amt,
        et.AllowanceTypeName,
        et.AllowanceRulesetName,
        et.AllowanceRuleName,
        -- Allowance total goes over the ruleset for the period, this will be distributed
        tra.AllowanceAmount AS AllowanceTotal,
        -- Sum the timecard amount into TCSumAmt
        SUM(h.Amt) OVER(PARTITION BY et.TCGroupId,
									 et.AllowanceTypeName, 
									 et.AllowanceRuleName,
									 et.AllowanceRulesetName,
									 h.PRCo,
									 h.PREndDate) AS TCSumAmt,
        -- Weighted average: % earned on that timecard line for the timecards in which the allowance was awarded
        --		Allowance amount awarded when the rules were applied 
		--    * Timecard amount earned / Sum of the timecard amount over the partition used for TCSumAmt above
		--    = DistAmt
        ROUND(tra.AllowanceAmount * 
				(h.Amt / 
					SUM(h.Amt) OVER(PARTITION BY et.TCGroupId,
												 et.AllowanceTypeName, 
												 et.AllowanceRuleName, 
												 et.AllowanceRulesetName,
												 h.PRCo,
												 h.PREndDate)
				)
			,2) AS DistAmt,
		-- LastDayRank is used to find the day we will use for rounding when the amounts distributed are "off"
        ROW_NUMBER() OVER(PARTITION BY et.AllowanceTypeName, 
									   et.AllowanceRulesetName,
									   h.PRCo,
									   h.PREndDate 
									   ORDER BY h.PostDate DESC) AS LastDayRank,
        et.TCGroupId,
        et.AllowanceEarnCode,
        tra.AllowanceRate
       
FROM    bPRTH h -- Timecard entry - Timecard line information
		JOIN #tmpEmpHoursAggregated AS et ON et.KeyID = h.KeyID
		JOIN #tmpEmpThresHours th ON th.TCGroupId = et.TCGroupId
								AND th.Employee = et.Employee
								AND th.AllowanceRulesetName = et.AllowanceRulesetName
								AND th.AllowanceRuleName = et.AllowanceRuleName
								AND th.AllowanceTypeName = et.AllowanceTypeName
								AND th.PRCo = et.PRCo
								AND th.PREndDate = et.PREndDate
		-- We have to sum up by Rule because we cannot distribute rate by ruleset
		JOIN #tmpRulesApplied AS tra  ON tra.Employee = et.Employee
								AND tra.AllowanceRulesetName = et.AllowanceRulesetName
								AND tra.AllowanceTypeName = et.AllowanceTypeName
								AND tra.AllowanceRuleName = et.AllowanceRuleName
								AND tra.PRCo = et.PRCo
								AND tra.PREndDate = et.PREndDate
								AND tra.TCGroupId = et.TCGroupId
WHERE	h.Amt <> 0 -- #130067

IF @debug = 1
BEGIN
	SELECT  'Distribution before rounding' AS TableName,* FROM #tmpDistribution AS td ORDER BY AllowanceRuleName, AllowanceRulesetName
END
 
-- Fix the rounding issues using the last day from the previous query
UPDATE d
-- Add the difference between the allowance total and the total distributed to the last day
SET DistAmt = DistAmt + (d.AllowanceTotal - TotalDist.TotalDist)
FROM #tmpDistribution d
	-- Subquery to get max distribution amounts
	CROSS APPLY (	SELECT SUM(DistAmt) AS TotalDist 
					FROM #tmpDistribution
					WHERE AllowanceRulesetName = d.AllowanceRulesetName
						AND AllowanceTypeName = d.AllowanceTypeName
						AND AllowanceRuleName = d.AllowanceRuleName
						AND PRCo = d.PRCo
						AND Employee = d.Employee
						AND PREndDate = d.PREndDate
						AND TCGroupId = d.TCGroupId
				) AS TotalDist
WHERE d.LastDayRank = 1
	AND TotalDist.TotalDist <> d.AllowanceTotal;
-- Return to PRProcessAllowances to record the values in PRTA. 
-- NOTE: Modifications were made to PRProcessAllowances correct errors this distribution table returned to PRTA
GO
GRANT EXECUTE ON  [dbo].[vspPRLoadAllowanceDistrib] TO [public]
GO
