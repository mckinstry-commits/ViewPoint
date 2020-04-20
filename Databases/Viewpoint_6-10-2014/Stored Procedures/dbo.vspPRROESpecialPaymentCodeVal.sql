SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspPRROESpecialPaymentCodeVal]
/************************************************************************
* CREATED:	KK 01/01/2013   
* MODIFIED: KK 03/18/2103 - No need to check for 'X' condition. Fixed in form code.
*
* USAGE: Canadian ROE Validation for PR Employee ROE History, Other Payments tab
*				-	When Category is "SP-SpecialPayments", a valid Speical Payment Code
*    
* INPUT: Category				2 character combobox selection
*		 Special Payment Code	3 character combobox selection
*
* OUTPUT: message if failed
*
* RETURNS:	0 if successfull 
*			1 and error msg if failed
*
*************************************************************************/
(@Category varchar(2),
 @SpecialPaymentCode varchar(3) = NULL,
 @msg varchar(255) = '' OUTPUT)

AS
BEGIN
	SET NOCOUNT ON

	IF @Category = 'SP' AND (@SpecialPaymentCode = '' OR @SpecialPaymentCode IS NULL)
	BEGIN
		SELECT @msg = 'Special Payment Code - valid value required when Category is SP-Special Payment'
		RETURN 1
	END
	
	RETURN 0

END
GO
GRANT EXECUTE ON  [dbo].[vspPRROESpecialPaymentCodeVal] TO [public]
GO
