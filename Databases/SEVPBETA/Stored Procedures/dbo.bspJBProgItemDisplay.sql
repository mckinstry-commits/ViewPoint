SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspJBProgItemDisplay]
   
/****************************************************************************
* CREATED BY: bc 12/08/99
* MODIFIED By : bc 01/20/00
*		kb 3/4/2 - issue #16386
*		TJL 03/27/09 - Issue #125679, All Progress Billing form to display excessive Contract Pct Complete
*
* USAGE:  calculates the values that are to be displayed at the top of the Progress Items Edit form
*
*
* INPUT PARAMETERS
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs
* RETURN VALUE
*   0         success
*   1         Failure
****************************************************************************/
(@jbco bCompany, @billmth bMonth, @billnum int, @contract bContract, @contractitem bContractItem, @invdate bDate,
/* outputs */
@contract_total bDollar output, @contract_prev_billed bDollar output, @contract_prevsm bDollar output, @contract_prev_total bDollar output,
@contract_inv_billed bDollar output, @contract_inv_sm bDollar output, @contract_inv_total bDollar output,
@item_total bDollar output, @item_prev_billed bDollar output, @item_prevsm bDollar output, @item_prev_total bDollar output,
@item_inv_billed bDollar output, @item_inv_sm bDollar output, @item_inv_total bDollar output,
@contract_pct_complete bPct output,  @msg varchar(255) output)
as
   
     set nocount on
   
/*generic declares */
declare @rcode int, @errmsg varchar(255)

select @rcode=0

--CONTRACT
/* total contract amount */
select @contract_total = isnull(sum(CurrContract),0) + isnull(sum(ChgOrderAmt),0)
from JBIN
where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnum and Contract = @contract

/* previous and current contract amounts */
select @contract_prev_billed = isnull(PrevWC,0),
    @contract_prevsm = isnull(PrevSM,0),
    @contract_prev_total = isnull(PrevWC,0) + isnull(PrevSM,0),
    @contract_inv_billed = isnull(WC,0),
    @contract_inv_sm = isnull(SM,0),
    @contract_inv_total = isnull(InvTotal,0),
    @contract_pct_complete = case @contract_total when 0 then 0 else
		case when (isnull(PrevWC,0) + isnull(PrevSM,0) + isnull(WC,0) + isnull(SM,0))/@contract_total >= 99.9999 then 99.9999
			when (isnull(PrevWC,0) + isnull(PrevSM,0) + isnull(WC,0) + isnull(SM,0))/@contract_total <= -99.9999 then -99.9999
		else (isnull(PrevWC,0) + isnull(PrevSM,0) + isnull(WC,0) + isnull(SM,0))/@contract_total end
		end
from JBIN
where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnum
   
--ITEM
/* total contract item amount */
select @item_total = isnull(min(t.CurrContract),0) + isnull(sum(x.ChgOrderAmt),0)
from JBIN n
join JBIT t on t.JBCo = n.JBCo and t.BillMonth = n.BillMonth
and t.BillNumber = n.BillNumber and t.Item = @contractitem
left join JBCC c on c.JBCo = n.JBCo and c.BillMonth = n.BillMonth
and c.BillNumber = n.BillNumber
left join JCOI i on i.JCCo = n.JBCo and i.Contract = n.Contract
and i.Job = c.Job and i.ACO = c.ACO and i.Item = t.Item
left join JBCX x on x.JBCo = n.JBCo and x.BillMonth = n.BillMonth
and x.BillNumber = n.BillNumber and x.Job = i.Job and x.ACO = i.ACO and x.ACOItem = i.ACOItem
where n.JBCo = @jbco and n.BillMonth = @billmth
and n.BillNumber = @billnum and n.Contract = @contract

/* previous & current contract item amounts */
select @item_prev_billed = isnull(PrevWC,0),
    @item_prevsm = isnull(PrevSM,0),
    @item_prev_total = isnull(PrevWC,0) + isnull(PrevSM,0),
    @item_inv_billed = isnull(WC,0),
    @item_inv_sm = isnull(SM,0),
    @item_inv_total = isnull(AmtBilled,0)
from JBIT
where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnum
and Item = @contractitem
   
 /*select @contract_pct_complete = case when sum(CurrContract) = 0 then 0
   else (sum(AmtBilled)+sum(PrevWC) + sum(PrevSM))/sum(CurrContract) end from JBIT t
   left join JCCI i on i.JCCo = t.JBCo and i.Contract = t.Contract and i.Item = t.Item
   where t.JBCo = @jbco
   and t.BillMonth = @billmth and t.BillNumber = @billnum and i.BillType = 'P'*/

bspexit:
 	return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspJBProgItemDisplay] TO [public]
GO
