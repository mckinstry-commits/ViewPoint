SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  PROC [dbo].[vspPR_AU_ETP_Pre83TaxFreeGet]
/***********************************************************/
-- CREATED BY: EN 3/04/2013  TFS-39858
-- MODIFIED BY: EN 4/5/2013 Story 44310 / Task 45407  Added solution for ignoring days without pay
--				DAN SO 04/27/2013 TASK 48576 - Prime @Pre83TaxablePortion = @SubjectAmount and not 0
--				DAN SO 04/30/2013 TASK 48576 - Change from HireDate to 7/01/1983 (6/30/1983)
--				DAN SO 04/30/2013 TASK 48576 - Added @TotalDaysOfEmployment = Pre and Post 83 days worked 
--
-- USAGE:
-- Determines what portion of an ETP/ETPR payment (earnings) is attributed to 
-- days of employment prior to 1 July 1983 and is thereby Tax-Free.
--
-- This computation requires determining the # of days of employment before
-- 1 July 1983 and also the total days of employment.  If the employee was actually
-- hired prior to that date, a factor is computed by dividing # of days before
-- 1 July 1983 by # day of employment and this factor is multiplied by the amount
-- of ETP/ETPR earnings to get the Tax-Free component of the earnings. 
-- 
--
-- INPUT PARAMETERS
--	 @PRCo					PR Company
--	 @Employee				Employee number
--	 @SubjectAmount			SubjectAmount on which to base the computation
--   @HireDate				Employee's date of hire
--   @SeparationDate		Employee's termination date
--
-- OUTPUT PARAMETERS
--	 @Pre83TaxFreePortion	portion of the employee's basis earnings to this dedn code that are Tax-Free
--	 @Pre83TaxablePortion   portion of the employee's basis earnings to this dedn code that are Taxable
--   @Message				Error message if error occurs	
--
-- RETURN VALUE
--   0			Success
--   1			Failure
--
/******************************************************************/
(
 @PRCo bCompany = NULL, 
 @Employee bEmployee = NULL, 
 @SubjectAmount bDollar = NULL,
 @HireDate bDate = NULL,
 @SeparationDate bDate = NULL,
 @Pre83TaxFreePortion bDollar OUTPUT,
 @Pre83TaxablePortion bDollar OUTPUT,
 @ErrorMsg varchar(1000) OUTPUT
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


	----------------------------------
	-- INITIALIZE RETURN PARAMETERS --
	----------------------------------
	SET @Pre83TaxFreePortion = 0
	SET @Pre83TaxablePortion = @SubjectAmount		-- TASK 48576 --

	---------------------------------------------------------------------------------------------------
	-- COMPUTE THE PRE 83 TAX FREE AND TAXABLE PORTION ONLY IF EMPLOYEE WAS HIRED BEFORE 1 JULY 1983 --
	---------------------------------------------------------------------------------------------------
	IF @HireDate < '7/1/1983'
	BEGIN

		DECLARE @DaysWorked int,
				@DaysWithoutPay int

		----------------------------------------------------------
		-- DETERMINE # OF DAYS OF EMPLOYMENT BEFORE 1 JULY 1983 --
		----------------------------------------------------------
		DECLARE @Pre83DaysOfEmployment decimal

		EXEC	@Return_Value = [dbo].[vspPRDaysWithoutPayGet]
				@PRCo = @PRCo,
				@Employee = @Employee,
				@FromDate = @HireDate,
				@ThruDate = '6/30/1983',
				@DaysWithoutPay = @DaysWithoutPay OUTPUT,
				@ErrorMsg = @ErrorMsg OUTPUT

		IF @Return_Value <> 0 GOTO vspExit

		SET @DaysWorked = DATEDIFF(DAY, @HireDate - 1, '6/30/1983')
		SET @Pre83DaysOfEmployment = CAST(@DaysWorked AS decimal) - CAST(@DaysWithoutPay AS decimal)

		---------------------------------------------------------------------------------------------
		-- DETERMINE TOTAL DAYS OF EMPLOYMENT FROM THE MOST RECENT HIRE DATE TO DATE OF SEPARATION --
		---------------------------------------------------------------------------------------------
		DECLARE @Post83DaysOfEmployment decimal

		EXEC	@Return_Value = [dbo].[vspPRDaysWithoutPayGet]
				@PRCo = @PRCo,
				@Employee = @Employee,
				@FromDate = '7/01/1983',	-- TASK 48576 --
				@ThruDate = @SeparationDate,
				@DaysWithoutPay = @DaysWithoutPay OUTPUT,
				@ErrorMsg = @ErrorMsg OUTPUT

		IF @Return_Value <> 0 GOTO vspExit

		SET @DaysWorked = DATEDIFF(DAY, '6/30/1983', @SeparationDate) -- TASK 48576 --
		SET @Post83DaysOfEmployment = CAST(@DaysWorked AS decimal) - CAST(@DaysWithoutPay AS decimal)

		---------------------------
		-- COMPUTE RETURN VALUES --
		---------------------------
		-- TASK 48576 --
		DECLARE @TotalDaysOfEmployment decimal
		SET @TotalDaysOfEmployment = @Pre83DaysOfEmployment + @Post83DaysOfEmployment

		IF @TotalDaysOfEmployment > 0	
		BEGIN
			SELECT @Pre83TaxFreePortion = ROUND((@Pre83DaysOfEmployment / @TotalDaysOfEmployment) * @SubjectAmount, 2)
			SELECT @Pre83TaxablePortion = ROUND(@SubjectAmount - @Pre83TaxFreePortion, 2)
		END

	END

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
GRANT EXECUTE ON  [dbo].[vspPR_AU_ETP_Pre83TaxFreeGet] TO [public]
GO
