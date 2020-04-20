SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspARJCCIValWithInfo    Script Date: 8/28/99 9:35:00 AM ******/
CREATE proc [dbo].[vspARJCCIValWithInfo]
  
(@jcco bCompany = 0, @contract bContract = null, @item bContractItem = null,
	@taxcode bTaxCode output, @retainPct bPct output, @defaultglaccount bGLAcct output, @glco bCompany output,
	@UM bUM output,	@unitcost bUnitCost output, @origcontractunits bUnits output, @origcontractamt bDollar output,
	@currcontractunits bUnits output, @currcontractamt bDollar output, @billedunits bUnits output,
	@billedamt bDollar output, @msg varchar(60) output)
as
set nocount on
/***********************************************************
* CREATED BY:  TJL 07/25/05:  Issue #26556, 6x Rewrite
* MODIFIED By : 
*				
* USAGE:
* validates JC contract item and returns item values
* an error is returned if any of the following occurs
* no contract passed, no item passed, no item found in JCCI.
*
* INPUT PARAMETERS
*   JCCo   JC Co to validate against
*   Contract  Contract to validate against
*   Item      Contract item to validate
*
* OUTPUT PARAMETERS
*
*	
*   @msg      error message if error occurs otherwise Description of Contract Item
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
 
declare @rcode int
select @rcode = 0
  
if @jcco is null
	begin
	select @msg = 'Missing JC Company!', @rcode = 1
	goto vspexit
	end

if @contract is null
	begin
	select @msg = 'Missing Contract!', @rcode = 1
	goto vspexit
	end

if @item is null
	begin
	select @msg = 'Missing Contract item!', @rcode = 1
	goto vspexit
	end
  
select @taxcode = isnull(i.TaxCode,''), @retainPct = i.RetainPCT,
	@defaultglaccount = case c.ContractStatus when 3 then d.ClosedRevAcct else d.OpenRevAcct end,
	@glco = d.GLCo, @UM = i.UM, @msg = i.Description, @unitcost = i.UnitPrice, @origcontractunits = i.OrigContractUnits, 
	@origcontractamt = i.OrigContractAmt, @currcontractunits = i.ContractUnits, 
	@currcontractamt = i.ContractAmt, @billedunits = i.BilledUnits,	@billedamt = i.BilledAmt
from bJCCI i with (nolock)
left join bJCDM d with (nolock) on d.JCCo = i.JCCo and d.Department = i.Department
join bJCCM c with (nolock) on c.JCCo = i.JCCo and c.Contract = i.Contract
where i.JCCo = @jcco and i.Contract = @contract and i.Item = @item

if @@rowcount = 0
	begin
	select @msg = 'Contract Item not on file!', @rcode = 1
	goto vspexit
	end
  
vspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspARJCCIValWithInfo] TO [public]
GO
