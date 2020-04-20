SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspJBGetBillStatus]
/***********************************************************
 * CREATED BY:  	TJL  02/24/06 - Issue #28051.  6x Recode
 * MODIFIED By :
 *
 * USAGE:
 *
 * INPUT PARAMETERS
 *
 *
 * OUTPUT PARAMETERS
 *   @msg      error message 

 * RETURN VALUE
 *   0         success
 *   1         Failure
 *****************************************************/

(@jbco bCompany = 0, @billmth bMonth, @billnum int, @invstatus varchar output,
	@msg varchar(255) output)

as
set nocount on

declare @rcode int
select @rcode = 0

select @invstatus = InvStatus
from bJBIN with (nolock)
where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnum

if isnull(@invstatus, '') = ''
	begin
	select @msg = 'Error reading Invoice Status', @rcode = 1
	goto vspexit
	end

vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJBGetBillStatus] TO [public]
GO
