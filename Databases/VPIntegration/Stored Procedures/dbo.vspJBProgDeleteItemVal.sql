SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspJBProgDeleteItemVal]
/*************************************
*
* Created:  TJL  02/27/06 - Issue #28051:  6x Recode 
* Modified: 
*
*
* Pass In:
*	JBCo, BillMonth, BillNumber, Contract, Item
*
* Success returns:
*	0	Item may be deleted cleanly
*	7	Item may be deleted but user is warned that Changes Orders exist and will also be deleted by trigger
*
* Error returns:
*	1 	and error message.  Items may not be deleted
**************************************/
(@jbco bCompany, @billmth bMonth, @billnum varchar(15), @contract bContract, @item bContractItem, @msg varchar(255) output)
   
as
set nocount on

declare @rcode int, @EditOnBothYN bYN, @job bJob, @aco bACO, @acoitem bContractItem, @jcoi_contract bContract,
	@jcoi_contractitem bContractItem, @cnt int, @acoitem_exists bYN
   
select @rcode = 0, @cnt = 0, @acoitem_exists = 'N'

/* First check to see if Item can be deleted from this Bill. */   
select @EditOnBothYN = EditProgOnBothYN
from bJBCO with (nolock)
where JBCo = @jbco
   
if exists(select 1
          from bJBIT with (nolock)
          where JBCo = @jbco and Contract = @contract and Item = @item and
                ((BillMonth < @billmth) or (BillMonth = @billmth and BillNumber < @billnum)))
	begin
	select @msg = 'Cannot delete an item that exists on a previous bill.', @rcode = 1
	goto vspexit
	end
   
if @EditOnBothYN = 'N' and
	exists(select 1
          from bJBIT t with (nolock)
          join bJCCI i with (nolock) on i.JCCo = t.JBCo and i.Contract = t.Contract and i.Item = t.Item and i.BillType = 'B'
          where t.JBCo = @jbco and t.BillMonth = @billmth and t.BillNumber = @billnum and t.Item = @item)
	begin
	select @msg = 'Cannot delete an item with contract items BillType = (B) from this grid.', @rcode = 1
	goto vspexit
	end
   
if exists(select 1
          from bJBIT t with (nolock)
          join bJCCI i with (nolock) on i.JCCo = t.JBCo and i.Contract = t.Contract and i.Item = t.Item and i.BillType = 'T'
          where t.JBCo = @jbco and t.BillMonth = @billmth and t.BillNumber = @billnum and t.Item = @item)
	begin
	select @msg = 'Cannot delete an item with contract items BillType = (T) from this grid.', @rcode = 1
	goto vspexit
	end
   
/* Next if Item may be deleted then:
   If the item being deleted will cause at least one ACO to be deleted by btJBITd then warn the user prior to delete */
select @job = min(Job)
from bJBCX with (nolock)
where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnum
while @job is not null
	begin
	select @aco = min(ACO)
	from bJBCX with (nolock)
	where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnum and Job = @job
	while @aco is not null
		begin
    	select @acoitem = min(ACOItem)
    	from bJBCX with (nolock)
    	where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnum and Job = @job and ACO = @aco
    	while @acoitem is not null
      		begin
      		select @acoitem_exists = 'Y'

      		select @jcoi_contractitem = Item
      		from bJCOI with (nolock)
      		where JCCo = @jbco and Job = @job and ACO = @aco and ACOItem = @acoitem and Contract = @contract

      		if @jcoi_contractitem <> @item
        		begin
        		select @cnt = 1
        		end
   
        	select @acoitem = min(ACOItem)
        	from bJBCX with (nolock)
        	where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnum and
            	Job = @job and ACO = @aco and ACOItem > @acoitem
        	end
   
      	/* if @cnt = 0 then no other record(s) in JBCX is applied to a different item other than the one that's being deleted */
      	if @acoitem_exists = 'Y' and @cnt = 0
        	begin
        	select @rcode = 7
        	goto vspexit
        	end
   
      	--Next ACO
      	select @acoitem_exists = 'N', @cnt = 0
   
      	select @aco = min(ACO)
      	from bJBCX with (nolock)
      	where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnum and Job = @job and ACO > @aco
      	end
   
	select @job = min(Job)
    from bJBCX with (nolock)
    where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnum and Job > @job
	end

vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJBProgDeleteItemVal] TO [public]
GO
