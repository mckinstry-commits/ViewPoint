SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   proc [dbo].[vspHQTaxCodeVal]
   /***************************************************
   * CREATED BY    : DC 09/18/09 
   * LAST MODIFIED : 
   *             
   * Used in:
   *	POEntryItem
   *
   * Usage:
   *   Gets the taxrate, and GST Tax Rate and validates
   *	that the tax code is valid for the tax type. TaxType 3 is valid only for ValueAdd taxcodes.
   *
   * Input:
   *	@taxgroup         
   *	@taxcode  
   *	@compdate
   *	@taxtype
   *
   * Output:
   *	@taxrate	
   *	@gstrate 
   *    @msg          
   *
   * Returns:
   *	0             success
   *   1             error
   *************************************************/
   	(@taxgroup bGroup = null, @taxcode bTaxCode = null, @compdate bDate = null, @taxtype int = null,
	@taxrate bRate=NULL output, @gstrate bRate=NULL output, @taxphase bPhase=NULL output, 
	@taxjcctype bJCCType=NULL output, @pstrate bRate = NULL output, @msg varchar(60)=null output)
   as
   
	set nocount on
   
	declare @rcode int, @valueadd char(1)
   
	SELECT @rcode = 0

	IF @taxgroup is null
		BEGIN
   		SELECT @msg = 'Missing Tax Group', @rcode = 1
   		GOTO vspexit
   		END
	IF @taxcode is null
   		BEGIN
   		SELECT @msg = 'Missing Tax Code', @rcode = 1
   		GOTO vspexit
   		END
	IF @taxtype is null
   		BEGIN
   		SELECT @msg = 'Missing Tax Type', @rcode = 1
   		GOTO vspexit
   		END
	IF @compdate is null
		/*if Compdate is null then always use New Rate */
   		BEGIN
   		SELECT @compdate='12/31/2070'
   		END

	/* Get tax rates for this TaxCode */
	exec @rcode = vspHQTaxRateGet @taxgroup, @taxcode, @compdate, @valueadd output, @taxrate output, @taxphase output, 
		@taxjcctype output, @gstrate output, @pstrate output,
		NULL, NULL, NULL, NULL, NULL, NULL, @msg output
	IF @rcode <> 0
	    BEGIN
	    SELECT @rcode = 1
	    GOTO vspexit
	    END
    ELSE
        -- Tax Type 3 - VAT should only be used with ValueAdd tax codes
	    IF (@valueadd = 'Y' and @taxtype <> 3) or (@valueadd = 'N' and @taxtype = 3)
			BEGIN
			SELECT @msg = 'Taxcode is invalid for Tax Type: ' + convert(char(1), @taxtype), @rcode = 1
   			GOTO vspexit
			END
       
   
   vspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHQTaxCodeVal] TO [public]
GO
