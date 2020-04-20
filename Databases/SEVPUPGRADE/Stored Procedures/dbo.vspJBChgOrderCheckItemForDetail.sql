SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspJBChgOrderCheckItemForDetail]
   
/****************************************************************************
* CREATED BY: TJL 03/10/06 - Issue #28199, 6x Recode
* MODIFIED By : 
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
(@co bCompany, @mth bMonth, @billnum int, @job bJob, @aco bACO, @acoitem bACOItem, @missing bYN output,
	@msg varchar(255) output)
as
   
set nocount on

/*generic declares */
declare @rcode int, @item bContractItem
   
select @rcode=0, @missing = 'N'

/* Get values */
select @item = Item 
from bJCOI with (nolock)
where JCCo = @co and Job = @job and ACO = @aco and ACOItem = @acoitem

/* Check for Item in JBIT */  
if not exists(select 1 from bJBIT with (nolock) where JBCo = @co and BillMonth = @mth and BillNumber = @billnum
	and Item = @item)
	begin
	select @missing = 'Y'
	goto vspexit
	end
   
vspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJBChgOrderCheckItemForDetail] TO [public]
GO
