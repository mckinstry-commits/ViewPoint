SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJBChangeOrderAdd Script Date: 8/28/99 9:32:34 AM ******/
CREATE proc [dbo].[bspJBChangeOrderAdd]
/***********************************************************
* CREATED BY	: kb 8/29/00
* MODIFIED BY :	bc 08/30/00 - made sure that a duplicate row will not be inserted into JBCC for this bill if the jcoi_count > jbcx_count
*		bc 11/16/00 - only add change order information on Items set up as 'B'oth or 'P'rogress types in JCCI
*		TJL 3/6/01 - Add additional filter (and h.IntExt = 'E') to eliminate Internal Change Orders from showing in Prog Bill
*		kb 2/19/2 - issue #16147
*		TJL 02/03/09 - Issue #132154, Attempt to improve performance when Change Orders added to bill
*		TJL 07/30/09 - Issue #134966, ACO with two ACO Items using same Contract Item causes duplicate Key error on JBCC insert
*
* USED IN:
*
* USAGE:
*
* INPUT PARAMETERS
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
   
(@co bCompany, @mth bMonth, @billnum int, @contract bContract,
	@acothrudate bDate, @contractitem bContractItem, @msg varchar(255) output)
as

set nocount on

declare @rcode int

select @rcode = 0
   
/* JBCC insert trigger adds appropriate JBCX records */
insert dbo.bJBCC (JBCo, BillMonth, BillNumber, Job, ACO, ChgOrderTot, AuditYN)
select distinct @co, @mth, @billnum, h.Job, h.ACO, 0,'N'
from dbo.bJCOH h (nolock) 
join dbo.bJCOI i (nolock) on i.JCCo = h.JCCo and i.Job = h.Job and i.ACO = h.ACO
join dbo.bJCCI c (nolock) on c.JCCo = i.JCCo and c.Contract = i.Contract and c.Item = i.Item
where h.JCCo = @co and h.Contract = @contract and i.Item = @contractitem and c.BillType in('B','P')
	and h.ApprovalDate <= isnull(@acothrudate, h.ApprovalDate) and h.IntExt = 'E'
	and not exists(select top 1 1 from dbo.bJBCX x
		where x.JBCo = h.JCCo and x.Job = h.Job and x.ACO = h.ACO and x.ACOItem = i.ACOItem)
	and not exists(select top 1 1 from dbo.bJBCC c
		where c.JBCo = h.JCCo and c.BillMonth = @mth and c.BillNumber = @billnum and c.Job = h.Job and c.ACO = h.ACO)

bspexit:
return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspJBChangeOrderAdd] TO [public]
GO
