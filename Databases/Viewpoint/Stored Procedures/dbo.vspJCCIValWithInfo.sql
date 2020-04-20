SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspJCCIValWithInfo   Script Date: 05/20/2005 ******/
CREATE proc [dbo].[vspJCCIValWithInfo]
/*************************************
 * Created By:	GF 12/28/2008
 * Modified By:
 *
 *
 * USAGE:
 * Called from PMProjectPhases to return contract item information to display
 * when on the cost type tab.
 *
 *
 * INPUT PARAMETERS
 * @jcco			JC Company
 * @contract		JC Contract
 * @contractitem	JC Contract Item
 *
 * Success returns:
 * @itemdesc		JC Contract Item Description
 * @um				JC Contract Item UM
 * @units			JC Contract Item Original Units
 * @unitcost		JC Contract Item Unit Price
 * @amount			JC Contract Item Original Amount
 *
 * Error returns:
 * 1 and error message
 **************************************/
(@jcco bCompany, @contract bContract, @contractitem bContractItem,
 @itemdesc bItemDesc = null output, @um bUM = null output, @units bUnits = 0 output,
 @unitcost bUnitCost = 0 output, @amount bDollar = 0 output)
as
set nocount on

declare @rcode int

select @rcode = 0

if isnull(@jcco,'') = '' or isnull(@contract,'') = '' or isnull(@contractitem,'') = ''
	begin
	select @rcode = 1
	goto bspexit
	end

---- get item info
select @itemdesc=Description, @um=UM, @units=OrigContractUnits,
		@unitcost=OrigUnitPrice, @amount=OrigContractAmt
from bJCCI with (nolock) where JCCo=@jcco and Contract=@contract and Item=@contractitem
if @@rowcount = 0
	begin
	select @rcode = 1
	end

bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCCIValWithInfo] TO [public]
GO
