SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspJBProgFutureBillandClosedMthChk]

/***************************************************************************
*
* Created:	TJL 07/14/06 - Issue #28048, 6x Rewrite JBProgressBilling
* Modified: GG 02/25/08 - #120107 - separate sub ledger close - use AR close month 
*
* Warns the user if a there are other bills for this contract in the future.
* Also checks to see whether the bill month is open in GLCo.
*
*
*
* Pass:
*	JBCo, BillMonth, BillNumber, Contract
*
* Success returns:
*	0
*
* Error returns:
*	1 and error message
*****************************************************************************/
@jbco bCompany, @billmth bMonth, @billnum int, @contract bContract, @futurebillmsg varchar(255) output,
	@subledgermthclosedmsg varchar(255) output,	@msg varchar(255) output
   
as
set nocount on
   
declare @rcode int, @futuremth bMonth, @futurebill int, @printmth varchar(5),
	@JClastmthsubclsd bMonth, @ARlastmthsubclsd bMonth
   
select @rcode = 0, @futuremth = null, @futurebill = null,
	@futurebillmsg = '', @subledgermthclosedmsg = ''

if @jbco is null
	begin
	select @msg = 'Missing JB Company.', @rcode = 1
	goto vspexit
	end

/*********************** FUTURE BILL CHECKS **********************/
if @contract is not null
	begin
	/* First check for Future Bill in this BillMonth. */
	select @futurebill = min(BillNumber)
	from bJBIN with (nolock)
	where JBCo = @jbco and Contract = @contract and BillMonth = @billmth and BillType in ('B','P') 
		and BillNumber > @billnum
	if @futurebill is not null 
		begin
		select @futuremth = @billmth
		end
	else
		/* Now check for Future Bill in future BillMonths. */
		begin
		select @futuremth = min(BillMonth)
		from bJBIN with (nolock)
		where JBCo = @jbco and Contract = @contract and BillMonth > @billmth and BillType in ('B','P') 
		if @futuremth is not null
			begin
			select @futurebill = min(BillNumber)
			from bJBIN with (nolock)
			where JBCo = @jbco and Contract = @contract and BillMonth = @futuremth and BillType in ('B','P')
 			end
		end
	   
	if @futurebill is not null
   		begin
   		select @printmth = convert(varchar(2),datepart(mm,@futuremth)) + '/' + convert(varchar(5),right(datepart(yy,@futuremth),2))
   		select @futurebillmsg = 'Warning!  Future bill # ' + convert(varchar(10),@futurebill) + ' exists in bill month ' + isnull(@printmth,'')
   		end
	end

/*********************** CLOSED MONTH CHECKS **********************/
   
/* Need Job Billings (Same as JCCo), JC GLCo and JC ARCo.GLCo */
select @JClastmthsubclsd = gj.LastMthSubClsd, @ARlastmthsubclsd = ga.LastMthARClsd -- #120107 - use AR month
from bJCCO j with (nolock)
join bARCO a with (nolock) on a.ARCo = j.ARCo
join bGLCO gj with (nolock) on gj.GLCo = j.GLCo
join bGLCO ga with (nolock) on ga.GLCo = a.GLCo
where j.JCCo = @jbco
   
/* Do compare and error */
if @billmth <= @JClastmthsubclsd
	begin
	select @subledgermthclosedmsg = 'Warning!  JC Subledger month is closed!'
	end
else
	begin
	if @billmth <= @ARlastmthsubclsd
		begin
		select @subledgermthclosedmsg = 'Warning!  AR Subledger month is closed!'
		end   
	end

vspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJBProgFutureBillandClosedMthChk] TO [public]
GO
