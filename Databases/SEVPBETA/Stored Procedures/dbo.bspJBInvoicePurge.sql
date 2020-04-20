SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspJBInvoicePurge]
/****************************************************************************
* CREATED: bc 03/29/00
* MODIFIED: kb 7/25/1 - issue #13919
* 			kb 9/13/1 - issue #13919
*    		kb 10/2/1 - issue #14547
*			kb 8/2/2 - issue #18143 - don't update billstatus in JCCD if purging
*			TJL 11/06/02 - Issue #18740, If Purging, set AuditYN to 'N'
*			TJL 11/09/07 - Issue #23357, Add more specific conditions regarding which invoices get purged
*			GG 02/25/08 - #120107 - separate sub ledger close - use AR close month
*
* USAGE:  displays values that are to be displayed at the top of the Release Retainage form
*
*
* INPUT PARAMETERS
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs
* RETURN VALUE
*   0         success
*   1         Failure
****************************************************************************/
(@jbco bCompany, @opt varchar(10), @contract bContract, @cust bCustomer,
	@billmth bMonth, @beginbill int, @endbill int,
	@invdate bDate, @chkmth bYN, @nodelete tinyint output, @errmsg varchar(255) output)
as

set nocount on
   
/*generic declares */
declare @rcode int, @glco bCompany, @arco bCompany, @custgroup bGroup, @lastclosedmth bMonth

select @rcode=0, @nodelete = 0

select @glco = GLCo
from bJCCO with (nolock)
where JCCo = @jbco

select @lastclosedmth = LastMthARClsd	-- #120107 - use AR close month
from bGLCO with (nolock)
where GLCo = @glco
   
if @opt = 'Contract'
	begin	/* Begin by Contract */
	if @contract is null
   		begin
  		select @errmsg = 'Missing contract input', @rcode = 1
  		goto bspexit
  		end
   
   	if @chkmth = 'Y'
   		begin
		update n 
		set n.Purge = 'Y', n.AuditYN = 'N' 
		from bJBIN n
		where n.JBCo = @jbco and n.Contract = @contract
   			and (n.InvStatus in ('I', 'N') or
			(n.InvStatus = 'A' and not exists(select 1 from bJBAR r where r.Co = n.JBCo and r.Mth = n.BillMonth and r.BillNumber = n.BillNumber)))

		delete n 
		from bJBIN n
		where n.JBCo = @jbco and n.Contract = @contract
   			and (n.InvStatus in ('I', 'N') or
			(n.InvStatus = 'A' and not exists(select 1 from bJBAR r where r.Co = n.JBCo and r.Mth = n.BillMonth and r.BillNumber = n.BillNumber)))
		if @@rowcount > 0 select @nodelete = 1
		end
	else
		begin
		update n 
		set n.Purge = 'Y', n.AuditYN = 'N' 
		from bJBIN n
		where n.JBCo = @jbco and n.Contract = @contract and n.BillMonth <= @lastclosedmth
			and (n.InvStatus in ('I', 'N') or
			(n.InvStatus = 'A' and not exists(select 1 from bJBAR r where r.Co = n.JBCo and r.Mth = n.BillMonth and r.BillNumber = n.BillNumber)))

		delete n 
		from bJBIN n
		where n.JBCo = @jbco and n.Contract = @contract and n.BillMonth <= @lastclosedmth
   			and (n.InvStatus in ('I', 'N') or
			(n.InvStatus = 'A' and not exists(select 1 from bJBAR r where r.Co = n.JBCo and r.Mth = n.BillMonth and r.BillNumber = n.BillNumber)))

		if @@rowcount >0 select @nodelete = 1
		end
   	end		/* End by Contract */
   
if @opt = 'Customer'
	begin	/* Begin by Customer */
   	select @arco = ARCo
   	from bJCCO with (nolock)
   	where JCCo = @jbco
   
   	select @custgroup = CustGroup
   	from bHQCO with (nolock)
	where HQCo = @arco
   
	if @cust is null
		begin
		select @errmsg = 'Missing customer input', @rcode = 1
		goto bspexit
		end
   
   	if @chkmth = 'Y'
       	begin
   		update n 
   		set n.Purge = 'Y', n.AuditYN = 'N' 
   		from bJBIN n
   		where n.JBCo = @jbco and n.CustGroup = @custgroup and n.Customer = @cust
   			and (n.InvStatus in ('I', 'N') or
			(n.InvStatus = 'A' and not exists(select 1 from bJBAR r where r.Co = n.JBCo and r.Mth = n.BillMonth and r.BillNumber = n.BillNumber)))
   
		delete n
		from bJBIN n
   		where n.JBCo = @jbco and n.CustGroup = @custgroup and n.Customer = @cust
   			and (n.InvStatus in ('I', 'N') or
			(n.InvStatus = 'A' and not exists(select 1 from bJBAR r where r.Co = n.JBCo and r.Mth = n.BillMonth and r.BillNumber = n.BillNumber)))
		if @@rowcount > 0 select @nodelete = 1
		end
	else
		begin
   		update n 
   		set n.Purge = 'Y', n.AuditYN = 'N' 
   		from bJBIN n
   		where n.JBCo = @jbco and n.CustGroup = @custgroup and n.Customer = @cust 
   			and n.BillMonth <= @lastclosedmth
   			and (n.InvStatus in ('I', 'N') or
			(n.InvStatus = 'A' and not exists(select 1 from bJBAR r where r.Co = n.JBCo and r.Mth = n.BillMonth and r.BillNumber = n.BillNumber)))
   
		delete n
		from bJBIN n
   		where n.JBCo = @jbco and n.CustGroup = @custgroup and n.Customer = @cust 
   			and n.BillMonth <= @lastclosedmth
   			and (n.InvStatus in ('I', 'N') or
			(n.InvStatus = 'A' and not exists(select 1 from bJBAR r where r.Co = n.JBCo and r.Mth = n.BillMonth and r.BillNumber = n.BillNumber)))
		if @@rowcount > 0 select @nodelete = 1
		end
   	end		/* End by Customer */
   
if @opt = 'BillNumber'
   	begin	/* Begin by BillNumber */
   	if @billmth is null or @beginbill is null or @endbill is null
		begin
		select @errmsg = 'Missing bill number inputs', @rcode = 1
		goto bspexit
		end
   
   	if @chkmth = 'Y'
		begin
   		update n 
   		set n.Purge = 'Y', n.AuditYN = 'N' 
   		from bJBIN n
   		where n.JBCo = @jbco and n.BillMonth = @billmth and n.BillNumber >= @beginbill 
   			and n.BillNumber <= @endbill
   			and (n.InvStatus in ('I', 'N') or
			(n.InvStatus = 'A' and not exists(select 1 from bJBAR r where r.Co = n.JBCo and r.Mth = n.BillMonth and r.BillNumber = n.BillNumber)))
   
		delete n
		from bJBIN n
   		where n.JBCo = @jbco and n.BillMonth = @billmth and n.BillNumber >= @beginbill 
   			and n.BillNumber <= @endbill
   			and (n.InvStatus in ('I', 'N') or
			(n.InvStatus = 'A' and not exists(select 1 from bJBAR r where r.Co = n.JBCo and r.Mth = n.BillMonth and r.BillNumber = n.BillNumber)))
		if @@rowcount >0 select @nodelete = 1
		end
	else
		begin
   		update n 
   		set n.Purge = 'Y', n.AuditYN = 'N' 
   		from bJBIN n
   		where n.JBCo = @jbco and n.BillMonth = @billmth and n.BillNumber >= @beginbill 
   		  	and n.BillNumber <= @endbill and n.BillMonth <= @lastclosedmth
   			and (n.InvStatus in ('I', 'N') or
			(n.InvStatus = 'A' and not exists(select 1 from bJBAR r where r.Co = n.JBCo and r.Mth = n.BillMonth and r.BillNumber = n.BillNumber)))
   
		delete n
		from bJBIN n
   		where n.JBCo = @jbco and n.BillMonth = @billmth and n.BillNumber >= @beginbill 
   			and n.BillNumber <= @endbill and n.BillMonth <= @lastclosedmth
   			and (n.InvStatus in ('I', 'N') or
			(n.InvStatus = 'A' and not exists(select 1 from bJBAR r where r.Co = n.JBCo and r.Mth = n.BillMonth and r.BillNumber = n.BillNumber)))
		if @@rowcount >0 select @nodelete = 1
		end
   	end		/* End by Bill Number */
   
if @opt = 'Date'
   	begin	/* Begin by Date */
   	if @invdate is null
		begin
		select @errmsg = 'Missing invoice date input', @rcode = 1
		goto bspexit
		end
   
   	if @chkmth = 'Y'
		begin
   		update n 
   		set n.Purge = 'Y', n.AuditYN = 'N' 
   		from bJBIN n
   		where n.JBCo = @jbco and n.InvDate <= @invdate
      		and (n.InvStatus in ('I', 'N') or
			(n.InvStatus = 'A' and not exists(select 1 from bJBAR r where r.Co = n.JBCo and r.Mth = n.BillMonth and r.BillNumber = n.BillNumber)))

		delete n
		from bJBIN n
   		where n.JBCo = @jbco and n.InvDate <= @invdate
   			and (n.InvStatus in ('I', 'N') or
			(n.InvStatus = 'A' and not exists(select 1 from bJBAR r where r.Co = n.JBCo and r.Mth = n.BillMonth and r.BillNumber = n.BillNumber)))
		if @@rowcount >0 select @nodelete = 1
		end
	else
		begin
   		update n 
   		set n.Purge = 'Y', n.AuditYN = 'N' 
   		from bJBIN n
   		where n.JBCo = @jbco and n.InvDate <= @invdate and n.BillMonth <= @lastclosedmth
   			and (n.InvStatus in ('I', 'N') or
			(n.InvStatus = 'A' and not exists(select 1 from bJBAR r where r.Co = n.JBCo and r.Mth = n.BillMonth and r.BillNumber = n.BillNumber)))
   
		delete n
		from bJBIN n
   		where n.JBCo = @jbco and n.InvDate <= @invdate and n.BillMonth <= @lastclosedmth
   			and (n.InvStatus in ('I', 'N') or
			(n.InvStatus = 'A' and not exists(select 1 from bJBAR r where r.Co = n.JBCo and r.Mth = n.BillMonth and r.BillNumber = n.BillNumber)))
		if @@rowcount >0 select @nodelete = 1
		end
	end
   
bspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBInvoicePurge] TO [public]
GO
