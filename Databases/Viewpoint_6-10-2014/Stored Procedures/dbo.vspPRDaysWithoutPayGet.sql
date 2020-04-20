SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspPRDaysWithoutPayGet]
/***********************************************************
* CREATED:	EN  EN 4/5/2013 Story 44310 / Task 45407
* MODIFIED BY: 
*
* USAGE:
* For a specified date range, determines an employee's total number of 
* days without pay based on the employee's periods without pay 
* (vPREmplPeriodsWithoutPay) used to store absences such as maternity/
* paternity leave and hiatus. 
*
* INPUT PARAMETERS
*   @PRCo			PR Company
*   @Employee		Employee number
*	@FromDate		beginning date of range for determination
*	@ThruDate		ending date of range for determination
*
* OUTPUT PARAMETERS
*	@DaysWithoutPay	# of days within the given date range that coincided with periods without pay for the employee
*   @ErrorMsg		Error message if error occurs	
*
* RETURN VALUE
*   0			Success
*   1			Failure
*
******************************************************************/
(@PRCo bCompany = NULL,
 @Employee bEmployee = NULL,
 @FromDate bDate = NULL,
 @ThruDate bDate = NULL,
 @DaysWithoutPay int OUTPUT,
 @ErrorMsg varchar(255) OUTPUT)

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

	IF @FromDate IS NULL
		BEGIN
			SET @Return_Value = 1
			SET @ErrorMsg = 'Missing From Date of date range!'
			GOTO vspExit
		END
		
	IF @ThruDate IS NULL
		BEGIN
			SET @Return_Value = 1
			SET @ErrorMsg = 'Missing Through Date of date range!'
			GOTO vspExit
		END


	-------------------------------------------------------------------------------------------------------
	-- DETERMINE NUMBER OF DAYS IN THE EMPLOYEE'S PERIODS WITHOUT PAY                       			 --
	--																									 --
	-- Find date ranges of any periods without pay that fall within or intersect the @FromDate to        --
	-- @ThruDate range, adjusting the beginning and/or ending dates of the periods without pay depending --
	-- on the given date range.																			 --
	-------------------------------------------------------------------------------------------------------
	;WITH DateRangesWithoutPay (FirstDate, LastDate)
	AS
	(
		-- find periods without pay that straddle the beginning or end of the given date range
		-- and adjust FirstDate or LastDate accordingly
		SELECT  CASE WHEN DATEDIFF(DAY, @FromDate, FirstDate) < 0 
					 THEN @FromDate 
					 ELSE FirstDate END,
				 
				CASE WHEN DATEDIFF(DAY, LastDate, @ThruDate) < 0
					 THEN @ThruDate	
					 ELSE LastDate END
			 
		FROM	dbo.vPREmplPeriodsWithoutPay
	
		WHERE	PRCo = @PRCo AND
				Employee = @Employee AND
				(@FromDate BETWEEN FirstDate AND LastDate OR
				 @ThruDate BETWEEN FirstDate AND LastDate)
		UNION
		-- find periods without pay that exist fully within the given date range
		SELECT	FirstDate, LastDate
		FROM	dbo.vPREmplPeriodsWithoutPay
	
		WHERE	PRCo = @PRCo AND
				Employee = @Employee AND
				(@FromDate <= FirstDate AND @ThruDate >= LastDate)
	)

	SELECT	@DaysWithoutPay = ISNULL(SUM(DATEDIFF(DAY, FirstDate, LastDate) + 1) ,0)
	FROM	DateRangesWithoutPay


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
GRANT EXECUTE ON  [dbo].[vspPRDaysWithoutPayGet] TO [public]
GO
