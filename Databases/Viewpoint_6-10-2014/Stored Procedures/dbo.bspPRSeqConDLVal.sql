SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[bspPRSeqConDLVal]
/***********************************************************
* CREATED BY:		CHS	11/10/2010	- #140541 - added pre-tax exclusion
* MODIFIED By:		DAN SO 08/15/2012 - TK-16990 - need to return SubjToArrearsPayback
*
* USAGE:
* validates PR Dedn/Liab Code - does not allow pre-tax to be added.
*
* INPUT 
*   @prco   			PR Company
*   @edltype			Code type to validate (D,L, or X IF either)
*   @edlcode   			DL Code to validate
*
* OUTPUT 
*	@SubjToArrPayYN		Subject To Arrears/Payback flag
*   @msg      			Code description or error message
*
* RETURN VALUE
*   0         success
*   1         Failure
******************************************************************/
(@prco bCompany = 0, @edltype char(1) = null, @edlcode bEDLCode = null, 
 @SubjToArrPayYN bYN output, @msg varchar(250) output)

	AS
	SET NOCOUNT ON

	DECLARE @rcode int, @PreTax bYN

	SELECT @rcode = 0, @PreTax = 'N'

	IF @prco IS NULL
		BEGIN
		SELECT @msg = 'Missing PR Company!', @rcode = 1
		GOTO bspexit
		END
		
	IF @edltype IS NULL or @edltype not in ('D','L','X')
		BEGIN
		SELECT @msg = 'Missing or invalid Deduction/Liability Type!', @rcode = 1
		GOTO bspexit
		END
		
	IF @edlcode IS NULL
		BEGIN
		SELECT @msg = CASE @edltype WHEN 'D' THEN 'Missing Deduction Code!'
									WHEN 'L' THEN 'Missing Liability Code!'
									ELSE 'Missing Dedn/Liab Code!' END, @rcode = 1
		GOTO bspexit
		END
   
	-- validate Dedn/Liab code -- TK-16990
	SELECT @msg = Description, @PreTax = PreTax, @SubjToArrPayYN = ISNULL(SubjToArrearsPayback, 'N')
	FROM PRDL
	WHERE PRCo = @prco 
		AND DLCode = @edlcode 
		AND (DLType = @edltype or @edltype = 'X')
		
	IF @@rowcount = 0
		BEGIN
		SELECT @msg = CASE @edltype WHEN 'D' THEN 'Invalid Deduction Code!'
									WHEN 'L' THEN 'Invalid Liability Code!'
									ELSE 'Invalid Dedn/Liab Code!' END, @rcode = 1
		GOTO bspexit
		END

	IF @PreTax = 'Y'
		BEGIN
		SELECT @msg = 'Deduction code ' + cast(@edlcode as varchar(20)) + ' is flagged as Pre-Tax and cannot be manually added.  See the F1 help for more information.', @rcode = 1
		END

   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRSeqConDLVal] TO [public]
GO
