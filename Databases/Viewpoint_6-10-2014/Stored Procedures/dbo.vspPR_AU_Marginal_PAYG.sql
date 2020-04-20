SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  PROC [dbo].[vspPR_AU_Marginal_PAYG]
/***********************************************************/
-- CREATED BY: EN 3/22/2013  Story 39859 / Task 42411
-- MODIFIED BY: EN 4/5/2013 Story 44310 / Task 45407  Added solution for ignoring days without pay
--              JayR 5/17/2013 Removed special symbol(s) as it interferes with database compares.              
--
-- USAGE:
-- Tax routine to compute tax on Early Retirement earnings in the case of Annual Leave category ETPA
-- and Long Service Leave type ETPL.  

-- NOTE: THIS SAME PROCESS CAN BE USED TO COMPUTE TAX ON AN ANNUAL BONUS WITH ONE EXCEPTION ...
--		 THE FLAT TAX ON AMOUNTS UNDER A CERTAIN THRESHOLD WOULD NOT APPLY IN AN ANNUAL BONUS SITUATION
--
-- This procedure uses stored procedure vspPR_AU_PAYGxx to compute tax by fictionally adding
-- the amount to be taxed onto an employee's regular wages to ensure that a realistic tax bracket is
-- used in the computation.
--
--
-- Steps to compute tax on an ETP Leave payment:
-- If the Leave Amount is less than $300, total tax is a flat 31.5% of the Leave Amount.  
-- However, if the Leave Amount is $300 or greater...
--  1)	From PRFI locate the deduction code used for federal PAYG tax.
--  2)	From PRDT get the total Subject Amount and Tax Amount for the PAYG deduction code for the number 
--      of pay periods equivalent to a year.  Do not include the current pay period.  
--      [This will account for any lapses of employment due to maternity leave or whatever so the actual 
--       date range of these PRDT entries could cover more than a year.]
--  3)	Divide the Subject Amount and PAYG Tax Amount values by the number of pay periods in a year (P) 
--      to get the average Subject Amount (A) and PAYG Tax Amount (B) values.
--  4)	Divide the Leave Amount (L) by the number of pay periods in a year to get the amount that would 
--      be attributed to a pay period if the Leave Amount were paid out over a one year period (C = L / P).
--  5)	Look up the name of the current PAYG tax routine in use, using PRDL to look up the Routine Name 
--      based on the PAYG deduction code and using PRRM to look up the Stored Procedure name attributed to 
--      the Routine Name.
--  6)	Add the average Subject Amount and the per pay period Leave Amount (A + C) and for that amount use 
--      the PAYG tax routine to compute what the tax (D) would be for the employee's pay period frequency.
--  7)	Determine the tax attributed to the per pay period Leave Amount by subtracting the average PAYG Tax 
--      Amount from the tax computed in the previous step (E = D - B).
--  8)	Multiply the tax attributed to the per pay period Leave Amount by the number of pay period in a year 
--      to arrive at the total tax to be withheld from the Leave Amount (total tax = E x P).
--
--
-- INPUT PARAMETERS
--   @PRCo						PR Company
--	 @Employee					Employee
--	 @PRGroup					Employee's PR Group
--   @PREndDate					End Date of payroll period being processed
--	 @NumberOfPayPdsAnnually	# of pay periods in a year based on this employee's pay frequency
--   @SubjectAmount				Subject Amount on which to base the computation
--
-- OUTPUT PARAMETERS
--	 @TaxAmount					Computed tax amount
--   @ErrorMsg					Error message if error occurs	
--
-- RETURN VALUE
--   0			Success
--   1			Failure
--
/******************************************************************/
(
 @PRCo bCompany = NULL,
 @Employee bEmployee = NULL,
 @PRGroup bGroup = NULL,
 @PREndDate bDate = NULL,
 @NumberOfPayPdsAnnually tinyint = 0,
 @SubjectAmount bDollar = 0,
 @TaxAmount bDollar OUTPUT,
 @ErrorMsg varchar(255) OUTPUT
)
AS

BEGIN TRY
	SET NOCOUNT ON

	DECLARE	@Return_Value int

	SELECT @Return_Value = 0


	----------------------------
	-- CHECK INPUT PARAMETERS --
	----------------------------
	IF @PRCo IS NULL
	BEGIN
		SET @Return_Value = 1
		SET @ErrorMsg = 'Missing PR Company!'
		GOTO vspExit
	END
		
	IF @Employee IS NULL
	BEGIN
		SET @Return_Value = 1
		SET @ErrorMsg = 'Missing Employee!'
		GOTO vspExit
	END

	IF @NumberOfPayPdsAnnually = 0
	BEGIN
		SET @Return_Value = 1
		SET @ErrorMsg = 'Missing # of Pay Periods per year!'
		GOTO vspExit
	END
	IF @NumberOfPayPdsAnnually NOT IN (52,26,12)
	BEGIN
		SET @Return_Value = 1
		SET @ErrorMsg = 'Pay Frequency must be Weekly, Biweekly (Fortnightly), or Monthly.'
		GOTO vspExit
	END

	
	-----------------------------------------------------------------------------------------------------------------------
	-- IF SUBJECT AMOUNT IS LESS THAN THE LEAVE LIMIT, APPLY A FLAT % TAX RATE (PARAMS FOUND IN dbo.vPRAULimitsAndRates) --
	-----------------------------------------------------------------------------------------------------------------------
	DECLARE @MaxEffectiveDate bDate,
			@LeaveLimit bDollar,
			@LeaveMaxPct bPct

	SELECT	@MaxEffectiveDate = MAX(EffectiveDate)

	FROM	dbo.vPRAULimitsAndRates
	WHERE	EffectiveDate <= @PREndDate 


	SELECT	@LeaveLimit = LeaveFlatRateLimit,
			@LeaveMaxPct = LeaveFlatRatePct

	FROM	dbo.vPRAULimitsAndRates
	WHERE	EffectiveDate = @MaxEffectiveDate

	IF @SubjectAmount < @LeaveLimit
	BEGIN
		SELECT @TaxAmount = ROUND(@SubjectAmount * @LeaveMaxPct, 0)
		GOTO vspExit
	END


	---------------------------------------------------------
	-- 1) GET DEDUCTION CODE USED FOR THE FEDERAL PAYG TAX --
	---------------------------------------------------------
	DECLARE @PAYGDednCode bEDLCode

	SELECT @PAYGDednCode = TaxDedn
	FROM PRFI
	WHERE PRCo = @PRCo


	--------------------------------------------------------------------------------------------
	-- 2) GET THE TOTAL PAYG SUBJECT AND TAX AMOUNTS FOR THE PAST YEAR'S WORTH OF PAY PERIODS --
	--	  This process involves first making a list of pay periods that conflict with period  --
	--	  without pay (like if the employee worked for part of a pay period so was not paid   --
	--	  an amount that correctly reflects regular wages for a pay period) and then ignoring --
	--	  those pay periods when getting a year's worth of wages.						      --
	--------------------------------------------------------------------------------------------
	DECLARE @AnnualRegularWages bDollar,
			@AnnualPAYGTax bDollar,
			@NumberOfPayPdsToAverage tinyint

	;WITH PayPeriodsToIgnore (PRGroup, PREndDate)
	AS
	(
		SELECT  DISTINCT PRPC.PRGroup, PRPC.PREndDate
		FROM	dbo.bPRPC PRPC
		
		JOIN	dbo.bPRDT PRDT ON PRDT.PRCo = PRPC.PRCo AND
								  PRDT.PRGroup = PRPC.PRGroup AND
								  PRDT.PREndDate = PRPC.PREndDate
								  
		JOIN	dbo.vPREmplPeriodsWithoutPay PWP ON PWP.PRCo = PRDT.PRCo AND
													PWP.Employee = PRDT.Employee
	
		WHERE	PRPC.PRCo = @PRCo AND
				PRDT.Employee = @Employee AND
				
				(PRPC.BeginDate BETWEEN FirstDate AND LastDate OR
				 PRPC.PREndDate BETWEEN FirstDate AND LastDate)
				OR
				(PRPC.BeginDate <= FirstDate AND PRPC.PREndDate >= LastDate)
	),
	OneYearOfWages (SubjectAmount, TaxAmount)
	AS
	(
		SELECT TOP (@NumberOfPayPdsAnnually) SUM(PRDT.SubjectAmt), SUM(PRDT.Amount) --getting the SUM ensures that mult pay seqs in a pay pd are counted as 1
		FROM	dbo.bPRDT PRDT
		WHERE	PRDT.PRCo = @PRCo 
				AND PRDT.Employee = @Employee 
				AND PRDT.EDLType = 'D' 
				AND PRDT.EDLCode = @PAYGDednCode 
				AND NOT (PRDT.PRGroup = @PRGroup AND PRDT.PREndDate = @PREndDate)
				AND NOT EXISTS (SELECT * FROM PayPeriodsToIgnore IGNORE WHERE IGNORE.PRGroup = PRDT.PRGroup AND
																			  IGNORE.PREndDate = PRDT.PREndDate)
		GROUP BY PRCo, PRGroup, PREndDate, Employee
		ORDER BY PREndDate DESC
	)

	SELECT	@AnnualRegularWages = SUM(SubjectAmount), 
			@AnnualPAYGTax = SUM(TaxAmount),
			@NumberOfPayPdsToAverage = COUNT(*)
	FROM OneYearOfWages


	--------------------------------------------------------------------------
	-- 3) COMPUTE THE AVERAGE PAYG SUBJECT AND TAX AMOUNTS FOR A PAY PERIOD --
	--------------------------------------------------------------------------
	DECLARE @AverageRegularWages bDollar,
			@AveragePAYGTax bDollar

	SELECT	@AverageRegularWages = ROUND(@AnnualRegularWages / @NumberOfPayPdsToAverage, 0),
			@AveragePAYGTax = ROUND(@AnnualPAYGTax / @NumberOfPayPdsToAverage, 0)


	--------------------------------------------------------------------------------------------------------
	-- 4) COMPUTE LEAVE AMOUNT FOR ONE PAY PERIOD ASSUMING THE LEAVE AS BEING PAID OVER A ONE YEAR PERIOD --
	--------------------------------------------------------------------------------------------------------
	DECLARE @SubjectPerPayPeriod bDollar

	SELECT	@SubjectPerPayPeriod = ROUND(@SubjectAmount / @NumberOfPayPdsToAverage, 0)

	
	--------------------------------------------------------------
	-- 5) GET CURRENT STORED PROCEDURE NAME OF PAYG TAX ROUTINE --
	--------------------------------------------------------------
	DECLARE @PAYGStoredProcName varchar(34)

	SELECT	@PAYGStoredProcName = 'dbo.' + PRRM.ProcName
	FROM	dbo.PRDL
	JOIN	dbo.PRRM ON PRRM.PRCo = PRDL.PRCo AND PRRM.Routine = PRDL.Routine
	WHERE	PRDL.PRCo = @PRCo AND PRDL.DLCode = @PAYGDednCode


	---------------------------------------------------------------------------------------------
	-- GET EMPLOYEE'S PAYG FILING STATUS (bPRED) INFO NEEDED TO PASS INTO THE PAYG TAX ROUTINE --
	---------------------------------------------------------------------------------------------
	DECLARE	@Scale tinyint, 
			@Status char(1), 
			@AdditionalExemptions tinyint, 
			@FTB_Offset bDollar 

	SELECT	@Scale = 0, 
			@Status = 'S', 
			@AdditionalExemptions = 0, 
			@FTB_Offset = 0

	SELECT	@Scale = RegExempts, 
			@Status = FileStatus, 
			@AdditionalExemptions = AddExempts, 
			@FTB_Offset = MiscAmt
    FROM	dbo.bPRED
    WHERE	PRCo = @PRCo 
			AND Employee = @Employee 
			AND DLCode = @PAYGDednCode


	------------------------------------------------------------------------
	-- GET EMPLOYEE (bPREH) INFO NEEDED TO PASS INTO THE PAYG TAX ROUTINE --
	------------------------------------------------------------------------
	DECLARE	@NonResidentAlienYN bYN	
	
	SELECT	@NonResidentAlienYN = 'N'

	SELECT	@NonResidentAlienYN = NonResAlienYN 
	FROM	dbo.PREH
   	WHERE	PRCo = @PRCo 
			AND Employee = @Employee


	----------------------------------------------------------------------------------------------
	-- 6) COMPUTE WHAT TAX WOULD BE FOR ONE PAY PERIOD ON THE SUBJECT AMOUNT PLUS REGULAR WAGES --
	----------------------------------------------------------------------------------------------
	DECLARE @TaxIncludingRegularWages bDollar,
			@SubjectPlusRegular bDollar

	SELECT  @SubjectPlusRegular = @SubjectPerPayPeriod + @AverageRegularWages

	EXEC	@Return_Value	= @PAYGStoredProcName
			@subjamt		= @SubjectPlusRegular,
			@ppds			= @NumberOfPayPdsAnnually,
			@Scale			= @Scale,
			@status			= @Status,
			@addlexempts	= @AdditionalExemptions,
			@nonresalienyn	= @NonResidentAlienYN,
			@ftb_offset		= @FTB_Offset,
			@amt			= @TaxIncludingRegularWages OUTPUT,
			@msg			= @ErrorMsg OUTPUT

	IF @Return_Value <> 0 GOTO vspExit


	-----------------------------------------
	-- 7 & 8) DETERMINE TAX PER PAY PERIOD --
	-----------------------------------------
	SELECT @TaxAmount = (ROUND(@TaxIncludingRegularWages,0) - @AveragePAYGTax) * @NumberOfPayPdsToAverage

END TRY

--------------------
-- ERROR HANDLING --
--------------------
BEGIN CATCH
	SET @Return_Value = 1
	SET @ErrorMsg = ERROR_PROCEDURE() + ': ' + ERROR_MESSAGE()	
END CATCH

------------------
-- EXIT ROUTINE --
------------------
vspExit:
	RETURN @Return_Value


GO
GRANT EXECUTE ON  [dbo].[vspPR_AU_Marginal_PAYG] TO [public]
GO
