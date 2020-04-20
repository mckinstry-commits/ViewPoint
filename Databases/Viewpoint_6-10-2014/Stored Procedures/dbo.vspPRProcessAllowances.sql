SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****************************************************************************************
*  CREATED BY: AdamR 12/05/12
* MODIFIED BY:	JayR 12/07/12 - B-11193  Break code into multiple stored procedures, add error handling....
*				  KK 12/11/12 - TK-20133 Get correct allowance distributed amount column 
*				  KK 12/14/12 - TK-20133 Removed error when checking for empty PRTA as Addons may have been added.
*										 They will have different EarnCodes.
*				  KK 01/22/13 - TK-20786 Update PRTA if exists, else Insert as new record
*			      JJ 01/25/13 - 8166 Fix issue where earning code needs to be summed up and multiple rates result in 0.00 to PRTA.
*				  KK 01/30/13 - 8166 Removed PRTA update as it is handled in PRProcess
*
* USAGE: Primary procedure used to process PR Allowances for Australia. 
*		 Called from PR Process with the purpose of determining and calculating eligible allowances 
*		 and inserting the record into PRTA.
*		
*			Executes vspPRLoadALlowances, 
*					 vspPRLoadAllowanceHoursAggregated,
*					 vspPRLoadAllowanceThresHours,
*					 vspPRLoadAllowanceRulesApplied,
*					 vspPRLoadAllowanceDistrib
*															 
* INPUT PARAMETERS
*   @prco		PR Company
*   @prgroup	PR Group
*   @prenddate	PR Ending Date
*   @employee	Employee to process (null if processing all Employees)
*   @payseq		Payment Sequence #
*
****************************************************************************************/
CREATE proc [dbo].[vspPRProcessAllowances] (
    @PRCo bCompany
  , @PRGroup bGroup
  , @PREndDate DATETIME
  , @Employee bEmployee
  , @PaySeq TINYINT
  )
AS

DECLARE @debug BIT;
SET @debug = 1;
DECLARE @errmsg VARCHAR(4000);

BEGIN TRY
	/**** Temp table "#TCAllowEmp" is created here to be filled by vspPRLoadAllowances ****/
	-- This table holds ALL the allowances by rule that this employee is eligible for
	CREATE TABLE #TCAllowEmp(
		[Employee] INT NOT NULL,
		[PRCo] tinyint NOT NULL,
		[PREndDate] smalldatetime NOT NULL,
		[PRGroup] tinyint NOT NULL,
		[PaySeq] [tinyint] NOT NULL,
		[PostSeq] [smallint] NOT NULL,
		[AllowanceTypeName] [varchar](16) NOT NULL,
		[Craft] VARCHAR(10) NULL,
		[AllowanceRulesetName] [varchar](16) NOT NULL,
		[AllowanceRuleName] [varchar](16) NOT NULL,
		[ThresholdPeriod] [tinyint] NOT NULL,
		[IsHoliday] CHAR(1) NOT NULL,
		[Threshold] NUMERIC(10,2) NOT NULL,
		[PayRate] NUMERIC(16,2) NULL,
		[Hours] NUMERIC(10,2) NOT NULL,
		[PostDate] SMALLDATETIME NOT NULL,
		[KeyID] [bigint] NOT NULL,
		[AllowanceEarnCode] smallint NOT NULL,
		[Id] [int] IDENTITY(1,1) NOT NULL
	);

	-- This stored procedure loads a #TCAllowEmp with the data.
	BEGIN TRY 
		EXEC dbo.[vspPRLoadAllowances] @PRCo = @PRCo, 
									   @PRGroup = @PRGroup, 
									   @PREndDate = @PREndDate, 
									   @Employee = @Employee, 
									   @PaySeq = @PaySeq;
	END TRY
	BEGIN CATCH
		SET @errmsg = 'Error in vspPRLoadAllowances:' + ERROR_MESSAGE();
		RAISERROR(@errmsg,16,1);
	END CATCH

	IF @debug = 1 
	BEGIN
		SELECT 'TCRecwRules' AS TabName, * FROM #TCAllowEmp AS tae ORDER BY PostDate
	END;
		
	IF NOT EXISTS (SELECT 1 FROM #TCAllowEmp)
	BEGIN
		IF @debug = 1 
		BEGIN
			PRINT 'No allowances to process';
		END;
		RETURN 0;
	END
	
    ------------------------------------------------------------------------------------------------------
    
	/**** Temp table "#tmpEmpHoursAggregated" is created here to be filled by vspPRLoadAllowanceHoursAggregated ****/
	-- This table is aggregated by hours so that thresholds may be compared
	CREATE TABLE #tmpEmpHoursAggregated
	(	
		TCGroupId INT NOT NULL,
		Employee INT NOT NULL,
		PRCo TINYINT NOT NULL,
		ThresholdPeriod INT NOT NULL,
		Threshold NUMERIC(10,2) NOT NULL,
		PeriodDate DATETIME NOT NULL, -- rollup date for the threshold period (day, end of week, or holiday)
		PeriodHours NUMERIC(10,2) NOT NULL,
		AllowanceRuleName VARCHAR(16) NOT NULL,
		AllowanceRulesetName VARCHAR(16) NOT NULL,
		AllowanceTypeName VARCHAR(16) NOT NULL,
		PREndDate DATETIME NOT NULL,
		PayPerWeek INT NOT NULL, -- used for Max Amount threshold test
		PayRate NUMERIC(16,5) NULL,
		IsHoliday CHAR(1) NOT NULL, -- used for holiday threshold test
		AllowanceEarnCode SMALLINT NOT NULL,
		KeyID BIGINT NOT NULL --rename timecard keyid
	);
	-- This stored procedure loads a #tmpEmpHoursAggregated with the data.
	BEGIN TRY 
		EXEC [dbo].[vspPRLoadAllowanceHoursAggregated];
	END TRY
	BEGIN CATCH
		SET @errmsg = 'Error in vspPRLoadAllowanceHoursAggregated:' + ERROR_MESSAGE();
		RAISERROR(@errmsg,16,1);
	END CATCH

	IF @debug = 1 
	BEGIN
		SELECT 'AggregatedHoursWRules' AS TabName, * FROM #tmpEmpHoursAggregated
	END

    ------------------------------------------------------------------------------------------------------
    
	/**** Temp table "#tmpEmpThresHours" is created here to be filled by vspPRLoadAllowanceThresHours ****/
	-- This table holds rules that will take precidence within each quallifying rule set
	CREATE TABLE #tmpEmpThresHours(
		[TCGroupId] [int] NOT NULL,
		[Employee] [int] NOT NULL,
		[PRCo] [tinyint] NOT NULL,
		[ThresholdPeriod] [int] NOT NULL,
		[Threshold] [numeric](10, 2) NOT NULL,
		[PeriodDate] [datetime] NOT NULL,
		[PeriodHours] [numeric](10, 2) NOT NULL,
		[AllowanceRuleName] [varchar](16) NOT NULL,
		[AllowanceRulesetName] [varchar](16) NOT NULL,
		[AllowanceTypeName] [varchar](16) NOT NULL,
		[PREndDate] [datetime] NOT NULL,
		[PayPerWeek] [int] NOT NULL,
		[PayRate] [numeric](16, 5) NULL,
		[IsHoliday] [char](1) NOT NULL,
		[AllowanceEarnCode] [smallint] NOT NULL,
		[KeyID] [bigint] NOT NULL,
		[ThersholdImportance] [bigint] NULL -- Used to deterimine which threshold/rule takes precidence
	);
	-- This stored procedure loads a #tmpEmpThresHours with the data.
	BEGIN TRY 
		EXEC dbo.[vspPRLoadAllowanceThresHours];
	END TRY
	BEGIN CATCH
		SET @errmsg = 'Error in vspPRLoadAllowanceThresHours:' + ERROR_MESSAGE();
		RAISERROR(@errmsg,16,1);
	END CATCH

	-- get some feedback
	IF @debug = 1
	BEGIN
		SELECT 'EmployeeThresholdForCalc' AS TabName,* 
		FROM #tmpEmpThresHours 
		ORDER BY Employee,AllowanceRulesetName,PeriodDate
	END

    ------------------------------------------------------------------------------------------------------
    
	/**** Temp table "#tmpRulesApplied" is created here to be filled by vspPRLoadAllowanceRulesApplied ****/
	-- This table holds rules, and rule information where the threshold is met or exceeded
	CREATE TABLE #tmpRulesApplied(
		[Employee] [int] NOT NULL,
		[PRCo] [tinyint] NOT NULL,
		[ThresholdPeriod] [int] NOT NULL,
		[Threshold] [numeric](10, 2) NOT NULL,
		[TCGroupId] [int] NOT NULL,
		[PeriodDate] [datetime] NOT NULL,
		[PeriodHours] [numeric](10, 2) NOT NULL,
		[AllowanceRuleName] [varchar](16) NOT NULL,
		[AllowanceRulesetName] [varchar](16) NOT NULL,
		[AllowanceTypeName] [varchar](16) NOT NULL,
		[PREndDate] [datetime] NOT NULL,
		[PayPerWeek] [int] NOT NULL,
		[AllowanceAmount] [numeric](37, 12) NULL,
		[AllowanceRate] [numeric](20, 7) NULL,
		[MaxAmountPeriod] [tinyint] NULL,
		[MaxAmount] [numeric](12, 2) NULL,
		[CalcMethod] [char](1) NOT NULL,
		[PayRate] [numeric](16, 5) NULL,
		[Factor] [numeric](3, 2) NULL,
		[RateAmount] [numeric](16, 5) NOT NULL
	);
	-- This stored procedure loads a #tmpRulesApplied with the data.
	BEGIN TRY 
		EXEC dbo.[vspPRLoadAllowanceRulesApplied];
	END TRY
	BEGIN CATCH
		SET @errmsg = 'Error in vspPRLoadAllowanceRulesApplied:' + ERROR_MESSAGE();
		RAISERROR(@errmsg,16,1);
	END CATCH;

	IF @debug = 1
	BEGIN
		SELECT  'RulesWithMaxAmount' AS TableName,
				Employee,
				PeriodDate,
				PayPerWeek,
				AllowanceAmount,
				ThresholdPeriod,
				PeriodHours,
				Threshold,
				MaxAmountPeriod,
				MaxAmount,
				CalcMethod,
				AllowanceRuleName,
				AllowanceRulesetName,
				PRCo,
				PayRate,
				Factor,
				RateAmount,
				TCGroupId,
				AllowanceRate
		FROM #tmpRulesApplied
		ORDER BY Employee,AllowanceRuleName,PeriodDate
	END;

    ------------------------------------------------------------------------------------------------------
    
	/**** Temp table "#tmpDistribution" is created here to be filled by vspPRLoadAllowanceDistrib ****/
	-- This table holds amounts to be distributed to PRTA
	CREATE TABLE #tmpDistribution(
		[PRCo] [tinyint] NOT NULL,
		[Employee] [int] NOT NULL,
		[PREndDate] [smalldatetime] NOT NULL,
		[PostSeq] [smallint] NOT NULL,
		[PaySeq] [tinyint] NOT NULL,
		[PRGroup] [tinyint] NOT NULL,
		[PostDate] [smalldatetime] NOT NULL,
		[Amt] [numeric](12, 2) NOT NULL,
		[AllowanceTypeName] [varchar](16) NOT NULL,
		[AllowanceRulesetName] [varchar](16) NOT NULL,
		[AllowanceRuleName] [varchar](16) NOT NULL,
		[AllowanceTotal] [numeric](37, 12) NULL,
		[TCSumAmt] [numeric](38, 2) NULL,
		[DistAmt] [numeric](38, 6) NULL,
		[LastDayRank] [bigint] NULL,
		[TCGroupId] [int] NOT NULL,
		[AllowanceEarnCode] [smallint] NOT NULL,
		[AllowanceRate] [numeric](20, 7) NULL
	);
	-- This stored procedure loads a #tmpDistribution with the data.
	BEGIN TRY 
		EXEC dbo.[vspPRLoadAllowanceDistrib];
	END TRY
	BEGIN CATCH
		SET @errmsg = 'Error in vspPRLoadAllowanceDistrib:' + ERROR_MESSAGE();
		RAISERROR(@errmsg,16,1);
	END CATCH

	IF @debug = 1
	BEGIN
		SELECT  'Distribution after rounding' AS TableName,* FROM #tmpDistribution AS td 
		ORDER BY AllowanceRulesetName
	END;
	
	-- Debugging temp tables. 
	-- 1. Check that dbo.testDebugTmps exists in the databse of stored procs
	-- 2. Uncomment the following section by removing(or commenting out) /** and **/
	-- 3. @debug must = 1 
	-- 4. Process payroll to execute statements while the temp tables are filled with data
	-- 5. Query tables from a new window (i.e. SELECT * FROM ##TCAllowEmp)
	-- NOTE: global tables can be accessed by adding another # sign as shown above,
	--       and will be cleaned up when the viewpoint session ends.
	/**
	IF @debug = 1
	BEGIN
	  --This stored proc maps temp tables to global temp tables so that we can play with them.
		EXEC dbo.testDebugTmps '#TCAllowEmp';
		EXEC dbo.testDebugTmps '#tmpEmpHoursAggregated';
		EXEC dbo.testDebugTmps '#tmpEmpThresHours';
		EXEC dbo.testDebugTmps '#tmpRulesApplied';
		EXEC dbo.testDebugTmps '#tmpDistribution';
	END 
    **/
    
	---- We are checking for differing rates which should not happen.
	--SET @errmsg = '';
	--SELECT TOP 2 @errmsg = @errmsg + ' Amt:' + CAST(SUM(td.DistAmt) AS VARCHAR(15)) 
	--  + ' PRCo:' + CAST(td.PRCo AS VARCHAR(10))
	--  + ' PRGroup:' + CAST(td.PRGroup AS VARCHAR(10))
	--  + ' PREndDate:' + CONVERT(VARCHAR(10),td.PREndDate,101)                  
	--  + ' Employee:' + CAST(td.Employee AS VARCHAR(10))
	--  + ' PostSeq:' +  CAST(td.PostSeq AS VARCHAR(10))
	--  + ' PaySeq:' + CAST(td.PaySeq AS VARCHAR(10))
	--  + ' AllowanceEarnCode:' + CAST(td.AllowanceEarnCode AS VARCHAR(10))
	--  + ' AllowanceRate:' + CAST(td.AllowanceRate AS VARCHAR(32))
	--  + '  ' + CHAR(10) + CHAR(13)
	--FROM #tmpDistribution td
	--WHERE EXISTS
	--   (
	--   SELECT 1
	--   FROM #tmpDistribution t2
	--   WHERE t2.PRCo    = td.PRCo
	--   AND t2.PRGroup   = td.PRGroup
	--   AND t2.PREndDate = td.PREndDate
	--   AND t2.Employee  = td.Employee
	--   AND t2.PaySeq    = td.PaySeq
	--   AND t2.PostSeq   = td.PostSeq
	--   AND t2.AllowanceEarnCode  = td.AllowanceEarnCode
	--   AND t2.AllowanceRate <> td.AllowanceRate
	--   )
	--GROUP BY td.PRCo,td.PRGroup,td.PREndDate,td.Employee,td.PostSeq,td.PaySeq,td.AllowanceEarnCode, td.AllowanceRate;
	
	--IF @errmsg <> '' 
	--BEGIN
	--	RAISERROR(@errmsg,16,1);
	--END;

	-- If the record does not already exist, insert it into PRTA
	INSERT INTO bPRTA
		(PRCo
		,PRGroup
		,PREndDate
		,Employee
		,PaySeq
		,PostSeq
		,EarnCode
		,Rate
		,Amt) 
	SELECT 
		 PRCo
		,PRGroup
		,PREndDate
		,Employee
		,PaySeq
		,PostSeq
		,EarnCode
		 -- If more than one rate comes in, rate = 0
		,CASE WHEN MaxRate = MinRate THEN MaxRate ELSE 0 END
		,Amt
	FROM(
		SELECT td.PRCo
			  , td.PRGroup
			  , td.PREndDate
			  , td.Employee
			  , td.PaySeq
			  , td.PostSeq
			  , td.AllowanceEarnCode AS EarnCode
			  , MAX(td.AllowanceRate) AS MaxRate
			  , MIN(td.AllowanceRate) AS MinRate
			  -- We are summing up because you can have two different rules with the same earn code for a given allowance
			  , SUM(td.DistAmt) AS Amt  
		FROM #tmpDistribution td  
		WHERE NOT EXISTS
			(
			 SELECT 1
			 FROM bPRTA
			 WHERE bPRTA.PRCo    = td.PRCo
			 AND bPRTA.PRGroup   = td.PRGroup
			 AND bPRTA.PREndDate = td.PREndDate
			 AND bPRTA.Employee  = td.Employee
			 AND bPRTA.PaySeq    = td.PaySeq
			 AND bPRTA.PostSeq   = td.PostSeq
			 AND bPRTA.EarnCode  = td.AllowanceEarnCode
			 )
		GROUP BY td.PRCo,td.PRGroup,td.PREndDate,td.Employee,td.PostSeq,td.PaySeq,td.AllowanceEarnCode
	) xx;
		
END TRY
BEGIN CATCH
	SET @errmsg = 'Error encountered in vspPRProcessAllowances:' + ERROR_MESSAGE();
	RAISERROR(@errmsg,11,1);
END CATCH
GO
GRANT EXECUTE ON  [dbo].[vspPRProcessAllowances] TO [public]
GO
