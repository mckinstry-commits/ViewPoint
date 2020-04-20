SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.vspPRAUPAYGGenerateAllEmployees    Script Date: 8/28/99 9:33:18 AM ******/
CREATE  PROC [dbo].[vspPRAUPAYGGenerateAllEmployees]
/***********************************************************/
-- CREATED BY: EN 3/19/2011
-- MODIFIED BY: 
--
-- USAGE:
-- Initializes the PAYG ATO/Super and Misc Amounts for all employees with accumulations in PREA for the tax year.
-- This procedure determines the employees to update then calls vspPRAUPAYGEmployeeAmountsGenerate for each employee.
--
-- INPUT PARAMETERS
--   @PRCo		PR Company
--   @TaxYear	Tax Year
--	 @OverwriteYN	Y = All employees will be included in generate ... any existing partial summaries with End Date 
--						of 6/30/TaxYear will be overwritten
--					N = Only employees w/o partial summaries with End Date of 6/30/TaxYear will be included in generate
--
-- OUTPUT PARAMETERS
--   @Message	Error message if error occurs	
--
-- RETURN VALUE
--   0			Success
--   1			Failure
--
-- TEST HARNESS
--
-- DECLARE	@ReturnCode int,
--			@Message varchar(60)

-- EXEC		@ReturnCode = [dbo].[vspPRAUPAYGGenerateAllEmployees]
--			@PRCo = 204,
--			@TaxYear = '2010',
--			@OverwriteYN = 'Y',
--			@Message = @Message OUTPUT

-- SELECT	@ReturnCode as 'Return Code', @Message as 'Error Message'
--
/******************************************************************/
(
@PRCo bCompany = null,
@TaxYear char(4) = null,
@OverwriteYN char(1) = null,
@EmployeesProcessed smallint output,
@Message varchar(4000) output
)
AS
BEGIN
	SET NOCOUNT ON

	-- Check Parameters
	IF @PRCo IS NULL
	BEGIN
		SELECT @Message = 'Missing PR Company!'
		RETURN 1
	END

	IF @TaxYear IS NULL
	BEGIN
		SELECT @Message = 'Missing Tax Year!'
		RETURN 1
	END

	IF @OverwriteYN IS NULL
	BEGIN
		SELECT @Message = 'Missing Overwrite Flag!'
		RETURN 1
	END

	--determine beginning date and ending date of the tax year
	DECLARE @TaxYearBeginDate bDate, @TaxYearEndDate bDate

	SELECT @TaxYearBeginDate = '07/01/' + CAST((CAST(@TaxYear AS smallint) - 1) AS char(4))
	SELECT @TaxYearEndDate = '06/30/' + CAST(CAST(@TaxYear AS smallint) AS char(4))

	--determine Begin and End Month of the tax year
	DECLARE @TaxYearBeginMonth bDate, @TaxYearEndMonth bDate

	SELECT @TaxYearBeginMonth = '07/01/' + CAST((CAST(@TaxYear AS smallint) - 1) AS char(4))
	SELECT @TaxYearEndMonth = '06/01/' + CAST(CAST(@TaxYear AS smallint) AS char(4))

	--Make a list of employees to be included in amounts generate, ie. employees with PRDT posted
	-- during the tax year and if not overwriting, do not have existing summaries through the end of the tax year.
	DECLARE @EmployeesToInclude TABLE (PRCo bCompany, Employee bEmployee)

	INSERT INTO @EmployeesToInclude
		SELECT PRDT.PRCo, PRDT.Employee 
		FROM dbo.bPRDT PRDT (nolock) 
			JOIN dbo.bPRSQ PRSQ (nolock) ON PRSQ.PRCo = PRDT.PRCo 
											AND PRSQ.PRGroup = PRDT.PRGroup 
											AND PRSQ.PREndDate = PRDT.PREndDate 
											AND PRSQ.Employee = PRDT.Employee
											AND PRSQ.PaySeq = PRDT.PaySeq
			WHERE	PRDT.PRCo = @PRCo
					AND PRSQ.PaidDate BETWEEN @TaxYearBeginDate AND @TaxYearEndDate
					AND PRSQ.CMRef IS NOT NULL
					AND (@OverwriteYN = 'Y' 
						OR (@OverwriteYN = 'N' 
							AND @TaxYearEndDate NOT IN (SELECT ItemAmounts.EndDate FROM dbo.PRAUEmployeeItemAmounts ItemAmounts
														WHERE ItemAmounts.PRCo = @PRCo AND ItemAmounts.TaxYear = @TaxYear AND ItemAmounts.Employee = PRDT.Employee)))

		UNION
		SELECT PREA.PRCo, PREA.Employee
			FROM dbo.bPREA PREA (nolock)
			WHERE	PREA.PRCo = @PRCo
					AND PREA.Mth BETWEEN @TaxYearBeginMonth AND @TaxYearEndMonth
					AND (@OverwriteYN = 'Y' 
						OR (@OverwriteYN = 'N' 
							AND @TaxYearEndDate NOT IN (SELECT ItemAmounts.EndDate FROM dbo.PRAUEmployeeItemAmounts ItemAmounts
														WHERE ItemAmounts.PRCo = @PRCo AND ItemAmounts.TaxYear = @TaxYear AND ItemAmounts.Employee = PREA.Employee)))

	--Confirm that all payments to be included in update have been updated to bPREA
	--	(for PRSQ.PaidDate between BeginDate and EndDate, make sure OldMth is not null in associated PRDT entries)
	DECLARE @PRGroup bGroup,
			@PREndDate bDate

	; --semi-colon required to use WITH
	WITH UNPOSTEDPAYPERIODS (PREndDate, PRGroup)
	AS
		(
		SELECT DISTINCT PRDT.PREndDate, PRDT.PRGroup
		FROM @EmployeesToInclude EmpList
		JOIN dbo.bPRDT PRDT (nolock) ON PRDT.PRCo = EmpList.PRCo AND PRDT.Employee = EmpList.Employee
		JOIN dbo.bPRSQ PRSQ (nolock) ON PRSQ.PRCo = PRDT.PRCo 
										AND PRSQ.PRGroup = PRDT.PRGroup 
										AND PRSQ.PREndDate = PRDT.PREndDate 
										AND PRSQ.Employee = PRDT.Employee
										AND PRSQ.PaySeq = PRDT.PaySeq
		WHERE PRDT.PRCo = @PRCo 
			  AND PRSQ.PaidDate BETWEEN @TaxYearBeginDate AND @TaxYearEndDate 
			  AND PRSQ.CMRef IS NOT NULL
			  AND PRDT.OldMth IS NULL
		)

	SELECT TOP(1) @PRGroup = PRGroup, @PREndDate = PREndDate FROM UNPOSTEDPAYPERIODS ORDER BY PREndDate ASC

	IF @PRGroup IS NOT NULL
	BEGIN
		SELECT @Message =	'Amounts for PR Group ' + CONVERT(varchar, @PRGroup)
							+ ', Pay Period Ending Date ' + CONVERT(varchar, @PREndDate, 103)
							+ ' have not yet been posted to Employee Accumulations.  Please run Ledger Update.'
		RETURN 1
	END

	--cursor through list of employees and generate amounts for each one
	DECLARE @Employee bEmployee, @ReturnCode int

	SELECT @EmployeesProcessed = 0

	DECLARE cEmployeesToInclude CURSOR LOCAL FAST_FORWARD FOR
	SELECT Employee FROM @EmployeesToInclude
	WHERE PRCo = @PRCo

	OPEN cEmployeesToInclude

	FETCH NEXT FROM cEmployeesToInclude INTO @Employee

	WHILE @@FETCH_STATUS = 0
	BEGIN

		EXEC	@ReturnCode = [dbo].[vspPRAUPAYGEmployeeAmountsGenerate]
				@PRCo = @PRCo,
				@TaxYear = @TaxYear,
				@Employee = @Employee,
				@EndDate = @TaxYearEndDate,
				@Message = @Message OUTPUT

		IF @ReturnCode = 1
		BEGIN
			RETURN 1
		END
		ELSE
		BEGIN
			SELECT @Message = ''
		END

		SELECT @EmployeesProcessed = @EmployeesProcessed + 1

		FETCH NEXT FROM cEmployeesToInclude INTO @Employee

	END

	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspPRAUPAYGGenerateAllEmployees] TO [public]
GO
