SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**************************************************************************************
* CREATED BY: 	AR 12/2012
* COMMITTED BY: JR 12/2012
* MODIFIED BY:  KK 01/16/13 - D-12044/TK-20786 Changed the earn code used from timecard ec to allowance ec when getting base rate
*				KK 01/24/13 - D-12044/TK-20786 Added join on prco for vPRAllowanceRuleSet
*				KK 02/04/13 - 8166 Added allowance earncode parameter to the function call vfPRRateDefault
*
* USAGE: Called from PRProcessAllowances to get total breadth of information from 
*
* INPUT PARAMETERS
*	PRCo, PRGroup, PREndDate, Employee, PaySeq 
*  
* OUTPUT: Fills and returns temp table #TCAllowEmp for processing allowances 
*
***************************************************************************************/
CREATE proc [dbo].[vspPRLoadAllowances] (
  @PRCo bCompany
  , @PRGroup bGroup
  , @PREndDate DATETIME
  , @Employee bEmployee
  , @PaySeq TINYINT
  )
AS

IF OBJECT_ID('tempdb..#TCAllowEmp') IS NULL
BEGIN 
	RAISERROR('ERROR: This stored procedure is meant to be called from vspPRProcessAllowances where the temp table is defined.',-11,1);
END

-- Get the allowances to our time card batch to filter down our set (no sense pulling all the allowances)
-- Find all rules related to time cards distinctly (sum time for multiple time cards that apply to a rule in the same period later)
INSERT INTO #TCAllowEmp (Employee, PRCo, PREndDate, PRGroup, PaySeq, PostSeq, AllowanceTypeName, Craft, AllowanceRulesetName, AllowanceRuleName, ThresholdPeriod, IsHoliday, Threshold, PayRate, Hours, PostDate, KeyID, AllowanceEarnCode)
SELECT DISTINCT 
		-- Key on timecard: Employee, Company, End Date, Group, PaySeq and PostSeq (employee might have mulitple time cards)
		tc.Employee,
		tc.PRCo, 
		tc.PREndDate,
		tc.PRGroup,
		tc.PaySeq,
		tc.PostSeq,
		-- allowLocInfo is a selection of data from CraftMast,CraftTemp,CraftClass, or CraftClassTemp given an employee's allowance
		allowLocInfo.AllowanceTypeName,
		-- Craft needed to determine holiday
		tc.Craft, 
		-- Rule info
		vpar.AllowanceRulesetName,
		vpar.AllowanceRuleName,
		-- Rule Set info
		vpars.ThresholdPeriod, 
		vpar.Holiday AS IsHoliday,
		vpar.Threshold,
		-- Get base pay rate from function (Grouping on Shift might be a concern in the future)
		dbo.vfPRRateDefault( tc.PRCo, 
							 tc.Employee, 
							 tc.PostDate, 
							 tc.Craft,
							 tc.Class, 
							 job.CraftTemplate, 
							 tc.Shift, 
							 tc.EarnCode, -- 8166 Added to pass the TC Earn Code to the function which needs it to find pay rate
							 allowLocInfo.EarnCode) AS PayRate, --TK-20786 Use Allowance Earn Code where Factor is ALWAYS 1.0)
		-- Get additional timecard information
		tc.[Hours], 
		tc.PostDate,
		tc.KeyID,
		allowLocInfo.EarnCode AS AllowanceEarnCode
-- This table gets wittled down as we continue to eliminate ineligible allowances through processing.
FROM dbo.bPRTH tc -- Employee timecards
	-- Get Job information to determine Template
	LEFT JOIN bJCJM job ON job.Job = tc.Job AND job.JCCo = tc.JCCo
	-- Location subquery: get allowances and rulesets from CraftMast,CraftTemp,CraftClass, or CraftClassTemp
	CROSS APPLY -- Calling out table names as static in we want to JOIN to PRAllowanceTypes in the future
		(	
			-- Craft/Class allowances
			SELECT 'vPRCraftClassAllowances' AS TableName,
					vpcca.AllowanceTypeName,
					vpcca.AllowanceRulesetName,
					vpcca.EarnCode
			FROM dbo.vPRCraftClassAllowance AS vpcca
			WHERE vpcca.Class = tc.Class
				AND vpcca.Craft = tc.Craft
				AND vpcca.PRCo = tc.PRCo
											
			UNION ALL
			-- Craft Master allowances
			SELECT 'vPRCraftMasterAllowances' AS TableName,
					vpcma.AllowanceTypeName,
					vpcma.AllowanceRulesetName,
					vpcma.EarnCode
			FROM dbo.vPRCraftMasterAllowance AS vpcma
			WHERE vpcma.Craft = tc.Craft
				AND vpcma.PRCo = tc.PRCo
			
			UNION ALL
			-- Craft/Class Template allowances
			SELECT 'vPRCraftClassTemplateAllowances' AS TableName,
					vpccta.AllowanceTypeName,
					vpccta.AllowanceRulesetName,
					vpccta.EarnCode
			FROM dbo.vPRCraftClassTemplateAllowance AS vpccta
			WHERE vpccta.Class = tc.Class
				AND vpccta.Craft = tc.Craft
				AND vpccta.PRCo = tc.PRCo
				AND vpccta.Template = job.CraftTemplate
			
			UNION ALL
			-- Craft Template allowances
			SELECT 'vPRCraftTemplateAllowances' AS TableName,
					vpcta.AllowanceTypeName,
					vpcta.AllowanceRulesetName,
					vpcta.EarnCode
			FROM dbo.vPRCraftTemplateAllowance AS vpcta
			WHERE vpcta.Craft = tc.Craft
				AND vpcta.PRCo = tc.PRCo
				AND vpcta.Template = job.CraftTemplate
		) allowLocInfo
		
-- Join in rules from RuleSet header and detail (Rules)
JOIN dbo.vPRAllowanceRuleSet AS vpars 
		ON vpars.PRCo = tc.PRCo -- KK added join on PRCo
		AND allowLocInfo.AllowanceRulesetName = vpars.AllowanceRulesetName
JOIN dbo.vPRAllowanceRules AS vpar 
		ON vpar.PRCo = tc.PRCo
		AND allowLocInfo.AllowanceRulesetName = vpar.AllowanceRulesetName
-- Join in earn codes and subject earncodes
JOIN dbo.bPREC AS ec 
		ON ec.PRCo = tc.PRCo 
		AND allowLocInfo.EarnCode = ec.EarnCode
JOIN dbo.bPRES AS es 
		ON ec.PRCo = es.PRCo 
		AND ec.EarnCode = es.EarnCode
		AND es.SubjEarnCode = tc.EarnCode
						
WHERE tc.Employee = @Employee
	AND tc.PRCo = @PRCo
	AND tc.PREndDate = @PREndDate
	AND tc.PRGroup = @PRGroup
	AND tc.PaySeq = @PaySeq;
	
GO
GRANT EXECUTE ON  [dbo].[vspPRLoadAllowances] TO [public]
GO
