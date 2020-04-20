SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspARInvoiceVal]
   /***********************************************************
   * CREATED BY	: MH 9/8/99
   * modified     : bc 9/24/99
   *
   * USAGE:
   * Validate an invoice number in ARTH
   *
   * INPUT PARAMETERS
   *   ARCo      AR Co to validate against
   *   invoice #
   *
   * OUTPUT PARAMETERS
   *   @msg      error message if error occurs
   * RETURN VALUE
   *   0         success
   *   1
   ************************************************************/
   (@arco bCompany = 0, @invoice varchar(10) = null, @customer bCustomer = null, 
   	@msg varchar(60) output )
   
   as
   
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   if @arco is null or @arco = 0
   	begin
      	select @msg = 'Missing AR Company!', @rcode =1
      	goto bspexit
      	end
   
   if @invoice is null
      	begin
      	select @msg = 'Missing Invoice Number!',@rcode =1
      	goto bspexit
      	end
   
   select  @msg = Description
   from ARTH 
   where ARCo = @arco and ltrim(Invoice) = ltrim(@invoice) and Customer=@customer
   if @@rowcount = 0
   	begin
   	select @msg = 'Invoice not on file!', @rcode = 1
   	goto bspexit
   	end
   
   bspexit:
   	if @rcode<>0 select @msg=@msg	--+ char(13) + char(10) + '[dbo.bspARInvoiceVal]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspARInvoiceVal] TO [public]
GO
