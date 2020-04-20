SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMContractVal    Script Date: 05/16/2006 ******/
CREATE proc [dbo].[vspPMContractVal]
/***********************************************************
 * CREATED BY:	GF 05/16/2006 - for project copy 6.x
 * MODIFIED By:
 *
 *
 *
 *
 * USAGE:
 * validates JC contract
 * an error is returned if any of the following occurs
 * no contract passed, no contract found in JCCM.
 *
 * INPUT PARAMETERS
 *   JCCo   JC Co to validate against
 *   Contract  Contract to validate
 *
 * OUTPUT PARAMETERS
 *   @status      Status of the contract
 *   @department  Department of the contract
 *   @customer    Customer of the contract
 *	 @retg		  Retainage percentage
 *   @startmonth  StartMonth of the contract
 *   @msg      error message if error occurs otherwise Description of Contract
 *
 * RETURN VALUE
 *   0         success
 *   1         Failure
 *****************************************************/
(@jcco bCompany = 0, @contract bContract = null, @status tinyint output,
 @department bDept=null output, @customer bCustomer=null output, @retg bPct=0 output,
 @startmonth bMonth=null output, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @status=1, @retg = 0

if @jcco is null
	begin
   	select @msg = 'Missing JC Company!', @rcode = 1
   	goto bspexit
   	end

if @contract is null
   	begin
   	select @msg = 'Missing Contract!', @rcode = 1
   	goto bspexit
   	end

------ validate contract in JCCM
select @msg = Description, @status=ContractStatus, @department=Department,
	   @startmonth=StartMonth, @customer=Customer, @retg=isnull(RetainagePCT,0)
from JCCM with (nolock)
where JCCo = @jcco and Contract = @contract
if @@rowcount = 0
   	begin
	select @msg = 'New Contract', @retg = 0
   	goto bspexit
   	end





bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMContractVal] TO [public]
GO
