SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspJBGetJBINAmounts]
/*********************************************************************************
*  Created by:	TJL  03/13/06:  Issue #28050, 6X rewrite
*  Modified by: TJL 07/24/08 - Issue #128287, JB International Sales Tax
*		TJL 12/28/09 - Issue #137089, JB Maximum Retainage
*		
*  
* Called from JBProgressBillRetgTot form to populate Bill Amount Labels on form.
*
* Inputs:
*	@jbco			-	JB Company
*	@billmth		-	BillMonth
*	@billnumber		-	BillNumber
*
* Outputs:
*	@msg			-	error message
*   @rcode	
*
*************************************************************************************/
(@jbco bCompany = null, @billmth bMonth, @billnumber int, @currcontract bDollar output, @prevwc bDollar output, 
	@wc bDollar output, @prevwcretg bDollar output, @wcretg bDollar output, @prevsm bDollar output, @sm bDollar output,
	@prevsmretg bDollar output, @smretg bDollar output, @prevrrel bDollar output, @retgrel bDollar output,
	@wcforretgcalc bDollar output, @smforretgcalc bDollar output, @errmsg varchar(255) output)
	 
as
set nocount on

declare @rcode int
  
select @rcode = 0

If @billmth is null
	begin
	select @errmsg = 'Missing BillMonth.', @rcode = 1
	goto vspexit
	end
If @billnumber is null
	begin
	select @errmsg = 'Missing BillNumber.', @rcode = 1
	goto vspexit
	end

/* Get Bill totals from JBIN for this Bill. */
--select @currcontract = isnull(n.CurrContract, 0), @prevwc = isnull(n.PrevWC, 0), @wc = isnull(n.WC, 0), @prevwcretg = isnull(n.PrevWCRetg, 0),
--	@wcretg = isnull(n.WCRetg, 0), @prevsm = isnull(n.PrevSM, 0), @sm = isnull(n.SM, 0), @prevsmretg = isnull(n.PrevSMRetg, 0),
--	@smretg = isnull(n.SMRetg, 0), @prevrrel = isnull(n.PrevRRel, 0) - isnull(n.PrevRetgTaxRel,0), 
--	@retgrel = isnull(n.RetgRel, 0) - isnull(n.RetgTaxRel,0)
--from bJBIN n with (nolock)
--where n.JBCo = @jbco and n.BillMonth = @billmth and n.BillNumber = @billnumber 

	
/* Get Bill totals */
select @currcontract = isnull(n.CurrContract, 0), @prevwc = isnull(n.PrevWC, 0), @wc = isnull(n.WC, 0), @prevwcretg = isnull(n.PrevWCRetg, 0),
	@wcretg = isnull(n.WCRetg, 0), @prevsm = isnull(n.PrevSM, 0), @sm = isnull(n.SM, 0), @prevsmretg = isnull(n.PrevSMRetg, 0),
	@smretg = isnull(n.SMRetg, 0), @prevrrel = isnull(n.PrevRRel, 0) - isnull(n.PrevRetgTaxRel,0), 
	@retgrel = isnull(n.RetgRel, 0) - isnull(n.RetgTaxRel,0), @wcforretgcalc = sum(t.WC)
from bJBIN n with (nolock)
left join bJBIT t with (nolock) on t.JBCo = n.JBCo and t.BillMonth = n.BillMonth and t.BillNumber = n.BillNumber and t.WCRetPct <> 0	
where n.JBCo = @jbco and n.BillMonth = @billmth and n.BillNumber = @billnumber 
group by n.CurrContract, n.PrevWC, n.WC, n.PrevWCRetg, n.WCRetg, n.PrevSM, n.SM, n.PrevSMRetg,
	n.SMRetg, n.PrevRRel, n.RetgRel, n.RetgTaxRel, n.PrevRetgTaxRel
If @@rowcount = 0
	begin
	select @errmsg = 'Not a valid JB Bill.', @rcode = 1
	goto vspexit
	end
	
select @smforretgcalc = sum(t.SM)
from bJBIT t with (nolock)
join JBITProgGrid tg on tg.JBCo = t.JBCo and tg.BillMonth = t.BillMonth and tg.BillNumber = t.BillNumber and tg.Item = t.Item
where t.JBCo = @jbco and t.BillMonth = @billmth and t.BillNumber = @billnumber and tg.SMRetgPct <> 0

vspexit:
if @rcode <> 0 select @errmsg = @errmsg		--+ char(13) + char(10) + '  [vspJBGetJBINAmounts]'
return @rcode



GO
GRANT EXECUTE ON  [dbo].[vspJBGetJBINAmounts] TO [public]
GO
