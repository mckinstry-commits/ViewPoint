SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[vspPRCraftMasterPreTaxDedVal]
   /***********************************************************
    * CREATED BY: MV 10/20/10
    * MODIFIED By : 
    *
    * USAGE:
    * validates PR Pre Tax Dedn Code delete for PR Craft Master.
    *
    * INPUT 
    *   @prco   		PR Company
    *   @edltype		Code type to validate (D,L, or X if either)
    *   @edlcode   	DL Code to validate
    *
    * OUTPUT 
    *   @msg  		Code description or error message
    *
    * RETURN VALUE
    *   0         success
    *   1         Failure
    ******************************************************************/
   	(@prco bCompany = 0, @edlcode bEDLCode,
		@craft varchar(10), @msg varchar(250) output)
	AS
	SET NOCOUNT ON
   
	DECLARE @rcode int, @CraftFlag bYN, @ErrMsg varchar(200)
   
	SELECT @rcode = 0, @CraftFlag = 'N', @ErrMsg = ''
   
	IF @prco IS NULL
	BEGIN
		SELECT @msg = 'Missing PR Company!', @rcode = 1
		RETURN @rcode
	END
	IF @edlcode IS NULL
	BEGIN
		SELECT @msg = CASE @edlcode WHEN 'D' THEN 'Missing Deduction Code!'
									ELSE 'Missing Dedn/Liab Code!' END, @rcode = 1
		RETURN @rcode
	END
	IF @craft IS NULL OR @craft = ''
	BEGIN
		SELECT @msg = 'Missing Craft!', @rcode = 1
		RETURN @rcode
	END
   
	--Check if pre tax deduction exists in Craft/Class for this class
	IF EXISTS	(
					SELECT * 
					FROM dbo.PRCD
					WHERE PRCo=@prco 
						AND Craft=@craft
						AND DLCode=@edlcode                        
				)
	BEGIN
		SELECT @CraftFlag = 'Y'
		SELECT @ErrMsg = ' Craft/Class '
	END
	--Check if pre-tax deduction exists in Craft/Class Template for this class
	IF EXISTS	(
					SELECT * 
					FROM dbo.PRTD 
					WHERE PRCo=@prco 
						AND Craft=@craft
						AND DLCode=@edlcode                        
				)
	BEGIN
		SELECT @CraftFlag = 'Y'
		SELECT @ErrMsg = CASE @ErrMsg WHEN '' THEN 'Craft/Class Template' ELSE 	'Craft/Class, Craft/Class Template' END
	END
--	Check if pre-tax deduction exists in Craft Template for this class
	IF EXISTS	(
					SELECT * 
					FROM dbo.PRTI 
					WHERE PRCo=@prco 
						AND Craft=@craft
						AND EDLCode=@edlcode                        
				)
	BEGIN
		SELECT @CraftFlag = 'Y'
		SELECT @ErrMsg = CASE @ErrMsg WHEN '' THEN 'Craft Template' ELSE @ErrMsg + ', Craft Template' END
	END
   
	IF @CraftFlag = 'Y' 
	BEGIN
		SELECT @msg = 'Delete Pre-Tax deduction: ' 
			+ convert(varchar(10),@edlcode) + ' from '
			+ @ErrMsg 
			+ ' before deleting in Craft Master.'
			
		SELECT @rcode = 1
	END

			
   RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPRCraftMasterPreTaxDedVal] TO [public]
GO
