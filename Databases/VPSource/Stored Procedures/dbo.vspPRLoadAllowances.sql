
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspPRLoadAllowances] (@PRCo bCompany, @PRGroup bGroup, @PREndDate DATETIME, @Employee bEmployee, @PaySeq TINYINT)
AS
/**************************************************************************************
* CREATED BY: 	AR 12/2012
* COMMITTED BY: JR 12/2012
* MODIFIED BY:  KK 01/16/13 - D-12044/TK-20786 Changed the earn code used from timecard ec to allowance ec when getting base rate
*				KK 01/24/13 - D-12044/TK-20786 Added join on prco for vPRAllowanceRuleSet
*				KK 04/12/13 - 45623 Modified call to RateDefault function. No need to pass EarnCode/Factor in modified function.
*
* USAGE: Called from PRProcessAllowances to get total breadth of information. This gets all possible allowances eligible for 
*		 each line on a given timecard for an employee. This information is in it's most raw unflitered state. Each record
*		 in this temp table will have it's own individual timecard line information, rate and allowance rule/ruleset, 
*		 EarnCode and threshold to be aggregated, filtered, applied and distributed. This table gets wittled down as we continue 
*		 to eliminate ineligible allowances through processing.
*
* INPUT PARAMETERS
*		PRCo, PRGroup, PREndDate, Employee, PaySeq 
*  
* OUTPUT: Fills and returns temp table #TCAllowEmp for processing allowances 
*
***************************************************************************************/
-- Make sure that the temp tables need for this procedure exist at this instance.
IF OBJECT_ID('tempdb..#TCAllowEmp') IS NULL
BEGIN 
	RAISERROR('ERROR: This stored procedure is meant to be called from vspPRProcessAllowances where the temp table is defined.',-11,1);
END

-- Get the allowances for our time card batch to filter down our set: Find all rules related to time cards distinctly
INSERT INTO #TCAllowEmp (Employee, PRCo, PREndDate, PRGroup, PaySeq, PostSeq, AllowanceTypeName, Craft, AllowanceRulesetName, AllowanceRuleName, ThresholdPeriod, IsHoliday, Threshold, PayRate, Hours, PostDate, KeyID, AllowanceEarnCode)
SELECT DISTINCT 
		-- Key on timecard: Employee, Company, End Date, Group, PaySeq and PostSeq (employee might have mulitple time cards)
		tc.Employee,
		tc.PRCo, 
		tc.PREndDate,
		tc.PRGroup,
		tc.PaySeq,
		tc.PostSeq,
		-- allowLocInfo:
		allowLocInfo.AllowanceTypeName,
		-- Timecard: Craft
		tc.Craft, 
		-- Rule: RuleSet Name, Rule Name
		vpar.AllowanceRulesetName,
		vpar.AllowanceRuleName,
		-- RuleSet: ThresholdPeriod
		vpars.ThresholdPeriod, 
		-- Rule: Holiday Y/N, Threshold
		vpar.Holiday AS IsHoliday,
		vpar.Threshold,
		-- Get base pay rate from function: Using the "Shift" declared at the allowance location
		dbo.vfPRRateDefault( tc.PRCo, --45623 Modified PRRateDefault, no need for EarnCode or Factor
							 tc.Employee, 
							 tc.PostDate, 
							 tc.Craft,
							 tc.Class, 
							 job.CraftTemplate, 
							 -- 46570 Use shift set at the allowance location if one exists, otherwise use timecard line Shift
							 CASE WHEN allowLocInfo.ShiftRateOverride IS NOT NULL
								  THEN allowLocInfo.ShiftRateOverride
								  ELSE tc.Shift END
			) AS PayRate, 					
		-- Get additional timecard information
		tc.[Hours],  
		tc.PostDate,
		tc.KeyID,
		allowLocInfo.EarnCode AS AllowanceEarnCode

FROM dbo.bPRTH tc -- Employee timecards
	-- Get Job information to determine Template
	LEFT JOIN bJCJM job ON job.Job = tc.Job AND job.JCCo = tc.JCCo
	-- Location subquery: Get allowances and rulesets from CraftMast, CraftTemp, CraftClass, or CraftClassTemp 
	--					  given an employee's Craft/Class/Job-Template
	CROSS APPLY -- Calling out table names as static in we want to JOIN to PRAllowanceTypes in the future
		(	
			-- Craft/Class allowances
			SELECT 'vPRCraftClassAllowances' AS TableName,
					vpcca.AllowanceTypeName,
					vpcca.AllowanceRulesetName,
					vpcca.EarnCode,
					vpcca.ShiftRateOverride 
			FROM dbo.vPRCraftClassAllowance AS vpcca
			WHERE vpcca.Class = tc.Class
				AND vpcca.Craft = tc.Craft
				AND vpcca.PRCo = tc.PRCo
											
			UNION ALL
			-- Craft Master allowances
			SELECT 'vPRCraftMasterAllowances' AS TableName,
					vpcma.AllowanceTypeName,
					vpcma.AllowanceRulesetName,
					vpcma.EarnCode,
					vpcma.ShiftRateOverride 
			FROM dbo.vPRCraftMasterAllowance AS vpcma
			WHERE vpcma.Craft = tc.Craft
				AND vpcma.PRCo = tc.PRCo
			
			UNION ALL
			-- Craft/Class Template allowances
			SELECT 'vPRCraftClassTemplateAllowances' AS TableName,
					vpccta.AllowanceTypeName,
					vpccta.AllowanceRulesetName,
					vpccta.EarnCode,
					vpccta.ShiftRateOverride 
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
					vpcta.EarnCode,
					vpcta.ShiftRateOverride 
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
