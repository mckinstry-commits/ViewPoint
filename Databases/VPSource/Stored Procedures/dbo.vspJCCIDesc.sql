SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspJCCIDesc    Script Date: 05/20/2005 ******/
CREATE proc [dbo].[vspJCCIDesc]
/*************************************
 * Created By:	GF 05/20/2005
 * Modified By:
 *
 *
 * USAGE:
 * Called from JCCI and PMContractItem to get key description for contract item.
 *
 *
 * INPUT PARAMETERS
 * @jcco			JC Company
 * @contract		JC Contract
 * @contractitem	JC Contract Item
 *
 * Success returns:
 * @sicode			JC SI Code
 * 0 and Description from JCCI
 *
 * Error returns:
 * 1 and error message
 **************************************/
(@jcco bCompany, @contract bContract, @contractitem bContractItem,
 @sicode varchar(16) output, @bills_exist bYN output, @currunits bUnits output,
 @curramt bDollar output, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @siregion  varchar(6)

select @rcode = 0, @msg = '', @bills_exist = 'N'

if isnull(@contract,'') = ''
	begin
   	select @msg = 'Contract cannot be null.', @rcode = 1
   	goto bspexit
	end

if isnull(@contractitem,'') = ''
	begin
   	select @msg = 'Contract Item cannot be null.', @rcode = 1
   	goto bspexit
	end


-- -- -- get item info
select @msg=Description, @currunits=ContractUnits, @curramt=ContractAmt
from bJCCI with (nolock) where JCCo=@jcco and Contract=@contract and Item=@contractitem
if @@rowcount <> 0
	begin
	if exists (select top 1 1 from JBIT with (nolock) where JBCo=@jcco and Contract=@contract and Item=@contractitem)
		begin
		select @bills_exist = 'Y'
-- -- -- @errmsg =  'This item has been previously billed. A change to the type may result in differences on the Previous Billed amounts in JB.'
		end
	end


select @siregion = SIRegion
from bJCCM with (nolock)
where JCCo=@jcco and Contract=@contract

-- default sicode to contract item
if isnull(@siregion,'')<>'' and exists (select 1 from JCSI where SIRegion= isnull(@siregion,'') and SICode = ltrim(@contractitem))
 select @sicode = ltrim(@contractitem)




bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCCIDesc] TO [public]
GO
