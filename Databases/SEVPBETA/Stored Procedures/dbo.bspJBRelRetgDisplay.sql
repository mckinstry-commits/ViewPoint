SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspJBRelRetgDisplay]

/****************************************************************************
* CREATED BY:    bc 02/16/00
* MODIFIED By :  bc 03/13/01 - fixed @net_relretg calculation
*
*
* USAGE:  displays values that are to be displayed at the top of the Release Retainage form
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
(@jbco bCompany, @billmth bMonth, @billnum int,
/* outputs */
@prev_amtbilled bDollar output, @prev_retgbilled bDollar output, @prev_relpct bPct output, @prev_relretg bDollar output, @prev_netretg bDollar output,
@amtbilled bDollar output, @retgbilled bDollar output, @relretg bDollar output, @net_relretg bDollar output,
@total_amtbilled bDollar output, @total_retgbilled bDollar output, @total_relpct bPct output, @total_relretg bDollar output, @total_netretg bDollar output,
@errmsg varchar(255) output)
as
   
set nocount on

/*generic declares */
declare @rcode int, @contract bContract, @custgroup bGroup, @customer bCustomer

select @rcode=0

--CONTRACT

/* Get current contract amounts and necessary bill information.  NOT broken out by Customer! */
select @contract = Contract, @custgroup = CustGroup, @customer = Customer,
     @prev_amtbilled = isnull(PrevAmt,0),
     @prev_retgbilled = isnull(PrevRetg,0),
     @prev_relretg = isnull(PrevRRel,0),
     @amtbilled = isnull(InvTotal,0),
     @retgbilled = isnull(InvRetg,0),
     @relretg = isnull(RetgRel,0)
from bJBIN
where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnum
   
/* If Desired by Customer/Contract: Get total Previous values for this Customer/Contract */
/* select @prev_amtbilled = sum(t.AmtBilled),
	@prev_retgbilled = Sum(t.RetgBilled),
	@prev_relretg = Sum(t.RetgRel)
from bJBIT t with (nolock)
join bJBIN n with (nolock) on n.JBCo = t.JBCo and n.BillMonth = t.BillMonth and n.BillNumber = t.BillNumber
where t.JBCo = @jbco and n.InvStatus <> 'D'				
	and n.CustGroup = @custgroup and n.Customer = @customer and t.Contract = @contract
	and ((t.BillMonth < @billmth) or (t.BillMonth = @billmth and t.BillNumber < @billnum)) */
   
/* Calculations */
select @prev_relpct = case @prev_retgbilled when 0 then 0 else @prev_relretg / @prev_retgbilled end,
     @prev_netretg = @prev_retgbilled - @prev_relretg,
     @total_amtbilled = @prev_amtbilled + @amtbilled,
     @total_retgbilled = @prev_retgbilled + @retgbilled,
     @total_relretg = @prev_relretg + @relretg,
     @total_netretg = @total_retgbilled - @total_relretg,
     @net_relretg = @retgbilled - @relretg
   
/* Do this calculation after the @total_relretg and @total_retgbilled values are set */
select  @total_relpct = case @total_retgbilled when 0 then 0 else @total_relretg/@total_retgbilled end

bspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBRelRetgDisplay] TO [public]
GO
