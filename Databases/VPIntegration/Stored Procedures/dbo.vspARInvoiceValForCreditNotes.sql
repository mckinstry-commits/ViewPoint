SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspARInvoiceValForCreditNotes]
/***********************************************************
* CREATED BY:	TJL 11/27/07 - Issue #29904
* MODIFIED BY:
*
* USAGE:
*	Validate an invoice number in ARTH for CreditNote Company or Current Company
*
* INPUT PARAMETERS
*   @arco				Current ARCo when Credit Note ARCo not used
*	@arcoforcreditnote	Credit Note ARCo 
*	@customer			Customer
*   invoice #
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs
* RETURN VALUE
*   0         success
*   1
************************************************************/
(@arco bCompany = null, @arcoforcreditnote bCompany = null, @custgroup bGroup = null, @customer bCustomer = null,
	@invoice varchar(10) = null, @msg varchar(60) output )
   
as
set nocount on
   
declare @rcode int
   
select @rcode = 0
   
if @arco is null
	begin
	select @msg = 'Missing module AR Company value.', @rcode = 1
	goto vspexit
	end

if @custgroup is null
	begin
	select @msg = 'Missing CustGroup value.', @rcode = 1
	goto vspexit
	end

if @customer is null
	begin
	select @msg = 'Missing Customer value.', @rcode = 1
	goto vspexit
	end
   
if @invoice is null
  	begin
  	select @msg = 'Missing Invoice Number.',@rcode =1
  	goto vspexit
  	end

/* Invoice Validation:  If a CreditNote ARCo value is used, then the invoice will be validated
   against this ARCo otherwise the module/current ARCo value will be used.  Both ARCo values will
   be using the same HQCo_CustGroup enforced by ARCo Validation.  Invoice validation is further based
   upon CustGroup/Customer. */
select  @msg = Description
from ARTH 
where ARCo = isnull(@arcoforcreditnote, @arco) and CustGroup = @custgroup and Customer = @customer
	and ltrim(Invoice) = ltrim(@invoice)
if @@rowcount = 0
	begin
	select @msg = 'Invoice not on file for this Customer in AR Company ' + convert(varchar(3), isnull(@arcoforcreditnote, @arco)) +
		'. ', @rcode = 1
	goto vspexit
	end
   
vspexit:
if @rcode <> 0 select @msg = @msg 
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspARInvoiceValForCreditNotes] TO [public]
GO
