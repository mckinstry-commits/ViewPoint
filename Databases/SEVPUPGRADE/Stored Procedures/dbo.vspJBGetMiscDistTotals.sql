SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspJBGetMiscDistTotals]
/*********************************************************************************
*  Created by:	TJL  03/08/06:  Issue #28047, 6X rewrite
*  Modified by:	
*		
*  
* Called from JBMiscDist Tab/Form from JBProgBillHeader and JBTMBills
* to compare the JBMiscDist Totals against the Bill amounts.  Its used to give
* a very simple warning to user when Distributions don't match Transaction Amounts.
*
* Inputs:
*	@jbco			-	JB Company
*	@billmth		-	BillMonth
*	@billnumber		-	BillNumber
*	@custgroup		-	CustGroup
*
* Outputs:
*	@msg			-	error message
*   @rcode	
*
*************************************************************************************/
(@jbco bCompany = null, @billmth bMonth, @billnumber int, @custgroup bGroup, @amount bDollar output, @errmsg varchar(255) output)
as
set nocount on

declare @rcode int
  
select @rcode = 0

/* Get MiscDistCode totals from JBMD for this Bill */
select @amount = isnull(sum(Amt), 0)
from bJBMD with (nolock)
where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnumber and CustGroup = @custgroup 

vspexit:
if @rcode <> 0 select @errmsg = @errmsg		--+ char(13) + char(10) + '  [vspJBGetMiscDistTotals]'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJBGetMiscDistTotals] TO [public]
GO
