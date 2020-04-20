SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*************************************
* Created By:	Dan So 10/02/2009 - Issue: #129350
* Modified by:
*
* Called from MSSurchargeCodes to return Surcharge Code key description
*
* INPUT:
*	@msco			MS Company
*	@SurchargeCode	MS Haul Code
*
* OUTPUT:
*	@msg		Description or Error message
*	@rcode		0 - Success
*				1 - Error
*
**************************************/
 --CREATE PROC [dbo].[vspMSSurchargeDesc]
 CREATE PROC [dbo].[vspMSSurchargeDesc]
 
(@msco bCompany, @SurchargeCode smallint, 
	@msg varchar(255) output)
	
AS
SET NOCOUNT ON

	DECLARE	@rcode int
	
	
	-- PRIME VARIABLES --
	SET @rcode = 0


	-------------------------------
	-- VALIDATE INPUT PARAMETERS --
	-------------------------------
	IF @msco IS NULL
		BEGIN
			SELECT @msg = 'Missing MS Company', @rcode = 1
			GOTO vspexit
		END
		
	IF @SurchargeCode IS NULL
		BEGIN
			SELECT @msg = 'Missing Surcharge Code', @rcode = 1
			GOTO vspexit
		END
		
		
	-------------------------------
	-- GET SURCHARGE DESCRIPTION --
	-------------------------------
	SELECT @msg = Description
	  FROM MSSurchargeCodes
	 WHERE MSCo = @msco
	   AND SurchargeCode = @SurchargeCode
	   
	   
	-----------------
	-- END ROUTINE --
	-----------------
	vspexit:
		IF @rcode <> 0 
			SET @msg = isnull(@msg,'')
			
		RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspMSSurchargeDesc] TO [public]
GO
