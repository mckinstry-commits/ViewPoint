SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*************************************
 * Created By:	DAN SO 04/02/2010 - ISSUE: #129350
 * Modified by:
 *
 * called from MSSurchargeCodes to validate and return pay code key description 
 *
 * Input:
 *	@MSCo		MS Company
 *	@PayCode	MS Pay Code
 *
 * Output:
 *	@msg		Description or Error Message
 *	@rcode		0 - Success
 *				1 - Failure
 *
 **************************************/
 --CREATE PROCEDURE [dbo].[vspMSPSurchargePayCodeVal]
 CREATE PROCEDURE [dbo].[vspMSPSurchargePayCodeVal]
 
(@MSCo bCompany, @PayCode bPayCode, @msg varchar(255) output)

	AS
	SET NOCOUNT ON
	

	DECLARE @rcode int

	-- PRIME VALUES --
	SET @rcode = 0
	
	----------------------------
	-- CHECK INPUT PARAMETERS --
	----------------------------
	IF @MSCo IS NULL
		BEGIN
			SET @msg = 'Missing Company Parameter!'
			SET @rcode = 1
			GOTO vspexit
		END
		
	IF @PayCode IS NULL
		BEGIN
			SET @msg = 'Missing Pay Code Parameter!'
			SET @rcode = 1
			GOTO vspexit
		END	
		
		
	-------------------------------------
	-- VALIDATE PAYCODE FOR SURCHARGES --
	-------------------------------------
	-- VALID PAYCODE? --
	IF NOT EXISTS(SELECT 1 FROM bMSPC WITH (NOLOCK) WHERE MSCo = @MSCo 
													  AND PayCode = @PayCode)
		BEGIN
			SET @msg = 'Invalid PayCode!'
			SET @rcode = 1
			GOTO vspexit
		END
	
	-- VALID PAYCODE FOR SURCHARGES --
	SELECT @msg = Description 
	  FROM bMSPC WITH (NOLOCK) 
	 WHERE MSCo = @MSCo 
	   AND PayCode = @PayCode
	   AND PayBasis = 7
	   
	IF @@ROWCOUNT <> 1
		BEGIN
			SET @msg = 'Surcharge related PayCode must be based on ''7-Percent of Surcharge Material'' in MS Pay Codes!'
			SET @rcode = 1
			GOTO vspexit
		END		
		

	-----------------
	-- END ROUTINE --
	-----------------
	vspexit:
		RETURN @rcode


GO
GRANT EXECUTE ON  [dbo].[vspMSPSurchargePayCodeVal] TO [public]
GO
