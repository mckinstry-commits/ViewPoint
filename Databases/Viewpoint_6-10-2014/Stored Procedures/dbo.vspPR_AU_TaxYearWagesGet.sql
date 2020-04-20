SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  PROC [dbo].[vspPR_AU_TaxYearWagesGet]
/***********************************************************/
-- CREATED BY: EN 3/26/2013
-- MODIFIED BY: 
--
-- USAGE:
-- Returns the amount of taxable wages earned by an employee for the current Australian tax year
-- based on the PR Ending Date. 
--
--
-- INPUT PARAMETERS
--   @PRCo						PR Company
--	 @Employee					Employee
--   @PREndDate					Last Payroll End Date of the tax year
--
-- OUTPUT PARAMETERS
--	 @TaxableAmount				Employee's taxable (PAYG) subject amount for the current tax year
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
 @PREndDate bDate = NULL,
 @TaxableWages bDollar OUTPUT,
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

	IF @PREndDate IS NULL
	BEGIN
		SET @Return_Value = 1
		SET @ErrorMsg = 'Missing Pay Period Ending Date!'
		GOTO vspExit
	END

	
	-----------------------------------
	-- DETERMINE 1ST DAY OF TAX YEAR --
	-----------------------------------
	DECLARE @TaxYear int,
			@TaxYearBeginDate bDate

	SELECT	@TaxYear = DATEPART(YEAR,@PREndDate)
	
	IF DATEPART(MONTH,@PREndDate) IN (1,2,3,4,5,6) SELECT @TaxYear = @TaxYear - 1
	
	SELECT	@TaxYearBeginDate = '07/01/' + CAST(@TaxYear AS varchar)


	------------------------------------------------------
	-- GET DEDUCTION CODE USED FOR THE FEDERAL PAYG TAX --
	------------------------------------------------------
	DECLARE @PAYGDednCode bEDLCode

	SELECT @PAYGDednCode = TaxDedn
	FROM PRFI
	WHERE PRCo = @PRCo


	-------------------------------------------------------------------
	-- DETERMINE THE TOTAL TAXABLE EARNINGS FOR THE CURRENT TAX YEAR --
	-------------------------------------------------------------------
	;WITH TaxYearWages (SubjectAmount)
	AS
	(
		SELECT  SUM(PRDT.SubjectAmt)
		FROM	dbo.bPRDT PRDT
		JOIN	dbo.bPRSQ PRSQ ON PRSQ.PRCo = PRDT.PRCo 
								  AND PRSQ.PRGroup = PRDT.PRGroup  
								  AND PRSQ.PREndDate = PRDT.PREndDate  
								  AND PRSQ.Employee = PRDT.Employee  
								  AND PRSQ.PaySeq = PRDT.PaySeq
		WHERE	PRDT.PRCo = @PRCo AND
				PRDT.Employee = @Employee AND
				PRDT.EDLType = 'D' AND
				PRDT.EDLCode = @PAYGDednCode AND
				PRSQ.PaidDate >= @TaxYearBeginDate AND PRSQ.PaidDate < @PREndDate
				
		UNION
		
		SELECT  PRDT.SubjectAmt
		FROM	dbo.bPRDT PRDT
		WHERE	PRDT.PRCo = @PRCo AND
				PRDT.Employee = @Employee AND
				PRDT.EDLType = 'D' AND
				PRDT.EDLCode = @PAYGDednCode AND
				PRDT.PREndDate = @PREndDate
	)

	SELECT	@TaxableWages = SUM(SubjectAmount)
	FROM TaxYearWages

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
GRANT EXECUTE ON  [dbo].[vspPR_AU_TaxYearWagesGet] TO [public]
GO
