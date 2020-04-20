SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*************************************
 * Created By:	DAN SO 04/02/2010 - ISSUE: #129350
 * Modified by:
 *
 * called from MSSurchargeCodes to validate and return rev code key description 
 *
 * Input:
 *	@EMGroup	EM Group
 *	@PayCode	MS Rev Code
 *
 * Output:
 *	@msg		Description or Error Message
 *	@rcode		0 - Success
 *				1 - Failure
 *
 **************************************/
 --CREATE PROCEDURE [dbo].[vspMSPSurchargeRevCodeVal]
 CREATE PROCEDURE [dbo].[vspMSPSurchargeRevCodeVal]
 
(@EMGroup bGroup = null, @RevCode bRevCode = null, @msg varchar(255) output)

	AS
	SET NOCOUNT ON
	

	DECLARE @rcode int

	-- PRIME VALUES --
	SET @rcode = 0
	
	----------------------------
	-- CHECK INPUT PARAMETERS --
	----------------------------
	IF @EMGroup IS NULL
		BEGIN
			SET @msg = 'Missing EM Group Parameter!'
			SET @rcode = 1
			GOTO vspexit
		END
		
	IF @RevCode IS NULL
		BEGIN
			SET @msg = 'Missing Rev Code Parameter!'
			SET @rcode = 1
			GOTO vspexit
		END	
		
		
	-------------------------------------
	-- VALIDATE PAYCODE FOR SURCHARGES --
	-------------------------------------
	-- VALID REVCODE? --
	IF NOT EXISTS(SELECT 1 FROM bEMRC WITH (NOLOCK) WHERE EMGroup = @EMGroup
													  AND RevCode = @RevCode)
		BEGIN
			SET @msg = 'Invalid RevCode!'
			SET @rcode = 1
			GOTO vspexit
		END
	
	-- VALID REVCODE FOR SURCHARGES --
	SELECT @msg = Description 
	  FROM bEMRC WITH (NOLOCK) 
	 WHERE EMGroup = @EMGroup 
	   AND RevCode = @RevCode
	   AND HaulBased = 'Y'
	   
	IF @@ROWCOUNT <> 1
		BEGIN
			SET @msg = 'Surcharge related RevCode must have ''Based on MS Haul Charge/Surcharge'' checked in EM Revenue Codes!'
			SET @rcode = 1
			GOTO vspexit
		END		
		

	-----------------
	-- END ROUTINE --
	-----------------
	vspexit:
		RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspMSPSurchargeRevCodeVal] TO [public]
GO
