SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspPRROEOtherMoniesCodeVal]
/************************************************************************
* CREATED:	KK 01/01/2013   
* MODIFIED: KK 03/18/2103 - No need to check for 'X' condition. Fixed in form code.
*
* USAGE: Canadian ROE Validation for PR Employee ROE History, Other Payments tab
*				-	When Category is "OM-OtherMonies", a valid Other Monies Code is required
*    
* INPUT: Category				2 character combobox selection
*		 Other Monies Code		1 character combobox selection
*
* OUTPUT: message if failed
*
* RETURNS:	0 if successfull 
*			1 and error msg if failed
*
*************************************************************************/
(@Category varchar(2),
 @OtherMoniesCode char = NULL,
 @msg varchar(255) = '' OUTPUT)

AS
BEGIN
	SET NOCOUNT ON

	IF @Category = 'OM' AND (@OtherMoniesCode = '' OR @OtherMoniesCode IS NULL)
	BEGIN
		SELECT @msg = 'Other Monies Code - valid value required when Category is OM-Other Monies'
		RETURN 1
	END
	
	RETURN 0

END


GO
GRANT EXECUTE ON  [dbo].[vspPRROEOtherMoniesCodeVal] TO [public]
GO
