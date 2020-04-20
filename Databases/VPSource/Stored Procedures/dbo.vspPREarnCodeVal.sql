SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspPREarnCodeVal]
/***********************************************************
* CREATED BY:  KK 11/14/2012
* MODIFIED By: 
* 
* USAGE: Validates PR Earn Code from PREC or PR Dedn Code from PRDL
*		 Validates that the method L-Allowance when used in PR Craft/Class, 
*															PR Craft/Class Template, 
*															PR Craft Master OR
*															PR Craft Template
*		 An error is returned if any of the following occurs
*
* INPUT PARAMETERS
*   @prco   	PR Company
*   @earncode   Code to validate
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs otherwise Description of Ded/Earnings/Liab Code
*
* RETURN VALUE
*   0         success
*   1         Failure
******************************************************************/
(@prco bCompany = 0, 
 @earncode bEDLCode = NULL,
 @msg varchar(60) OUTPUT)

AS SET NOCOUNT ON

DECLARE	@method char(1)

IF @prco IS NULL or @prco = 0
BEGIN
	SELECT @msg = 'Missing PR Company!'
	RETURN 1
END

IF @earncode IS NULL
BEGIN
	SELECT @msg = 'Missing Earn Code!'
	RETURN 1
END

SELECT @method = Method, @msg = Description
FROM PREC
WHERE PRCo = @prco
  AND EarnCode = @earncode
  
IF @@rowcount = 0
BEGIN
	SELECT @msg = 'Earn Code not on file!'
	RETURN 1
END
  
IF @method <> 'L'
BEGIN
	SELECT @msg = 'Allowance Earn Code "Method" must be type L-Allowance!'
	RETURN 1
END

RETURN 0

GO
GRANT EXECUTE ON  [dbo].[vspPREarnCodeVal] TO [public]
GO
