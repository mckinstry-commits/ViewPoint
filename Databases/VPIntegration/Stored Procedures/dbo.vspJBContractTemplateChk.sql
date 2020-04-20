SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspJBContractTemplateChk]
/**************************************************************************************
* CREATED BY:     TJL 09/11/06 - Issue #121618
* MODIFIED By :	  
*
* USAGE:  Checks to see if the Template being deleted is currently in JCCM.JBTemplate
*		  on any Open or Soft Closed Contracts.  (Called from JBTemplate form and btJBTMd trigger
*		  and if TRUE, user is not allowed to delete the Template
*
* INPUT PARAMETERS
*   JBCo		JB Co to validate against
*   Template	JB Template being deleted
*
* OUTPUT PARAMETERS
*   @msg	error message if error occurs
* RETURN VALUE
*   0		Success - No Open or SoftClosed Contracts using this Template
*   1		Failure - Could not determine
*	7		Success Conditional - Contracts are using this Template
*		
**************************************************************************************/
   
(@jbco bCompany = 0, @template varchar(10), @msg varchar(255) output)

as
set nocount on
   
declare @rcode int
select @rcode = 0
   
if @jbco is null
   	begin
	select @msg = 'Missing JB Company.', @rcode = 1
	goto vspexit
	end
if @template is null
   	begin
	select @msg = 'Missing JB Template.', @rcode = 1
	goto vspexit
	end
   
/* Begin Contract check */
select 1
from bJCCM m with (nolock)
where m.JCCo = @jbco and m.ContractStatus in (1, 2) and m.JBTemplate = @template
if @@rowcount <> 0
	begin
	/* Contract exists that are using this Template. */
	select @rcode = 7
	goto vspexit
	end
   
vspexit:

return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJBContractTemplateChk] TO [public]
GO
