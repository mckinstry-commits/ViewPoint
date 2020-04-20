SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspJBContractInfoContractVal]
/***********************************************************
* CREATED BY:	CHS		08/04/2008 - Issue #128061
* MODIFIED By:	
*
* USAGE:
*	Returns JC Job Status
*
* INPUT PARAMETERS
*
* OUTPUT PARAMETERS
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
(@jcco bCompany = null, @contract bContract = null, @contractstatus bStatus = null output, @msg varchar(255) = '' output)

as
set nocount on


declare @rcode int

select @rcode = 0

/* Validate Job */   
select @contractstatus = ContractStatus
from JCCM c with (nolock)
where c.JCCo = @jcco and c.Contract = @contract


vspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJBContractInfoContractVal] TO [public]
GO
