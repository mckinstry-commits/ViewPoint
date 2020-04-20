SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[vspAPHQTaxCodeVal]
   /***************************************************
   * CREATED BY    : MV 06/25/08 
   * LAST MODIFIED : MV 02/04/10 - #136500 added NULL param to bspHQTaxRateGetAll 
   *				 MV 10/25/11 - TK-09243 added NULL param to bspHQTaxRateGetAll
   *             
   *
   * Usage:
   *   For APEntryDetail, APUnapprovedItem, APRecurInvItem gets the taxrate and validates
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
   *    @msg          
   *
   * Returns:
   *	0             success
   *   1             error
   *************************************************/
   	(@taxgroup bGroup = null, @taxcode bTaxCode = null, @compdate bDate = null, @taxtype int = null,
	@taxrate bRate output, @msg varchar(60)=null output)
   as
   
   set nocount on
   
   declare @rcode int, @valueadd char(1)
   
   select @rcode = 0

	if @taxgroup is null
	begin
   	select @msg = 'Missing Tax Group', @rcode = 1
   	goto vspexit
   	end
	if @taxcode is null
   	begin
   	select @msg = 'Missing Tax Code', @rcode = 1
   	goto vspexit
   	end
	if @taxtype is null
   	begin
   	select @msg = 'Missing Tax Type', @rcode = 1
   	goto vspexit
   	end
	if @compdate is null
	/*if Compdate is null then always use New Rate */
   	begin
   	select @compdate='12/31/2070'
   	end

   /* Get tax rate for this TaxCode */
	exec @rcode = bspHQTaxRateGetAll @taxgroup, @taxcode, @compdate, @valueadd output, @taxrate output, null, null,
    null, null, null, null, null, null, NULL, NULL,@msg output
	if @rcode <> 0
	    begin
	    select @rcode = 1
	    goto vspexit
	    end
    else
        -- Tax Type 3 - VAT should only be used with ValueAdd tax codes
	    if (@valueadd = 'Y' and @taxtype <> 3) or (@valueadd = 'N' and @taxtype = 3)
	    begin
	    select @msg = 'Taxcode is invalid for Tax Type: ' + convert(char(1), @taxtype), @rcode = 1
   	    goto vspexit
	    end
	
      
   
   vspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPHQTaxCodeVal] TO [public]
GO
