SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE proc [dbo].[vspJCGetContractAmtForMaxRetg]
/***********************************************************
* Creadted By: TJL	12/31/09 - Issue #129894, Max Retainage Enhancement
* Modified By:	
*	
*			
* Called from JC/PM Contract Master forms and returns the calculated
* maximum retainage amount based upon:
*
*	JCCM Percent of Contract setup value.
*	JCCM exclude Variations from Max Retainage by % value.
*	JCCI Non-Zero Retainage Percent items
*
*
* INPUT PARAMETERS
* JCCo			JC Co to validate against
* Contract		Contract to validate
* MaxRetgPct	Maximum Retainage Percent of Contract value		
* Exclude Flag	ExclACOfromMaxRetgYN flag
*
* OUTPUT PARAMETERS
* @maxretgamt
* @msg			error message if error occurs otherwise Description of Contract
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
(@jcco bCompany = 0, @contract bContract = null, @maxretgpct bPct = 0, @inclchgordersinmax bYN = 'Y',
 @maxretgamt bDollar output, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @maxretgamt = 0

if @jcco is null
  	begin
  	select @msg = 'Missing JC Company!', @rcode = 1
  	goto vspexit
  	end

if @contract is null
  	begin
  	select @msg = 'Missing Contract!', @rcode = 1
  	goto vspexit
  	end

/* May or may not exclude change order values but regardless, will always exclude any
   contract items with a JCCI.RetainPCT set to 0.0%. */
select @maxretgamt = case when @inclchgordersinmax = 'Y' then (@maxretgpct * isnull(sum(ContractAmt), 0)) 
	else (@maxretgpct * isnull(sum(OrigContractAmt), 0)) end
from bJCCI with (nolock)
where JCCo = @jcco and Contract = @contract and RetainPCT <> 0

vspexit:

return @rcode



GO
GRANT EXECUTE ON  [dbo].[vspJCGetContractAmtForMaxRetg] TO [public]
GO
