SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspPRROEWorkfileEmplVal]
/***********************************************************
* CREATED BY:  KK 03/11/2013
* MODIFIED By: KK 04/01/2013 - Added switcheroo code, and backword validation for co/empl/roedate duplicates
*			   KK 05/03/2013 - Removed backword validation. This was corrected in standards. 
* 
* USAGE: Used in PREmployeeROEWorkfiled, Validates Employee and gets description from PREH/PREHFullName 
*
* INPUT PARAMETERS
*   @prco   	PR Company
*   @employee   Employee to validate
*	@roedate	ROE Date
*
* OUTPUT PARAMETERS
*	@emplOut	Employee if using sortname switcheroo
*   @msg		Error message or Description (Full name)
*
* RETURN VALUE
*   0         success
*   1         Failure
******************************************************************/
(@prco bCompany = NULL, 
 @employee varchar(15) = NULL,
 @roedate bDate = NULL,
 @emplOut bEmployee = NULL OUTPUT,
 @msg varchar(60) OUTPUT)

AS SET NOCOUNT ON

IF @prco IS NULL or @prco = 0
BEGIN
	SELECT @msg = 'Missing PR Company!'
	RETURN 1
END

IF @employee IS NULL
BEGIN
	SELECT @msg = 'Missing Employee!'
	RETURN 1
END

/* If @employee is numeric, try to find Employee number */
IF dbo.bfIsInteger(@employee) = 1 -- 1 means yes, it is an integer
BEGIN
	IF LEN(@employee) < 7
	BEGIN
		SELECT @emplOut = Employee
		FROM PREH
		WHERE PRCo = @prco AND 
			  Employee = CONVERT(int,CONVERT(float, @employee))
	END
	ELSE
	BEGIN
		SELECT @msg = 'Invalid Employee Number, length must be 6 digits or less.'
		RETURN 1
	END
END

/* if not numeric or not found try to find as Sort Name */
IF @@ROWCOUNT = 0
BEGIN
   	SELECT @emplOut = Employee
	FROM PREH
	WHERE PRCo = @prco AND 
		  SortName = @employee

	/* if not found,  try to find closest */
  	IF @@ROWCOUNT = 0
	BEGIN
		SET ROWCOUNT 1
		SELECT @emplOut = Employee
		FROM PREH
		WHERE PRCo = @prco AND 
			  SortName LIKE @employee + '%'
		IF @@ROWCOUNT = 0
		BEGIN
			SELECT @msg = 'Not a valid Employee!'
			RETURN 1
		END
	END
END

IF @emplOut IS NOT NULL SELECT @employee = @emplOut

SELECT @msg = FullName 
  FROM PREHFullName
 WHERE PRCo = @prco
   AND Employee = @employee
 
IF @@rowcount = 0
BEGIN
	SELECT @msg = 'Employee is not on file!' 
	RETURN 1
END

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[vspPRROEWorkfileEmplVal] TO [public]
GO
