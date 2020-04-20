SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspARReleaseContractValwithInfo]

(@jcco bCompany = 0, @contract bContract = null, @rectype tinyint output, @customer bCustomer output, @payterms bPayTerms output,   
	 @msg varchar(60) output)
as
set nocount on
   
/***********************************************************
* CREATED BY: TJL  04/28/09 - Issue #132992, Contract allowed without JCCo until Posting error
* MODIFIED By :	
*
*
* USAGE:
* validates JC contract - returns RecType, Customer and PayTerms
* 
* 
*
* INPUT PARAMETERS
*   JCCo		JC Co to validate against
*   Contract	Contract to validate
*
* OUTPUT PARAMETERS
*   @rectype
*	@customer
*	@payterms
*   @msg      error message if error occurs otherwise Description of Contract
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
   
declare @rcode int

select @rcode = 0

if @jcco is null
	begin
	select @msg = 'Missing JC Company.', @rcode = 1
	goto vspexit
	end

select 1
from JCCO with (nolock) where JCCo=@jcco
if @@rowcount = 0
	begin
	select @msg = 'JC Company invalid.', @rcode = 1
	goto vspexit
	end

if @contract is null
	begin
	select @msg = 'Missing Contract.', @rcode = 1
	goto vspexit
	end

select @msg = Description, @rectype = RecType, @customer = Customer, @payterms = PayTerms
from JCCM with (nolock)
where JCCo = @jcco and Contract = @contract
if @@rowcount = 0
	begin
	select @msg = 'Contract not on file.', @rcode = 1
	goto vspexit
	end

vspexit:
return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspARReleaseContractValwithInfo] TO [public]
GO
