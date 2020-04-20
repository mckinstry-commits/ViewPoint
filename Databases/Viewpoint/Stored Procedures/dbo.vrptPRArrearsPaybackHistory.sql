SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vrptPRArrearsPaybackHistory]
(
	@PRCo							bCompany,
	@PRGroup						smallint		= -1, --Since 0 is an allowed value for PRGroup in V6, use -1 as default, meaning "select all rows"
	@BeginningEmployee				bEmployee		= 0,
	@EndingEmployee					bEmployee		= 2147483647,
	@DeductionCodes					varchar(200)	= '',
	@BeginningDate					bDate			= '1950-01-01',
	@EndingDate						bDate			= '2050-12-31',
	@IncludeEmpDednBelowThreshold	bYN				= 'N'
)

AS

/**************************************************************************************

Author:			Czeslaw
Date Created:	08/22/2012
Reports:		PR Arrears/Payback History (PRArrearsPaybackHistory.rpt)

Purpose:		Returns life-to-date arrears balance information for any 
				employee/DLCode combination that has a non-zero balance or has any
				arrears or payback activity within the specified date range. If the
				employee/DLCode combination does have activity within the range, then
				that detail is included.

Revision History      
Date	Author	Issue	Description

**************************************************************************************/

SET NOCOUNT ON

/* Create temp table to hold values for final selection */

CREATE TABLE dbo.#TempTablePRArrearsPayback
(
	[PRCo]							tinyint,		--bCompany
	[CompanyName]					varchar(60),
	[PRGroup_Employee]				tinyint,		--bGroup
	[Employee]						int,			--bEmployee
	[EmployeeNameLast]				varchar(30),
	[EmployeeNameFirst]				varchar(30),
	[EmployeeNameMid]				varchar(15),
	[EmployeeNameSuffix]			varchar(4),
	[DLCode]						smallint,		--bEDLCode
	[DLCodeDescription]				varchar(30),	--bDesc
	[LifeToDateArrears]				numeric(12,2),	--bDollar
	[LifeToDatePayback]				numeric(12,2),	--bDollar
	[LifeToDateBalance]				numeric(12,2),	--bDollar
	[Date]							smalldatetime,	--bDate
	[Seq]							smallint,
	[ArrearsAmt]					numeric(12,2),	--bDollar
	[PaybackAmt]					numeric(12,2),	--bDollar
	[PRGroup_Activity]				tinyint,		--bGroup
	[PREndDate]						smalldatetime,	--bDate
	[PaySeq]						tinyint,
	[Memo]							varchar(max),
	[SimpleDednAmount]				numeric(16,5),	--bUnitCost
	[UseThresholdOverride]			char(1),		--bYN
	[RptArrearsThresholdOverride]	char(1),
	[ThresholdFactorOverride]		numeric(8,6),	--bRate
	[ThresholdAmountOverride]		numeric(12,2),	--bDollar
	[RptArrearsThreshold]			char(1),
	[ThresholdFactor]				numeric(8,6),	--bRate
	[ThresholdAmount]				numeric(12,2),	--bDollar
	[ThresholdAmountEffective]		numeric(12,2)	--bDollar
)


/* Insert initial rows (primarily from PRED) into temp table, selecting on all parameters except @IncludeEmpDednBelowThreshold */

INSERT INTO dbo.#TempTablePRArrearsPayback 
(
	[PRCo],
	[CompanyName],
	[PRGroup_Employee],
	[Employee],
	[EmployeeNameLast],
	[EmployeeNameFirst],
	[EmployeeNameMid],
	[EmployeeNameSuffix],
	[DLCode],
	[DLCodeDescription],
	[LifeToDateArrears],
	[LifeToDatePayback],
	[LifeToDateBalance],
	[Date],
	[Seq],
	[ArrearsAmt],
	[PaybackAmt],
	[PRGroup_Activity],
	[PREndDate],
	[PaySeq],
	[Memo],
	[SimpleDednAmount],
	[UseThresholdOverride],
	[RptArrearsThresholdOverride],
	[ThresholdFactorOverride],
	[ThresholdAmountOverride],
	[RptArrearsThreshold],
	[ThresholdFactor],
	[ThresholdAmount],
	[ThresholdAmountEffective]
)
SELECT
	'PRCo'							= PRED.PRCo,
	'CompanyName'					= HQCO.Name,
	'PRGroup_Employee'				= PREH.PRGroup,
	'Employee'						= PRED.Employee,
	'EmployeeNameLast'				= PREH.LastName,
	'EmployeeNameFirst'				= PREH.FirstName,
	'EmployeeNameMid'				= PREH.MidName,
	'EmployeeNameSuffix'			= PREH.Suffix,
	'DLCode'						= PRED.DLCode,
	'DLCodeDescription'				= PRDL.[Description],
	'LifeToDateArrears'				= PRED.LifeToDateArrears,
	'LifeToDatePayback'				= PRED.LifeToDatePayback,
	'LifeToDateBalance'				= (PRED.LifeToDateArrears - PRED.LifeToDatePayback),
	'Date'							= PRArrears.[Date],
	'Seq'							= PRArrears.Seq,
	'ArrearsAmt'					= PRArrears.ArrearsAmt,
	'PaybackAmt'					= PRArrears.PaybackAmt,
	'PRGroup_Activity'				= PRArrears.PRGroup,
	'PREndDate'						= PRArrears.PREndDate,
	'PaySeq'						= PRArrears.PaySeq,
	'Memo'							= PRArrears.Memo,
	'SimpleDednAmount'				= CASE WHEN PRED.OverCalcs = 'N' THEN PRDL.RateAmt1 ELSE ISNULL(PRED.RateAmt,0) END,
	'UseThresholdOverride'			= PRED.OverrideStdArrearsThreshold,
	'RptArrearsThresholdOverride'	= PRED.RptArrearsThresholdOverride,
	'ThresholdFactorOverride'		= PRED.ThresholdFactorOverride,
	'ThresholdAmountOverride'		= PRED.ThresholdAmountOverride,
	'RptArrearsThreshold'			= PRDL.RptArrearsThreshold,
	'ThresholdFactor'				= PRDL.ThresholdFactor,
	'ThresholdAmount'				= PRDL.ThresholdAmount,
	'ThresholdAmountEffective'		= NULL
FROM dbo.PRED PRED
JOIN dbo.HQCO HQCO ON HQCO.HQCo = PRED.PRCo
JOIN dbo.PREH PREH ON PREH.PRCo = PRED.PRCo AND PREH.Employee = PRED.Employee
JOIN dbo.PRDL PRDL ON PRDL.PRCo = PRED.PRCo AND PRDL.DLCode = PRED.DLCode
LEFT JOIN dbo.PRArrears PRArrears ON PRArrears.PRCo = PRED.PRCo AND PRArrears.Employee = PRED.Employee AND PRArrears.DLCode = PRED.DLCode
	--Include PRArrears activity detail in row only if activity occurs within specified date range
	AND PRArrears.[Date] BETWEEN @BeginningDate AND @EndingDate
WHERE PRED.PRCo = @PRCo
--If user supplies no value for parameter @PRGroup (resulting in default value -1 from Crystal), then include employees from all PRGroups
AND (CASE WHEN @PRGroup <> -1 THEN PREH.PRGroup ELSE -2 END) = (CASE WHEN @PRGroup <> -1 THEN @PRGroup ELSE -2 END)
--If user supplies no value for parameters @BeginningEmployee and @EndingEmployee, then include all employees based on default values from Crystal
AND PRED.Employee BETWEEN @BeginningEmployee AND @EndingEmployee
--If user supplies no value for parameter @DeductionCodes, then include any DLCode; otherwise, include current row if its DLCode occurs in user-supplied parameter value
--Note that user may supply a comma-separated list of multiple DLCodes for parameter @DeductionCodes
AND (CASE WHEN @DeductionCodes <> '' THEN CHARINDEX(','+CONVERT(varchar(5),PRED.DLCode)+',',','+REPLACE(@DeductionCodes,' ','')+',') ELSE 1 END) > 0
--Include row if current life-to-date balance for emp/DLCode is not zero, or if row represents arrears or payback activity within specified date range
AND ((PRED.LifeToDateArrears - PRED.LifeToDatePayback) <> 0 OR PRArrears.[Date]	BETWEEN @BeginningDate AND @EndingDate)


/* For each emp/DLCode row, calculate the effective threshold amount value, and update temp table */

DECLARE @Company bCompany, @Employee bEmployee, @DLCode bEDLCode
DECLARE @SimpleDednAmount bUnitCost, @UseThresholdOverride bYN
DECLARE @RptArrearsThresholdOverride char(1), @ThresholdFactorOverride bRate, @ThresholdAmountOverride bDollar
DECLARE @RptArrearsThreshold char(1), @ThresholdFactor bRate, @ThresholdAmount bDollar

DECLARE @ThresholdAmountEffective bDollar
SELECT @ThresholdAmountEffective = 0

DECLARE ArrearsThresholdCursor CURSOR LOCAL FAST_FORWARD FOR
	SELECT PRCo, Employee, DLCode, SimpleDednAmount, UseThresholdOverride, 
		RptArrearsThresholdOverride, ThresholdFactorOverride, ThresholdAmountOverride, RptArrearsThreshold, ThresholdFactor, ThresholdAmount
	FROM dbo.#TempTablePRArrearsPayback

OPEN ArrearsThresholdCursor
FETCH NEXT FROM ArrearsThresholdCursor INTO @Company, @Employee, @DLCode, @SimpleDednAmount, @UseThresholdOverride, 
	@RptArrearsThresholdOverride, @ThresholdFactorOverride, @ThresholdAmountOverride, @RptArrearsThreshold, @ThresholdFactor, @ThresholdAmount

WHILE @@fetch_status = 0
	BEGIN
	
		/* Calculate amount where employee-level override setup (in PRED) is in effect */
		IF @UseThresholdOverride = 'Y'
			BEGIN
				IF @RptArrearsThresholdOverride = 'F'  --Factor
					BEGIN
						SELECT @ThresholdAmountEffective = (@SimpleDednAmount * @ThresholdFactorOverride)
					END
				ELSE IF @RptArrearsThresholdOverride = 'A'  --Amount
					BEGIN
						SELECT @ThresholdAmountEffective = @ThresholdAmountOverride
					END
			END

		/* Calculate amount where deduction-level standard setup (in PRDL) is in effect */
		ELSE
			BEGIN
				IF @RptArrearsThreshold = 'F'  --Factor
					BEGIN
						SELECT @ThresholdAmountEffective = (@SimpleDednAmount * @ThresholdFactor)
					END
				ELSE IF @RptArrearsThreshold = 'A'  --Amount
					BEGIN
						SELECT @ThresholdAmountEffective = @ThresholdAmount
					END
			END

		/* Update temp table with calculated amount */
		UPDATE dbo.#TempTablePRArrearsPayback
		SET ThresholdAmountEffective = @ThresholdAmountEffective
		WHERE PRCo = @Company AND Employee = @Employee AND DLCode = @DLCode
		
		/* Re-initialize variables */
		SELECT @ThresholdAmountEffective = 0
		
		/* Retrieve next row from cursor */
		FETCH NEXT FROM ArrearsThresholdCursor INTO @Company, @Employee, @DLCode, @SimpleDednAmount, @UseThresholdOverride, 
			@RptArrearsThresholdOverride, @ThresholdFactorOverride, @ThresholdAmountOverride, @RptArrearsThreshold, @ThresholdFactor, @ThresholdAmount
		
	END

CLOSE ArrearsThresholdCursor
DEALLOCATE ArrearsThresholdCursor


/* Final selection for report, selecting on parameter @IncludeEmpDednBelowThreshold */

SELECT
	[PRCo],
	[CompanyName],
	--[PRGroup_Employee],				--Column not used in Crystal file
	[Employee],
	[EmployeeNameLast],
	[EmployeeNameFirst],
	[EmployeeNameMid],
	[EmployeeNameSuffix],
	[DLCode],
	[DLCodeDescription],
	[LifeToDateArrears],
	[LifeToDatePayback],
	[LifeToDateBalance],
	[Date],
	[Seq],
	[ArrearsAmt],
	[PaybackAmt],
	[PRGroup_Activity],
	[PREndDate],
	[PaySeq],
	[Memo]--,
	--[SimpleDednAmount],				--Column not used in Crystal file
	--[UseThresholdOverride],			--Column not used in Crystal file
	--[RptArrearsThresholdOverride],	--Column not used in Crystal file
	--[ThresholdFactorOverride],		--Column not used in Crystal file
	--[ThresholdAmountOverride],		--Column not used in Crystal file
	--[RptArrearsThreshold],			--Column not used in Crystal file
	--[ThresholdFactor],				--Column not used in Crystal file
	--[ThresholdAmount],				--Column not used in Crystal file
	--[ThresholdAmountEffective]		--Column not used in Crystal file
FROM dbo.#TempTablePRArrearsPayback
WHERE (CASE WHEN @IncludeEmpDednBelowThreshold = 'N' THEN LifeToDateBalance ELSE ThresholdAmountEffective END) >= ThresholdAmountEffective

DROP TABLE dbo.#TempTablePRArrearsPayback
GO
GRANT EXECUTE ON  [dbo].[vrptPRArrearsPaybackHistory] TO [public]
GO
