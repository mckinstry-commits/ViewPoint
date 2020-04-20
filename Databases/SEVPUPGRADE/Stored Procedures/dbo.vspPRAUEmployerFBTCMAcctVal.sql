SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


	CREATE  procedure [dbo].[vspPRAUEmployerFBTCMAcctVal]
	/******************************************************
	* CREATED BY:	MV 03/17/11
	* MODIFIED By: 
	*
	* Usage:	Validates CM Acct and returns description and 
	*			returns default values.  
	*			Called from PRAUEmployerFBTItems.
	*
	* Input params:
	*
	*	@PRCo
	*	@CMAcct
	*
	* Output params:
	*	@BSBNumber
	*	@CMBankAcct	
	*	@CMAUAcctName	
	*	@Msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	(@PRCo bCompany, @CMAcct bCMAcct,
   		@BSBNumber VARCHAR(6) OUTPUT,
   		@CMBankAcct VARCHAR(30) OUTPUT,
   		@CMAUAcctName VARCHAR(26) OUTPUT,	
   		@Msg varchar(100) OUTPUT)
  	

	AS
	SET NOCOUNT ON
	DECLARE @rcode INT

	SELECT @rcode = 0
	
	IF @CMAcct IS NULL
	BEGIN
		SELECT @Msg = 'Missing CM Acct.', @rcode = 1
		GOTO  vspexit
	END

	IF EXISTS
		(
			SELECT 1 
			FROM dbo.CMAC
			JOIN dbo.PRCO ON PRCO.CMCo=CMAC.CMCo 
			WHERE PRCO.PRCo=@PRCo AND CMAC.CMCo=PRCO.CMCo AND CMAC.CMAcct=@CMAcct
		)
	BEGIN
		SELECT @BSBNumber = AUBSB,
		@CMBankAcct = BankAcct,
		@CMAUAcctName = AUAccountName,                    
		@Msg = Description
		FROM dbo.CMAC
		JOIN dbo.PRCO ON PRCO.CMCo=CMAC.CMCo 
		WHERE PRCO.PRCo=@PRCo AND CMAC.CMCo=PRCO.CMCo AND CMAC.CMAcct=@CMAcct
	END
	ELSE
	BEGIN
		SELECT @Msg = 'Invalid CM Account.', @rcode = 1
	END
	 
	vspexit:
	RETURN @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPRAUEmployerFBTCMAcctVal] TO [public]
GO
