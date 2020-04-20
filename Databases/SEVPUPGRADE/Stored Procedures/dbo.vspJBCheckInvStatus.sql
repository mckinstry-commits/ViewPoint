SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspJBCheckInvStatus]
/**************************************************************************************
* CREATED BY:     TJL 09/11/06 - Issue #28642
* MODIFIED By :	  
*
* USAGE:  Checks to see if the InvStatus on the JB Bill has been changed by another user
*	just before attempting to Delete the JB Bill using form Delete button.
*	(Called from JBProgressBillHeader and JBTMBills form and if TRUE,  
*	user is not allowed to delete the Bill.
*
* INPUT PARAMETERS
*   JBCo		JB Co to validate against
*   BillMonth	JB BillMonth
*	BillNumber	JB BillNumber
*
* OUTPUT PARAMETERS
*   @msg	error message if error occurs
* RETURN VALUE
*   0		Success - InvStatus is 'A' or 'N' at the moment of Delete
*   1		Failure - Could not determine InvStatus is now 'C', 'D', 'I'
*	7		Success Conditional - InvStatus is now 'C', 'D', 'I'
*		
**************************************************************************************/
   
(@jbco bCompany = 0, @billmth bMonth,  @billnum int, @msg varchar(255) output)

as
set nocount on
   
declare @rcode int, @invstatus char(1)
select @rcode = 0
   
if @jbco is null
   	begin
	select @msg = 'Missing JB Company.', @rcode = 1
	goto vspexit
	end
if @billmth is null
   	begin
	select @msg = 'Missing JB BillMonth.', @rcode = 1
	goto vspexit
	end
if @billnum is null
   	begin
	select @msg = 'Missing JB BillNumber.', @rcode = 1
	goto vspexit
	end

/* Begin JB Bill InvStatus check */
select @invstatus = n.InvStatus
from bJBIN n with (nolock)
where n.JBCo = @jbco and n.BillMonth = @billmth and n.BillNumber = @billnum
if @invstatus not in ('A', 'N')
	begin
	/* JB Bill Status has been changed and Bill may not be deleted. */
	select @rcode = 7
	goto vspexit
	end
   
vspexit:

return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJBCheckInvStatus] TO [public]
GO
