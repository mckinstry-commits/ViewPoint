SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE         procedure [dbo].[vspPREmplPWPDateVal]
/************************************************************************
* CREATED:	EN  EN 4/5/2013 Story 44310 / Task 45407
* MODIFIED:	
*
* Validates the Employee Periods Without Pay FirstDate/LastDate
* date range to ensure that LastDate is not a date prior to 
* FirstDate and that there are not conflicts with date ranges
* already existing for the employee in dbo.vPREmplPeriodsWithoutPay.
*
* INPUT PARAMETERS
*   @PRCo			PR Company to validate against
*   @Employee		Employee to validate against
*	@Seq			vPREmplPeriodsWithoutPay Seq of entry being validated
*	@FirstDate		beginning date of range to be validated
*	@LastDate		ending date of range to be validated
*
* OUTPUT PARAMETERS
*   @@ErrorMsg		error message if error occurs
*
* RETURN VALUE
*   0         success
*   1         Failure
  *************************************************************************/   
(@PRCo bCompany = NULL, 
 @Employee bEmployee = NULL, 
 @Seq smallint = NULL, 
 @FirstDate bDate = NULL,
 @LastDate bDate = NULL,
 @ErrorMsg varchar(255) = '' OUTPUT)
  
AS

BEGIN TRY

	SET NOCOUNT ON
  
	DECLARE @Return_Value tinyint

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

	IF @Seq IS NULL
	BEGIN
		SET @Return_Value = 1
		SET @ErrorMsg = 'Missing Seq!'
		GOTO vspExit
	END

	-----------------------------------------------------------------
	-- NO NEED TO CONTINUE IF EITHER FIRST OR LAST DATE IS MISSING --
	-----------------------------------------------------------------
	IF @FirstDate IS NULL OR @LastDate IS NULL
	BEGIN
		SET @Return_Value = 0
		GOTO vspExit
	END

	---------------------------------------------
	-- Compare order of FirstDate and LastDate --
	---------------------------------------------
	IF DATEDIFF(DAY, @FirstDate, @LastDate) < 0
	BEGIN
		SELECT @ErrorMsg = 'Last Date cannot be earlier than First Date '
		SELECT @Return_Value = 1
		GOTO vspExit
	END

	----------------------------------------------------------
	-- Verify that date ranges do not intersect or conflict --
	----------------------------------------------------------
	IF EXISTS  (SELECT	* 
				FROM	dbo.vPREmplPeriodsWithoutPay
				 
				WHERE	PRCo = @PRCo AND 
						Employee = @Employee AND 
						Seq <> @Seq AND
						(FirstDate BETWEEN @FirstDate AND @LastDate OR
						 LastDate BETWEEN @FirstDate AND @LastDate)
			   )
	OR EXISTS  (SELECT	*
				FROM	dbo.vPREmplPeriodsWithoutPay
				WHERE	PRCo = @PRCo AND 
						Employee = @Employee AND 
						Seq <> @Seq AND
						(FirstDate <= @FirstDate AND LastDate >= @LastDate)
			   )
	BEGIN
		SELECT @ErrorMsg = 'Date range conflicts with an existing date range '
		SELECT @Return_Value = 1
		GOTO vspExit
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
GRANT EXECUTE ON  [dbo].[vspPREmplPWPDateVal] TO [public]
GO
