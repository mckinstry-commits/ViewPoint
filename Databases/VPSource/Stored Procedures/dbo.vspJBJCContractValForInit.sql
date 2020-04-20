SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspJBJCContractValForInit    Script Date:  ******/
CREATE proc [dbo].[vspJBJCContractValForInit]
   
/********************************************************************************************************
* CREATED BY:  TJL  09/11/06 - Issue #120713, Add Init Warnings when Contract is not Billable for some reason
* MODIFIED By:	GF 12/17/2007 - issue #25569 separate post closed job flags in JCCO enhancement
*
*
*
* USAGE:
*	Validates JC contract
*	Error returned when contract is not found, is pending, or is closed and billing not allowed
*
*
* INPUT PARAMETERS
*   JCCo		JC Co to validate against
*   Contract	Contract to validate
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs otherwise Description of Contract
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
(@jcco bCompany = 0, @contract bContract = null, @msg varchar(60) output)
   
as
set nocount on  

declare @rcode int, @postclosedjobs varchar(1), @postsoftclosedjobs varchar(1), @contractstatus tinyint

select @rcode = 0, @contractstatus = 1
   
if @jcco is null
	begin
	select @msg = 'Missing JC Company.', @rcode = 1
	goto vspexit
	end
if @contract is null
	begin
	select @msg = 'Missing Contract.', @rcode = 1
	goto vspexit
	end

/* Get JCCO information */
select @postclosedjobs = j.PostClosedJobs, @postsoftclosedjobs = j.PostSoftClosedJobs
from JCCO j with (nolock)
where j.JCCo = @jcco
   
select @msg = Description, @contractstatus=ContractStatus
from JCCM with (nolock)
where JCCo = @jcco and Contract = @contract

/* Validation failures that will prevent user from initializing bills. */ 

/************************* SEE NOTE BELOW: ****************************/
/* If you change error Text below, you must also change in both Forms JBProgressBillInit
   and JBTandMBillInit under events SyncContract1DescLabelColor and SyncContract2DescLabelColor.
   Its minor but it controls the Text color on the Contract Description label on validation error.

   I started to use a 99 - hidden field, on each form, to keep track of this but because of the 
   BeginContract and EndContract inputs, it quickly became more coding then it was worth.
*/
if @@rowcount = 0
	begin
	select @msg = 'Contract not on file.', @rcode = 1
	goto vspexit
	end

if @contractstatus = 0
	begin
	select @msg = 'Cannot bill pending contracts.', @rcode = 1
	goto vspexit
	end
---- check soft closed contracts
if @postsoftclosedjobs = 'N' and @contractstatus = 2
	begin
	select @msg = 'Contract is soft-closed.  Billing not allowed.', @rcode = 1
	goto vspexit
	end
---- check hard closed contracts
if @postclosedjobs = 'N' and @contractstatus = 3
	begin
	select @msg = 'Contract is hard-closed.  Billing not allowed.', @rcode = 1
	goto vspexit
	end

vspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJBJCContractValForInit] TO [public]
GO
