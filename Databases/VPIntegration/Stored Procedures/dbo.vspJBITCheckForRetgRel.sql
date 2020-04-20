SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspJBITCheckForRetgRel]
/***********************************************************
* CREATED BY: TJL 03/23/09 - Issue #128250, Allow Deleting Bills In Closed Mth
* MODIFIED By :  
*
* USAGE:
*   Called from JBProgressBillHeader and JBTMBillEdit forms.  If Retainage has been
*   released using the Bill, then the bill will NOT be allowed to be deleted in a
*   closed month.
*
* INPUT PARAMETERS
*   Co				JB Co to validate against
*   BillMonth		
*	BillNumber
*
* OUTPUT PARAMETERS
*   @msg      error message 
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
   
(@jbco bCompany, @billmonth bMonth, @billnumber int, @errmsg varchar(255) output)
   
as
set nocount on

declare @rcode int

select @rcode = 0
   
if @jbco is null
	begin
	select @errmsg = 'Missing JB Company.', @rcode = 1
	goto vspexit
	end
if @billmonth is null
	begin
	select @errmsg = 'Missing Bill Month.', @rcode = 1
	goto vspexit
	end
if @billnumber is null
	begin
	select @errmsg = 'Missing Bill Number.', @rcode = 1
	goto vspexit
	end

if exists(select top 1 1
from bJBIT with (nolock)
where JBCo = @jbco and BillMonth = @billmonth and BillNumber = @billnumber
	and RetgRel <> 0)
	begin
	select @errmsg = 'this Bill is being used to Release Retainage.', @rcode = 7
	goto vspexit
	end

vspexit:
return @rcode



GO
GRANT EXECUTE ON  [dbo].[vspJBITCheckForRetgRel] TO [public]
GO
