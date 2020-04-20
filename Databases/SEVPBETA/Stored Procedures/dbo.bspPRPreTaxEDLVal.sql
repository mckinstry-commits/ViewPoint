SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPREarnDedLiabVal    Script Date: 8/28/99 9:33:18 AM ******/
CREATE  proc [dbo].[bspPRPreTaxEDLVal]
/***********************************************************
* CREATED BY:	CHS	10/18/2010	- issue #140541
* MODIFIED By:	CHS	07/23/2012	- B-104475 allow deduction with calc category of 'E' and 'I'
*
* USAGE:
* validates PR Earn Code FROM PREC or PR Dedn Code FROM PRDL
* an error is returned IF any of the following occurs code is not valid
*
* INPUT PARAMETERS
*   @prco   	PR Company
*   @edltype	Code type to validate ('E' or 'D'))
*   @edlcode   	Code to validate
*
* OUTPUT PARAMETERS
*   @msg      error message IF error occurs otherwise Description of Ded/Earnings/Liab Code
* RETURN VALUE
*   0         success
*   1         Failure
******************************************************************/
(@prco bCompany = 0, @edltype CHAR(1) = null, @edlcode bEDLCode = null, @dlcode bEDLCode = null, @msg varchar(255) output)
   	
AS
SET NOCOUNT ON


DECLARE @rcode INT, --@PRedtype CHAR(1), 
@ParentDLType CHAR(1), 
@PRPreTax CHAR(1), @CalcCategory CHAR(1), @Method CHAR(1)

SELECT @rcode = 0

IF isnull(@prco, 0) = 0
	BEGIN
	SELECT @msg = 'Missing PR Company!', @rcode = 1
	GOTO bspexit
	END

IF isnull(@edltype, '') = ''
	BEGIN
	SELECT @msg = 'Missing Earnings/Deduction Type!', @rcode = 1
	GOTO bspexit
	END

-- we are allowing on Earnings and Deduction codes for the pre tax basis	
IF @edltype = 'L'
	BEGIN
	SELECT @msg = 'Liability Type is not allowed!', @rcode = 1
	GOTO bspexit
	END	
   	
IF isnull(@edlcode, 0) = 0
	BEGIN
		IF @edltype='D'
		BEGIN
		SELECT @msg = 'Missing PR Deduction Code!', @rcode = 1
		GOTO bspexit
		END
	
	IF @edltype='E'
		BEGIN
		SELECT @msg = 'Missing PR Earnings Code!', @rcode = 1
		GOTO bspexit
		END
	
	END

-- validate code when type is Earnings   	
IF @edltype='E'
	BEGIN
	SELECT @msg = Description
	FROM PREC
	WHERE PRCo = @prco and EarnCode=@edlcode
	
	IF @@rowcount = 0
		BEGIN
		SELECT @msg = 'PR Earnings Code not on file!', @rcode = 1
		GOTO bspexit
		END

	END
   	
IF @edltype='D'
BEGIN
	-- validate target (parent) deduction we are assigning to - category must be Federal, State, Local, or Employee calculation category
	SELECT @msg=Description, @CalcCategory=CalcCategory, @Method=Method, @ParentDLType = DLType
	FROM PRDL
	WHERE PRCo=@prco and DLCode=@dlcode
	
		
	IF @ParentDLType IN ('L', 'D')
		BEGIN
		IF @CalcCategory not in ('F', 'S', 'L', 'E', 'I')
		BEGIN
			SELECT @msg = 'This code cannot be added to the basis. '
			SELECT @msg = @msg + CASE WHEN @ParentDLType = 'D' THEN + 'Deduction' ELSE 'Liability' END 
			SELECT @msg = @msg + ' Code  ' + cast(@dlcode as varchar(30)) 
			SELECT @msg = @msg + + '  must be a Federal, State, Local, Employee or Insurance calculation category.', @rcode = 1
			GOTO bspexit
		END		
		END		

	-- validate target (parent) deduction we are assigning to - method must be G-Rate of gross or R-Routine
	IF @Method not in ('G', 'R')
	BEGIN
		SELECT @msg = 'This code cannot be added to the basis. '
		SELECT @msg = @msg + CASE WHEN @ParentDLType = 'D' THEN + 'Deduction' ELSE 'Liability' END 		
		SELECT @msg = @msg + ' Code  ' + cast(@dlcode as varchar(30)) + '  must be a G-Rate of Gross or R-Routine method.', @rcode = 1
		GOTO bspexit
	END


	SELECT @msg=Description, @PRPreTax=PreTax
	FROM PRDL
	WHERE PRCo=@prco and DLCode=@edlcode

	IF @@rowcount = 0
	BEGIN
		SELECT @msg = 'PR Deduction Code not on file!', @rcode = 1
		GOTO bspexit
	END
	
	IF @PRPreTax='N'
	BEGIN
		SELECT @msg = 'PR Deduction Code is not marked as a pre tax deduction!', @rcode = 1
		GOTO bspexit
	END	


 END  

   bspexit:

   RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRPreTaxEDLVal] TO [public]
GO
