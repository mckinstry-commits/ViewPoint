SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspPRROEWorkfileROEDateVal]
/***********************************************************
* CREATED BY:  KK 04/02/2013 - 43039 - Validation for co/empl/roedate duplicates
* MODIFIED By: KK 05/03/2013 - 49177 - Validation modification to be for co/empl/roedate duplication, this will allow co/empl/roedate duplicates
* 
* USAGE: Used in PREmployeeROEWorkfile, Validates ROEDate
*
* INPUT PARAMETERS
*   @prco   	PR Company
*   @employee   Employee to validate
*	@roedate	ROE Date
*
* OUTPUT PARAMETERS
*   @msg      error message or Description (Full name)
*
* RETURN VALUE
*   0         success
*   1         Failure
******************************************************************/
(@prco bCompany = NULL, 
 @employee varchar(15) = NULL,
 @roedate bDate = NULL,
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

IF @roedate IS NULL
BEGIN
	SELECT @msg = 'Missing ROE Date!'
	RETURN 1
END

DECLARE @vpusername bVPUserName;
SET @vpusername = SUSER_SNAME();

IF EXISTS(SELECT * FROM vPRROEEmployeeWorkfile
				  WHERE PRCo = @prco
					AND Employee = @employee
					AND ROEDate = @roedate
					AND VPUserName = @vpusername)
BEGIN
	SELECT @msg = 'Record already exists.' 
	RETURN 1
END			

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[vspPRROEWorkfileROEDateVal] TO [public]
GO
