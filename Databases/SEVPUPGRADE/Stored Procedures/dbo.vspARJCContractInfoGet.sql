SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQGroupVal    Script Date: 8/28/99 9:34:50 AM ******/
CREATE proc [dbo].[vspARJCContractInfoGet]
/*************************************
*  Created:		TJL  08/25/05 - Issue #27720
*  Modified:	
*
*  Retrieve commonly used JCCM Information and return to AR Forms.
*
*  Inputs:
*	 JCCo:		JC Company
*	 Contract:	Contract
*
*  Outputs:
*
*
* Error returns:
*	0 and Group Description from bHQGP
*	1 and error message
**************************************/
(@jcco bCompany, @contract bContract, @description bDesc output, @dept bDept output, @contractstatus tinyint output,
	@custgroup bGroup output, @customer bCustomer output, @payterms bPayTerms output, @taxgroup bGroup output, 
	@taxcode bTaxCode output, @retgpct bPct output, @rectype tinyint output, @errmsg varchar(255) output)
as 
set nocount on
declare @rcode int
select @rcode = 0
  	
if @jcco is null
	begin
	select @errmsg = 'Missing JC Company.', @rcode = 1
	goto vspexit
	end
if @contract is null
	begin
	select @errmsg = 'Missing Contract.', @rcode = 1
	goto vspexit
	end

select @description = Description, @dept = Department, @contractstatus = ContractStatus,
	@custgroup = CustGroup, @customer = Customer, @payterms = PayTerms, @taxgroup = TaxGroup, 
	@taxcode = TaxCode, @retgpct = RetainagePCT, @rectype = RecType
from bJCCM with (nolock)
where JCCo = @jcco and Contract = @contract
if @@rowcount = 0
	begin
	select @errmsg = 'Error getting JC Contract information.', @rcode = 1
	end
  
vspexit:
if @rcode <> 0 select @errmsg = @errmsg		--+ char(10) + char(13) + char(10) + char(13) + '[vspARJCContractInfoGet]'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspARJCContractInfoGet] TO [public]
GO
