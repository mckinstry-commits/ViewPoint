SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspJBChgOrderCheckItem]
   
/****************************************************************************
* CREATED BY: kb 2/22/00
* MODIFIED By : kb 3/27/00 - add billtype restriction
*
* USAGE:
*
*  INPUT PARAMETERS
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs
* RETURN VALUE
*   0         success
*   1         Failure
********************************************************************************************************************/
(@co bCompany,@mth bMonth, @billnum int, @job bJob, @aco bACO, @missing bYN output,
@msg varchar(255) output)
as
   
set nocount on

/*generic declares */
declare @rcode int, @acoitem bACOItem, @item bContractItem, @contract bContract
   
select @rcode=0, @missing = 'N'
   
select @acoitem = min(ACOItem) 
from bJBCX with (nolock)
where JBCo = @co and BillMonth = @mth and BillNumber = @billnum
	and Job = @job and ACO = @aco
   
while @acoitem is not null
   	begin
   	select @item = Item 
	from bJCOI with (nolock)
	where JCCo = @co and Job = @job and ACO = @aco and ACOItem = @acoitem
   
	select @contract = Contract 
	from bJBIN with (nolock)
	where JBCo = @co and BillMonth = @mth and BillNumber = @billnum
   
	if exists(select 1 from bJCCI with (nolock) where JCCo = @co and Contract = @contract and
		(BillType = 'P' or BillType = 'B'))
		begin
       	if not exists(select 1 from bJBIT with (nolock) where JBCo = @co and BillMonth = @mth and BillNumber = @billnum
       		and Item = @item)
       		begin
       		select @missing = 'Y'
       		goto bspexit
       		end
       	select @acoitem = min(ACOItem) 
		from bJBCX with (nolock)
		where JBCo = @co and BillMonth = @mth and BillNumber = @billnum 
			and Job = @job and ACO = @aco and ACOItem > @acoitem
     	end
   	end
   
bspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBChgOrderCheckItem] TO [public]
GO
