SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspPR_AU_ETP_InvalidityTaxFreeGet]
/***********************************************************
* CREATED:	DAN SO 03/07/2013 - TFS: User Story 39860:PR ETP Redundancy Tax Calculations - 1
*							  - Co-developed with Ellen BN
* MODIFIED BY:	EN 4/5/2013 Story 44310 / Task 45407  Added solution for ignoring days without pay
*				DAN SO 04/26/2013 - Task 48575 - If Retirement Date < Invalidity Date - ALL Invalidity earnings are taxable
*				DAN SO 04/30/2013 - Task 48575 - Changed @RetirementAge datatype from INT to bUnits
*
* USAGE:
* Determines what portion of Invalidity (ATO Type: ETPV) earnings
* that is Tax-Free and what is Taxable.  
*
* INPUT PARAMETERS
*	@PRCo					- PR Company
*   @Employee				- Employee number
*	@ETPAmt					- ETP Amount
*	@BirthDate				- Employee birth date
*   @HireDate				- Employee hire date
*   @SeparationDate			- Employee separation date
*
* OUTPUT PARAMETERS
*	@InvalidityTaxFreePortion	- Portion of the employee's Invalidity ETP that is Tax-Free
*	@InvalidityTaxablePortion	- Portion of the employee's Invalidity ETP that is Taxable
*   @ErrorMsg					- Error message if error occurs	
*
* RETURN VALUE
*   0			Success
*   1			Failure
*
******************************************************************/
(@PRCo bCompany = NULL, 
 @Employee bEmployee = NULL, 
 @ETPAmt bDollar = NULL,
 @BirthDate bDate = NULL, @HireDate bDate = NULL, @SeparationDate bDate = NULL,
 @EmployeeGender CHAR(1) = NULL,
 @InvalidityTaxFreePortion bDollar OUTPUT, @InvalidityTaxablePortion bDollar OUTPUT,
 @ErrorMsg VARCHAR(255) OUTPUT)

AS
SET NOCOUNT ON

BEGIN TRY

	DECLARE @RetirementAge bUnits,
			@Return_Value INT
			
	------------------
	-- PRIME VALUES --
	------------------
	SET @RetirementAge = 0
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

	IF @ETPAmt IS NULL
		BEGIN
			SET @Return_Value = 1
			SET @ErrorMsg = 'Missing ETP Amount!'
			GOTO vspExit
		END
		
	IF @BirthDate IS NULL
		BEGIN
			SET @Return_Value = 1
			SET @ErrorMsg = 'Missing Birth Date!'
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

	IF @EmployeeGender IS NULL
		BEGIN
			SET @Return_Value = 1
			SET @ErrorMsg = 'Missing Employee Gender!'
			GOTO vspExit
		END
		
	
	----------------------------------
	-- INITIALIZE RETURN PARAMETERS --
	----------------------------------
	SET @InvalidityTaxFreePortion = 0
	SET @InvalidityTaxablePortion = @ETPAmt		-- TASK 48575 --
		
	------------------------------
	-- DETERMINE Retirement Age --
	------------------------------
	-- Male Retirement Age --
	SET @RetirementAge = 65 
	
	-- Female Retirement Age --
	IF UPPER(@EmployeeGender) = 'F'
		BEGIN
		
			---------------------
			-- Date YYYY-MM-DD --
			---------------------
			SELECT @RetirementAge =
			  CASE 
				 WHEN @BirthDate < '1935-07-01' THEN 60.5
				 WHEN @BirthDate BETWEEN '1935-07-01' AND '1936-12-31' THEN 60.5
				 WHEN @BirthDate BETWEEN '1937-01-01' AND '1938-06-30' THEN 61
				 WHEN @BirthDate BETWEEN '1938-07-01' AND '1939-12-31' THEN 61.5
				 WHEN @BirthDate BETWEEN '1940-01-01' AND '1941-06-30' THEN 62
				 WHEN @BirthDate BETWEEN '1941-07-01' AND '1942-12-31' THEN 62.5
				 WHEN @BirthDate BETWEEN '1943-01-01' AND '1944-06-30' THEN 63	
				 WHEN @BirthDate BETWEEN '1944-07-01' AND '1945-12-31' THEN 63.5
				 WHEN @BirthDate BETWEEN '1946-01-01' AND '1947-06-30' THEN 64	
				 WHEN @BirthDate BETWEEN '1947-07-01' AND '1948-12-31' THEN 64.5
				 WHEN @BirthDate > '1949-01-01' THEN 65
				 ELSE 0
			  END		
		END
		
	-------------------------------------------------------------------------------------
	-- DETERMINE Whole Days FROM SeparationDate TO WHAT WOULD HAVE BEEN RetirementDate --
	------------------------------------------------------------------------------------- 
	DECLARE @DaysSepToRet INT, 
			@DaysWorked INT, 
			@DaysWithoutPay INT,
			@RetirementDate bDate
	
	SET @RetirementDate = DATEADD(MONTH, (@RetirementAge * 12), @BirthDate)
	SET @DaysSepToRet = DATEDIFF(DAY, @SeparationDate, @RetirementDate) + 1

	EXEC	@Return_Value = [dbo].[vspPRDaysWithoutPayGet]
			@PRCo = @PRCo,
			@Employee = @Employee,
			@FromDate = @HireDate,
			@ThruDate = @SeparationDate,
			@DaysWithoutPay = @DaysWithoutPay OUTPUT,
			@ErrorMsg = @ErrorMsg OUTPUT

	IF @Return_Value <> 0 GOTO vspExit

	SET @DaysWorked = DATEDIFF(DAY, @HireDate - 1, @SeparationDate)	- @DaysWithoutPay

	-----------------------
	-- CALCULATE AMOUNTS --
	-----------------------
	-- TASK 48575 --
	IF @DaysSepToRet > 0
		BEGIN
			SET @InvalidityTaxFreePortion = (@ETPAmt * @DaysSepToRet) / (@DaysWorked + @DaysSepToRet)
			SET @InvalidityTaxablePortion = @ETPAmt - @InvalidityTaxFreePortion
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
GRANT EXECUTE ON  [dbo].[vspPR_AU_ETP_InvalidityTaxFreeGet] TO [public]
GO
