SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspJBGetBillInvDate]
/***********************************************************
 * CREATED BY: kb 1/17/01
 * MODIFIED By :
 *
 * USAGE:
 *
 * INPUT PARAMETERS
 *   JBCo      JB Co to validate against
 *
 * OUTPUT PARAMETERS
 *   @msg      error message if error occurs otherwise Description of Contract
 * RETURN VALUE
 *   0         success
 *   1         Failure
 *****************************************************/
   
@jbco bCompany = 0, @billmth bMonth, @billnum int, @invdate bDate output,
	@custgroup bGroup output, @customer bCustomer output, @taxgroup bGroup output,
	@taxcode bTaxCode output, @taxrate bRate output, @msg varchar(255) output
   
as
set nocount on
   
declare @rcode int
select @rcode = 0
   
select @invdate = n.InvDate, @custgroup = n.CustGroup, @customer = n.Customer,
	@taxcode = a.TaxCode, @taxgroup = a.TaxGroup
from bJBIN n with (nolock)
join bARCM a with (nolock) on a.CustGroup = n.CustGroup and a.Customer = n.Customer
where n.JBCo = @jbco and n.BillMonth = @billmth and n.BillNumber = @billnum
   
if @taxcode is not null
	begin
	exec bspHQTaxRateGet @taxgroup, @taxcode, @invdate, @taxrate output, @msg = @msg output
	end

bspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBGetBillInvDate] TO [public]
GO
