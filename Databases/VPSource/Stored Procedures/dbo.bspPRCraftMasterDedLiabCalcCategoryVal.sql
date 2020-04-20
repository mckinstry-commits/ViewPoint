SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[bspPRCraftMasterDedLiabCalcCategoryVal]
   /***********************************************************
    * CREATED BY: MV 10/19/10
    * MODIFIED By : 
    *
    * USAGE:
    * validates PR Dedn/Liab Code for PR Craft Master.
    *
    * INPUT 
    *   @prco   		PR Company
    *   @edltype		Code type to validate (D,L, or X if either)
    *   @edlcode   	DL Code to validate
    *   @calccategory 	Calculation Category restriction (F,S,L,I,C,E, or A if any)
    *
    * OUTPUT 
    *   @edltypeout	Code type (D or L)
    *   @method		Calculation Method
    *   @msg  		Code description or error message
    *
    * RETURN VALUE
    *   0         success
    *   1         Failure
    ******************************************************************/
   	(@prco bCompany = 0, @edltype char(1) = null, @edlcode bEDLCode = null, @calccategory varchar (1) = 'A',
   	 @edltypeout char(1) output, @method varchar(10) output, @msg varchar(250) output)
	AS
	SET NOCOUNT ON
   
	DECLARE @rcode int, @calcctgryout varchar(1), @PreTax bYN
   
	SELECT @rcode = 0
   
	IF @prco IS NULL
   		BEGIN
   		SELECT @msg = 'Missing PR Company!', @rcode = 1
   		GOTO bspexit
   		END
	IF @edltype IS NULL OR @edltype NOT IN ('D','L','X')
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
   
	-- validate Dedn/Liab code
	SELECT @msg = Description, @edltypeout = DLType, @method = Method,
		@calcctgryout = CalcCategory, @PreTax=PreTax
	FROM PRDL
	WHERE PRCo = @prco AND DLCode = @edlcode AND (DLType = @edltype OR @edltype = 'X')
	IF @@rowcount = 0
		BEGIN
		SELECT @msg = CASE @edltype WHEN 'D' THEN 'Invalid Deduction Code!'
									WHEN 'L' THEN 'Invalid Liability Code!'
									ELSE 'Invalid Dedn/Liab Code!' END, @rcode = 1
		GOTO bspexit
		END
	-- validate Calculation Category
	IF @PreTax = 'Y'
		BEGIN
		IF @calcctgryout <> 'C'
			BEGIN
			SELECT @msg = 'Invalid Calculation Category for this Pre-Tax Ded/Liab code.' + char(13)
   			SELECT @msg = @msg + 'Calculation Category must be Craft.', @rcode = 1
			GOTO bspexit
			END
		END
	IF @PreTax = 'N'
		BEGIN
   		IF @calcctgryout not in (@calccategory, 'A') 
			BEGIN
			SELECT @msg = 'Invalid Calculation Category for Ded/Liab code.' + char(13)
			SELECT @msg = @msg + 'Calculation Category must be '
			SELECT @msg = @msg + CASE @calccategory WHEN 'C' THEN 'Craft'
				WHEN 'F' THEN 'Fed' 
				WHEN 'S' THEN 'State'
				WHEN 'L' THEN 'Local' 
				WHEN 'I' THEN 'Insurance'
				WHEN 'E' THEN 'Employee' END
			SELECT @msg = @msg + ' or Any. ', @rcode = 1
			GOTO bspexit
			END
		END
   
   bspexit:
   	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRCraftMasterDedLiabCalcCategoryVal] TO [public]
GO
