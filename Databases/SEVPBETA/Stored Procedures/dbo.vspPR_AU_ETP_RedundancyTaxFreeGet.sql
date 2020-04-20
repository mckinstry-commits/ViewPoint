SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  PROC [dbo].[vspPR_AU_ETP_RedundancyTaxFreeGet]
/***********************************************************/
-- CREATED BY: EN 2/22/2013  TFS-39858
-- MODIFIED BY: EN 4/5/2013 Story 44310 / Task 45407  Added solution for ignoring days without pay
--
-- USAGE:
-- Determines what portion of Redundancy and Early Retirement (ATO Category ETPR) earnings
-- is Tax-Free and what is ETP Taxable.  
--
-- The Tax-Free portion will be reported on the PAYG statement as Lump Sum D.
-- The remaining, ETP Taxable portion will be included in the Gross Payments of the PAYG statement.
--
-- INPUT PARAMETERS
--   @PRCo						PR Company
--	 @Employee					Employee
--   @UseSubjectAmountYN		If = Y then computation will be based on SubjectAmount passed in, 
--								otherwise SubjectAmount will be the totals ETPR earnings for the employee
--   @SubjectAmount				SubjectAmount on which to base the computation
--   @HireDate					Employee's date of hire
--   @SeparationDate			Employee's termination date
--   @RedundancyTaxFreeBasis	Base amount (basic tax free portion)
--   @RedundancyTaxFreeYears	Per Year tax free amount
--
-- OUTPUT PARAMETERS
--	 @RedundancyTaxFreePortion	Portion of the employee's ETP Redundancy earnings that are Tax-Free
--	 @RedundancyTaxablePortion	Portion of the employee's ETP Redundancy earnings that are Taxable
--   @Message					Error message if error occurs	
--
-- RETURN VALUE
--   0			Success
--   1			Failure
--
/******************************************************************/
(
 @PRCo bCompany = NULL,
 @Employee bEmployee = NULL,
 @UseSubjectAmountYN bYN = 'N',
 @SubjectAmount bDollar = 0,
 @HireDate bDate = NULL,
 @SeparationDate bDate = NULL,
 @RedundancyTaxFreeBasis bDollar = 0,
 @RedundancyTaxFreeYears bDollar = 0,
 @RedundancyTaxFreePortion bDollar OUTPUT,
 @RedundancyTaxablePortion bDollar OUTPUT,
 @ErrorMsg varchar(100) OUTPUT
)

AS
SET NOCOUNT ON

BEGIN TRY

	DECLARE @Return_Value tinyint
			
	------------------
	-- PRIME VALUES --
	------------------
    SET @Return_Value = 0
    SET @ErrorMsg = ''
    
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

	IF @HireDate IS NULL
		BEGIN
			SET @Return_Value = 1
			SET @ErrorMsg = 'Missing Hire Date!'
			GOTO vspExit
		END
		
	IF @SeparationDate IS NULL
		BEGIN
			SET @Return_Value = 1
			SET @ErrorMsg = 'Missing Separation Date!'
			GOTO vspExit
		END


	-------------------------------------------------------------------------------------------------
	-- IF NOT USING THE SUBJECT AMOUNT PASSED IN, SUBJECT AMOUNT WILL BE THE OVERALL ETPR EARNINGS --
	-------------------------------------------------------------------------------------------------
	IF @UseSubjectAmountYN = 'N'
	BEGIN
		SELECT @SubjectAmount = SUM(PREA.Amount)
		FROM dbo.bPREA PREA (NOLOCK)
		JOIN dbo.bPREC PREC ON PREC.PRCo = PREA.PRCo AND PREC.EarnCode = PREA.EDLCode
		WHERE PREA.PRCo = @PRCo AND
				PREA.Employee = @Employee AND
				PREA.EDLType = 'E' AND
				PREC.ATOCategory = 'ETPR'
		GROUP BY PREA.PRCo, PREA.Employee
	END


	-------------------------------------------------------------------------------------------------------------
	-- DETERMINE # OF YEARS WORKED (FRACTIONAL PART IS IGNORED) AND USE TO COMPUTE REDUNDANCY TAX FREE PORTION --
	-------------------------------------------------------------------------------------------------------------
	DECLARE @YearsWorked tinyint
		
	SET @YearsWorked = FLOOR((DATEDIFF(DAY, @HireDate, @SeparationDate)) / 365.25)

	SET @RedundancyTaxFreePortion = @RedundancyTaxFreeBasis + (@YearsWorked * @RedundancyTaxFreeYears)


	--------------------------------------------------------------------------------------------------------------
	-- COMPUTE ETP TAX FREE AND TAXABLE PORTIONS ALLOWING FOR THE CHANCE THAT ALL ETPR EARNINGS MAY BE TAX FREE --
	--------------------------------------------------------------------------------------------------------------
	IF @RedundancyTaxFreePortion > @SubjectAmount SET @RedundancyTaxFreePortion = @SubjectAmount

	SET @RedundancyTaxablePortion = @SubjectAmount - @RedundancyTaxFreePortion


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
GRANT EXECUTE ON  [dbo].[vspPR_AU_ETP_RedundancyTaxFreeGet] TO [public]
GO
