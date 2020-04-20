SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*************************************
* Created By:  DAN SO 10/02/2009 - ISSUE #129350
* Modified By: 
*
*
* USAGE:	Validate Surcharge Material - Really just a valida material within Material Group
*			Could not locate a simple Material Validation procedure
*
*
* INPUT PARAMETERS
*	@msco				MS Company -- currently not used
*	@MatlGroup			Material Group
*	@SurchargeMaterial	SurchargeCode
*
* OUTPUT PARAMETERS
*	@Taxable	Surcharge Material Taxable?
*	@msg        Material Description OR error message
*   
* RETURN VALUE
*   0         Success
*   1         Failure
*
**************************************/
--CREATE PROC [dbo].[vspMSSurchargeMaterialVal]
CREATE  PROC [dbo].[vspMSSurchargeMaterialVal]
 
(@msco bCompany = NULL, @MatlGroup bGroup = NULL, @SurchargeMaterial bMatl = NULL,
	@Taxable bYN = NULL output,
	@msg varchar(255) = NULL output)

AS
SET NOCOUNT ON

	DECLARE	@rcode	int


	-- PRIME VALUES --
	SET @rcode = 0
	SET @Taxable = 'N'
	
	
	----------------------------------
	-- VALIDATE INCOMING PARAMETERS --
	----------------------------------
	IF @msco IS NULL
		BEGIN
			SELECT @msg = 'Missing MS Company', @rcode = 1
			GOTO vspexit
		END
		
	IF @SurchargeMaterial IS NULL
		BEGIN
			SELECT @msg = 'Missing Surcharge Material', @rcode = 1
			GOTO vspexit
		END
		
	------------------------------------
	-- GET MATERIAL SURCHARGE Taxable --
	------------------------------------
	SELECT @msg = Description, @Taxable = Taxable
	  FROM HQMT WITH (NOLOCK)
	 WHERE MatlGroup = @MatlGroup
	   AND Material = @SurchargeMaterial
	   AND Type <> 'E'

	IF @@ROWCOUNT = 0
		BEGIN
			SELECT @msg = 'Invalid Material', @rcode = 1
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
GRANT EXECUTE ON  [dbo].[vspMSSurchargeMaterialVal] TO [public]
GO
