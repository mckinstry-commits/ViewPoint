SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspJBCheckARAppliedTrans]

/***************************************************************************
*
* Created:	TJL 09/06/06 - Issue #121506, Check for AR Applied Transactions
* Modified:  
*
*
* Pass In:
*	JBCo, BillMonth, BillNumber
*
* Success returns:
*	0
*
* Error returns:
*	1 and Error message
*	7 and warning message
*
*****************************************************************************/
@jbco bCompany, @billmth bMonth, @billnum int, @msg varchar(255) output
   
as
set nocount on
   
declare @rcode int, @jccoarco bCompany, @artrans bTrans

select @rcode = 0

if @jbco is null
	begin
	select @msg = 'JB Company is missing.', @rcode = 1
	goto vspexit
	end
if @billmth is null
	begin
	select @msg = 'JB BillMonth is missing.', @rcode = 1
	goto vspexit
	end
if @billnum is null
	begin
	select @msg = 'JB BillNumber is missing.', @rcode = 1
	goto vspexit
	end

/* Get required information */
select @jccoarco = j.ARCo, @artrans = n.ARTrans
from bJBIN n with (nolock)
join bJCCO j with (nolock) on j.JCCo = n.JBCo
where n.JBCo = @jbco and n.BillMonth = @billmth and n.BillNumber = @billnum
if @@rowcount = 0
	begin
	select @msg = 'Unable to retrieve JC Company information.', @rcode = 1
	goto vspexit
	end

/* Check for Applied Transactions */
if @artrans is not null
	begin
	if exists(select 1
		from bARTH ARTH with (nolock)
		join bARTL ARTL with (nolock) on ARTL.ARCo = ARTH.ARCo and ARTL.Mth = ARTH.Mth and ARTL.ARTrans = ARTH.ARTrans
		where ARTL.ARCo = @jccoarco and ARTL.ApplyMth = @billmth and ARTL.ApplyTrans = @artrans	--Applied transactions, in AR, against this JB Bill
			and (ARTL.ApplyMth <> ARTL.Mth or ARTL.ApplyTrans <> ARTL.ARTrans)				--Exclude the original AR Invoice transaction for this Bill
			and ARTH.Source like ('AR%'))													--Only AR transactions because they are invisible in JB
		begin
		/* Applied Transactions exist in AR generated from within AR itself */
		select @msg = 'There are ARCashReceipts or other AR generated Applied Transactions, against this JB Invoice, posted in AR.', @rcode = 7
		goto vspexit
		end
	end

vspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJBCheckARAppliedTrans] TO [public]
GO
