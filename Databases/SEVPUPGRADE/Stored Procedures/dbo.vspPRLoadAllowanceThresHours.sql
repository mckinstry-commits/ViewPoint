SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[vspPRLoadAllowanceThresHours] 
AS
/**************************************************************************************
* CREATED BY: 	AR 12/2012
* COMMITTED BY: JR 12/2012
* MODIFIED BY:  KK 01/30/13 - 8166  Added comments to code
*
* USAGE: Called from PRProcessAllowances to filter the allowance rules that apply with respect
*		 to timecard hours and thresholds. The eligible threshold with the highest weight will have position 1.
*  
* OUTPUT: Fills and returns temp table #tmpEmpThresHours for processing allowances 
*
***************************************************************************************/
IF OBJECT_ID('tempdb..#tmpEmpThresHours') IS NULL
OR OBJECT_ID('tempdb..#tmpEmpHoursAggregated') IS NULL
BEGIN 
	RAISERROR('ERROR: This stored procedure is meant to be called from vspPRProcessAllowances.  vspPRProcessAllowances has the temp table definition',-11,1);
END;

INSERT INTO #tmpEmpThresHours(
		TCGroupId,				Employee,				PRCo,		
		ThresholdPeriod,		Threshold,				PeriodDate, 
		PeriodHours,			AllowanceRuleName,		AllowanceRulesetName, 
		AllowanceTypeName,		PREndDate,				PayPerWeek, 
		PayRate,				IsHoliday,				AllowanceEarnCode, 
		KeyID,					ThersholdImportance)
		
SELECT  a.TCGroupId,			a.Employee,				a.PRCo, 
		a.ThresholdPeriod,		a.Threshold,			a.PeriodDate, 
		a.PeriodHours,			a.AllowanceRuleName,	a.AllowanceRulesetName, 
		a.AllowanceTypeName,	a.PREndDate,			a.PayPerWeek, 
		a.PayRate,				a.IsHoliday,			a.AllowanceEarnCode, 
		a.KeyID,				a.ThersholdImportance
FROM -- Sort rules based on the importance/highest threshold of rules to enable filtering
	(
		SELECT *
			,ROW_NUMBER() OVER (PARTITION BY	AllowanceRulesetName,
												AllowanceTypeName,
												PREndDate,
												PRCo,
												Employee,
												PeriodDate
							ORDER BY	IsHoliday DESC, -- Y overrides N, Holiday takes precidence
										Threshold DESC) AS ThersholdImportance -- Then by greatest threshold
		FROM #tmpEmpHoursAggregated
		WHERE PeriodHours >= Threshold -- Filter rows that don't meet a threshold
	) a
WHERE a.ThersholdImportance = 1  -- Take the top threshold
GO
GRANT EXECUTE ON  [dbo].[vspPRLoadAllowanceThresHours] TO [public]
GO
