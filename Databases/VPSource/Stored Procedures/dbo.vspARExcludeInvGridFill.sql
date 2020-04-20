SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspARExcludeInvGridFill    Script Date: 11/3/05 ******/
CREATE proc [dbo].[vspARExcludeInvGridFill]
/****************************************************************
* CREATED BY	: TJL 11/03/05 - Issue #28323, 6x recode
* 
*
* USAGE:
* 	Provide user a list of Invoices by Customer, RecType, and Contract
*
* INPUT PARAMETERS
*	@arco		-	AR Company
*	@custgroup	-	Customer Group
*	@customer	-	Customer
*	@rectype	-	Optional, RecType - No Input results in showing All invoices
*	@JCCo		-	Optional, JCCo - Absent unless 'Exclude by Contract' is selected, 
*									 then required.
*	@contract	-	Optional, Contract Number - Absent unless 'Exclude by Contract' is selected, 
*									 then optional.  No Input results in showing All contracts
*									 for this JCCo.
*	@showzero	-	When ShowZero chkbox set 'Y', show 0.00 value invoices
*
* OUTPUT PARAMETERS
*   @errmsg
*
*****************************************************************/
(@arco bCompany = null, @custgroup bGroup = null, @customer bCustomer = null,
	@rectype int = null, @jcco bCompany = null, @contract varchar(10) = null,
  	@showzero varchar(1) = 'N')
  
as
set nocount on
  
/* Declare Working variables */
declare @rcode int, @exclcontfromfc bYN
declare @errmsg varchar(256)

select @rcode=0
  
if @arco is null
	begin
  	select @errmsg = 'AR Company is missing.', @rcode = 1
  	goto vspexit
  	end
if @custgroup is null
  	begin
  	select @errmsg = 'AR Customer Group is missing.', @rcode = 1
  	goto vspexit
  	end
if @customer is null
  	begin
  	select @errmsg = 'AR Customer is missing.', @rcode = 1
  	goto vspexit
  	end

/* Get ExcludeContFromFC value for this customer */
select @exclcontfromfc = ExclContFromFC
from bARCM with (nolock)
where CustGroup = @custgroup and Customer = @customer
  
/* Get record set based on this Company, Customer, and optional RecType and Contract.
   The use of ARTH.AmountDue here is extremely fast and the AmountDue field has
   proven accurate upon a detailed review of the bspARTHUpdate process. */
select Invoice, Mth, ARTrans, TransDate, DueDate, Contract, AmountDue, ExcludeFC
from bARTH  with (nolock)
where ARCo = @arco and CustGroup = @custgroup and Customer = @customer
  	and Mth = AppliedMth and ARTrans = AppliedTrans
  	and ARTransType in ('I', 'F', 'R')
  	and AmountDue <> case when @showzero = 'N' then 0 else -9999999999.99 end
	and RecType = isnull(@rectype, RecType)
	and isnull(JCCo, 0) = isnull(@jcco, isnull(JCCo,0))
	and isnull(Contract, '') = case when @exclcontfromfc = 'Y' then '' else isnull(@contract, isnull(Contract, ''))end
order by Invoice, Mth, ARTrans
  
if @@rowcount = 0
  	begin
  	select @errmsg = 'No invoices were returned for display for Customer ' + convert(varchar(10),@customer), @rcode = 7
  	goto vspexit
  	end
  
vspexit:
if @rcode <> 0 select @errmsg = @errmsg		--+ char(13) + char(10) + char(13) + char(10) + '[vspARExcludeInvGridFill]'
  
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspARExcludeInvGridFill] TO [public]
GO
