SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspJBProgACOChk]
/*************************************
*
* Created:  bc 09/21/00
*		TJL  03/06/06 - Issue #28199:  Format @msg output to fit JBProgChgOrder Form, Added (nolock)
*		TJL  01/11/09 - Issue #130770, Increase ACO Description label to 60 characters
*
* warns the user if an ACO for this job exists on another bill for this contract
*
* this is a warning only.
*
*
* Success returns:
*	0
*
* Error returns:
*	1 and error message
**************************************/
@jbco bCompany, @billmth bMonth, @billnum int, @job bJob, @aco bACO, @msg varchar(255) output

as
set nocount on

declare @rcode int, @different_mth bMonth, @different_bill int, @printmth varchar(5), @contract bContract

select @rcode = 0, @different_mth = null, @different_bill = null

select @contract = Contract
from bJBIN with (nolock)
where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnum
   
select @different_mth = min(n.BillMonth)
from bJBIN n with (nolock)
join bJBCC c with (nolock) on c.JBCo = n.JBCo and c.BillMonth = n.BillMonth and c.BillNumber = n.BillNumber and c.Job = @job and c.ACO = @aco
where n.JBCo = @jbco and n.Contract = @contract and ((n.BillMonth <> @billmth) or (n.BillMonth = @billmth and n.BillNumber <> @billnum))
   
if @different_mth is not null
	begin
	
	select @different_bill = min(n.BillNumber)
	from bJBIN n with (nolock)
	join bJBCC c with (nolock) on c.JBCo = n.JBCo and c.BillMonth = n.BillMonth and c.BillNumber = n.BillNumber and c.Job = @job and c.ACO = @aco
	where n.JBCo = @jbco and n.Contract = @contract and n.BillMonth = @different_mth and
	    ((@different_mth <> @billmth) or (@different_mth = @billmth and n.BillNumber <> @billnum))
	end
   
if @different_bill is not null
	begin
	select @printmth = convert(varchar(2),datepart(mm,@different_mth)) + '/' + convert(varchar(5),right(datepart(yy,@different_mth),2))
	select @msg = 'Warning!  Job ' + isnull(ltrim(@job),'') + ',' + char(10) + char(13) + 'ACO ' + isnull(ltrim(@aco),'') + ' exists on:' + char(10) + char(13) 
	select @msg = @msg + 'bill #' + isnull(convert(varchar(10),@different_bill),'') + ' in bill month ' + isnull(@printmth,'')
	select @rcode = 1
	end
   
bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBProgACOChk] TO [public]
GO
