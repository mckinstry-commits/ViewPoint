SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspPREmployeeInfoGet]
/*************************************
* CREATED:	CHS	11/15/2010	- issue #138416
* MODIFIED:
* 
* Returns commonly needed info for PR Employee Load Procedures
*
* Input:
*	@prco			PR Company
*
* Output:
*	@premco					EM Company
*	@prapco					AP Company
*	@prglco					GL Company
*	@MessageFileStatusYN	Message filing status flag
*	@msg					Error message				
*
* Return code:
*	0 = success, 1 = error 
**************************************/
(@prco bCompany, 
	@premco bCompany OUTPUT, 
	@prglco bCompany OUTPUT, 
	@MessageFileStatusYN bYN OUTPUT,
	@msg VARCHAR(60) OUTPUT)

AS
SET NOCOUNT ON

DECLARE @rcode INT

SELECT @rcode = 0
 
--get PRCO info  
SELECT
	@premco = EMCo, 
	@MessageFileStatusYN = MessageFileStatusYN,
	@prglco = GLCo
FROM dbo.bPRCO (NOLOCk)
WHERE PRCo = @prco
IF @@ROWCOUNT = 0
	BEGIN
	SELECT @msg = 'Company# ' + convert(VARCHAR,@prco) + ' not setup in PR', @rcode = 1
  	GOTO vspexit
  	END

vspexit:
  	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPREmployeeInfoGet] TO [public]
GO
