SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspJBGetJBITTotals]
/*********************************************************************************
*  Created by:	TJL  03/08/06:  Issue #28047, 6X rewrite
*  Modified by:	
*		
*  
* Called from JBMiscDist Tab/Form from JBProgBillHeader
* to compare the JBMiscDist Totals against the Bill amounts.  Its used to give
* a very simple warning to user when Distributions don't match Transaction Amounts.
*
* Inputs:
*	@jbco			-	JB Company
*	@billmth		-	BillMonth
*	@billnumber		-	BillNumber
*
* Outputs:
*	@msg			-	error message
*   @rcode	
*
*************************************************************************************/
(@jbco bCompany = null, @billmth bMonth, @billnumber int, @amount bDollar output, @errmsg varchar(255) output)
as
set nocount on

declare @rcode int
  
select @rcode = 0

/* Get Bill totals from JBIT for this Bill. */
select @amount = isnull(sum(AmtBilled), 0)
from bJBIT with (nolock)
where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnumber 

vspexit:
if @rcode <> 0 select @errmsg = @errmsg		--+ char(13) + char(10) + '  [vspJBGetJBITTotals]'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJBGetJBITTotals] TO [public]
GO
