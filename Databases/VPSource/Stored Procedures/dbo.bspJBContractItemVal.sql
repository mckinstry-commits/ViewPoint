SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspJBContractItemVal]
/*************************************
*
* Created:  bc 09/22/99
* Modified: kb 3/27/00 - added billtype restriction
*     	kb 8/9/00 - added source input to validate item by source
*     	kb 1/17/00 - issue #10987
*		TJL 03/28/03 - Issue #20039, If restricting on BillGroup, compare item Billgroup
*		TJL 02/16/06 - Issue #28051, 6x Rewrite.  Return JCCI.RetainPct
*
* validates Contract Item
*
* Pass:
*
*
* Success returns:
*	0
*
* Error returns:
*	1 and error message
**************************************/
(@jbco bCompany, @billmonth bMonth, @billnum int, @contract bContract,
	@contractitem bContractItem, @source char(1), @invdate bDate, @taxgroup bGroup output,
	@taxcode bTaxCode output, @taxrate bRate output, @retainpct bPct output, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @billtype char(1), @jcbillgroup bBillingGroup, 
	@jbbillgroup bBillingGroup, @restrictbillgroup bYN

select @rcode = 0

if @jbco is null
	begin
  	select @msg = 'Missing JB Company', @rcode = 1
  	goto bspexit
  	end
   
select @jbbillgroup = BillGroup, @restrictbillgroup = RestrictBillGroupYN
from bJBIN with (nolock)
where JBCo = @jbco and BillMonth = @billmonth and BillNumber = @billnum
if @@rowcount = 0
	begin
	select @msg = 'Not a valid JB Bill', @rcode = 1
	goto bspexit
	end
   
select @msg = Description, @billtype = BillType, @taxgroup = TaxGroup,
	@taxcode = TaxCode, @jcbillgroup = BillGroup, @retainpct = RetainPCT
from bJCCI with (nolock)
where JCCo = @jbco and Contract = @contract and Item = @contractitem
if @@rowcount = 0
	begin
	select @msg = 'Not a valid contract item', @rcode = 1
	goto bspexit
	end
   
if @jcbillgroup is not null and isnull(@jbbillgroup,'') <> @jcbillgroup
  	and @restrictbillgroup = 'Y'
  	begin
  	select @msg = 'Contract item ' + isnull(convert(varchar(16), @contractitem),'') + ' billing group does not match invoice', @rcode = 1
  	goto bspexit
  	end
   
if @source = 'P'
	begin
	if @billtype ='T' or @billtype ='N'
   	begin
       select @msg = 'Billtype ' + isnull(@billtype,'') + ' is invalid for a Progress contract item', @rcode = 1
       goto bspexit
       end
   end
   
if @source = 'T'
   begin
	if @billtype ='P' or @billtype ='N'
       begin
       select @msg = 'Billtype ' + isnull(@billtype,'') + ' is invalid for a T & M contract item', @rcode = 1
       goto bspexit
       end
   end
   
if @taxcode is not null
exec bspHQTaxRateGet @taxgroup, @taxcode, @invdate, @taxrate output, @msg = @msg output

bspexit:
if @rcode<>0 select @msg=@msg	--+ char(13) + char(10) + '[bspJBContractItemVal]'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBContractItemVal] TO [public]
GO
