SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE function [dbo].[vfJBItemOverLimitYN]
(@jbco bCompany = null, @billmonth bMonth = null, @billnumber Int = null,
	@contract bContract = null, @contractitem bContractItem = null)
returns bYN
/***********************************************************
* CREATED BY	: TJL 05/26/06
* MODIFIED BY	
*
* USAGE:
* 	Evaluated and returns Y/N if Item being bill has already
*	been bill beyond the specified Contract Item amount
*
* INPUT PARAMETERS:
*	JBCo
*	BillMonth
*	BillNumber  
*	Contract on Bill
*	Item on Bill Line
*
* OUTPUT PARAMETERS:
*	OverLimitYN
*	
*
*****************************************************/
as
begin

declare @overlimityn bYN, @limitopt char(1), @taxinterface bYN, @jbitbilledamt bDollar,
	@billtype char(1), @contractamt bDollar

select @overlimityn = 'N'

/* Begin OverLimit Checks - Because this is used by TMBillLines, which are Item oriented,
   we only need to perform the check if OverLimitOpt = 'I'.  This will cause a warning to
   display on the TMBillLines form for any Item which is currently over limit.  This 
   warning is determined, on the fly, and is NOT saved in a Table.  (In this way, it differs
   from how JBTMBillEdit Form works which saves this error to bJBBE).  In addition, 
   OverLimit by Contract will display only on the Header form JBTMBillEdit. */
   
select @limitopt = JBLimitOpt, @taxinterface = TaxInterface
from dbo.bJCCM with (nolock)
where JCCo = @jbco and Contract = @contract
   
if @limitopt <> 'I'		
goto exitfunction
   
/* As user selects a JBTMBill Line, if Item changes, we need to get up to the moment 
   Item values for all Current Bills to be compared with the current ContractAmt 
   (including ChangeOrders) for this Item.  To keep it simple, we only need to look
   in bJBIT for the sum(AmtBilled) for this Contract/Item (Current Billed amounts) and
   compare it to bJCCI.ContractAmt (Current Contract amount, including Change Orders 
   for this Item). */
   
/* Get Total Billed Amount for this Item */
select @jbitbilledamt = sum(t.AmtBilled) + 
	case @taxinterface when 'Y' then sum(t.TaxAmount) else 0 end
from dbo.bJBIT t with (nolock)
join dbo.bJBIN n with (nolock) on n.JBCo = t.JBCo and n.BillMonth = t.BillMonth and n.BillNumber = t.BillNumber
where t.JBCo = @jbco and t.Contract = @contract and t.Item = @contractitem
	and n.InvStatus <> 'D'
	and (t.BillMonth < @billmonth or (t.BillMonth = @billmonth and t.BillNumber <= @billnumber))
   
/* Get Current Contract Amount for this Item */
select @billtype = BillType, @contractamt = ContractAmt		--Includes Change Orders
from dbo.bJCCI with (nolock)
where JCCo = @jbco and Contract = @contract and Item = @contractitem
   
if @billtype in ('B', 'T')
	begin
	if @jbitbilledamt > @contractamt select @overlimityn = 'Y'
	end

exitfunction:
  			
return @overlimityn
end

GO
GRANT EXECUTE ON  [dbo].[vfJBItemOverLimitYN] TO [public]
GO
