SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspJCCIValWithUP    Script Date: 8/28/99 9:35:00 AM ******/
CREATE  proc [dbo].[vspJCCIValForRevAdj]
/***********************************************************
* CREATED BY:	02/25/2009 CHS - Copied from vspJCCIValWithUP and modified
* MODIFIED By:
*	
*
* USAGE:
* validates JC contract item, used in JC Change Orders,
* an error is returned if any of the following occurs
* no contract passed, no item passed, no item found in JCCI.
*
* INPUT PARAMETERS
*   JCCo   JC Co to validate against
*   Contract  Contract to validate against
*   Item      Contract item to validate
*
* OUTPUT PARAMETERS
*   @um       			unit of measure for contract item
*   @unitprice 			unit price for contract item
*   @contractitemexists 	default GLAcct
*   @msg      			error message if error occurs otherwise Description of Contract Item
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
(@jcco bCompany = 0, @contract bContract = null, @item bContractItem = null,
 @contractitemexists bYN output, @um bUM output, @unitcost bUnitCost output,
 @sicode varchar(16) output, @defglacct bGLAcct output, @msg varchar(255) output)

as
set nocount on

declare @rcode int

select @rcode = 0, @contractitemexists = 'Y'


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

if @item is null
	begin
	select @msg = 'Missing Contract item!', @rcode = 1
	goto bspexit
	end


---- validate contract item and get information
select @defglacct = case c.ContractStatus when 3 then d.ClosedRevAcct else d.OpenRevAcct end,
	@um = UM, @unitcost = UnitPrice, @msg = i.Description, @sicode=i.SICode
from bJCCI i with (nolock)
left join bJCDM d with (nolock) on d.JCCo = i.JCCo and d.Department = i.Department
join bJCCM c with (nolock) on c.JCCo = i.JCCo and c.Contract = i.Contract
where i.JCCo = @jcco and i.Contract = @contract and i.Item = @item
if @@rowcount = 0
	begin
	select @msg = 'Contract Item not on file!', @contractitemexists = 'N', @rcode = 1
	goto bspexit
	end

----  select @defglacct = case c.ContractStatus when 3 then d.ClosedRevAcct else d.OpenRevAcct end,
----  	   @um = UM, @msg = i.Description
----  from bJCCI i with (nolock)
----  join bJCCM c with (nolock) on c.JCCo = i.JCCo and c.Contract = i.Contract
----  left join bJCDM d with (nolock) on d.JCCo = i.JCCo and d.Department = i.Department
----  where i.JCCo = @jcco and i.Contract = @contract and i.Item = @item


bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCCIValForRevAdj] TO [public]
GO
