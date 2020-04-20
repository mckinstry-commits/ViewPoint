SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspJBCompletedBillGridFill    Script Date:  ******/
CREATE proc [dbo].[vspJBCompletedBillGridFill]
/****************************************************************
* CREATED BY	: TJL 01/04/06 - Issue #28184, 6x recode
* 
*
* USAGE:
* 	Provide user a list of Contracts that can be automatically Billed (via JBCompleteBill form),
*	for the full amount, simply by selecting the Contract in the list and Updating.
*
* INPUT PARAMETERS
*	@jcco		-	JC Company
*
*
* OUTPUT PARAMETERS
*   @errmsg
*
*****************************************************************/
(@jbco bCompany = null)
  
as
set nocount on
  
/* Declare Working variables */
declare @rcode int, @errmsg varchar(255)

select @rcode=0
  
if @jbco is null
	begin
  	select @errmsg = 'JB Company is missing.', @rcode = 1
  	goto vspexit
  	end
  
/* Get record set based on: */
select bJCCM.Contract, bJCCM.Description, bJCCM.CompleteYN
from bJCCM with (nolock)
where JCCo = @jbco and bJCCM.BillOnCompletionYN = 'Y' and bJCCM.ContractStatus = 1
    and (bJCCM.DefaultBillType = 'P' or bJCCM.DefaultBillType = 'B')
    and not exists(select 1 from bJBIN with (nolock) where bJBIN.JBCo = @jbco and bJBIN.Contract = bJCCM.Contract and bJBIN.BillOnCompleteYN = 'Y')
  
if @@rowcount = 0
  	begin
  	select @errmsg = 'There are no contracts configured for Billing in this manner.', @rcode = 7
  	goto vspexit
  	end
  
vspexit:
if @rcode <> 0 select @errmsg = @errmsg		--+ char(13) + char(10) + char(13) + char(10) + '[vspJBCompletedBillGridFill]'
  
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJBCompletedBillGridFill] TO [public]
GO
