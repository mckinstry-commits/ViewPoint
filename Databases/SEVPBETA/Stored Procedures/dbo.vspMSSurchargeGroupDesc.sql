SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*************************************
* Created By:	Dan So 02/01/2010 - Issue: #129350
* Modified by:
*
* Called from MSSurchargeGroups to return Surcharge Group key description
*
* INPUT:
*	@msco			MS Company
*	@SurchargeGroup	Smallint
*
* OUTPUT:
*	@msg		Description or Error message
*	@rcode		0 - Success
*				1 - Error
*
**************************************/
 --CREATE PROC [dbo].[vspMSSurchargeGroupDesc]
 CREATE PROC [dbo].[vspMSSurchargeGroupDesc]
 
(@msco bCompany, @SurchargeGroup smallint, @Validate bYN,
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
		
	IF @SurchargeGroup IS NULL
		BEGIN
			SELECT @msg = 'Missing Surcharge Group', @rcode = 1
			GOTO vspexit
		END
		
		
	-------------------------------
	-- GET SURCHARGE DESCRIPTION --
	-------------------------------
	SELECT @msg = Description
	  FROM MSSurchargeGroups
	 WHERE MSCo = @msco
	   AND SurchargeGroup = @SurchargeGroup
	   
	   
	------------------------------
	-- VALIDATE SURCHARGE GROUP --
	------------------------------
	IF (@Validate = 'Y') AND (@msg IS NULL)
		BEGIN
			SET @msg = 'Invalid Surcharge Group'
			SET @rcode = 1
			GOTO vspexit
		END
		
	   
	   
	-----------------
	-- END ROUTINE --
	-----------------
	vspexit:
		IF @rcode <> 0 
			SET @msg = isnull(@msg,'')
			
		RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspMSSurchargeGroupDesc] TO [public]
GO
