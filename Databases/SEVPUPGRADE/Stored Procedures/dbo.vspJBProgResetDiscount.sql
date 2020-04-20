SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspJBProgResetDiscount Script Date:  ******/
CREATE proc [dbo].[vspJBProgResetDiscount]
/***********************************************************
* CREATED BY  : TJL 07/01/09 - Issue #119759, Update JBIT Discount when user manually changes item values
* MODIFIED BY :	
*
*
* USED IN:  JB Progress Bill Header when PayTerms changes
*
* USAGE:  On existing JB Progress bills, when a user makes a change to the PayTerms value, this 
*	may get called to update the Discount value on each Item of the Billing.
*
* INPUT PARAMETERS
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
   
(@jbco bCompany = null, @billmth bMonth = null, @billnum int = null, @discrate bPct, @msg varchar(255) output)
as

set nocount on

declare @rcode int, @numrows int

select @rcode = 0, @numrows = 0

if @jbco is null
	begin
	select @msg = 'Missing JB Company.', @rcode = 1
	goto vspexit
	end
if @billmth is null
	begin
	select @msg = 'Missing Bill Month.', @rcode = 1
	goto vspexit
	end
if @billnum is null
	begin
	select @msg = 'Missing Bill Number.', @rcode = 1
	goto vspexit
	end	
	  
/* Set Discount value for all Items on this Bill. */
select @numrows = count(1)
from bJBIT
where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnum

if isnull(@numrows,0) > 0
	begin
	update bJBIT
	set Discount = (isnull(WC,0) + isnull(SM,0)) * isnull(@discrate,0)
	where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnum
	
	if @@rowcount <> @numrows
		begin
		select @msg = 'The recalculation of Discount on some bill items has failed.', @rcode = 1
		goto vspexit
		end	
	end
	
vspexit:
return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspJBProgResetDiscount] TO [public]
GO
