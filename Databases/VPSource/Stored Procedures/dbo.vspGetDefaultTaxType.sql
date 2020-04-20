SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   proc [dbo].[vspGetDefaultTaxType]
   /***************************************************
   * CREATED BY    : DAN SO 09/06/2011 - TK-07743 - used to set Default Tax Type
   * LAST MODIFIED : 
   *             
   * Used in:
   *	POItemDistributionLines
   *
   * Usage:
   *   Gets the Default Tax Type based on HQCountry
   *
   * Input:
   *	@Company	- Company         
   *
   * Output:
   *	@TaxType	
   *    @msg          
   *
   * Returns:
   *	0             success
   *	1             error
   *************************************************/
   	(@Company bCompany = NULL, 
   	@TaxType INT = NULL OUTPUT,
	@msg VARCHAR(60) = NULL OUTPUT)
	
	AS
	
	SET NOCOUNT ON
   
	DECLARE @rcode int
   
   
	-- CHECK INPUT PARAMETER(S) --	
	IF @Company IS NULL 
		BEGIN
   			SET @msg = 'Missing Company'
   			SET @rcode = 1
   			GOTO vspexit
   		END
   		
	-- PRIME VARIABLES --
	SET @rcode = 0
	SET @TaxType = 1	-- (1:Sales 2:Use 3:VAT)


	-- (1:Sales 2:Use 3:VAT) --
	SELECT @TaxType = CASE WHEN DefaultCountry = 'US' THEN 1 ELSE 3 END
	  FROM bHQCO with (nolock)
	 WHERE HQCo = @Company

   
   vspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspGetDefaultTaxType] TO [public]
GO
